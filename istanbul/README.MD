The scripts can create a clique or Istanbul private network which is launched using tmux.

# Pre-requsites
## [NodeJS](https://nodejs.org/en/download/) and [Geth (Istanbul version)](https://github.com/getamis/go-ethereum)

# Instructions

Install the required packages by:
```
npm install
```
Clone [Instabul](https://github.com/getamis/go-ethereum) and build geth by:
```
cd path/to/istanbul/
make geth
```

## New Istanbul (IBFT) network:
```
./poaoribftnetwork.sh path/to/istanbul/build/bin/geth [number of nodes] istanbul
```

This will create a `poaoribftnetwork` directory in the current directory as well as launching a tmux session called `poaoribft_network`, you can attach to it by:
```
tmux attach -s poaoribft_network
```

The tmux session has multiple windows one for each node and one for a boot node. The poaoribftnetwork directory for a 2 node private network will look like the following:

```
poaoribftnetwork
|-- boot.key
|-- config.toml
|-- genesis.json
|-- newextradata.txt
|-- node1
|   |-- geth
|   |-- geth.ipc
|   |-- keystore
|   `-- node.key
|-- node2
|   |-- geth
|   |-- geth.ipc
|   |-- keystore
|   `-- node.key
`-- passwd.txt

```

## New Clique (PoA) network:

```
./poaoribftnetwork.sh path/to/istanbul/build/bin/geth [number of nodes] clique
```

## Launch an existing Istanbul or Clique

Please ensure you are in the __parent__ directory of `poaoribftnetwork`, then run:
```
./poaoribftnetwork.sh path/to/istanbul/build/bin/geth
```

Because of the genesis file, the network will automatically run the correct consensus algorithm.