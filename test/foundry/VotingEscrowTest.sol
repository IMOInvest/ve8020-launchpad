// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {TestToken} from "../../contracts/mock/Token.sol";
import {BPTToken} from  "../../contracts/mock/BptToken.sol";
import {RewardDistributor} from  "../../contracts/RewardDistributor.sol";
import {RewardFaucet} from "../../contracts/RewardFaucet.sol";
import {BalancerToken} from "../../contracts/mock/BalancerToken.sol";
import {BalancerMinter} from "../../contracts/mock/BalancerMinter.sol";
import {AuraToken} from "../../contracts/mock/AuraToken.sol"; // Assuming you have a mock AuraToken contract
import {Zapper} from "../../contracts/Zapper.sol"; // Import the Zapper contract
import {IVotingEscrow} from "../../contracts/interfaces/IVotingEscrow.sol"; // Import the VotingEscrow interface

contract VotingEscrowTest is Test {
    IVotingEscrow votingEscrow;
    TestToken rewardToken;
    BPTToken bptToken;
    RewardDistributor rewardDistributor;
    RewardFaucet rewardFaucet;
    BalancerToken balToken;
    BalancerMinter balMinter;
    AuraToken auraToken; // Mock AuraToken
    Zapper zapper; // Zapper contract

    /*

    
The VotingEscrow Implementation deployed at: 0x2Ad9c4368d3D7852a762749e96B6F330D416Ef94
The RewardDistributor Implementation deployed at: 0x6346cD3ee775517c19ee28bb53B97f34Ce69ad97
The RewardFaucet Implementation deployed at: 0x4cA2a6F42D9a20DE79A05DaD6D90Fa94CE1D7526
The Launchpad deployed at: 0xe152eF55C48441656Df1E70Ba040244F3165e6b0

❗️ Use following Constructor Arguments (ABI-encoded) for Launchpad verification:
0000000000000000000000002ad9c4368d3d7852a762749e96b6f330d416ef940000000000000000000000006346cd3ee775517c19ee28bb53b97f34ce69ad970000000000000000000000004ca2a6f42d9a20de79a05dad6d90fa94ce1d75260000000000000000000000004158734d47fc9692176b5085e0f52ee0da5d47f10000000000000000000000001509706a6c66ca549ff0cb464de88231ddbe213b0000000000000000000000000c5538098ebe88175078972f514c9e101d325d4f
*/
    address owner;
    address creator;
    address user1;
    address user2;

    uint256 user1Amount = 2000 ether;
    uint256 user2Amount = 1000 ether;
    uint256 totalRewardAmount = 10000 ether;

    // Addresses of already deployed contracts
    address votingEscrowAddress = 0xC12Cc45e4689e41F1f9E743E896e2BF4915361f7; // Replace with actual address
    address rewardTokenAddress = 0x5A7a2bf9fFae199f088B25837DcD7E115CF8E1bb; // Replace with actual address
    address bptTokenAddress = 	0xcCAC11368BDD522fc4DD23F98897712391ab1E00; // Replace with actual address
    address rewardDistributorAddress = 0x7d659A8d16e0C726aFDbAf76C2034fc73141e2d8; // Replace with actual address
    address rewardFaucetAddress = 0xCC599051522E9Fcd055fa982c825a043d6455905; // Replace with actual address
    address balTokenAddress = 0x4158734D47Fc9692176B5085E0F52ee0Da5d47F1; // Replace with actual address
    address balMinterAddress = 0x0c5538098EBe88175078972F514C9e101D325D4F; // Replace with actual address
    address auraTokenAddress = 0x1509706a6c66CA549ff0cB464de88231DDBe213B; // Replace with actual address
    address odosRouterAddress = 0x19cEeAd7105607Cd444F5ad10dd51356436095a1; // Replace with actual address
    address rewardReceiverAddress = 0x897Ec8F290331cfb0916F57b064e0A78Eab0e4A5;

    function setUp() public {
        owner = address(this);
        creator = address(0x1);
        user1 = address(0x2);
        user2 = address(0x3);

        // Use the addresses of already deployed contracts
        rewardToken = TestToken(rewardTokenAddress);
        bptToken = BPTToken(bptTokenAddress);
        votingEscrow = IVotingEscrow(votingEscrowAddress);
        rewardDistributor = RewardDistributor(rewardDistributorAddress);
        rewardFaucet = RewardFaucet(rewardFaucetAddress);
        balToken = BalancerToken(balTokenAddress);
        balMinter = BalancerMinter(balMinterAddress);
        auraToken = AuraToken(auraTokenAddress);

        // Create new Zapper contract
        zapper = new Zapper(
            address(bptToken),
            address(votingEscrow),
            payable(odosRouterAddress),
            address(rewardDistributor),
            address(balToken),
            address(auraToken)
        );

        // Mint tokens
        deal(rewardTokenAddress, creator, 100 ether);
        deal(balTokenAddress, creator, 100 ether);
        deal(auraTokenAddress, creator, 100 ether);

        deal(bptTokenAddress, user1, 100 ether);
        deal(bptTokenAddress, user2, 100 ether);

        // Initialize contracts if needed (assuming they are already initialized)
        // votingEscrow.initialize(...);
        // rewardDistributor.initialize(...);
        // rewardFaucet.initialize(...);
    }

    function testClaimAuraRewards() public {
        // Store initial balances
        uint256 initialBalBalance = balToken.balanceOf(votingEscrowAddress);
        uint256 initialAuraBalance = auraToken.balanceOf(votingEscrowAddress);
        uint256 user1Amount = 10 ether;

        vm.prank(user1, user1);
        bptToken.approve(address(votingEscrow), user1Amount);

        vm.prank(user1, user1);
        votingEscrow.create_lock(user1Amount, block.timestamp + 365 days);

        vm.warp(block.timestamp +  365 days);
        // Call claimAuraRewards

        vm.prank(owner, owner);
        votingEscrow.claimAuraRewards();

        // Check final balances
        uint256 finalBalBalance = balToken.balanceOf(votingEscrowAddress);
        uint256 finalAuraBalance = auraToken.balanceOf(votingEscrowAddress);

        console.log("Initial BAL balance: ", initialBalBalance);
        console.log("Final BAL balance: ", finalBalBalance);
        console.log("Initial Aura balance: ", initialAuraBalance);
        console.log("Final Aura balance: ", finalAuraBalance);

        // Assert that balances have increased
        //assertGt(finalBalBalance, initialBalBalance, "BAL balance did not increase");
        //assertGt(finalAuraBalance, initialAuraBalance, "Aura balance did not increase");
    }

    // Fuzzing tests for Zapper functions

    function testFuzz_ZapAndCreateLockFor(uint256 amount, uint256 unlockTime) public {
        vm.assume(amount > 0 && amount <= user1Amount);
        vm.assume(unlockTime > block.timestamp);

        // Mint tokens to user1
        bptToken.mint(user1, amount);

        // Approve Zapper contract to spend tokens
        vm.prank(user1);
        bptToken.approve(address(zapper), amount);

        // Call zapAndCreateLockFor
        vm.prank(user1);
        zapper.zapAndCreateLockFor(amount, unlockTime, user1);

        // Check that the lock was created
        assertTrue(votingEscrow.locked__end(user1) > block.timestamp, "Lock was not created");
    }

    function testFuzz_ZapAndDepositForLock(uint256 amount) public {
        vm.assume(amount > 0 && amount <= user1Amount);

        // Mint tokens to user1
        bptToken.mint(user1, amount);

        // Create an initial lock for user1
        uint256 unlockTime = block.timestamp + 7 days;
        vm.prank(user1);
        bptToken.approve(address(zapper), amount);
        vm.prank(user1);
        zapper.zapAndCreateLockFor(amount, unlockTime, user1);

        // Mint more tokens to user1
        bptToken.mint(user1, amount);

        // Approve Zapper contract to spend tokens
        vm.prank(user1);
        bptToken.approve(address(zapper), amount);

        // Call zapAndDepositForLock
        vm.prank(user1);
        zapper.zapAndDepositForLock(amount, user1);

        // Check that the deposit was added to the lock
        assertTrue(votingEscrow.locked__end(user1) > block.timestamp, "Deposit was not added to the lock");
    }

    function testFuzz_ZapAssetsToWethAndStake(bytes calldata swapData, uint256 unlockTime) public {
        vm.assume(unlockTime > block.timestamp);

        // Call zapAssetsToWethAndStake
        vm.prank(user1);
        zapper.zapAssetsToWethAndStake(swapData, unlockTime, user1);

        // Check that the assets were staked
        // Add your assertions here
    }

    function testFuzz_AutoCompoundRewards(bytes calldata swapData, uint256 unlockTime, address[] calldata rewardsTokens) public {
        vm.assume(unlockTime > block.timestamp);

        // Call AutoCompoundRewards
        vm.prank(user1);
        zapper.AutoCompoundRewards(swapData, unlockTime, rewardsTokens);

        // Check that the rewards were compounded
        // Add your assertions here
    }
}
