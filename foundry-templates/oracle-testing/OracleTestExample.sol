// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {OracleTestBase} from "./OracleTestBase.sol";

/// @title OracleTestExample
/// @author ep0chzer0
/// @notice Example showing how to use OracleTestBase
contract OracleTestExample is OracleTestBase {

    // Mock oracle for demonstration
    MockOracle oracle;

    function setUp() public {
        oracle = new MockOracle();
        oracle.setPrice(1000e8); // $1000 with 8 decimals
    }

    /*//////////////////////////////////////////////////////////////
                         STALENESS TESTS
    //////////////////////////////////////////////////////////////*/

    function test_OracleStaleness() public {
        // Oracle has 1 hour staleness window
        testStalenessWindow(1 hours);
    }

    function _checkOracleAtStaleness(
        uint256 staleness,
        bool shouldBeValid
    ) internal override {
        if (shouldBeValid) {
            // Should return valid price
            (uint256 price, bool valid) = oracle.getPrice();
            assertTrue(valid, "Oracle should be valid");
            assertGt(price, 0, "Price should be non-zero");
        } else {
            // Should revert or return invalid
            (, bool valid) = oracle.getPrice();
            assertFalse(valid, "Oracle should be stale");
        }
    }

    /*//////////////////////////////////////////////////////////////
                       EPOCH BOUNDARY TESTS
    //////////////////////////////////////////////////////////////*/

    function test_EpochBoundaries() public {
        // Test 24-hour epochs over 7 days
        testEpochBoundaries(24 hours, 7);
    }

    function _onEpochBoundary(
        uint256 epochIndex,
        bool isStart
    ) internal override {
        // Check oracle updates correctly at epoch boundaries
        if (isStart) {
            oracle.setPrice(1000e8 + (epochIndex * 10e8));
        }
        (uint256 price,) = oracle.getPrice();
        assertGt(price, 0);
    }

    /*//////////////////////////////////////////////////////////////
                      CROSS-CHAIN REPLAY TESTS
    //////////////////////////////////////////////////////////////*/

    function test_CrossChainReplay() public {
        uint256[] memory chains = new uint256[](3);
        chains[0] = 1;      // Ethereum
        chains[1] = 42161;  // Arbitrum
        chains[2] = 137;    // Polygon

        testCrossChainReplay(chains);
    }

    function _onChainSwitch(uint256 chainId) internal override {
        // Verify oracle data isn't replayed across chains
        assertEq(block.chainid, chainId);
        // Add chain-specific validation here
    }

    /*//////////////////////////////////////////////////////////////
                        PRICE EXTREME TESTS
    //////////////////////////////////////////////////////////////*/

    function test_PriceExtremes() public {
        testPriceExtremes(1000e8);
    }

    function _onPriceUpdate(uint256 price) internal override {
        oracle.setPrice(price);

        if (price == 0) {
            // Should handle zero price gracefully
            (, bool valid) = oracle.getPrice();
            assertFalse(valid, "Zero price should be invalid");
        } else {
            // Price was set successfully - verify it's readable
            (uint256 readPrice, bool valid) = oracle.getPrice();
            assertTrue(valid, "Price should be valid");
            assertEq(readPrice, price, "Price should match");
        }
    }
}

/// @notice Simple mock oracle for testing
contract MockOracle {
    uint256 public price;
    uint256 public lastUpdate;
    uint256 public constant STALENESS_THRESHOLD = 1 hours;

    function setPrice(uint256 _price) external {
        price = _price;
        lastUpdate = block.timestamp;
    }

    function getPrice() external view returns (uint256, bool valid) {
        valid = (block.timestamp - lastUpdate) < STALENESS_THRESHOLD && price > 0;
        return (price, valid);
    }
}
