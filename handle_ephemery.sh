#!/usr/bin/env bash 

set -e

if [ "$network" == "ephemery" ]; then 
    echo "fetching ephemery state"
    # TODO option to reset
    # rm -rf $ephemery_dir
    if [ ! -d "$BASE_CONFIG_CUSTOM_NETWORK_TESTNET_DIR" ];then
        wget https://github.com/ephemery-testnet/ephemery-genesis/releases/download/ephemery-111/testnet-all.tar.gz
        mkdir -p $BASE_CONFIG_CUSTOM_NETWORK_TESTNET_DIR && tar -xzf testnet-all.tar.gz -C $BASE_CONFIG_CUSTOM_NETWORK_TESTNET_DIR
        rm testnet-all.tar.gz 
    fi 
    BASE_CONFIG_CUSTOM_NETWORK_NETWORK_ID=$(cat $BASE_CONFIG_CUSTOM_NETWORK_TESTNET_DIR/genesis.json | grep chainId | tr -d ',' | sed 's/"chainId"://g' | tr -d '[:space:]')
    ENR_FILE="$BASE_CONFIG_CUSTOM_NETWORK_TESTNET_DIR/boot_enr.txt"
    BASE_CONFIG_CUSTOM_NETWORK_BOOTNODES_ENR=$(awk '{printf "%s,", $0}' "$ENR_FILE" | sed -e "s/- enr/enr/g" -e 's/,$//')
    BASE_CONFIG_CUSTOM_NETWORK_BOOTNODES_ENODE=$(awk '{printf "%s,", $0}' $BASE_CONFIG_CUSTOM_NETWORK_TESTNET_DIR/boot_enode.txt | sed 's/,$//')

    export BASE_CONFIG_CUSTOM_NETWORK_NETWORK_ID
    export BASE_CONFIG_CUSTOM_NETWORK_BOOTNODES_ENR
    export BASE_CONFIG_CUSTOM_NETWORK_BOOTNODES_ENODE
fi
