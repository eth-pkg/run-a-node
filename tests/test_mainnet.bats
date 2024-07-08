#!/usr/bin/env bats

set -euo pipefail

chmod +x run-a-client.sh

network=mainnet
wait_time=10
el_pid=
cl_pid=

cleanup() {
  echo "Cleaning up background processes and logs..."
  [ -n "$el_pid" ] && kill "$el_pid" || true 
  [ -n "$cl_pid" ] && kill "$cl_pid" || true 
}

trap cleanup EXIT INT SIGINT SIGTERM

does_not_contain_error() {
  local message="$1"
  local lower_message=$(echo "$message" | tr '[:upper:]' '[:lower:]')

  if [[ "$lower_message" != *"error"* ]]; then
    return 0  
  else
    return 1
  fi
}

# NOTE I would like to run all these tests through for loops, but then filter won't be working 
#  bats --show-output-of-passing-tests tests/test_mainnet.bats --filter besu

## Besu pairs 
@test "$network: besu-lighthouse" {
  el_output_log=$(mktemp)
  cl_output_log=$(mktemp)

  rm -rf $HOME/.run-a-node

  bash run-a-client.sh --network "$network" --el besu &>"$el_output_log" &
  el_pid=$!
  bash run-a-client.sh --network "$network" --cl lighthouse &>"$cl_output_log" &
  cl_pid=$!

  sleep "$wait_time"

  cl_output=$(cat $cl_output_log)
  el_output=$(cat $el_output_log)

  kill $el_pid  2>/dev/null || echo "Failed to kill process with PID $el_pid"
  # use kill instead of pkill with lighthouse
  kill $cl_pid  2>/dev/null || echo "Failed to kill process with PID $cl_pid"

  [[ "$el_output" == *"Network: Mainnet"* ]]
  [[ "$el_output" == *"Ethereum main loop is up"* ]]

  [[ "$cl_output" == *"Configured for network                  name: mainnet"* ]]
  [[ "$cl_output" == *"Starting checkpoint sync"* ]]

}

@test "$network: besu-lodestar" {
  el_output_log=$(mktemp)
  cl_output_log=$(mktemp)

  rm -rf $HOME/.run-a-node

  bash run-a-client.sh --network "$network" --el besu &>"$el_output_log" &
  el_pid=$!
  bash run-a-client.sh --network "$network" --cl lodestar &>"$cl_output_log" &
  cl_pid=$!

  sleep "$wait_time"

  cl_output=$(cat $cl_output_log)
  el_output=$(cat $el_output_log)

  kill $el_pid  2>/dev/null || echo "Failed to kill process with PID $el_pid"
  pkill -9 -P $cl_pid  2>/dev/null || echo "Failed to kill process with PID $cl_pid"

  [[ "$el_output" == *"Network: Mainnet"* ]]
  [[ "$el_output" == *"Ethereum main loop is up"* ]]

  [[ "$cl_output" == *"Lodestar network=mainnet"* ]]
  [[ "$cl_output" == *"Fetching checkpoint state"* ]]
}

@test "$network: besu-nimbus-eth2" {
  el_output_log=$(mktemp)
  cl_output_log=$(mktemp)

  rm -rf $HOME/.run-a-node

  bash run-a-client.sh --network "$network" --el besu &>"$el_output_log" &
  el_pid=$!
  bash run-a-client.sh --network "$network" --cl nimbus-eth2 &>"$cl_output_log" &
  cl_pid=$!

  sleep "$wait_time"

  cl_output=$(cat $cl_output_log)
  el_output=$(cat $el_output_log)

  kill $el_pid  2>/dev/null || echo "Failed to kill process with PID $el_pid"
  # use kill instead of pkill with nimbus-eth2
  kill $cl_pid  2>/dev/null || echo "Failed to kill process with PID $cl_pid"

  [[ "$el_output" == *"Network: Mainnet"* ]]
  [[ "$el_output" == *"Ethereum main loop is up"* ]]

  [[ "$cl_output" == *"const_preset=mainnet"* ]]
  [[ "$cl_output" == *"Starting beacon node"* ]]
}

@test "$network: besu-prysm" {
  el_output_log=$(mktemp)
  cl_output_log=$(mktemp)

  rm -rf $HOME/.run-a-node

  bash run-a-client.sh --network "$network" --el besu &>"$el_output_log" &
  el_pid=$!
  bash run-a-client.sh --network "$network" --cl prysm &>"$cl_output_log" &
  cl_pid=$!

  sleep 40 # prysm initial sync is slower

  cl_output=$(cat $cl_output_log)
  el_output=$(cat $el_output_log)

  kill $el_pid  2>/dev/null || echo "Failed to kill process with PID $el_pid"
  # use kill instead of pkill with prysm
  kill $cl_pid  2>/dev/null || echo "Failed to kill process with PID $cl_pid"

  [[ "$el_output" == *"Network: Mainnet"* ]]
  [[ "$el_output" == *"Ethereum main loop is up"* ]]

  [[ "$cl_output" == *"Running on Ethereum Mainnet"* ]]
  [[ "$cl_output" == *"Starting initial chain sync"* ]]
}

@test "$network: besu-teku" {
  el_output_log=$(mktemp)
  cl_output_log=$(mktemp)

  rm -rf $HOME/.run-a-node

  bash run-a-client.sh --network "$network" --el besu &>"$el_output_log" &
  el_pid=$!
  bash run-a-client.sh --network "$network" --cl teku &>"$cl_output_log" &
  cl_pid=$!

  sleep 60

  cl_output=$(cat $cl_output_log)
  el_output=$(cat $el_output_log)

  kill $el_pid  2>/dev/null || echo "Failed to kill process with PID $el_pid"
  # pkill does not work with teku
  kill $cl_pid  2>/dev/null || echo "Failed to kill process with PID $cl_pid"

  [[ "$el_output" == *"Network: Mainnet"* ]]
  [[ "$el_output" == *"Ethereum main loop is up"* ]]

  [[ "$cl_output" == *"Network: mainnet"* ]]
  [[ "$cl_output" == *"Syncing started"* ]]
  # [[ "$cl_output" == *"Execution Client is online"* ]]
}

## Ergion pairs 
@test "$network: erigon-lighthouse" {
  el_output_log=$(mktemp)
  cl_output_log=$(mktemp)

  rm -rf $HOME/.run-a-node

  bash run-a-client.sh --network "$network" --el erigon &>"$el_output_log" &
  el_pid=$!
  bash run-a-client.sh --network "$network" --cl lighthouse &>"$cl_output_log" &
  cl_pid=$!

  sleep "$wait_time"

  cl_output=$(cat $cl_output_log)
  el_output=$(cat $el_output_log)

  kill $el_pid  2>/dev/null || echo "Failed to kill process with PID $el_pid"
  # use kill instead of pkill with lighthouse
  kill $cl_pid  2>/dev/null || echo "Failed to kill process with PID $cl_pid"

  # TODO: not sure if this is what it should be tested 
  [[ "$el_output" == *"Initialising Ethereum protocol           network=1"* ]]

  [[ "$cl_output" == *"Configured for network                  name: mainnet"* ]]
  [[ "$cl_output" == *"Starting checkpoint sync"* ]]

}

@test "$network: erigon-lodestar" {
  el_output_log=$(mktemp)
  cl_output_log=$(mktemp)

  rm -rf $HOME/.run-a-node

  bash run-a-client.sh --network "$network" --el erigon &>"$el_output_log" &
  el_pid=$!
  bash run-a-client.sh --network "$network" --cl lodestar &>"$cl_output_log" &
  cl_pid=$!

  sleep "$wait_time"

  cl_output=$(cat $cl_output_log)
  el_output=$(cat $el_output_log)

  kill $el_pid  2>/dev/null || echo "Failed to kill process with PID $el_pid"
  pkill -9 -P $cl_pid  2>/dev/null || echo "Failed to kill process with PID $cl_pid"

  # TODO: not sure if this is what it should be tested 
  [[ "$el_output" == *"Initialising Ethereum protocol           network=1"* ]]

  [[ "$cl_output" == *"Lodestar network=mainnet"* ]]
  [[ "$cl_output" == *"Fetching checkpoint state"* ]]
}

@test "$network: erigon-nimbus-eth2" {
  el_output_log=$(mktemp)
  cl_output_log=$(mktemp)

  rm -rf $HOME/.run-a-node

  bash run-a-client.sh --network "$network" --el erigon &>"$el_output_log" &
  el_pid=$!
  bash run-a-client.sh --network "$network" --cl nimbus-eth2 &>"$cl_output_log" &
  cl_pid=$!

  sleep "$wait_time"

  cl_output=$(cat $cl_output_log)
  el_output=$(cat $el_output_log)

  kill $el_pid  2>/dev/null || echo "Failed to kill process with PID $el_pid"
  # use kill instead of pkill with nimbus-eth2
  kill $cl_pid  2>/dev/null || echo "Failed to kill process with PID $cl_pid"

  # TODO: not sure if this is what it should be tested 
  [[ "$el_output" == *"Initialising Ethereum protocol           network=1"* ]]

  [[ "$cl_output" == *"const_preset=mainnet"* ]]
  [[ "$cl_output" == *"Starting beacon node"* ]]
}

@test "$network: erigon-prysm" {
  el_output_log=$(mktemp)
  cl_output_log=$(mktemp)

  rm -rf $HOME/.run-a-node

  bash run-a-client.sh --network "$network" --el erigon &>"$el_output_log" &
  el_pid=$!
  bash run-a-client.sh --network "$network" --cl prysm &>"$cl_output_log" &
  cl_pid=$!

  sleep 40 # prysm initial sync is slower

  cl_output=$(cat $cl_output_log)
  el_output=$(cat $el_output_log)

  kill $el_pid  2>/dev/null || echo "Failed to kill process with PID $el_pid"
  # use kill instead of pkill with prysm
  kill $cl_pid  2>/dev/null || echo "Failed to kill process with PID $cl_pid"

  # TODO: not sure if this is what it should be tested 
  [[ "$el_output" == *"Initialising Ethereum protocol           network=1"* ]]

  [[ "$cl_output" == *"Running on Ethereum Mainnet"* ]]
  [[ "$cl_output" == *"Starting initial chain sync"* ]]
}

@test "$network: erigon-teku" {
  el_output_log=$(mktemp)
  cl_output_log=$(mktemp)

  rm -rf $HOME/.run-a-node

  bash run-a-client.sh --network "$network" --el erigon &>"$el_output_log" &
  el_pid=$!
  bash run-a-client.sh --network "$network" --cl teku &>"$cl_output_log" &
  cl_pid=$!

  sleep 60

  cl_output=$(cat $cl_output_log)
  el_output=$(cat $el_output_log)

  kill $el_pid  2>/dev/null || echo "Failed to kill process with PID $el_pid"
  # pkill does not work with teku
  kill $cl_pid  2>/dev/null || echo "Failed to kill process with PID $cl_pid"

  # TODO: not sure if this is what it should be tested 
  [[ "$el_output" == *"Initialising Ethereum protocol           network=1"* ]]

  [[ "$cl_output" == *"Network: mainnet"* ]]
  [[ "$cl_output" == *"Syncing started"* ]]
  # [[ "$cl_output" == *"Execution Client is online"* ]]
}

# geth 

@test "$network: geth-lighthouse" {
  el_output_log=$(mktemp)
  cl_output_log=$(mktemp)

  rm -rf $HOME/.run-a-node

  bash run-a-client.sh --network "$network" --el geth &>"$el_output_log" &
  el_pid=$!
  bash run-a-client.sh --network "$network" --cl lighthouse &>"$cl_output_log" &
  cl_pid=$!

  sleep "$wait_time"

  cl_output=$(cat $cl_output_log)
  el_output=$(cat $el_output_log)

  kill $el_pid  2>/dev/null || echo "Failed to kill process with PID $el_pid"
  # use kill instead of pkill with lighthouse
  kill $cl_pid  2>/dev/null || echo "Failed to kill process with PID $cl_pid"

  [[ "$el_output" == *"Starting Geth on Ethereum mainnet"* ]]
  [[ "$el_output" == *"Started P2P networking"* ]]

  [[ "$cl_output" == *"Configured for network                  name: mainnet"* ]]
  [[ "$cl_output" == *"Starting checkpoint sync"* ]]

}

@test "$network: geth-lodestar" {
  el_output_log=$(mktemp)
  cl_output_log=$(mktemp)

  rm -rf $HOME/.run-a-node

  bash run-a-client.sh --network "$network" --el geth &>"$el_output_log" &
  el_pid=$!
  bash run-a-client.sh --network "$network" --cl lodestar &>"$cl_output_log" &
  cl_pid=$!

  sleep "$wait_time"

  cl_output=$(cat $cl_output_log)
  el_output=$(cat $el_output_log)

  kill $el_pid  2>/dev/null || echo "Failed to kill process with PID $el_pid"
  pkill -9 -P $cl_pid  2>/dev/null || echo "Failed to kill process with PID $cl_pid"

  [[ "$el_output" == *"Starting Geth on Ethereum mainnet"* ]]
  [[ "$el_output" == *"Started P2P networking"* ]]

  [[ "$cl_output" == *"Lodestar network=mainnet"* ]]
  [[ "$cl_output" == *"Fetching checkpoint state"* ]]
}

@test "$network: geth-nimbus-eth2" {
  el_output_log=$(mktemp)
  cl_output_log=$(mktemp)

  rm -rf $HOME/.run-a-node

  bash run-a-client.sh --network "$network" --el geth &>"$el_output_log" &
  el_pid=$!
  bash run-a-client.sh --network "$network" --cl nimbus-eth2 &>"$cl_output_log" &
  cl_pid=$!

  sleep "$wait_time"

  cl_output=$(cat $cl_output_log)
  el_output=$(cat $el_output_log)

  kill $el_pid  2>/dev/null || echo "Failed to kill process with PID $el_pid"
  # use kill instead of pkill with nimbus-eth2
  kill $cl_pid  2>/dev/null || echo "Failed to kill process with PID $cl_pid"

  [[ "$el_output" == *"Starting Geth on Ethereum mainnet"* ]]
  [[ "$el_output" == *"Started P2P networking"* ]]

  [[ "$cl_output" == *"const_preset=mainnet"* ]]
  [[ "$cl_output" == *"Starting beacon node"* ]]
}

@test "$network: geth-prysm" {
  el_output_log=$(mktemp)
  cl_output_log=$(mktemp)

  rm -rf $HOME/.run-a-node

  bash run-a-client.sh --network "$network" --el geth &>"$el_output_log" &
  el_pid=$!
  bash run-a-client.sh --network "$network" --cl prysm &>"$cl_output_log" &
  cl_pid=$!

  sleep 40 # prysm initial sync is slower

  cl_output=$(cat $cl_output_log)
  el_output=$(cat $el_output_log)

  kill $el_pid  2>/dev/null || echo "Failed to kill process with PID $el_pid"
  # use kill instead of pkill with prysm
  kill $cl_pid  2>/dev/null || echo "Failed to kill process with PID $cl_pid"

  [[ "$el_output" == *"Starting Geth on Ethereum mainnet"* ]]
  [[ "$el_output" == *"Started P2P networking"* ]]

  [[ "$cl_output" == *"Running on Ethereum Mainnet"* ]]
  [[ "$cl_output" == *"Starting initial chain sync"* ]]
}

@test "$network: geth-teku" {
  el_output_log=$(mktemp)
  cl_output_log=$(mktemp)

  rm -rf $HOME/.run-a-node

  bash run-a-client.sh --network "$network" --el geth &>"$el_output_log" &
  el_pid=$!
  bash run-a-client.sh --network "$network" --cl teku &>"$cl_output_log" &
  cl_pid=$!

  sleep 60

  cl_output=$(cat $cl_output_log)
  el_output=$(cat $el_output_log)

  kill $el_pid  2>/dev/null || echo "Failed to kill process with PID $el_pid"
  # pkill does not work with teku
  kill $cl_pid  2>/dev/null || echo "Failed to kill process with PID $cl_pid"

  [[ "$el_output" == *"Starting Geth on Ethereum mainnet"* ]]
  [[ "$el_output" == *"Started P2P networking"* ]]

  [[ "$cl_output" == *"Network: mainnet"* ]]
  [[ "$cl_output" == *"Syncing started"* ]]
  # [[ "$cl_output" == *"Execution Client is online"* ]]
}
# nethermind 
@test "$network: nethermind-lighthouse" {
  el_output_log=$(mktemp)
  cl_output_log=$(mktemp)

  rm -rf $HOME/.run-a-node

  bash run-a-client.sh --network "$network" --el nethermind &>"$el_output_log" &
  el_pid=$!
  bash run-a-client.sh --network "$network" --cl lighthouse &>"$cl_output_log" &
  cl_pid=$!

  sleep "$wait_time"

  cl_output=$(cat $cl_output_log)
  el_output=$(cat $el_output_log)

  kill $el_pid  2>/dev/null || echo "Failed to kill process with PID $el_pid"
  # use kill instead of pkill with lighthouse
  kill $cl_pid  2>/dev/null || echo "Failed to kill process with PID $cl_pid"

  [[ "$el_output" == *"Chain ID     : Mainnet"* ]]

  [[ "$cl_output" == *"Configured for network                  name: mainnet"* ]]
  [[ "$cl_output" == *"Starting checkpoint sync"* ]]

}

@test "$network: nethermind-lodestar" {
  el_output_log=$(mktemp)
  cl_output_log=$(mktemp)

  rm -rf $HOME/.run-a-node

  bash run-a-client.sh --network "$network" --el nethermind &>"$el_output_log" &
  el_pid=$!
  bash run-a-client.sh --network "$network" --cl lodestar &>"$cl_output_log" &
  cl_pid=$!

  sleep "$wait_time"

  cl_output=$(cat $cl_output_log)
  el_output=$(cat $el_output_log)

  kill $el_pid  2>/dev/null || echo "Failed to kill process with PID $el_pid"
  pkill -9 -P $cl_pid  2>/dev/null || echo "Failed to kill process with PID $cl_pid"

  [[ "$el_output" == *"Chain ID     : Mainnet"* ]]

  [[ "$cl_output" == *"Lodestar network=mainnet"* ]]
  [[ "$cl_output" == *"Fetching checkpoint state"* ]]
}

@test "$network: nethermind-nimbus-eth2" {
  el_output_log=$(mktemp)
  cl_output_log=$(mktemp)

  rm -rf $HOME/.run-a-node

  bash run-a-client.sh --network "$network" --el nethermind &>"$el_output_log" &
  el_pid=$!
  bash run-a-client.sh --network "$network" --cl nimbus-eth2 &>"$cl_output_log" &
  cl_pid=$!

  sleep "$wait_time"

  cl_output=$(cat $cl_output_log)
  el_output=$(cat $el_output_log)

  kill $el_pid  2>/dev/null || echo "Failed to kill process with PID $el_pid"
  # use kill instead of pkill with nimbus-eth2
  kill $cl_pid  2>/dev/null || echo "Failed to kill process with PID $cl_pid"

  [[ "$el_output" == *"Chain ID     : Mainnet"* ]]

  [[ "$cl_output" == *"const_preset=mainnet"* ]]
  [[ "$cl_output" == *"Starting beacon node"* ]]
}

@test "$network: nethermind-prysm" {
  el_output_log=$(mktemp)
  cl_output_log=$(mktemp)

  rm -rf $HOME/.run-a-node

  bash run-a-client.sh --network "$network" --el nethermind &>"$el_output_log" &
  el_pid=$!
  bash run-a-client.sh --network "$network" --cl prysm &>"$cl_output_log" &
  cl_pid=$!

  sleep 40 # prysm initial sync is slower

  cl_output=$(cat $cl_output_log)
  el_output=$(cat $el_output_log)

  kill $el_pid  2>/dev/null || echo "Failed to kill process with PID $el_pid"
  # use kill instead of pkill with prysm
  kill $cl_pid  2>/dev/null || echo "Failed to kill process with PID $cl_pid"

  [[ "$el_output" == *"Chain ID     : Mainnet"* ]]

  [[ "$cl_output" == *"Running on Ethereum Mainnet"* ]]
  [[ "$cl_output" == *"Starting initial chain sync"* ]]
}

@test "$network: nethermind-teku" {
  el_output_log=$(mktemp)
  cl_output_log=$(mktemp)

  rm -rf $HOME/.run-a-node

  bash run-a-client.sh --network "$network" --el nethermind &>"$el_output_log" &
  el_pid=$!
  bash run-a-client.sh --network "$network" --cl teku &>"$cl_output_log" &
  cl_pid=$!

  sleep 60

  cl_output=$(cat $cl_output_log)
  el_output=$(cat $el_output_log)

  kill $el_pid  2>/dev/null || echo "Failed to kill process with PID $el_pid"
  # pkill does not work with teku
  kill $cl_pid  2>/dev/null || echo "Failed to kill process with PID $cl_pid"

  [[ "$el_output" == *"Chain ID     : Mainnet"* ]]

  [[ "$cl_output" == *"Network: mainnet"* ]]
  [[ "$cl_output" == *"Syncing started"* ]]
  # [[ "$cl_output" == *"Execution Client is online"* ]]
}

# reth 
@test "$network: reth-lighthouse" {
  el_output_log=$(mktemp)
  cl_output_log=$(mktemp)

  rm -rf $HOME/.run-a-node

  bash run-a-client.sh --network "$network" --el reth &>"$el_output_log" &
  el_pid=$!
  bash run-a-client.sh --network "$network" --cl lighthouse &>"$cl_output_log" &
  cl_pid=$!

  sleep "$wait_time"

  cl_output=$(cat $cl_output_log)
  el_output=$(cat $el_output_log)

  kill $el_pid  2>/dev/null || echo "Failed to kill process with PID $el_pid"
  # use kill instead of pkill with lighthouse
  kill $cl_pid  2>/dev/null || echo "Failed to kill process with PID $cl_pid"

  # TODO not sure how to check if it is mainnet
  [[ "$el_output" == *"Consensus engine initialized"* ]]

  [[ "$cl_output" == *"Configured for network                  name: mainnet"* ]]
  [[ "$cl_output" == *"Starting checkpoint sync"* ]]

}

@test "$network: reth-lodestar" {
  el_output_log=$(mktemp)
  cl_output_log=$(mktemp)

  rm -rf $HOME/.run-a-node

  bash run-a-client.sh --network "$network" --el reth &>"$el_output_log" &
  el_pid=$!
  bash run-a-client.sh --network "$network" --cl lodestar &>"$cl_output_log" &
  cl_pid=$!

  sleep "$wait_time"

  cl_output=$(cat $cl_output_log)
  el_output=$(cat $el_output_log)

  kill $el_pid  2>/dev/null || echo "Failed to kill process with PID $el_pid"
  pkill -9 -P $cl_pid  2>/dev/null || echo "Failed to kill process with PID $cl_pid"

  # TODO not sure how to check if it is mainnet
  [[ "$el_output" == *"Consensus engine initialized"* ]]

  [[ "$cl_output" == *"Lodestar network=mainnet"* ]]
  [[ "$cl_output" == *"Fetching checkpoint state"* ]]
}

@test "$network: reth-nimbus-eth2" {
  el_output_log=$(mktemp)
  cl_output_log=$(mktemp)

  rm -rf $HOME/.run-a-node

  bash run-a-client.sh --network "$network" --el reth &>"$el_output_log" &
  el_pid=$!
  bash run-a-client.sh --network "$network" --cl nimbus-eth2 &>"$cl_output_log" &
  cl_pid=$!

  sleep "$wait_time"

  cl_output=$(cat $cl_output_log)
  el_output=$(cat $el_output_log)

  kill $el_pid  2>/dev/null || echo "Failed to kill process with PID $el_pid"
  # use kill instead of pkill with nimbus-eth2
  kill $cl_pid  2>/dev/null || echo "Failed to kill process with PID $cl_pid"

  # TODO not sure how to check if it is mainnet
  [[ "$el_output" == *"Consensus engine initialized"* ]]

  [[ "$cl_output" == *"const_preset=mainnet"* ]]
  [[ "$cl_output" == *"Starting beacon node"* ]]
}

@test "$network: reth-prysm" {
  el_output_log=$(mktemp)
  cl_output_log=$(mktemp)

  rm -rf $HOME/.run-a-node

  bash run-a-client.sh --network "$network" --el reth &>"$el_output_log" &
  el_pid=$!
  bash run-a-client.sh --network "$network" --cl prysm &>"$cl_output_log" &
  cl_pid=$!

  sleep 40 # prysm initial sync is slower

  cl_output=$(cat $cl_output_log)
  el_output=$(cat $el_output_log)

  kill $el_pid  2>/dev/null || echo "Failed to kill process with PID $el_pid"
  # use kill instead of pkill with prysm
  kill $cl_pid  2>/dev/null || echo "Failed to kill process with PID $cl_pid"

  # TODO not sure how to check if it is mainnet
  [[ "$el_output" == *"Consensus engine initialized"* ]]

  [[ "$cl_output" == *"Running on Ethereum Mainnet"* ]]
  [[ "$cl_output" == *"Starting initial chain sync"* ]]
}

@test "$network: reth-teku" {
  el_output_log=$(mktemp)
  cl_output_log=$(mktemp)

  rm -rf $HOME/.run-a-node

  bash run-a-client.sh --network "$network" --el reth &>"$el_output_log" &
  el_pid=$!
  bash run-a-client.sh --network "$network" --cl teku &>"$cl_output_log" &
  cl_pid=$!

  sleep 60

  cl_output=$(cat $cl_output_log)
  el_output=$(cat $el_output_log)

  kill $el_pid  2>/dev/null || echo "Failed to kill process with PID $el_pid"
  # pkill does not work with teku
  kill $cl_pid  2>/dev/null || echo "Failed to kill process with PID $cl_pid"

  # TODO not sure how to check if it is mainnet
  [[ "$el_output" == *"Consensus engine initialized"* ]]

  [[ "$cl_output" == *"Network: mainnet"* ]]
  [[ "$cl_output" == *"Syncing started"* ]]
  # [[ "$cl_output" == *"Execution Client is online"* ]]
}
