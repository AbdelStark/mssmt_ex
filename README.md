# Merkle-Sum Sparse Merkle Tree (MS-SMT) in Elixir

A Merkle-Sum Sparse Merkle tree (MS-SMT) is a specific variant of a Merkle tree that combines a Merkle sum tree and a Sparse Merkle tree. As any merkle root, the MS-SMT can store a huge amount of data, and you only have store the Hash, an ideal candidate to store and trace user created assets.

## Installation

To use MS-SMT in your Elixir project, add it to your list of dependencies in `mix.exs`:

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

Here's a basic example of how to use the MS-SMT module:

```elixir
# Create a new empty MS-SMT
tree = MSSMT.new()

# Insert key-value pairs
tree = MSSMT.insert(tree, "key1", 100)
tree = MSSMT.insert(tree, "key2", 200)

# Retrieve a value
value = MSSMT.get(tree, "key1")  # Returns 100

# Update a value
tree = MSSMT.update(tree, "key1", 150)

# Delete a key-value pair
tree = MSSMT.delete(tree, "key2")

# Calculate root hash
root_hash = MSSMT.root_hash(tree)

# Calculate total sum
total_sum = MSSMT.total_sum(tree)  # Returns 150
```

## Development

To set up the project for development:

1. Clone the repository:

```bash
git clone https://github.com/AbdelStark/mssmt.git
cd mssmt
```

1. Install dependencies:

```bash
mix deps.get
```

1. Run tests:

```bash
mix test
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## TODO

- Implement a more efficient tree structure
- Add proof generation and verification for inclusion and non-inclusion
- Implement batch updates and optimizations for large-scale operations
- Add more comprehensive error handling and input validation
