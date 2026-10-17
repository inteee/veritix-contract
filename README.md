# veritix-contract

Soroban smart contract for VeriTix payments. `VeriTixPay` combines a SEP-41-style token (VTX) with ticket-payment primitives: escrows, multi-beneficiary escrows, disputes, recurring payments and payment splits.

## Modules

| Module | Purpose | Status |
| --- | --- | --- |
| `admin`, `control`, `authorization`, `whitelist` | Admin and compliance controls | Partly exposed |
| `balance`, `allowance`, `metadata` | Token balances, allowances, metadata | Balances and metadata exposed |
| `escrow`, `multi_escrow` | Escrow of funds for beneficiaries | Exposed |
| `dispute` | Dispute handling over escrows | Exposed |
| `recurring`, `splitter` | Recurring payments and splits | Recurring exposed; splitter in progress |

See `docs/architecture.md` for details.

## Prerequisites

```bash
rustup target add wasm32v1-none
```

The Rust toolchain is pinned in `rust-toolchain.toml`.

## Make targets

| Target | Description |
| --- | --- |
| `make preflight` | Check the toolchain and wasm target |
| `make build` | Build for the host target |
| `make test` | Run the unit tests |
| `make fmt` / `make fmt-check` | Format / check formatting |
| `make lint` | Clippy with warnings denied |
| `make wasm` | Build the optimized wasm artifact |
| `make install-hooks` | Install the pre-commit hook |

## Contributing and security

See `CONTRIBUTING.md` and `SECURITY.md`. Licensed under Apache-2.0 (see `LICENSE`).
