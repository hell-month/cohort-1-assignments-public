// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {MiniAMMFactory} from "../src/MiniAMMFactory.sol";
import {IMiniAMMFactoryEvents} from "../src/IMiniAMMFactory.sol";
import {MiniAMM} from "../src/MiniAMM.sol";
import {MockERC20} from "../src/MockERC20.sol";

contract MiniAMMFactoryTest is Test {
    MiniAMMFactory public factory;
    MockERC20 public token0;
    MockERC20 public token1;

    // Import events for testing
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256 pairNumber);

    function setUp() public {
        // Deploy mock tokens
        token0 = new MockERC20("Token A", "TKA");
        token1 = new MockERC20("Token B", "TKB");
    }

    function test_Factory_CreatePair() public {
        // Deploy factory
        factory = new MiniAMMFactory();

        // Create pair
        address pair = factory.createPair(address(token0), address(token1));

        // Check pair was created correctly
        assertEq(factory.getPair(address(token0), address(token1)), pair);
        assertEq(factory.getPair(address(token1), address(token0)), pair); // Should work both ways
        assertEq(factory.allPairsLength(), 1);
        assertEq(factory.allPairs(0), pair);

        // Check pair has correct configuration
        MiniAMM pairContract = MiniAMM(pair);
        
        // Tokens should be ordered (tokenX < tokenY)
        address expectedTokenX = address(token0) < address(token1) ? address(token0) : address(token1);
        address expectedTokenY = address(token0) < address(token1) ? address(token1) : address(token0);
        
        assertEq(pairContract.tokenX(), expectedTokenX);
        assertEq(pairContract.tokenY(), expectedTokenY);
    }

    function test_Factory_CannotCreateDuplicatePair() public {
        factory = new MiniAMMFactory();

        // Create first pair
        factory.createPair(address(token0), address(token1));

        // Try to create duplicate pair
        vm.expectRevert("Pair exists");
        factory.createPair(address(token0), address(token1));

        // Try with reversed order
        vm.expectRevert("Pair exists");
        factory.createPair(address(token1), address(token0));
    }

    function test_Factory_CannotCreatePairWithSameToken() public {
        factory = new MiniAMMFactory();

        // Try to create pair with same token
        vm.expectRevert("Identical addresses");
        factory.createPair(address(token0), address(token0));
    }

    function test_Factory_CannotCreatePairWithZeroAddress() public {
        factory = new MiniAMMFactory();

        // Try to create pair with zero address
        vm.expectRevert("Zero address");
        factory.createPair(address(0), address(token1));

        vm.expectRevert("Zero address");
        factory.createPair(address(token0), address(0));
    }

    function test_Factory_AllPairs() public {
        factory = new MiniAMMFactory();

        // Initially no pairs
        assertEq(factory.allPairsLength(), 0);

        // Create first pair
        address pair1 = factory.createPair(address(token0), address(token1));
        assertEq(factory.allPairsLength(), 1);
        assertEq(factory.allPairs(0), pair1);

        // Create second pair
        MockERC20 token2 = new MockERC20("Token C", "TKC");
        address pair2 = factory.createPair(address(token0), address(token2));
        assertEq(factory.allPairsLength(), 2);
        assertEq(factory.allPairs(1), pair2);
    }

    function test_Factory_TokenOrdering() public {
        factory = new MiniAMMFactory();

        // Create tokens with specific addresses for predictable ordering
        MockERC20 tokenA = new MockERC20("Token A", "TKA");
        MockERC20 tokenB = new MockERC20("Token B", "TKB");

        address pair1 = factory.createPair(address(tokenA), address(tokenB));
        
        // Verify that getPair works both ways (should return same pair)
        assertEq(factory.getPair(address(tokenA), address(tokenB)), pair1);
        assertEq(factory.getPair(address(tokenB), address(tokenA)), pair1);
        
        // Creating the same pair in reverse order should revert since pair already exists
        vm.expectRevert("Pair exists");
        factory.createPair(address(tokenB), address(tokenA));
    }

    function test_Factory_PairCreatedEvent() public {
        factory = new MiniAMMFactory();

        // Determine token ordering (factory orders tokens by address)
        address expectedToken0 = address(token0) < address(token1) ? address(token0) : address(token1);
        address expectedToken1 = address(token0) < address(token1) ? address(token1) : address(token0);

        // Expect the PairCreated event with correct parameters (don't check pair address)
        vm.expectEmit(true, true, false, false);
        emit PairCreated(expectedToken0, expectedToken1, address(0), 1);

        address pair = factory.createPair(address(token0), address(token1));

        // Verify the pair was created and event was emitted correctly
        assertTrue(pair != address(0));
    }

    function test_Factory_PairCreatedEventMultiplePairs() public {
        factory = new MiniAMMFactory();

        // Create first pair
        address expectedToken0_1 = address(token0) < address(token1) ? address(token0) : address(token1);
        address expectedToken1_1 = address(token0) < address(token1) ? address(token1) : address(token0);

        vm.expectEmit(true, true, false, false);
        emit PairCreated(expectedToken0_1, expectedToken1_1, address(0), 1);
        
        address pair1 = factory.createPair(address(token0), address(token1));

        // Create second pair with new token
        MockERC20 token2 = new MockERC20("Token C", "TKC");
        
        address expectedToken0_2 = address(token0) < address(token2) ? address(token0) : address(token2);
        address expectedToken1_2 = address(token0) < address(token2) ? address(token2) : address(token0);

        vm.expectEmit(true, true, false, false);
        emit PairCreated(expectedToken0_2, expectedToken1_2, address(0), 2); // pairNumber should be 2

        address pair2 = factory.createPair(address(token0), address(token2));

        // Verify both pairs are different and factory state is correct
        assertTrue(pair1 != pair2);
        assertEq(factory.allPairsLength(), 2);
    }
}
