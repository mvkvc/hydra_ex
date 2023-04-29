defmodule Hydra.MixProject do
  use Mix.Project

  def project do
    [
      app: :hydra_ex,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:yamerl, "~> 0.4.0"}
    ]
  end
end
