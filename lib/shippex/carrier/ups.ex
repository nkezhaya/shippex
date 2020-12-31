defmodule Shippex.Carrier.UPS do
  @moduledoc false
  @behaviour Shippex.Carrier

  import Shippex.Address, only: [state_without_country: 1]

  alias Shippex.Carrier.UPS.Client
  alias Shippex.{Address, Shipment, Service, Transaction, Util}

  defmacro with_response(response, do: block) do
    quote do
      response = unquote(response)

      case response do
        {:ok, response} ->
          fault = response.body["Fault"]

          if not is_nil(fault) do
            error = fault["detail"]["Errors"]["ErrorDetail"]["PrimaryErrorCode"]
            {:error, %{code: error["Code"], message: error["Description"]}}
          else
            var!(response) = response
            unquote(block)
          end

        {:error, error} ->
          {:error, %{code: 1, message: "The UPS API is down.", extra: error}}
      end
    end
  end

  @impl true
  def fetch_rates(%Shipment{} = shipment) do
    services = Service.services_for_carrier(:ups, shipment)

    rates =
      Enum.map(services, fn service ->
        fetch_rate(shipment, service)
      end)

    oks = Enum.filter(rates, &(elem(&1, 0) == :ok))
    errors = Enum.filter(rates, &(elem(&1, 0) == :error))

    Enum.sort(oks, fn r1, r2 ->
      {:ok, r1} = r1
      {:ok, r2} = r2

      r1.price < r2.price
    end) ++ errors
  end

  @impl true
  def fetch_rate(%Shipment{} = shipment, %Service{} = service) do
    params =
      Map.new()
      |> Map.merge(security_params())
      |> Map.merge(rate_request_params(shipment, service))

    response = Client.post("/Rate", params, [{"Content-Type", "application/json"}])

    with_response response do
      body = response.body["RateResponse"]

      case body["Response"]["ResponseStatus"] do
        %{"Code" => "1"} ->
          price =
            body["RatedShipment"]["TotalCharges"]["MonetaryValue"]
            |> Util.price_to_cents()

          rate = %Shippex.Rate{service: service, price: price, line_items: []}

          {:ok, rate}

        %{"Code" => code, "Description" => description} ->
          {:error, %{code: code, message: description, service: service}}
      end
    end
  end

  @impl true
  def create_transaction(%Shipment{} = shipment, %Service{} = service) do
    params =
      Map.new()
      |> Map.merge(security_params())
      |> Map.merge(shipment_request_params(shipment, service))

    response = Client.post("/Ship", params, [{"Content-Type", "application/json"}])

    with_response response do
      body = response.body["ShipmentResponse"]

      case body["Response"]["ResponseStatus"] do
        %{"Code" => "1"} ->
          results = body["ShipmentResults"]

          price =
            results["ShipmentCharges"]["TotalCharges"]["MonetaryValue"]
            |> Util.price_to_cents()

          rate = %Shippex.Rate{service: service, price: price, line_items: []}

          package_response = results["PackageResults"]

          label = %Shippex.Label{
            tracking_number: package_response["TrackingNumber"],
            format: :gif,
            image: package_response["ShippingLabel"]["GraphicImage"]
          }

          transaction = Transaction.new(shipment, rate, label)

          {:ok, transaction}

        %{"Code" => code, "Description" => description} ->
          {:error, %{code: code, message: description, service: service}}

        _ ->
          raise "Invalid response: #{response}"
      end
    end
  end

  @impl true
  def cancel_transaction(%Transaction{} = transaction) do
    cancel_transaction(transaction.label.tracking_number)
  end

  @impl true
  def cancel_transaction(_shipment, tracking_number) do
    void_params = %{
      VoidShipmentRequest: %{
        Request: %{},
        VoidShipment: %{
          ShipmentIdentificationNumber: tracking_number
        }
      }
    }

    params =
      Map.new()
      |> Map.merge(security_params())
      |> Map.merge(void_params)

    response = Client.post("/Void", params, [{"Content-Type", "application/json"}])

    with_response response do
      body = response.body["VoidShipmentResponse"]

      case body["SummaryResult"]["Status"] do
        %{"Code" => "1"} ->
          {:ok, "Voided successfully."}

        %{"Code" => _code, "Description" => description} ->
          {:error, description}

        _ ->
          {:error, "Invalid response from UPS."}
      end
    end
  end

  @impl true
  def services_country?(_country_code) do
    # TODO
    true
  end

  @impl true
  def validate_address(%Address{} = address) do
    state =
      case address.state do
        nil -> nil
        _ -> state_without_country(address)
      end

    xav_params = %{
      XAVRequest: %{
        Request: %{
          RequestOption: "1"
        },
        MaximumListSize: "10",
        AddressKeyFormat: %{
          AddressLine: address.address,
          PoliticalDivision2: address.city,
          PoliticalDivision1: state,
          PostcodePrimaryLow: address.zip,
          CountryCode: address.country
        }
      }
    }

    params =
      Map.new()
      |> Map.merge(security_params())
      |> Map.merge(xav_params)

    response = Client.post("/XAV", params, [{"Content-Type", "application/json"}])

    with_response response do
      body = response.body["XAVResponse"]

      if Map.has_key?(body, "NoCandidatesIndicator") do
        {:error, %{code: 2001, description: "Invalid address."}}
      else
        candidates = List.flatten([body["Candidate"] || []])

        candidates =
          Enum.map(candidates, fn candidate ->
            candidate = candidate["AddressKeyFormat"]

            Address.new!(%{
              "first_name" => address.first_name,
              "last_name" => address.last_name,
              "name" => address.name,
              "company_name" => address.company_name,
              "phone" => address.phone,
              "address" => candidate["AddressLine"],
              "address_line_2" => address.address_line_2,
              "city" => candidate["PoliticalDivision2"],
              "state" => candidate["PoliticalDivision1"],
              "zip" => candidate["PostcodePrimaryLow"],
              "country" => candidate["CountryCode"]
            })
          end)

        {:ok, candidates}
      end
    end
  end

  defp security_params do
    config = config()

    %{
      UPSSecurity: %{
        UsernameToken: %{
          Username: config.username,
          Password: config.password
        },
        ServiceAccessToken: %{
          AccessLicenseNumber: config.secret_key
        }
      }
    }
  end

  defp rate_request_params(%Shipment{} = shipment, %Service{} = service) do
    %{
      RateRequest: %{
        Request: %{
          RequestOption: "Rate"
        },
        Shipment: shipment_params(shipment, service)
      }
    }
  end

  defp shipment_request_params(%Shipment{} = shipment, %Service{} = service) do
    shipment_data =
      shipment_params(shipment, service)
      |> Map.merge(%{
        PaymentInformation: %{
          ShipmentCharge: %{
            Type: "01",
            BillShipper: %{
              AccountNumber: config().shipper.account_number
            }
          }
        }
      })

    %{
      ShipmentRequest: %{
        Request: %{
          RequestOption: "validate"
        },
        Shipment: shipment_data
      },
      LabelSpecification: %{
        LabelImageFormat: %{
          Code: "GIF"
        }
      }
    }
  end

  defp shipment_params(%Shipment{} = shipment, %Service{} = service) do
    from = shipment.from
    to = shipment.to

    params = %{
      Description: shipment.package.description,
      Shipper: shipper_address_params(),
      ShipFrom: address_params(from),
      ShipTo: address_params(to),
      Package: package_params(shipment),
      Service: service_params(service)
    }

    if not is_nil(shipment.package.monetary_value) do
      %{
        InvoiceLineTotal: %{
          CurrencyCode: Shippex.currency_code(),
          MonetaryValue: to_string(shipment.package.monetary_value)
        }
      }
    end
    |> case do
      nil -> params
      merge -> Map.merge(params, merge)
    end
  end

  defp service_params(%Service{} = service) do
    code = Service.service_code(service)
    %{Code: code, Description: service.description}
  end

  defp address_params(%Address{} = address) do
    state =
      case address.state do
        nil -> nil
        _ -> state_without_country(address)
      end

    %{
      Name: address.name,
      AttentionName: address.name,
      Phone: %{Number: address.phone},
      Address: %{
        AddressLine: Address.address_line_list(address),
        City: address.city,
        StateProvinceCode: state,
        PostalCode: String.replace(address.zip, ~r/\s+/, ""),
        CountryCode: address.country
      }
    }
  end

  defp shipper_address_params() do
    config = config()

    address =
      Address.new!(%{
        "name" => config.shipper.name,
        "phone" => config.shipper.phone,
        "address" => config.shipper.address,
        "address_line_2" => config.shipper[:address_line_2],
        "city" => config.shipper.city,
        "state" => config.shipper.state,
        "zip" => config.shipper.zip,
        "country" => config.shipper[:country]
      })

    address
    |> address_params
    |> Map.put(:ShipperNumber, config.shipper.account_number)
  end

  defp package_params(%Shipment{} = shipment) do
    package = shipment.package

    [len, width, height] =
      case Application.get_env(:shippex, :distance_unit, :in) do
        :in ->
          [package.length, package.width, package.height]

        :cm ->
          [package.length, package.width, package.height]
          |> Enum.map(&Shippex.Util.cm_to_inches(&1))

        u ->
          raise """
          Invalid unit of measurement specified: #{IO.inspect(u)}

          Must be either :in or :cm
          """
      end

    weight =
      case Application.get_env(:shippex, :weight_unit, :lbs) do
        :lbs ->
          package.weight

        :kg ->
          Shippex.Util.kgs_to_lbs(package.weight)

        u ->
          raise """
          Invalid unit of measurement specified: #{IO.inspect(u)}

          Must be either :lbs or :kg
          """
      end

    %{
      Packaging: %{Code: "02", Description: "Rate"},
      PackagingType: %{Code: "02", Description: "Rate"},
      Dimensions: %{
        UnitOfMeasurement: %{Code: "IN"},
        Length: "#{len}",
        Width: "#{width}",
        Height: "#{height}"
      },
      PackageWeight: %{
        UnitOfMeasurement: %{Code: "LBS"},
        Weight: "#{weight}"
      }
    }
  end

  defmodule Client do
    @moduledoc false
    use HTTPoison.Base

    # HTTPoison implementation
    def process_url(endpoint), do: base_url() <> endpoint
    def process_request_body(body), do: Jason.encode!(body)
    def process_response_body(body), do: Jason.decode!(body)

    defp base_url do
      case Shippex.env() do
        :prod -> "https://onlinetools.ups.com/rest"
        _ -> "https://wwwcie.ups.com/rest"
      end
    end
  end

  defdelegate config(), to: Shippex.Config, as: :ups_config
end
