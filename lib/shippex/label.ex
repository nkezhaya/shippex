defmodule Shippex.Label do
  @moduledoc """
  Defines the struct for storing a returned `Rate`, along with the tracking
  number, base64-encoded image and its format.

      %Shippex.Label{rate: %Shippex.Rate{},
                     tracking_number: "ABCDEF1234",
                     format: :gif,
                     image: "iVBORw0K..."}

  Note that `:image` is always a pure base64 string, and doesn't contain common
  prefixes like `"data:image/gif;base64,"` and so on.

  Currently, UPS returns GIF labels, and USPS returns PDF labels.
  """

  @enforce_keys [:tracking_number, :format, :image]
  defstruct [:tracking_number, :format, :image]

  @type t :: %__MODULE__{
          tracking_number: String.t(),
          format: :gif | :pdf | :tif | :png,
          image: String.t()
        }
end
