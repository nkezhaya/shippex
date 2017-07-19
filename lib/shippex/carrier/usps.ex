defmodule Shippex.Carrier.USPS do
  @moduledoc false

  import SweetXml
  alias Shippex.Carrier.USPS.Client
  alias Shippex.Package

  @default_container :variable
  @large_containers ~w(rectangular nonrectangular variable)a
  def fetch_rates(%Shippex.Shipment{} = shipment) do
    fetch_rate(shipment, :all)
  end

  def fetch_rate(%Shippex.Shipment{} = shipment, service) do
    service = case service do
      %Shippex.Service{} = service -> service.code
      :all -> "ALL"
      s when is_bitstring(s) -> s
    end

    container =
      case Package.usps_containers[shipment.package.container] do
        nil -> Package.usps_containers[@default_container]
        container -> container
      end
      |> String.upcase

    size =
      if shipment.package.container in @large_containers do
        shipment.package
        |> Map.take([:length, :width, :height])
        |> Map.values
        |> Enum.any?(& &1 > 12)
        |> if(do: "LARGE", else: "REGULAR")
      else
        "REGULAR"
      end

    container_params =
      [{:Container, nil, container},
       {:Size, nil, size},
       {:Width, nil, shipment.package.width},
       {:Length, nil, shipment.package.length},
       {:Height, nil, shipment.package.height},
       {:Girth, nil, shipment.package.girth},
       {:Machinable, nil, "False"}]

    package_params =
      {:Package, %{ID: "0"},
        [{:Service, nil, service},
         {:ZipOrigination, nil, shipment.from.zip},
         {:ZipDestination, nil, shipment.to.zip},
         {:Pounds, nil, "0"},
         {:Ounces, nil, shipment.package.weight}] ++ container_params}

    request =
      {:RateV4Request, %{USERID: config().username},
        [{:Revision, nil, 2}, package_params]}

    IO.puts(XmlBuilder.generate(request))
    case Client.post("", %{API: "RateV4", XML: request}) do
      {:ok, rates} ->
        body = rates.body

        case xpath(body, ~x"//Error//text()"s) do
          "" ->
            body
            |> xpath(
              ~x"//RateV4Response//Package//Postage"l,
              name: ~x"./MailService//text()"s |> transform_by(&strip_html/1),
              code: ~x"@CLASSID"s,
              rate: ~x"./Rate//text()"s |> transform_by(&Decimal.new/1)
            )
          _ ->
            code = xpath(body, ~x"//Error//Number//text()"s)
            message = xpath(body, ~x"//Error//Description//text()"s)
            {:error, %{code: code, message: message}}
        end

      {:error, _} -> {:error, ""}
    end
  end

  def fetch_label(%Shippex.Shipment{} = shipment, %Shippex.Service{} = service) do
  end
  def fetch_label(%Shippex.Shipment{} = shipment, %Shippex.Rate{} = rate) do
    fetch_label(shipment, rate.service)
  end

  def cancel_shipment(%Shippex.Label{} = label) do
    cancel_shipment(label.tracking_number)
  end
  def cancel_shipment(tracking_number) when is_bitstring(tracking_number) do
  end

  def validate_address(%Shippex.Address{} = address) do
    address_params =
      {:Address, %{ID: "0"},
        [{:FirmName, nil, nil},
         {:Address1, nil, address.address},
         {:Address2, nil, address.address_line_2},
         {:City, nil, address.city},
         {:State, nil, address.state},
         {:Zip5, nil, address.zip},
         {:Zip4, nil, ""}]}

    request =
      {:AddressValidateRequest, %{USERID: config().username}, [address_params]}

    Client.post("", %{API: "Verify", XML: request})
  end

  defp strip_html(string) do
    string
    |> HtmlEntities.decode
    |> String.replace(~r/<\/?\w+>.*<\/\w+>/, "")
  end

  defmodule Client do
    @moduledoc false
    use HTTPoison.Base

    # HTTPoison implementation
    def process_url(endpoint), do: base_url() <> endpoint
    def process_request_body(params) do
      params = Enum.map params, fn
        {:XML, xml} when is_tuple(xml) -> {:XML, generate(xml)}
        {k, v} when is_atom(k) -> {k, v}
        {k, v} when is_bitstring(k) -> {String.to_atom(k), v}
      end

      {:form, params}
    end

    defp base_url do
      "https://secure.shippingapis.com/ShippingAPI.dll"
    end

    defp generate(object) do
      object
      |> XmlBuilder.generate
      |> String.replace(~r/[\t\n]+/, "")
    end
  end

  defp config do
    with cfg when is_list(cfg) <- Keyword.get(Shippex.config, :usps, {:error, :not_found}),

         un <-
           Keyword.get(cfg, :username, {:error, :not_found, :username}),

         pw <-
           Keyword.get(cfg, :password, {:error, :not_found, :password}) do

         %{username: un,
           password: pw}
    else
      {:error, :not_found, token} -> raise Shippex.InvalidConfigError,
        message: "USPS config key missing: #{token}"

      {:error, :not_found} -> raise Shippex.InvalidConfigError,
        message: "USPS config is either invalid or not found."
    end
  end
end
