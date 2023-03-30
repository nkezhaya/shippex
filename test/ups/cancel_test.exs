defmodule ExShip.UPS.CancellationTest do
  use ExUnit.Case

  setup do
    [shipment: Helper.valid_shipment]
  end

  test "successfully void shipment label", %{shipment: shipment} do
    tracking_number = "1Z2220060290602143"

    {:ok, _} = ExShip.cancel_transaction(:ups, shipment, tracking_number)
  end
end
