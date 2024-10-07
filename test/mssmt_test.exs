defmodule MSSMTTest do
  use ExUnit.Case
  doctest MSSMT

  setup do
    {:ok, tree: MSSMT.new()}
  end

  test "creates a new empty MS-SMT", %{tree: tree} do
    assert tree == %{}
  end

  test "inserts and retrieves a value", %{tree: tree} do
    key = <<1, 2, 3>>
    tree = MSSMT.insert(tree, key, 100)
    assert MSSMT.get(tree, key) == 100
  end

  test "updates a value", %{tree: tree} do
    key = <<1, 2, 3>>
    tree = MSSMT.insert(tree, key, 100)
    tree = MSSMT.update(tree, key, 200)
    assert MSSMT.get(tree, key) == 200
  end

  test "updates a non-existent key", %{tree: tree} do
    key = <<1, 2, 3>>
    tree = MSSMT.update(tree, key, 200)
    assert MSSMT.get(tree, key) == nil
  end

  test "deletes a value", %{tree: tree} do
    key = <<1, 2, 3>>
    tree = MSSMT.insert(tree, key, 100)
    tree = MSSMT.delete(tree, key)
    assert MSSMT.get(tree, key) == nil
  end

  test "deletes a non-existent key", %{tree: tree} do
    key = <<1, 2, 3>>
    tree = MSSMT.delete(tree, key)
    assert tree == %{}
  end

  test "calculates root hash", %{tree: tree} do
    tree = MSSMT.insert(tree, <<1>>, 100)
    tree = MSSMT.insert(tree, <<2>>, 200)
    root_hash = MSSMT.root_hash(tree)
    assert is_binary(root_hash)
    assert byte_size(root_hash) == 32
  end

  test "calculates total sum", %{tree: tree} do
    tree = MSSMT.insert(tree, <<1>>, 100)
    tree = MSSMT.insert(tree, <<2>>, 200)
    assert MSSMT.total_sum(tree) == 300
  end

  test "generates and verifies proof of inclusion", %{tree: tree} do
    key1 = <<1>>
    key2 = <<2>>
    key3 = <<3>>
    tree = MSSMT.insert(tree, key1, 100)
    tree = MSSMT.insert(tree, key2, 200)
    tree = MSSMT.insert(tree, key3, 300)

    root_hash = MSSMT.root_hash(tree)
    proof = MSSMT.generate_proof(tree, key2)

    assert MSSMT.verify_proof(root_hash, key2, 200, proof)
    # Wrong value
    refute MSSMT.verify_proof(root_hash, key2, 300, proof)
    # Wrong key
    refute MSSMT.verify_proof(root_hash, key1, 200, proof)
    # Corrupted proof
    bad_proof =
      Enum.map(proof, fn node ->
        %{node | hash: <<0::256>>}
      end)

    refute MSSMT.verify_proof(root_hash, key2, 200, bad_proof)
  end

  test "handles large number of insertions", %{tree: tree} do
    tree =
      Enum.reduce(1..1000, tree, fn i, acc ->
        MSSMT.insert(acc, <<i::32>>, i)
      end)

    assert MSSMT.total_sum(tree) == Enum.sum(1..1000)
    assert byte_size(MSSMT.root_hash(tree)) == 32
  end

  test "maintains correct state after mixed operations", %{tree: tree} do
    tree = MSSMT.insert(tree, <<1>>, 100)
    tree = MSSMT.insert(tree, <<2>>, 200)
    tree = MSSMT.insert(tree, <<3>>, 300)
    tree = MSSMT.update(tree, <<2>>, 250)
    tree = MSSMT.delete(tree, <<1>>)

    assert MSSMT.get(tree, <<1>>) == nil
    assert MSSMT.get(tree, <<2>>) == 250
    assert MSSMT.get(tree, <<3>>) == 300
    assert MSSMT.total_sum(tree) == 550
  end

  test "handles binary keys of different lengths", %{tree: tree} do
    tree = MSSMT.insert(tree, <<1>>, 100)
    tree = MSSMT.insert(tree, <<1, 2>>, 200)
    tree = MSSMT.insert(tree, <<1, 2, 3>>, 300)

    assert MSSMT.get(tree, <<1>>) == 100
    assert MSSMT.get(tree, <<1, 2>>) == 200
    assert MSSMT.get(tree, <<1, 2, 3>>) == 300
    assert MSSMT.total_sum(tree) == 600
  end

  test "handles non-existent keys", %{tree: tree} do
    assert MSSMT.get(tree, <<0>>) == nil
    assert MSSMT.total_sum(tree) == 0
  end

  test "rejects invalid inputs for insert", %{tree: tree} do
    assert_raise FunctionClauseError, fn ->
      MSSMT.insert(tree, 123, 100)
    end

    assert_raise FunctionClauseError, fn ->
      MSSMT.insert(tree, <<1>>, "invalid_value")
    end
  end

  test "rejects invalid inputs for update", %{tree: tree} do
    assert_raise FunctionClauseError, fn ->
      MSSMT.update(tree, 123, 100)
    end

    assert_raise FunctionClauseError, fn ->
      MSSMT.update(tree, <<1>>, "invalid_value")
    end
  end

  test "verifies proof for non-existent key", %{tree: tree} do
    tree = MSSMT.insert(tree, <<1>>, 100)
    root_hash = MSSMT.root_hash(tree)
    proof = MSSMT.generate_proof(tree, <<2>>)
    # Since <<2>> is not in the tree, the proof should fail
    refute MSSMT.verify_proof(root_hash, <<2>>, 200, proof)
  end

  test "handles empty tree operations", %{tree: tree} do
    assert MSSMT.root_hash(tree) == nil
    assert MSSMT.total_sum(tree) == 0
    proof = MSSMT.generate_proof(tree, <<1>>)
    assert proof == []
  end
end
