defmodule ExShip.Carrier.UPS do
  @moduledoc false
  @behaviour ExShip.Carrier

  import ExShip.Address, only: [state_without_country: 1]

  alias ExShip.Carrier.UPS.Client
  alias ExShip.{Address, Config, InvalidConfigError, Shipment, Service, Transaction, Util}

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

          rate = %ExShip.Rate{service: service, price: price, line_items: []}

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

          rate = %ExShip.Rate{service: service, price: price, line_items: []}

          package_response = results["PackageResults"]

          label = %ExShip.Label{
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
  def track_packages(_tracking_numbers) do
    # TODO
    raise "Not yet implemented for UPS"
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
          PostcodePrimaryLow: address.postal_code,
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
              "postal_code" => candidate["PostcodePrimaryLow"],
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
    package = List.first(shipment.packages)

    params = %{
      Description: package.description,
      Shipper: shipper_address_params(),
      ShipFrom: address_params(from),
      ShipTo: address_params(to),
      Package: package_params(package),
      Service: service_params(service)
    }

    if not is_nil(package.monetary_value) do
      %{
        InvoiceLineTotal: %{
          CurrencyCode: ExShip.currency_code(),
          MonetaryValue: to_string(package.monetary_value)
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
        PostalCode: String.replace(address.postal_code, ~r/\s+/, ""),
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
        "postal_code" => config.shipper.postal_code,
        "country" => config.shipper[:country]
      })

    address
    |> address_params
    |> Map.put(:ShipperNumber, config.shipper.account_number)
  end

  defp package_params(package) do
    [len, width, height] =
      case Application.get_env(:exship, :distance_unit, :in) do
        :in ->
          [package.length, package.width, package.height]

        :cm ->
          [package.length, package.width, package.height]
          |> Enum.map(&ExShip.Util.cm_to_inches(&1))

        u ->
          raise """
          Invalid unit of measurement specified: #{IO.inspect(u)}

          Must be either :in or :cm
          """
      end

    weight =
      case Application.get_env(:exship, :weight_unit, :lbs) do
        :lbs ->
          package.weight

        :kg ->
          ExShip.Util.kgs_to_lbs(package.weight)

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
      case ExShip.env() do
        :prod -> "https://onlinetools.ups.com/rest"
        _ -> "https://wwwcie.ups.com/rest"
      end
    end
  end

  def config() do
    with cfg when is_list(cfg) <-
           Keyword.get(Config.config(), :ups, {:error, :not_found}),
         sk when is_binary(sk) <-
           Keyword.get(cfg, :secret_key, {:error, :not_found, :secret_key}),
         sh when is_map(sh) <- Keyword.get(cfg, :shipper, {:error, :not_found, :shipper}),
         an when is_binary(an) <-
           Keyword.get(cfg, :shipper)
           |> Map.get(:account_number, {:error, :not_found, :account_number}),
         un when is_binary(an) <- Keyword.get(cfg, :username, {:error, :not_found, :username}),
         pw when is_binary(pw) <- Keyword.get(cfg, :password, {:error, :not_found, :password}) do
      %{
        username: un,
        password: pw,
        secret_key: sk,
        shipper: sh
      }
    else
      {:error, :not_found, :shipper} ->
        raise InvalidConfigError,
          message:
            "UPS shipper config key missing. This could be because was provided as a keyword list instead of a map."

      {:error, :not_found, token} ->
        raise InvalidConfigError, message: "UPS config key missing: #{token}"

      {:error, :not_found} ->
        raise InvalidConfigError, message: "UPS config is either invalid or not found."
    end
  end

  @impl true
  def carrier() do
    :ups
  end
end
