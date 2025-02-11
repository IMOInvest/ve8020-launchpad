// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

// solhint-disable func-name-mixedcase

interface IVotingEscrow {
    struct Point {
        int128 bias;
        int128 slope; // - dweight / dt
        uint256 ts;
        uint256 blk; // block
    }

    function epoch() external view returns (uint256);

    function admin() external view returns (address);

    function future_admin() external view returns (address);

    function apply_smart_wallet_checker() external;

    function apply_transfer_ownership() external;

    function balanceOf(address user, uint256 timestamp) external view returns (uint256);

    function balanceOfAt(address addr, uint256 _block) external view returns (uint256);

    function checkpoint() external;

    function commit_smart_wallet_checker(address addr) external;

    function commit_transfer_ownership(address addr) external;

    function create_lock(uint256 _value, uint256 _unlock_time) external;

    function decimals() external view returns (uint256);

    function deposit_for(address _addr, uint256 _value) external;

    function get_last_user_slope(address addr) external view returns (int128);

    function increase_amount(uint256 _value) external;

    function increase_unlock_time(uint256 _unlock_time) external;

    function locked__end(address _addr) external view returns (uint256);

    function name() external view returns (string memory);

    function point_history(uint256 timestamp) external view returns (Point memory);

    function symbol() external view returns (string memory);

    function token() external view returns (address);

    function totalSupply(uint256 t) external view returns (uint256);

    function totalSupplyAt(uint256 _block) external view returns (uint256);

    function user_point_epoch(address user) external view returns (uint256);

    function user_point_history__ts(address _addr, uint256 _idx) external view returns (uint256);

    function user_point_history(address user, uint256 timestamp) external view returns (Point memory);

    function withdraw() external;

    // New functions added from the provided ABI
    function MAXTIME() external view returns (uint256);

    function TOKEN() external view returns (address);

    function admin_early_unlock() external view returns (address);

    function admin_unlock_all() external view returns (address);

    function all_unlock() external view returns (bool);

    function auraToken() external view returns (address);

    function balMinter() external view returns (address);

    function balToken() external view returns (address);

    function changeRewardReceiver(address newReceiver) external;

    function claimAuraRewards() external;

    function claimExternalRewards() external;

    function deposit_from_zapper(address _addr, uint256 _value, uint256 _unlock_time) external;

    function early_unlock() external view returns (bool);

    function future_smart_wallet_checker() external view returns (address);

    function initialize(
        address _token_addr,
        string memory _name,
        string memory _symbol,
        address _admin_addr,
        address _admin_unlock_all,
        address _admin_early_unlock,
        uint256 _max_time,
        address _balToken,
        address _auraToken,
        address _balMinter,
        address _rewardReceiver,
        bool _rewardReceiverChangeable,
        address _rewardDistributor
    ) external;

    function is_initialized() external view returns (bool);

    function locked(address arg0) external view returns (int128 amount, uint256 end);

    function penalty_k() external view returns (uint256);

    function penalty_treasury() external view returns (address);

    function penalty_upd_ts() external view returns (uint256);

    function prev_penalty_k() external view returns (uint256);

    function rewardDistributor() external view returns (address);

    function rewardReceiver() external view returns (address);

    function rewardReceiverChangeable() external view returns (bool);

    function set_all_unlock() external;

    function set_early_unlock(bool _early_unlock) external;

    function set_early_unlock_penalty_speed(uint256 _penalty_k) external;

    function set_penalty_treasury(address _penalty_treasury) external;

    function slope_changes(uint256 arg0) external view returns (int128);

    function smart_wallet_checker() external view returns (address);

    function supply() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function withdraw_early() external;
}
