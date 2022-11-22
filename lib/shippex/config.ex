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

  def usps_config() do
    with cfg when is_list(cfg) <- Keyword.get(config(), :usps, {:error, :not_found}),
         un <- Keyword.get(cfg, :username, {:error, :not_found, :username}),
         pw <- Keyword.get(cfg, :password, {:error, :not_found, :password}) do
      %{username: un, password: pw}
    else
      {:error, :not_found, token} ->
        raise InvalidConfigError, message: "USPS config key missing: #{token}"

      {:error, :not_found} ->
        raise InvalidConfigError, message: "USPS config is either invalid or not found."
    end
  end

  def ups_config() do
    with cfg when is_list(cfg) <- Keyword.get(config(), :ups, {:error, :not_found}),
         sk when is_binary(sk) <-
           Keyword.get(cfg, :secret_key, {:error, :not_found, :secret_key}),
         sh when is_map(sh) <- Keyword.get(cfg, :shipper, {:error, :not_found, :shipper}),
         an when is_binary(an) <-
           Keyword.get(cfg, :shipper)
           |> Map.get(:account_number, {:error, :not_found, :account_number}),
         un when is_binary(an) <- Keyword.get(cfg, :username, {:error, :not_found, :username}),
         pw when is_binary(pw) <- Keyword.get(cfg, :password, {:error, :not_found, :password}) do
      %{
        username: un,
        password: pw,
        secret_key: sk,
        shipper: sh
      }
    else
      {:error, :not_found, :shipper} ->
        raise InvalidConfigError,
          message:
            "UPS shipper config key missing. This could be because was provided as a keyword list instead of a map."

      {:error, :not_found, token} ->
        raise InvalidConfigError, message: "UPS config key missing: #{token}"

      {:error, :not_found} ->
        raise InvalidConfigError, message: "UPS config is either invalid or not found."
    end
  end
end
