#!/bin/bash

set -e 

LOGS_DIR=~/run-node/$network/$execution_client-$consensus_client
mkdir -p $LOGS_DIR
PID_FILE="$LOGS_DIR/process.txt"

kill_previous_processes() {
  if [[ -f "$PID_FILE" ]]; then
    while IFS= read -r pid; do
      if [[ ! -z "$pid" ]]; then
        kill -9 "$pid" 2>/dev/null
      fi
    done < "$PID_FILE"
    rm -f "$PID_FILE"
  fi
}

usage() {
  echo "Usage: $0 --network <network> --consensus-client <consensus_client> --execution-client <execution_client> --with-validator"
  exit 1
}

network=
consensus_client=
execution_client=
with_validator=
## TODO not implemented 
with_monitoring=

while [[ "$#" -gt 0 ]]; do
  case $1 in
    --network) network="$2"; shift ;;
    --consensus-client) consensus_client="$2"; shift ;;
    --execution-client) execution_client="$2"; shift ;;
    --with-validator) with_validator=true; shift ;;
    *) echo "Unknown parameter passed: $1"; usage ;;
  esac
  shift
done

if [[ -z "$network" || -z "$consensus_client" || -z "$execution_client" ]]; then
  echo "Error: Missing required parameters."
  usage
fi

OP_ARGS=

if [ -z "$with_validator" ]; then
    OP_ARGS="$OP_ARGS --with-validator"
fi 

kill_previous_processes

chmod +x run-a-client.sh

# Run execution client
nohup run-a-client.sh --network "$network" --consensus-client "$consensus_client" --execution-client "$execution_client" --run execution $OP_ARGS > $LOGS_DIR/execution.log 2>&1 &
EL_CLIENT_PID=$!
echo "Execution client started with PID $EL_CLIENT_PID"
echo "$EL_CLIENT_PID" >> "$PID_FILE"

# Run consensus client
nohup run-a-client.sh --network "$network" --consensus-client "$consensus_client" --execution-client "$execution_client" --run consensus $OP_ARGS > $LOGS_DIR/consensus.log 2>&1 &
CL_CLIENT_PID=$!
echo "Consensus client started with PID $CL_CLIENT_PID"
echo "$CL_CLIENT_PID" >> "$PID_FILE"

# Run the client with validator if specified
if [ "$with_validator" == "true" ]; then 
    nohup run-a-client.sh --network "$network" --consensus-client "$consensus_client" --execution-client "$execution_client" --run validator $OP_ARGS > $LOGS_DIR/validator.log 2>&1 &
    VALIDATOR_CLIENT_PID=$!
    echo "validator client started with PID $VALIDATOR_CLIENT_PID"
    echo "$VALIDATOR_CLIENT_PID" >> "$PID_FILE"
fi

sleep 1 

echo "To kill the started process run:"
echo "kill -p $EL_CLIENT_PID"
echo "kill -p $CL_CLIENT_PID"

if [ "$with_validator" == "true" ]; then 
    echo "kill -f $VALIDATOR_CLIENT_PID"
fi     
