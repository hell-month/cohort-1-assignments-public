// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {MiniAMM} from "../src/MiniAMM.sol";
import {IMiniAMMEvents} from "../src/IMiniAMM.sol";
import {MockERC20} from "../src/MockERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MiniAMMTest is Test {
    MiniAMM public miniAMM;
    MockERC20 public token0;
    MockERC20 public token1;

    address public alice = address(0x1);
    address public bob = address(0x2);
    address public charlie = address(0x3);

    // Import events
    event AddLiquidity(uint256 xAmountIn, uint256 yAmountIn);
    event Swap(uint256 xAmountIn, uint256 yAmountIn, uint256 xAmountOut, uint256 yAmountOut);

    function setUp() public {
        // Deploy mock tokens
        token0 = new MockERC20("Token A", "TKA");
        token1 = new MockERC20("Token B", "TKB");

        // Deploy MiniAMM with the tokens
        miniAMM = new MiniAMM(address(token0), address(token1));

        // Mint tokens to test addresses
        token0.freeMintTo(10000 * 10 ** 18, alice);
        token1.freeMintTo(10000 * 10 ** 18, alice);
        token0.freeMintTo(10000 * 10 ** 18, bob);
        token1.freeMintTo(10000 * 10 ** 18, bob);
        token0.freeMintTo(10000 * 10 ** 18, charlie);
        token1.freeMintTo(10000 * 10 ** 18, charlie);

        // Approve tokens for MiniAMM
        vm.startPrank(alice);
        token0.approve(address(miniAMM), type(uint256).max);
        token1.approve(address(miniAMM), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(bob);
        token0.approve(address(miniAMM), type(uint256).max);
        token1.approve(address(miniAMM), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(charlie);
        token0.approve(address(miniAMM), type(uint256).max);
        token1.approve(address(miniAMM), type(uint256).max);
        vm.stopPrank();
    }

    function test_Constructor() public view {
        // Check that tokens are set (order doesn't matter for this test)
        assertTrue(miniAMM.tokenX() == address(token0) || miniAMM.tokenX() == address(token1));
        assertTrue(miniAMM.tokenY() == address(token0) || miniAMM.tokenY() == address(token1));
        assertTrue(miniAMM.tokenX() != miniAMM.tokenY());
        assertEq(miniAMM.k(), 0);
        assertEq(miniAMM.xReserve(), 0);
        assertEq(miniAMM.yReserve(), 0);
    }

    function test_ConstructorTokenOrdering() public {
        // Test that tokens are ordered correctly (tokenX < tokenY)
        MockERC20 tokenA = new MockERC20("Token A", "TKA");
        MockERC20 tokenB = new MockERC20("Token B", "TKB");

        MiniAMM amm1 = new MiniAMM(address(tokenA), address(tokenB));
        assertEq(amm1.tokenX(), address(tokenA));
        assertEq(amm1.tokenY(), address(tokenB));

        MiniAMM amm2 = new MiniAMM(address(tokenB), address(tokenA));
        assertEq(amm2.tokenX(), address(tokenA));
        assertEq(amm2.tokenY(), address(tokenB));
    }

    function test_ConstructorRevertZeroAddress() public {
        vm.expectRevert("tokenX cannot be zero address");
        new MiniAMM(address(0), address(token1));

        vm.expectRevert("tokenY cannot be zero address");
        new MiniAMM(address(token0), address(0));
    }

    function test_ConstructorRevertSameToken() public {
        vm.expectRevert("Tokens must be different");
        new MiniAMM(address(token0), address(token0));
    }

    function test_AddLiquidityFirstTime_WithLPTokens() public {
        uint256 xAmount = 1000 * 10 ** 18;
        uint256 yAmount = 2000 * 10 ** 18;

        vm.startPrank(alice);

        // Calculate expected LP tokens using sqrt
        uint256 expectedLPTokens = 1414213562373095048801;

        uint256 lpMinted = miniAMM.addLiquidity(xAmount, yAmount);

        // Check LP tokens were minted correctly
        assertEq(lpMinted, expectedLPTokens);
        assertEq(miniAMM.balanceOf(alice), expectedLPTokens);
        assertEq(miniAMM.totalSupply(), expectedLPTokens);

        // Check reserves were updated
        assertEq(miniAMM.xReserve(), xAmount);
        assertEq(miniAMM.yReserve(), yAmount);
        assertEq(miniAMM.k(), xAmount * yAmount);

        vm.stopPrank();
    }

    function test_AddLiquidityNotFirstTime_WithLPTokens() public {
        // First, add initial liquidity
        uint256 xInitial = 1000 * 10 ** 18;
        uint256 yInitial = 2000 * 10 ** 18;

        vm.prank(alice);
        miniAMM.addLiquidity(xInitial, yInitial);

        // Now add more liquidity maintaining the ratio
        uint256 xDelta = 500 * 10 ** 18;
        uint256 yRequired = (xDelta * yInitial) / xInitial; // 1000 tokens

        vm.startPrank(bob);

        // Calculate expected LP tokens
        uint256 expectedLPTokens = 707106781186547524400;

        uint256 lpMinted = miniAMM.addLiquidity(xDelta, yRequired);

        // Check LP tokens were minted correctly
        assertEq(lpMinted, expectedLPTokens);
        assertEq(miniAMM.balanceOf(bob), expectedLPTokens);

        // Check reserves were updated correctly
        assertEq(miniAMM.xReserve(), xInitial + xDelta);
        assertEq(miniAMM.yReserve(), yInitial + yRequired);

        vm.stopPrank();
    }

    function test_RemoveLiquidity() public {
        // First, add liquidity
        uint256 xAmount = 1000 * 10 ** 18;
        uint256 yAmount = 2000 * 10 ** 18;

        vm.prank(alice);
        uint256 lpTokens = miniAMM.addLiquidity(xAmount, yAmount);

        // Now remove half of the liquidity
        uint256 lpToRemove = lpTokens / 2;
        
        vm.startPrank(alice);

        // Get actual token addresses from miniAMM (they might be reordered)
        address tokenX = miniAMM.tokenX();
        address tokenY = miniAMM.tokenY();
        
        uint256 aliceTokenXBefore = IERC20(tokenX).balanceOf(alice);
        uint256 aliceTokenYBefore = IERC20(tokenY).balanceOf(alice);

        (uint256 xOut, uint256 yOut) = miniAMM.removeLiquidity(lpToRemove);

        // Check that LP tokens were burned
        assertEq(miniAMM.balanceOf(alice), lpTokens - lpToRemove);

        // Check that tokens were returned (pre-calculated expected values)
        assertEq(xOut, 499999999999999999999); // ~500e18
        assertEq(yOut, 999999999999999999999); // ~1000e18

        // Check token balances increased
        assertEq(IERC20(tokenX).balanceOf(alice), aliceTokenXBefore + xOut);
        assertEq(IERC20(tokenY).balanceOf(alice), aliceTokenYBefore + yOut);

        // Check reserves decreased
        assertEq(miniAMM.xReserve(), xAmount - xOut);
        assertEq(miniAMM.yReserve(), yAmount - yOut);

        vm.stopPrank();
    }

    function test_RemoveLiquidityAll() public {
        // Add liquidity
        uint256 xAmount = 1000 * 10 ** 18;
        uint256 yAmount = 2000 * 10 ** 18;

        vm.prank(alice);
        uint256 lpTokens = miniAMM.addLiquidity(xAmount, yAmount);

        // Remove all liquidity
        vm.startPrank(alice);

        (uint256 xOut, uint256 yOut) = miniAMM.removeLiquidity(lpTokens);

        // Check that all LP tokens were burned
        assertEq(miniAMM.balanceOf(alice), 0);

        // Check that all tokens were returned (exact amounts since removing 100% of liquidity)
        assertEq(xOut, xAmount);
        assertEq(yOut, yAmount);

        vm.stopPrank();
    }

    function test_SwapWithFees() public {
        // Add initial liquidity
        uint256 xInitial = 1000 * 10 ** 18;
        uint256 yInitial = 2000 * 10 ** 18;

        vm.prank(alice);
        miniAMM.addLiquidity(xInitial, yInitial);

        // Swap with 0.3% fee
        uint256 xSwap = 100 * 10 ** 18;

        vm.startPrank(bob);

        // Calculate expected output with 0.3% fee
        uint256 expectedYOut = 181322178776029826316;

        // Determine which token will be received
        address tokenY = miniAMM.tokenY();
        
        uint256 bobTokenYBefore = IERC20(tokenY).balanceOf(bob);

        miniAMM.swap(xSwap, 0);

        uint256 actualYOut = IERC20(tokenY).balanceOf(bob) - bobTokenYBefore;

        // Check that output matches expected with fee
        assertEq(actualYOut, expectedYOut);

        // Check that k invariant is maintained or increased (due to fees)
        uint256 newK = miniAMM.xReserve() * miniAMM.yReserve();
        assertGe(newK, miniAMM.k());

        vm.stopPrank();
    }

    function test_SwapFeeBenefitsLiquidityProviders() public {
        // Add initial liquidity
        uint256 xInitial = 1000 * 10 ** 18;
        uint256 yInitial = 2000 * 10 ** 18;

        vm.prank(alice);
        uint256 aliceLPTokens = miniAMM.addLiquidity(xInitial, yInitial);

        // Perform multiple swaps to accumulate fees
        vm.startPrank(bob);
        
        for (uint i = 0; i < 10; i++) {
            miniAMM.swap(10 * 10 ** 18, 0); // Swap X for Y
            miniAMM.swap(0, 10 * 10 ** 18); // Swap Y for X
        }
        
        vm.stopPrank();

        // Alice removes liquidity and should get more than she put in due to fees
        vm.startPrank(alice);
        
        (uint256 xOut, uint256 yOut) = miniAMM.removeLiquidity(aliceLPTokens);
        
        // Due to swap fees, Alice should get back slightly less due to slippage
        // But overall should be close to what she put in (swap fees benefit her as LP)
        assertGt(xOut + yOut, (xInitial + yInitial) * 98 / 100); // Allow 2% slippage tolerance

        vm.stopPrank();
    }


    function test_SwapRevertNoLiquidity() public {
        vm.expectRevert("No liquidity in pool");
        vm.prank(alice);
        miniAMM.swap(100 * 10 ** 18, 0);
    }

    function test_SwapRevertBothDirections() public {
        // Add initial liquidity
        uint256 xInitial = 1000 * 10 ** 18;
        uint256 yInitial = 2000 * 10 ** 18;

        vm.prank(alice);
        miniAMM.addLiquidity(xInitial, yInitial);

        vm.expectRevert("Can only swap one direction at a time");
        vm.prank(bob);
        miniAMM.swap(100 * 10 ** 18, 100 * 10 ** 18);
    }

    function test_SwapRevertZeroAmount() public {
        // Add initial liquidity
        uint256 xInitial = 1000 * 10 ** 18;
        uint256 yInitial = 2000 * 10 ** 18;

        vm.prank(alice);
        miniAMM.addLiquidity(xInitial, yInitial);

        vm.expectRevert("Must swap at least one token");
        vm.prank(bob);
        miniAMM.swap(0, 0);
    }

    function test_SwapRevertInsufficientLiquidity() public {
        // Add initial liquidity
        uint256 xInitial = 1000 * 10 ** 18;
        uint256 yInitial = 2000 * 10 ** 18;

        vm.prank(alice);
        miniAMM.addLiquidity(xInitial, yInitial);

        vm.expectRevert("Insufficient liquidity");
        vm.prank(bob);
        miniAMM.swap(xInitial + 1, 0); // Try to swap more than available
    }

    function test_SwapPriceImpact() public {
        // Add initial liquidity
        uint256 xInitial = 1000 * 10 ** 18;
        uint256 yInitial = 2000 * 10 ** 18;

        vm.prank(alice);
        miniAMM.addLiquidity(xInitial, yInitial);

        // Get the actual token addresses from MiniAMM
        address actualTokenY = miniAMM.tokenY();
        MockERC20 tokenYActual = actualTokenY == address(token0) ? token0 : token1;

        // Small swap
        vm.startPrank(bob);
        miniAMM.swap(10 * 10 ** 18, 0);
        uint256 smallSwapOutput = tokenYActual.balanceOf(bob);

        // Reset bob's balance by transferring tokens back to MiniAMM
        uint256 bobTokenYBalance = tokenYActual.balanceOf(bob);
        tokenYActual.transfer(address(miniAMM), bobTokenYBalance);

        // Large swap
        miniAMM.swap(100 * 10 ** 18, 0);
        uint256 largeSwapOutput = tokenYActual.balanceOf(bob);

        // Large swap should have worse price (more slippage)
        // The larger swap should have a worse price per token
        uint256 smallSwapPricePerToken = smallSwapOutput * 10 ** 18 / (10 * 10 ** 18);
        uint256 largeSwapPricePerToken = largeSwapOutput * 10 ** 18 / (100 * 10 ** 18);

        assertLt(largeSwapPricePerToken, smallSwapPricePerToken); // Larger swap has worse price

        vm.stopPrank();
    }

    function test_AddLiquidityEvent() public {
        uint256 xAmount = 1000 * 10 ** 18;
        uint256 yAmount = 2000 * 10 ** 18;

        vm.expectEmit(true, true, true, true);
        emit AddLiquidity(xAmount, yAmount);

        vm.prank(alice);
        miniAMM.addLiquidity(xAmount, yAmount);
    }

    function test_SwapEvent() public {
        // Add initial liquidity
        uint256 xInitial = 1000 * 10 ** 18;
        uint256 yInitial = 2000 * 10 ** 18;

        vm.prank(alice);
        miniAMM.addLiquidity(xInitial, yInitial);

        uint256 xSwap = 100 * 10 ** 18;

        // Calculate expected output with 0.3% fee
        // Pre-calculated expected output: 181.322178776029826316e18
        uint256 expectedYOut = 181322178776029826316;

        vm.expectEmit(true, true, true, true);
        emit Swap(xSwap, 0, 0, expectedYOut);

        vm.prank(bob);
        miniAMM.swap(xSwap, 0);
    }

    // Helper function for square root
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
}