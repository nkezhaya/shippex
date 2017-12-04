defmodule Shippex.Util do
  @moduledoc false

  @states %{
    "US" => %{
      "AL" => "Alabama",
      "AK" => "Alaska",
      "AZ" => "Arizona",
      "AR" => "Arkansas",
      "CA" => "California",
      "CO" => "Colorado",
      "CT" => "Connecticut",
      "DE" => "Delaware",
      "DC" => "District of Columbia",
      "FL" => "Florida",
      "GA" => "Georgia",
      "HI" => "Hawaii",
      "ID" => "Idaho",
      "IL" => "Illinois",
      "IN" => "Indiana",
      "IA" => "Iowa",
      "KS" => "Kansas",
      "KY" => "Kentucky",
      "LA" => "Louisiana",
      "ME" => "Maine",
      "MD" => "Maryland",
      "MA" => "Massachusetts",
      "MI" => "Michigan",
      "MN" => "Minnesota",
      "MS" => "Mississippi",
      "MO" => "Missouri",
      "MT" => "Montana",
      "NE" => "Nebraska",
      "NV" => "Nevada",
      "NH" => "New Hampshire",
      "NJ" => "New Jersey",
      "NM" => "New Mexico",
      "NY" => "New York",
      "NC" => "North Carolina",
      "ND" => "North Dakota",
      "OH" => "Ohio",
      "OK" => "Oklahoma",
      "OR" => "Oregon",
      "PA" => "Pennsylvania",
      "RI" => "Rhode Island",
      "SC" => "South Carolina",
      "SD" => "South Dakota",
      "TN" => "Tennessee",
      "TX" => "Texas",
      "UT" => "Utah",
      "VT" => "Vermont",
      "VA" => "Virginia",
      "WA" => "Washington",
      "WV" => "West Virginia",
      "WI" => "Wisconsin",
      "WY" => "Wyoming"
    },
    "CA" => %{
      "AB" => "Alberta",
      "BC" => "British Columbia",
      "MB" => "Manitoba",
      "NB" => "New Brunswick",
      "NL" => "Newfoundland and Labrador",
      "NT" => "Northwest Territories",
      "NS" => "Nova Scotia",
      "NU" => "Nunavut",
      "ON" => "Ontario",
      "PE" => "Prince Edward Island",
      "QC" => "Quebec",
      "SK" => "Saskatchewan",
      "YT" => "Yukon"
    },
    "MX" => %{
      "AG" => "Aguascalientes",
      "BC" => "Baja California",
      "BS" => "Baja California Sur",
      "CM" => "Campeche",
      "CS" => "Chiapas",
      "CH" => "Chihuahua",
      "CO" => "Coahuila",
      "CL" => "Colima",
      "DF" => "Distrito Federal",
      "DG" => "Durango",
      "GT" => "Guanajuanto",
      "GR" => "Guerrero",
      "HG" => "Hidalgo",
      "JA" => "Jalisco",
      "MX" => "México",
      "MI" => "Michoacán",
      "MO" => "Morelos",
      "NA" => "Nayarit",
      "NL" => "Nuevo León",
      "OA" => "Oaxaca",
      "PU" => "Puebla",
      "QT" => "Querétaro",
      "QR" => "Quintana Roo",
      "SL" => "San Luis Potosí",
      "SI" => "Sinaloa",
      "SO" => "Sonora",
      "TB" => "Tabasco",
      "TM" => "Tamaulipas",
      "TL" => "Tlaxcala",
      "VE" => "Veracruz",
      "YU" => "Yucatán",
      "ZA" => "Zacatecas"
    }
  }

  @doc """
  Converts a full state name to its state code, or abbreviation.

      iex> Util.full_state_to_abbreviation("Texas")
      "TX"
      iex> Util.full_state_to_abbreviation("teXaS")
      "TX"
      iex> Util.full_state_to_abbreviation("TX")
      "TX"
      iex> Util.full_state_to_abbreviation("TX")
      "TX"
      iex> Util.full_state_to_abbreviation("AlberTa")
      "AB"
      iex> Util.full_state_to_abbreviation("Veracruz")
      "VE"
      iex> Util.full_state_to_abbreviation("Yucatán")
      "YU"
      iex> Util.full_state_to_abbreviation("Yucatan")
      "YU"
      iex> Util.full_state_to_abbreviation("YucatAN")
      "YU"
      iex> Util.full_state_to_abbreviation("Not a state.")
      nil
  """
  @spec full_state_to_abbreviation(String.t) :: nil | String.t
  def full_state_to_abbreviation(state)
    when is_bitstring(state) and byte_size(state) == 2, do: state
  def full_state_to_abbreviation(state) when is_bitstring(state) do
    state = filter_for_comparison(state)

    @states
    |> Map.values
    |> Enum.find_value(fn states ->
      Enum.find states, fn {_abbr, full} ->
        filter_for_comparison(full) == state
      end
    end)
    |> case do
      {abbr, _full} -> abbr
      _ -> nil
    end
  end
  defp filter_for_comparison(string) do
    string
    |> String.trim
    |> String.downcase
    |> String.normalize(:nfd)
    |> String.replace(~r/[^A-z\s]/u, "")
  end

  @spec states(String.t) :: %{String.t => String.t}
  def states(country \\ "US")
  def states(nil), do: %{}
  def states(country) do
    case @states[country] do
      states when is_map(states) -> states
      _ -> %{}
    end
  end

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
  @spec price_to_cents(nil | number() | String.t) :: integer
  def price_to_cents(string) when is_bitstring(string) do
    {float, _} = Float.parse(string)
    price_to_cents(float)
  end
  def price_to_cents(nil),
    do: 0
  def price_to_cents(float) when is_float(float),
    do: Float.floor(float * 100) |> round
  def price_to_cents(integer) when is_integer(integer),
    do: integer * 100

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
