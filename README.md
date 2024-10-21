# Merkle-Sum Sparse Merkle Tree (MS-SMT) in Elixir

A **Merkle-Sum Sparse Merkle Tree (MS-SMT)** is a data structure that combines the features of a Merkle tree and a sum tree, allowing for efficient proofs of inclusion and accumulation of values. It's particularly useful for securely storing large amounts of data with the ability to verify the integrity and sum of the data efficiently.

This Elixir implementation provides a simple and efficient MS-SMT library for use in your projects.

## Table of Contents

- [Merkle-Sum Sparse Merkle Tree (MS-SMT) in Elixir](#merkle-sum-sparse-merkle-tree-ms-smt-in-elixir)
  - [Table of Contents](#table-of-contents)
  - [Installation](#installation)
  - [Usage](#usage)
    - [Basic Operations](#basic-operations)
    - [Generating and Verifying Proofs](#generating-and-verifying-proofs)
  - [API Reference](#api-reference)
    - [MSSMT.new/0](#mssmtnew0)
    - [MSSMT.insert/3](#mssmtinsert3)
    - [MSSMT.get/2](#mssmtget2)
    - [MSSMT.delete/2](#mssmtdelete2)
    - [MSSMT.root\_hash/1](#mssmtroot_hash1)
    - [MSSMT.total\_sum/1](#mssmttotal_sum1)
    - [MSSMT.merkle\_proof/2](#mssmtmerkle_proof2)
    - [MSSMT.verify\_proof/4](#mssmtverify_proof4)
  - [Development](#development)
  - [Contributing](#contributing)
  - [License](#license)

## Installation

To use `mssmt` in your Elixir project, add it to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:mssmt, git: "https://github.com/AbdelStark/mssmt.git"}
  ]
end
```

Then run:

```bash
mix deps.get
```

## Usage

### Basic Operations

```elixir
# Import the MSSMT module
import MSSMT

# Create a new empty MS-SMT
tree = MSSMT.new()

# Insert key-value pairs
key1 = :crypto.strong_rand_bytes(32)
key2 = :crypto.strong_rand_bytes(32)
tree = MSSMT.insert(tree, key1, "value1", 100)
tree = MSSMT.insert(tree, key2, "value2", 200)

# Retrieve a value
{:ok, retrieved_value, retrieved_sum} = MSSMT.get(tree, key)

# Delete a key-value pair
{:ok, tree} = MSSMT.delete(tree, key1)

# Calculate root hash
root_hash = MSSMT.root_hash(tree)  # Returns a 32-byte binary hash

# Calculate total sum
total_sum = MSSMT.total_sum(tree)  # Returns 150
```

### Generating and Verifying Proofs

```elixir
key1 = :crypto.strong_rand_bytes(32)
key2 = :crypto.strong_rand_bytes(32)
key3 = :crypto.strong_rand_bytes(32)
tree = MSSMT.new()
tree = MSSMT.insert(tree, key1, "value1", 100)
tree = MSSMT.insert(tree, key2, "value2", 200)
tree = MSSMT.insert(tree, key3, "value3", 300)

proof = MSSMT.generate_proof(tree, key1)

root_hash = MSSMT.root_hash(tree)

# Verify the proof
is_valid = MSSMT.verify_proof(root_hash, key1, "value1", proof)  # Returns true

# Verify with incorrect value
is_valid = MSSMT.verify_proof(root_hash, key1, "value2", proof)  # Returns false

# Verify with incorrect key
is_valid = MSSMT.verify_proof(root_hash, key2, "value2", proof)  # Returns false
```

## API Reference

### MSSMT.new/0

Creates a new empty Merkle-Sum Sparse Merkle Tree.

**Example:**

```elixir
tree = MSSMT.new()
```

---

### MSSMT.insert/3

Inserts a key-value pair into the tree.

- **Parameters:**
  - `tree`: The current tree.
  - `key`: A binary representing the key.
  - `value`: A numeric value associated with the key.
  - `sum`: The sum of the value.

**Example:**

```elixir
key = :crypto.strong_rand_bytes(32)
{:ok, tree} = MSSMT.insert(tree, key, "value1", 100)
```

---

### MSSMT.get/2

Retrieves the value associated with a key.

- **Parameters:**
  - `tree`: The current tree.
  - `key`: A binary representing the key.

**Returns:** The value and sum associated with the key, or `{:error, :not_found}` if the key does not exist.

**Example:**

```elixir
{:ok, retrieved_value, retrieved_sum} = MSSMT.get(tree, key)
```

---

### MSSMT.delete/2

Deletes a key-value pair from the tree.

- **Parameters:**
  - `tree`: The current tree.
  - `key`: A binary representing the key.

**Example:**

```elixir
key = :crypto.strong_rand_bytes(32)
{:ok, tree} = MSSMT.delete(tree, key)
```

---

### MSSMT.root_hash/1

Calculates the root hash of the tree.

- **Parameters:**
  - `tree`: The current tree.

**Returns:** A 32-byte binary hash representing the root of the tree, or `nil` if the tree is empty.

**Example:**

```elixir
root_hash = MSSMT.root_hash(tree)
```

---

### MSSMT.total_sum/1

Calculates the total sum of all values in the tree.

- **Parameters:**
  - `tree`: The current tree.

**Returns:** The total sum as a number.

**Example:**

```elixir
total_sum = MSSMT.total_sum(tree)
```

---

### MSSMT.merkle_proof/2

Generates a proof of inclusion for a given key.

- **Parameters:**
  - `tree`: The current tree.
  - `key`: A binary representing the key.

**Returns:** A list of nodes required to verify the inclusion of the key.

**Example:**

```elixir
key = :crypto.strong_rand_bytes(32)
proof = MSSMT.merkle_proof(tree, key)
```

---

### MSSMT.verify_proof/4

Verifies a proof of inclusion for a given key and value.

- **Parameters:**
  - `root_hash`: The root hash of the tree.
  - `key`: A binary representing the key.
  - `value`: The numeric value associated with the key.
  - `proof`: The proof generated by `generate_proof/2`.

**Returns:** `true` if the proof is valid, `false` otherwise.

**Example:**

```elixir
key = :crypto.strong_rand_bytes(32)
is_valid = MSSMT.verify_proof(root_hash, key, "value1", 100, proof)
```

## Development

To set up the project for development:

1. **Clone the repository:**

   ```bash
   git clone https://github.com/AbdelStark/mssmt.git
   cd mssmt
   ```

2. **Install dependencies:**

   ```bash
   mix deps.get
   ```

3. **Run tests:**

   ```bash
   mix test
   ```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

When contributing, please:

- Write clear, concise commit messages.
- Write tests for new functionality.
- Ensure all tests pass before submitting.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
