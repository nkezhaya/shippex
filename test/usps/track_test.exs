defmodule Shippex.USPS.TrackTest do
  use ExUnit.Case

  alias Shippex.Carrier.USPS

  setup do
    [shipment: Helper.valid_shipment()]
  end

  test "track package", %{shipment: shipment} do
    {:ok, transaction} = USPS.create_transaction(shipment, :usps_priority)

    # Not yet available
    assert {:error, %{code: "-2147219283"}} =
             USPS.track_packages(transaction.label.tracking_number)
  end
end
