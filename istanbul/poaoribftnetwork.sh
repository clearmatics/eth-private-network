#!/bin/bash

# Define variables
ARGS_LENGTH=${#@}
STARTING_DIR=`dirname \`readlink -f $0\``
NETWORK_DIR="${STARTING_DIR}/poaoribftnetwork"
PASSWORD_PATH="${NETWORK_DIR}/passwd.txt"
GETH_BIN_PATH=$1
NUMBER_OF_NODES=$2
CONSENSUS_ALGO=$3
ISTANBUL_TOOLS_PATH="${GOPATH}/src/github.com/getamis/istanbul-tools"
ISTANBUL_TOOLS_GITHUB="https://github.com/getamis/istanbul-tools.git"
TMUX_SESSION_NAME="poaoribft_network"
BOOTNODE_PORT=4800
PORT=4800
RPC_PORT=9501
CHAINID=2017

# Create a common password file
createPasswd() {
    echo
    echo "---------Creating ${PASSWORD_PATH}---------"
    touch "${PASSWORD_PATH}"
    echo "istanbulnetwork" > "${PASSWORD_PATH}"
    echo "---------Finished creating ${PASSWORD_PATH}---------"
    echo
}

# Create a directory for the given path
createDir() {
    DIR="$1"
    if ! [ -d  "${DIR}" ]; then
        echo "---------Creating ${DIR}---------"
        mkdir -p "${DIR}"
        echo "---------Finished creating ${DIR}---------"
    fi
}

# Bye using Geth create the account in the given dir location
createAccounts() {
    echo "---------Creating Accounts---------"
    for i in `seq 1 "${NUMBER_OF_NODES}"`
    do
    echo
        if ! [ -d  ""${NETWORK_DIR}/node${i}"" ]; then
            mkdir -p ""${NETWORK_DIR}/node${i}""
        fi
        ${GETH_BIN_PATH} --datadir "${NETWORK_DIR}/node${i}" --password ${PASSWORD_PATH} account new
    echo
    done
    echo "---------Finished creating Accounts---------"
}

# Create toml file which has validator addresses in them
createToml() {
    VANITY="0x00"
    NODE_ADDRESSES=("$@")

    if [ -f "${NETWORK_DIR}/config.toml" ]; then
        rm "${NETWORK_DIR}/config.toml"
    fi

    echo "vanity = \"${VANITY}\"" >> "${NETWORK_DIR}/config.toml"

    count=1
    for i in ${NODE_ADDRESSES[@]}
    do
        if [ ${#NODE_ADDRESSES[@]} -eq "1" ]; then
            echo "validators = [\"0x${i}\"]" >> "${NETWORK_DIR}/config.toml"
        elif [ ${count} -eq "1" ]; then
            echo "validators = [\"0x${i}\"," >> "${NETWORK_DIR}/config.toml"
        elif [ ${count} -eq ${#NODE_ADDRESSES[@]} ]; then
            echo "${string}\"0x${i}\"]" >> "${NETWORK_DIR}/config.toml"
        else
            echo "${string}\"0x${i}\"," >> "${NETWORK_DIR}/config.toml"
        fi
        count=`expr ${count} + 1`
    done
}

# Create the genesis needed to initialise the nodes
createGenesis() {
    echo
    echo "---------Creating Genesis file---------"
    # Get the address from keystore and store them in an array
    ADDRESSES=()
    for i in `ls ${NETWORK_DIR} | grep node`
    do
        ADDRESSES+=(`ls ${NETWORK_DIR}/${i}/keystore | cut -d'-' -f9`)
    done

    if [ ${CONSENSUS_ALGO} = "istanbul" ]; then
        # Clone istanbul-tools
        if ! [ -d "${ISTANBUL_TOOLS_PATH}" ]; then
            git clone "${ISTANBUL_TOOLS_GITHUB}" "${ISTANBUL_TOOLS_PATH}"
        fi

        # Make istanbul-tools
        if ! [ -f "${ISTANBUL_TOOLS_PATH}/build/bin/istanbul" ]; then
            make -C ${ISTANBUL_TOOLS_PATH}
        fi

        # Create config.toml with the validators
        createToml ${ADDRESSES[@]}

        # Call istanbul extra encode and store in a file
        ${ISTANBUL_TOOLS_PATH}/build/bin/istanbul extra encode --config "${NETWORK_DIR}/config.toml" | cut -d':' -f2 | tr -d " \t\n\r" >  "${NETWORK_DIR}/newextradata.txt"
    fi

    # Update genesis file, the genesis.json and extra data's file location is passed in and the rest of the addresses are passed to assign some ether
    node "${STARTING_DIR}/updategenesis.js" ${NETWORK_DIR} ${CHAINID} ${CONSENSUS_ALGO} ${ADDRESSES[@]}
    echo "---------Finished creating Genesis file---------"
    echo
}

initialiseNodes() {
    echo
    echo "---------Initialising nodes with Genesis file---------"
    for i in `ls ${NETWORK_DIR} | grep node`
    do
    echo
        ${GETH_BIN_PATH} --datadir "${NETWORK_DIR}/${i}" init "${NETWORK_DIR}/genesis.json"
    echo
    done
    echo "---------Finished initialising nodes with Genesis file---------"
    echo
}


createBootNodeKey() {
    bootnode -genkey "${NETWORK_DIR}/boot.key"
}

launchBootNode() {
    tmux new -s ${TMUX_SESSION_NAME} -n "bootnode" -d
    tmux send-keys -t "${TMUX_SESSION_NAME}:bootnode" "bootnode -nodekey \"${NETWORK_DIR}/boot.key\" -verbosity 9 -addr :${BOOTNODE_PORT}" C-m
    PORT=`expr ${PORT} + 1`
}

launchNodes() {
    count=1
    for i in `ls ${NETWORK_DIR} | grep node`
    do
        tmux new-window -t ${TMUX_SESSION_NAME}:${count} -n ${i} 
        tmux send-keys -t ${TMUX_SESSION_NAME}:${count} "${GETH_BIN_PATH} --datadir "${NETWORK_DIR}/${i}" --syncmode 'full' --port ${PORT} --rpcport ${RPC_PORT} --rpc --rpcaddr '0.0.0.0' --rpccorsdomain '*' --rpcapi 'personal,db,eth,net,web3,txpool,miner,istanbul' --bootnodes 'enode://`bootnode -nodekey ${NETWORK_DIR}/boot.key -writeaddress`@127.0.0.1:${BOOTNODE_PORT}' --networkid ${CHAINID} --gasprice '0' -unlock \"0x`ls ${NETWORK_DIR}/${i}/keystore | cut -d'-' -f9`\" --password ${PASSWORD_PATH} --debug --mine --minerthreads '1' --etherbase \"0x`ls ${NETWORK_DIR}/${i}/keystore | cut -d'-' -f9`\"" C-m
        tmux split-window -h -t ${TMUX_SESSION_NAME}:${count}
        tmux send-keys -t ${TMUX_SESSION_NAME}:${count} "sleep 10s" C-m
        tmux send-keys -t ${TMUX_SESSION_NAME}:${count} "${GETH_BIN_PATH} attach ipc:${NETWORK_DIR}/${i}/geth.ipc" C-m
        
        PORT=`expr ${PORT} + 1`
        RPC_PORT=`expr ${RPC_PORT} + 1`
        count=`expr ${count} + 1`
    done
}

### Start of the main script
if [ ${ARGS_LENGTH} -eq "1" ]; then
    if [ -d ${NETWORK_DIR} ]; then
    tmux kill-session -t ${TMUX_SESSION_NAME} > /dev/null 2>&1
        launchBootNode
        launchNodes
    else
        echo "Please create an istanbul or clique network by passing geth binary with the number of node you would like to create and consensus algorithm"
        exit 1
    fi
elif [ ${ARGS_LENGTH} -eq "3" ]; then
    if [ ${CONSENSUS_ALGO} = "istanbul" ] || [ ${CONSENSUS_ALGO} = "clique" ]; then
        tmux kill-session -t ${TMUX_SESSION_NAME} > /dev/null 2>&1
        if [ -d "${NETWORK_DIR}" ]; then
            rm -rf "${NETWORK_DIR}"
        fi

        createDir "${NETWORK_DIR}"
        cd "${NETWORK_DIR}"

        createPasswd

        createAccounts

        createGenesis

        initialiseNodes

        createBootNodeKey

        launchBootNode
        launchNodes
    else
        echo "Please enter the consensus algorithm you want: \"istanbul\" or \"clique\", as the last argument"
        exit 1
    fi
else
    echo "Please create an istanbul or clique network by passing geth binary with the number of node you would like to create and consensus algorithm"
    exit 1
fi