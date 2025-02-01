// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;
// pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IAuraLocker} from '../interfaces/IAuraLocker.sol';

abstract contract AuraBPTToken is ERC20, IAuraLocker  {
    constructor() ERC20('BPTToken1', 'BPT1') {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}