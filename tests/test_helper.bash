#!/usr/bin/env bash

el_pid=
cl_pid=

kill_process() {
  local pid="$1"
  local output
  local attempt=1
  local killed=false

  until [ $attempt -gt 9 ]; do
    if ! ps -p "$pid" > /dev/null 2>&1; then
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

kill_process_on_port(){
  local port="$1"
  local pid 

  pid=$(lsof -ti :$port 2>&1 || true)

  kill_process "$pid"
}


trap helper_cleanup EXIT INT SIGINT SIGTERM

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
    elif [ "nethermind" = "$el_name" ]; then
      [[ "$el_output" == *"Chain ID     : Mainnet"* ]]
    elif [ "reth" = "$el_name" ]; then
      # TODO not sure how to know which chain
      [[ "$el_output" == *"Consensus engine initialized"* ]]
    else
      echo "Unsupported execution client"
      exit 1
    fi
  elif [ "sepolia" = "$network" ]; then
    if [ "besu" = "$el_name" ]; then
      [[ "$el_output" == *"Network: Sepolia"* ]]
      [[ "$el_output" == *"Ethereum main loop is up"* ]]
    elif [ "erigon" = "$el_name" ]; then
      [[ "$el_output" == *"Initialising Ethereum protocol           network=11155111"* ]]
    elif [ "geth" = "$el_name" ]; then
      [[ "$el_output" == *"Starting Geth on Sepolia testnet..."* ]]
      [[ "$el_output" == *"Started P2P networking"* ]]
    elif [ "nethermind" = "$el_name" ]; then
      [[ "$el_output" == *"Chain ID     : Sepolia"* ]]
    elif [ "reth" = "$el_name" ]; then
      # TODO not sure how to know which chain
      [[ "$el_output" == *"Consensus engine initialized"* ]]
    else
      echo "Unsupported execution client"
      exit 1
    fi  
  elif [ "holesky" = "$network" ]; then
    if [ "besu" = "$el_name" ]; then
      [[ "$el_output" == *"Network: Holesky"* ]]
      [[ "$el_output" == *"Ethereum main loop is up"* ]]
    elif [ "erigon" = "$el_name" ]; then
      [[ "$el_output" == *"Initialising Ethereum protocol           network=17000"* ]]
    elif [ "geth" = "$el_name" ]; then
      [[ "$el_output" == *"Starting Geth on Holesky testnet..."* ]]
      [[ "$el_output" == *"Started P2P networking"* ]]
    elif [ "nethermind" = "$el_name" ]; then
      [[ "$el_output" == *"Chain ID     : Holesky"* ]]
    elif [ "reth" = "$el_name" ]; then
      # TODO not sure how to know which chain
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
      # test assurance that el is connected
      [[ "$cl_output" == *"\"Connected to new endpoint\" endpoint=\"http://localhost:8551\""* ]]
    elif [ "teku" = "$cl_name" ]; then
      [[ "$cl_output" == *"Configuration | Network: mainnet"* ]]
      # test if can connect to el client
      [[ "$cl_output" == *"Syncing started"* ]]
    else
      echo "Unsupported consensus client"
      exit 1
    fi
  elif [ "sepolia" = "$network" ]; then
    if [ "lighthouse" = "$cl_name" ]; then
      [[ "$cl_output" == *"Configured for network                  name: sepolia"* ]]
      [[ "$cl_output" == *"Starting checkpoint sync"* ]]
    elif [ "lodestar" = "$cl_name" ]; then
      [[ "$cl_output" == *"Lodestar network=sepolia"* ]]
      [[ "$cl_output" == *"Fetching checkpoint state"* ]]
    elif [ "nimbus-eth2" = "$cl_name" ]; then
      [[ "$cl_output" == *"eth2Network: some(\\\"sepolia\\\")"* ]]
      [[ "$cl_output" == *"Starting beacon node"* ]]
    elif [ "prysm" = "$cl_name" ]; then
      [[ "$cl_output" == *"Running on the Sepolia Beacon Chain Testnet"* ]]
      # test assurance that el is connected
      [[ "$cl_output" == *"\"Connected to new endpoint\" endpoint=\"http://localhost:8551\""* ]]
    elif [ "teku" = "$cl_name" ]; then
      [[ "$cl_output" == *"Configuration | Network: sepolia"* ]]
      # test if can connect to el client
      [[ "$cl_output" == *"Syncing started"* ]]
    else
      echo "Unsupported consensus client"
      exit 1
    fi
  elif [ "holesky" = "$network" ]; then
    if [ "lighthouse" = "$cl_name" ]; then
      [[ "$cl_output" == *"Configured for network                  name: holesky"* ]]
      [[ "$cl_output" == *"Starting checkpoint sync"* ]]
    elif [ "lodestar" = "$cl_name" ]; then
      [[ "$cl_output" == *"Lodestar network=holesky"* ]]
      [[ "$cl_output" == *"Fetching checkpoint state"* ]]
    elif [ "nimbus-eth2" = "$cl_name" ]; then
      [[ "$cl_output" == *"Obtaining genesis state"* ]]
      [[ "$cl_output" == *"holesky-genesis.ssz.sz"* ]]
      [[ "$cl_output" == *"Starting beacon node"* ]]
    elif [ "prysm" = "$cl_name" ]; then
      [[ "$cl_output" == *"Running on the Holesky Beacon Chain Testnet"* ]]
      # test assurance that el is connected
      [[ "$cl_output" == *"\"Connected to new endpoint\" endpoint=\"http://localhost:8551\""* ]]
    elif [ "teku" = "$cl_name" ]; then
      [[ "$cl_output" == *"Configuration | Network: holesky"* ]]
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
  # Arrange
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
  
  # kill hanging processes on ports, from previous tests, if exists
  # TODO should be coming from the config shared_port, el_discovery_port and cl_discovery_port
  kill_process_on_port "8551"
  kill_process_on_port "30303"
  kill_process_on_port "9000"

  # Act
  nohup bash run-a-client.sh --network "$network" --el "$el"  >"$el_output_log" 2>&1 &
  el_pid=$!
  nohup bash run-a-client.sh --network "$network" --cl "$cl" >"$cl_output_log" 2>&1 &
  cl_pid=$!

  sleep "$wait_time"

  kill_process "$cl_pid"
  kill_process "$el_pid"

  # Assert
  # cat "$el_output_log"
  # echo "---------------------END OF EL LOG----------------"
  # echo "---------------------END OF EL LOG----------------"
  # echo "---------------------END OF EL LOG----------------"
  # cat "$cl_output_log" 
  check_el_started "$network" "$el_output_log" "$el_name"
  check_cl_started "$network" "$cl_output_log" "$cl_name"

}
