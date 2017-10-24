defmodule Shippex.Carrier.USPS do
  @moduledoc false
  @behaviour Shippex.Carrier

  import SweetXml
  alias Shippex.Carrier.USPS.Client
  alias Shippex.Package
  alias Shippex.Util

  @default_container :variable
  @large_containers ~w(rectangular nonrectangular variable)a

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

  def fetch_rates(%Shippex.Shipment{} = shipment) do
    fetch_rate(shipment, :all)
  end

  def fetch_rate(%Shippex.Shipment{} = shipment, service) do
    service = case service do
      %Shippex.Service{} = service -> service.code
      :all -> "ALL"
      s when is_bitstring(s) -> s
    end

    package_params =
      {:Package, %{ID: "0"},
        [{:Service, nil, service},
         {:ZipOrigination, nil, shipment.from.zip},
         {:ZipDestination, nil, shipment.to.zip},
         {:Pounds, nil, "0"},
         {:Ounces, nil, shipment.package.weight}] ++ container_params(shipment)}

    request =
      {:RateV4Request, %{USERID: config().username},
        [{:Revision, nil, 2}, package_params]}

    with_response Client.post("ShippingAPI.dll", %{API: "RateV4", XML: request}) do
      body
      |> xpath(
        ~x"//RateV4Response//Package//Postage"l,
        name: ~x"./MailService//text()"s |> transform_by(&strip_html/1),
        service: ~x"./MailService//text()"s |> transform_by(&service_to_code/1),
        rate: ~x"./Rate//text()"s |> transform_by(&Util.price_to_cents/1)
      )
      |> Enum.map(fn(%{name: description, service: service, rate: cents}) ->
        rate = %Shippex.Rate{service: %{service | description: description},
                             price: cents}

        {:ok, rate}
      end)
      |> Enum.filter(fn {:ok, rate} ->
        case rate.service.code do
          "LIBRARY MAIL" -> config().include_library_mail
          "MEDIA MAIL" -> config().include_media_mail
          _ -> true
        end
      end)
    end
  end
  defp service_to_code(description) do
    code = cond do
      description =~ ~r/priority mail express/i -> "PRIORITY MAIL EXPRESS"
      description =~ ~r/priority/i -> "PRIORITY"
      description =~ ~r/first[-\s]*class/i -> "FIRST CLASS"
      description =~ ~r/retail ground/i -> "RETAIL GROUND"
      description =~ ~r/media mail/i -> "MEDIA MAIL"
      description =~ ~r/library mail/i -> "LIBRARY MAIL"
    end

    Shippex.Service.by_carrier_and_code(:usps, code)
  end

  def fetch_label(%Shippex.Shipment{} = shipment, %Shippex.Service{} = service) do
    [root, api] = case Shippex.env do
      :dev  -> ["DelivConfirmCertifyV4.0Request",  "DelivConfirmCertifyV4"]
      :prod -> ["DeliveryConfirmationV4.0Request", "DeliveryConfirmationV4"]
    end

    request =
      {root, %{USERID: config().username},
        [{:Revision, nil, 2},
         address_params(shipment.from, prefix: "From", firm: "Firm", name: true),
         address_params(shipment.to, prefix: "To", firm: "Firm", name: true),
         {:WeightInOunces, nil, shipment.package.weight},
         {:ServiceType, nil, service.code},
         {:ImageType, nil, "TIF"}]}

    with_response Client.post("ShippingAPI.dll", %{API: api, XML: request}) do
      data =
        body
        |> xpath(
          ~x"//#{String.replace(root, "Request", "Response")}",
          rate: ~x"//Postage//text()"s,
          tracking_number: ~x"//DeliveryConfirmationNumber//text()"s,
          image: ~x"//DeliveryConfirmationLabel//text()"s
        )

      price = Util.price_to_cents(data.rate)

      rate = %Shippex.Rate{service: service, price: price}
      image = String.replace(data.image, "\n", "")
      label = %Shippex.Label{rate: rate,
                             tracking_number: data.tracking_number,
                             format: "tif",
                             image: image}

      {:ok, label}
    end
  end

  def cancel_shipment(%Shippex.Label{} = label) do
    cancel_shipment(label.tracking_number)
  end
  def cancel_shipment(tracking_number) when is_bitstring(tracking_number) do
  end

  def validate_address(%Shippex.Address{country: "US"} = address) do
    request =
      {:AddressValidateRequest, %{USERID: config().username},
        [{:Revision, nil, "1"},
         {:Address, %{ID: "0"}, address_params(address, firm: "FirmName")}]}

    with_response Client.post("", %{API: "Verify", XML: request}) do
      candidates =
        body
        |> xpath(
          ~x"//AddressValidateResponse//Address"l,
          address: ~x"./Address2//text()"s, # USPS swaps address lines 1 & 2
          address_line_2: ~x"./Address1//text()"s,
          city: ~x"./City//text()"s,
          state: ~x"./State//text()"s,
          zip: ~x"./Zip5//text()"s,
        )
        |> Enum.map(fn (candidate) ->
          candidate
          |> Map.merge(Map.take(address, [:name, :phone]))
          |> Shippex.Address.address
        end)

      {:ok, candidates}
    end
  end

  defp address_params(%Shippex.Address{} = address, opts) do
    tree = []
    prefix = Keyword.get(opts, :prefix, "")

    tree = if Keyword.get(opts, :name, false) do
      tree ++ [{prefix <> "Name", nil, address.name}]
    else
      tree
    end

    tree = case Keyword.get(opts, :firm, false) do
      firm when is_boolean(firm) ->
        tree ++ [{prefix <> "Firm", nil, ""}]
      firm when is_bitstring(firm) ->
        tree ++ [{prefix <> firm, nil, ""}]
      _ ->
        tree
    end

    tree ++
      [{prefix <> "Address1", nil, address.address_line_2 || ""},
       {prefix <> "Address2", nil, address.address},
       {prefix <> "City", nil, address.city},
       {prefix <> "State", nil, address.state},
       {prefix <> "Zip5", nil, address.zip},
       {prefix <> "Zip4", nil, ""}]
  end

  defp container_params(%Shippex.Shipment{package: package}) do
    container =
      case Package.usps_containers[package.container] do
        nil -> Package.usps_containers[@default_container]
        container -> container
      end
      |> String.upcase

    size =
      if package.container in @large_containers do
        package
        |> Map.take([:length, :width, :height])
        |> Map.values
        |> Enum.any?(& &1 > 12)
        |> if(do: "LARGE", else: "REGULAR")
      else
        "REGULAR"
      end

    [{:Container, nil, container},
     {:Size, nil, size},
     {:Width, nil, package.width},
     {:Length, nil, package.length},
     {:Height, nil, package.height},
     {:Girth, nil, package.girth},
     {:Machinable, nil, "False"}]
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
    def process_url("") do
      case Shippex.env do
        :dev -> "ShippingAPITest.dll"
        :prod -> "ShippingAPI.dll"
      end
      |> process_url
    end
    def process_url(endpoint) do
      base_url() <> "/" <> endpoint
    end

    def process_request_body(params) do
      params = Enum.map params, fn
        {:XML, xml} when is_tuple(xml) -> {:XML, generate(xml)}
        {k, v} when is_atom(k) -> {k, v}
        {k, v} when is_bitstring(k) -> {String.to_atom(k), v}
      end

      {:form, params}
    end

    defp base_url do
      "https://secure.shippingapis.com"
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
           Keyword.get(cfg, :password, {:error, :not_found, :password}),

         include_library_mail <-
           Keyword.get(cfg, :include_library_mail, true),

         include_media_mail <-
           Keyword.get(cfg, :include_media_mail, true) do

         %{username: un,
           password: pw,
           include_library_mail: include_library_mail,
           include_media_mail: include_media_mail}
    else
      {:error, :not_found, token} -> raise Shippex.InvalidConfigError,
        message: "USPS config key missing: #{token}"

      {:error, :not_found} -> raise Shippex.InvalidConfigError,
        message: "USPS config is either invalid or not found."
    end
  end
end
