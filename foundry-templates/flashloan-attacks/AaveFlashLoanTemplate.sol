// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";

/// @title AaveFlashLoanTemplate
/// @author ep0chzer0
/// @notice Template for testing Aave V3 flash loan attack vectors
/// @dev Fork mainnet to use: forge test --fork-url $ETH_RPC_URL

interface IPoolAddressesProvider {
    function getPool() external view returns (address);
}

interface IPool {
    function flashLoanSimple(
        address receiverAddress,
        address asset,
        uint256 amount,
        bytes calldata params,
        uint16 referralCode
    ) external;
}

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}

abstract contract AaveFlashLoanTemplate is Test {
    // Mainnet Aave V3
    address constant AAVE_POOL = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;

    // Common tokens
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant DAI = 0x6B175474E89094C44Da98b954EeecdAC5BBa8F85;

    // Flash loan state
    bool internal _inFlashLoan;
    address internal _flashLoanToken;
    uint256 internal _flashLoanAmount;

    /*//////////////////////////////////////////////////////////////
                          FLASH LOAN EXECUTION
    //////////////////////////////////////////////////////////////*/

    /// @notice Execute a flash loan attack
    /// @param token Token to borrow
    /// @param amount Amount to borrow
    function _executeFlashLoan(address token, uint256 amount) internal {
        _flashLoanToken = token;
        _flashLoanAmount = amount;
        _inFlashLoan = true;

        IPool(AAVE_POOL).flashLoanSimple(
            address(this),
            token,
            amount,
            "", // params - passed to executeOperation
            0   // referralCode
        );

        _inFlashLoan = false;
    }

    /// @notice Aave callback - implement your attack logic here
    /// @dev Override this in your test contract
    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external virtual returns (bool) {
        require(msg.sender == AAVE_POOL, "Invalid caller");
        require(initiator == address(this), "Invalid initiator");

        // ============================================
        // YOUR ATTACK LOGIC HERE
        // ============================================
        _onFlashLoanReceived(asset, amount, premium, params);

        // Approve repayment (amount + premium)
        uint256 amountOwed = amount + premium;
        IERC20(asset).approve(AAVE_POOL, amountOwed);

        return true;
    }

    /// @notice Override this with your attack logic
    function _onFlashLoanReceived(
        address asset,
        uint256 amount,
        uint256 premium,
        bytes calldata params
    ) internal virtual;

    /*//////////////////////////////////////////////////////////////
                            TEST HELPERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Calculate required profit to cover flash loan fee
    /// @param amount The borrowed amount
    /// @return minProfit Minimum profit needed (Aave fee is 0.05%)
    function _minProfitRequired(uint256 amount) internal pure returns (uint256) {
        return (amount * 5) / 10000; // 0.05% fee
    }

    /// @notice Check if attack was profitable after fees
    function _isProfitable(
        address token,
        uint256 balanceBefore,
        uint256 flashLoanAmount
    ) internal view returns (bool, uint256 profit) {
        uint256 balanceAfter = IERC20(token).balanceOf(address(this));
        uint256 fee = _minProfitRequired(flashLoanAmount);

        if (balanceAfter > balanceBefore + fee) {
            profit = balanceAfter - balanceBefore - fee;
            return (true, profit);
        }
        return (false, 0);
    }
}

/// @title ExampleAaveFlashLoanTest
/// @notice Example showing how to use the template
contract ExampleAaveFlashLoanTest is AaveFlashLoanTemplate {
    address targetProtocol;
    uint256 balanceBefore;

    function setUp() public {
        // Fork mainnet
        vm.createSelectFork(vm.envString("ETH_RPC_URL"));
    }

    function test_FlashLoanAttack() public {
        balanceBefore = IERC20(WETH).balanceOf(address(this));

        // Execute flash loan with 1000 WETH
        _executeFlashLoan(WETH, 1000 ether);

        // Check profitability
        (bool profitable, uint256 profit) = _isProfitable(WETH, balanceBefore, 1000 ether);

        if (profitable) {
            emit log_named_uint("Profit", profit);
        }
    }

    function _onFlashLoanReceived(
        address asset,
        uint256 amount,
        uint256 premium,
        bytes calldata /* params */
    ) internal override {
        // Example: Price manipulation attack
        // 1. Use borrowed funds to manipulate price
        // 2. Exploit the manipulated price
        // 3. Return funds + fee

        // YOUR ATTACK LOGIC HERE
    }
}
