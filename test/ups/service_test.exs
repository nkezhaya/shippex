defmodule Shippex.UPS.ServiceTest do
  use ExUnit.Case
  doctest Shippex

  alias Shippex.Service

  test "services queries" do
    assert Service.services_for_carrier("ups") == Service.services_for_carrier(:ups)
    assert length(Service.services_for_carrier(:ups)) > 0
  end
end
