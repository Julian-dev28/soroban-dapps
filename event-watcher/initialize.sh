#!/bin/bash

set -e

NETWORK="$1"

SOROBAN_RPC_HOST="$2"

WASM_PATH="target/wasm32-unknown-unknown/release/"
LIQUIDITY_POOL_WASM=$WASM_PATH"soroban_liquidity_pool_contract.optimized.wasm"
ABUNDANCE_WASM=$WASM_PATH"abundance_token.optimized.wasm"
TOKEN_WASM="contracts/liquidity-pool/token/soroban_token_contract.wasm"


if [[ "$SOROBAN_RPC_HOST" == "" ]]; then
  # If soroban-cli is called inside the soroban-preview docker container,
  # it can call the stellar standalone container just using its name "stellar"
  if [[ "$IS_USING_DOCKER" == "true" ]]; then
    SOROBAN_RPC_HOST="http://stellar:8000"
    SOROBAN_RPC_URL="$SOROBAN_RPC_HOST"
  elif [[ "$NETWORK" == "futurenet" ]]; then
    SOROBAN_RPC_HOST="https://rpc-futurenet.stellar.org:443"
    SOROBAN_RPC_URL="$SOROBAN_RPC_HOST"
  else
     # assumes standalone on quickstart, which has the soroban/rpc path
    SOROBAN_RPC_HOST="http://localhost:8000"
    SOROBAN_RPC_URL="$SOROBAN_RPC_HOST/soroban/rpc"
  fi
else 
  SOROBAN_RPC_URL="$SOROBAN_RPC_HOST"  
fi


case "$1" in
standalone)
  echo "Using standalone network with RPC URL: $SOROBAN_RPC_URL"
  SOROBAN_NETWORK_PASSPHRASE="Standalone Network ; February 2017"
  FRIENDBOT_URL="$SOROBAN_RPC_HOST/friendbot"
  ;;
futurenet)
  echo "Using Futurenet network with RPC URL: $SOROBAN_RPC_URL"
  SOROBAN_NETWORK_PASSPHRASE="Test SDF Future Network ; October 2022"
  FRIENDBOT_URL="https://friendbot-futurenet.stellar.org/"
  ;;
*)
  echo "Usage: $0 standalone|futurenet [rpc-host]"
  exit 1
  ;;
esac

echo Add the $NETWORK network to cli client
soroban config network add \
  --rpc-url "$SOROBAN_RPC_URL" \
  --network-passphrase "$SOROBAN_NETWORK_PASSPHRASE" "$NETWORK"

if !(soroban config identity ls | grep token-admin 2>&1 >/dev/null); then
  echo Create the token-admin identity
  soroban config identity generate token-admin
fi
TOKEN_ADMIN_SECRET="$(soroban config identity show token-admin)"
TOKEN_ADMIN_ADDRESS="$(soroban config identity address token-admin)"

mkdir -p .soroban

# This will fail if the account already exists, but it'll still be fine.
echo Fund token-admin account from friendbot
curl --silent -X POST "$FRIENDBOT_URL?addr=$TOKEN_ADMIN_ADDRESS" >/dev/null

ARGS="--network $NETWORK --source token-admin"


echo "Building contracts"
soroban contract build
echo "Optimizing contracts"
soroban contract optimize --wasm $WASM_PATH"soroban_liquidity_pool_contract.wasm"
soroban contract optimize --wasm $WASM_PATH"abundance_token.wasm"


echo Deploy the first liquidity pool contract
LIQUIDITY_POOL_1_ID="$(
  soroban contract deploy $ARGS \
    --wasm $LIQUIDITY_POOL_WASM
)"
echo "Liquidity Pool 1 contract deployed succesfully with ID: $LIQUIDITY_POOL_1_ID"

echo Deploy the second liquidity pool contract
LIQUIDITY_POOL_2_ID="$(
  soroban contract deploy $ARGS \
    --wasm $LIQUIDITY_POOL_WASM
)"
echo "Liquidity Pool 2 contract deployed succesfully with ID: $LIQUIDITY_POOL_2_ID"

echo Deploy the third liquidity pool contract
LIQUIDITY_POOL_3_ID="$(
  soroban contract deploy $ARGS \
    --wasm $LIQUIDITY_POOL_WASM
)"
echo "Liquidity Pool 3 contract deployed succesfully with ID: $LIQUIDITY_POOL_3_ID"

echo Deploy the abundance token A 1 contract
ABUNDANCE_A_1_ID="$(
  soroban contract deploy $ARGS \
    --wasm $ABUNDANCE_WASM
)"
echo "Contract deployed succesfully with ID: $ABUNDANCE_A_1_ID"

echo Deploy the abundance token B 1 contract
ABUNDANCE_B_1_ID="$(
  soroban contract deploy $ARGS \
    --wasm $ABUNDANCE_WASM
)"
echo "Contract deployed succesfully with ID: $ABUNDANCE_B_1_ID"

echo Deploy the abundance token A 2 contract
ABUNDANCE_A_2_ID="$(
  soroban contract deploy $ARGS \
    --wasm $ABUNDANCE_WASM
)"
echo "Contract deployed succesfully with ID: $ABUNDANCE_A_2_ID"

echo Deploy the abundance token B 2 contract
ABUNDANCE_B_2_ID="$(
  soroban contract deploy $ARGS \
    --wasm $ABUNDANCE_WASM
)"
echo "Contract deployed succesfully with ID: $ABUNDANCE_B_2_ID"

echo Deploy the abundance token A 3 contract
ABUNDANCE_A_3_ID="$(
  soroban contract deploy $ARGS \
    --wasm $ABUNDANCE_WASM
)"
echo "Contract deployed succesfully with ID: $ABUNDANCE_A_3_ID"

echo Deploy the abundance token B 3 contract
ABUNDANCE_B_3_ID="$(
  soroban contract deploy $ARGS \
    --wasm $ABUNDANCE_WASM
)"
echo "Contract deployed succesfully with ID: $ABUNDANCE_B_3_ID"

if [[ "$ABUNDANCE_B_1_ID" < "$ABUNDANCE_A_1_ID" ]]; then
  echo Changing tokens order
  OLD_ABUNDANCE_A_ID=$ABUNDANCE_A_1_ID
  ABUNDANCE_A_1_ID=$ABUNDANCE_B_1_ID
  ABUNDANCE_B_1_ID=$OLD_ABUNDANCE_A_ID
fi

if [[ "$ABUNDANCE_B_2_ID" < "$ABUNDANCE_A_2_ID" ]]; then
  echo Changing tokens order
  OLD_ABUNDANCE_A_ID=$ABUNDANCE_A_2_ID
  ABUNDANCE_A_2_ID=$ABUNDANCE_B_2_ID
  ABUNDANCE_B_2_ID=$OLD_ABUNDANCE_A_ID
fi

if [[ "$ABUNDANCE_B_3_ID" < "$ABUNDANCE_A_3_ID" ]]; then
  echo Changing tokens order
  OLD_ABUNDANCE_A_ID=$ABUNDANCE_A_3_ID
  ABUNDANCE_A_3_ID=$ABUNDANCE_B_3_ID
  ABUNDANCE_B_3_ID=$OLD_ABUNDANCE_A_ID
fi


echo "Initialize the abundance token A 1 contract"
TOKEN_1_A_SYMBOL=USDC
soroban contract invoke \
  $ARGS \
  --id "$ABUNDANCE_A_1_ID" \
  -- \
  initialize \
  --symbol $TOKEN_1_A_SYMBOL \
  --decimal 7 \
  --name USDCoin \
  --admin "$TOKEN_ADMIN_ADDRESS"


echo "Initialize the abundance token B 1 contract"
TOKEN_1_B_SYMBOL=BTC
soroban contract invoke \
  $ARGS \
  --id "$ABUNDANCE_B_1_ID" \
  -- \
  initialize \
  --symbol $TOKEN_1_B_SYMBOL \
  --decimal 7 \
  --name Bitcoin \
  --admin "$TOKEN_ADMIN_ADDRESS"

echo "Initialize the abundance token A 2 contract"
TOKEN_2_A_SYMBOL=DAI
soroban contract invoke \
  $ARGS \
  --id "$ABUNDANCE_A_2_ID" \
  -- \
  initialize \
  --symbol $TOKEN_2_A_SYMBOL \
  --decimal 7 \
  --name Dai \
  --admin "$TOKEN_ADMIN_ADDRESS"


echo "Initialize the abundance token B 2 contract"
TOKEN_2_B_SYMBOL=BNB
soroban contract invoke \
  $ARGS \
  --id "$ABUNDANCE_B_2_ID" \
  -- \
  initialize \
  --symbol $TOKEN_2_B_SYMBOL \
  --decimal 7 \
  --name BinanceCoin \
  --admin "$TOKEN_ADMIN_ADDRESS"


echo "Initialize the abundance token A 3 contract"
TOKEN_3_A_SYMBOL=LTC
soroban contract invoke \
  $ARGS \
  --id "$ABUNDANCE_A_3_ID" \
  -- \
  initialize \
  --symbol $TOKEN_3_A_SYMBOL \
  --decimal 7 \
  --name LiteCoin \
  --admin "$TOKEN_ADMIN_ADDRESS"


echo "Initialize the abundance token B 3"
TOKEN_3_B_SYMBOL=EUROC
soroban contract invoke \
  $ARGS \
  --id "$ABUNDANCE_B_3_ID" \
  -- \
  initialize \
  --symbol $TOKEN_3_B_SYMBOL \
  --decimal 7 \
  --name EuroCoin \
  --admin "$TOKEN_ADMIN_ADDRESS"



echo "Installing token wasm contract"
TOKEN_WASM_HASH="$(soroban contract install \
    $ARGS \
    --wasm $TOKEN_WASM
)"


echo "Initialize the liquidity pool 1 contract"
soroban contract invoke \
  $ARGS \
  --wasm $LIQUIDITY_POOL_WASM \
  --id "$LIQUIDITY_POOL_1_ID" \
  -- \
  initialize \
  --token_wasm_hash "$TOKEN_WASM_HASH" \
  --token_a "$ABUNDANCE_A_1_ID" \
  --token_b "$ABUNDANCE_B_1_ID"


echo "Getting the share id 1"
SHARE_ID_1="$(soroban contract invoke \
  $ARGS \
  --wasm $LIQUIDITY_POOL_WASM \
  --id "$LIQUIDITY_POOL_1_ID" \
  -- \
  share_id
)"
SHARE_ID_1=${SHARE_ID_1//\"/}
echo "Share ID 1: $SHARE_ID_1"

echo "Initialize the liquidity pool 2 contract"
soroban contract invoke \
  $ARGS \
  --wasm $LIQUIDITY_POOL_WASM \
  --id "$LIQUIDITY_POOL_2_ID" \
  -- \
  initialize \
  --token_wasm_hash "$TOKEN_WASM_HASH" \
  --token_a "$ABUNDANCE_A_2_ID" \
  --token_b "$ABUNDANCE_B_2_ID"

echo "Getting the share id 2"
SHARE_ID_2="$(soroban contract invoke \
  $ARGS \
  --wasm $LIQUIDITY_POOL_WASM \
  --id "$LIQUIDITY_POOL_2_ID" \
  -- \
  share_id
)"
SHARE_ID_2=${SHARE_ID_2//\"/}
echo "Share ID 2: $SHARE_ID_2"

echo "Initialize the liquidity pool 3 contract"
soroban contract invoke \
  $ARGS \
  --wasm $LIQUIDITY_POOL_WASM \
  --id "$LIQUIDITY_POOL_3_ID" \
  -- \
  initialize \
  --token_wasm_hash "$TOKEN_WASM_HASH" \
  --token_a "$ABUNDANCE_A_3_ID" \
  --token_b "$ABUNDANCE_B_3_ID"

echo "Getting the share id 3"
SHARE_ID_3="$(soroban contract invoke \
  $ARGS \
  --wasm $LIQUIDITY_POOL_WASM \
  --id "$LIQUIDITY_POOL_3_ID" \
  -- \
  share_id
)"
SHARE_ID_3=${SHARE_ID_3//\"/}
echo "Share ID 3: $SHARE_ID_3"


echo Creating data on database
DB_FILE="backend/database.db"

# Insert data into the token table and get the inserted IDs
echo First pool
TOKEN_ID_1=$(sqlite3 "$DB_FILE" "INSERT INTO token (contract_id, symbol, decimals, xlm_value) VALUES ('$ABUNDANCE_A_1_ID', '$TOKEN_1_A_SYMBOL', 7, 2); SELECT last_insert_rowid();")

TOKEN_ID_2=$(sqlite3 "$DB_FILE" "INSERT INTO token (contract_id, symbol, decimals, xlm_value) VALUES ('$ABUNDANCE_B_1_ID', '$TOKEN_1_B_SYMBOL', 7, 5); SELECT last_insert_rowid();")

TOKEN_SHARE_ID=$(sqlite3 "$DB_FILE" "INSERT INTO token (contract_id, symbol, decimals, xlm_value, is_share) VALUES ('$SHARE_ID_1', 'POOL', 7, 0, 1); SELECT last_insert_rowid();")

POOL_HASH_ID=$(curl -s "https://rpciege.com/convert/$LIQUIDITY_POOL_1_ID")

sqlite3 "$DB_FILE" "INSERT INTO pool (contract_id, contract_hash_id, name, liquidity, volume, fees, token_a_id, token_b_id, token_share_id, token_a_reserves, token_b_reserves) VALUES ('$LIQUIDITY_POOL_1_ID', '$POOL_HASH_ID', '${TOKEN_1_A_SYMBOL}-${TOKEN_1_B_SYMBOL}', 0, 0, 0, $TOKEN_ID_1, $TOKEN_ID_2,  $TOKEN_SHARE_ID, 0, 0);"

echo Second pool
TOKEN_ID_1=$(sqlite3 "$DB_FILE" "INSERT INTO token (contract_id, symbol, decimals, xlm_value) VALUES ('$ABUNDANCE_A_2_ID', '$TOKEN_2_A_SYMBOL', 7, 3); SELECT last_insert_rowid();")

TOKEN_ID_2=$(sqlite3 "$DB_FILE" "INSERT INTO token (contract_id, symbol, decimals, xlm_value) VALUES ('$ABUNDANCE_B_2_ID', '$TOKEN_2_B_SYMBOL', 7, 1); SELECT last_insert_rowid();")

TOKEN_SHARE_ID=$(sqlite3 "$DB_FILE" "INSERT INTO token (contract_id, symbol, decimals, xlm_value, is_share) VALUES ('$SHARE_ID_2', 'POOL', 7, 0, 1); SELECT last_insert_rowid();")

POOL_HASH_ID=$(curl -s "https://rpciege.com/convert/$LIQUIDITY_POOL_2_ID")


sqlite3 "$DB_FILE" "INSERT INTO pool (contract_id, contract_hash_id, name, liquidity, volume, fees, token_a_id, token_b_id, token_share_id, token_a_reserves, token_b_reserves) VALUES ('$LIQUIDITY_POOL_2_ID', '$POOL_HASH_ID', '${TOKEN_2_A_SYMBOL}-${TOKEN_2_B_SYMBOL}', 0, 0, 0, $TOKEN_ID_1, $TOKEN_ID_2, $TOKEN_SHARE_ID, 0, 0);"


echo Third pool
TOKEN_ID_1=$(sqlite3 "$DB_FILE" "INSERT INTO token (contract_id, symbol, decimals, xlm_value) VALUES ('$ABUNDANCE_A_3_ID', '$TOKEN_3_A_SYMBOL', 7, 4); SELECT last_insert_rowid();")

TOKEN_ID_2=$(sqlite3 "$DB_FILE" "INSERT INTO token (contract_id, symbol, decimals, xlm_value) VALUES ('$ABUNDANCE_B_3_ID', '$TOKEN_3_B_SYMBOL', 7, 7); SELECT last_insert_rowid();")

TOKEN_SHARE_ID=$(sqlite3 "$DB_FILE" "INSERT INTO token (contract_id, symbol, decimals, xlm_value, is_share) VALUES ('$SHARE_ID_3', 'POOL', 7, 0, 1); SELECT last_insert_rowid();")

POOL_HASH_ID=$(curl -s "https://rpciege.com/convert/$LIQUIDITY_POOL_3_ID")

sqlite3 "$DB_FILE" "INSERT INTO pool (contract_id, contract_hash_id, name, liquidity, volume, fees, token_a_id, token_b_id, token_share_id, token_a_reserves, token_b_reserves) VALUES ('$LIQUIDITY_POOL_3_ID', '$POOL_HASH_ID', '${TOKEN_3_A_SYMBOL}-${TOKEN_3_B_SYMBOL}', 0, 0, 0, $TOKEN_ID_1, $TOKEN_ID_2, $TOKEN_SHARE_ID, 0, 0);"

echo "Done"

