defmodule MSSMT.MixProject do
  use Mix.Project

  def project do
    [
      app: :mssmt,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      description: "An Elixir implementation of a Merkle-Sum Sparse Merkle Tree (MS-SMT).",
      package: package(),
      deps: deps(),
      name: "MSSMT",
      source_url: "https://github.com/AbdelStark/mssmt",
      homepage_url: "https://github.com/AbdelStark/mssmt",
      docs: [
        main: "MSSMT",
        extras: ["README.md"]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger, :crypto]
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.28", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end

  defp package do
    [
      name: "mssmt",
      maintainers: ["@AbdelStark"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/AbdelStark/mssmt"
      },
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE)
    ]
  end
end
