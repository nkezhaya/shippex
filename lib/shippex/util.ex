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

  @spec full_state_to_abbreviation(String.t) :: String.t
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

  @spec lbs_to_kgs(number()) :: float
  def lbs_to_kgs(lbs) do
    Float.round(lbs * 0.453592, 1)
  end

  @spec kgs_to_lbs(number()) :: float
  def kgs_to_lbs(kgs) do
    Float.round(kgs * 2.20462, 1)
  end

  @spec inches_to_cm(number()) :: float
  def inches_to_cm(inches) do
    Float.round(inches * 2.54, 1)
  end

  @spec cm_to_inches(number()) :: float
  def cm_to_inches(cm) do
    Float.round(cm * 0.393701, 1)
  end
end
