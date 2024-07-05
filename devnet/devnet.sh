#!/bin/bash

set -E

CHAIN_ID=${CHAIN_ID:-32382}
GENESIS_TIME_DELAY=15
NUM_VALIDATORS=64

TEMPLATE_DIR="./devnet/template"
DIR=/tmp/devnet
LOG_DIR=/tmp/devnet/log

TESTNET_DIR=$DIR/testnet
GENESIS_SSZ="$TESTNET_DIR/genesis.ssz"
CONFIG_YML="$TESTNET_DIR/config.yaml"
GENESIS_JSON="$TESTNET_DIR/genesis.json"
JWT_SECRET="$DIR/jwt/jwtsecret"
GETH_PASSWORD="$DIR/geth_password.txt"

BEACON_CHAIN_CMD=/usr/lib/eth-node-prysm/bin/beacon-chain
VALIDATOR_CMD=/usr/lib/eth-node-prysm/bin/validator

ENDPOINT_URL=http://localhost:8551
FEE_RECEIPENT_ADDRESS=0x123463a4b065722e99115d6c222f267d9cabb524

if [ "$DIR" != "/" ]; then 
    rm -rf $DIR 
fi 

# 0. Copy templates from 
if [ ! -d "$DIR" ]; then 
    cp -R "$TEMPLATE_DIR" "$DIR"
fi 

mkdir -p $LOG_DIR

# Cleanup previous runs 
pkill -f $(basename $BEACON_CHAIN_CMD)
pkill -f $(basename $VALIDATOR_CMD)
pkill -f $(basename $PRYSMCTL)


if [ ! -d "$TESTNET_DIR" ];then 
    sudo docker run --rm -it -v $DIR:/data \
    -v $PWD/devnet/config/defaults.env:/config/values.env \
    ethpandaops/ethereum-genesis-generator:latest all

    sudo chown -R $UID:$GID $DIR/custom_config_data
    mv $DIR/custom_config_data $TESTNET_DIR
fi 

# 3. Initialize Geth genesis configuration
geth --datadir=$DIR init $GENESIS_JSON


# 4. Run Prysm beacon chain
nohup $BEACON_CHAIN_CMD  --datadir=$DIR/beacondata \
                         --min-sync-peers=0 \
                         --genesis-state=$GENESIS_SSZ \
                         --bootstrap-node= \
                         --interop-eth1data-votes \
                         --chain-config-file=$CONFIG_YML \
                         --contract-deployment-block=0 \
                         --chain-id=$CHAIN_ID \
                         --rpc-host=0.0.0.0 \
                         --grpc-gateway-host=0.0.0.0 \
                         --execution-endpoint "$ENDPOINT_URL" \
                         --accept-terms-of-use \
                         --jwt-secret=$JWT_SECRET \
                         --suggested-fee-recipient=$FEE_RECEIPENT_ADDRESS \
                         --minimum-peers-per-subnet=0 \
                         --enable-debug-rpc-endpoints \
                         --force-clear-db > $LOG_DIR/beacon-chain.log &
BEACON_CHAIN_PID=$!
# echo "BEACON_CHAIN_PID: $BEACON_CHAIN_PID"
# cat nohup.out
# rm nohup.out 

# exit 0

echo "Prysm beacon-chain started with PID $BEACON_CHAIN_PID"

# TODO no clue what are these, and how to generate these
cp ./devnet/geth_password.txt $DIR 
cp ./devnet/sk.json $DIR 
cp -R ./devnet/keystore $DIR 

# 5. Run Geth execution client
nohup geth --http \
           --http.api=eth,net,web3 \
           --http.addr=0.0.0.0 \
           --http.corsdomain=* \
           --ws \
           --ws.api=eth,net,web3 \
           --ws.addr=0.0.0.0 \
           --ws.origins=* \
           --authrpc.vhosts=* \
           --authrpc.addr=0.0.0.0 \
           --authrpc.jwtsecret=$JWT_SECRET \
           --datadir=$DIR \
           --allow-insecure-unlock \
           --unlock=$FEE_RECEIPENT_ADDRESS \
           --password=$GETH_PASSWORD \
           --nodiscover \
           --syncmode=full > $LOG_DIR/execution-client.log  &
GETH_PID=$!
echo "Geth started with PID $GETH_PID"

# 6. Run Prysm validator
nohup $VALIDATOR_CMD  --beacon-rpc-provider=localhost:4000 \
                      --datadir=$DIR/validatordata \
                      --accept-terms-of-use \
                      --interop-num-validators=$NUM_VALIDATORS \
                      --interop-start-index=0 \
                      --chain-config-file=$CONFIG_YML \
                      --force-clear-db  > $LOG_DIR/validator.log &
VALIDATOR_PID=$!
echo "Prysm validator started with PID $VALIDATOR_PID"


sleep 1

rm nohup.out || true  

echo "To kill the started process run:"
echo "pkill -f $(basename $BEACON_CHAIN_CMD)"
echo "pkill -f $(basename $VALIDATOR_CMD)"
echo "pkill -f $(basename $PRYSMCTL)"
