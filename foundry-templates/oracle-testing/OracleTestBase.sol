// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";

/// @title OracleTestBase
/// @author ep0chzer0
/// @notice Base contract for testing oracle integrations and timestamp vulnerabilities
abstract contract OracleTestBase is Test {

    /*//////////////////////////////////////////////////////////////
                            TIMESTAMP HELPERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Warp to a specific timestamp and check oracle staleness
    /// @param targetTimestamp The timestamp to warp to
    function warpTo(uint256 targetTimestamp) internal {
        vm.warp(targetTimestamp);
    }

    /// @notice Skip forward by a duration
    /// @param duration Seconds to skip forward
    function skipTime(uint256 duration) internal {
        skip(duration);
    }

    /// @notice Test oracle behavior at epoch boundaries
    /// @param epochDuration The duration of each epoch
    /// @param epochCount Number of epochs to test
    function testEpochBoundaries(uint256 epochDuration, uint256 epochCount) internal {
        uint256 startTime = block.timestamp;
        for (uint256 i = 0; i < epochCount; i++) {
            // Test at epoch start
            warpTo(startTime + (epochDuration * i));
            _onEpochBoundary(i, true);

            // Test at epoch end (1 second before next)
            warpTo(startTime + (epochDuration * (i + 1)) - 1);
            _onEpochBoundary(i, false);
        }
    }

    /// @notice Override to implement epoch boundary tests
    function _onEpochBoundary(uint256 epochIndex, bool isStart) internal virtual {}

    /*//////////////////////////////////////////////////////////////
                          STALENESS TESTING
    //////////////////////////////////////////////////////////////*/

    /// @notice Test oracle staleness at various intervals
    /// @param maxStaleness Maximum staleness allowed by the oracle
    function testStalenessWindow(uint256 maxStaleness) internal {
        uint256 startTime = block.timestamp;

        // Fresh data
        _checkOracleAtStaleness(0, true);

        // Just within bounds
        warpTo(startTime + maxStaleness - 1);
        _checkOracleAtStaleness(maxStaleness - 1, true);

        // At boundary
        warpTo(startTime + maxStaleness);
        _checkOracleAtStaleness(maxStaleness, false);

        // Beyond bounds
        warpTo(startTime + maxStaleness + 1);
        _checkOracleAtStaleness(maxStaleness + 1, false);
    }

    /// @notice Override to implement staleness checks
    function _checkOracleAtStaleness(uint256 staleness, bool shouldBeValid) internal virtual {}

    /*//////////////////////////////////////////////////////////////
                        CROSS-CHAIN HELPERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Fork to a different chain for cross-chain testing
    /// @param rpcUrl The RPC URL of the target chain
    /// @return forkId The fork ID
    function forkChain(string memory rpcUrl) internal returns (uint256 forkId) {
        forkId = vm.createFork(rpcUrl);
        vm.selectFork(forkId);
    }

    /// @notice Test signature replay across chains
    /// @param chainIds Array of chain IDs to test
    function testCrossChainReplay(uint256[] memory chainIds) internal {
        for (uint256 i = 0; i < chainIds.length; i++) {
            vm.chainId(chainIds[i]);
            _onChainSwitch(chainIds[i]);
        }
    }

    /// @notice Override to implement cross-chain tests
    function _onChainSwitch(uint256 chainId) internal virtual {}

    /*//////////////////////////////////////////////////////////////
                         PRICE MANIPULATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Simulate price deviation
    /// @param basePrice The starting price
    /// @param deviationBps Deviation in basis points (100 = 1%)
    /// @param up True for increase, false for decrease
    function simulatePriceDeviation(
        uint256 basePrice,
        uint256 deviationBps,
        bool up
    ) internal pure returns (uint256) {
        uint256 deviation = (basePrice * deviationBps) / 10000;
        return up ? basePrice + deviation : basePrice - deviation;
    }

    /// @notice Test oracle behavior under various price conditions
    function testPriceExtremes(uint256 normalPrice) internal {
        // Zero price
        _onPriceUpdate(0);

        // Normal price
        _onPriceUpdate(normalPrice);

        // Very large price
        _onPriceUpdate(type(uint128).max);

        // Max uint256
        _onPriceUpdate(type(uint256).max);
    }

    /// @notice Override to implement price update tests
    function _onPriceUpdate(uint256 price) internal virtual {}
}
