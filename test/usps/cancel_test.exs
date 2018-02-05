defmodule Shippex.USPS.CancelTest do
  use ExUnit.Case

  setup do
    [shipment: Helper.valid_shipment]
  end

  test "cancel domestic transaction" do
    Shippex.Shipment.shipment(Helper.origin(), Helper.destination(), Helper.package())
    |> cancel_shipment()
  end

  test "cancel international transaction" do
    Shippex.Shipment.shipment(Helper.origin(), Helper.destination("MX"), Helper.package())
    |> cancel_shipment()
  end

  defp cancel_shipment(shipment) do
    rates = Shippex.Carrier.USPS.fetch_rate(shipment, :all)

    rate =
      rates
      |> Enum.filter(fn {code, _} -> code == :ok end)
      |> Enum.filter(fn {_, rate} ->
        rate.service.id in ~w(usps_priority usps_priority_express usps_parcel_ground)a
      end)
      |> Enum.map(fn {_, rate} -> rate end)
      |> Enum.shuffle
      |> hd

    {:ok, transaction} = Shippex.Carrier.USPS.create_transaction(shipment, rate.service)

    tracking_number = transaction.label.tracking_number
    {:ok, _} = Shippex.Carrier.USPS.cancel_transaction(shipment, tracking_number)

    # Try again
    {:error, reason} = Shippex.Carrier.USPS.cancel_transaction(shipment, tracking_number)

    assert reason =~ ~r/already/i
  end
end
