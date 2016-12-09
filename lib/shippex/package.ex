defmodule Shippex.Package do
  @enforce_keys [:length, :width, :height, :weight]
  defstruct [:length, :width, :height, :weight, :description]
end
