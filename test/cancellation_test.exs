defmodule CancellationTest do
  use ExUnit.Case
  doctest Shippex

  setup do
    [shipment: Helper.valid_shipment]
  end

  test "successfully void shipment label", %{shipment: shipment} do
    label = %Shippex.Label{
      tracking_number: "1Z2220060290602143"
    }

    {:ok, label} = Shippex.cancel_shipment(label)
    assert label
  end
end
