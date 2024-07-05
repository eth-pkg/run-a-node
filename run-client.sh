#!/usr/bin/env bash 

set -e

error_handler() {
    echo "Error occurred in script at line: $1"
    echo "Command executed: $2"
    exit 1
}

# Trap errors and call the error_handler function
trap 'error_handler ${LINENO} "${BASH_COMMAND}"' ERR


valid_execution_clients=("besu" "erigon" "geth" "nethermind")
valid_consensus_clients=("lighthouse" "lodestar" "nimbus-eth2" "prysm" "teku")
valid_network_options=("mainnet" "sepolia" "ephemery" "holesky" "testnet")
valid_run_options=("execution" "consensus" "validator" "bootnode")

declare -A latest_clients

latest_clients["besu"]="24.5.1"
latest_clients["erigon"]="2.60.0"
latest_clients["geth"]="1.14.3"
latest_clients["lighthouse"]="5.1.3"
latest_clients["lodestar"]="1.18.1"
latest_clients["nethermind"]="1.26.0"
latest_clients["nimbus-eth2"]="24.5.1"
latest_clients["prysm"]="5.0.3"
latest_clients["teku"]="24.4.0"



create_data_dir_if_not_exists(){
    if [ ! -d "$1" ]; then
        mkdir -p "$1"
    fi
}

create_secrets_file_if_not_exists(){
    if [ ! -f "$1" ]; then
        ## todo apply permissions
        openssl rand -hex 32 | tr -d "\n" | sudo tee $1
    fi 
}

# Function to display usage information
run_node_usage() {
  echo "Usage: $0 [ --network mainnet|sepolia|ephemery|holesky|devnet ] \
[ --consensus-client lighthouse|lodestar|nimbus-eth2|prysm|teku ] \
[ --execution-client besu|erigon|geth|nethermind ] \
[ --run execution|consensus|validator|bootnode ] \
[ --with-builder ( both EL and CL ) ] \
[ --with-graphql ( only EL ) ] \
[ --with-metrics ( both EL and CL) ] \
[ --with-http (both EL and CL) ] \
[ --with-tx-pool (only EL) ] \
[ --with-ws (only EL) ] \
[ --with-validator ]
"
    exit 1
}



is_valid_option() {
    local option="$1"
    shift
    local array=("$@")
    for element in "${array[@]}"; do
        if [[ "$element" == "$option" ]]; then
            return 0
        fi
    done
    return 1
}

# Function to parse command-line options
run_node_parse_options() {
    network=
    consensus_client=
    execution_client=
    run=
    with_builder=
    with_graphql=
    with_metrics=
    with_http=
    with_tx_pool=
    with_ws=
    with_validator=

    OPTS=$(getopt -o '' -l "network:\
                            ,consensus-client:\
                            ,execution-client:\
                            ,run:\
                            ,with-builder:\
                            ,with-graphql:\
                            ,with-metrics:\
                            ,with-http:\
                            ,with-tx-pool:\
                            ,with-ws:\
                            ,with-validator" -n "$0" -- "$@")
    if [ $? != 0 ]; then
        run_node_usage
    fi

    eval set -- "$OPTS"

    while true; do
        case "$1" in
            --network)
                network="$2"
                shift 2
                ;;
            --consensus-client)
                consensus_client="$2"
                shift 2
                ;;
            --execution-client)
                execution_client="$2"
                shift 2
                ;;
            --run)
                run="$2"
                shift 2
                ;;
            --with-builder)
                with_builder=true
                shift 1
                ;;     
            --with-graphql)
                with_graphql=true
                shift 1
                ;;       
            --with-metrics)
                with_metrics=true
                shift 1
                ;;     
            --with-http)
                with_http=true
                shift 1
                ;;  
            --with-tx-pool)
                with_tx_pool=true
                shift 1
                ;;   
            --with-ws)
                with_ws=true
                shift 1
                ;;              
            --with-validator)
                with_validator=true
                shift 1
                ;;             
            --)
                shift
                break
                ;;
            *)
                run_node_usage
                ;;
        esac
    done

    # Validate required options, everything is required, defaults are given
    if  [ -z "$network" ]; then
	    echo "please provide a network value"
        run_node_usage
    fi

    if  [ -z "$consensus_client" ]; then
	    echo "please provide consensus-client value"
        run_node_usage
    fi

    if  [ -z "$execution_client" ]; then
	    echo "please provide execution-client value"
        run_node_usage
    fi

    if  [ -z "$run" ]; then
	    echo "please provide run value"
        run_node_usage
    fi

    # Validate consensus client
    if [[ -n "$consensus_client" ]]; then
        if ! is_valid_option "$consensus_client" "${valid_consensus_clients[@]}"; then
            echo "Invalid consensus client: $consensus_client"
            usage
        fi
    fi

    # Validate execution client
    if [[ -n "$execution_client" ]]; then
        if ! is_valid_option "$execution_client" "${valid_execution_clients[@]}"; then
            echo "Invalid execution client: $execution_client"
            usage
        fi
    fi

    if [[ -n "$network" ]]; then
        if ! is_valid_option "$network" "${valid_network_options[@]}"; then
            echo "Invalid network: $network"
            usage
        fi
    fi

    if [[ -n "$run" ]]; then
        if ! is_valid_option "$run" "${valid_run_options[@]}"; then
            echo "Invalid run: $run"
            usage
        fi
    fi

    echo "Network: $network"
    echo "Consensus Client: $consensus_client"
    echo "Execution Client: $execution_client"
    echo "Running Client: $run"
    echo "Run a validator: $with_validator"

}

# Parse command-line options, standardized options for all clients
run_node_parse_options "$@"

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# source variables
set -a 
source "$script_dir/network/$network/$execution_client-$consensus_client/base.conf"
set +a

create_data_dir_if_not_exists $BASE_CONFIG_DATA_DIR
create_secrets_file_if_not_exists $BASE_CONFIG_SECRETS_FILE

if [ "$network" == "ephemery" ]; then 
    source ./handle_ephemery.sh
fi 

if [ "$network" == "testnet" ]; then 
    source ./handle_ephemery.sh
fi 

script=""

latest_execution_client_version=${latest_clients["$execution_client"]}
latest_consensus_client_version=${latest_clients["$consensus_client"]}

SHARED_RUN="$run"
ADDITIONAL_CONFS=""

if [ "$run" = "execution" ]; then
    client_name="$execution_client"
elif [ "$run" = "consensus" ]; then
    client_name="$consensus_client"
fi

if [ "$client_name" ]; then
    [ "$with_builder" ] && ADDITIONAL_CONFS="$ADDITIONAL_CONFS --conf-file $script_dir/network/$network/$execution_client-$consensus_client/$client_name-builder.conf"
    [ "$with_metrics" ] && ADDITIONAL_CONFS="$ADDITIONAL_CONFS --conf-file $script_dir/network/$network/$execution_client-$consensus_client/$client_name-metrics.conf"
    [ "$with_http" ] && ADDITIONAL_CONFS="$ADDITIONAL_CONFS --conf-file $script_dir/network/$network/$execution_client-$consensus_client/$client_name-http.conf"
    
    if [ "$run" = "execution" ]; then
        [ "$with_tx_pool" ] && ADDITIONAL_CONFS="$ADDITIONAL_CONFS --conf-file $script_dir/network/$network/$execution_client-$consensus_client/$client_name-tx-pool.conf"
        [ "$with_ws" ] && ADDITIONAL_CONFS="$ADDITIONAL_CONFS --conf-file $script_dir/network/$network/$execution_client-$consensus_client/$client_name-ws.conf"
    fi
    
  
fi
if [ "$run" = "consensus" ]; then 
    if [ "$with_validator" = true ]; then
        ADDITIONAL_CONFS="$ADDITIONAL_CONFS --conf-file $script_dir/network/$network/$execution_client-$consensus_client/$client_name-with-validator.conf"
    else
        ADDITIONAL_CONFS="$ADDITIONAL_CONFS --conf-file $script_dir/network/$network/$execution_client-$consensus_client/$client_name-without-validator.conf"
    fi
fi 
export SHARED_RUN

if [ "$client_name" ] ; then 
    script="$script_dir/clients/$execution_client/$latest_execution_client_version/run-$client_name.sh"
    chmod +x "$script"
    $script --conf-file "$script_dir/network/$network/$execution_client-$consensus_client/$client_name-base.conf" $ADDITIONAL_CONFS
elif [ "$run" = "validator" ]; then 
    script="$script_dir/clients/$consensus_client/$latest_consensus_client_version/run-validator.sh"
    chmod +x "$script"
    $script --env-file "$script_dir/network/$network/$execution_client-$consensus_client/validator.conf"
elif [ "$run" = "bootnode" ]; then 
    script="$script_dir/clients/$consensus_client/$latest_consensus_client_version/run-$consensus_client.sh"
    chmod +x "$script"
    $script --env-file "$script_dir/network/$network/$execution_client-$consensus_client/bootnode.conf"   
else 
    echo "unsupported option"
    exit 1     
fi 
