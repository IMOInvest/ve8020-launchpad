// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IVault}  from "./interfaces/IVault.sol";
import {ABalancer} from "./utils/ABalancer.sol";
import {IOdosRouterV2} from "./interfaces/IOdosRouterv2.sol";

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
    IVotingEscrow public votingEscrow;
    IOdosRouterV2 public odosRouter;

    /**
     * @notice Initializes the Zapper contract with the specified token and VotingEscrow contract addresses.
     * @param _token The address of the ERC20 token to be used for locking.
     * @param _votingEscrow The address of the VotingEscrow contract.
     * @param _odosRouter The address of the OdosRouterV2 contract.
     */
    constructor(IERC20 _token, IVotingEscrow _votingEscrow, IOdosRouterV2 _odosRouter) {
        token = _token;
        votingEscrow = _votingEscrow;
        odosRouter = _odosRouter;
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
    function zapAssetsToWethAndStake(bytes calldata swapData, uint256 _unlock_time) public {
        uint256 userWethBalance = IERC20(WETH).balanceOf(msg.sender); //User WETH balance before swap
        uint256 wethBalance = IERC20(WETH).balanceOf(address(this)); //Contract WETH balance before swap
        //use Odos router to swap assets to WETH, WETH is returned to user address
        (bool success, bytes memory result) = address(odosRouter).call{value: 0}(swapData);

        require(success, "Swap failed");

        //Transfer swapped WETH from user to this contract
        IERC20(WETH).safeTransfer(address(this), IERC20(WETH).balanceOf(msg.sender) - userWethBalance); 
        
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
        if (hasLock(msg.sender)) {
            zapAndDepositForLock(BPTBalance, msg.sender);
        } else {
            zapAndCreateLockFor(BPTBalance, _unlock_time, msg.sender);
        }
    }
    
}
