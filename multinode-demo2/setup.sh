#!/usr/bin/env bash

here=$(dirname "$0")
# shellcheck source=multinode-demo/common.sh
source "$here"/common.sh

set -e
NUM_VALIDATORS=2  # 可修改为任意数量的 Validator

# Create genesis ledger
if [[ -r $FAUCET_KEYPAIR ]]; then
  cp -f "$FAUCET_KEYPAIR" "$SOLANA_CONFIG_DIR"/faucet.json
else
  $solana_keygen new --no-passphrase -fso "$SOLANA_CONFIG_DIR"/faucet.json
fi


args=(
  "$@"
  --max-genesis-archive-unpacked-size 1073741824
  --enable-warmup-epochs
)

for i in $(seq 1 "$NUM_VALIDATORS"); do
  VALIDATOR_DIR="$SOLANA_CONFIG_DIR/validator-$i"
  rm -rf "$VALIDATOR_DIR"
  mkdir -p "$VALIDATOR_DIR"

  echo "创建 Validator-$i 身份文件..."
  $solana_keygen new --no-passphrase -so "$VALIDATOR_DIR/identity.json"
  $solana_keygen new --no-passphrase -so "$VALIDATOR_DIR/stake-account.json"
  $solana_keygen new --no-passphrase -so "$VALIDATOR_DIR/vote-account.json"

  args+=(
    --bootstrap-validator "$VALIDATOR_DIR/identity.json"
                          "$VALIDATOR_DIR/vote-account.json"
                          "$VALIDATOR_DIR/stake-account.json"
  )
done

"$SOLANA_ROOT"/fetch-spl.sh
if [[ -r spl-genesis-args.sh ]]; then
  SPL_GENESIS_ARGS=$(cat "$SOLANA_ROOT"/spl-genesis-args.sh)
  #shellcheck disable=SC2207
  #shellcheck disable=SC2206
  args+=($SPL_GENESIS_ARGS)
fi

default_arg --ledger "$SOLANA_CONFIG_DIR"/validator-1
default_arg --faucet-pubkey "$SOLANA_CONFIG_DIR"/faucet.json
default_arg --faucet-lamports 500000000000000000
default_arg --hashes-per-tick auto
default_arg --cluster-type development
default_arg --fee-burn-percentage 0
default_arg --rent-burn-percentage 0
default_arg --inflation none

$solana_genesis "${args[@]}"
