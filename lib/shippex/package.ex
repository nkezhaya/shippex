defmodule Shippex.Package do
  @moduledoc """
  Defines the struct for storing a `Package`, which is then passed along with
  an origin and destination address for shipping estimates. A `description` is
  optional, as it may or may not be used with various carriers. The
  `monetary_value` *might* be required depending on the origin/destination
  countries of the shipment.

  For USPS, a package has a `container` string which can be one of the
  pre-defined USPS containers.

      %Shippex.Package{length: 8
                       width: 8,
                       height: 8,
                       weight: 5.5,
                       monetary_value: 100}
  """

  @type t :: %__MODULE__{}

  @enforce_keys [:length, :width, :height, :weight]
  defstruct [:length, :width, :height, :weight, :girth,
             :description, :monetary_value, :container]

  @doc """
  Returns the list of predefined containers for use with USPS. These can be
  passed to `package.container` for fetching rates.
  """
  @spec usps_containers :: %{atom => String.t}
  def usps_containers do
    %{box_large: "Lg Flat Rate Box",
      box_medium: "Md Flat Rate Box",
      box_small: "Sm Flat Rate Box",
      envelope: "Flat Rate Envelope",
      envelope_gift_card: "Gift Card Flat Rate Envelope",
      envelope_legal: "Legal Flat Rate Envelope",
      envelope_padded: "Padded Flat Rate Envelope",
      envelope_small: "Sm Flat Rate Envelope",
      envelope_window: "Window Flat Rate Envelope",
      nonrectangular: "Nonrectangular",
      rectangular: "Rectangular",
      variable: "Variable"}
  end
end
