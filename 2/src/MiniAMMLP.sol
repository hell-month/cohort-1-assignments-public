// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

abstract contract MiniAMMLP is ERC20 {
    constructor(address _tokenX, address _tokenY) ERC20("MiniAMM LP", "MINI-LP") {
    }

    function _mintLP(address to, uint256 amount) internal {
        _mint(to, amount);
    }

    function _burnLP(address from, uint256 amount) internal {
        _burn(from, amount);
    }
}