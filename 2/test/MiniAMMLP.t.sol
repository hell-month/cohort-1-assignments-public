// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {MiniAMM} from "../src/MiniAMM.sol";
import {MockERC20} from "../src/MockERC20.sol";

contract MiniAMMLPTest is Test {
    MiniAMM public miniAMM;
    MockERC20 public token0;
    MockERC20 public token1;
    
    address public alice = address(0x1);

    function setUp() public {
        // Deploy mock tokens
        token0 = new MockERC20("Token A", "TKA");
        token1 = new MockERC20("Token B", "TKB");

        // Deploy MiniAMM
        miniAMM = new MiniAMM(address(token0), address(token1));

        // Setup tokens for alice
        token0.freeMintTo(10000 * 10 ** 18, alice);
        token1.freeMintTo(10000 * 10 ** 18, alice);

        vm.startPrank(alice);
        token0.approve(address(miniAMM), type(uint256).max);
        token1.approve(address(miniAMM), type(uint256).max);
        vm.stopPrank();
    }

    function test_LP_Mint() public {
        uint256 xAmount = 1000 * 10 ** 18;
        uint256 yAmount = 2000 * 10 ** 18;

        vm.prank(alice);
        uint256 lpMinted = miniAMM.addLiquidity(xAmount, yAmount);

        // Check minting worked
        assertGt(lpMinted, 0, "Should mint LP tokens");
        assertEq(miniAMM.balanceOf(alice), lpMinted, "Alice should receive minted LP tokens");
        assertGt(miniAMM.totalSupply(), 0, "Total supply should increase");
    }

    function test_LP_Burn() public {
        // First mint
        vm.prank(alice);
        uint256 lpMinted = miniAMM.addLiquidity(1000 * 10 ** 18, 2000 * 10 ** 18);

        uint256 balanceBefore = miniAMM.balanceOf(alice);
        uint256 supplyBefore = miniAMM.totalSupply();

        // Then burn
        vm.prank(alice);
        miniAMM.removeLiquidity(lpMinted);

        // Check burning worked
        assertEq(miniAMM.balanceOf(alice), 0, "Alice's LP tokens should be burned");
        assertLt(miniAMM.totalSupply(), supplyBefore, "Total supply should decrease");
    }
}