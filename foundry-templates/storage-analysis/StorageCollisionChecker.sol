// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";

/// @title StorageCollisionChecker
/// @author ep0chzer0
/// @notice Utilities for detecting storage collisions in upgradeable contracts
abstract contract StorageCollisionChecker is Test {
    /*//////////////////////////////////////////////////////////////
                         EIP-1967 SLOTS
    //////////////////////////////////////////////////////////////*/

    // EIP-1967 standard slots
    bytes32 constant IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    bytes32 constant ADMIN_SLOT =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
    bytes32 constant BEACON_SLOT =
        0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    // OpenZeppelin Initializable slot
    bytes32 constant INITIALIZABLE_SLOT =
        0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00;

    /*//////////////////////////////////////////////////////////////
                       STORAGE LAYOUT ANALYSIS
    //////////////////////////////////////////////////////////////*/

    /// @notice Read storage at a specific slot
    function readSlot(
        address target,
        bytes32 slot
    ) internal view returns (bytes32) {
        return vm.load(target, slot);
    }

    /// @notice Read storage at a specific slot as address
    function readSlotAsAddress(
        address target,
        bytes32 slot
    ) internal view returns (address) {
        return address(uint160(uint256(vm.load(target, slot))));
    }

    /// @notice Read storage at a specific slot as uint256
    function readSlotAsUint(
        address target,
        bytes32 slot
    ) internal view returns (uint256) {
        return uint256(vm.load(target, slot));
    }

    /// @notice Calculate mapping slot for a given key
    function getMappingSlot(
        bytes32 baseSlot,
        address key
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(key, baseSlot));
    }

    /// @notice Calculate mapping slot for uint key
    function getMappingSlot(
        bytes32 baseSlot,
        uint256 key
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(key, baseSlot));
    }

    /// @notice Calculate dynamic array element slot
    function getArraySlot(
        bytes32 baseSlot,
        uint256 index
    ) internal pure returns (bytes32) {
        return bytes32(uint256(keccak256(abi.encode(baseSlot))) + index);
    }

    /*//////////////////////////////////////////////////////////////
                      COLLISION DETECTION
    //////////////////////////////////////////////////////////////*/

    /// @notice Check if implementation upgrade would cause storage collision
    /// @param proxy The proxy contract
    /// @param newImplementation The new implementation to check
    /// @param slotsToCheck Array of storage slots to verify
    function checkUpgradeCollision(
        address proxy,
        address newImplementation,
        bytes32[] memory slotsToCheck
    ) internal returns (bool hasCollision, bytes32[] memory collidingSlots) {
        uint256 collisionCount = 0;
        bytes32[] memory tempCollisions = new bytes32[](slotsToCheck.length);

        for (uint256 i = 0; i < slotsToCheck.length; i++) {
            bytes32 slot = slotsToCheck[i];

            // Read current value from proxy
            bytes32 proxyValue = readSlot(proxy, slot);

            // Read value from implementation (should be empty for proper upgrade)
            bytes32 implValue = readSlot(newImplementation, slot);

            // If implementation has data in this slot, potential collision
            if (implValue != bytes32(0) && proxyValue != bytes32(0)) {
                tempCollisions[collisionCount] = slot;
                collisionCount++;
                emit log_named_bytes32("Storage collision at slot", slot);
            }
        }

        hasCollision = collisionCount > 0;
        collidingSlots = new bytes32[](collisionCount);
        for (uint256 i = 0; i < collisionCount; i++) {
            collidingSlots[i] = tempCollisions[i];
        }
    }

    /// @notice Verify EIP-1967 slots are not overwritten
    function checkEIP1967Slots(
        address proxy
    ) internal view returns (bool safe) {
        // These slots should only contain addresses or be empty
        bytes32 implValue = readSlot(proxy, IMPLEMENTATION_SLOT);
        bytes32 adminValue = readSlot(proxy, ADMIN_SLOT);
        bytes32 beaconValue = readSlot(proxy, BEACON_SLOT);

        // Check that values are valid addresses (upper bytes should be zero)
        bool implValid = uint256(implValue) <= type(uint160).max || implValue == bytes32(0);
        bool adminValid = uint256(adminValue) <= type(uint160).max || adminValue == bytes32(0);
        bool beaconValid = uint256(beaconValue) <= type(uint160).max || beaconValue == bytes32(0);

        safe = implValid && adminValid && beaconValid;
    }

    /// @notice Check for uninitialized proxy vulnerability
    function checkUninitializedProxy(
        address proxy
    ) internal view returns (bool vulnerable) {
        address impl = readSlotAsAddress(proxy, IMPLEMENTATION_SLOT);

        // If implementation is zero, proxy is uninitialized
        if (impl == address(0)) {
            return true;
        }

        // Check if proxy has any code
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(proxy)
        }

        // Implementation set but no code = potentially destructed
        vulnerable = codeSize == 0;
    }

    /*//////////////////////////////////////////////////////////////
                       STORAGE GAP VERIFICATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Verify storage gap is present and correct size
    /// @param target Contract to check
    /// @param gapSlotStart First slot of the gap
    /// @param expectedGapSize Expected number of slots in gap (usually 50)
    function verifyStorageGap(
        address target,
        bytes32 gapSlotStart,
        uint256 expectedGapSize
    ) internal view returns (bool correct, uint256 actualGapSize) {
        actualGapSize = 0;

        // Count consecutive zero slots
        for (uint256 i = 0; i < expectedGapSize + 10; i++) {
            bytes32 slot = bytes32(uint256(gapSlotStart) + i);
            bytes32 value = readSlot(target, slot);

            if (value == bytes32(0)) {
                actualGapSize++;
            } else {
                break;
            }
        }

        correct = actualGapSize >= expectedGapSize;
    }

    /*//////////////////////////////////////////////////////////////
                          STORAGE DUMP
    //////////////////////////////////////////////////////////////*/

    /// @notice Dump storage slots for analysis
    function dumpStorage(
        address target,
        uint256 startSlot,
        uint256 count
    ) internal view returns (bytes32[] memory values) {
        values = new bytes32[](count);

        for (uint256 i = 0; i < count; i++) {
            values[i] = readSlot(target, bytes32(startSlot + i));
        }
    }

    /// @notice Find non-zero storage slots
    function findNonZeroSlots(
        address target,
        uint256 startSlot,
        uint256 count
    ) internal view returns (bytes32[] memory slots, bytes32[] memory values) {
        uint256 nonZeroCount = 0;
        bytes32[] memory tempSlots = new bytes32[](count);
        bytes32[] memory tempValues = new bytes32[](count);

        for (uint256 i = 0; i < count; i++) {
            bytes32 slot = bytes32(startSlot + i);
            bytes32 value = readSlot(target, slot);

            if (value != bytes32(0)) {
                tempSlots[nonZeroCount] = slot;
                tempValues[nonZeroCount] = value;
                nonZeroCount++;
            }
        }

        slots = new bytes32[](nonZeroCount);
        values = new bytes32[](nonZeroCount);
        for (uint256 i = 0; i < nonZeroCount; i++) {
            slots[i] = tempSlots[i];
            values[i] = tempValues[i];
        }
    }
}
