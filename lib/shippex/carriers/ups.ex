defmodule Shippex.Carriers.UPS do
  use HTTPoison.Base

  def fetch_rates(%Shippex.Shipment{} = shipment) do
    services = Shippex.Service.services_for_carrier(:ups)

    Enum.map services, fn (service) ->
      fetch_rate(shipment, service)
    end
  end

  def fetch_rate(%Shippex.Shipment{} = shipment, %Shippex.Service{} = service) do
    alias Decimal, as: D

    params = Map.new
      |> Map.merge(security_params)
      |> Map.merge(rate_request_params(shipment, service))

    {:ok, response} = post("/Rate", params, [{"Content-Type", "application/json"}])

    fault = response.body["Fault"]

    if is_nil(fault) do
      body = response.body["RateResponse"]

      case body["Response"]["ResponseStatus"] do
        %{"Code" => "1", "Description" => "Success"} ->
          price = body["RatedShipment"]["TotalCharges"]["MonetaryValue"]
            |> D.new
            |> D.mult(D.new(100))

          rate = %Shippex.Rate{service: service, price: price}

          {:ok, rate}

        %{"Code" => code, "Description" => description} ->
          {:error, %{code: code, message: description}}
      end
    else
      error = fault["detail"]["Errors"]["ErrorDetail"]["PrimaryErrorCode"]
      {:error, %{code: error["Code"], message: error["Description"]}}
    end
  end

  def fetch_label(%Shippex.Rate{} = rate, %Shippex.Shipment{} = shipment) do
    params = Map.new
      |> Map.merge(security_params)
      |> Map.merge(shipment_request_params(shipment, rate.service))

    {:ok, response} = post("/Ship", params, [{"Content-Type", "application/json"}])

    fault = response.body["Fault"]

    if is_nil(fault) do
      body = response.body["ShipmentResponse"]

      case body["Response"]["ResponseStatus"] do
        %{"Code" => "1", "Description" => "Success"} ->

          package_response = body["ShipmentResults"]["PackageResults"]
          label = %Shippex.Label{tracking_number: package_response["TrackingNumber"],
                                 format: "gif",
                                 image: package_response["ShippingLabel"]["GraphicImage"]}

          {:ok, label}

        %{"Code" => code, "Description" => description} ->
          {:error, %{code: code, message: description}}

        _ -> raise "Invalid response: #{response}"
      end
    else
      error = fault["detail"]["Errors"]["ErrorDetail"]["PrimaryErrorCode"]
      {:error, %{code: error["Code"], message: error["Description"]}}
    end
  end

  # HTTPoison implementation
  def process_url(endpoint), do: base_url <> endpoint
  def process_request_body(body), do: Poison.encode!(body)
  def process_response_body(body), do: Poison.decode!(body)

  defp base_url do
    case Mix.env do
      :prod -> "https://onlinetools.ups.com/rest"
      _     -> "https://wwwcie.ups.com/rest"
    end
  end

  defp security_params do
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

  defp rate_request_params(%Shippex.Shipment{} = shipment, %Shippex.Service{} = service) do
    %{
      RateRequest: %{
        Request: %{
          RequestOption: "Rate"
        },
        Shipment: shipment_params(shipment, service)
      }
    }
  end

  defp shipment_request_params(%Shippex.Shipment{} = shipment, %Shippex.Service{} = service) do
    shipment_data = shipment_params(shipment, service)
      |> Map.merge(%{
        PaymentInformation: %{
          ShipmentCharge: %{
            Type: "01",
            BillShipper: %{
              AccountNumber: config.shipper_number
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

  defp shipment_params(%Shippex.Shipment{} = shipment, %Shippex.Service{} = service) do
    %{
      Description: shipment.package.description,

      Shipper: address_params(shipment.from, include_shipper_number: true),
      ShipFrom: address_params(shipment.from),
      ShipTo: address_params(shipment.to),

      Package: package_params(shipment.package),
      Service: service_params(service)
    }
  end

  defp service_params(%Shippex.Service{} = service) do
    %{
      Code: service.code,
      Description: service.description
    }
  end

  defp address_params(%Shippex.Address{} = address, options \\ []) do
    params = %{
      Name: address.name,
      Phone: %{
        Number: address.phone
      },
      Address: %{
        AddressLine: Shippex.Address.address_line_list(address),
        City: address.city,
        StateProvinceCode: address.state,
        PostalCode: address.zip,
        CountryCode: "US"
      }
    }

    case Keyword.get(options, :include_shipper_number) do
      true -> Map.put(params, :ShipperNumber, config.shipper_number)
      _    -> params
    end
  end

  defp package_params(%Shippex.Package{} = package) do
    %{
      Packaging: %{
        Code: "02",
        Description: "Rate"
      },
      PackagingType: %{
        Code: "02",
        Description: "Rate"
      },
      Dimensions: %{
        UnitOfMeasurement: %{
          Code: "IN",
          Description: "inches"
        },
        Length: "#{package.length}",
        Width: "#{package.width}",
        Height: "#{package.height}"
      },
      PackageWeight: %{
        UnitOfMeasurement: %{
          Code: "LBS",
          Description: "pounds"
        },
        Weight: "#{package.weight}"
      }
    }
  end

  defp config do
    with cfg when is_list(cfg) <- Keyword.get(Shippex.config, :ups, {:error, :not_found}),

         sk <- Keyword.get(cfg, :secret_key,      {:error, :not_found, :secret_key}),
         sn <- Keyword.get(cfg, :shipper_number,  {:error, :not_found, :shipper_number}),
         un <- Keyword.get(cfg, :username,        {:error, :not_found, :username}),
         pw <- Keyword.get(cfg, :password,        {:error, :not_found, :password}) do

         %{
           username: un,
           password: pw,
           secret_key: sk,
           shipper_number: sn
         }
    else
      {:error, :not_found, token} -> raise Shippex.InvalidConfigError,
        message: "UPS config key missing: #{token}"

      {:error, :not_found} -> raise Shippex.InvalidConfigError,
        message: "UPS config is either invalid or not found."
    end
  end
end
