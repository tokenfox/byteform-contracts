#!/bin/bash
set -e

# Load environment variables from .env file if it exists
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
else
    echo "No .env found, using environment variables from shell"
fi

if [ -z "$RPC_URL_SEPOLIA" ]; then
    echo "RPC_URL_SEPOLIA is not set."
    exit 1
fi

if [ -z "$ETHERSCAN_API_KEY" ]; then
    echo "ETHERSCAN_API_KEY is not set."
    exit 1
fi

if [ -z "$PRIVATE_KEY" ]; then
    echo "PRIVATE_KEY is not set."
    exit 1
fi

forge script script/Deploy.s.sol:DeployScript \
    --rpc-url $RPC_URL_SEPOLIA \
    --broadcast \
    --verify \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --private-key $PRIVATE_KEY \
    --chain-id 11155111