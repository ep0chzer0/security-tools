// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";

/// @title ReentrancyTestBase
/// @author ep0chzer0
/// @notice Base contract for testing reentrancy vulnerabilities
abstract contract ReentrancyTestBase is Test {

    /*//////////////////////////////////////////////////////////////
                           ATTACK CONTRACTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Deploy a single-function reentrancy attacker
    function deployAttacker(
        address target,
        bytes memory attackCalldata
    ) internal returns (SingleReentrant) {
        return new SingleReentrant(target, attackCalldata);
    }

    /// @notice Deploy a cross-function reentrancy attacker
    function deployCrossAttacker(
        address target,
        bytes memory initialCalldata,
        bytes memory reentrantCalldata
    ) internal returns (CrossReentrant) {
        return new CrossReentrant(target, initialCalldata, reentrantCalldata);
    }

    /*//////////////////////////////////////////////////////////////
                          REENTRANCY PATTERNS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test single-function reentrancy
    /// @param target Contract to attack
    /// @param attackCalldata Calldata for the vulnerable function
    /// @param value ETH to send with attack
    function testSingleReentrancy(
        address target,
        bytes memory attackCalldata,
        uint256 value
    ) internal returns (bool vulnerable) {
        SingleReentrant attacker = deployAttacker(target, attackCalldata);
        vm.deal(address(attacker), value);

        uint256 targetBalBefore = target.balance;

        try attacker.attack{value: value}() {
            // Check if attacker drained more than deposited
            vulnerable = address(attacker).balance > value;
        } catch {
            vulnerable = false;
        }

        _onReentrancyResult("single", vulnerable, targetBalBefore, target.balance);
    }

    /// @notice Test cross-function reentrancy
    function testCrossReentrancy(
        address target,
        bytes memory initialCalldata,
        bytes memory reentrantCalldata,
        uint256 value
    ) internal returns (bool vulnerable) {
        CrossReentrant attacker = deployCrossAttacker(target, initialCalldata, reentrantCalldata);
        vm.deal(address(attacker), value);

        uint256 targetBalBefore = target.balance;

        try attacker.attack{value: value}() {
            vulnerable = address(attacker).balance > value;
        } catch {
            vulnerable = false;
        }

        _onReentrancyResult("cross", vulnerable, targetBalBefore, target.balance);
    }

    /// @notice Test read-only reentrancy
    function testReadOnlyReentrancy(
        address target,
        bytes memory triggerCalldata,
        bytes memory viewCalldata
    ) internal returns (bool inconsistent) {
        ReadOnlyReentrant attacker = new ReadOnlyReentrant(target, viewCalldata);

        // Get value before
        (bool s1, bytes memory before) = target.staticcall(viewCalldata);
        require(s1, "View call failed");

        // Trigger reentrancy and capture mid-state
        try attacker.attack(triggerCalldata) {
            bytes memory during = attacker.capturedValue();
            inconsistent = keccak256(before) != keccak256(during);
        } catch {
            inconsistent = false;
        }

        _onReentrancyResult("readonly", inconsistent, 0, 0);
    }

    /// @notice Override to handle reentrancy test results
    function _onReentrancyResult(
        string memory attackType,
        bool vulnerable,
        uint256 balBefore,
        uint256 balAfter
    ) internal virtual {}
}

/// @notice Single-function reentrancy attacker
contract SingleReentrant {
    address public target;
    bytes public attackCalldata;
    uint256 public attackCount;
    uint256 public maxAttacks = 10;

    constructor(address _target, bytes memory _calldata) {
        target = _target;
        attackCalldata = _calldata;
    }

    function attack() external payable {
        (bool success,) = target.call{value: msg.value}(attackCalldata);
        require(success, "Initial attack failed");
    }

    receive() external payable {
        if (attackCount < maxAttacks && target.balance > 0) {
            attackCount++;
            (bool success,) = target.call(attackCalldata);
            // Don't require success - may run out of funds
            success;
        }
    }
}

/// @notice Cross-function reentrancy attacker
contract CrossReentrant {
    address public target;
    bytes public initialCalldata;
    bytes public reentrantCalldata;
    bool public inAttack;

    constructor(address _target, bytes memory _initial, bytes memory _reentrant) {
        target = _target;
        initialCalldata = _initial;
        reentrantCalldata = _reentrant;
    }

    function attack() external payable {
        inAttack = true;
        (bool success,) = target.call{value: msg.value}(initialCalldata);
        require(success, "Initial call failed");
        inAttack = false;
    }

    receive() external payable {
        if (inAttack) {
            (bool success,) = target.call(reentrantCalldata);
            success;
        }
    }
}

/// @notice Read-only reentrancy attacker
contract ReadOnlyReentrant {
    address public target;
    bytes public viewCalldata;
    bytes public capturedValue;

    constructor(address _target, bytes memory _viewCalldata) {
        target = _target;
        viewCalldata = _viewCalldata;
    }

    function attack(bytes calldata triggerCalldata) external {
        (bool success,) = target.call(triggerCalldata);
        require(success, "Trigger failed");
    }

    receive() external payable {
        // Capture view state during reentrancy
        (bool success, bytes memory data) = target.staticcall(viewCalldata);
        if (success) {
            capturedValue = data;
        }
    }
}
