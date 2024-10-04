defmodule MSSMT do
  @moduledoc """
  Implementation of a Merkle-Sum Sparse Merkle Tree (MS-SMT).
  """

  defmodule Node do
    @moduledoc """
    Represents a node in the MS-SMT.
    """
    defstruct [:key, :value, :hash, :sum]
  end

  @doc """
  Creates a new empty MS-SMT.
  """
  def new do
    %{}
  end

  @doc """
  Inserts a key-value pair into the MS-SMT.
  """
  def insert(tree, key, value) do
    node = %Node{key: key, value: value, hash: hash(key, value), sum: value}
    Map.put(tree, key, node)
  end

  @doc """
  Retrieves the value associated with a key from the MS-SMT.
  """
  def get(tree, key) do
    case Map.get(tree, key) do
      nil -> nil
      node -> node.value
    end
  end

  @doc """
  Updates the value associated with a key in the MS-SMT.
  """
  def update(tree, key, value) do
    case Map.get(tree, key) do
      nil ->
        tree

      node ->
        updated_node = %{node | value: value, hash: hash(key, value), sum: value}
        Map.put(tree, key, updated_node)
    end
  end

  @doc """
  Deletes a key-value pair from the MS-SMT.
  """
  def delete(tree, key) do
    Map.delete(tree, key)
  end

  @doc """
  Calculates the root hash of the MS-SMT.
  """
  def root_hash(tree) do
    tree
    |> Map.values()
    |> Enum.reduce("", fn node, acc -> hash(acc, node.hash) end)
  end

  @doc """
  Calculates the total sum of all values in the MS-SMT.
  """
  def total_sum(tree) do
    tree
    |> Map.values()
    |> Enum.reduce(0, fn node, acc -> acc + node.sum end)
  end

  # Private helper function to calculate hash
  defp hash(key, value) do
    :crypto.hash(:sha256, "#{key}#{value}") |> Base.encode16()
  end
end
