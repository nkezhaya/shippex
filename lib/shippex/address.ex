defmodule Shippex.Address do
  @moduledoc """
  Represents an address that can be passed to other `Shippex` functions. Do
  *not* initialize this struct directly. Instead, use `address/1`.
  """

  @type t :: %__MODULE__{}

  @enforce_keys [:first_name, :last_name, :name, :phone, :address, :address_line_2, :city, :state, :zip, :country]
  defstruct [:first_name, :last_name, :name, :company_name, :phone, :address, :address_line_2, :city, :state, :zip, :country]

  alias __MODULE__, as: Address
  alias Shippex.Util

  @doc """
  Initializes an `Address` struct from the given `params`, and performs minor
  validations that do not require any service requests.

  You may specify `first_name` and `last_name` separately, which will be
  concatenated to make the `name` property, or just specify `name` directly.

  If `name` is specified directly, Shippex will try to infer the first and last
  names in case they're required separately for API calls.

      Shippex.Address.address(%{
        first_name: "Earl",
        last_name: "Grey",
        phone: "123-123-1234",
        address: "9999 Hobby Lane",
        address_line_2: nil,
        city: "Austin",
        state: "TX",
        zip: "78703"
      })
  """
  @spec address(map()) :: t | none
  def address(params) when is_map(params) do
    params = for {key, val} <- params, into: %{} do
      key = cond do
        is_atom(key) -> Atom.to_string(key)
        true -> key
      end

      val = cond do
        is_bitstring(val) -> String.trim(val)
        true -> val
      end

      {key, val}
    end

    {first_name, last_name, name} = cond do
      not(is_nil(params["first_name"]) or is_nil(params["last_name"])) ->
        name = params["first_name"] <> " " <> params["last_name"]
        {params["first_name"], params["last_name"], name}
      not is_nil(params["name"]) ->
        names = String.split(params["name"])
        first_name = hd names
        last_name = Enum.join(tl(names), " ")
        {first_name, last_name, params["name"]}
      true ->
        {nil, nil, nil}
    end

    address = %Address{
      name: name,
      first_name: first_name,
      last_name: last_name,
      company_name: params["company_name"],
      phone: params["phone"],
      address: params["address"],
      address_line_2: params["address_line_2"],
      city: params["city"],
      state: Util.full_state_to_abbreviation(params["state"]),
      zip: String.replace(params["zip"], ~r/\s+/, ""),
      country: params["country"] || "US"
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
