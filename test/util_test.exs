defmodule UtilTest do
  use ExUnit.Case
  doctest Shippex

  alias Shippex.Util

  test "state helper" do
    assert Util.full_state_to_abbreviation("Texas") == "TX"
    assert Util.full_state_to_abbreviation("teXaS") == "TX"
    assert Util.full_state_to_abbreviation("TX") == "TX"
  end
end
