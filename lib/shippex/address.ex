defmodule Shippex.Address do
  @enforce_keys [:name, :phone, :address, :address_line_2, :city, :state, :zip]
  defstruct [:name, :phone, :address, :address_line_2, :city, :state, :zip]

  alias __MODULE__, as: Address
  alias Shippex.Util

  def to_struct(params) when is_map(params) do
    address = %Address{
      name: params["name"],
      phone: params["phone"],
      address: params["address"],
      address_line_2: params["address_line_2"],
      city: params["city"],
      state: Util.full_state_to_abbreviation(params["state"]),
      zip: params["zip"]
    }

    # Check for a passed array.
    address = case params["address"] do
      [line1] -> Map.put(address, :address, line1)

      [line1, line2 | _] ->
        address
        |> Map.put(:address, line1)
        |> Map.put(:address_line_2, line2)

      _ -> address
    end

    address
  end

  def address_line_list(%Shippex.Address{} = address) do
    [address.address,
      address.address_line_2]
      |> Enum.reject(&is_nil/1)
  end
end
