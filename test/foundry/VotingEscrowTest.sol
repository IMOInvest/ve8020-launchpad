// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../../contracts/VotingEscrow.vy";
import "../../contracts/mock/Token.sol";
import "../../contracts/mock/BptToken.sol";
import "../../contracts/RewardDistributor.sol";
import "../../contracts/RewardFaucet.sol";
import "../../contracts/mock/BalancerToken.sol";
import "../../contracts/mock/BalancerMinter.sol";
import "../../contracts/mock/AuraToken.sol"; // Assuming you have a mock AuraToken contract

contract VotingEscrowTest is Test {
    VotingEscrow votingEscrow;
    TestToken rewardToken;
    BPTToken bptToken;
    RewardDistributor rewardDistributor;
    RewardFaucet rewardFaucet;
    BalancerToken balToken;
    BalancerMinter balMinter;
    AuraToken auraToken; // Mock AuraToken

    address owner;
    address creator;
    address user1;
    address user2;

    uint256 user1Amount = 2000 ether;
    uint256 user2Amount = 1000 ether;
    uint256 totalRewardAmount = 10000 ether;

    function setUp() public {
        owner = address(this);
        creator = address(0x1);
        user1 = address(0x2);
        user2 = address(0x3);

        rewardToken = new TestToken();
        bptToken = new BPTToken();
        votingEscrow = new VotingEscrow();
        rewardDistributor = new RewardDistributor();
        rewardFaucet = new RewardFaucet();
        balToken = new BalancerToken();
        balMinter = new BalancerMinter(address(balToken));
        auraToken = new AuraToken(); // Initialize mock AuraToken

        // Mint tokens
        rewardToken.mint(creator, totalRewardAmount);
        bptToken.mint(user1, user1Amount);
        bptToken.mint(user2, user2Amount);

        // Initialize contracts
        votingEscrow.initialize(
            address(bptToken),
            "initName",
            "initSymbol",
            user2,
            address(0),
            address(0),
            7 days,
            address(balToken),
            address(auraToken), // Set Aura token address
            address(balMinter),
            creator,
            true,
            address(rewardDistributor)
        );

        rewardDistributor.initialize(
            address(votingEscrow),
            address(rewardFaucet),
            block.timestamp + 21 days,
            user2
        );

        rewardFaucet.initialize(address(rewardDistributor));
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
}