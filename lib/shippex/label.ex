defmodule Shippex.Label do
  @moduledoc """
  Defines the struct for storing a returned `Rate`, along with the tracking
  number, base64-encoded image, and its MIME format.

      %Shippex.Label{rate: %Shippex.Rate{},
                     tracking_number: "ABCDEF1234",
                     format: "image/gif",
                     image: "data:image/gif;base64,iVBORw0K..."}
  """

  @type t :: %__MODULE__{}

  @enforce_keys [:tracking_number]
  defstruct [:rate, :tracking_number, :format, :image]
end
