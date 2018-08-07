const fs = require('fs')
const commandLineArgs = process.argv.slice(2)
const genesisFilePath = commandLineArgs[0]
const newExtraDataFilePath = commandLineArgs[1]
const newChainId = parseInt(commandLineArgs[2])
const addresses = commandLineArgs.slice(3)

let genesis = {
    "config": {
        "homesteadBlock": 1,
        "eip150Block": 2,
        "eip150Hash": "0x0000000000000000000000000000000000000000000000000000000000000000",
        "eip155Block": 3,
        "eip158Block": 3,
        "istanbul": {
            "epoch": 30000,
            "policy": 0
        }
    },
    "nonce": "0x0",
    "timestamp": "0x0",
    "gasLimit": "0x47b760",
    "difficulty": "0x1",
    "mixHash": "0x63746963616c2062797a616e74696e65206661756c7420746f6c6572616e6365",
    "coinbase": "0x0000000000000000000000000000000000000000",
    "number": "0x0",
    "gasUsed": "0x0",
    "parentHash": "0x0000000000000000000000000000000000000000000000000000000000000000"
}

let newExtraData = fs.readFileSync(newExtraDataFilePath, 'utf8')
let startingBalance = "0x446c3b15f9926687d2c40534fdb564000000000000"

// Update genesis.extraData
genesis.extraData = newExtraData
genesis.alloc = {}
for (var i = 0 ; i < addresses.length; i++) {
    genesis.alloc[addresses[i]] = {"balance" : startingBalance}
}
genesis.config.chainId = newChainId

fs.writeFileSync(genesisFilePath, JSON.stringify(genesis, null, 4))
