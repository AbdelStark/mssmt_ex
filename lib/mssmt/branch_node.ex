defmodule MSSMT.BranchNode do
  @moduledoc """
  Represents a branch node in the MSSMT.
  """

  alias MSSMT.{Node, NodeHash}

  defstruct [:left, :right]

  @type t :: %__MODULE__{
          left: Node.t(),
          right: Node.t()
        }

  @doc """
  Creates a new branch node.

  ## Parameters

    - `left`: The left child node.
    - `right`: The right child node.

  ## Examples

      iex> MSSMT.BranchNode.new(left_node, right_node)
      %MSSMT.BranchNode{...}

  """
  @spec new(Node.t(), Node.t()) :: t()
  def new(left, right) do
    %__MODULE__{left: left, right: right}
  end

  @doc """
  Computes the hash of the branch node.

  The hash is computed over the concatenation of the left and right child hashes and the sum of their sums (as unsigned little-endian 64-bit integer).

  ## Examples

      iex> MSSMT.BranchNode.compute_hash(branch_node)
      <<...>>

  """
  @spec compute_hash(t()) :: NodeHash.t()
  def compute_hash(%__MODULE__{left: left, right: right}) do
    sum = Node.node_sum(left) + Node.node_sum(right)

    :crypto.hash(
      :sha256,
      Node.node_hash(left) <> Node.node_hash(right) <> <<sum::unsigned-little-64>>
    )
  end
end

defimpl MSSMT.Node, for: MSSMT.BranchNode do
  @doc """
  Computes the hash of the branch node.
  """
  def node_hash(branch) do
    MSSMT.BranchNode.compute_hash(branch)
  end

  @doc """
  Returns the sum associated with the branch node.
  """
  def node_sum(branch) do
    MSSMT.Node.node_sum(branch.left) + MSSMT.Node.node_sum(branch.right)
  end

  @doc """
  Returns a copy of the branch node.

  Since structs are immutable, this returns the node itself.
  """
  def copy(branch), do: branch
end
