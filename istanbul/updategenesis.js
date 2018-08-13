const fs = require('fs')
const commandLineArgs = process.argv.slice(2)
const networkDir = commandLineArgs[0]
const genesisFilePath = networkDir + "/genesis.json"
const newExtraDataFilePath = networkDir + "/newextradata.txt"
const newChainId = parseInt(commandLineArgs[1])
const consensusAlgorithm = commandLineArgs[2]
const addresses = commandLineArgs.slice(3)

let genesis = {
    "config": {
        "homesteadBlock": 1,
        "eip150Block": 2,
        "eip150Hash": "0x0000000000000000000000000000000000000000000000000000000000000000",
        "eip155Block": 3,
        "eip158Block": 3,
    },
    "nonce": "0x0",
    "timestamp": "0x0",
    "gasLimit": "0x47b760",
    "difficulty": "0x1",
    "coinbase": "0x0000000000000000000000000000000000000000",
    "number": "0x0",
    "gasUsed": "0x0",
    "parentHash": "0x0000000000000000000000000000000000000000000000000000000000000000"
}

let startingBalance = "0x200000000000000000000000000000000000000000000000000000000000000"
genesis.alloc = {}
for (var i = 0 ; i < addresses.length; i++) {
    genesis.alloc[addresses[i]] = {"balance" : startingBalance}
}
genesis.config.chainId = newChainId

if (consensusAlgorithm == "istanbul") {
    genesis.config["istanbul"] = {
        "epoch": 30000,
        "policy": 0
    }
    genesis["mixHash"] = "0x63746963616c2062797a616e74696e65206661756c7420746f6c6572616e6365"
    genesis.extraData = fs.readFileSync(newExtraDataFilePath, 'utf8')
    
} else if (consensusAlgorithm == "clique") {
    genesis.config["clique"] = {
        "period": 15,
        "epoch": 30000
    }
    genesis.config["byzantiumBlock"] = 4
    genesis["mixHash"] = "0x0000000000000000000000000000000000000000000000000000000000000000"
    genesis.extraData = 
    "0x0000000000000000000000000000000000000000000000000000000000000000" + 
    addresses.join('') + 
    "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
}

fs.writeFileSync(genesisFilePath, JSON.stringify(genesis, null, 4))