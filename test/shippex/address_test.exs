defmodule Shippex.AddressTest do
  use ExUnit.Case

  test "address shortens the full state" do
    address = Shippex.Address.address(%{
      "name" => "Earl G",
      "address" => "9999 Hobby Ln",
      "city" => "Austin",
      "state" => "Texas",
      "zip" => "78703",
      "country" => "US"
    })

    assert address.state == "TX"
    assert address.country == "US"
  end

  test "address handles the address formatting" do
    address_line_1 = "9999 Hobby Ln"
    address_line_2 = "Ste 900"

    address = Shippex.Address.address(%{
      "address" => [address_line_1, address_line_2],
      "city" => "Austin",
      "state" => "Texas",
      "zip" => "78703"
    })

    assert address.address == address_line_1
    assert address.address_line_2 == address_line_2
  end
end
