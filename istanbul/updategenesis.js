const fs = require('fs')

const commandLineArgs = process.argv.slice(2)
const genesisFilePath = commandLineArgs[0]
const newExtraDataFilePath = commandLineArgs[1]
const addresses = commandLineArgs.slice(2)

let rawGenesis = fs.readFileSync(genesisFilePath)
let genesis = JSON.parse(rawGenesis)

let newExtraData = fs.readFileSync(newExtraDataFilePath, 'utf8')

// Update genesis.extraData
genesis.extraData = newExtraData

let startingBalance = genesis.alloc[Object.keys(genesis.alloc)[0]].balance

genesis.alloc = {}

for (var i = 0 ; i < addresses.length; i++) {
    genesis.alloc[addresses[i]] = {"balance" : startingBalance}
}

fs.writeFileSync(genesisFilePath, JSON.stringify(genesis, null, 4))

