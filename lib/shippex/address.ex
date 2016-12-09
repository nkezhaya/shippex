defmodule Shippex.Address do
  defstruct [:name, :phone, :address, :address_line_2, :city, :state, :zip]

  def address_line_list(%Shippex.Address{} = address) do
    [address.address,
      address.address_line_2]
      |> Enum.filter(fn (ln) -> not is_nil(ln) end)
  end
end
