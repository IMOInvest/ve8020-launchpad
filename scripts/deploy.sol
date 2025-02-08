// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "lib/forge-std/src/Script.sol";
import "contracts/VotingEscrow.vy";
import "contracts/RewardDistributor.sol";
import "contracts/RewardFaucet.sol";
import "contracts/Launchpad.vy";

contract Deploy is Script {
    function run() external {
        // Begin recording actions for the deployment
        vm.startBroadcast();

        // Deploy implementation contracts
        VotingEscrow votingEscrowImpl = new VotingEscrow();
        RewardDistributor rewardDistributorImpl = new RewardDistributor();
        RewardFaucet rewardFaucetImpl = new RewardFaucet();

        // Define addresses
        address balToken = 0x4158734d47fc9692176b5085e0f52ee0da5d47f1;
        address balMinter = 0x0c5538098EBe88175078972F514C9e101D325D4F;
        address auraToken = 0x1509706a6c66ca549ff0cb464de88231ddbe213b;

        // Deploy Launchpad
        Launchpad launchpad = new Launchpad(
            address(votingEscrowImpl),
            address(rewardDistributorImpl),
            address(rewardFaucetImpl),
            balToken,
            auraToken,
            balMinter
        );

        // Stop recording actions
        vm.stopBroadcast();

        // Log deployment addresses
        console.log("Deployment Summary:");
        console.log("VotingEscrow Implementation:", address(votingEscrowImpl));
        console.log("RewardDistributor Implementation:", address(rewardDistributorImpl));
        console.log("RewardFaucet Implementation:", address(rewardFaucetImpl));
        console.log("Launchpad:", address(launchpad));

        // Log constructor arguments for verification
        console.log("\nConstructor Arguments for Launchpad verification:");
        console.log("votingEscrowImpl:", address(votingEscrowImpl));
        console.log("rewardDistributorImpl:", address(rewardDistributorImpl));
        console.log("rewardFaucetImpl:", address(rewardFaucetImpl));
        console.log("balToken:", balToken);
        console.log("auraToken:", auraToken);
        console.log("balMinter:", balMinter);
    }
}
