defmodule Shippex.Transaction do
  @moduledoc false

  alias Shippex.{Transaction, Shipment, Rate, Label, Carrier}

  @enforce_keys [:shipment, :rate, :label, :carrier]
  defstruct [:shipment, :rate, :label, :carrier]

  @type t :: %__MODULE__{
          shipment: Shipment.t(),
          rate: Rate.t(),
          label: nil | Label.t(),
          carrier: Carrier.t()
        }

  @spec new(Shipment.t(), Rate.t(), nil | Label.t()) :: Transaction.t()
  def new(%Shipment{} = shipment, %Rate{} = rate, label) do
    carrier = rate.service.carrier
    %Transaction{shipment: shipment, rate: rate, label: label, carrier: carrier}
  end
end
