defmodule CancellationTest do
  use ExUnit.Case
  doctest Shippex

  test "successfully void shipment label" do
    label = %Shippex.Label{
      tracking_number: "1Z2220060290602143"
    }

    {:ok, _} = Shippex.cancel_shipment(label)
    {:ok, _} = Shippex.cancel_shipment(label.tracking_number)
  end
end
