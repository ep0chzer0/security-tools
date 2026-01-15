// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";

/// @title AccessControlTestBase
/// @author ep0chzer0
/// @notice Base contract for testing access control vulnerabilities
abstract contract AccessControlTestBase is Test {

    /*//////////////////////////////////////////////////////////////
                           COMMON ROLES
    //////////////////////////////////////////////////////////////*/

    bytes32 constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    /*//////////////////////////////////////////////////////////////
                        UNAUTHORIZED ACCESS TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test that a function reverts for unauthorized callers
    /// @param target Contract to test
    /// @param calldata_ Calldata for the protected function
    /// @param authorizedUser An address that SHOULD have access
    /// @param unauthorizedUser An address that should NOT have access
    function testUnauthorizedAccess(
        address target,
        bytes memory calldata_,
        address authorizedUser,
        address unauthorizedUser
    ) internal returns (bool properlyProtected) {
        // Test unauthorized user (should fail)
        vm.prank(unauthorizedUser);
        (bool shouldFail,) = target.call(calldata_);

        // Test authorized user (should succeed)
        vm.prank(authorizedUser);
        (bool shouldSucceed,) = target.call(calldata_);

        properlyProtected = !shouldFail && shouldSucceed;

        if (!properlyProtected) {
            if (shouldFail) {
                emit log("VULNERABLE: Unauthorized user could call protected function");
            }
            if (!shouldSucceed) {
                emit log("WARNING: Authorized user could not call function");
            }
        }
    }

    /// @notice Test multiple addresses for unauthorized access
    function testMultipleUnauthorized(
        address target,
        bytes memory calldata_,
        address[] memory testAddresses
    ) internal returns (address[] memory vulnerableAddresses) {
        uint256 vulnerableCount = 0;
        address[] memory tempVulnerable = new address[](testAddresses.length);

        for (uint256 i = 0; i < testAddresses.length; i++) {
            vm.prank(testAddresses[i]);
            (bool success,) = target.call(calldata_);

            if (success) {
                tempVulnerable[vulnerableCount] = testAddresses[i];
                vulnerableCount++;
            }
        }

        // Copy to correctly sized array
        vulnerableAddresses = new address[](vulnerableCount);
        for (uint256 i = 0; i < vulnerableCount; i++) {
            vulnerableAddresses[i] = tempVulnerable[i];
        }
    }

    /*//////////////////////////////////////////////////////////////
                         OWNERSHIP TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test two-step ownership transfer
    function testTwoStepOwnershipTransfer(
        address target,
        address currentOwner,
        address newOwner
    ) internal returns (bool secure) {
        // Try direct ownership transfer by non-owner
        vm.prank(newOwner);
        (bool directTransfer,) = target.call(
            abi.encodeWithSignature("transferOwnership(address)", newOwner)
        );

        // If direct transfer worked for non-owner, it's vulnerable
        if (directTransfer) {
            emit log("VULNERABLE: Non-owner can transfer ownership");
            return false;
        }

        // Proper two-step: owner initiates, new owner accepts
        vm.prank(currentOwner);
        (bool initiate,) = target.call(
            abi.encodeWithSignature("transferOwnership(address)", newOwner)
        );

        // Check if pending owner is set (two-step) or immediate (one-step)
        (bool hasPending, bytes memory pendingData) = target.staticcall(
            abi.encodeWithSignature("pendingOwner()")
        );

        secure = hasPending && abi.decode(pendingData, (address)) == newOwner;

        if (!secure && initiate) {
            emit log("WARNING: One-step ownership transfer (no pending owner)");
        }
    }

    /// @notice Test that ownership cannot be renounced accidentally
    function testOwnershipRenounce(
        address target,
        address owner
    ) internal returns (bool canRenounce) {
        vm.prank(owner);
        (canRenounce,) = target.call(
            abi.encodeWithSignature("renounceOwnership()")
        );

        if (canRenounce) {
            emit log("WARNING: Ownership can be renounced - verify this is intentional");
        }
    }

    /*//////////////////////////////////////////////////////////////
                         INITIALIZER TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test that initializer can only be called once
    function testInitializerProtection(
        address target,
        bytes memory initCalldata
    ) internal returns (bool protected) {
        // First call should succeed (or already initialized)
        (bool first,) = target.call(initCalldata);

        // Second call should fail
        (bool second,) = target.call(initCalldata);

        protected = !second;

        if (!protected) {
            emit log("VULNERABLE: Initializer can be called multiple times");
        }
    }

    /// @notice Test that implementation contract cannot be initialized
    function testImplementationInitializer(
        address implementation,
        bytes memory initCalldata
    ) internal returns (bool vulnerable) {
        (vulnerable,) = implementation.call(initCalldata);

        if (vulnerable) {
            emit log("VULNERABLE: Implementation contract can be initialized directly");
        }
    }

    /*//////////////////////////////////////////////////////////////
                          ROLE ESCALATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Test for role self-assignment
    function testRoleSelfAssignment(
        address target,
        bytes32 role,
        address attacker
    ) internal returns (bool vulnerable) {
        vm.prank(attacker);
        (vulnerable,) = target.call(
            abi.encodeWithSignature("grantRole(bytes32,address)", role, attacker)
        );

        if (vulnerable) {
            emit log("VULNERABLE: Users can grant roles to themselves");
        }
    }

    /// @notice Test for admin role escalation
    function testAdminEscalation(
        address target,
        address regularUser
    ) internal returns (bool vulnerable) {
        vm.prank(regularUser);
        (vulnerable,) = target.call(
            abi.encodeWithSignature("grantRole(bytes32,address)", DEFAULT_ADMIN_ROLE, regularUser)
        );

        if (vulnerable) {
            emit log("CRITICAL: Users can escalate to admin role");
        }
    }

    /*//////////////////////////////////////////////////////////////
                            HELPERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Generate array of common test addresses
    function _getTestAddresses() internal pure returns (address[] memory) {
        address[] memory addrs = new address[](5);
        addrs[0] = address(0);                    // Zero address
        addrs[1] = address(1);                    // Precompile range
        addrs[2] = address(0xdead);               // Common burn address
        addrs[3] = address(uint160(uint256(keccak256("attacker"))));
        addrs[4] = address(uint160(uint256(keccak256("random"))));
        return addrs;
    }
}
