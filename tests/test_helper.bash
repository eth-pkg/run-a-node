#!/usr/bin/env bash

does_not_contain_error() {
  local message="$1"
  local lower_message
  lower_message=$(echo "$message" | tr '[:upper:]' '[:lower:]')
  [[ "$lower_message" != *"error"* ]]
}

check_el_started() {
  local network="$1"
  local el_output_log="$2"
  local el_name="$3"
  local el_output

  el_output=$(cat "$el_output_log")
  rm $el_output_log 2>/dev/null

  if [ "mainnet" = "$network" ]; then
    if [ "besu" = "$el_name" ]; then
      [[ "$el_output" == *"Network: Mainnet"* ]]
      [[ "$el_output" == *"Ethereum main loop is up"* ]]
    elif [ "erigon" = "$el_name" ]; then
      [[ "$el_output" == *"Initialising Ethereum protocol           network=1"* ]]
    elif [ "geth" = "$el_name" ]; then
      [[ "$el_output" == *"Starting Geth on Ethereum mainnet"* ]]
      [[ "$el_output" == *"Started P2P networking"* ]]
    elif [ "nethermind" = "$el_name"]; then
      [[ "$el_output" == *"Chain ID     : Mainnet"* ]]
    elif [ "reth" = "$el_name" ]; then
      [[ "$el_output" == *"Consensus engine initialized"* ]]
    else
      echo "Unsupported execution client"
      exit 1
    fi
  else
    echo "EL tests are not implemented for network: $network"
    exit 1

  fi
}

check_cl_started() {
  local network="$1"
  local cl_output_log="$2"
  local cl_name="$3"
  local cl_output

  cl_output=$(cat "$cl_output_log")
  rm $cl_output_log 2>/dev/null

  if [ "mainnet" = "$network" ]; then
    if [ "lighthouse" = "$cl_name" ]; then
      [[ "$cl_output" == *"Configured for network                  name: mainnet"* ]]
      [[ "$cl_output" == *"Starting checkpoint sync"* ]]
    elif [ "lodestar" = "$cl_name" ]; then
      [[ "$cl_output" == *"Lodestar network=mainnet"* ]]
      [[ "$cl_output" == *"Fetching checkpoint state"* ]]
    elif [ "nimbus-eth2" = "$cl_name" ]; then
      [[ "$cl_output" == *"const_preset=mainnet"* ]]
      [[ "$cl_output" == *"Starting beacon node"* ]]
    elif [ "prysm" = "$cl_name" ]; then
      [[ "$cl_output" == *"Running on Ethereum Mainnet"* ]]
      [[ "$cl_output" == *"Starting initial chain sync"* ]]
    elif [ "teku" = "$cl_name" ]; then
      [[ "$cl_output" == *"Configuration | Network: mainnet"* ]]
      # test if can connect to el client
      [[ "$cl_output" == *"Syncing started"* ]]
    else
      echo "Unsupported consensus client"
      exit 1
    fi
  else
    echo "CL tests are not implemented for network: $network"
    exit 1
  fi
}

run_test() {
  local network="$1"
  local el="$2"
  local cl="$3"
  local wait_time="$4"
  local el_output_log cl_output_log

  el_output_log=$(mktemp)
  cl_output_log=$(mktemp)

  # TODO shared data dir, this will need to be fixed 
  # tests should use a random dir
  rm -rf "$HOME/.run-a-node"

  bash run-a-client.sh --network "$network" --el "$el" &>"$el_output_log" &
  el_pid=$!
  bash run-a-client.sh --network "$network" --cl "$cl" &>"$cl_output_log" &
  cl_pid=$!

  sleep "$wait_time"

  kill "$el_pid" 2>/dev/null || echo "Failed to kill $el process with PID $el_pid"

  pkill -P "$cl_pid" 2>/dev/null || true  
  kill "$cl_pid" 2>/dev/null || true  

  check_el_started "$network" "$el_output_log" "$el_name"
  check_cl_started "$network" "$cl_output_log" "$cl_name"

}
