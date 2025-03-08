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
import {IVotingEscrow} from "../../contracts/interfaces/IVotingEscrow.sol"; // Import the VotingEscrow interface
import {ILaunchpad} from "../../contracts/interfaces/ILaunchpad.sol";
import {VyperDeployer} from "../../lib/utils/VyperDeployer.sol";
import {VyperDeployerLegacy} from "./VyperDeployerLegacy.sol";
import {SmartWalletWhitelist} from "../../contracts/utils/SmartWalletWhitelist.sol";
import "../../contracts/RewardPoolDepositWrapper.sol";

contract VotingEscrowTestFromScratch is Test {
    IVotingEscrow votingEscrow;
    TestToken rewardToken;
    BPTToken bptToken;
    RewardDistributor rewardDistributor;
    RewardFaucet rewardFaucet;
    BalancerToken balToken;
    BalancerMinter balMinter;
    AuraToken auraToken; // Mock AuraToken
    VyperDeployer vyperDeployer;
    VyperDeployerLegacy vyperDeployerLegacy;
    SmartWalletWhitelist smartWalletWhitelist;
    RewardPoolDepositWrapper rewardPoolDepositWrapper; //Zapper for aura BPT into lock

    uint256 MAXLOCKTIME = 135691200; //Some time, cannot be 10 years (too long)
    uint256 RewardDistributorStartTime = block.timestamp + 14 days;
    address rewardReceiverAddress;

    address owner;
    address creator;
    address user1;
    address user2;

    uint256 user1Amount = 2000 ether;
    uint256 user2Amount = 1000 ether;
    uint256 totalRewardAmount = 10000 ether;

    // Addresses of already deployed contracts
    
    //address votingEscrowAddress = 0xC12Cc45e4689e41F1f9E743E896e2BF4915361f7; // Replace with actual address
    address rewardTokenAddress = 0x5A7a2bf9fFae199f088B25837DcD7E115CF8E1bb; // Replace with actual address
    //address bptTokenAddress = 	0xcCAC11368BDD522fc4DD23F98897712391ab1E00; // Aura eth bpt
    address bptTokenAddress = 	0x007bb7a4bfc214DF06474E39142288E99540f2b3; // IMO eth bpt

    //address rewardDistributorAddress = 0x7d659A8d16e0C726aFDbAf76C2034fc73141e2d8; // Replace with actual address
    //address rewardFaucetAddress = 0xCC599051522E9Fcd055fa982c825a043d6455905; // Replace with actual address
    address balTokenAddress = 0x4158734D47Fc9692176B5085E0F52ee0Da5d47F1; // Replace with actual address
    address balMinterAddress = 0x0c5538098EBe88175078972F514C9e101D325D4F; // Replace with actual address
    address auraTokenAddress = 0x1509706a6c66CA549ff0cB464de88231DDBe213B; // Replace with actual address
    address odosRouterAddress = 0x19cEeAd7105607Cd444F5ad10dd51356436095a1; // Replace with actual address
    //rewardReceiverAddressaddress rewardReceiverAddress = 0x897Ec8F290331cfb0916F57b064e0A78Eab0e4A5;
    address  imoAddress = 	0x5A7a2bf9fFae199f088B25837DcD7E115CF8E1bb;
    address wETHAddress = 0x4200000000000000000000000000000000000006;
    address  vault = 0xBA12222222228d8Ba445958a75a0704d566BF2C8; //Balancer Base Vault Address
    address _rewardPoolAddress = 0x0Ec191f765C0a1611aB3A4cdB839A66D2033e476;
    bytes32 _balancerPoolId = 0x007bb7a4bfc214df06474e39142288e99540f2b3000200000000000000000191;


    function setUp() public {
        owner = address(this);
        creator = address(0x897Ec8F290331cfb0916F57b064e0A78Eab0e4A5); //EOA
        user1 = address(0x7BD93fb2b1339761220e4167329De5C8671B93e1); //EOA
        user2 = address(0x3);
        rewardReceiverAddress = address(0x4);

        address zeroAddress = address(0);

        bytes memory args = abi.encode(
            zeroAddress,
            zeroAddress,
            zeroAddress,
            zeroAddress,
            zeroAddress,
            zeroAddress,
            zeroAddress
        ); 

        // Deploy from scracth
        VyperDeployer deployer = new VyperDeployer();
        //VyperDeployerLegacy deployerLegacy = new VyperDeployerLegacy();  
        address votingEscrowAddress = deployer.deployContract('contracts/', 'VotingEscrow', args);
        //address votingEscrowAddress = deployerLegacy.deployContract('VotingEscrow', args);

        
        rewardToken = TestToken(rewardTokenAddress);
        bptToken = BPTToken(bptTokenAddress);
        
        votingEscrow = IVotingEscrow(votingEscrowAddress);

        balToken = BalancerToken(balTokenAddress);
        balMinter = BalancerMinter(balMinterAddress);
        auraToken = AuraToken(auraTokenAddress);
        
        // Deploy new contracts

        // Set up the reward distributor
        RewardDistributor rewardDistributor = new RewardDistributor();

        //set up Reward Faucet
        RewardFaucet rewardFaucet = new RewardFaucet();

        bytes memory launchpadArgs = abi.encode(
            address(votingEscrow),
            address(rewardDistributor),
            address(rewardFaucet),
            address(balToken),
            address(auraToken),
            address(balMinter)
        );

        //setup launchpad contract
        address launchpad = deployer.deployContract('contracts/', 'Launchpad', launchpadArgs);
        //address launchpad = deployerLegacy.deployContract('Launchpad', launchpadArgs);

        ILaunchpad launchpadDeployed = ILaunchpad(launchpad);

        //string  name = "IMO staking Test";
        //string  symbol = "veIMOTEST";

        //Deploy VE from launchpad
        (address NewVotingEscrowAddress, address NewRewardDistributorAddress, address NewRewardFaucetAddress) = launchpadDeployed.deploy(
            address(bptToken),
            "IMO staking Test",
            "veIMOTEST",
            MAXLOCKTIME,
            RewardDistributorStartTime,
            owner,
            owner,
            rewardReceiverAddress);


        //(address NewVotingEscrowAddress, address NewRewardDistributorAddress, address NewRewardFaucetAddress) = launchpad.deploy(address(0));
        
        votingEscrow = IVotingEscrow(NewVotingEscrowAddress);
        rewardDistributor = RewardDistributor(NewRewardDistributorAddress);
        rewardFaucet = RewardFaucet(NewRewardFaucetAddress);
        

        // Create new RewardPoolDepositor contract

        rewardPoolDepositWrapper = new RewardPoolDepositWrapper(
            vault, 
            address(votingEscrow)
        );

        //Setup wallet checker
        smartWalletWhitelist = new SmartWalletWhitelist(owner);

        vm.prank(owner);
        smartWalletWhitelist.setChecker(address(smartWalletWhitelist));

        vm.prank(owner);
        smartWalletWhitelist.approveWallet(address(rewardPoolDepositWrapper));




        //set wallet checker for VE
        vm.prank(owner);
        votingEscrow.commit_smart_wallet_checker(address(smartWalletWhitelist));

        vm.prank(owner);
        votingEscrow.apply_smart_wallet_checker();
        

        // Mint tokens
        deal(rewardTokenAddress, creator, 100 ether);
        deal(balTokenAddress, creator, 100 ether);
        deal(auraTokenAddress, creator, 100 ether);

        //deal(bptTokenAddress, user1, 100 ether);
        //deal(bptTokenAddress, user2, 100 ether);

        // Initialize contracts if needed (assuming they are already initialized)
        // votingEscrow.initialize(...);
        // rewardDistributor.initialize(...);
        // rewardFaucet.initialize(...);
    }

    function testClaimAuraRewards() public {
        address receiver = votingEscrow.rewardReceiver();
        // Store initial balances
        uint256 initialBalBalance = balToken.balanceOf(receiver);
        uint256 initialAuraBalance = auraToken.balanceOf(receiver);
        uint256 user1Amount = 10 ether;

        vm.prank(user1, user1);
        bptToken.approve(address(votingEscrow), user1Amount);

        vm.prank(user1, user1);
        votingEscrow.create_lock(user1Amount, block.timestamp + 365 days);

        vm.warp(block.timestamp +  365 days);
        // Call claimAuraRewards

        votingEscrow.claimAuraRewards();

        // Check final balances
        uint256 finalBalBalance = balToken.balanceOf(receiver);
        uint256 finalAuraBalance = auraToken.balanceOf(receiver);

        console.log("Initial BAL balance: ", initialBalBalance);
        console.log("Final BAL balance: ", finalBalBalance);
        console.log("Initial Aura balance: ", initialAuraBalance);
        console.log("Final Aura balance: ", finalAuraBalance);

        // Assert that balances have increased
        assertGt(finalBalBalance, initialBalBalance, "BAL balance did not increase");
        assertGt(finalAuraBalance, initialAuraBalance, "Aura balance did not increase");
    }

    // Fuzzing tests for Zapper functions

    function testFuzz_ZapAndCreateLockFor(uint256 amount) public {
        amount = bound(amount, 1000000000000 , 1e19);

        uint256 unlockTime = block.timestamp + 365 days;
        uint256 imoScalingFactor  = 4000;
        uint256 imoAmount = amount*imoScalingFactor;


        // Mint tokens to user1
        deal(imoAddress, user1, imoAmount);
        deal(user1, amount);

        // Approve Zapper contract to spend tokens
        vm.prank(user1, user1);
        IERC20(imoAddress).approve(address(rewardPoolDepositWrapper), imoAmount);

        vm.prank(user1, user1);
        IERC20(wETHAddress).approve(address(rewardPoolDepositWrapper), amount);

        bool isAllowed = smartWalletWhitelist.check(address(rewardPoolDepositWrapper));
        console.log("Is Pool Depositor allowed: ", isAllowed);

        vm.prank(user1, user1);
        IERC20(bptTokenAddress).approve(address(votingEscrow), type(uint256).max);

        IAsset[] memory assets = new IAsset[](2);
        assets[0] = IAsset(wETHAddress);  // 0x0f1D1b7abAeC1Df25f2C4Db751686FC5233f6D3f
        assets[1] = IAsset(imoAddress); // 0x4200000000000000000000000000000000000006

        uint256[] memory maxAmountsIn = new uint256[](2);
        maxAmountsIn[0] = amount;
        maxAmountsIn[1] = imoAmount;

        bytes memory userData = abi.encode(
            1, // = uint256(WeightedPoolUserData.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT)
            maxAmountsIn,
            uint256(0)
        );

        IBalancerVault.JoinPoolRequest memory request = IBalancerVault.JoinPoolRequest({
            assets: assets,
            maxAmountsIn: maxAmountsIn,
            userData: userData,
            fromInternalBalance: false
        });

        // Call zapAndCreateLockFor
        vm.prank(user1, user1);
        rewardPoolDepositWrapper.depositMutipleAndLock(_rewardPoolAddress, IERC20(imoAddress), IERC20(wETHAddress), imoAmount, amount, _balancerPoolId, true,unlockTime, request);

        // Check that the lock was created
        uint256 stakeAmount = IERC20(address(votingEscrow)).balanceOf(user1);

        assertTrue(stakeAmount > 0, "Deposit was not added to the lock");
        assertTrue(votingEscrow.locked__end(user1) > block.timestamp, "Lock was not created");
    }

    function testFuzz_ZapAndDepositForLock(uint256 amount) public {
        amount = bound(amount, 1000000000000 , 1e19);

        uint256 unlockTime = block.timestamp + 365 days;
        uint256 imoScalingFactor  = 4000;
        uint256 imoAmount = amount*imoScalingFactor;
        uint256 initialBPTAmount = 1e16;


        // Mint tokens to user1
        deal(imoAddress, user1, imoAmount);
        deal(user1, amount);
        deal(bptTokenAddress, user1, initialBPTAmount);

        vm.prank(user1, user1);
        IERC20(bptTokenAddress).approve(address(votingEscrow), type(uint256).max);

        // Create an initial lock
        vm.prank(user1, user1);
        votingEscrow.create_lock(initialBPTAmount, unlockTime);

        uint256 stakeAmount = IERC20(address(votingEscrow)).balanceOf(user1);
        console.log("Initial Stake amount: ", stakeAmount);
        // Warp to the future
        //vm.warp(block.timestamp + 1 days);

        // Approve Zapper contract to spend tokens
        vm.prank(user1, user1);
        IERC20(imoAddress).approve(address(rewardPoolDepositWrapper), imoAmount);

        vm.prank(user1, user1);
        IERC20(wETHAddress).approve(address(rewardPoolDepositWrapper), amount);

        bool isAllowed = smartWalletWhitelist.check(address(rewardPoolDepositWrapper));
        console.log("Is Zapper allowed: ", isAllowed);

        // Mint tokens to user1
        deal(imoAddress, user1, imoAmount);
        deal(user1, amount);

        // Approve Zapper contract to spend tokens
        vm.prank(user1, user1);
        IERC20(imoAddress).approve(address(rewardPoolDepositWrapper), imoAmount);

        vm.prank(user1, user1);
        IERC20(wETHAddress).approve(address(rewardPoolDepositWrapper), amount);

        vm.prank(user1, user1);
        IERC20(bptTokenAddress).approve(address(votingEscrow), type(uint256).max);

        IAsset[] memory assets = new IAsset[](2);
        assets[0] = IAsset(wETHAddress);  // 0x0f1D1b7abAeC1Df25f2C4Db751686FC5233f6D3f
        assets[1] = IAsset(imoAddress); // 0x4200000000000000000000000000000000000006

        uint256[] memory maxAmountsIn = new uint256[](2);
        maxAmountsIn[0] = amount;
        maxAmountsIn[1] = imoAmount;

        bytes memory userData = abi.encode(
            1, // = uint256(WeightedPoolUserData.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT)
            maxAmountsIn,
            uint256(0)
        );

        IBalancerVault.JoinPoolRequest memory request = IBalancerVault.JoinPoolRequest({
            assets: assets,
            maxAmountsIn: maxAmountsIn,
            userData: userData,
            fromInternalBalance: false
        });

        // Call zapAndCreateLockFor
        vm.prank(user1, user1);
        rewardPoolDepositWrapper.depositMutipleAndLock(_rewardPoolAddress, IERC20(imoAddress), IERC20(wETHAddress), imoAmount, amount, _balancerPoolId, true,unlockTime, request);

        // Check that the deposit was added to the lock
        stakeAmount = IERC20(address(votingEscrow)).balanceOf(user1) ;//- stakeAmount;
        console.log("New Stake amount: ", stakeAmount);
        assertTrue(stakeAmount > 0, "Deposit was not added to the lock");
        assertTrue(votingEscrow.locked__end(user1) > block.timestamp, "Deposit was not added to the lock");
    }

}
