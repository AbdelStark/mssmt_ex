defmodule MSSMTTest do
  @moduledoc """
  Test suite for the MSSMT module.
  """

  use ExUnit.Case
  doctest MSSMT

  test "new tree" do
    tree = MSSMT.new()
    assert MSSMT.root_hash(tree) == <<0::256>>
    assert MSSMT.total_sum(tree) == 0
  end

  test "insert and get operations" do
    tree = MSSMT.new()
    key = :crypto.strong_rand_bytes(32)
    value = "value1"
    sum = 100

    {:ok, tree} = MSSMT.insert(tree, key, value, sum)
    {:ok, retrieved_value, retrieved_sum} = MSSMT.get(tree, key)

    assert retrieved_value == value
    assert retrieved_sum == sum
  end

  test "update existing key" do
    tree = MSSMT.new()
    key = :crypto.strong_rand_bytes(32)
    value1 = "value1"
    sum1 = 100

    {:ok, tree} = MSSMT.insert(tree, key, value1, sum1)

    value2 = "value2"
    sum2 = 200

    {:ok, tree} = MSSMT.insert(tree, key, value2, sum2)
    {:ok, retrieved_value, retrieved_sum} = MSSMT.get(tree, key)

    assert retrieved_value == value2
    assert retrieved_sum == sum2
  end

  test "generate and verify proof" do
    tree = MSSMT.new()
    key1 = :crypto.strong_rand_bytes(32)
    key2 = :crypto.strong_rand_bytes(32)
    value1 = "value1"
    value2 = "value2"
    sum1 = 100
    sum2 = 200

    {:ok, tree} = MSSMT.insert(tree, key1, value1, sum1)
    {:ok, tree} = MSSMT.insert(tree, key2, value2, sum2)

    proof = MSSMT.merkle_proof(tree, key1)
    root_hash = MSSMT.root_hash(tree)
    assert MSSMT.verify_proof(root_hash, key1, value1, sum1, proof)

    # Test invalid proof
    refute MSSMT.verify_proof(root_hash, key1, value1, sum1 + 1, proof)
  end

  test "total sum calculation" do
    tree = MSSMT.new()
    key1 = :crypto.strong_rand_bytes(32)
    key2 = :crypto.strong_rand_bytes(32)
    key3 = :crypto.strong_rand_bytes(32)
    value1 = "value1"
    value2 = "value2"
    value3 = "value3"
    sum1 = 100
    sum2 = 200

    {:ok, tree} = MSSMT.insert(tree, key1, value1, sum1)
    {:ok, tree} = MSSMT.insert(tree, key2, value2, sum2)

    assert MSSMT.total_sum(tree) == sum1 + sum2

    sum3 = 300
    {:ok, tree} = MSSMT.insert(tree, key3, value3, sum3)
    assert MSSMT.total_sum(tree) == sum1 + sum2 + sum3
  end

  test "delete operation" do
    tree = MSSMT.new()
    key = :crypto.strong_rand_bytes(32)
    value = "value"
    sum = 100

    {:ok, tree} = MSSMT.insert(tree, key, value, sum)
    {:ok, retrieved_value, retrieved_sum} = MSSMT.get(tree, key)
    assert retrieved_value == value
    assert retrieved_sum == sum

    {:ok, tree} = MSSMT.delete(tree, key)
    assert MSSMT.get(tree, key) == {:error, :not_found}
    assert MSSMT.total_sum(tree) == 0
  end

  test "non-existent key" do
    tree = MSSMT.new()
    key = :crypto.strong_rand_bytes(32)
    assert MSSMT.get(tree, key) == {:error, :not_found}
  end

  test "root hash changes with tree modifications" do
    tree = MSSMT.new()
    initial_hash = MSSMT.root_hash(tree)

    key = :crypto.strong_rand_bytes(32)
    {:ok, tree} = MSSMT.insert(tree, key, "value", 100)
    assert MSSMT.root_hash(tree) != initial_hash

    {:ok, tree} = MSSMT.delete(tree, key)
    assert MSSMT.root_hash(tree) == initial_hash
  end

  test "merkle proof for non-existent key" do
    tree = MSSMT.new()
    key = :crypto.strong_rand_bytes(32)
    proof = MSSMT.merkle_proof(tree, key)
    assert proof == []
  end

  test "delete non-existent key" do
    tree = MSSMT.new()
    key = :crypto.strong_rand_bytes(32)
    assert MSSMT.delete(tree, key) == {:error, :not_found}
  end
end
