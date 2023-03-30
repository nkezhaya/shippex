defmodule ExShip.Address do
  @moduledoc """
  Represents an address that can be passed to other `ExShip` functions. Do
  *not* initialize this struct directly. Instead, use `address/1`.
  """

  @enforce_keys ~w(first_name last_name name phone address address_line_2 address_line_3 city
                   state postal_code country type)a

  defstruct ~w(first_name last_name name company_name phone address
               address_line_2 address_line_3 city state postal_code country type meta valid)a

  @type t() :: %__MODULE__{
          first_name: nil | String.t(),
          last_name: nil | String.t(),
          name: nil | String.t(),
          company_name: nil | String.t(),
          phone: nil | String.t(),
          address: String.t(),
          address_line_2: nil | String.t(),
          address_line_3: nil | String.t(),
          city: String.t(),
          state: String.t(),
          postal_code: String.t(),
          type: String.t(),
    valid: String.t(),
          meta: String.t(),
          country: ISO.country_code()
        }

  alias __MODULE__, as: Address
  alias ExShip.Util

  @default_country "US"

  @doc """
  Initializes an `Address` struct from the given `params`, and performs minor
  validations that do not require any service requests.

  You may specify `first_name` and `last_name` separately, which will be
  concatenated to make the `name` property, or just specify `name` directly.

  If `name` is specified directly, ExShip will try to infer the first and last
  names in case they're required separately for API calls.

      ExShip.Address.new(%{
        first_name: "Earl",
        last_name: "Grey",
        phone: "123-123-1234",
        address: "9999 Hobby Lane",
        address_line_2: nil,
        address_line_3: nil,
        city: "Austin",
        state: "TX",
        type: :residential,
        postal_code: "78703",
        valid: true,
        email: nil
        meta: nil
      })
  """
  @spec new(map()) :: {:ok, t()} | {:error, String.t()}
  def new(params) when is_map(params) do
    params = Util.stringify_and_trim(params)

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

    country =
      cond do
        Util.blank?(params["country"]) ->
          @default_country

        c = ISO.find_country(params["country"]) ->
          {code, _} = c
          code

        true ->
          throw({:invalid_state_and_country, "invalid country #{params["country"]}"})
      end

    state =
      if Util.blank?(params["state"]) and not subdivision_required?(country) do
        nil
      else
        case ISO.find_subdivision_code(country, params["state"]) do
          {:ok, state} -> state
          {:error, error} -> throw({:invalid_state_and_country, error})
        end
      end

    type =
      if is_nil(params["type"]) do
        :residential
      else
        params["type"]
      end

    address = %Address{
      name: name,
      first_name: first_name,
      last_name: last_name,
      company_name: params["company_name"],
      phone: params["phone"],
      address: params["address"],
      address_line_2: params["address_line_2"],
      address_line_3: params["address_line_3"],
      city: params["city"],
      state: state,
      type: type,
      postal_code: String.trim(params["postal_code"] || ""),
      country: country,
      valid: nil,
      meta: nil
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
        ExShip.Carrier.module(carrier).validate_address(address)

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

      iex> address = ExShip.Address.state_without_country(%{
      ...>   first_name: "Earl",
      ...>   last_name: "Grey",
      ...>   phone: "123-123-1234",
      ...>   address: "9999 Hobby Lane",
      ...>   address_line_2: nil,
      ...>   city: "Austin",
      ...>   state: "US-TX",
      ...>   postal_code: "78703",
      ...>   type: :business,
      ...>   country: "US",
      ...>   meta: nil
      ...>  })
      iex> Address.state_without_country(address)
      "TX"
  """
  @spec state_without_country(t() | %{state: String.t(), country: String.t()}) :: String.t()
  def state_without_country(%{state: state, country: country}) do
    String.replace(state, "#{country}-", "")
  end

  @spec state_without_country(String.t()) :: String.t()
  def state_without_country(state) do
    state
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
    |> ISO.country_name()
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

  @doc """
  Returns `true` if addresses for the country require a postal code to be
  specified to validate addresses.

      iex> Address.postal_code_required?("US")
      true

      iex> Address.postal_code_required?("CN")
      true

      iex> Address.postal_code_required?("HK")
      false
  """
  @spec postal_code_required?(ISO.country_code()) :: boolean()

  for country_code <- ~w(AO AG AW BS BZ BJ BO BQ BW BF BI CM CF TD KM CG CD CK
    CI CW DJ DM TL GQ ER FJ TF GA GM GD GY HM HK KI KP LY MW ML MR NR NU QA RW
    KN ST SC SL SX SB SS SR SY TG TK TO TV UG AE VU ZW) do
    def postal_code_required?(unquote(country_code)), do: false
  end

  def postal_code_required?(_) do
    true
  end
end
