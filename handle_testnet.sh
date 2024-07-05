if [ "$network" == "testnet" ]; then 
    CHAIN_ID=${CHAIN_ID:-32382}
    GENESIS_TIME_DELAY=15
    PRYSMCTL=/usr/lib/eth-node-prysm/bin/prysmctl

    create_data_dir_if_not_exists $BASE_CONFIG_VALIDATOR_DATADIR
    # TODO option to reset
    if [ ! -d "$BASE_CONFIG_CUSTOM_NETWORK_TESTNET_DIR" ];then
        echo "creating genesis state"

        docker run --rm -it -v $BASE_CONFIG_DATA_DIR:/data \
        -v $PWD/devnet/config/defaults.env:/config/values.env \
        ethpandaops/ethereum-genesis-generator:latest all

        mv $BASE_CONFIG_DATA_DIR/custom_config_data $BASE_CONFIG_CUSTOM_NETWORK_TESTNET_DIR
        sudo chown -R "$(id -u):$(id -g)" $BASE_CONFIG_CUSTOM_NETWORK_TESTNET_DIR
         
        touch "$BASE_CONFIG_DATA_DIR/geth_password.txt"


    fi 
    if [ "$execution_client" = "geth" ];then 
        # 3. Initialize Geth genesis configuration
        geth --datadir=$BASE_CONFIG_DATA_DIR init $BASE_CONFIG_CUSTOM_NETWORK_GENESIS_FILE 
        cp "./devnet/sk.json" "$BASE_CONFIG_DATA_DIR"
        cp -R "./devnet/keystore" "$BASE_CONFIG_DATA_DIR"
    fi 

    SHARED_GENESIS_TIME=$(jq -r '.genesis_time' $BASE_CONFIG_CUSTOM_NETWORK_TESTNET_DIR/parsedBeaconState.json)
    SHARED_CONFIG_NETWORK_ID=$CHAIN_ID
    
    echo "SHARED_GENESIS_TIME: $SHARED_GENESIS_TIME"

    export SHARED_GENESIS_TIME
    export SHARED_CONFIG_NETWORK_ID
fi