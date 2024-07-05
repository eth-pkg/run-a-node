# run-a-client
Ethereum client scripts to run clients, but with standardized options

NOTE: This repository is in active development. Code can change drasticially,
and except bugs. 

## Running a node 

Open two terminals and execute the following commands:

Terminal 1:
```bash 
bash run-a-client.sh --network <network> \
                   --consensus-client <consensus_client> \
                   --execution-client <execution_client> \
                   --run execution 
```

Terminal 2:
```bash
bash run-a-client.sh --network <network> \
                   --consensus-client <consensus_client> \
                   --execution-client <execution_client> \
                   --run consensus 
```

## Running with simplified approach

This will run a node with selected network and clients. Note this is intended as examples. 

```
bash run-a-node.sh --network <network> \
                   --consensus-client <consensus_client> \
                   --execution-client <execution_client>
```


For running a node on:
- Mainnet, see [mainnet.md](mainnet.md)
- Sepolia, see [sepolia.md](sepolia.md)
- Holesky, see [holesky.md](holesky.md)
- Ephemery, see [ephemery.md](ephemery.md)
- Local minimum testnet, see [local-only-testnet.md](local-only-testnet.md)
