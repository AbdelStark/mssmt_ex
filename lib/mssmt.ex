defmodule MSSMT do
  @moduledoc """
  Merkle Sum Sparse Merkle Tree (MSSMT) implementation.

  Provides functions to create, insert, retrieve, delete, and verify elements in the MSSMT.
  """

  @hash_size 32
  @max_tree_height @hash_size * 8

  alias MSSMT.{LeafNode, BranchNode, NodeHash, Node}

  import Bitwise

  @doc """
  Creates a new empty MSSMT.

  ## Examples

      iex> _tree = MSSMT.new()
      nil

  """
  @spec new() :: nil
  def new(), do: nil

  @doc """
  Inserts a key-value pair with an associated sum into the MSSMT.

  ## Parameters

    - `tree`: The current tree.
    - `key`: The key to insert (256-bit binary).
    - `value`: The value associated with the key.
    - `sum`: The sum associated with the key.

  ## Examples

      iex> tree = MSSMT.new()
      iex> key = :crypto.strong_rand_bytes(32)
      iex> {:ok, tree} = MSSMT.insert(tree, key, "value", 100)
      iex> {:ok, value, sum} = MSSMT.get(tree, key)
      iex> value
      "value"
      iex> sum
      100

  """
  @spec insert(Node.t() | nil, <<_::256>>, binary(), non_neg_integer()) :: {:ok, Node.t()}
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

  @doc """
  Retrieves the value and sum associated with a key in the MSSMT.

  ## Parameters

    - `tree`: The current tree.
    - `key`: The key to retrieve (256-bit binary).

  ## Examples

      iex> tree = MSSMT.new()
      iex> key = :crypto.strong_rand_bytes(32)
      iex> {:ok, tree} = MSSMT.insert(tree, key, "value", 100)
      iex> {:ok, value, sum} = MSSMT.get(tree, key)
      iex> value
      "value"
      iex> sum
      100

  """
  @spec get(Node.t() | nil, <<_::256>>) ::
          {:ok, binary(), non_neg_integer()} | {:error, :not_found}
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

  @doc """
  Generates a Merkle proof for a given key.

  ## Parameters

    - `tree`: The current tree.
    - `key`: The key to generate the proof for (256-bit binary).

  ## Examples

      iex> tree = MSSMT.new()
      iex> key = :crypto.strong_rand_bytes(32)
      iex> {:ok, tree} = MSSMT.insert(tree, key, "value", 100)
      iex> proof = MSSMT.merkle_proof(tree, key)
      iex> is_list(proof)
      true

  """
  @spec merkle_proof(Node.t() | nil, <<_::256>>) :: [Node.t()]
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

  @doc """
  Verifies a Merkle proof against a root hash.

  ## Parameters

    - `root_hash`: The root hash of the MSSMT.
    - `key`: The key the proof is for (256-bit binary).
    - `value`: The value associated with the key.
    - `sum`: The sum associated with the key.
    - `proof`: The Merkle proof as a list of sibling nodes.

  ## Examples

      iex> tree = MSSMT.new()
      iex> key = :crypto.strong_rand_bytes(32)
      iex> {:ok, tree} = MSSMT.insert(tree, key, "value", 100)
      iex> proof = MSSMT.merkle_proof(tree, key)
      iex> root_hash = MSSMT.root_hash(tree)
      iex> MSSMT.verify_proof(root_hash, key, "value", 100, proof)
      true

  """
  @spec verify_proof(NodeHash.t(), <<_::256>>, binary(), non_neg_integer(), [Node.t()]) ::
          boolean()
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

  @doc """
  Returns the root hash of the MSSMT.

  ## Examples

      iex> tree = MSSMT.new()
      iex> root_hash = MSSMT.root_hash(tree)
      iex> root_hash == <<0::256>>
      true

  """
  @spec root_hash(Node.t() | nil) :: NodeHash.t()
  def root_hash(nil), do: NodeHash.zero()
  def root_hash(tree), do: Node.node_hash(tree)

  @doc """
  Returns the total sum of all nodes in the MSSMT.

  ## Examples

      iex> tree = MSSMT.new()
      iex> key1 = :crypto.strong_rand_bytes(32)
      iex> key2 = :crypto.strong_rand_bytes(32)
      iex> {:ok, tree} = MSSMT.insert(tree, key1, "value1", 100)
      iex> {:ok, tree} = MSSMT.insert(tree, key2, "value2", 200)
      iex> MSSMT.total_sum(tree)
      300

  """
  @spec total_sum(Node.t() | nil) :: non_neg_integer()
  def total_sum(nil), do: 0
  def total_sum(tree), do: Node.node_sum(tree)

  @doc """
  Deletes a key from the MSSMT.

  ## Parameters

    - `tree`: The current tree.
    - `key`: The key to delete (256-bit binary).

  ## Examples

      iex> tree = MSSMT.new()
      iex> key = :crypto.strong_rand_bytes(32)
      iex> {:ok, tree} = MSSMT.insert(tree, key, "value", 100)
      iex> {:ok, tree} = MSSMT.delete(tree, key)
      iex> MSSMT.get(tree, key)
      {:error, :not_found}

  """
  @spec delete(Node.t() | nil, <<_::256>>) :: {:ok, Node.t() | nil} | {:error, :not_found}
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

  defp maybe_collapse(%BranchNode{left: nil, right: nil}), do: nil
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
