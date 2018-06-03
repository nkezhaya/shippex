defmodule Shippex.Util do
  @moduledoc false

  @countries %{
    "AD" => "Andorra",
    "AE" => "United Arab Emirates",
    "AF" => "Afghanistan",
    "AG" => "Antigua and Barbuda",
    "AI" => "Anguilla",
    "AL" => "Albania",
    "AM" => "Armenia",
    "AN" => "Netherland Antilles",
    "AO" => "Angola",
    "AR" => "Argentina",
    "AT" => "Austria",
    "AU" => "Australia",
    "AW" => "Aruba",
    "AZ" => "Azerbaijan",
    "BA" => "Bosnia-Herzegovina",
    "BB" => "Barbados",
    "BD" => "Bangladesh",
    "BE" => "Belgium",
    "BF" => "Burkina Faso",
    "BG" => "Bulgaria",
    "BH" => "Bahrain",
    "BI" => "Burundi",
    "BJ" => "Benin",
    "BM" => "Bermuda",
    "BN" => "Brunei Darussalam",
    "BO" => "Bolivia",
    "BR" => "Brazil",
    "BS" => "Bahamas",
    "BT" => "Bhutan",
    "BW" => "Botswana",
    "BY" => "Belarus",
    "BZ" => "Belize",
    "CA" => "Canada",
    "CC" => "Cocos Island",
    "CD" => "Congo (Kinshasa)",
    "CF" => "Central African Republic",
    "CG" => "Congo (Brazzaville)",
    "CH" => "Switzerland",
    "CI" => "Ivory Coast",
    "CK" => "Cook Islands",
    "CL" => "Chile",
    "CM" => "Cameroon",
    "CN" => "China",
    "CO" => "Colombia",
    "CR" => "Costa Rica",
    "CU" => "Cuba",
    "CV" => "Cape Verde",
    "CX" => "Christmas Island",
    "CY" => "Cyprus",
    "CZ" => "Czech Republic",
    "DE" => "Germany",
    "DJ" => "Djibouti",
    "DK" => "Denmark",
    "DM" => "Dominica",
    "DO" => "Dominican Republic",
    "DZ" => "Algeria",
    "EC" => "Ecuador",
    "EE" => "Estonia",
    "EG" => "Egypt",
    "ES" => "Spain",
    "ET" => "Ethiopia",
    "FI" => "Finland",
    "FJ" => "Fiji",
    "FK" => "Falkland Islands",
    "FO" => "Faroe Islands",
    "FR" => "France",
    "GA" => "Gabon",
    "GB" => "Great Britain",
    "GD" => "Grenada",
    "GE" => "Georgia",
    "GH" => "Ghana",
    "GI" => "Gibraltar",
    "GL" => "Greenland",
    "GP" => "Guadeloupe",
    "GQ" => "Equatorial Guinea",
    "GF" => "French Guiana",
    "GM" => "Gambia",
    "GN" => "Guinea",
    "GR" => "Greece",
    "GT" => "Guatemala",
    "GW" => "Guinea-Bissau",
    "GY" => "Guyana",
    "HK" => "Hong Kong",
    "HN" => "Honduras",
    "HR" => "Croatia",
    "HT" => "Haiti",
    "HU" => "Hungary",
    "ID" => "Indonesia",
    "IE" => "Ireland",
    "IL" => "Israel",
    "IN" => "India",
    "IQ" => "Iraq",
    "IR" => "Iran",
    "IS" => "Iceland",
    "IT" => "Italy",
    "JM" => "Jamaica",
    "JO" => "Jordan",
    "JP" => "Japan",
    "KE" => "Kenya",
    "KG" => "Kyrgyzstan",
    "KH" => "Cambodia",
    "KI" => "Kiribati",
    "KM" => "Comoros",
    "KN" => "Saint Kitts and Nevis",
    "KP" => "Democratic People's Republic of Korea",
    "KR" => "Republic of Korea",
    "KW" => "Kuwait",
    "KY" => "Cayman Islands",
    "KZ" => "Kazakhstan",
    "LA" => "Laos",
    "LB" => "Lebanon",
    "LC" => "Saint Lucia",
    "LI" => "Liechtenstein",
    "LK" => "Sri Lanka",
    "LR" => "Liberia",
    "LS" => "Lesotho",
    "LT" => "Lithuania",
    "LU" => "Luxembourg",
    "LV" => "Latvia",
    "LY" => "Libya",
    "MA" => "Morocco",
    "MC" => "Monaco",
    "MD" => "Moldova",
    "MG" => "Madagascar",
    "ML" => "Mali",
    "MM" => "Myanmar",
    "MN" => "Mongolia",
    "MO" => "Macau",
    "MQ" => "Martinique",
    "MR" => "Mauritania",
    "MS" => "Montserrat",
    "MT" => "Malta",
    "MU" => "Mauritius",
    "MV" => "Maldives",
    "MW" => "Malawi",
    "MX" => "Mexico",
    "MY" => "Malaysia",
    "MZ" => "Mozambique",
    "NA" => "Namibia",
    "NC" => "New Caledonia",
    "NE" => "Niger",
    "NF" => "Norfolk Island",
    "NG" => "Nigeria",
    "NI" => "Nicaragua",
    "NL" => "Netherlands",
    "NO" => "Norway",
    "NP" => "Nepal",
    "NR" => "Nauru",
    "NU" => "Niue",
    "NZ" => "New Zealand",
    "OM" => "Oman",
    "PA" => "Panama",
    "PE" => "Peru",
    "PF" => "French Polynesia",
    "PG" => "Papua New Guinea",
    "PH" => "Philippines",
    "PK" => "Pakistan",
    "PL" => "Poland",
    "PM" => "St. Pierre and Miquelon",
    "PN" => "Pitcairn Island",
    "PT" => "Portugal",
    "PY" => "Paraguay",
    "QA" => "Qatar",
    "RE" => "Reunion",
    "RO" => "Romania",
    "RU" => "Russian Federation",
    "RW" => "Rwanda",
    "SA" => "Saudi Arabia",
    "SB" => "Solomon Islands",
    "SC" => "Seychelles",
    "SD" => "Sudan",
    "SE" => "Sweden",
    "SG" => "Singapore",
    "SH" => "St. Helena",
    "SI" => "Slovenia",
    "SJ" => "Svalbard and Jan Mayen Islands",
    "SK" => "Slovak Republic",
    "SL" => "Sierra Leone",
    "SM" => "San Marino",
    "SN" => "Senegal",
    "SO" => "Somalia",
    "SR" => "Suriname",
    "ST" => "Sao Tome and Principe",
    "SV" => "El Salvador",
    "SY" => "Syria",
    "SZ" => "Swaziland",
    "TC" => "Turks and Caicos Islands",
    "TD" => "Chad",
    "TF" => "French Southern Territories",
    "TG" => "Togo",
    "TH" => "Thailand",
    "TJ" => "Tajikistan",
    "TK" => "Tokelau",
    "TM" => "Turkmenistan",
    "TN" => "Tunisia",
    "TO" => "Tonga",
    "TP" => "East Timor",
    "TR" => "Turkey",
    "TT" => "Trinidad and Tobago",
    "TV" => "Tuvalu",
    "TW" => "Taiwan",
    "TZ" => "Tanzania",
    "UA" => "Ukraine",
    "UG" => "Uganda",
    "UK" => "United Kingdom",
    "US" => "United States",
    "UY" => "Uruguay",
    "UZ" => "Uzbekistan",
    "VA" => "Vatican City",
    "VC" => "Saint Vincent and Grenadines",
    "VE" => "Venezuela",
    "VG" => "British Virgin Islands",
    "VN" => "Vietnam",
    "VU" => "Vanuatu",
    "WF" => "Wallis and Futuna Islands",
    "WS" => "Samoa",
    "YE" => "Yemen",
    "ZA" => "South Africa",
    "ZM" => "Zambia",
    "ZW" => "Zimbabwe"
  }

  @territories %{
    "US" => %{
      "AS" => "American Samoa",
      "GU" => "Guam",
      "MH" => "Marshall Islands",
      "MP" => "Northern Mariana Islands",
      "PR" => "Puerto Rico",
      "VI" => "Virgin Islands, US"
    }
  }

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
  @spec full_state_to_abbreviation(String.t()) :: nil | String.t()
  def full_state_to_abbreviation(state)
      when is_bitstring(state) and byte_size(state) == 2,
      do: state

  def full_state_to_abbreviation(state) when is_bitstring(state) do
    state = filter_for_comparison(state)

    @states
    |> Map.values()
    |> Enum.find_value(fn states ->
      Enum.find(states, fn {_abbr, full} ->
        filter_for_comparison(full) == state
      end)
    end)
    |> case do
      {abbr, _full} -> abbr
      _ -> nil
    end
  end

  @doc """
  Returns a map of country codes and their full names.

      iex> countries = Util.countries()
      ...> match? %{"US" => "United States"}, countries
      true
  """
  @spec countries() :: %{String.t() => String.t()}
  def countries() do
    @countries
  end

  @doc """
  Returns a map of state codes and full names for the given 2-letter country
  code.

      iex> states = Util.states("US")
      ...> match? %{"TX" => "Texas", "PR" => "Puerto Rico"}, states
      true
      iex> states = Util.states("MX")
      ...> match? %{"AG" => "Aguascalientes"}, states
      true
      iex> Util.states("Not a country.")
      %{}
  """
  @spec states(String.t()) :: %{String.t() => String.t()}
  def states(country \\ "US") do
    with states <- @states[country] || %{},
         territories <- @territories[country] || %{} do
      Map.merge(states, territories)
    end
  end

  @doc """
  Converts a country's 2-letter code to its full name.

      iex> Util.abbreviation_to_country_name("US")
      "United States"
      iex> Util.abbreviation_to_country_name("TN")
      "Tunisia"
      iex> Util.abbreviation_to_country_name("TX")
      nil
  """
  @spec abbreviation_to_country_name(String.t()) :: nil | String.t()
  def abbreviation_to_country_name(abbr) when is_bitstring(abbr) do
    @countries[abbr]
  end

  defp filter_for_comparison(string) do
    string
    |> String.trim()
    |> String.downcase()
    |> String.normalize(:nfd)
    |> String.replace(~r/[^A-z\s]/u, "")
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
