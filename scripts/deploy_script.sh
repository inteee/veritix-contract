#!/usr/bin/env bash
# Build and deploy the contract with the Stellar CLI.
#
# Usage: NETWORK=testnet SOURCE=<identity> ./scripts/deploy_script.sh
set -euo pipefail

NETWORK="${NETWORK:-testnet}"
SOURCE="${SOURCE:?Set SOURCE to a Stellar CLI identity (see 'stellar keys')}"
WASM="target/wasm32v1-none/release/veritix_contract.wasm"

stellar contract build

CONTRACT_ID="$(stellar contract deploy --wasm "$WASM" --source "$SOURCE" --network "$NETWORK")"
echo "Deployed contract: $CONTRACT_ID"
echo "Initialize it with: stellar contract invoke --id $CONTRACT_ID --source $SOURCE --network $NETWORK -- initialize --admin_addr <ADMIN_ADDRESS>"
