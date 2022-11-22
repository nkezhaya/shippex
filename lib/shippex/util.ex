defmodule Shippex.Util do
  @moduledoc false

  @doc """
  Takes a price and multiplies it by 100. Accepts nil, floats, integers, and
  strings.

      iex> Util.price_to_cents(nil)
      0
      iex> Util.price_to_cents(0)
      0
      iex> Util.price_to_cents(28.00)
      2800
      iex> Util.price_to_cents("28.00")
      2800
      iex> Util.price_to_cents("28")
      2800
      iex> Util.price_to_cents(28)
      2800
  """
  @spec price_to_cents(nil | number() | String.t()) :: integer
  def price_to_cents(string) when is_binary(string) do
    {float, _} = Float.parse(string)
    price_to_cents(float)
  end

  def price_to_cents(nil), do: 0
  def price_to_cents(float) when is_float(float), do: Float.floor(float * 100) |> round
  def price_to_cents(integer) when is_integer(integer), do: integer * 100

  @doc """
  Takes a price and divides it by 100, returning a string representation. This
  is used for API calls that require dollars instead of cents. Unlike
  `price_to_cents`, this only accepts integers and nil. Otherwise, it will
  raise an exception.

      iex> Util.price_to_dollars(nil)
      "0.00"
      iex> Util.price_to_dollars(200_00)
      "200"
      iex> Util.price_to_dollars("20000")
      ** (FunctionClauseError) no function clause matching in Shippex.Util.price_to_dollars/1
  """
  @spec price_to_dollars(integer) :: String.t() | none()
  def price_to_dollars(nil), do: "0.00"

  def price_to_dollars(integer) when is_integer(integer) do
    dollars = Integer.floor_div(integer, 100)
    cents = rem(integer, 100)
    s = "#{dollars}"

    cond do
      cents == 0 ->
        s

      cents < 10 ->
        "#{s}.0#{cents}"

      true ->
        "#{s}.#{cents}"
    end
  end

  @doc """
  Converts pounds to kilograms.

      iex> Util.lbs_to_kgs(10)
      4.5
      iex> Util.lbs_to_kgs(0)
      0.0
  """
  @spec lbs_to_kgs(number()) :: float()
  def lbs_to_kgs(lbs) do
    Float.round(lbs * 0.453592, 1)
  end

  @doc """
  Converts kilograms to pounds.

      iex> Util.kgs_to_lbs(10)
      22.0
      iex> Util.kgs_to_lbs(0)
      0.0
  """
  @spec kgs_to_lbs(number()) :: float()
  def kgs_to_lbs(kgs) do
    Float.round(kgs * 2.20462, 1)
  end

  @doc """
  Converts inches to centimeters.

      iex> Util.inches_to_cm(10)
      25.4
      iex> Util.inches_to_cm(0)
      0.0
  """
  @spec inches_to_cm(number()) :: float()
  def inches_to_cm(inches) do
    Float.round(inches * 2.54, 1)
  end

  @doc """
  Converts centimeters to inches.

      iex> Util.cm_to_inches(10)
      3.9
      iex> Util.cm_to_inches(0)
      0.0
  """
  @spec cm_to_inches(number()) :: float()
  def cm_to_inches(cm) do
    Float.round(cm * 0.393701, 1)
  end

  @doc """
  Removes accents/ligatures from letters.

      iex> Util.unaccent("Curaçao")
      "Curacao"
      iex> Util.unaccent("Republic of Foo (the)")
      "Republic of Foo (the)"
      iex> Util.unaccent("Åland Islands")
      "Aland Islands"
  """
  @spec unaccent(String.t()) :: String.t()
  def unaccent(string) do
    diacritics = Regex.compile!("[\u0300-\u036f]")

    string
    |> String.normalize(:nfd)
    |> String.replace(diacritics, "")
  end

  @doc ~S"""
  Returns `true` for `nil`, empty strings, and strings only containing
  whitespace. Returns `false` otherwise.

      iex> Util.blank?(nil)
      true
      iex> Util.blank?("")
      true
      iex> Util.blank?("   ")
      true
      iex> Util.blank?(" \t\r\n ")
      true
      iex> Util.blank?("Test")
      false
      iex> Util.blank?(100)
      false
  """
  @spec blank?(term()) :: boolean()
  def blank?(nil), do: true
  def blank?(""), do: true
  def blank?(s) when is_binary(s), do: String.trim(s) == ""
  def blank?(_), do: false

  @doc """
  Returns the given map with keys converted to strings, and the values trimmed
  (if the values are also strings).

      iex> Util.stringify_and_trim(%{foo: "  bar  "}) 
      %{"foo" => "bar"}
  """
  @spec stringify_and_trim(map()) :: map()
  def stringify_and_trim(params) do
    for {key, val} <- params, into: %{} do
      key =
        cond do
          is_atom(key) -> Atom.to_string(key)
          true -> key
        end

      val =
        cond do
          is_binary(val) -> String.trim(val)
          true -> val
        end

      {key, val}
    end
  end

  @doc """
  Returns the mane and module tuple.

      iex> Util.get_modules()
      {%{}, :module_name}
  """
  def get_modules() do
    {:ok, modules} = :application.get_key(:shippex, :modules)

    modules
    |> Stream.map(&Module.split/1)
    |> Stream.filter(fn module ->
      case module do
        ["Shippex", "Carrier", _] -> true
        ["Shippex", "Carrier", "_", "Client"] -> false
        _ -> false
      end
    end)
    # concat
    |> Stream.map(&Module.concat/1)
    |> Stream.map(&{&1, apply(&1, :carrier, [])})
    |> Enum.map(fn output ->
      output
    end)
  end
end
