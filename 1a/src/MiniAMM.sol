// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {IMiniAMM, IMiniAMMEvents} from "./IMiniAMM.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Add as many variables or functions as you would like
// for the implementation. The goal is to pass `forge test`.
contract MiniAMM is IMiniAMM, IMiniAMMEvents {
    uint256 public k;
    uint256 public xReserve;
    uint256 public yReserve;

    address public tokenX;
    address public tokenY;

    // implement constructor
    constructor(address _tokenX, address _tokenY) {
        require(_tokenX != address(0), "tokenX cannot be zero address");
        require(_tokenY != address(0), "tokenY cannot be zero address");
        require(_tokenX != _tokenY, "Tokens must be different");

        // order tokens so that tokenX < tokenY
        if (_tokenX < _tokenY) {
            tokenX = _tokenX;
            tokenY = _tokenY;
        } else {
            tokenX = _tokenY;
            tokenY = _tokenX;
        }

        k = 0;
        xReserve = 0;
        yReserve = 0;
    }

    // add parameters and implement function.
    // this function will determine the initial 'k'.
    function _addLiquidityFirstTime(uint256 xAmountIn, uint256 yAmountIn, address provider) internal {
        IERC20(tokenX).transferFrom(provider, address(this), xAmountIn);
        IERC20(tokenY).transferFrom(provider, address(this), yAmountIn);

        xReserve = xAmountIn;
        yReserve = yAmountIn;
        k = xReserve * yReserve;

        emit AddLiquidity(xAmountIn, yAmountIn);
    }

    // add parameters and implement function.
    // this function will increase the 'k'
    // because it is transferring liquidity from users to this contract.
    function _addLiquidityNotFirstTime(uint256 xAmountIn, uint256 yAmountIn, address provider) internal {
        IERC20(tokenX).transferFrom(provider, address(this), xAmountIn);
        IERC20(tokenY).transferFrom(provider, address(this), yAmountIn);

        xReserve += xAmountIn;
        yReserve += yAmountIn;
        k = xReserve * yReserve;

        emit AddLiquidity(xAmountIn, yAmountIn);
    }

    // complete the function
    function addLiquidity(uint256 xAmountIn, uint256 yAmountIn) external {
        require(xAmountIn > 0 && yAmountIn > 0, "Amounts must be greater than 0");
        if (k == 0) {
            _addLiquidityFirstTime(xAmountIn, yAmountIn, msg.sender);
        } else {
            _addLiquidityNotFirstTime(xAmountIn, yAmountIn, msg.sender);
        }
    }

    // complete the function
    function swap(uint256 xAmountIn, uint256 yAmountIn) external {
        require(k > 0, "No liquidity in pool");
        if (xAmountIn > 0 && yAmountIn > 0) {
            revert("Can only swap one direction at a time");
        }
        if (xAmountIn == 0 && yAmountIn == 0) {
            revert("Must swap at least one token");
        }

        // use current k for calculations
        uint256 currentK = xReserve * yReserve;

        if (xAmountIn > 0) {
            // sanity: do not allow swapping more than reserve in
            require(xAmountIn <= xReserve, "Insufficient liquidity");

            // take tokenX in
            IERC20(tokenX).transferFrom(msg.sender, address(this), xAmountIn);

            // compute tokenY out based on constant product
            uint256 newX = xReserve + xAmountIn;
            uint256 newY = currentK / newX;
            uint256 yOut = yReserve - newY;

            // send tokenY out
            IERC20(tokenY).transfer(msg.sender, yOut);

            // update reserves and k
            xReserve = newX;
            yReserve = newY;
            k = xReserve * yReserve;

            emit Swap(xAmountIn, yOut);
        } else {
            // yAmountIn > 0 path
            require(yAmountIn <= yReserve, "Insufficient liquidity");

            // take tokenY in
            IERC20(tokenY).transferFrom(msg.sender, address(this), yAmountIn);

            // compute tokenX out
            uint256 newY = yReserve + yAmountIn;
            uint256 newX = currentK / newY;
            uint256 xOut = xReserve - newX;

            // send tokenX out
            IERC20(tokenX).transfer(msg.sender, xOut);

            // update reserves and k
            xReserve = newX;
            yReserve = newY;
            k = xReserve * yReserve;

            // event fields mirror (xIn, yOut) semantics
            emit Swap(xOut, yAmountIn);
        }
    }
}
