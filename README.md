# Merkle-Sum Sparse Merkle Tree (MS-SMT) in Elixir

A **Merkle-Sum Sparse Merkle Tree (MS-SMT)** is a data structure that combines the features of a Merkle tree and a sum tree, allowing for efficient proofs of inclusion and accumulation of values. It's particularly useful for securely storing large amounts of data with the ability to verify the integrity and sum of the data efficiently.

This Elixir implementation provides a simple and efficient MS-SMT library for use in your projects.

## Table of Contents

- [Merkle-Sum Sparse Merkle Tree (MS-SMT) in Elixir](#merkle-sum-sparse-merkle-tree-ms-smt-in-elixir)
  - [Table of Contents](#table-of-contents)
  - [Installation](#installation)
  - [Usage](#usage)
    - [Basic Operations](#basic-operations)
    - [Handling Binary Keys of Different Lengths](#handling-binary-keys-of-different-lengths)
    - [Generating and Verifying Proofs](#generating-and-verifying-proofs)
  - [API Reference](#api-reference)
    - [MSSMT.new/0](#mssmtnew0)
    - [MSSMT.insert/3](#mssmtinsert3)
    - [MSSMT.get/2](#mssmtget2)
    - [MSSMT.update/3](#mssmtupdate3)
    - [MSSMT.delete/2](#mssmtdelete2)
    - [MSSMT.root\_hash/1](#mssmtroot_hash1)
    - [MSSMT.total\_sum/1](#mssmttotal_sum1)
    - [MSSMT.generate\_proof/2](#mssmtgenerate_proof2)
    - [MSSMT.verify\_proof/4](#mssmtverify_proof4)
  - [Development](#development)
  - [Contributing](#contributing)
  - [License](#license)

## Installation

To use `mssmt` in your Elixir project, add it to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:mssmt, git: "https://github.com/AbdelStark/mssmt.git", tag: "v0.1.0"}
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
tree = MSSMT.insert(tree, <<1, 2, 3>>, 100)
tree = MSSMT.insert(tree, <<4, 5, 6>>, 200)

# Retrieve a value
value = MSSMT.get(tree, <<1, 2, 3>>)  # Returns 100

# Update a value
tree = MSSMT.update(tree, <<1, 2, 3>>, 150)

# Delete a key-value pair
tree = MSSMT.delete(tree, <<4, 5, 6>>)

# Calculate root hash
root_hash = MSSMT.root_hash(tree)  # Returns a 32-byte binary hash

# Calculate total sum
total_sum = MSSMT.total_sum(tree)  # Returns 150
```

### Handling Binary Keys of Different Lengths

```elixir
tree = MSSMT.new()
tree = MSSMT.insert(tree, <<1>>, 100)
tree = MSSMT.insert(tree, <<1, 2>>, 200)
tree = MSSMT.insert(tree, <<1, 2, 3>>, 300)

MSSMT.get(tree, <<1>>)          # Returns 100
MSSMT.get(tree, <<1, 2>>)       # Returns 200
MSSMT.get(tree, <<1, 2, 3>>)    # Returns 300
MSSMT.total_sum(tree)           # Returns 600
```

### Generating and Verifying Proofs

```elixir
tree = MSSMT.new()
tree = MSSMT.insert(tree, <<1>>, 100)
tree = MSSMT.insert(tree, <<2>>, 200)
tree = MSSMT.insert(tree, <<3>>, 300)

root_hash = MSSMT.root_hash(tree)
proof = MSSMT.generate_proof(tree, <<2>>)

# Verify the proof
is_valid = MSSMT.verify_proof(root_hash, <<2>>, 200, proof)  # Returns true

# Verify with incorrect value
is_valid = MSSMT.verify_proof(root_hash, <<2>>, 250, proof)  # Returns false

# Verify with incorrect key
is_valid = MSSMT.verify_proof(root_hash, <<4>>, 200, proof)  # Returns false
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

**Example:**

```elixir
tree = MSSMT.insert(tree, <<1, 2, 3>>, 100)
```

---

### MSSMT.get/2

Retrieves the value associated with a key.

- **Parameters:**
  - `tree`: The current tree.
  - `key`: A binary representing the key.

**Returns:** The value associated with the key, or `nil` if the key does not exist.

**Example:**

```elixir
value = MSSMT.get(tree, <<1, 2, 3>>)
```

---

### MSSMT.update/3

Updates the value associated with a key.

- **Parameters:**
  - `tree`: The current tree.
  - `key`: A binary representing the key.
  - `value`: The new numeric value to associate with the key.

**Example:**

```elixir
tree = MSSMT.update(tree, <<1, 2, 3>>, 150)
```

---

### MSSMT.delete/2

Deletes a key-value pair from the tree.

- **Parameters:**
  - `tree`: The current tree.
  - `key`: A binary representing the key.

**Example:**

```elixir
tree = MSSMT.delete(tree, <<1, 2, 3>>)
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

### MSSMT.generate_proof/2

Generates a proof of inclusion for a given key.

- **Parameters:**
  - `tree`: The current tree.
  - `key`: A binary representing the key.

**Returns:** A list of nodes required to verify the inclusion of the key.

**Example:**

```elixir
proof = MSSMT.generate_proof(tree, <<1, 2, 3>>)
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
is_valid = MSSMT.verify_proof(root_hash, <<1, 2, 3>>, 150, proof)
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
