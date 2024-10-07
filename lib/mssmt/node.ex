defprotocol MSSMT.Node do
  @moduledoc """
  Protocol defining the behavior for nodes in the MSSMT.
  """

  @doc """
  Computes the node's hash.
  """
  @spec node_hash(t()) :: MSSMT.NodeHash.t()
  def node_hash(node)

  @doc """
  Computes the node's sum.
  """
  @spec node_sum(t()) :: non_neg_integer()
  def node_sum(node)

  @doc """
  Returns a copy of the node.

  Since structs are immutable, this returns the node itself.
  """
  @spec copy(t()) :: t()
  def copy(node)
end
