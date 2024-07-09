# run-a-node

This repository features two main components: the `run-a-node` top-level node running script and the `run-a-client` standardized script. The `run-a-client` script is designed to run each client uniformly, respecting each client's unique options while providing a minimal abstraction layer. This allows users to easily run clients without delving into detailed configurations until they are ready to modify specific config values.

Options are moved into configuration files, which are provided through CLI variables, ensuring a consistent format for each client. However, specific client configuration files can still be used if needed.

This repository is intended for those who want to set up a node but are confused by the myriad of options. It provides an easy way to see how everything works with minimal effort.

This repository was created as a result of the `eth-nodes` Debian packaging project, where standardizing options was necessary for easy management.

**NOTE:** This repository is under active development. The code can change drastically, and bugs should be expected.

## Running a Client Pair

Open two terminals and execute the following commands:

Terminal 1:
```bash 
bash run-a-client.sh --network <network> --cl <consensus_client>
```

Terminal 2:
```bash
bash run-a-client.sh --network <network> --el <execution_client>
```

## Running a client pair with one script

This will run a node with the selected network and clients. Note this is intended as an example.

```bash
bash run-a-node.sh --network <network> --cl <consensus_client> --el <execution_client>
```

## Available Options

The available options for both `run-a-client` and `run-a-node` scripts are:

- `<network>`: ephemery, holesky, mainnet, sepolia, testnet
- `<consensus_client>`: lighthouse, lodestar, nimbus-eth2, prsym, teku
- `<execution_client>`: besu, erigon, geth, nethermind, reth


## Running tests 


```bash
bats --show-output-of-passing-tests tests/test_<network>.bats
```

If you want to filter by client or client pair 

```bash
bats --show-output-of-passing-tests tests/test_<network>.bats --filter <client>
```

or by client pair 

```bash
bats --show-output-of-passing-tests tests/test_<network>.bats --filter <execution_client>-<consensus_client>
```