defmodule MSSMT.NodeHash do
  @moduledoc """
  Module representing a node hash in the Merkle Sum Sparse Merkle Tree (MSSMT).
  """

  @type t :: <<_::256>>
  @hash_size 32

  @doc """
  Returns a zero hash (hash of all zeros).

  ## Examples

      iex> MSSMT.NodeHash.zero()
      <<0::256>>

  """
  @spec zero() :: t()
  def zero(), do: :binary.copy(<<0>>, @hash_size)
end
