defmodule Shippex do

  defmodule InvalidConfigError do
    defexception [:message]

    def exception(message) do
      "Invalid config: #{message}"
    end
  end

  @doc """
  config :shippex, :carriers, [
    ups: [
      username: "MyUsername",
      password: "MyPassword",
      secret_key: "123123",
      shipper_number: "AB1234"
    ]
  ]
  """
  def config do
    case Application.get_env(:shippex, :carriers, :not_found) do
      :not_found -> raise InvalidConfigError, "Shippex config not found"

      config -> config
    end
  end
end
