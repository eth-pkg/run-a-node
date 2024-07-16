#!/usr/bin/env bash

el_pid=
cl_pid=

kill_process() {
  local pid="$1"
  local output
  local attempt=1
  local killed=false

  until [ $attempt -gt 9 ]; do
    if ! ps -p "$pid" >/dev/null 2>&1; then
      killed=true
      break
    fi

    output=$(kill "$pid" 2>&1)
    if [ "$?" == 0 ]; then
      killed=true
      break
    fi

    attempt=$((attempt + 1))
  done

  if [ "$killed" = false ]; then
    output=$(kill -9 "$pid" 2>&1)
  fi
}

helper_cleanup() {
  echo "Cleaning up background processes and logs..."
  kill_process "$el_pid"
  kill_process "$cl_pid"
}

kill_process_on_port() {
  local port="$1"
  local pid

  pid=$(lsof -ti :$port 2>&1 || true)

  if ! [ -z "$pid"]; then
    echo "killing pid: $pid" >&2

    kill -9 $pid
  fi
}

trap helper_cleanup EXIT INT SIGINT SIGTERM

call_rpc_api() {
  local url=$1
  local payload=$2
  local response

  echo "curl -s -X POST --data '"$payload"' -H "Content-Type: application/json" $url" >&2
  response=$(curl -s -X POST --data "$payload" -H "Content-Type: application/json" $url || true)

  if echo "$response" | grep -q '"result"'; then
    echo "$response"
  else
    echo "execution client is offline or unreachable." >&2
    exit 1
  fi
}

call_json_api() {
  local url=$1
  local response

  echo "curl -s -X GET -H "Content-Type: application/json" $url" >&2
  response=$(curl -s -X GET -H "Content-Type: application/json" $url || true)

  if echo "$response" | grep -q '"data"'; then
    echo "$response"
  else
    echo "client is offline or unreachable." >&2
    exit 1
  fi
}

get_chain_id_on_eth1() {
  local url=$1
  local payload='{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":0}'
  local response=$(call_rpc_api $url $payload)
  local status=$?
  if [ $status -ne 0 ]; then
    exit $status
  fi
  echo "response: $response" >&2
  local chain_id=$(echo $response | jq '.result' | sed 's/"//g')
  printf "%d" $chain_id
}

get_chain_id_on_beacon_chain() {
  local url=$1
  local response=$(call_json_api "$url/eth/v1/config/deposit_contract")
  local status=$?
  if [ $status -ne 0 ]; then
    exit $status
  fi
  echo "response: $response" >&2
  local chain_id=$(echo $response | jq '.data.chain_id' | sed 's/"//g')
  echo $chain_id
}

get_el_syncing() {
  local url=$1
  local payload='{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":0}'
  local response=$(call_rpc_api $url $payload)
  local status=$?
  if [ $status -ne 0 ]; then
    exit $status
  fi
  echo "$response" >&2
  local result=$(echo $response | jq '.result')
  echo $result
}

get_chain_id_for_network() {
  local network="$1"

  if [ "mainnet" = "$network" ]; then
    echo 1
  elif [ "sepolia" = "$network" ]; then
    echo 11155111 # use hex stripped id, TODO fix it later on
  elif [ "holesky" = "$network" ]; then
    echo 17000
  elif [ "ephemery" = "$network" ]; then
    local network_id=$(cat $HOME/.run-a-node/ephemery/ephemery/genesis.json | grep chainId | tr -d ',' | sed 's/"chainId"://g' | tr -d '[:space:]')
    echo $network_id
  elif [ "testnet" = "$network" ]; then
    echo 1337
  else
    echo "Unsupported $network" >&2
    exit 1
  fi
}

check_network() {
  local url="$1"
  local network="$2"
  local expected_chain_id=$(get_chain_id_for_network $network)
  local chain_id=$(get_chain_id $url)
  local status=$?
  if [ $status -ne 0 ]; then
    exit $status
  fi

  [ "$expected_chain_id" == "$chain_id" ]
}

error_not_network() {
  local network="$1"
  local client="$2"
  echo "Error: Network is not $network for $client"
  exit 1
}

test_checkpoint_sync() {
  local cl_sync_status=$1
  local el_sync_status=$2
  local cl=$3
  local el=$4
  local el_offline=$(echo $cl_sync_status | jq .data.el_offline)
  local cl_is_syncing=$(echo $cl_sync_status | jq .data.is_syncing)
  local cl_is_optimistic=$(echo $cl_sync_status | jq .data.is_optimistic)

  if [ "$cl_is_syncing" = "false" ] && [ "$cl_is_optimistic" = "true" ]; then
    :
  elif [ "$cl_is_syncing" = "true" ] && [ "$cl_is_optimistic" = "true" ] && [ "$cl" = "teku" ]; then
    :  # teku is doing backfill with checkpoint sync
  elif [ "$cl_is_syncing" = "true" ] && [ "$cl_is_optimistic" = "true" ] && [ "$cl" = "nimbus-eth2" ]; then
    :  # nimbus-eth2 is also doing backfilling, so sync status is true  
  else
    echo "Consensus client is not using checkpoint sync" # we are testing for checkpoint sync in this case
    exit 1
  fi
  if [ "prysm" = "$cl" ]; then
    # BUG with prysm until version 5.0.4
    [ "true" = "$el_offline" ] || {
      echo "$el is offline"
      exit 1
    }
  else
    [ "false" = "$el_offline" ] || {
      echo "$el is offline"
      exit 1
    }
  fi

  # on mainnet after CL sync (checkpoint sync), the client should be syncing (mainnet, sepolia, holesky)
  if [ "false" = "$el_sync_status" ]; then
    echo "el is not syncing"
    exit 1
  fi

}

run_test() {
  # Arrange
  local network="$1"
  local el="$2"
  local cl="$3"
  local wait_time="$4"
  local output_log_el output_log_cl
  local expected_chain_id=$(get_chain_id_for_network $network)
  local chain_id_cl chain_id_el
  local cl_sync_status el_offline cl_is_syncing el_sync_status cl_is_optimistic

  output_log_cl=$(mktemp)
  output_log_el=$(mktemp)

  # TODO shared data dir, this will need to be fixed
  # tests should use a random dir
  rm -rf "$HOME/.run-a-node"

  # kill hanging processes on ports, from previous tests, if exists
  # TODO should be coming from the config shared_port, el_discovery_port and cl_discovery_port
  kill_process_on_port "8551"
  kill_process_on_port "30303"
  kill_process_on_port "9000"
  kill_process_on_port "8545"
  kill_process_on_port "5052"

  # Act
  bash run-a-client.sh --network "$network" --el "$el" >"$output_log_el" 2>&1 &
  el_pid=$!
  nohup ./run-a-client.sh --network "$network" --cl "$cl" >"$output_log_cl" 2>&1 &
  cl_pid=$!

  sleep "$wait_time"

  chain_id_el=$(get_chain_id_on_eth1 "http://localhost:8545" || true)
  chain_id_cl=$(get_chain_id_on_beacon_chain "http://localhost:5052" || true)
  cl_sync_status=$(call_json_api "http://localhost:5052/eth/v1/node/syncing" || true)
  echo "response: $cl_sync_status" >&2
  el_sync_status=$(get_el_syncing "http://localhost:8545" || true)
  echo "response: $el_sync_status" >&2

  kill_process "$el_pid"

  if [ "nimbu-eth2" = "$cl" ];then 
    echo "$output_log_cl"
  fi 

  # Cleanup first, otherwise test process will hang
  # fix lodestar hanging issue, while running the tests
  if [ "lodestar" = "$cl" ]; then
    pkill -P "$cl_pid" >/dev/null 2>&1
  else
    kill_process "$cl_pid"
  fi

  # Assert
  [ "$expected_chain_id" = "$chain_id_el" ] || {
    echo "Execution client started on wrong network expected: $expected_chain_id, received: $chain_id_el"
    cat $output_log_el
    exit 1
  }
  [ "$expected_chain_id" = "$chain_id_cl" ] || {
    echo "Consensus client started on wrong network expected: $expected_chain_id, received: $chain_id_cl"
    cat $output_log_cl
    exit 1
  }

  test_checkpoint_sync "$cl_sync_status" "$el_sync_status" "$cl" "$el"
}
