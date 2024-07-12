#!/usr/bin/env bats

set -euo pipefail

chmod +x run-a-client.sh

load helper/test_helper.bash

network=mainnet
# wait time until cl endpoints are running (with slower internet)
lighthouse_wait_time=180 #requires initial checkpoint sync
lodestar_wait_time=180   # requires initial checkpoint sync
nimbus_eth2_wait_time=20 # starts before initial checkpoint sync
prysm_wait_time=60      # had to increase time as the el_offline takes time
teku_wait_time=60

besu_wait_time=420 # for sync status, but besu api starts in 10s
erigon_wait_time=420 # yup, it is downloading snapshots on mainnet, which is very slow ...
geth_wait_time=420
nethermind_wait_time=420
reth_wait_time=420

cleanup() {
  helper_cleanup
}

trap cleanup EXIT INT SIGINT SIGTERM

get_wait_time() {
  if [ "$1" -gt "$2" ]; then
    echo $1
  else
    echo $2
  fi
}

# In theory it could be run through for loop, but then filter won't work with bats
# we need filter on CI and locally to only run client specific tests

## Besu tests
@test "$network: besu-lighthouse" {
  local el_name="besu"
  local cl_name="lighthouse"
  local wait_time=$(get_wait_time $besu_wait_time $lighthouse_wait_time)

  run_test "$network" "$el_name" "$cl_name" "$wait_time"
}

@test "$network: besu-lodestar" {
  local el_name="besu"
  local cl_name="lodestar"
  local wait_time=$(get_wait_time $besu_wait_time $lodestar_wait_time)

  run_test "$network" "$el_name" "$cl_name" "$wait_time"
}

@test "$network: besu-nimbus-eth2" {
  local el_name="besu"
  local cl_name="nimbus-eth2"
  local wait_time=$(get_wait_time $besu_wait_time $nimbus_eth2_wait_time)

  run_test "$network" "$el_name" "$cl_name" "$wait_time"
}

@test "$network: besu-prysm" {
  local el_name="besu"
  local cl_name="prysm"
  local wait_time=$(get_wait_time $besu_wait_time $prysm_wait_time)

  run_test "$network" "$el_name" "$cl_name" "$wait_time"
}

@test "$network: besu-teku" {
  local el_name="besu"
  local cl_name="teku"
  local wait_time=$(get_wait_time $besu_wait_time $teku_wait_time)

  run_test "$network" "$el_name" "$cl_name" "$wait_time"
}

# erigon tests
@test "$network: erigon-lighthouse" {
  local el_name="erigon"
  local cl_name="lighthouse"

  local wait_time=$(get_wait_time $erigon_wait_time $lighthouse_wait_time)

  run_test "$network" "$el_name" "$cl_name" "$wait_time"
}

@test "$network: erigon-lodestar" {
  local el_name="erigon"
  local cl_name="lodestar"

  local wait_time=$(get_wait_time $erigon_wait_time $lodestar_wait_time)

  run_test "$network" "$el_name" "$cl_name" "$wait_time"
}

@test "$network: erigon-nimbus-eth2" {
  local el_name="erigon"
  local cl_name="nimbus-eth2"

  local wait_time=$(get_wait_time $besu_wait_time $nimbus_eth2_wait_time)

  run_test "$network" "$el_name" "$cl_name" "$wait_time"
}

# TODO failing
@test "$network: erigon-prysm" {
  local el_name="erigon"
  local cl_name="prysm"

  local wait_time=$(get_wait_time $erigon_wait_time $prysm_wait_time)

  run_test "$network" "$el_name" "$cl_name" "$wait_time"
}
# TODO failing
@test "$network: erigon-teku" {
  local el_name="erigon"
  local cl_name="teku"

  local wait_time=$(get_wait_time $erigon_wait_time $teku_wait_time)

  run_test "$network" "$el_name" "$cl_name" "$wait_time"
}

## geth
@test "$network: geth-lighthouse" {
  local el_name="geth"
  local cl_name="lighthouse"

  local wait_time=$(get_wait_time $geth_wait_time $lighthouse_wait_time)

  run_test "$network" "$el_name" "$cl_name" "$wait_time"
}

@test "$network: geth-lodestar" {
  local el_name="geth"
  local cl_name="lodestar"

  local wait_time=$(get_wait_time $geth_wait_time $lodestar_wait_time)

  run_test "$network" "$el_name" "$cl_name" "$wait_time"
}

@test "$network: geth-nimbus-eth2" {
  local el_name="geth"
  local cl_name="nimbus-eth2"

  local wait_time=$(get_wait_time $geth_wait_time $nimbus_eth2_wait_time)

  run_test "$network" "$el_name" "$cl_name" "$wait_time"
}

@test "$network: geth-prysm" {
  local el_name="geth"
  local cl_name="prysm"

  local wait_time=$(get_wait_time $geth_wait_time $prysm_wait_time)

  run_test "$network" "$el_name" "$cl_name" "$wait_time"
}

@test "$network: geth-teku" {
  local el_name="geth"
  local cl_name="teku"

  local wait_time=$(get_wait_time $geth_wait_time $teku_wait_time)

  run_test "$network" "$el_name" "$cl_name" "$wait_time"
}

## nethermind
@test "$network: nethermind-lighthouse" {
  local el_name="nethermind"
  local cl_name="lighthouse"

  local wait_time=$(get_wait_time $nethermind_wait_time $lighthouse_wait_time)

  run_test "$network" "$el_name" "$cl_name" "$wait_time"
}

@test "$network: nethermind-lodestar" {
  local el_name="nethermind"
  local cl_name="lodestar"

  local wait_time=$(get_wait_time $nethermind_wait_time $lodestar_wait_time)

  run_test "$network" "$el_name" "$cl_name" "$wait_time"
}

@test "$network: nethermind-nimbus-eth2" {
  local el_name="nethermind"
  local cl_name="nimbus-eth2"

  local wait_time=$(get_wait_time $nethermind_wait_time $nimbus_eth2_wait_time)

  run_test "$network" "$el_name" "$cl_name" "$wait_time"
}

@test "$network: nethermind-prysm" {
  local el_name="nethermind"
  local cl_name="prysm"

  local wait_time=$(get_wait_time $nethermind_wait_time $prysm_wait_time)

  run_test "$network" "$el_name" "$cl_name" "$wait_time"
}

@test "$network: nethermind-teku" {
  local el_name="nethermind"
  local cl_name="teku"

  local wait_time=$(get_wait_time $nethermind_wait_time $teku_wait_time)

  run_test "$network" "$el_name" "$cl_name" "$wait_time"
}

## reth
@test "$network: reth-lighthouse" {
  local el_name="reth"
  local cl_name="lighthouse"

  local wait_time=$(get_wait_time $reth_wait_time $lighthouse_wait_time)

  run_test "$network" "$el_name" "$cl_name" "$wait_time"
}

@test "$network: reth-lodestar" {
  local el_name="reth"
  local cl_name="lodestar"

  local wait_time=$(get_wait_time $reth_wait_time $lodestar_wait_time)

  run_test "$network" "$el_name" "$cl_name" "$wait_time"
}

@test "$network: reth-nimbus-eth2" {
  local el_name="reth"
  local cl_name="nimbus-eth2"

  local wait_time=$(get_wait_time $reth_wait_time $nimbus_eth2_wait_time)

  run_test "$network" "$el_name" "$cl_name" "$wait_time"
}

@test "$network: reth-prysm" {
  local el_name="reth"
  local cl_name="prysm"

  local wait_time=$(get_wait_time $reth_wait_time $prysm_wait_time)

  run_test "$network" "$el_name" "$cl_name" "$wait_time"
}

@test "$network: reth-teku" {
  local el_name="reth"
  local cl_name="teku"

  local wait_time=$(get_wait_time $reth_wait_time $teku_wait_time)

  run_test "$network" "$el_name" "$cl_name" "$wait_time"
}
