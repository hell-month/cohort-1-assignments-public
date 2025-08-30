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

        // Deploy mock ERC20 tokens
        token0 = new MockERC20("a","a");
        token1 = new MockERC20("b","b");
        // Deploy MiniAMM with the tokens
        miniAMM = new MiniAMM(address(token0),address(token1));
        vm.stopBroadcast();
    }
}
