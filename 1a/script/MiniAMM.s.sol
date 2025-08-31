// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {MiniAMM} from "../src/MiniAMM.sol";
import {MockERC20} from "../src/MockERC20.sol";

// this file is for deploy contact
contract MiniAMMScript is Script {
    MiniAMM public miniAMM;
    MockERC20 public token0;
    MockERC20 public token1;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        MockERC20 tokenA = new MockERC20("TestDD", "tD");
        MockERC20 tokenB = new MockERC20("TestEE", "tE");
        MiniAMM amm = new MiniAMM(address(tokenA), address(tokenB));
        vm.stopBroadcast();
    }
}

// ==========================

// ##### flare-coston2
// ✅  [Success] Hash: 0xa732c755b1e3ff20762cd60e02c76e25648c0311f5aead00d084cc3d74b24947
// Contract Address: 0xCbcff4Bd5127A3F1Fb5779C096DDc2130353BF68
// Block: 21422986
// Paid: 0.0615714375 C2FLR (985143 gas * 62.5 gwei)


// ##### flare-coston2
// ✅  [Success] Hash: 0xe7cef43fec2fd8345fc62ee656376c7440e418692f94f2fddcda7aeaf05e67d8
// Contract Address: 0xFA25d25638db963ed9cB77FE7A106be5316c95bA
// Block: 21422989
// Paid: 0.0615714375 C2FLR (985143 gas * 62.5 gwei)


// ##### flare-coston2
// ✅  [Success] Hash: 0xeceabb758a179707dee7b30d5e3e5d1f61f2f30c2100b03b8af140a2abcb71db
// Contract Address: 0x696e6580ee863398FB7DDE7B1aD8b4F89B40099F
// Block: 21422990
// Paid: 0.064905875 C2FLR (1038494 gas * 62.5 gwei)

// ✅ Sequence #1 on flare-coston2 | Total Paid: 0.18804875 C2FLR (3008780 gas * avg 62.5 gwei)
                                                                                                                                                                                                                

// ==========================

// ONCHAIN EXECUTION COMPLETE & SUCCESSFUL.