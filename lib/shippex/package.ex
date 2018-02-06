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
  @typep flat_rate_container :: %{
           name: String.t(),
           rate: integer,
           length: number,
           width: number,
           height: number
         }

  @enforce_keys [:length, :width, :height, :weight]
  defstruct [:length, :width, :height, :weight, :girth, :description, :monetary_value, :container]

  @doc """
  Returns a map of predefined containers for use with USPS. These can be
  passed to `package.container` for fetching rates.
  """
  @spec usps_containers :: %{atom => String.t()}
  def usps_containers do
    %{
      box_large: "Lg Flat Rate Box",
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
      variable: "Variable"
    }
  end

  @doc """
  Returns a map of flat rate USPS containers, along with their string description
  and flat shipping rate (in cents).
  """
  @spec usps_flat_rate_containers() :: %{atom => flat_rate_container}
  def usps_flat_rate_containers() do
    %{
      envelope: %{name: "Flat Rate Envelope", rate: 665, length: 12.5, height: 9.5, width: 0},
      envelope_gift_card: %{
        name: "Gift Card Flat Rate Envelope",
        rate: 665,
        length: 10,
        height: 7,
        width: 0
      },
      envelope_window: %{
        name: "Window Flat Rate Envelope",
        rate: 665,
        length: 10,
        height: 5,
        width: 0
      },
      envelope_small: %{name: "Sm Flat Rate Envelope", rate: 665, length: 10, height: 6, width: 0},
      envelope_legal: %{
        name: "Legal Flat Rate Envelope",
        rate: 695,
        length: 15,
        height: 9.5,
        width: 0
      },
      envelope_padded: %{
        name: "Padded Flat Rate Envelope",
        rate: 720,
        length: 12.5,
        height: 9.5,
        width: 0
      },
      box_small: %{
        name: "Sm Flat Rate Box",
        rate: 715,
        length: 8.6875,
        height: 5.4375,
        width: 1.75
      },
      box_medium: %{name: "Md Flat Rate Box", rate: 1360, length: 11.25, height: 8.75, width: 6},
      box_large: %{name: "Lg Flat Rate Box", rate: 1885, length: 12.25, height: 12.25, width: 6}
    }
  end
end
