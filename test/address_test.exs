defmodule AddressTest do
  use ExUnit.Case
  doctest Shippex

  test "address creates a validated struct" do
    address = Shippex.Address.to_struct(%{
      "name" => "Earl G",
      "address" => "9999 Hobby Ln",
      "city" => "Austin",
      "state" => "Texas",
      "zip" => "78703"
    })

    assert address.state == "TX"
  end
end
