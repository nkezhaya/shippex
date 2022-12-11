defmodule Shippex.Carrier.Dummy do
  @moduledoc false
  @behaviour Shippex.Carrier

  @impl true
  def fetch_rates(_arg) do
    [
      {:high, rate()}
    ]
  end

  @impl true
  def fetch_rate(arg, _arg2), do: fetch_rates(arg)

  @impl true
  def create_transaction(_arg1, _arg2) do
    {:shipment,
     %Shippex.Transaction{shipment: shipment(), rate: rate(), label: nil, carrier: carrier()}}
  end

  @impl true
  def cancel_transaction(_arg) do
    {:cancelled, "cancelled"}
  end

  @impl true
  def cancel_transaction(_arg1, _arg2) do
    {:cancelled, "cancelled"}
  end

  @impl true
  def validate_address(address), do: {:ok, [address]}

  @impl true
  @not_serviced ~w(AN AQ BV EH KP HM IO PN SO SJ SY SZ TF YE YU)
  def services_country?(country) when country in @not_serviced do
    false
  end

  def services_country?(_country) do
    true
  end

  @impl true
  def track_parcels(tracking_numbers) do
    {:ok, tracking_numbers}
  end

  defp rate() do
    {carrier, _} = carrier()
    %Shippex.Rate{
      service: %Shippex.Service{
        id: :dummy,
        carrier: carrier,
        description: "Dummy Shipping Service"
      },
      price: 1000,
      line_items: nil
    }
  end

  defp shipment() do
  end

  @impl true
  def carrier() do
    :dummy
  end

end
