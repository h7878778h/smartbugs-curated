// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "../dataset/ERC20.sol";

contract ERC20Mock is ERC20 {
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {}

    function mint(address account, uint256 value) external {
        _mint(account, value);
    }

    function burn(address account, uint256 value) external {
        _burn(account, value);
    }

    function approveInternal(address owner, address spender, uint256 value) external {
        _approve(owner, spender, value);
    }

    function transferInternal(address from, address to, uint256 value) external {
        _transfer(from, to, value);
    }

    function spendAllowanceInternal(address owner, address spender, uint256 value) external {
        _spendAllowance(owner, spender, value);
    }
}