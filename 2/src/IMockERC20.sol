// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

// DO NOT change the interface
interface IMockERC20 {
    function freeMintTo(uint256 amount, address to) external;
    function freeMintToSender(uint256 amount) external;
}
