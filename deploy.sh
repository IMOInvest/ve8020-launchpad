#!/bin/bash
source .env

# Deploy
forge script script/Deploy.s.sol:Deploy \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY \
    --broadcast \
    --verify \
    -vvvv

# If you want to verify manually later:
# forge verify-contract \
#     --chain-id 8453 \
#     --num-of-optimizations 200 \
#     --constructor-args $(cast abi-encode "constructor(address,address,address,address,address,address)" \
#         $VOTING_ESCROW_IMPL \
#         $REWARD_DISTRIBUTOR_IMPL \
#         $REWARD_FAUCET_IMPL \
#         $BAL_TOKEN \
#         $AURA_TOKEN \
#         $BAL_MINTER) \
#     $DEPLOYED_ADDRESS \
#     src/Launchpad.sol:Launchpad \
#     $ETHERSCAN_API_KEY
