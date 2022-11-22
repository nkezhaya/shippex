defmodule Shippex.Config do
  @moduledoc false

  alias Shippex.InvalidConfigError

  @spec carriers() :: [Carrier.t()]
  def carriers() do
    config()
    |> Enum.map_with_index(fn _config, i -> i end)
  end

  @spec config() :: Keyword.t() | none()
  def config() do
    case Application.get_env(:shippex, :carriers, :not_found) do
      :not_found ->
        raise InvalidConfigError, "Shippex config not found"

      config ->
        if not Keyword.keyword?(config) do
          raise InvalidConfigError,
                "Shippex config was found, but doesn't contain a keyword list."
        end

        config
    end
  end

  @spec currency_code() :: String.t() | none()
  def currency_code() do
    case Application.get_env(:shippex, :currency, :usd) do
      code when code in [:usd, :can, :mxn] ->
        code |> Atom.to_string() |> String.upcase()

      _ ->
        raise InvalidConfigError, "Shippex currency must be either :usd, :can, or :mxn"
    end
  end

  @spec env() :: :dev | :prod | none()
  def env() do
    case Application.get_env(:shippex, :env, :dev) do
      e when e in [:dev, :prod] -> e
      _ -> raise InvalidConfigError, "Shippex env must be either :dev or :prod"
    end
  end
end
