// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@balancer-labs/v2-solidity-utils/contracts/openzeppelin/SafeERC20.sol";
import {IVault}  from "./interfaces/IVault.sol";
import {ABalancer} from "./utils/ABalancer.sol";
import {IOdosRouterV2} from "./interfaces/IOdosRouterv2.sol";
import {RewardDistributor} from "./RewardDistributor.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IWETH} from "./interfaces/IWETH.sol";
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
    IERC20 public IMO;
    IVotingEscrow public votingEscrow;
    IOdosRouterV2 public odosRouter;
    RewardDistributor public rewardDistributor;

    event Test(address indexed user, uint256 amount);

    /**
     * @notice Initializes the Zapper contract with the specified token and VotingEscrow contract addresses.
     * @param _token The address of the ERC20 token to be used for locking.
     * @param _votingEscrow The address of the VotingEscrow contract.
     * @param _odosRouter The address of the OdosRouterV2 contract.
     */
    constructor(address _token, address _votingEscrow, address payable _odosRouter, address _rewardDistributor, address _balToken, address _auraToken, address _imoToken) Ownable(msg.sender) {
        token = IERC20(_token);
        votingEscrow = IVotingEscrow(_votingEscrow);
        odosRouter = IOdosRouterV2(_odosRouter);
        rewardDistributor = RewardDistributor(_rewardDistributor);
        BAL = IERC20(_balToken);
        AURA = IERC20(_auraToken);
        IMO = IERC20(_imoToken);
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
     * @notice Transfers IMO and or ETH tokens from the user and creates a new lock in the VotingEscrow contract.
     * @param _ImoAmount The amount of tokens to lock.
     * @param _unlock_time The timestamp at which the lock will expire.
     */
    function zapAndLockFor(uint256 _ImoAmount,uint256 _EthAmount, uint256 _unlock_time, address _recipient) public {
        require(msg.sender == _recipient || msg.sender == address(this), "Only Zapper or the recipient can call this function");
        require (!hasLock(_recipient), "lock already exists for the user");

        emit Test(msg.sender, _ImoAmount);

        if(_ImoAmount > 0 && msg.sender != address(this)) {
            // Transfer IMO tokens from the user to this contract
            IMO.safeTransferFrom(msg.sender, address(this), _ImoAmount);
        }

         if(_EthAmount > 0 && msg.sender != address(this)) {
            // Transfer WETH tokens from the user to this contract
            IERC20(WETH).safeTransferFrom(msg.sender, address(this), _EthAmount);
        }
        // Get the balance of BPT before deposit in this contract
        uint256 bptBalance = IERC20(IMOETHBPT).balanceOf(address(this));

        //Approve WETH and IMO to the Balancer vault
        IERC20(WETH).safeApprove(address(vault), _EthAmount);
        IERC20(IMO).safeApprove(address(vault), _ImoAmount);

        //Join IMO Pool
        joinImoPool(_EthAmount, _ImoAmount, address(this),address(this));

        //Get New BPT Balance after adding WETH and IMO to the pool
        bptBalance = IERC20(IMOETHBPT).balanceOf(address(this)) - bptBalance;

        //Transfer BPT to the recipient
        IERC20(IMOETHBPT).safeTransfer(_recipient, bptBalance);
        //uint256 auraBptBalance = IERC20(IMOETHAURABPT).balanceOf(address(this));


        //Test only, raw BPT
        votingEscrow.deposit_from_zapper(_recipient, bptBalance, _unlock_time);

        /*

        //Join Aura Pool
        joinAuraPool(bptBalance);

        //Get New AURA BPT Balance after adding BPT to the pool
        auraBptBalance = IERC20(IMOETHAURABPT).balanceOf(address(this)) - auraBptBalance;

        // Approve the voting escrow contract to spend the tokens
        token.safeApprove(address(votingEscrow), auraBptBalance);

        // Call the deposit_from_zapper function on the voting escrow contract
        votingEscrow.deposit_from_zapper(_recipient, auraBptBalance, _unlock_time);
        */
    }

    /**
     * @notice Transfers IMO and or ETH tokens from the user and creates a new lock in the VotingEscrow contract.
     * @param _ImoAmount The amount of tokens to lock.
     * @param _unlock_time The timestamp at which the lock will expire.
     */
    function zapAndLockForNative(uint256 _ImoAmount, uint256 _unlock_time, address _recipient) external payable {
        require(msg.sender == _recipient || msg.sender == address(this), "Only Zapper or the recipient can call this function");
        require(_ImoAmount >0  || msg.value > 0, "Amounts are zero");
        require (!hasLock(_recipient), "lock already exists for the user");

        // Convert ETH to WETH
        IWETH(WETH).deposit{value: msg.value}();
        //Send back the remaining WETH to the user
        IERC20(WETH).safeTransfer(msg.sender, msg.value);


        //Call the zapAndLockFor function
        zapAndLockFor(_ImoAmount, msg.value, _unlock_time, _recipient);
    }

    /**
     * @notice Transfers IMO and ETH tokens from the user and adds them to an existing lock in the VotingEscrow contract.
     * @param _ImoAmount The amount of tokens to add to the existing lock.
     */
    function zapAndDepositForLock(uint256 _ImoAmount, uint256 _EthAmount, address _recipient) public {
        require(msg.sender == _recipient || msg.sender == address(this), "Only Zapper or the recipient can call this function");
        require (hasLock(_recipient), "No lock exists for the user");

        if(_ImoAmount > 0) {
            // Transfer IMO tokens from the user to this contract
            IMO.safeTransferFrom(msg.sender, address(this), _ImoAmount);
        }
        if(_EthAmount > 0) {
            // Transfer WETH tokens from the user to this contract
            IERC20(WETH).safeTransferFrom(msg.sender, address(this), _EthAmount);
        }
        // Get the balance of BPT before deposit in this contract
        uint256 bptBalance = IERC20(IMOETHBPT).balanceOf(address(this));

        //Approve WETH and IMO to the Balancer vault
        IERC20(WETH).safeApprove(address(vault), _EthAmount);
        IERC20(IMO).safeApprove(address(vault), _ImoAmount);

        //Join IMO Pool
        joinImoPool(_EthAmount, _ImoAmount, address(this), address(this));

        //Get New BPT Balance after adding WETH and IMO to the pool
        bptBalance = IERC20(IMOETHBPT).balanceOf(address(this)) - bptBalance;
        uint256 auraBptBalance = IERC20(IMOETHAURABPT).balanceOf(address(this));

        /*

        //Join Aura Pool
        joinAuraPool(bptBalance);

        //Get New AURA BPT Balance after adding BPT to the pool
        auraBptBalance = IERC20(IMOETHAURABPT).balanceOf(address(this)) - auraBptBalance;

        // Approve the voting escrow contract to spend the tokens
        token.safeApprove(address(votingEscrow), auraBptBalance);

        // Call the deposit_for function on the voting escrow contract
        votingEscrow.deposit_for(_recipient, auraBptBalance);
        */
    }

    function zapAndDepositForLockNative(uint256 _ImoAmount,address _recipient) external payable {
        require(msg.sender == _recipient || msg.sender == address(this), "Only Zapper or the recipient can call this function");
        require (hasLock(_recipient), "No lock exists for the user");
        require(_ImoAmount >0  || msg.value > 0, "Amounts are zero");
       
        // Convert ETH to WETH
        IWETH(WETH).deposit{value: msg.value}();

        //Call the zapAndDepositForLock function
        zapAndDepositForLock(_ImoAmount, msg.value, _recipient);
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
        /*
        if hasLock(_recipient) {
            zapAndDepositForLock(BPTBalance, _recipient);
        } else {
            zapAndCreateLockFor(BPTBalance, _unlock_time, _recipient);
        }
        */
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
