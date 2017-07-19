defmodule Shippex.UtilTest do
  use ExUnit.Case
  doctest Shippex

  alias Shippex.Util

  test "state helper" do
    assert Util.full_state_to_abbreviation("Texas") == "TX"
    assert Util.full_state_to_abbreviation("teXaS") == "TX"
    assert Util.full_state_to_abbreviation("TX") == "TX"
    assert Util.full_state_to_abbreviation("TX") == "TX"
    assert Util.full_state_to_abbreviation("AlberTa") == "AB"
    assert Util.full_state_to_abbreviation("Veracruz") == "VE"
    assert Util.full_state_to_abbreviation("Yucatán") == "YU"
    assert Util.full_state_to_abbreviation("Yucatan") == "YU"
    assert Util.full_state_to_abbreviation("YucatAN") == "YU"

    assert is_nil(Util.full_state_to_abbreviation("Not a State"))
  end

  test "conversion helper" do
    assert Util.lbs_to_kgs(10) == 4.5
    assert Util.kgs_to_lbs(10) == 22.0
    assert Util.inches_to_cm(10) == 25.4
    assert Util.cm_to_inches(10) == 3.9

    assert Util.lbs_to_kgs(0) == 0.0
    assert Util.kgs_to_lbs(0) == 0.0
    assert Util.inches_to_cm(0) == 0.0
    assert Util.cm_to_inches(0) == 0.0
  end
end
