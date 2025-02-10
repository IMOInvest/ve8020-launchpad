// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@balancer-labs/v2-solidity-utils/contracts/openzeppelin/SafeERC20.sol";
import {IVault}  from "./interfaces/IVault.sol";
import {ABalancer} from "./utils/ABalancer.sol";
import {IOdosRouterV2} from "./interfaces/IOdosRouterv2.sol";
import {RewardDistributor} from "./RewardDistributor.sol";

interface IVotingEscrow {
    function create_lock(uint256 _value, uint256 _unlock_time) external;
    function deposit_for(address _addr, uint256 _value) external;
    function deposit_from_zapper(address _addr, uint256 _value, uint256 _unlock_time) external;
    function locked__end(address _addr) external view returns (uint256);
}

/**
 * @title Zapper
 * @notice Facilitates the creation and addition of locks in the VotingEscrow contract by transferring tokens from users.
 * @dev Uses SafeERC20 for safe token transfers and approvals.
 */
contract Zapper is ABalancer {
    using SafeERC20 for IERC20;
    IERC20 public token;
    IERC20 public BAL;
    IERC20 public AURA;
    IVotingEscrow public votingEscrow;
    IOdosRouterV2 public odosRouter;
    RewardDistributor public rewardDistributor;

    /**
     * @notice Initializes the Zapper contract with the specified token and VotingEscrow contract addresses.
     * @param _token The address of the ERC20 token to be used for locking.
     * @param _votingEscrow The address of the VotingEscrow contract.
     * @param _odosRouter The address of the OdosRouterV2 contract.
     */
    constructor(address _token, address _votingEscrow, address payable _odosRouter, address _rewardDistributor, address _balToken, address _auraToken) {
        token = IERC20(_token);
        votingEscrow = IVotingEscrow(_votingEscrow);
        odosRouter = IOdosRouterV2(_odosRouter);
        rewardDistributor = RewardDistributor(_rewardDistributor);
        BAL = IERC20(_balToken);
        AURA = IERC20(_auraToken);
    }

    /**
     * @notice Checks if the specified user has an existing lock in the VotingEscrow contract.
     * @param _addr The address of the user to check.
     * @return True if the user has an existing lock, false otherwise.
     */
    function hasLock(address _addr) internal view returns (bool) {
        return votingEscrow.locked__end(_addr) > block.timestamp;
    }

    /**
     * @notice Transfers tokens from the user and creates a new lock in the VotingEscrow contract.
     * @param _amount The amount of tokens to lock.
     * @param _unlock_time The timestamp at which the lock will expire.
     */
    function zapAndCreateLockFor(uint256 _amount, uint256 _unlock_time, address _recipient) public {
        require(msg.sender == _recipient || msg.sender == address(this), "Only Zapper or the recipient can call this function");
        // Transfer tokens from the user to this contract
        token.safeTransferFrom(_recipient, address(this), _amount);

        // Approve the voting escrow contract to spend the tokens
        token.safeApprove(address(votingEscrow), _amount);

        // Call the deposit_from_zapper function on the voting escrow contract
        votingEscrow.deposit_from_zapper(_recipient, _amount, _unlock_time);
    }

    /**
     * @notice Transfers tokens from the user and adds them to an existing lock in the VotingEscrow contract.
     * @param _amount The amount of tokens to add to the existing lock.
     */
    function zapAndDepositForLock(uint256 _amount, address _recipient) public {
        require(msg.sender == _recipient || msg.sender == address(this), "Only Zapper or the recipient can call this function");
        require(hasLock(_recipient), "No existing lock found for the user");
        // Transfer tokens from the user to this contract
        token.safeTransferFrom(_recipient, address(this), _amount);

        // Approve the voting escrow contract to spend the tokens
        token.safeApprove(address(votingEscrow), _amount);

        // Call the deposit_for function on the voting escrow contract
        votingEscrow.deposit_for(_recipient, _amount);
    }

    /**
     * @notice Zap Odos assets to WETH, add to BPT and stake to Aura and Voting Escrow. Requires WETH approval from user
     * @param swapData Odos swap data to swap assets to WETH.
     * @param _unlock_time Unlock time for new Lock. If locks already exists, this parameter is ignored.
     */
    function zapAssetsToWethAndStake(bytes calldata swapData, uint256 _unlock_time, address _recipient) public {
        require(msg.sender == _recipient || msg.sender == address(this), "Only Zapper or the recipient can call this function");
        uint256 userWethBalance = IERC20(WETH).balanceOf(_recipient); //User WETH balance before swap
        uint256 wethBalance = IERC20(WETH).balanceOf(address(this)); //Contract WETH balance before swap
        //use Odos router to swap assets to WETH, WETH is returned to user address
        (bool success, bytes memory result) = address(odosRouter).call{value: 0}(swapData);

        require(success, "Swap failed");

        //Transfer swapped WETH from user to this contract
        IERC20(WETH).safeTransfer(address(this), IERC20(WETH).balanceOf(_recipient) - userWethBalance); 
        
        //Get WETH balance after swap
        wethBalance = IERC20(WETH).balanceOf(address(this)) - wethBalance;
        require(wethBalance > 0, "WETH balance is zero");

        //Get BPT balance before adding WETH
        uint256 BPTBalance = IERC20(IMOETHBPT).balanceOf(address(this));

        //Add WETH to the pool
        IERC20(WETH).safeApprove(address(vault), wethBalance);
        joinImoPoolOnlyWeth(wethBalance, address(this), address(this));

        //Get BPT balance after adding WETH
        BPTBalance = IERC20(IMOETHBPT).balanceOf(address(this))- BPTBalance;
        require(BPTBalance > 0, "BPT balance is zero");

        //Stake to Aura
        joinAuraPool(BPTBalance);

        //Stake to Voting Escrow
        if (hasLock(_recipient)) {
            zapAndDepositForLock(BPTBalance, _recipient);
        } else {
            zapAndCreateLockFor(BPTBalance, _unlock_time, _recipient);
        }
    }

    /**
     * @notice Autocompound Rewards assets to WETH, add to BPT and stake to Aura and Voting Escrow. Requires _RewardsToken Approval approval from user
     * @param swapData Odos swap data to swap assets to WETH.
     * @param _unlock_time Unlock time for new Lock. If locks already exists, this parameter is ignored.
     */
    function AutoCompoundRewards(bytes calldata swapData, uint256 _unlock_time, address[] calldata _RewardsTokens) external {
        //Claim Rewards tokens
        // Create a dynamic array of IERC20 tokens
        IERC20[] memory tokens = new IERC20[](_RewardsTokens.length);

        // Add the reward tokens to the array
        for (uint256 i = 0; i < _RewardsTokens.length; i++) {
            tokens[i] = IERC20(_RewardsTokens[i]);
        }

        //Claim tokens on behalf of user
        rewardDistributor.claimTokens(msg.sender, tokens);

        //Swap BAL and AURA to WETH, stake to Aura and Voting Escrow
        zapAssetsToWethAndStake(swapData, _unlock_time, msg.sender);
    }
    
}
