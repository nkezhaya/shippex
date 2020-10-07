defmodule Shippex.Carrier.Dummy do
  @behaviour Shippex.Carrier

  def fetch_rates(_arg) do
    [
      {:high, rate()}
    ]
  end

  def fetch_rate(arg, _arg2), do: fetch_rates(arg)

  def create_transaction(_arg1, _arg2) do
    {:shipment,
     %Shippex.Transaction{shipment: shipment(), rate: rate(), label: nil, carrier: carrier()}}
  end

  def cancel_transaction(_arg) do
    {:cancelled, "cancelled"}
  end

  def cancel_transaction(_arg1, _arg2) do
    {:cancelled, "cancelled"}
  end

  def validate_address(address), do: {:ok, [address]}

  defp rate() do
    %Shippex.Rate{
      service: %Shippex.Service{
        id: :dummy,
        carrier: carrier(),
        description: "Dummy Shipping Service"
      },
      price: 1000,
      line_items: nil
    }
  end

  defp shipment() do
  end

  defp carrier() do
    :dummy
  end
end
