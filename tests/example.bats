#!/usr/bin/env bats

# Define the test parameters
networks=("mainnet" "ropsten" "rinkeby")
clients=("erigon" "besu")
consensus_clients=("teku" "prysm")

# Define sleep times for each client combination
declare -A sleep_times
sleep_times["erigon_teku"]=60
sleep_times["erigon_prysm"]=50
sleep_times["besu_teku"]=40
sleep_times["besu_prysm"]=30

# Define expected messages for each client
declare -A el_messages
el_messages["erigon"]="Initialising Ethereum protocol network=1"
el_messages["besu"]="Starting Besu"

declare -A cl_messages
cl_messages["teku"]="Syncing started"
cl_messages["prysm"]="Execution Client is online"

# Helper function to run the test
run_test() {
  local network=$1
  local el_client=$2
  local cl_client=$3
  local sleep_time=$4

  el_output_log=$(mktemp)
  cl_output_log=$(mktemp)

  rm -rf $HOME/.run-a-node

  bash run-a-client.sh --network "$network" --el "$el_client" &>"$el_output_log" &
  el_pid=$!
  bash run-a-client.sh --network "$network" --cl "$cl_client" &>"$cl_output_log" &
  cl_pid=$!

  sleep "$sleep_time"

  cl_output=$(cat $cl_output_log)
  el_output=$(cat $el_output_log)

  kill $el_pid 2>/dev/null || echo "Failed to kill process with PID $el_pid"
  kill $cl_pid 2>/dev/null || echo "Failed to kill process with PID $cl_pid"

  # Check the output against the expected messages
  [[ "$el_output" == *"${el_messages[$el_client]}"* ]] || echo "EL output check failed for $el_client"
  [[ "$cl_output" == *"${cl_messages[$cl_client]}"* ]] || echo "CL output check failed for $cl_client"

  rm -f "$el_output_log" "$cl_output_log"
}

for el_client in "${clients[@]}"; do
  for cl_client in "${consensus_clients[@]}"; do
    sleep_time="${sleep_times[${el_client}_${cl_client}]}"
    eval "
        @test \"mainnet: $el_client-$cl_client, sleep=$sleep_time\" {
          run_test \"mainnet\" \"$el_client\" \"$cl_client\" \"$sleep_time\"
        }
      "
  done
done
