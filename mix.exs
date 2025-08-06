defmodule ChangesetUtils.MixProject do
  use Mix.Project

  def project do
    [
      app: :changeset_utils,
      version: "0.1.0",
      elixir: "~> 1.18",
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto, "~> 3.13"}
    ]
  end
end
