defmodule Shippex.Util do
  @moduledoc false
  
  @states [
    ["Alabama", "AL"],
    ["Alaska", "AK"],
    ["Arizona", "AZ"],
    ["Arkansas", "AR"],
    ["California", "CA"],
    ["Colorado", "CO"],
    ["Connecticut", "CT"],
    ["Delaware", "DE"],
    ["District of Columbia", "DC"],
    ["Florida", "FL"],
    ["Georgia", "GA"],
    ["Hawaii", "HI"],
    ["Idaho", "ID"],
    ["Illinois", "IL"],
    ["Indiana", "IN"],
    ["Iowa", "IA"],
    ["Kansas", "KS"],
    ["Kentucky", "KY"],
    ["Louisiana", "LA"],
    ["Maine", "ME"],
    ["Maryland", "MD"],
    ["Massachusetts", "MA"],
    ["Michigan", "MI"],
    ["Minnesota", "MN"],
    ["Mississippi", "MS"],
    ["Missouri", "MO"],
    ["Montana", "MT"],
    ["Nebraska", "NE"],
    ["Nevada", "NV"],
    ["New Hampshire", "NH"],
    ["New Jersey", "NJ"],
    ["New Mexico", "NM"],
    ["New York", "NY"],
    ["North Carolina", "NC"],
    ["North Dakota", "ND"],
    ["Ohio", "OH"],
    ["Oklahoma", "OK"],
    ["Oregon", "OR"],
    ["Pennsylvania", "PA"],
    ["Rhode Island", "RI"],
    ["South Carolina", "SC"],
    ["South Dakota", "SD"],
    ["Tennessee", "TN"],
    ["Texas", "TX"],
    ["Utah", "UT"],
    ["Vermont", "VT"],
    ["Virginia", "VA"],
    ["Washington", "WA"],
    ["West Virginia", "WV"],
    ["Wisconsin", "WI"],
    ["Wyoming", "WY"]
  ]

  @spec full_state_to_abbreviation(String.t) :: String.t
  def full_state_to_abbreviation(state) when is_bitstring(state) and byte_size(state) == 2 do
    state
  end
  def full_state_to_abbreviation(state) when is_bitstring(state) do
    state = String.downcase(state)

    result = Enum.find @states, fn (s) ->
      [full, abbr] = s

      if state == String.downcase(full) do
        abbr
      else
        false
      end
    end

    case result do
      [_full, abbr] -> abbr
      _ -> nil
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
