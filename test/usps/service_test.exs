defmodule Shippex.USPS.ServiceTest do
  use ExUnit.Case

  alias Shippex.Service

  test "usps services" do
    assert Service.services_for_carrier("usps") == Service.services_for_carrier(:usps)
    assert length(Service.services_for_carrier(:usps)) > 0
  end
end
