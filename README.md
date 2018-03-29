# Setup and run an Ethereum Private Network

## Content

* `eth_common/` - genesis.json file, setup new coinbase (base account), password file.
* `Dockerfile-gethlatest` - Image of ethereum node container using the latest stable version of geth.
* `Dockerfile-geth1.7.3` - Image of ethereum node container using the version 1.7.3 of geth (Can easily be modified to support another specific version of geth).
* `node_client/` - JSON-RPC client writen in NodeJS.

## Start a private network

1. The docker-compose file starts 2 nodes (default) on the `privtnet` docker network.
```
$ docker network create privtnet
$ docker-compose up -d
```
2. The two nodes are launched in a dedicated docker network, _BUT_ they need to see each other as peer nodes in the ethereum network.
Thus, we need to add them as peers (manually):
  * To get a mapping container=IPAddress, run:
  ```bash
    docker network inspect privtnet --format='{{range .Containers}}{{.Name}}={{.IPv4Address}}  ||  {{end}}'
  ```
  * Attach to each container, by running `docker attach [containerID]`
  * Start the node and get access to the geth console by running `./startNode.sh`
  * On each node, run `admin.nodeInfo.enode` in the geth console.
  * In the geth console of node1, declare a variable `enode`, which value is equal to the result of `admin.nodeInfo.enode` of the node2, and *REPLACE* the `[::]` part by the IP of the docker container running node2 (see in `docker network inspect privtnet`). Do the same thing with node2.
  * Add the node as peer to the other node, by running `admin.addPeer(enode)` in each console.
  * List the peers on each node, by running: `admin.peers` in the geth console.
  * At that point, both nodes should see each other as peers. 
3. Run the commands:
`eth.hashrate` and `eth.blockNumber` (If both outputs are 0, then wait for a few seconds/minutes). Both outputs should be quite close from each other.

## Play with the nodes

1. Check the balance of the different accounts from your geth console:
```javascript
function checkBalances() {
    var totalBalance = 0;
    for (var accountNb in eth.accounts) {
        var account = eth.accounts[accountNb];
        var accountBalance = web3.fromWei(eth.getBalance(account), "ether");
        totalBalance += parseFloat(accountBalance);
        console.log("eth.accounts[" + accountNb + "]: \t" + account + " \t balance: " + accountBalance + " ether");
    }
    console.log("Total balance: " + totalBalance + " ether");
};
```
Inlined function to copy and paste directly in your console:
```javascript
function checkBalances(){var e=0;for(var a in eth.accounts){var t=eth.accounts[a],c=web3.fromWei(eth.getBalance(t),"ether");e+=parseFloat(c),console.log("eth.accounts["+a+"]: \t"+t+" \t balance: "+c+" ether")}console.log("Total balance: "+e+" ether")}
```
2. Launch the node client to get the latest blocks. (_Note:_ This has to be launched from another terminal on the host machine for instance):
```bash
cd node_client && node index.js
```
3. Inspect some blocks from one of the node:
```bash
eth.getBlock([blockNumber])
```
4. Do some transactions between one account to another:
  * Create a second account on your node: `personal.newAccount('[youPassword]')`
  * Verify that your account has been created properly. The command `eth.accounts` should output 2 accounts.
  * Send some ether from `eth.account[0]` to `eth.account[1]`. To do so, you need to:
   - Unlock the account you want to send the ethers from: Run `personal.unlockAccount(eth.accounts[0])`, and enter your passphrase.
   - Perform the transaction: set the amount `var amount = web3.toWei(0.01, "ether")`, and run `eth.sendTransaction({from:eth.accounts[0], to:eth.accounts[1], value: amount})`
5. Once your transaction is made, you can inspect it, by running `eth.getTransaction("[hashOfTheTX]")`, where `hashOfTheTX` is the hash that has been printed on the Geth console when you submitted your transaction at step 4.
6. Next steps: Play around and make you familiar with geth (Inspect the blocks, inspect the TX and so on...)

## Use Curl to interact with your nodes

The template is:
```bash
$ curl -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"[method to call]","params":[listOfParameters], "id": 1}' http://[yourNodeURL]:[yourNodePort]

```

Here is an example requesting the rpc modules via curl.
```bash
$ curl -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"rpc/_modules","params":[], "id": 1}' http://localhost:8549

```

See: http://www.jsonrpc.org/specification and https://github.com/ethereum/wiki/wiki/JSON-RPC for more details.

### Sources

- https://gist.github.com/fishbullet/04fcc4f7af90ee9fa6f9de0b0aa325ab
- https://github.com/ethereum/go-ethereum/wiki/Managing-your-accounts
- https://media.consensys.net/how-to-build-a-private-ethereum-blockchain-fbf3904f337
