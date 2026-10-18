Prerequisites
rustup target add wasm32v1-none
The Rust toolchain is pinned in rust-toolchain.toml.

Make targets
Target	Description
make preflight	Check the toolchain and wasm target
make build	Build for the host target
make test	Run the unit tests
make fmt / make fmt-check	Format / check formatting
make lint	Clippy with warnings denied
make wasm	Build the optimized wasm artifact
make install-hooks	Install the pre-commit hook
