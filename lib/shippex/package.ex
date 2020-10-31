defmodule Shippex.Package do
  @moduledoc """
  Defines the struct for storing a `Package`, which is then passed along with
  an origin and destination address for shipping estimates. A `description` is
  optional, as it may or may not be used with various carriers.

  For USPS, a package has a `container` string which can be one of the
  pre-defined USPS containers.

  Do not pass a `weight` parameter. Instead, pass in a list of `:items` with a
  weight parameter on each of these. The weight on the package will be the sum
  of the weights of each of these. Same for `:monetary_value`.

  `:description` can optionally be passed in. Otherwise, it will be generated
  by joining the descriptions of each of the items.

      Shippex.Package.package(%{length: 8
                                width: 8,
                                height: 8,
                                items: [
                                  %{weight: 1, monetary_value: 100, description: "A"},
                                  %{weight: 2, monetary_value: 200, description: "B"}
                                ]})

      # => %Package{weight: 3, monetary_value: 300, description: "A, B", ...}
  """

  alias Shippex.Item

  @enforce_keys [:length, :width, :height, :weight, :items, :monetary_value, :description]
  @fields ~w(length width height weight girth container insurance monetary_value description items)a
  defstruct @fields

  @typep flat_rate_container() :: %{
           name: String.t(),
           rate: integer(),
           length: number(),
           width: number(),
           height: number()
         }

  @type t() :: %__MODULE__{
          length: number(),
          width: number(),
          height: number(),
          weight: number(),
          monetary_value: number(),
          girth: nil | number(),
          container: nil | String.t(),
          insurance: nil | number(),
          description: nil | String.t(),
          items: [Item.t()]
        }

  @doc """
  Builds and returns a `Package`. Use this instead of directly initializing
  the struct.
  """
  @spec new(map()) :: t()
  def new(attrs) do
    items =
      case attrs do
        %{items: [_ | _] = items} -> Enum.map(items, &Item.new/1)
        _ -> []
      end

    weight =
      items
      |> Enum.filter(&is_number(&1.weight))
      |> Enum.reduce(0, &(&1.weight + &2))

    monetary_value =
      items
      |> Enum.filter(&is_number(&1.monetary_value))
      |> Enum.reduce(0, &(&1.monetary_value + &2))

    description =
      case attrs do
        %{description: d} when is_binary(d) and d != "" ->
          d

        _ ->
          items
          |> Enum.filter(&is_binary(&1.description))
          |> Enum.map(&String.normalize(&1.description, :nfc))
          |> Enum.join(", ")
      end

    attrs =
      attrs
      |> Map.merge(%{
        items: items,
        weight: weight,
        monetary_value: monetary_value,
        description: description
      })
      |> Map.take(@fields)

    struct(__MODULE__, attrs)
  end

  @doc """
  Returns a map of predefined containers for use with USPS. These can be
  passed to `package.container` for fetching rates.
  """
  @spec usps_containers() :: %{atom() => String.t()}
  def usps_containers() do
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
  @spec usps_flat_rate_containers() :: %{atom() => flat_rate_container()}
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
