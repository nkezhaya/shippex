defmodule Shippex.Carrier.USPS do
  @moduledoc false
  @behaviour Shippex.Carrier

  require EEx
  import SweetXml
  import Shippex.Address, only: [state_without_country: 1]

  alias Shippex.Carrier.USPS.Client
  alias Shippex.Carrier.USPS.Insurance
  alias Shippex.{Address, Config, InvalidConfigError, Package, Label, Service, Shipment, Util}

  @default_container :rectangular
  @large_containers ~w(rectangular nonrectangular variable)a
  @contents ~w(HAZMAT CREMATEDREMAINS PERISHABLE PHARMACEUTICALS MEDICAL SUPPLIES LIVES)a
  @content_descriptions ~w(BEES DAYOLDPOULTRY ADULTBIRDS OTHER)a
  @sort_types ~w(LETTER LARGEENVELOPE PACKAGE FLATRATE)a
  @shipdate_options ~w(EMSH HFP)a
  @sortation_level ~w(3D 5D BAS CR MIX NDC NONE PST SCF TBE TBF TBH TBT)a
  @destination_entry_facility_type ~w(DDU DNDC DCSF NONE)a

  @typep flat_rate_container() :: %{
    name: String.t(),
    rate: integer(),
    length: number(),
    width: number(),
    height: number()
  }

  for f <-
        ~w(address cancel carrier_pickup_availability city_state_by_zipcode express_mail_commitments first_class_service_standards hold_for_pickup package_pickup_cancel package_pickup_change package_pickup_inquery package_pickup_schedule package_service_standardb priority_mail_service_standards proof_of_delivery return_label return_receipt label rate scan sdc_get_locations sunday_holiday track track_confirm_by_email track_fields validate_address zipcode)a do
    EEx.function_from_file(
      :defp,
      :"render_#{f}",
      __DIR__ <> "/usps/templates/#{f}.eex",
      [
        :assigns
      ],
      trim: true
    )
  end

  defmacro with_response(response, do: block) do
    quote do
      case unquote(response) do
        {:ok, %{body: body}} ->
          case xpath(body, ~x"//Error//text()"s) do
            "" ->
              var!(body) = body
              unquote(block)

            error ->
              code = xpath(body, ~x"//Error//Number//text()"s)
              message = xpath(body, ~x"//Error//Description//text()"s)
              {:error, %{code: code, message: message}}
          end

        {:error, error} ->
          {:error, %{code: 1, message: "The USPS API is down.", extra: error}}
      end
    end
  end

  @impl true
  def fetch_rates(_shipment) do
    {:error, "Fetch All Rates Not implemented for USPS"}
  end

  def machineable?(_package) do
    "False"
  end

  @impl true
  def fetch_rate(%Shipment{} = shipment, service) do
    service =
      case service do
        %Shippex.Service{} = service -> service
        s when is_atom(s) -> Service.get(s)
      end

    api =
      if international?(shipment) do
        "IntlRateV2"
      else
        "RateV4"
      end

    rate_request = String.trim(render_rate(shipment: shipment, service: service))

    with_response Client.post("ShippingAPI.dll", %{API: api, XML: rate_request}, %{
                    "Content-Type" => "application/xml"
                  }) do
      spec =
        extra_services_spec(shipment) ++
          if international?(shipment) do
            [
              name: ~x"./SvcDescription//text()"s,
              service: ~x"./SvcDescription//text()"s,
              rate: ~x"./Postage//text()"f
            ]
          else
            [
              name: ~x"./MailService//text()"s,
              service: ~x"./MailService//text()"s,
              rate: ~x"./Rate//text()"s
            ]
          end

      rates =
        if international?(shipment) do
          xpath(
            body,
            ~x"//IntlRateV2Response//Package//Service"l,
            spec
          )
        else
          xpath(
            body,
            ~x"//RateV4Response//Package//Postage"l,
            spec
          )
        end
        |> add_line_items(shipment, service)
        |> Enum.map(fn response ->
          total = response.line_items |> Enum.map(& &1.price) |> Enum.sum()

          %{
            name: strip_html(response.name),
            service: description_to_service(response.service),
            rate: total,
            line_items: response.line_items
          }
        end)
        |> Enum.map(fn %{name: description, service: service} = response ->
          service = %{service | description: description}

          rate = %Shippex.Rate{
            service: service,
            price: response.rate,
            line_items: response.line_items
          }

          {:ok, rate}
        end)

      rates =
        if international?(shipment) do
          rates
          |> Enum.sort(fn {:ok, rate1}, {:ok, rate2} ->
            service = String.downcase(service.description)

            d1 = String.jaro_distance(String.downcase(rate1.service.description), service)
            d2 = String.jaro_distance(String.downcase(rate2.service.description), service)

            d1 > d2
          end)
        else
          rates
        end

      case rates do
        [] -> {:error, "Rate unavailable for service."}
        [rate] -> rate
        list when is_list(list) -> hd(list)
      end
    end
  end

  @impl true
  def create_transaction(shipment, service) when is_atom(service) do
    create_transaction(shipment, Service.get(service))
  end

  def create_transaction(%Shipment{} = shipment, %Service{} = service) do
    api =
      cond do
        not international?(shipment) ->
          "eVS"

        service.id == :usps_priority_express ->
          "eVSExpressMailIntl"

        service.id == :usps_priority ->
          "eVSPriorityMailIntl"

        service.id == :usps_first_class ->
          "eVSFirstClassMailIntl"

        true ->
          raise """
          Only the Priority and Priority Express services are supported for
          international shipments at the moment. (Received :#{service.id}.)
          """
      end

    request = render_label(shipment: shipment, service: service, api: api)

    with_response Client.post("ShippingAPI.dll", %{API: api, XML: request}) do
      spec =
        if international?(shipment) do
          [insurance_fee: ~x"//InsuranceFee//text()"s]
        else
          extra_services_spec(shipment, "Extra")
        end ++
          [
            rate: ~x"//Postage//text()"s,
            tracking_number: ~x"//BarcodeNumber//text()"s,
            image: ~x"//LabelImage//text()"s
          ]

      response = xpath(body, ~x"//#{api}Response", spec) |> add_line_items(shipment, service)

      line_items = response.line_items
      price = line_items |> Enum.map(& &1.price) |> Enum.sum()

      rate = %Shippex.Rate{service: service, price: price, line_items: line_items}
      image = String.replace(response.image, "\n", "")
      label = %Label{tracking_number: response.tracking_number, format: :pdf, image: image}

      transaction = Shippex.Transaction.new(shipment, rate, label)

      {:ok, transaction}
    end
  end

  @impl true
  def cancel_transaction(%Shippex.Transaction{} = transaction) do
    cancel_transaction(transaction.shipment, transaction.label.tracking_number)
  end

  @impl true
  def cancel_transaction(%Shippex.Shipment{} = shipment, tracking_number) do
    root =
      if international?(shipment) do
        "eVSI"
      else
        "eVS"
      end

    api = root <> "Cancel"

    request = render_cancel(root: root, tracking_number: tracking_number)

    with_response Client.post("ShippingAPI.dll", %{API: api, XML: request}) do
      data =
        xpath(
          body,
          ~x"//#{root}CancelResponse",
          status: ~x"//Status//text()"s,
          reason: ~x"//Reason//text()"s
        )

      status =
        if data.status =~ ~r/not cancel/i do
          :error
        else
          :ok
        end

      {status, data.reason}
    end
  end

  defp extra_services_spec(shipment, prefix \\ nil) do
    prefix =
      case prefix do
        nil ->
          if international?(shipment), do: "Extra", else: "Special"

        prefix ->
          prefix
      end

    [
      extra_services: [
        ~x"//#{prefix}Services//#{prefix}Service"l,
        id: ~x"./ServiceID//text()"s,
        name: ~x"./ServiceName//text()"s,
        available: ~x"./Available//text()"s |> transform_by(&String.downcase/1),
        price: ~x"./Price//text()"s
      ]
    ]
  end

  defp add_line_items(rates, shipment, service) when is_list(rates) do
    Enum.map(rates, fn rate -> add_line_items(rate, shipment, service) end)
  end

  defp add_line_items(rate, shipment, service) do
    postage_line_item = %{name: "Postage", price: rate.rate}

    insurance_line_item =
      Enum.map(shipment.packages, fn package ->
        cond do
          is_nil(package.insurance) ->
            nil

          not is_nil(rate[:insurance_fee]) ->
            %{name: "Insurance", price: rate.insurance_fee}

          true ->
            insurance_code = Integer.to_string(insurance_code(shipment, service))

            rate.extra_services
            |> Enum.find(fn
              %{available: available, id: ^insurance_code} when available != "false" -> true
              _ -> false
            end)
            |> case do
              %{price: price} ->
                %{name: "Insurance", price: price}

              _ ->
                nil
            end
        end
      end)

    line_items =
      ([postage_line_item] ++ insurance_line_item)
      |> Enum.reject(&is_nil/1)
      |> Enum.map(fn %{price: price} = line_item ->
        %{line_item | price: Util.price_to_cents(price)}
      end)

    Map.put(rate, :line_items, line_items)
  end

  defp insurance_code(%Shipment{} = shipment, service),
    do: insurance_code(international?(shipment), service)

  defp insurance_code(_, data), do: Insurance.code(data)

  @spec create_hash(String.t(), number()) :: String.t()
  def create_hash(string, min_len \\ 5) do
    case string do
      nil -> Nanoid.generate(min_len)
      _ -> Nanoid.generate(min_len, string)
    end
  end

  @spec weight_in_ounces(number()) :: number()
  defp weight_in_ounces(pounds) do
    16 *
      case Application.get_env(:shippex, :weight_unit, :lbs) do
        :lbs ->
          pounds

        :kg ->
          Util.kgs_to_lbs(pounds)

        u ->
          raise """
          Invalid unit of measurement specified: #{IO.inspect(u)}

          Must be either :lbs or :kg. This can be configured with:

              config :shippex, :weight_unit, :lbs
          """
      end
  end

  defp description_to_service(description) do
    cond do
      description =~ ~r/priority mail express/i ->
        :usps_priority_express

      description =~ ~r/priority/i ->
        :usps_priority

      description =~ ~r/first[-\s]*class/i ->
        :usps_first_class

      description =~ ~r/retail ground/i ->
        :usps_retail_ground

      description =~ ~r/media mail/i ->
        :usps_media

      description =~ ~r/library mail/i ->
        :usps_library

      description =~ ~r/gxg/i ->
        :usps_gxg

      true ->
        :usps_retail_ground
    end
    |> Shippex.Service.get()
  end

  defp international_mail_type(%Package{container: nil}), do: "PACKAGE"

  defp international_mail_type(%Package{container: container}) do
    container = "#{container}"

    cond do
      container =~ ~r/envelope/i -> "ENVELOPE"
      container =~ ~r/flat[-\s]*rate/i -> "FLATRATE"
      container =~ ~r/rectangular|variable/i -> "PACKAGE"
      true -> "ALL"
    end
  end

  @impl true
  def validate_address(%Shippex.Address{country: "US"} = address) do
    request = render_validate_address(address: address)

    with_response Client.post("", %{API: "Verify", XML: request}) do
      candidates =
        body
        |> xpath(
          ~x"//AddressValidateResponse//Address"l,
          # USPS swaps address lines 1 & 2
          address: ~x"./Address2//text()"s,
          address_line_2: ~x"./Address1//text()"s,
          city: ~x"./City//text()"s,
          state: ~x"./State//text()"s,
          postal_code: ~x"./Zip5//text()"s
        )
        |> Enum.map(fn candidate ->
          candidate
          |> Map.merge(Map.take(address, ~w(first_name last_name name company_name phone)a))
          |> Shippex.Address.new!()
        end)

      {:ok, candidates}
    end
  end

  @impl true
  def track_packages(tracking_number) when is_binary(tracking_number) do
    track_packages([tracking_number])
  end

  def track_packages(tracking_numbers) when is_list(tracking_numbers) do
    request = render_track(tracking_numbers: tracking_numbers)

    with_response Client.post("ShippingAPI.dll", %{API: "TrackV2", XML: request}) do
      {:ok,
       xpath(
         body,
         ~x"//TrackResponse//TrackInfo"l,
         summary: ~x"./TrackSummary//text()"s,
         details: ~x"./TrackDetail//text()"l
       )}
    end
  end

  @impl true
  @not_serviced ~w(AN AQ BV CU EH FK GS HM IO KP LA MM PM PN PS SJ SO SS SY TF TJ TM UM WS YE YU)
  def services_country?(country) when country in @not_serviced do
    false
  end

  def services_country?(_country) do
    true
  end

  def domestic?("US"), do: true
  def domestic?(country) when country in ~w(AS FM GU MH MP PR PW UM VI), do: true
  def domestic?(_), do: false

  def international?(%Shipment{to: %Address{country: c}}),
    do: not domestic?(c)

  def international?(_),
    do: false

  defdelegate country(data), to: Shippex.Country

  @doc """
  Returns a map of predefined containers for use with USPS. These can be
  passed to `package.container` for fetching rates.
  """
  @spec containers() :: %{atom() => String.t()}
  defp containers() do
      %{
        box_large: "Lg Flat Rate Box",
        box_medium: "Md Flat Rate Box",
        box_small: "Sm Flat Rate Box",
        envelope: "Flat Rate Envelope",
        envelope_gift_card: "Gift Card Flat Rate Envelope",
        envelope_legal: "Legal Flat Rate Envelope",
        envelope_padded: "Padded Flat Rate Envelope",
        envelope_small: "Sm Flat Rate Envelope",
        envelope_window: "Window Flat Rate Envelope",
        nonrectangular: "Nonrectangular",
        rectangular: "Rectangular",
        variable: "Variable"
      }
  end

  @doc """
  Returns a map of flat rate USPS containers, along with their string description
  and flat shipping rate (in cents).
  """
  @spec flat_rate_containers() :: %{atom() => flat_rate_container()}
  def flat_rate_containers() do
    %{
      envelope: %{name: "Flat Rate Envelope", rate: 665, length: 12.5, height: 9.5, width: 0},
      envelope_gift_card: %{
        name: "Gift Card Flat Rate Envelope",
        rate: 665,
        length: 10,
        height: 7,
        width: 0
      },
      envelope_window: %{
        name: "Window Flat Rate Envelope",
        rate: 665,
        length: 10,
        height: 5,
        width: 0
      },
      envelope_small: %{name: "Sm Flat Rate Envelope", rate: 665, length: 10, height: 6, width: 0},
      envelope_legal: %{
        name: "Legal Flat Rate Envelope",
        rate: 695,
        length: 15,
        height: 9.5,
        width: 0
      },
      envelope_padded: %{
        name: "Padded Flat Rate Envelope",
        rate: 720,
        length: 12.5,
        height: 9.5,
        width: 0
      },
      box_small: %{
        name: "Sm Flat Rate Box",
        rate: 715,
        length: 8.6875,
        height: 5.4375,
        width: 1.75
      },
      box_medium: %{name: "Md Flat Rate Box", rate: 1360, length: 11.25, height: 8.75, width: 6},
      box_large: %{name: "Lg Flat Rate Box", rate: 1885, length: 12.25, height: 12.25, width: 6}
    }
  end

  defp container(package) do
    case containers()[package.container] do
      nil -> containers()[@default_container]
      container -> container
    end
    |> String.upcase()
  end

  defp size(package) do
    is_large? =
      cond do
        container(package) == "RECTANGULAR" ->
          true

        package.container in @large_containers ->
          package
          |> Map.take(~w(large width height)a)
          |> Map.values()
          |> Enum.any?(&(&1 > 12))

        true ->
          false
      end

    if is_large?, do: "LARGE", else: "REGULAR"
  end

  defp strip_html(string) do
    string
    |> HtmlEntities.decode()
    |> String.replace(~r/<\/?\w+>.*<\/\w+>/, "")
  end

  def config() do
    with cfg when is_list(cfg) <-
           Keyword.get(Config.config(), :usps, {:error, :not_found}),
         un when is_binary(un) <- Keyword.get(cfg, :username, {:error, :not_found, :username}),
         pw when is_binary(pw) <- Keyword.get(cfg, :password, {:error, :not_found, :password}) do
      %{
        username: un,
        password: pw
      }
    else
      {:error, :not_found, :shipper} ->
        raise InvalidConfigError,
          message:
            "USPS shipper config key missing. This could be because was provided as a keyword list instead of a map."

      {:error, :not_found, token} ->
        raise InvalidConfigError, message: "USPS config key missing: #{token}"

      {:error, :not_found} ->
        raise InvalidConfigError, message: "USPS config is either invalid or not found."
    end
  end

  @impl true
  def carrier() do
    :usps
  end
end

defmodule Shippex.Carrier.USPS.Classid do
  defstruct ratev4: [
              "0": "First-ClassMail;LargeEnvelope",
              "0": "First-ClassMail;StampedLetter",
              "0": "First-ClassPackageService-Retail",
              "0": "First-ClassMail;Postcards",
              "1": "PriorityMail",
              "2": "PriorityMailExpress;HoldForPickup",
              "3": "PriorityMailExpress",
              "4": "StandardPost",
              "5": "BoundPrintedMatterPackages",
              "6": "MediaMailPackage",
              "7": "LibraryMailPackage",
              "13": "PriorityMailExpress;FlatRateEnvelope",
              "15": "First-ClassMail;LargePostcards",
              "16": "PriorityMail;FlatRateEnvelope",
              "17": "PriorityMail;MediumFlatRateBox",
              "20": "BoundPrintedMatterFlats",
              "22": "PriorityMail;LargeFlatRateBox",
              "23": "PriorityMailExpress;Sunday/HolidayDelivery",
              "25": "PriorityMailExpress;Sunday/HolidayDeliveryFlatRateEnvelope",
              "27": "PriorityMailExpress;FlatRateEnvelopeHoldForPickup",
              "28": "PriorityMail;SmallFlatRateBox",
              "29": "PriorityMail;PaddedFlatRateEnvelope",
              "30": "PriorityMailExpress;LegalFlatRateEnvelope",
              "31": "PriorityMailExpress;LegalFlatRateEnvelopeHoldForPickup",
              "32": "PriorityMailExpress;Sunday/HolidayDeliveryLegalFlatRateEnvelope",
              "33": "PriorityMail;HoldForPickup",
              "34": "PriorityMail;LargeFlatRateBoxHoldForPickup",
              "35": "PriorityMail;MediumFlatRateBoxHoldForPickup",
              "36": "PriorityMail;SmallFlatRateBoxHoldForPickup",
              "37": "PriorityMail;FlatRateEnvelopeHoldForPickup",
              "38": "PriorityMail;GiftCardFlatRateEnvelope",
              "39": "PriorityMail;GiftCardFlatRateEnvelopeHoldForPickup",
              "40": "PriorityMail;WindowFlatRateEnvelope",
              "41": "PriorityMail;WindowFlatRateEnvelopeHoldForPickup",
              "42": "PriorityMail;SmallFlatRateEnvelope",
              "43": "PriorityMail;SmallFlatRateEnvelopeHoldForPickup",
              "44": "PriorityMail;LegalFlatRateEnvelope",
              "45": "PriorityMail;LegalFlatRateEnvelopeHoldForPickup",
              "46": "PriorityMail;PaddedFlatRateEnvelopeHoldForPickup",
              "47": "PriorityMail;RegionalRateBoxA",
              "48": "PriorityMail;RegionalRateBoxAHoldForPickup",
              "49": "PriorityMail;RegionalRateBoxB",
              "50": "PriorityMail;RegionalRateBoxBHoldForPickup",
              "53": "First-Class;PackageServiceHoldForPickup",
              "55": "PriorityMailExpress;FlatRateBoxes",
              "56": "PriorityMailExpress;FlatRateBoxesHoldForPickup",
              "57": "PriorityMailExpress;Sunday/HolidayDeliveryFlatRateBoxes",
              "58": "PriorityMail;RegionalRateBoxC",
              "59": "PriorityMail;RegionalRateBoxCHoldForPickup",
              "61": "First-Class;PackageService",
              "62": "PriorityMailExpress;PaddedFlatRateEnvelope",
              "63": "PriorityMailExpress;PaddedFlatRateEnvelopeHoldForPickup",
              "64": "PriorityMailExpress;Sunday/HolidayDeliveryPaddedFlatRateEnvelope",
              "77": "PackageSelectGround",
              "78": "First-ClassMail;MeteredLetter",
              "82": "PackageSelectLightweightMachinablePackages5-Digit",
              "82": "PackageSelectLightweightIrregularPackages5-Digit",
              "82": "PackageSelectLightweightMachinablePackagesNDC",
              "82": "PackageSelectLightweightIrregularPackagesNDC",
              "82": "PackageSelectLightweightMachinablePackagesMixedNDC",
              "82": "PackageSelectLightweightIrregularPackagesMixedNDC",
              "82": "PackageSelectLightweightIrregularPackagesSCF",
              "84": "PriorityMailCubic",
              "88": "USPSConnectLocalDDU",
              "89": "USPSConnectLocalFlatRateBag–SmallDDU",
              "90": "USPSConnectLocalFlatRateBag–LargeDDU",
              "91": "USPSConnectLocalFlatRateBoxDDU",
              "92": "PackageSelectGroundCubic",
              "179": "PackageSelectDestinationEntryMachinableDDU",
              "179": "PackageSelectDestinationEntryNonmachinableDDU",
              "179": "PackageSelectDestinationEntryMachinableDSCF5D",
              "179": "PackageSelectDestinationEntryNonmachinableDSCF5-Digit",
              "179": "PackageSelectDestinationEntryMachinableDSCFSCF",
              "179": "PackageSelectDestinationEntryNonmachinableDSCF3-Digit",
              "179": "PackageSelectDestinationEntryMachinableDNDC",
              "179": "PackageSelectDestinationEntryNonmachinableDNDC",
              "922": "PriorityMailReturnServicePaddedFlatRateEnvelope",
              "932": "PriorityMailReturnServiceGiftCardFlatRateEnvelope",
              "934": "PriorityMailReturnServiceWindowFlatRateEnvelope",
              "936": "PriorityMailReturnServiceSmallFlatRateEnvelope",
              "938": "PriorityMailReturnServiceLegalFlatRateEnvelope",
              "939": "PriorityMailReturnServiceFlatRateEnvelope",
              "946": "PriorityMailReturnServiceRegionalRateBoxA",
              "947": "PriorityMailReturnServiceRegionalRateBoxB",
              "962": "PriorityMailReturnService",
              "963": "PriorityMailReturnServiceLargeFlatRateBox",
              "964": "PriorityMailReturnServiceMediumFlatRateBox",
              "965": "PriorityMailReturnServiceSmallFlatRateBox",
              "967": "PriorityMailReturnServiceCubic",
              "968": "First-ClassPackageReturnService",
              "969": "GroundReturnService",
              "2020": "BoundPrintedMatterFlatsHoldForPickup",
              "2071": "PackageSelectGround;HoldForPickup",
              "2077": "BoundPrintedMatterPackagesHoldForPickup",
              "2082": "PackageSelectLightweightMachinablePackages5-DigitHoldForPickup",
              "2082": "PackageSelectLightweightIrregularPackages5-DigitHoldForPickup",
              "2082": "PackageSelectLightweightMachinablePackagesNDCHoldForPickup",
              "2082": "PackageSelectLightweightIrregularPackagesNDCHoldForPickup",
              "2082": "PackageSelectLightweightMachinablePackagesMixedNDCHoldForPickup",
              "2082": "PackageSelectLightweightIrregularPackagesMixedNDCHoldForPickup",
              "2082": "PackageSelectLightweightIrregularPackagesSCFHoldForPickup"
            ],
            ratev6: [
              "1": "Priority Mail Express International",
              "2": "Priority Mail International",
              "4": "Global Express Guaranteed; (GXG)**",
              "5": "Global Express Guaranteed; Document",
              "6": "Global Express Guarantee; Non-Document Rectangular",
              "7": "Global Express Guaranteed; Non-Document Non-Rectangular",
              "8": "Priority Mail International; Flat Rate Envelope**",
              "9": "Priority Mail International; Medium Flat Rate Box",
              "10": "Priority Mail Express International; Flat Rate Envelope",
              "11": "Priority Mail International; Large Flat Rate Box",
              "12": "USPS GXG; Envelopes**",
              "13": "First-Class Mail; International Letter**",
              "14": "First-Class Mail; International Large Envelope**",
              "15": "First-Class Package International Service**",
              "16": "Priority Mail International; Small Flat Rate Box**",
              "17": "Priority Mail Express International; Legal Flat Rate Envelope",
              "18": "Priority Mail International; Gift Card Flat Rate Envelope**",
              "19": "Priority Mail International; Window Flat Rate Envelope**",
              "20": "Priority Mail International; Small Flat Rate Envelope**",
              "1": "Priority Mail Express International",
              "2": "Priority Mail International",
              "4": "Global Express Guaranteed; (GXG)**",
              "5": "Global Express Guaranteed; Document",
              "6": "Global Express Guarantee; Non-Document Rectangular",
              "7": "Global Express Guaranteed; Non-Document Non-Rectangular",
              "8": "Priority Mail International; Flat Rate Envelope**",
              "9": "Priority Mail International; Medium Flat Rate Box",
              "10": "Priority Mail Express International; Flat Rate Envelope",
              "11": "Priority Mail International; Large Flat Rate Box",
              "12": "USPS GXG; Envelopes**",
              "13": "First-Class Mail; International Letter**",
              "14": "First-Class Mail; International Large Envelope**",
              "15": "First-Class Package International Service**",
              "16": "Priority Mail International; Small Flat Rate Box**",
              "17": "Priority Mail Express International; Legal Flat Rate Envelope",
              "18": "Priority Mail International; Gift Card Flat Rate Envelope**",
              "19": "Priority Mail International; Window Flat Rate Envelope**",
              "20": "Priority Mail International; Small Flat Rate Envelope**",
              "28": "Airmail M-Bag"
            ]
end
