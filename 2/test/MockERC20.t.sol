// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {MockERC20} from "../src/MockERC20.sol";

contract MockERC20Test is Test {
    MockERC20 public token;
    address public alice = address(0x1);
    address public bob = address(0x2);

    function setUp() public {
        token = new MockERC20("Mock Token", "MTK");
    }

    function test_Constructor() public view {
        assertEq(token.name(), "Mock Token");
        assertEq(token.symbol(), "MTK");
        assertEq(token.decimals(), 18);
        assertEq(token.totalSupply(), 0);
    }

    function test_FreeMintTo() public {
        uint256 mintAmount = 1000 * 10 ** 18; // 1000 tokens

        // Initial balance should be 0
        assertEq(token.balanceOf(alice), 0);

        // Mint tokens to alice
        token.freeMintTo(mintAmount, alice);

        // Check that alice received the tokens
        assertEq(token.balanceOf(alice), mintAmount);
        assertEq(token.totalSupply(), mintAmount);
    }

    function test_FreeMintToSender() public {
        uint256 mintAmount = 2000 * 10 ** 18; // 2000 tokens

        // Start acting as alice
        vm.startPrank(alice);

        // Initial balance should be 0
        assertEq(token.balanceOf(alice), 0);

        // Mint tokens to sender (alice)
        token.freeMintToSender(mintAmount);

        // Check that alice received the tokens
        assertEq(token.balanceOf(alice), mintAmount);
        assertEq(token.totalSupply(), mintAmount);

        vm.stopPrank();
    }
}
