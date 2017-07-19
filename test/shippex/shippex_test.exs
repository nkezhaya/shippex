defmodule Shippex.ShippexTest do
  use ExUnit.Case
  doctest Shippex

  test "set env" do
    Application.put_env(:shippex, :env, :prod)
    assert Shippex.env == :prod

    Application.put_env(:shippex, :env, :dev)
    assert Shippex.env == :dev
  end

  test "currency code" do
    Application.put_env(:shippex, :currency, :mxn)
    assert Shippex.currency_code == "MXN"

    Application.put_env(:shippex, :currency, :can)
    assert Shippex.currency_code == "CAN"

    Application.put_env(:shippex, :currency, :foo)
    assert_raise Shippex.InvalidConfigError, &Shippex.currency_code/0

    Application.put_env(:shippex, :currency, :usd)
    assert Shippex.currency_code == "USD"
  end
end
