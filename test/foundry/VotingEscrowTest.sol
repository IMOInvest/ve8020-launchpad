// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
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

    address owner;
    address creator;
    address user1;
    address user2;

    uint256 user1Amount = 2000 ether;
    uint256 user2Amount = 1000 ether;
    uint256 totalRewardAmount = 10000 ether;

    // Addresses of already deployed contracts
    address votingEscrowAddress = address(0); // Replace with actual address
    address rewardTokenAddress = address(0); // Replace with actual address
    address bptTokenAddress = address(0); // Replace with actual address
    address rewardDistributorAddress = address(0); // Replace with actual address
    address rewardFaucetAddress = address(0); // Replace with actual address
    address balTokenAddress = address(0); // Replace with actual address
    address balMinterAddress = address(0); // Replace with actual address
    address auraTokenAddress = address(0); // Replace with actual address
    address odosRouterAddress = address(0); // Replace with actual address

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
        rewardToken.mint(creator, totalRewardAmount);
        bptToken.mint(user1, user1Amount);
        bptToken.mint(user2, user2Amount);

        // Initialize contracts if needed (assuming they are already initialized)
        // votingEscrow.initialize(...);
        // rewardDistributor.initialize(...);
        // rewardFaucet.initialize(...);
    }

    function testClaimAuraRewards() public {
        // Mint some Aura and BAL tokens to the VotingEscrow contract to simulate rewards
        balToken.mint(address(votingEscrow), 100 ether);
        auraToken.mint(address(votingEscrow), 50 ether);

        // Store initial balances
        uint256 initialBalBalance = balToken.balanceOf(creator);
        uint256 initialAuraBalance = auraToken.balanceOf(creator);

        // Call claimAuraRewards
        votingEscrow.claimAuraRewards();

        // Check final balances
        uint256 finalBalBalance = balToken.balanceOf(creator);
        uint256 finalAuraBalance = auraToken.balanceOf(creator);

        // Assert that balances have increased
        assertGt(finalBalBalance, initialBalBalance, "BAL balance did not increase");
        assertGt(finalAuraBalance, initialAuraBalance, "Aura balance did not increase");
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
