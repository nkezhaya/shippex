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
  def price_to_cents(string) when is_bitstring(string) do
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
end
