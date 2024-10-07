defmodule MSSMT.NodeHash do
  @moduledoc false
  @type t :: <<_::256>>
  @hash_size 32

  @spec zero() :: t()
  def zero(), do: :binary.copy(<<0>>, @hash_size)
end

defprotocol MSSMT.Node do
  @spec node_hash(t()) :: MSSMT.NodeHash.t()
  def node_hash(node)

  @spec node_sum(t()) :: non_neg_integer()
  def node_sum(node)

  @spec copy(t()) :: t()
  def copy(node)
end

defmodule MSSMT.LeafNode do
  alias MSSMT.NodeHash

  defstruct [:key, :value, :sum, :node_hash]

  @type t :: %__MODULE__{
          key: <<_::256>>,
          value: binary(),
          sum: non_neg_integer(),
          node_hash: NodeHash.t() | nil
        }

  def new(key, value, sum) do
    %__MODULE__{key: key, value: value, sum: sum}
  end

  def compute_hash(%__MODULE__{value: value, sum: sum}) do
    :crypto.hash(:sha256, value <> <<sum::unsigned-little-64>>)
  end
end

defimpl MSSMT.Node, for: MSSMT.LeafNode do
  def node_hash(%{node_hash: nil} = leaf) do
    hash = MSSMT.LeafNode.compute_hash(leaf)
    %{leaf | node_hash: hash}
    hash
  end

  def node_hash(%{node_hash: hash}), do: hash

  def node_sum(%{sum: sum}), do: sum

  def copy(leaf), do: %{leaf | node_hash: nil}
end

defmodule MSSMT.BranchNode do
  alias MSSMT.{Node, NodeHash}

  defstruct [:left, :right, :node_hash, :sum]

  @type t :: %__MODULE__{
          left: Node.t(),
          right: Node.t(),
          node_hash: NodeHash.t() | nil,
          sum: non_neg_integer() | nil
        }

  def new(left, right) do
    %__MODULE__{left: left, right: right}
  end

  def compute_hash(%__MODULE__{left: left, right: right} = branch) do
    sum = Node.node_sum(branch)

    :crypto.hash(
      :sha256,
      Node.node_hash(left) <> Node.node_hash(right) <> <<sum::unsigned-little-64>>
    )
  end
end

defimpl MSSMT.Node, for: MSSMT.BranchNode do
  def node_hash(%{node_hash: nil} = branch) do
    hash = MSSMT.BranchNode.compute_hash(branch)
    %{branch | node_hash: hash}
    hash
  end

  def node_hash(%{node_hash: hash}), do: hash

  def node_sum(%{sum: nil, left: left, right: right} = branch) do
    sum = MSSMT.Node.node_sum(left) + MSSMT.Node.node_sum(right)
    %{branch | sum: sum}
    sum
  end

  def node_sum(%{sum: sum}), do: sum

  def copy(branch), do: %{branch | node_hash: nil, sum: nil}
end

defmodule MSSMT do
  @hash_size 32
  @max_tree_height @hash_size * 8

  alias MSSMT.{LeafNode, BranchNode, NodeHash, Node}

  import Bitwise

  def new(), do: nil

  def insert(tree, key, value, sum) when byte_size(key) == @hash_size do
    leaf = LeafNode.new(key, value, sum)
    {:ok, do_insert(tree, key, leaf, 0)}
  end

  defp do_insert(nil, _key, leaf, _height), do: leaf

  defp do_insert(%LeafNode{key: existing_key} = existing_leaf, key, new_leaf, height) do
    cond do
      existing_key == key ->
        new_leaf

      height >= @max_tree_height ->
        raise "Cannot split nodes further, keys are identical"

      true ->
        split_node(existing_leaf, new_leaf, height)
    end
  end

  defp do_insert(%BranchNode{left: left, right: right}, key, leaf, height) do
    if get_bit(key, height) == 0 do
      BranchNode.new(do_insert(left, key, leaf, height + 1), right)
    else
      BranchNode.new(left, do_insert(right, key, leaf, height + 1))
    end
  end

  defp split_node(leaf1, leaf2, height) do
    if get_bit(leaf1.key, height) == 0 do
      BranchNode.new(leaf1, leaf2)
    else
      BranchNode.new(leaf2, leaf1)
    end
  end

  def get(tree, key) when byte_size(key) == @hash_size do
    do_get(tree, key, 0)
  end

  defp do_get(nil, _key, _height), do: {:error, :not_found}

  defp do_get(%LeafNode{key: leaf_key, value: value, sum: sum}, key, _height) do
    if leaf_key == key do
      {:ok, value, sum}
    else
      {:error, :not_found}
    end
  end

  defp do_get(%BranchNode{left: left, right: right}, key, height) do
    if get_bit(key, height) == 0 do
      do_get(left, key, height + 1)
    else
      do_get(right, key, height + 1)
    end
  end

  def merkle_proof(tree, key) when byte_size(key) == @hash_size do
    {proof_nodes, _} = do_merkle_proof(tree, key, 0, [])
    Enum.reverse(proof_nodes)
  end

  defp do_merkle_proof(nil, _key, _height, acc), do: {acc, nil}

  defp do_merkle_proof(%LeafNode{} = leaf, _key, _height, acc), do: {acc, leaf}

  defp do_merkle_proof(%BranchNode{left: left, right: right}, key, height, acc) do
    if get_bit(key, height) == 0 do
      do_merkle_proof(left, key, height + 1, [right | acc])
    else
      do_merkle_proof(right, key, height + 1, [left | acc])
    end
  end

  def verify_proof(root_hash, key, value, sum, proof) when byte_size(key) == @hash_size do
    leaf = LeafNode.new(key, value, sum)
    leaf_hash = Node.node_hash(leaf)

    {computed_hash, _} =
      Enum.reduce(Enum.with_index(proof), {leaf_hash, sum}, fn {sibling, height},
                                                               {current_hash, current_sum} ->
        sibling_hash = Node.node_hash(sibling)
        sibling_sum = Node.node_sum(sibling)

        if get_bit(key, height) == 0 do
          new_sum = current_sum + sibling_sum

          new_hash =
            :crypto.hash(:sha256, current_hash <> sibling_hash <> <<new_sum::unsigned-little-64>>)

          {new_hash, new_sum}
        else
          new_sum = sibling_sum + current_sum

          new_hash =
            :crypto.hash(:sha256, sibling_hash <> current_hash <> <<new_sum::unsigned-little-64>>)

          {new_hash, new_sum}
        end
      end)

    computed_hash == root_hash
  end

  def root_hash(nil), do: NodeHash.zero()
  def root_hash(tree), do: Node.node_hash(tree)

  def total_sum(nil), do: 0
  def total_sum(tree), do: Node.node_sum(tree)

  def delete(tree, key) when byte_size(key) == @hash_size do
    case do_delete(tree, key, 0) do
      {:ok, new_tree} -> {:ok, new_tree}
      :not_found -> {:error, :not_found}
    end
  end

  defp do_delete(nil, _key, _height), do: :not_found

  defp do_delete(%LeafNode{key: leaf_key}, key, _height) do
    if leaf_key == key do
      {:ok, nil}
    else
      :not_found
    end
  end

  defp do_delete(%BranchNode{left: left, right: right}, key, height) do
    if get_bit(key, height) == 0 do
      case do_delete(left, key, height + 1) do
        {:ok, new_left} -> {:ok, maybe_collapse(BranchNode.new(new_left, right))}
        :not_found -> :not_found
      end
    else
      case do_delete(right, key, height + 1) do
        {:ok, new_right} -> {:ok, maybe_collapse(BranchNode.new(left, new_right))}
        :not_found -> :not_found
      end
    end
  end

  defp maybe_collapse(%BranchNode{left: nil, right: right}), do: right
  defp maybe_collapse(%BranchNode{left: left, right: nil}), do: left
  defp maybe_collapse(branch), do: branch

  defp get_bit(key, index) do
    byte_index = div(index, 8)
    bit_index = rem(index, 8)
    <<_::size(byte_index)-bytes, byte::8, _::binary>> = key
    byte >>> (7 - bit_index) &&& 1
  end
end
