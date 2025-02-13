// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface ILaunchpad {
    event VESystemCreated(
        address indexed token, address votingEscrow, address rewardDistributor, address rewardFaucet, address admin
    );

    function auraToken() external view returns (address);
    function balMinter() external view returns (address);
    function balToken() external view returns (address);
    function deploy(
        address tokenBptAddr,
        string memory name,
        string memory symbol,
        uint256 maxLockTime,
        uint256 rewardDistributorStartTime,
        address admin_unlock_all,
        address admin_early_unlock,
        address rewardReceiver
    ) external returns (address, address, address);
    function rewardDistributor() external view returns (address);
    function rewardFaucet() external view returns (address);
    function votingEscrow() external view returns (address);
}
