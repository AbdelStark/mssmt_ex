defmodule MSSMT do
  @moduledoc """
  Implementation of a Merkle-Sum Sparse Merkle Tree (MS-SMT).

  A MS-SMT is a data structure that combines the features of a Merkle tree
  and a sum tree, allowing for efficient proofs of inclusion and accumulation
  of values.
  """

  defmodule Node do
    @moduledoc """
    Represents a node in the MS-SMT.

    Each node contains:
    - `key`: The unique identifier for the leaf node.
    - `value`: The value associated with the key.
    - `hash`: The cryptographic hash of the node.
    - `sum`: The cumulative sum of values from the leaves up to this node.
    """
    defstruct [:key, :value, :hash, :sum]
  end

  @doc """
  Creates a new empty MS-SMT.
  """
  @spec new() :: map()
  def new do
    %{}
  end

  @doc """
  Inserts a key-value pair into the MS-SMT.

  ## Examples

      iex> tree = MSSMT.new()
      iex> tree = MSSMT.insert(tree, "key1", 100)
      iex> MSSMT.get(tree, "key1")
      100

  """
  @spec insert(map(), binary(), number()) :: map()
  def insert(tree, key, value) when is_binary(key) and is_number(value) do
    node = %Node{
      key: key,
      value: value,
      hash: leaf_hash(key, value),
      sum: value
    }

    Map.put(tree, key, node)
  end

  @doc """
  Retrieves the value associated with a key from the MS-SMT.

  Returns `nil` if the key does not exist.

  ## Examples

      iex> tree = MSSMT.new()
      iex> MSSMT.get(tree, "nonexistent_key")
      nil

  """
  @spec get(map(), binary()) :: number() | nil
  def get(tree, key) when is_binary(key) do
    case Map.get(tree, key) do
      nil -> nil
      node -> node.value
    end
  end

  @doc """
  Updates the value associated with a key in the MS-SMT.

  If the key does not exist, the tree remains unchanged.

  ## Examples

      iex> tree = MSSMT.new()
      iex> tree = MSSMT.insert(tree, "key1", 100)
      iex> tree = MSSMT.update(tree, "key1", 200)
      iex> MSSMT.get(tree, "key1")
      200

  """
  @spec update(map(), binary(), number()) :: map()
  def update(tree, key, value) when is_binary(key) and is_number(value) do
    case Map.get(tree, key) do
      nil ->
        tree

      node ->
        updated_node = %Node{
          node
          | value: value,
            hash: leaf_hash(key, value),
            sum: value
        }

        Map.put(tree, key, updated_node)
    end
  end

  @doc """
  Deletes a key-value pair from the MS-SMT.

  ## Examples

      iex> tree = MSSMT.new()
      iex> tree = MSSMT.insert(tree, "key1", 100)
      iex> tree = MSSMT.delete(tree, "key1")
      iex> MSSMT.get(tree, "key1")
      nil

  """
  @spec delete(map(), binary()) :: map()
  def delete(tree, key) when is_binary(key) do
    Map.delete(tree, key)
  end

  @doc """
  Calculates the root hash of the MS-SMT.

  The root hash is a cryptographic representation of the entire tree state.

  ## Examples

      iex> tree = MSSMT.new()
      iex> tree = MSSMT.insert(tree, "key1", 100)
      iex> root_hash = MSSMT.root_hash(tree)
      iex> byte_size(root_hash)
      32

  """
  @spec root_hash(map()) :: binary() | nil
  def root_hash(tree) do
    tree
    |> Map.values()
    |> Enum.sort_by(& &1.key)
    |> calculate_root_hash()
  end

  @doc """
  Calculates the total sum of all values in the MS-SMT.

  ## Examples

      iex> tree = MSSMT.new()
      iex> tree = MSSMT.insert(tree, "key1", 100)
      iex> tree = MSSMT.insert(tree, "key2", 200)
      iex> MSSMT.total_sum(tree)
      300

  """
  @spec total_sum(map()) :: number()
  def total_sum(tree) do
    tree
    |> Map.values()
    |> Enum.reduce(0, fn node, acc -> acc + node.sum end)
  end

  @doc """
  Generates a proof of inclusion for a given key.

  The proof consists of the necessary sibling nodes to reconstruct the root hash.

  ## Examples

      iex> tree = MSSMT.new()
      iex> tree = MSSMT.insert(tree, "key1", 100)
      iex> proof = MSSMT.generate_proof(tree, "key1")
      iex> is_list(proof)
      true

  """
  @spec generate_proof(map(), binary()) :: list(Node.t())
  def generate_proof(tree, key) when is_binary(key) do
    sorted_nodes = tree |> Map.values() |> Enum.sort_by(& &1.key)
    do_generate_proof(sorted_nodes, key, [])
  end

  defp do_generate_proof([], _key, proof), do: Enum.reverse(proof)

  defp do_generate_proof([%Node{key: node_key} = node | rest], key, proof) do
    if node_key == key do
      Enum.reverse(proof) ++ rest
    else
      do_generate_proof(rest, key, [node | proof])
    end
  end

  @doc """
  Verifies a proof of inclusion for a given key and value.

  Returns `true` if the proof is valid, `false` otherwise.

  ## Examples

      iex> tree = MSSMT.new()
      iex> tree = MSSMT.insert(tree, "key1", 100)
      iex> root_hash = MSSMT.root_hash(tree)
      iex> proof = MSSMT.generate_proof(tree, "key1")
      iex> MSSMT.verify_proof(root_hash, "key1", 100, proof)
      true

  """
  @spec verify_proof(binary() | nil, binary(), number(), list(Node.t())) :: boolean()
  def verify_proof(root_hash, key, value, proof) when is_binary(key) and is_number(value) do
    leaf = %Node{
      key: key,
      value: value,
      hash: leaf_hash(key, value),
      sum: value
    }

    nodes = [leaf | proof] |> Enum.sort_by(& &1.key)
    calculated_hash = calculate_root_hash(nodes)
    calculated_hash == root_hash
  end

  # Private helper functions

  @doc false
  @spec leaf_hash(binary(), number()) :: binary()
  defp leaf_hash(key, value) when is_binary(key) and is_number(value) do
    :crypto.hash(:sha256, key <> :erlang.term_to_binary(value))
  end

  @doc false
  @spec calculate_root_hash([Node.t()]) :: binary() | nil
  defp calculate_root_hash([]), do: nil

  defp calculate_root_hash([single_node]) do
    single_node.hash
  end

  defp calculate_root_hash(nodes) when length(nodes) > 1 do
    nodes
    |> Enum.chunk_every(2)
    |> Enum.map(&merge_nodes/1)
    |> calculate_root_hash()
  end

  @doc false
  @spec merge_nodes([Node.t()]) :: Node.t()
  defp merge_nodes([left, right]) do
    combined_hash = hash_nodes(left, right)
    combined_sum = left.sum + right.sum

    %Node{
      key: left.key,
      hash: combined_hash,
      sum: combined_sum
    }
  end

  defp merge_nodes([single]) do
    single
  end

  @doc false
  @spec hash_nodes(Node.t(), Node.t()) :: binary()
  defp hash_nodes(left, right) do
    :crypto.hash(
      :sha256,
      left.hash <> <<left.sum::64>> <> right.hash <> <<right.sum::64>>
    )
  end
end
