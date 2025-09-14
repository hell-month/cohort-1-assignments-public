// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

// DO NOT change the interface
interface IMiniAMMFactory {
    // View functions
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint256 index) external view returns (address pair);
    function allPairsLength() external view returns (uint256);
    
    // State-changing functions
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

// DO NOT change the interface
interface IMiniAMMFactoryEvents {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256 pairNumber);
}
