defmodule Shippex.UPS.ServiceTest do
  use ExUnit.Case
  doctest Shippex

  alias Shippex.Service

  test "usps services" do
    assert Service.services_for_carrier("usps") == Service.services_for_carrier(:usps)
    assert length(Service.services_for_carrier(:usps)) > 0
  end
end
