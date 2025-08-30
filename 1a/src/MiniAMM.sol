// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {IMiniAMM, IMiniAMMEvents} from "./IMiniAMM.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Add as many variables or functions as you would like
// for the implementation. The goal is to pass `forge test`.
contract MiniAMM is IMiniAMM, IMiniAMMEvents {
    uint256 public k = 0;
    uint256 public xReserve = 0;
    uint256 public yReserve = 0;

    address public tokenX;
    address public tokenY;

    // implement constructor
    constructor(address _tokenX, address _tokenY) {}

    // add parameters and implement function.
    // this function will determine the initial 'k'.
    function _addLiquidityFirstTime() internal {}

    // add parameters and implement function.
    // this function will increase the 'k'
    // because it is transferring liquidity from users to this contract.
    function _addLiquidityNotFirstTime() internal {}

    // complete the function
    function addLiquidity(uint256 xAmountIn, uint256 yAmountIn) external {
        if (k == 0) {
            // add params
            _addLiquidityFirstTime();
        } else {
            // add params
            _addLiquidityNotFirstTime();
        }
    }

    // complete the function >> this is for tradding
    function swap(uint256 xAmountIn, uint256 yAmountIn) external {}
}
