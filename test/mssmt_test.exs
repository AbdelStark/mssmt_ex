defmodule MSSMTTest do
  use ExUnit.Case
  doctest MSSMT

  test "creates a new empty MS-SMT" do
    assert MSSMT.new() == %{}
  end

  test "inserts and retrieves a value" do
    tree = MSSMT.new()
    tree = MSSMT.insert(tree, "key1", 100)
    assert MSSMT.get(tree, "key1") == 100
  end

  test "updates a value" do
    tree = MSSMT.new()
    tree = MSSMT.insert(tree, "key1", 100)
    tree = MSSMT.update(tree, "key1", 200)
    assert MSSMT.get(tree, "key1") == 200
  end

  test "deletes a value" do
    tree = MSSMT.new()
    tree = MSSMT.insert(tree, "key1", 100)
    tree = MSSMT.delete(tree, "key1")
    assert MSSMT.get(tree, "key1") == nil
  end

  test "calculates root hash" do
    tree = MSSMT.new()
    tree = MSSMT.insert(tree, "key1", 100)
    tree = MSSMT.insert(tree, "key2", 200)
    assert is_binary(MSSMT.root_hash(tree))
  end

  test "calculates total sum" do
    tree = MSSMT.new()
    tree = MSSMT.insert(tree, "key1", 100)
    tree = MSSMT.insert(tree, "key2", 200)
    assert MSSMT.total_sum(tree) == 300
  end
end
