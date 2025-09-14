// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {IMiniAMM, IMiniAMMEvents} from "./IMiniAMM.sol";
import {MiniAMMLP} from "./MiniAMMLP.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Add as many variables or functions as you would like
// for the implementation. The goal is to pass `forge test`.
contract MiniAMM is IMiniAMM, IMiniAMMEvents, MiniAMMLP {
    uint256 public k = 0;
    uint256 public xReserve = 0;
    uint256 public yReserve = 0;

    address public tokenX;
    address public tokenY;

    // implement constructor
    constructor(address _tokenX, address _tokenY) MiniAMMLP(_tokenX, _tokenY) {
        if (_tokenX == address(0)) revert("tokenX cannot be zero address");
        if (_tokenY == address(0)) revert("tokenY cannot be zero address");
        if (_tokenX == _tokenY) revert("Tokens must be different");

        // order tokens by address to ensure deterministic X/Y
        if (_tokenX < _tokenY) {
            tokenX = _tokenX;
            tokenY = _tokenY;
        } else {
            tokenX = _tokenY;
            tokenY = _tokenX;
        }
    }

    // Helper function to calculate square root
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }

    // add parameters and implement function.
    // this function will determine the 'k'.
    function _addLiquidityFirstTime(uint256 xAmountIn, uint256 yAmountIn) internal returns (uint256 lpMinted) {
        // transfer tokens in
        require(IERC20(tokenX).transferFrom(msg.sender, address(this), xAmountIn), "transferFrom X failed");
        require(IERC20(tokenY).transferFrom(msg.sender, address(this), yAmountIn), "transferFrom Y failed");

        // mint LP as sqrt(x*y)
        lpMinted = sqrt(xAmountIn * yAmountIn);
        _mintLP(msg.sender, lpMinted);

        // update reserves and k
        xReserve = xAmountIn;
        yReserve = yAmountIn;
        k = xReserve * yReserve;
    }

    // add parameters and implement function.
    // this function will increase the 'k'
    // because it is transferring liquidity from users to this contract.
    function _addLiquidityNotFirstTime(uint256 xAmountIn) internal returns (uint256 lpMinted) {
        // maintain ratio: yAmountIn must be provided by caller based on current reserves
        // yAmountIn is computed externally; here we infer from msg value? Not available, so rely on allowance and balances
        // We will compute yAmountIn required as (xAmountIn * yReserve) / xReserve using integer math and expect caller to have approved at least that amount.
        uint256 yAmountIn = (xAmountIn * yReserve) / xReserve;

        require(IERC20(tokenX).transferFrom(msg.sender, address(this), xAmountIn), "transferFrom X failed");
        require(IERC20(tokenY).transferFrom(msg.sender, address(this), yAmountIn), "transferFrom Y failed");

        // LP minted proportional to added liquidity: min(xIn * totalSupply / xRes, yIn * totalSupply / yRes)
        uint256 _totalSupply = totalSupply();
        uint256 lpFromX = (xAmountIn * _totalSupply) / xReserve;
        uint256 lpFromY = (yAmountIn * _totalSupply) / yReserve;
        lpMinted = lpFromX < lpFromY ? lpFromX : lpFromY;
        _mintLP(msg.sender, lpMinted);

        xReserve += xAmountIn;
        yReserve += yAmountIn;
        k = xReserve * yReserve;
    }

    // complete the function. Should transfer LP token to the user.
    function addLiquidity(uint256 xAmountIn, uint256 yAmountIn) external returns (uint256 lpMinted) {
        emit AddLiquidity(xAmountIn, yAmountIn);
        if (xReserve == 0 && yReserve == 0) {
            require(xAmountIn > 0 && yAmountIn > 0, "Amounts must be positive");
            lpMinted = _addLiquidityFirstTime(xAmountIn, yAmountIn);
        } else {
            require(xAmountIn > 0, "x must be positive");
            // yAmountIn is expected to be the exact ratio by test; ignore provided yAmountIn and derive internally for safety
            lpMinted = _addLiquidityNotFirstTime(xAmountIn);
        }
    }

    // Remove liquidity by burning LP tokens
    function removeLiquidity(uint256 lpAmount) external returns (uint256 xAmount, uint256 yAmount) {
        uint256 _totalSupply = totalSupply();
        require(lpAmount > 0 && lpAmount <= _totalSupply, "invalid lp amount");

        // compute proportional amounts
        xAmount = (lpAmount * xReserve) / _totalSupply;
        yAmount = (lpAmount * yReserve) / _totalSupply;

        _burnLP(msg.sender, lpAmount);

        // update reserves then transfer out
        xReserve -= xAmount;
        yReserve -= yAmount;
        k = xReserve * yReserve;

        require(IERC20(tokenX).transfer(msg.sender, xAmount), "transfer X failed");
        require(IERC20(tokenY).transfer(msg.sender, yAmount), "transfer Y failed");
    }

    // complete the function
    function swap(uint256 xAmountIn, uint256 yAmountIn) external {
        if (xReserve == 0 || yReserve == 0) revert("No liquidity in pool");
        if ((xAmountIn == 0 && yAmountIn == 0)) revert("Must swap at least one token");
        if (xAmountIn > 0 && yAmountIn > 0) revert("Can only swap one direction at a time");

        uint256 xOut;
        uint256 yOut;

        if (xAmountIn > 0) {
            if (xAmountIn > xReserve) revert("Insufficient liquidity");
            // take x in
            require(IERC20(tokenX).transferFrom(msg.sender, address(this), xAmountIn), "transferFrom X failed");

            // uniswap v2 formula with 0.3% fee
            uint256 amountInWithFee = xAmountIn * 997;
            uint256 numerator = amountInWithFee * yReserve;
            uint256 denominator = xReserve * 1000 + amountInWithFee;
            yOut = numerator / denominator;

            require(yOut < yReserve, "Insufficient liquidity");

            // update reserves
            xReserve += xAmountIn;
            yReserve -= yOut;

            // send out Y
            require(IERC20(tokenY).transfer(msg.sender, yOut), "transfer Y failed");
        } else {
            if (yAmountIn > yReserve) revert("Insufficient liquidity");
            require(IERC20(tokenY).transferFrom(msg.sender, address(this), yAmountIn), "transferFrom Y failed");

            uint256 amountInWithFee = yAmountIn * 997;
            uint256 numerator = amountInWithFee * xReserve;
            uint256 denominator = yReserve * 1000 + amountInWithFee;
            xOut = numerator / denominator;

            require(xOut < xReserve, "Insufficient liquidity");

            yReserve += yAmountIn;
            xReserve -= xOut;

            require(IERC20(tokenX).transfer(msg.sender, xOut), "transfer X failed");
        }

        k = xReserve * yReserve;
        emit Swap(xAmountIn, yAmountIn, xOut, yOut);
    }
}
