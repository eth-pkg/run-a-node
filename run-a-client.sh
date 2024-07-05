#!/usr/bin/env bash

set -euo pipefail

readonly VALID_EXECUTION_CLIENTS=("besu" "erigon" "geth" "nethermind" "reth")
readonly VALID_CONSENSUS_CLIENTS=("lighthouse" "lodestar" "nimbus-eth2" "prysm" "teku")
readonly VALID_NETWORK_OPTIONS=("mainnet" "sepolia" "ephemery" "holesky" "testnet")
readonly VALID_RUN_OPTIONS=("execution" "consensus" "validator")

declare -A LATEST_CLIENTS=(
    ["besu"]="24.5.1"
    ["erigon"]="2.60.0"
    ["geth"]="1.14.3"
    ["lighthouse"]="5.1.3"
    ["lodestar"]="1.18.1"
    ["nethermind"]="1.26.0"
    ["nimbus-eth2"]="24.5.1"
    ["prysm"]="5.0.3"
    ["teku"]="24.4.0"
)

create_data_dir_if_not_exists() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
    fi
}

create_secrets_file_if_not_exists() {
    local file="$1"
    if [ ! -f "$file" ]; then
        openssl rand -hex 32 | tr -d "\n" | sudo tee "$file" > /dev/null
    fi
}

run_node_usage() {
    echo "Usage: $0 [ --network mainnet|sepolia|ephemery|holesky|devnet ] \
[ --consensus-client lighthouse|lodestar|nimbus-eth2|prysm|teku ] \
[ --execution-client besu|erigon|geth|nethermind ] \
[ --run execution|consensus|validator ]"
    exit 1
}

is_valid_option() {
    local option="$1"
    shift
    local valid_options=("$@")
    for element in "${valid_options[@]}"; do
        if [[ "$element" == "$option" ]]; then
            return 0
        fi
    done
    return 1
}

network=
consensus_client=
execution_client=
run=
run_node_parse_options() {

    local opts
    opts=$(getopt -o '' -l "network:,consensus-client:,execution-client:,run:" -n "$0" -- "$@")
    if [ $? != 0 ]; then
        run_node_usage
    fi

    eval set -- "$opts"

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
            --)
                shift
                break
                ;;
            *)
                run_node_usage
                ;;
        esac
    done

    if [ -z "$network" ]; then
        echo "Please provide a network value"
        run_node_usage
    fi

    if [ -z "$consensus_client" ]; then
        echo "Please provide a consensus-client value"
        run_node_usage
    fi

    if [ -z "$execution_client" ]; then
        echo "Please provide an execution-client value"
        run_node_usage
    fi

    if [ -z "$run" ]; then
        echo "Please provide a run value"
        run_node_usage
    fi

    if ! is_valid_option "$network" "${VALID_NETWORK_OPTIONS[@]}"; then
        echo "Invalid network: $network"
        run_node_usage
    fi

    if ! is_valid_option "$consensus_client" "${VALID_CONSENSUS_CLIENTS[@]}"; then
        echo "Invalid consensus client: $consensus_client"
        run_node_usage
    fi

    if ! is_valid_option "$execution_client" "${VALID_EXECUTION_CLIENTS[@]}"; then
        echo "Invalid execution client: $execution_client"
        run_node_usage
    fi

    if ! is_valid_option "$run" "${VALID_RUN_OPTIONS[@]}"; then
        echo "Invalid run option: $run"
        run_node_usage
    fi

    echo "Network: $network"
    echo "Consensus Client: $consensus_client"
    echo "Execution Client: $execution_client"
    echo "Running Client: $run"
}

run_node_parse_options "$@"

latest_execution_client_version=${LATEST_CLIENTS["$execution_client"]}
latest_consensus_client_version=${LATEST_CLIENTS["$consensus_client"]}

EXECUTION_CLIENT=$execution_client
CONSENSUS_CLIENT=$consensus_client
EXECUTION_CLIENT_VERSION=$latest_execution_client_version
CONSENSUS_CLIENT_VERSION=$latest_consensus_client_version

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
set -a 
source "$script_dir/network/$network/$network.conf"
set +a

create_data_dir_if_not_exists "$BASE_CONFIG_DATA_DIR"
create_secrets_file_if_not_exists "$BASE_CONFIG_SECRETS_FILE"

if [[ "$network" == "ephemery" ]] || [[ "$network" == "testnet" ]]; then
    source "$script_dir/handle_ephemery.sh"
fi



shared_run="$run"
additional_confs=""
sub_dir=""
latest_client_version=

if [ "$run" == "execution" ]; then
    client_name="$execution_client"
    sub_dir="el"
    latest_client_version=$latest_execution_client_version
elif [ "$run" == "consensus" ]; then
    client_name="$consensus_client"
    sub_dir="cl"
    latest_client_version=$latest_consensus_client_version
fi

export shared_run

if [ -n "$client_name" ]; then
    script="$script_dir/clients/$client_name/$latest_client_version/run-$client_name.sh"
    chmod +x "$script"
    "$script" --conf-file "$script_dir/network/$network/$sub_dir/$client_name/$client_name-$network.conf" $additional_confs
elif [ "$run" == "validator" ]; then
    script="$script_dir/clients/$consensus_client/$latest_consensus_client_version/run-validator.sh"
    chmod +x "$script"
    "$script" --env-file "$script_dir/network/$network/$execution_client-$consensus_client/validator.conf"
else
    echo "Unsupported option"
    exit 1
fi
