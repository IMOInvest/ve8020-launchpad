// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

import {Errors} from "../libs/Errors.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {SafeTransferLib} from "../libs/SafeTransferLib.sol";
import {IVault} from "../interfaces/IVault.sol";
import {EtherUtils} from "../libs/EthersUtils.sol";
import {IVault} from "../interfaces/IVault.sol";
import "../libs/Balancer/WeightedPoolUserData.sol";
import {IAuraBooster} from "../interfaces/IAuraBooster.sol";


abstract contract ABalancer is EtherUtils, ReentrancyGuard {
    using SafeTransferLib for ERC20;

    // Base mainnet address of IMO.
    address internal IMO = 	0x5A7a2bf9fFae199f088B25837DcD7E115CF8E1bb;

    address public IMOETHBPT = 0x007bb7a4bfc214DF06474E39142288E99540f2b3;

    // Base mainnet address balanlcer vault.
    address internal vault = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    // Base mainnet id for balancer IMO-WETH pool.
    bytes32 internal poolId = 0x007bb7a4bfc214df06474e39142288e99540f2b3000200000000000000000191;
    // Base mainnet Address of Aura Booster 
    address public auraBooster = 0x98Ef32edd24e2c92525E59afc4475C1242a30184;

    uint256 internal auraBoosterPid = 0;


    /// @notice Emitted when the Balancer vault address is updated.
    /// @param newVault The address of the new Balancer vault.
    event SetBalancerVault(address newVault);

    /// @notice Emitted when the Balancer pool ID is updated.
    /// @param newPoolId The new pool ID.
    event SetBalancerPoolId(bytes32 newPoolId);

    event SetImoAddress(address newAddress);


     /// @notice Sets a new address for the IMO address.
    /// @param _newAddress The address of the new IMO Token.
    function setImoAddress(address _newAddress) external onlyOwner {
        IMO = _newAddress;
        emit SetImoAddress(_newAddress);
    }

    /// @notice Sets a new address for the Balancer vault.
    /// @param _vault The address of the new Balancer vault.
    function setBalancerVault(address _vault) external onlyOwner {
        if (_vault == address(0)) revert Errors.ZeroAddress();
        vault = _vault;

        emit SetBalancerVault(_vault);
    }

    /// @notice Sets a new pool ID for Balancer operations.
    /// @param _poolId The new pool ID.
    function setBalancerPoolId(bytes32 _poolId) external onlyOwner {
        poolId = _poolId;

        emit SetBalancerPoolId(_poolId);
    }

    /// @notice Resets WETH allowance for the specified Balancer vault.
    function resetBalancerAllowance() external onlyOwner {
        _resetWethAllowance(vault);
    }

    /// @notice Removes WETH allowance for the specified Balancer vault.
    function removeBalancerAllowance() external onlyOwner {
        _removeWethAllowance(vault);
    }


    function joinImoPool(uint256 EthAmount, uint256 ImoAmount, address sender, address receiver) public {
        address[] memory assets = new address[](2);
        assets[0] = WETH;  // 0x0f1D1b7abAeC1Df25f2C4Db751686FC5233f6D3f
        assets[1] = IMO; // 0x4200000000000000000000000000000000000006

        uint256[] memory maxAmountsIn = new uint256[](2);
        maxAmountsIn[0] = EthAmount;
        maxAmountsIn[1] = ImoAmount;

        bytes memory userData = abi.encode(
            uint256(WeightedPoolUserData.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT), // = 1
            maxAmountsIn,
            uint256(0)
        );

        IVault.JoinPoolRequest memory request = IVault.JoinPoolRequest({
            assets: assets,
            maxAmountsIn: maxAmountsIn,
            userData: userData,
            fromInternalBalance: true
        });

    
        IVault(vault).joinPool(poolId, sender, receiver, request);

    }  

    function joinImoPoolOnlyWeth(uint256 wethAmount, address sender, address receiver) public {
        address[] memory assets = new address[](2);
        assets[0] = IMO;  // 0x0f1D1b7abAeC1Df25f2C4Db751686FC5233f6D3f
        assets[1] = WETH; // 0x4200000000000000000000000000000000000006

        uint256[] memory maxAmountsIn = new uint256[](2);
        maxAmountsIn[0] = 0;
        maxAmountsIn[1] = wethAmount;

        bytes memory userData = abi.encode(
            uint256(WeightedPoolUserData.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT), // = 1
            maxAmountsIn,
            uint256(0)
        );

        IVault.JoinPoolRequest memory request = IVault.JoinPoolRequest({
            assets: assets,
            maxAmountsIn: maxAmountsIn,
            userData: userData,
            fromInternalBalance: false
        });

    
        IVault(vault).joinPool(poolId, sender, receiver, request);

    } 


    function joinAuraPool(uint256 _amount) internal {
        ERC20(IMOETHBPT).safeApprove(auraBooster, _amount);
        IAuraBooster(auraBooster).deposit(auraBoosterPid, _amount, true);
    }

    

    function getUserImoBalance(address user, address BPTpoolToken, uint256 BPTbalanceofUser) internal view returns (uint256) {

        uint256 totalBPTBalance = IERC20(BPTpoolToken).totalSupply();

        (address[] memory tokens, uint256[] memory balances, ) = IVault(vault).getPoolTokens(poolId);

        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == IMO) {
                return balances[i] * BPTbalanceofUser / totalBPTBalance;
            }
        }

        return 0;

    }

    // Get the IMO balance of the user in the IMO-ETH pool (hardcoded from the poolId)
    function getUserImoBalanceFromPool(uint256 BPTbalanceofUser) public view returns (uint256) {
        return getUserImoBalance(msg.sender, address(IMOETHBPT), BPTbalanceofUser);
    }
}