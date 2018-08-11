defmodule Shippex.Address do
  @moduledoc """
  Represents an address that can be passed to other `Shippex` functions. Do
  *not* initialize this struct directly. Instead, use `address/1`.
  """

  @enforce_keys [
    :first_name,
    :last_name,
    :name,
    :phone,
    :address,
    :address_line_2,
    :city,
    :state,
    :zip,
    :country
  ]
  defstruct [
    :first_name,
    :last_name,
    :name,
    :company_name,
    :phone,
    :address,
    :address_line_2,
    :city,
    :state,
    :zip,
    :country
  ]

  @type t :: %__MODULE__{
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
          country: String.t()
        }

  alias __MODULE__, as: Address
  alias Shippex.ISO

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
      case validated_state_and_country(params["state"], params["country"]) do
        {:ok, state, country} ->
          {state, country}

        {:error, error} ->
          throw({:invalid_state_and_country, error})
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
      zip: String.trim(params["zip"]),
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
    {:invalid_state_and_country, error} ->
      {:error, error}
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
  @spec state_without_country(t()) :: String.t()
  def state_without_country(%Address{state: state, country: country}) do
    String.replace(state, "#{country}-", "")
  end

  @doc """
  Converts a full state name to its 2-letter ISO-3166-2 code. The country MUST
  be an ISO-compliant 2-letter country code.

      iex> Address.state_code("Texas")
      "US-TX"
      iex> Address.state_code("teXaS")
      "US-TX"
      iex> Address.state_code("TX")
      nil
      iex> Address.state_code("AlberTa", "CA")
      "CA-AB"
      iex> Address.state_code("Veracruz", "MX")
      "MX-VER"
      iex> Address.state_code("Yucatán", "MX")
      "MX-YUC"
      iex> Address.state_code("Yucatan", "MX")
      "MX-YUC"
      iex> Address.state_code("YucatAN", "MX")
      "MX-YUC"
      iex> Address.state_code("Not a state.")
      nil
  """
  @spec state_code(String.t(), String.t()) :: nil | String.t()
  def state_code(state, country) when is_bitstring(state) and is_bitstring(country) do
    iso = ISO.data()
    divisions = iso[country]["divisions"]

    cond do
      Map.has_key?(divisions, "#{country}-#{state}") ->
        "#{country}-#{state}"

      Map.has_key?(divisions, state) ->
        state

      true ->
        state = filter_for_comparison(state)

        divisions
        |> Enum.find(fn {_state_code, full_state} ->
          filter_for_comparison(full_state) == state
        end)
        |> case do
          nil -> nil
          {state_code, _full_state} -> state_code
        end
    end
  end

  @doc """
  Converts a full country name to its 2-letter ISO-3166-2 code.

      iex> Address.country_code("United States")
      "US"
      iex> Address.country_code("Mexico")
      "MX"
      iex> Address.country_code("Not a country.")
      nil
  """
  @spec country_code(String.t()) :: nil | String.t()
  def country_code(country) do
    iso = ISO.data()

    if Map.has_key?(iso, country) do
      country
    else
      Enum.find_value(iso, fn
        {code, %{"name" => ^country}} -> code
        _ -> nil
      end)
    end
  end

  @doc """
  Takes a state and country input and returns the validated, ISO-3166-compliant
  results in a tuple.

      iex> Address.validated_state_and_country("TX")
      {"US-TX", "US"}
      iex> Address.validated_state_and_country("TX", "US")
      {"US-TX", "US"}
      iex> Address.validated_state_and_country("US-TX", "US")
      {"US-TX", "US"}
      iex> Address.validated_state_and_country("Texas", "US")
      {"US-TX", "US"}
      iex> Address.validated_state_and_country("Texas", "United States")
      {"US-TX", "US"}
  """
  @spec validated_state_and_country(any, any) ::
          {:ok, String.t(), String.t()} | {:error, String.t()}
  def validated_state_and_country(state, country \\ nil) do
    country = country_code(country || "US")

    cond do
      String.starts_with?(state, "#{country}-") ->
        {:ok, state, country}

      not is_nil(abbr = state_code(state, country)) ->
        {:ok, abbr, country}

      true ->
        {:error, "Invalid state #{state} for country #{country}"}
    end
  end

  defp filter_for_comparison(string) do
    string
    |> String.trim()
    |> String.downcase()
    |> String.normalize(:nfd)
    |> String.replace(~r/[^A-z\s]/u, "")
  end
end
