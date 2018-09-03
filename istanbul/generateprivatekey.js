const keythereum = require("keythereum")
const fs = require("fs")

const commandLineArgs = process.argv.slice(2)
const nodeDir = commandLineArgs[0]
const address = commandLineArgs[1]
const passwordFilePath = commandLineArgs[2]
const password = fs.readFileSync(passwordFilePath, 'utf8').trim()

let key = keythereum.importFromFile(address, nodeDir)
console.log(password)
console.log(typeof password)
var buffer = keythereum.recover(password, key)
fs.writeFileSync(nodeDir + "/node.key", buffer.toString('hex'))
