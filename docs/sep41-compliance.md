# SEP-41 compliance

`VeriTixPay` implements the Stellar Token Standard, [SEP-41]. The claim is
falsifiable: every function below is exercised through the public client in
[`src/sep41_test.rs`](../src/sep41_test.rs), and every event shape is asserted
topic-by-topic in [`src/event_test.rs`](../src/event_test.rs). A change that
breaks the interface, the allowance expiration semantics, or an event fails a
test rather than failing silently in a wallet.

## Interface

The functions currently exposed by `VeriTixPay` (see `src/contract.rs`):

| Function | Signature | Notes |
| --- | --- | --- |
| `name` | `() -> String` | Defaults to `VeriTix`; overridable with `initialize_with_metadata`. |
| `symbol` | `() -> String` | Defaults to `VTX`. |
| `decimals` | `() -> u32` | Defaults to `7`. |
| `total_supply` | `() -> i128` | `0` before the first mint. |
| `max_supply` | `() -> i128` | Supply cap, `0` when uncapped. |
| `balance` | `(account: Address) -> i128` | `0` for an address that has never been credited. |
| `transfer` | `(from, to, amount: i128)` | Requires `from` authorization. |
| `mint` | `(admin, to, amount: i128)` | Admin-only. |

The allowance, burn, clawback, memo and holder-set logic exists as internal
modules (`src/allowance.rs`, `src/events.rs`) but is **not yet exposed** as
contract entry points, so the contract is not yet fully SEP-41 compliant.
`approve`, `allowance`, `transfer_from`, `burn` and `burn_from` still need to
be exposed. Extra operator functions such as `total_holders`, `get_holders`,
`spendable_balance`, `is_paused` and `set_frozen` are likewise not available.

## Allowance expiration

An allowance is stored together with the ledger it expires on, and follows the
standard's rule exactly:

- An allowance is **expired** once `expiration_ledger` is strictly behind the
  current ledger. It is still live on the ledger it expires on.
- An **expired** allowance reads as `0` from `allowance()`. It is not an error:
  a spender that never spends gets nothing back, which is the point of setting
  an expiry at all.
- `approve()` with a **non-zero** amount and an `expiration_ledger` that is
  already behind the current ledger is rejected with `ExpirationInPast`.
- `approve()` with a **zero** amount is always accepted, regardless of the
  ledger requested. Revoking an allowance has no expiry to get wrong, and a
  zero amount is how an allowance is revoked.
- Spending an expired or insufficient allowance fails with
  `InsufficientAllowance` and changes nothing, including the balances.
- `transfer_from` and `burn_from` reduce the allowance by exactly the amount
  moved. Exhausting it revokes the entry, so the remaining figure and the
  storage footprint agree that nothing is granted.

`approve()` **overwrites**. A spender handed a new number gets that number, not
the old one plus the new one.

## Events

All five required events use the standard topic layout, emitted through
`#[contractevent(data_format = "vec")]`:

| Event | Topics | Data |
| --- | --- | --- |
| `mint` | `["mint", to: Address]` | `[amount: i128]` |
| `burn` | `["burn", from: Address]` | `[amount: i128]` |
| `transfer` | `["transfer", from: Address, to: Address]` | `[amount: i128]` |
| `approve` | `["approve", from: Address, spender: Address]` | `[amount: i128, expiration_ledger: u32]` |
| `clawback` | `["clawback", admin: Address, from: Address]` | `[amount: i128]` |

Two deliberate choices:

- **`transfer_from` emits `transfer`, and `burn_from` emits `burn`.** The
  tokens left the same account by the same means; an indexer reconstructing
  balances from the event log should not have to care which signature was used.
  The spender's identity is recoverable from the `approve` event that preceded
  it.
- **`transfer_with_memo` reuses the `transfer` topics** and appends the memo to
  the data, giving `[amount: i128, memo: Bytes]`. A memo is extra information
  about a transfer, not a different kind of transfer, so a wallet that only
  parses `transfer` still shows the tickets moving.

`clawback` carries the admin address as a topic rather than a data field so an
auditor can filter clawbacks by the account that performed them. It is kept
distinct from `burn` for the same reason: an admin recovery and a holder's own
burn both reduce supply, and an auditor needs to tell them apart.

## Rejections

| Condition | Failure |
| --- | --- |
| Amount `0` or negative | `InvalidAmount` |
| Transfer or burn above the balance | `InsufficientBalance` |
| Spend above the live allowance | `InsufficientAllowance` |
| `approve` with a past expiration and a non-zero amount | `ExpirationInPast` |
| Memo longer than 64 bytes | `MemoTooLarge` |
| Transfer while the contract is paused | `Paused` |
| Transfer to or from a frozen account | `Frozen` |
| Mint or clawback from a non-admin | `Unauthorized` |
| Mint above the configured cap | `SupplyCapExceeded` |
| A second `initialize` | `AlreadyInitialized` |

Every one of these is a panic, so a rejected invocation reverts in full: no
partial balance movement, no partial allowance reduction, and no event on the
ledger. `src/event_test.rs` asserts that last point directly, because a
correctly-rejected call that still emitted an event would corrupt every indexer
reading the log.

## Deliberate deviations

- **Accounts are authorized by default and freezing is opt-in.** A fresh
  deployment behaves like an ordinary SEP-41 token; the compliance controls are
  available but inert until an admin turns them on.
- **Memos are capped at 64 bytes.** The standard does not require a limit, but
  the memo is paid for by every reader of the ledger.
- **`clawback` takes the admin address as an argument** rather than reading it
  from storage, so the caller that performed the recovery is unambiguous in both
  the authorization check and the event.

[SEP-41]: https://github.com/stellar/stellar-protocol/blob/master/core/cap-0046.md
