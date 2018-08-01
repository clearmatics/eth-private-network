#!/bin/bash

# TODO: remember to add a function for the bootnode
# TODO: instead of having 2 different scripts have multiple arguements which state what is to be done with the script
# TODO: Need to initialise each of the node using the genesis
# TODO: Need to start the nodes using genesis
# TODO: change the way ports are passed to the geth when the program is created
# TODO: Get the istanbulversion of Geth

# DONE
# TODO: in the createAccount() function create the account using  password and geth
# TODO: Remove the istanbul dir if it exists at the beginning of the script
# TODO: Collect address from the nodes and add them to an array in order to create the genisis file
# TODO: Think about how to get the addresss from nodes (possibly through the keystore folder in each of the nodes)
# TODO: possibly need to download the getamis istanbul-tools
# TODO: remmber the creation of genesis.json
    # Delete unnecessary folders by istanbul tools
    # Need to create the extra data from the toml file
    # Create a javascript file to update genesis files
    # Learn how to save the json into the file from script
# TODO: Only install geth if not availabe

# Define variables
GOPATH="/home/user98/go"
PATH=$PATH:/usr/local/go/bin
THIS_FILE_PARENT_DIR=`dirname \`readlink -f $0\``
ISTANBUL_DIR="${HOME}/istanbultestnet"
PASSWORD_PATH="${ISTANBUL_DIR}/passwd.txt"
NUMBER_OF_NODES=$1
GETAMIS_PATH="${GOPATH}/src/github.com/getamis"
ISTANBUL_TOOLS_PATH="${GOPATH}/src/github.com/getamis/istanbul-tools"
ISTANBUL_TOOLS_GITHUB="https://github.com/getamis/istanbul-tools.git"

# Ensure script is run as root
isRoot() {
    if [ `whoami` != "root" ]; then
        echo "Please run as root"
        exit 2
    fi
}

# Install go-ethereum
installGeth() {
    geth version > /dev/null 2>&1
    if [ "$?" -ne "0" ]; then
        echo; echo "Installing latest Geth ..."
        apt-get install -y software-properties-common
        add-apt-repository -y ppa:ethereum/ethereum
        apt-get update
        apt-get install -y ethereum
        echo "Finished installing Geth ..."; echo
    fi
}

# Create a common password file
createPasswd() {
    echo; echo "Creating ${PASSWORD_PATH} ..."
    touch "${PASSWORD_PATH}"
    echo "istanbulnetwork" > "${PASSWORD_PATH}"
    echo "Finished creating ${PASSWORD_PATH} ..."; echo
}

# Create a directory for the given path
createDIR() {
    DIR="$1"
    if [ ! -d  "${DIR}" ]; then
        echo; echo "Creating ${DIR}"
        mkdir -p "${DIR}"
        echo "Finished creating ${DIR}"; echo
    fi
}

# Bye using Geth create the account in the given dir location
createAccount() {
    NODE_DIR="$1"
    PORT="$2"

    createDIR ${NODE_DIR}
    geth --datadir ${NODE_DIR} --password ${PASSWORD_PATH} account new
}

# Create toml file which has validator addresses in them
createToml() {
    VANITY="0x00"
    NODE_ADDRESSES=("$@")

    if [ -f "${ISTANBUL_DIR}/config.toml" ]; then
        rm "${ISTANBUL_DIR}/config.toml"
    fi

    echo "vanity = \"${VANITY}\"" >> "${ISTANBUL_DIR}/config.toml"

    count=1
    for i in ${NODE_ADDRESSES[@]}
    do
        if [ ${count} -eq "1" ]; then
            echo "validators = [\"0x${i}\"," >> "${ISTANBUL_DIR}/config.toml"
        elif [ ${count} -eq ${#NODE_ADDRESSES[@]} ]; then
            echo "${string}\"0x${i}\"]" >> "${ISTANBUL_DIR}/config.toml"
        else
            echo "${string}\"0x${i}\"," >> "${ISTANBUL_DIR}/config.toml"
        fi
        count=`expr ${count} + 1`
    done
}

# Create the genesis needed to initialise the nodes
createGenesis() {
    echo

    # Get the address from keystore and store them in an array
    ADDRESSES=()
    for i in `ls ${ISTANBUL_DIR} | grep node`
    do
        ADDRESSES+=(`ls ${ISTANBUL_DIR}/${i}/keystore | cut -d'-' -f9`)
    done

    # Clone istanbul-tools
    if ! [ -d "${ISTANBUL_TOOLS_PATH}" ]; then
        git clone "${ISTANBUL_TOOLS_GITHUB}" "${ISTANBUL_TOOLS_PATH}"
        chown -R `logname`:`logname` "${GETAMIS_PATH}"
    fi

    # Make istanbul-tools
    if ! [ -f "${ISTANBUL_TOOLS_PATH}/build/bin/istanbul" ]; then
        make -C ${ISTANBUL_TOOLS_PATH}
    fi

    # Run istanbul-tools
    ${ISTANBUL_TOOLS_PATH}/build/bin/istanbul setup --num ${NUMBER_OF_NODES} --verbose --save > /dev/null 2>&1

    # Remove unnecessary folders created by istanbul-tools
    for i in `seq 0 \`expr ${NUMBER_OF_NODES} - 1\``
    do
        rm -rf "${i}"
    done

    # Create config.toml with the validators
    createToml ${ADDRESSES[@]}

    # Call istanbul extra encode and store in a file
    ${ISTANBUL_TOOLS_PATH}/build/bin/istanbul extra encode --config "${ISTANBUL_DIR}/config.toml" | cut -d':' -f2 | tr -d " \t\n\r" >  "${ISTANBUL_DIR}/newextradata.txt"

    # Update genesis file, the genesis.json and extra data's file location is passed in and the rest of the addresses are passed to assign some ether
    node "${THIS_FILE_PARENT_DIR}/updategenesis.js" "${ISTANBUL_DIR}/genesis.json" "${ISTANBUL_DIR}/newextradata.txt" ${ADDRESSES[@]}
}

initialiseNetwork() {
    echo
}


startBootNode() {
    echo
}

### Start of the main script
if ! [ ${NUMBER_OF_NODES} -eq ${NUMBER_OF_NODES} ] || [ -z ${NUMBER_OF_NODES} ]; then
    echo ${NUMBER_OF_NODES}
    echo "Please enter the number of node you would like to create as the first argument"
    exit 1
fi

isRoot

if [ -d "${ISTANBUL_DIR}" ]; then
    rm -rf "${ISTANBUL_DIR}"
fi

installGeth

createDIR "${ISTANBUL_DIR}"
cd "${ISTANBUL_DIR}"
createPasswd

for i in `seq 1 "${NUMBER_OF_NODES}"`
do
    createAccount "${ISTANBUL_DIR}/node${i}" 1000${i}
done

createGenesis

chown -R `logname`:`logname` "${ISTANBUL_DIR}"