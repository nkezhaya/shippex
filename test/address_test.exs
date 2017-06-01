defmodule AddressTest do
  use ExUnit.Case
  doctest Shippex

  test "address shortens the full state" do
    address = Shippex.Address.to_struct(%{
      "name" => "Earl G",
      "address" => "9999 Hobby Ln",
      "city" => "Austin",
      "state" => "Texas",
      "zip" => "78703"
    })

    assert address.state == "TX"
  end

  test "address handles the address formatting" do
    address_line_1 = "9999 Hobby Ln"
    address_line_2 = "Ste 900"

    address = Shippex.Address.to_struct(%{
      "address" => [address_line_1, address_line_2],
      "city" => "Austin",
      "state" => "Texas",
      "zip" => "78703"
    })

    assert address.address == address_line_1
    assert address.address_line_2 == address_line_2
  end

  test "validate address" do
    # UPS only validates CA/NY addresses in testing.

    name = "Earl G"
    phone = "123-456-7890"
    valid_address = Shippex.Address.to_struct(%{
      "name" => name,
      "phone" => phone,
      "address" => "404 S Figueroa St",
      "address_line_2" => "Suite 101",
      "city" => "Los Angeles",
      "state" => "CA",
      "zip" => "90071"
    })

    assert valid_address.address_line_2 == "Suite 101"

    {:ok, candidates} = Shippex.Carrier.UPS.validate_address(valid_address)
    assert length(candidates) == 1
    assert hd(candidates).name == name
    assert hd(candidates).phone == phone

    Enum.each candidates, fn(candidate) ->
      assert candidate.address_line_2 == "Suite 101"
    end

    ambiguous_address = Shippex.Address.to_struct(%{
      "address" => "404 S Figaro St",
      "address_line_2" => "Suite 101",
      "city" => "Los Angeles",
      "state" => "CA",
      "zip" => "90071"
    })

    {:ok, candidates} = Shippex.Carrier.UPS.validate_address(ambiguous_address)
    assert length(candidates) > 1

    invalid_address = Shippex.Address.to_struct(%{
      "address" => "9999 Wat Wat",
      "city" => "San Francisco",
      "state" => "CA",
      "zip" => "90071"
    })

    {:error, _} = Shippex.Carrier.UPS.validate_address(invalid_address)
  end
end
