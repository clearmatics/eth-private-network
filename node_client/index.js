// Copyright (c) 2016-2018 Clearmatics Technologies Ltd
// SPDX-License-Identifier: LGPL-3.0+

var rpc = require('node-json-rpc');

var nodeOne = {
  port: 8548,
  host: 'localhost',
  path: '/',
  strict: true
};

var nodeTwo = {
  port: 8549,
  host: 'localhost',
  path: '/',
  strict: true
};

var clientNodeOne = new rpc.Client(nodeOne);
var clientNodeTwo = new rpc.Client(nodeTwo);

setInterval(()=> {
  // Get the coinbase on node 1
  clientNodeOne.call({"jsonrpc": "2.0", "method": "eth_coinbase", "params": [], "id": 0},
    function(err, res) {
      if (err) {
        console.log(err);
      }
      console.log("'NODE ONE' coinbase: " + res.result)
    })

  // Get the blockNumber on node 1
  clientNodeOne.call({"jsonrpc": "2.0", "method": "eth_blockNumber", "params": [], "id": 1},
    function(err, res) {
      if (err) {
        console.log(err);
      }
      console.log("'NODE ONE' block number: " + parseInt(res.result, 16))
    })

  // Get the coinbase on node 2
  clientNodeTwo.call({"jsonrpc": "2.0", "method": "eth_coinbase", "params": [], "id": 2},
    function(err, res) {
      if (err) {
        console.log(err);
      }
      console.log("'NODE TWO' coinbase: " + res.result)
    })

  // Get the blockNumber on node 2
  clientNodeTwo.call({"jsonrpc": "2.0", "method": "eth_blockNumber", "params": [], "id": 3},
    function(err, res) {
      if (err) {
        console.log(err);
      }
      console.log("'NODE TWO' block number: " + parseInt(res.result, 16))
    })
}, 5000)
