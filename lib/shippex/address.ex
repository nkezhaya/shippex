defmodule Shippex.Address do
  @moduledoc """
  Represents an address that can be passed to other `Shippex` functions. Do
  *not* initialize this struct directly. Instead, use `address/1`.
  """

  @enforce_keys ~w(first_name last_name name phone address address_line_2 city
                   state zip country)a

  defstruct ~w(first_name last_name name company_name phone address
               address_line_2 city state zip country)a

  @type t() :: %__MODULE__{
          first_name: nil | String.t(),
          last_name: nil | String.t(),
          name: nil | String.t(),
          company_name: nil | String.t(),
          phone: nil | String.t(),
          address: String.t(),
          address_line_2: nil | String.t(),
          city: String.t(),
          state: String.t(),
          zip: String.t(),
          country: ISO.country_code()
        }

  alias __MODULE__, as: Address
  alias Shippex.ISO

  @default_country "US"

  @doc """
  Initializes an `Address` struct from the given `params`, and performs minor
  validations that do not require any service requests.

  You may specify `first_name` and `last_name` separately, which will be
  concatenated to make the `name` property, or just specify `name` directly.

  If `name` is specified directly, Shippex will try to infer the first and last
  names in case they're required separately for API calls.

      Shippex.Address.new(%{
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
  @spec new(map()) :: {:ok, t()} | {:error, String.t()}
  def new(params) when is_map(params) do
    params =
      for {key, val} <- params, into: %{} do
        key =
          cond do
            is_atom(key) -> Atom.to_string(key)
            true -> key
          end

        val =
          cond do
            is_bitstring(val) -> String.trim(val)
            true -> val
          end

        {key, val}
      end

    {first_name, last_name, name} =
      cond do
        not (is_nil(params["first_name"]) or is_nil(params["last_name"])) ->
          name = params["first_name"] <> " " <> params["last_name"]
          {params["first_name"], params["last_name"], name}

        not is_nil(params["name"]) ->
          names = String.split(params["name"])
          first_name = hd(names)
          last_name = Enum.join(tl(names), " ")
          {first_name, last_name, params["name"]}

        true ->
          {nil, nil, nil}
      end

    {state, country} =
      case ISO.find_subdivision_code(params["country"] || @default_country, params["state"]) do
        {:ok, state} -> {state, String.slice(state, 0, 2)}
        {:error, error} -> throw({:invalid_state_and_country, error})
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
      state: state,
      zip: String.trim(params["zip"] || ""),
      country: country
    }

    # Check for a passed array.
    address =
      case params["address"] do
        [line1] ->
          Map.put(address, :address, line1)

        [line1, line2 | _] ->
          address
          |> Map.put(:address, line1)
          |> Map.put(:address_line_2, line2)

        _ ->
          address
      end

    {:ok, address}
  catch
    {:invalid_state_and_country, error} -> {:error, error}
  end

  @doc """
  Calls `new/1` and raises an error on failure.
  """
  @spec new!(map()) :: t() | none()
  def new!(params) do
    case new(params) do
      {:ok, address} -> address
      {:error, error} -> raise error
    end
  end

  @doc false
  def validate(%__MODULE__{} = address, opts) do
    carrier = Keyword.get(opts, :carrier, :usps)

    case address.country do
      "US" ->
        Shippex.Carrier.module(carrier).validate_address(address)

      _country ->
        {:ok, [address]}
    end
  end

  @doc """
  Returns the list of non-`nil` address lines. If no `address_line_2` is
  present, it returns a list of a single `String`.
  """
  @spec address_line_list(t()) :: [String.t()]
  def address_line_list(%Address{} = address) do
    [address.address, address.address_line_2]
    |> Enum.reject(&is_nil/1)
  end

  @doc """
  Returns the state code without its country code prefix.

      iex> address = Shippex.Address.new!(%{
      ...>   first_name: "Earl",
      ...>   last_name: "Grey",
      ...>   phone: "123-123-1234",
      ...>   address: "9999 Hobby Lane",
      ...>   address_line_2: nil,
      ...>   city: "Austin",
      ...>   state: "US-TX",
      ...>   zip: "78703",
      ...>   country: "US"
      ...>  })
      iex> Address.state_without_country(address)
      "TX"
  """
  @spec state_without_country(t() | %{state: String.t(), country: String.t()}) :: String.t()
  def state_without_country(%{state: state, country: country}) do
    String.replace(state, "#{country}-", "")
  end

  @doc """
  Returns a common country name for the given country code.  This removes
  occurrences of `"(the)"` that may be present in the ISO-3166-2 data. For
  example, the code "US" normally maps to "United States of America (the)". We
  can shorten this with:

      iex> Address.common_country_name("US")
      "United States"
  """
  @common_names %{
    "US" => "United States"
  }

  @spec common_country_name(String.t()) :: String.t()

  for {code, name} <- @common_names do
    def common_country_name(unquote(code)), do: unquote(name)
  end

  def common_country_name(code) do
    code
    |> ISO.country_code_to_name()
    |> String.replace("(the)", "")
    |> String.trim()
  end

  @doc """
  Returns the country code for the given common name, or nil if none was found.

      iex> Address.common_country_code("United States")
      "US"
      iex> Address.common_country_code("United States of America")
      "US"
  """
  @spec common_country_code(String.t()) :: nil | String.t()
  for {code, name} <- @common_names do
    def common_country_code(unquote(name)), do: unquote(code)
  end

  def common_country_code(common_name) do
    ISO.country_code(common_name)
  end

  @doc """
  Returns `true` if addresses for the country require a province, state, or
  other subdivision to be specified to validate addresses.

      iex> Address.subdivision_required?("US")
      true

      iex> Address.subdivision_required?("CN")
      true

      iex> Address.subdivision_required?("SG")
      false
  """
  @spec subdivision_required?(ISO.country_code()) :: boolean()

  for country_code <- ~w(AU CA CN ES IT MX MY US) do
    def subdivision_required?(unquote(country_code)), do: true
  end

  def subdivision_required?(_) do
    false
  end
end
