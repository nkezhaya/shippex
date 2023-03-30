defmodule ExShip.Config do
  @moduledoc false

  alias ExShip.InvalidConfigError

  @spec carriers() :: [Carrier.t()]
  def carriers() do
    config()
    |> Enum.map(fn({x,_}) -> x end)
  end

  @spec carriers() :: [Carrier.t()]
  def carriers(nil) do
    config()
    |> Enum.map(fn({x,_}) -> x end)
  end

  @spec carriers(List.t()) :: [Carrier.t()]
  def carriers(config) do
    config
    |> Enum.map(fn({x,_}) -> x end)
  end

  @spec config() :: Keyword.t() | none()
  def config() do
    case Application.get_env(:exship, :carriers, :not_found) do
      :not_found ->
        raise InvalidConfigError, "ExShip config not found"

      config ->
        if not Keyword.keyword?(config) do
          raise InvalidConfigError,
                "ExShip config was found, but doesn't contain a keyword list."
        end

        config
    end
  end

  @spec currency_code() :: String.t() | none()
  def currency_code() do
    case Application.get_env(:exship, :currency, :usd) do
      code when code in [:usd, :can, :mxn] ->
        code |> Atom.to_string() |> String.upcase()

      _ ->
        raise InvalidConfigError, "ExShip currency must be either :usd, :can, or :mxn"
    end
  end

  @spec env() :: :dev | :prod | none()
  def env() do
    case Application.get_env(:exship, :env, :dev) do
      e when e in [:dev, :prod] -> e
      _ -> raise InvalidConfigError, "ExShip env must be either :dev or :prod"
    end
  end
end
