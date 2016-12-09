defmodule Shippex.Address do
  @enforce_keys [:name, :address, :city, :state, :zip]
  defstruct [:name, :phone, :address, :address_line_2, :city, :state, :zip]

  alias __MODULE__, as: Address

  def to_struct(params) when is_map(params) do
    %Address{
      address: params["address"],
      address_line_2: params["address_line_2"],
      city: params["city"],
      state: Util.full_state_to_abbreviation(params["state"]),
      zip: params["zip"]
    }
  end

  def address_line_list(%Shippex.Address{} = address) do
    [address.address,
      address.address_line_2]
      |> Enum.filter(fn (ln) -> not is_nil(ln) end)
  end
end
