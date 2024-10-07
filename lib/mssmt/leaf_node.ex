defmodule MSSMT.LeafNode do
  @moduledoc """
  Represents a leaf node in the Merkle Sum Sparse Merkle Tree (MSSMT).
  """

  alias MSSMT.NodeHash

  defstruct [:key, :value, :sum]

  @type t :: %__MODULE__{
          key: <<_::256>>,
          value: binary(),
          sum: non_neg_integer()
        }

  @doc """
  Creates a new leaf node.

  ## Parameters

    - `key`: The key associated with the leaf (256-bit binary).
    - `value`: The value stored in the leaf.
    - `sum`: The sum associated with the leaf.

  ## Examples

      iex> MSSMT.LeafNode.new(key, "value", 100)
      %MSSMT.LeafNode{...}

  """
  @spec new(<<_::256>>, binary(), non_neg_integer()) :: t()
  def new(key, value, sum) do
    %__MODULE__{key: key, value: value, sum: sum}
  end

  @doc """
  Computes the hash of the leaf node.

  The hash is computed over the concatenation of the value and the sum (as unsigned little-endian 64-bit integer).

  ## Examples

      iex> MSSMT.LeafNode.compute_hash(leaf_node)
      <<...>>

  """
  @spec compute_hash(t()) :: NodeHash.t()
  def compute_hash(%__MODULE__{value: value, sum: sum}) do
    :crypto.hash(:sha256, value <> <<sum::unsigned-little-64>>)
  end
end

defimpl MSSMT.Node, for: MSSMT.LeafNode do
  @doc """
  Computes the hash of the leaf node.
  """
  def node_hash(leaf) do
    MSSMT.LeafNode.compute_hash(leaf)
  end

  @doc """
  Returns the sum associated with the leaf node.
  """
  def node_sum(%{sum: sum}), do: sum

  @doc """
  Returns a copy of the leaf node.

  Since structs are immutable, this returns the node itself.
  """
  def copy(leaf), do: leaf
end
