defmodule Shippex.UPS.AddressTest do
  use ExUnit.Case

  test "validate address" do
    # UPS only validates CA/NY addresses in testing.

    name = "Earl G"
    phone = "123-456-7890"
    valid_address = Shippex.Address.address(%{
      "name" => name,
      "phone" => phone,
      "address" => "404 S Figueroa St",
      "address_line_2" => "Suite 101",
      "city" => "Los Angeles",
      "state" => "CA",
      "zip" => "90071"
    })

    assert valid_address.address_line_2 == "Suite 101"

    {:ok, candidates} = Shippex.validate_address(valid_address, carrier: :ups)
    assert length(candidates) == 1
    assert hd(candidates).name == name
    assert hd(candidates).phone == phone

    Enum.each candidates, fn(candidate) ->
      assert candidate.address_line_2 == "Suite 101"
    end

    ambiguous_address = Shippex.Address.address(%{
      "address" => "404 S Figaro St",
      "address_line_2" => "Suite 101",
      "city" => "Los Angeles",
      "state" => "CA",
      "zip" => "90071"
    })

    {:ok, candidates} = Shippex.validate_address(ambiguous_address, carrier: :ups)
    assert length(candidates) > 1

    invalid_address = Shippex.Address.address(%{
      "address" => "9999 Wat Wat",
      "city" => "San Francisco",
      "state" => "CA",
      "zip" => "90071"
    })

    {:error, _} = Shippex.validate_address(invalid_address, carrier: :ups)

    invalid_address = Shippex.Address.address(%{
      "name" => name,
      "phone" => phone,
      "address" => "404 S Figueroa St",
      "address_line_2" => "Suite 101",
      "city" => "Los Angeles",
      "state" => "BC",
      "zip" => "90071",
      "country" => "US"
    })

    {:error, _} = Shippex.validate_address(invalid_address, carrier: :ups)

    invalid_address = Shippex.Address.address(%{
      "name" => name,
      "phone" => phone,
      "address" => "404 S Figueroa St",
      "address_line_2" => "Suite 101",
      "city" => "Los Angeles",
      "state" => "BX",
      "zip" => "90071",
      "country" => "MX"
    })

    {:error, _} = Shippex.validate_address(invalid_address, carrier: :ups)
  end
end
