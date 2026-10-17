# TTL policy

Soroban entries expire. An entry that is never touched eventually falls below the network's minimum TTL and is archived, after which reading it returns nothing - the contract cannot tell "never existed" from "expired".

Two helpers in `src/storage_types.rs` implement the policy:

| Helper | Applies to | Threshold | Extends to |
| --- | --- | --- | --- |
| `bump_instance(e)` | Instance storage | `INSTANCE_LIFETIME_THRESHOLD` (518,400 ledgers, ~30 days) | `INSTANCE_BUMP_AMOUNT` (2,592,000 ledgers, ~150 days) |
| `bump_persistent(e, &key)` | One persistent entry | `PERSISTENT_LIFETIME_THRESHOLD` (2,073,600 ledgers, ~120 days) | `PERSISTENT_BUMP_AMOUNT` (4,752,000 ledgers, ~275 days) |

Ledger figures assume a 5-second ledger close.

## Where state lives

Currently the admin key, balances and all records are stored in **persistent** storage (`env.storage().persistent()`), not instance storage. Instance storage is not used for the admin.

## Current coverage

`bump_persistent` is applied by the dispute module. Other modules do not yet call the helpers, so their entries are not extended on access. New code should call `bump_persistent` on every read and write of a persistent key.

## Adding a key

1. Add the variant to `DataKey` in `src/storage_types.rs`.
2. Use persistent storage if the number of entries grows with usage.
3. Call `bump_persistent` on every read and write of the key.
4. Document it in `docs/storage-layout.md`.
