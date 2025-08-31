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
    constructor(address _tokenX, address _tokenY) {
        require(_tokenX != _tokenY, "Tokens must be different");
        if(_tokenX == address(0)) {
            revert("tokenX cannot be zero address");
        }
        if(_tokenY == address(0)) {
            revert("tokenY cannot be zero address");
        }

        if(_tokenX < _tokenY) {
            tokenX = _tokenX;
            tokenY = _tokenY;
        }else {
            tokenX = _tokenY;
            tokenY = _tokenX;
        } 
    }

    // add parameters and implement function.
    // this function will determine the initial 'k'.
    function _addLiquidityFirstTime(uint256 xAmountIn, uint256 yAmountIn) internal {
        k = xAmountIn * yAmountIn ;
    }

    // add parameters and implement function.
    // this function will increase the 'k'
    // because it is transferring liquidity from users to this contract.
    function _addLiquidityNotFirstTime(uint256 xAmountIn, uint256 yAmountIn) internal {
        
    }

    // complete the function
    function addLiquidity(uint256 xAmountIn, uint256 yAmountIn) external {
        if (k == 0) {
            // add params
            _addLiquidityFirstTime(xAmountIn,yAmountIn);
        } else {
            // add params
            _addLiquidityNotFirstTime(xAmountIn,yAmountIn);
        }
    }

    // complete the function >> this is for tradding
    function swap(uint256 xAmountIn, uint256 yAmountIn) external {}
}
