// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IMockERC20} from "./IMockERC20.sol";

// Add as many variables or functions as you would like
// for the implementation. The goal is to pass `forge test`.
contract MockERC20 is ERC20, IMockERC20 {

    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {

    }

    // Implement
    function freeMintTo(uint256 amount, address to) external {
        _mint(to, amount);
    }

    // Implement
    function freeMintToSender(uint256 amount) external {
        _mint(msg.sender,amount);
        // msg.sender → 현재 함수(트랜잭션)를 호출한 계정 주소 , 일반 계정(EOA)일 수도 있고 다른 컨트랙트일 수도 있음
    }
}
