# Architecture

`veritix-contract` is a single Soroban contract, `VeriTixPay` (`src/contract.rs`), that combines a SEP-41-style token (VTX) with ticket-payment primitives: escrows, recurring payments, payment splits and disputes. The crate builds as a `cdylib` for `wasm32v1-none`.

## Modules

| Module | Responsibility |
| --- | --- |
| `contract` | The `#[contractimpl]` entry points; thin wrappers over the modules below |
| `admin`, `control`, `authorization`, `whitelist` | Admin identity and compliance controls |
| `balance`, `allowance`, `metadata` | Token balances, allowances, name/symbol/decimals |
| `escrow`, `multi_escrow` | Holding funds for a beneficiary or several beneficiaries |
| `dispute` | Disputes that freeze an escrow until a ruling is final |
| `recurring`, `splitter` | Recurring charges and payment splits |
| `events` | `#[contractevent]` definitions |
| `storage_types` | `DataKey`, record types and TTL helpers |
| `validation` | Shared argument checks |

## Design rules

- Entry points stay thin; logic lives in the modules.
- All persistent state is reached through the single `DataKey` enum (see `docs/storage-layout.md`).
- Failures are panics with a stable `Code:` prefix (see `docs/error_codes_v2.md`).
- Entries are kept alive with the TTL helpers described in `docs/ttl.md`.
