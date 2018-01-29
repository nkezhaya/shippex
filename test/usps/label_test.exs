defmodule Shippex.USPS.LabelTest do
  use ExUnit.Case

  setup do
    [shipment: Helper.valid_shipment]
  end

  test "label generated", %{shipment: shipment} do
    package = %{shipment.package | container: :variable}
    shipment = %{shipment | package: package}
    rates = Shippex.Carrier.USPS.fetch_rate(shipment, "priority")
    assert is_list(rates) and length(rates) > 0

    rate =
      rates
      |> Enum.filter(fn {code, _} -> code == :ok end)
      |> Enum.map(fn {_, rate} -> rate end)
      |> Enum.reject(& &1.service.code == "PRIORITY MAIL EXPRESS")
      |> Enum.shuffle
      |> hd

    {:ok, label} = Shippex.Carrier.USPS.fetch_label(shipment, rate.service)

    assert label
    assert label.tracking_number
    assert label.image

    File.write("foo.tiff", :base64.decode(label.image))
  end
end
