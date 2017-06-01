defmodule Shippex.Package do
  @moduledoc """
  Defines the struct for storing a `Package`, which is then passed along with
  an origin and destination address for shipping estimates. A `description` is
  optional, as it may or may not be used with various carriers.

      %Shippex.Package{length: 8
                       width: 8,
                       height: 8,
                       weight: 5.5}
  """

  @enforce_keys [:length, :width, :height, :weight]
  defstruct [:length, :width, :height, :weight, :description]
end
