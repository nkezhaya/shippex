defmodule Shippex.Address do
  @moduledoc """
  Represents an address that can be passed to other `Shippex` functions. Do
  *not* initialize this struct directly. Instead, use `to_struct/1`.
  """

  @type t :: %__MODULE__{}

  @enforce_keys [:name, :phone, :address, :address_line_2, :city, :state, :zip]
  defstruct [:name, :phone, :address, :address_line_2, :city, :state, :zip]

  alias __MODULE__, as: Address
  alias Shippex.Util

  @doc """
  Initializes an `Address` struct from the given `params`, and performs minor
  validations that do not require any service requests.

      Shippex.Address.to_struct(%{
        name: "Earl G",
        phone: "123-123-1234",
        address: "9999 Hobby Lane",
        address_line_2: nil,
        city: "Austin",
        state: "TX",
        zip: "78703"
      })
  """
  @spec to_struct(map()) :: t
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

  @doc """
  Returns the list of non-`nil` address lines. If no `address_line_2` is
  present, it returns a list of a single `String`.
  """
  @spec address_line_list(t) :: [String.t]
  def address_line_list(%Shippex.Address{} = address) do
    [address.address,
      address.address_line_2]
      |> Enum.reject(&is_nil/1)
  end
end
