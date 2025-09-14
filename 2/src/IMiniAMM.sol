// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

// DO NOT change the interface
interface IMiniAMM {
    function addLiquidity(uint256 xAmountIn, uint256 yAmountIn) external returns (uint256 lpMinted);
    function removeLiquidity(uint256 lpAmount) external returns (uint256 xAmount, uint256 yAmount);
    function swap(uint256 xAmountIn, uint256 yAmountIn) external;
}

// DO NOT change the interface
interface IMiniAMMEvents {
    event AddLiquidity(uint256 xAmountIn, uint256 yAmountIn);
    event Swap(uint256 xAmountIn, uint256 yAmountIn, uint256 xAmountOut, uint256 yAmountOut);
}
