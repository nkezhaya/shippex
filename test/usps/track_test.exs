defmodule ExShip.USPS.TrackTest do
  use ExUnit.Case

  alias ExShip.Carrier.USPS

  setup do
    [shipment: Helper.valid_shipment()]
  end

  test "track package", %{shipment: shipment} do
    {:ok, transaction} = USPS.create_transaction(shipment, :usps_priority)

    # Not yet available. USPS doesn't provide test tracking numbers, so there's
    # no way to test a success case.
    assert {:error, %{code: "-2147219283"}} =
             USPS.track_packages(transaction.label.tracking_number)
  end
end
