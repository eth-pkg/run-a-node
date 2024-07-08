#!/usr/bin/env bats

set -euo pipefail

chmod +x run-a-client.sh

load test_helper.bash

network=ephemery
wait_time=10
el_pid=
cl_pid=

cleanup() {
  echo "Cleaning up background processes and logs..."
  [ -n "$el_pid" ] && kill "$el_pid" || true
  [ -n "$cl_pid" ] && kill "$cl_pid" || true
}

trap cleanup EXIT INT SIGINT SIGTERM


# In theory it could be run through for loop, but then filter won't work with bats
# we need filter on CI and locally to only run client specific tests

## Besu tests
@test "$network: besu-lighthouse" {
  local el_name="besu"
  local cl_name="lighthouse"

  run_test "$network" "$el_name" "$cl_name" "$wait_time"
}

@test "$network: besu-lodestar" {
  local el_name="besu"
  local cl_name="lodestar"

  run_test "$network" "$el_name" "$cl_name" "$wait_time"
}

@test "$network: besu-nimbus-eth2" {
  local el_name="besu"
  local cl_name="nimbus-eth2"

  run_test "$network" "$el_name" "$cl_name" "$wait_time"
}

@test "$network: besu-prysm" {
  local el_name="besu"
  local cl_name="prysm"

  run_test "$network" "$el_name" "$cl_name" 40
}

@test "$network: besu-teku" {
  local el_name="besu"
  local cl_name="teku"

  run_test "$network" "$el_name" "$cl_name" 90
}

# erigon tests
@test "$network: erigon-lighthouse" {
  local el_name="erigon"
  local cl_name="lighthouse"

  run_test "$network" "$el_name" "$cl_name" "$wait_time"
}

@test "$network: erigon-lodestar" {
  local el_name="erigon"
  local cl_name="lodestar"

  run_test "$network" "$el_name" "$cl_name" "$wait_time"
}

@test "$network: erigon-nimbus-eth2" {
  local el_name="erigon"
  local cl_name="nimbus-eth2"

  run_test "$network" "$el_name" "$cl_name" "$wait_time"
}

@test "$network: erigon-prysm" {
  local el_name="erigon"
  local cl_name="prysm"

  run_test "$network" "$el_name" "$cl_name" 40
}

@test "$network: erigon-teku" {
  local el_name="erigon"
  local cl_name="teku"

  run_test "$network" "$el_name" "$cl_name" 90
}

## geth
@test "$network: geth-lighthouse" {
  local el_name="geth"
  local cl_name="lighthouse"

  run_test "$network" "$el_name" "$cl_name" "$wait_time"
}

@test "$network: geth-lodestar" {
  local el_name="geth"
  local cl_name="lodestar"

  run_test "$network" "$el_name" "$cl_name" "$wait_time"
}

@test "$network: geth-nimbus-eth2" {
  local el_name="geth"
  local cl_name="nimbus-eth2"

  run_test "$network" "$el_name" "$cl_name" "$wait_time"
}

@test "$network: geth-prysm" {
  local el_name="geth"
  local cl_name="prysm"

  run_test "$network" "$el_name" "$cl_name" 40
}

@test "$network: geth-teku" {
  local el_name="geth"
  local cl_name="teku"

  run_test "$network" "$el_name" "$cl_name" 90
}

## nethermind
@test "$network: nethermind-lighthouse" {
  local el_name="nethermind"
  local cl_name="lighthouse"

  run_test "$network" "$el_name" "$cl_name" 20
}

@test "$network: nethermind-lodestar" {
  local el_name="nethermind"
  local cl_name="lodestar"

  run_test "$network" "$el_name" "$cl_name" 20
}

@test "$network: nethermind-nimbus-eth2" {
  local el_name="nethermind"
  local cl_name="nimbus-eth2"

  run_test "$network" "$el_name" "$cl_name" 20
}

@test "$network: nethermind-prysm" {
  local el_name="nethermind"
  local cl_name="prysm"

  run_test "$network" "$el_name" "$cl_name" 40
}

@test "$network: nethermind-teku" {
  local el_name="nethermind"
  local cl_name="teku"

  run_test "$network" "$el_name" "$cl_name" 60
}

## reth
@test "$network: reth-lighthouse" {
  local el_name="reth"
  local cl_name="lighthouse"

  run_test "$network" "$el_name" "$cl_name" "$wait_time"
}

@test "$network: reth-lodestar" {
  local el_name="reth"
  local cl_name="lodestar"

  run_test "$network" "$el_name" "$cl_name" "$wait_time"
}

@test "$network: reth-nimbus-eth2" {
  local el_name="reth"
  local cl_name="nimbus-eth2"

  run_test "$network" "$el_name" "$cl_name" "$wait_time"
}

@test "$network: reth-prysm" {
  local el_name="reth"
  local cl_name="prysm"

  run_test "$network" "$el_name" "$cl_name" 40
}

@test "$network: reth-teku" {
  local el_name="reth"
  local cl_name="teku"

  run_test "$network" "$el_name" "$cl_name" 90
}
