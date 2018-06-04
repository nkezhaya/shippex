defmodule Shippex.Carrier.USPS do
  @moduledoc false
  @behaviour Shippex.Carrier

  require EEx
  import SweetXml
  alias Shippex.Carrier.USPS.Client
  alias Shippex.{Address, Package, Label, Service, Shipment, Util, ISO}

  @default_container :rectangular
  @large_containers ~w(rectangular nonrectangular variable)a

  for f <- ~w(address cancel label rate validate_address)a do
    EEx.function_from_file(:defp, :"render_#{f}", __DIR__ <> "/usps/templates/#{f}.eex", [
      :assigns
    ])
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

        {:error, _} ->
          {:error, %{code: 1, message: "The USPS API is down."}}
      end
    end
  end

  def fetch_rates(_shipment) do
    raise "Not implemented for USPS"
  end

  def fetch_rate(%Shipment{} = shipment, service) do
    service =
      case service do
        %Shippex.Service{} = service -> service
        s when is_atom(s) -> Service.get(s)
      end

    api =
      if shipment.international? do
        "IntlRateV2"
      else
        "RateV4"
      end

    rate = render_rate(shipment: shipment, service: service)

    with_response Client.post("ShippingAPI.dll", %{API: api, XML: rate}) do
      spec =
        extra_services_spec(shipment) ++
          if shipment.international? do
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
        if shipment.international? do
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
        if shipment.international? do
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

  def create_transaction(shipment, service) when is_atom(service) do
    create_transaction(shipment, Service.get(service))
  end

  def create_transaction(%Shipment{} = shipment, %Service{} = service) do
    api =
      cond do
        not shipment.international? ->
          "eVS"

        service.id == :usps_priority_express ->
          "eVSExpressMailIntl"

        service.id == :usps_priority ->
          "eVSPriorityMailIntl"

        true ->
          raise """
          Only the Priority and Priority Express services are supported for
          international shipments at the moment.
          """
      end

    request = render_label(shipment: shipment, service: service, api: api)

    with_response Client.post("ShippingAPI.dll", %{API: api, XML: request}) do
      spec =
        if shipment.international? do
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

      transaction = Shippex.Transaction.transaction(shipment, rate, label)

      {:ok, transaction}
    end
  end

  def cancel_transaction(%Shippex.Transaction{} = transaction) do
    cancel_transaction(transaction.shipment, transaction.label.tracking_number)
  end

  def cancel_transaction(%Shippex.Shipment{} = shipment, tracking_number) do
    root =
      if shipment.international? do
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

  def us_territories() do
    ~w(PR PW MH FM MP GU AS VI)
  end

  def invalid_destinations() do
    ~w(AN AQ BV EH KP HM IO PN SO SJ SY TF US YE YU)
  end

  defp extra_services_spec(shipment, prefix \\ nil) do
    prefix =
      case prefix do
        nil ->
          if shipment.international?, do: "Extra", else: "Special"

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
      cond do
        is_nil(shipment.package.insurance) ->
          nil

        not is_nil(rate[:insurance_fee]) ->
          %{name: "Insurance", price: rate.insurance_fee}

        true ->
          insurance_code = insurance_code(shipment, service)

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

    line_items =
      [postage_line_item, insurance_line_item]
      |> Enum.reject(&is_nil/1)
      |> Enum.map(fn %{price: price} = line_item ->
        %{line_item | price: Util.price_to_cents(price)}
      end)

    Map.put(rate, :line_items, line_items)
  end

  defp insurance_code(%{international?: true}, %{id: :usps_gxg}), do: "106"
  defp insurance_code(%{international?: true}, %{id: :usps_priority}), do: "108"
  defp insurance_code(%{international?: true}, %{id: :usps_priority_express}), do: "107"
  defp insurance_code(%{international?: false}, %{id: :usps_priority}), do: "125"
  defp insurance_code(%{international?: false}, %{id: :usps_priority_express}), do: "101"
  defp insurance_code(%{international?: false}, %{id: _}), do: "100"

  defp weight_in_ounces(%Shipment{package: %Package{weight: weight}}) do
    16 *
      case Application.get_env(:shippex, :weight_unit, :lbs) do
        :lbs ->
          weight

        :kg ->
          Util.kgs_to_lbs(weight)

        u ->
          raise """
          Invalid unit of measurement specified: #{IO.inspect(u)}

          Must be either :lbs or :kg
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
          zip: ~x"./Zip5//text()"s
        )
        |> Enum.map(fn candidate ->
          candidate
          |> Map.merge(Map.take(address, ~w(first_name last_name name company_name phone)a))
          |> Shippex.Address.address()
        end)

      {:ok, candidates}
    end
  end

  defp country(%Address{country: code}) do
    ISO.abbreviation_to_country_name(code)
    |> replace_name()
  end

  defp replace_name("Russian Federation"), do: "Russia"
  defp replace_name("Korea (South)"), do: "South Korea"
  defp replace_name("Korea (North)"), do: "North Korea"
  defp replace_name("Congo, the"), do: "Congo, Republic of the"
  defp replace_name("Falkland Islands (Malvinas)"), do: "Falkland Islands"
  defp replace_name("Holy See"), do: "Vatican City"
  defp replace_name("Cocos (Keeling) Islands"), do: "Cocos Island (Australia)"
  defp replace_name("Cote d'Ivoire"), do: "Ivory Coast"
  defp replace_name("Bosnia & Herzegovina"), do: "Bosnia-Herzegovina"

  defp replace_name("South Georgia and the South Sandwich Islands"),
    do: "South Georgia (Falkland Islands)"

  defp replace_name(name), do: String.replace(name, "&", "and")

  defp container(%Shipment{package: package}) do
    case Package.usps_containers()[package.container] do
      nil -> Package.usps_containers()[@default_container]
      container -> container
    end
    |> String.upcase()
  end

  defp size(%Shipment{package: package} = shipment) do
    is_large? =
      cond do
        container(shipment) == "RECTANGULAR" ->
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

  defp config do
    with cfg when is_list(cfg) <- Keyword.get(Shippex.config(), :usps, {:error, :not_found}),
         un <- Keyword.get(cfg, :username, {:error, :not_found, :username}),
         pw <- Keyword.get(cfg, :password, {:error, :not_found, :password}) do
      %{username: un, password: pw}
    else
      {:error, :not_found, token} ->
        raise Shippex.InvalidConfigError, message: "USPS config key missing: #{token}"

      {:error, :not_found} ->
        raise Shippex.InvalidConfigError, message: "USPS config is either invalid or not found."
    end
  end
end
