// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";

/// @title FlashLoanTestBase
/// @author ep0chzer0
/// @notice Base contract for testing flash loan attack vectors
abstract contract FlashLoanTestBase is Test {
    /*//////////////////////////////////////////////////////////////
                            FLASH LOAN PROVIDERS
    //////////////////////////////////////////////////////////////*/

    // Mainnet addresses
    address constant AAVE_V3_POOL = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;
    address constant UNISWAP_V3_FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    address constant BALANCER_VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;

    /*//////////////////////////////////////////////////////////////
                          FLASH LOAN SIMULATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Simulate having a large token balance (like a flash loan)
    /// @param token The token to simulate borrowing
    /// @param amount The amount to borrow
    function simulateFlashLoan(
        address token,
        uint256 amount
    ) internal {
        deal(token, address(this), amount);
    }

    /// @notice Simulate flash loan with callback pattern
    /// @param token Token to borrow
    /// @param amount Amount to borrow
    /// @param target Contract to attack
    /// @param attackCalldata Calldata for the attack
    function executeFlashLoanAttack(
        address token,
        uint256 amount,
        address target,
        bytes memory attackCalldata
    ) internal returns (bool success, bytes memory result) {
        // Simulate receiving flash loaned funds
        uint256 balanceBefore = _getBalance(token, address(this));
        deal(token, address(this), balanceBefore + amount);

        // Execute attack
        (success, result) = target.call(attackCalldata);

        // Simulate repaying flash loan (in real scenario, must repay + fee)
        // If attack profitable, attacker keeps the difference
    }

    /*//////////////////////////////////////////////////////////////
                        PRICE MANIPULATION PATTERNS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test oracle manipulation via flash loan
    /// @param oracle The oracle contract
    /// @param pool The liquidity pool to manipulate
    /// @param token Token to use for manipulation
    /// @param amount Flash loan amount
    function testOracleManipulation(
        address oracle,
        address pool,
        address token,
        uint256 amount
    ) internal returns (uint256 priceBefore, uint256 priceAfter) {
        // Get price before
        priceBefore = _getOraclePrice(oracle);

        // Simulate large swap to move price
        simulateFlashLoan(token, amount);

        // Perform swap (implementation depends on pool type)
        _manipulatePool(pool, token, amount);

        // Get price after manipulation
        priceAfter = _getOraclePrice(oracle);
    }

    /// @notice Test sandwich attack profitability
    /// @param pool The pool being traded on
    /// @param victimAmount The victim's swap amount (for simulation)
    function testSandwichAttack(
        address pool,
        uint256 victimAmount
    ) internal returns (uint256 profit) {
        uint256 balanceBefore = address(this).balance;

        // Front-run: buy before victim
        _executeFrontrun(pool);

        // Victim transaction executes (simulated)
        // Override _simulateVictimTx to implement victim's swap
        _simulateVictimTx(pool, victimAmount);

        // Back-run: sell after victim
        _executeBackrun(pool);

        uint256 balanceAfter = address(this).balance;
        profit = balanceAfter > balanceBefore ? balanceAfter - balanceBefore : 0;
    }

    /// @notice Override to simulate victim's transaction
    function _simulateVictimTx(
        address pool,
        uint256 amount
    ) internal virtual {}

    /*//////////////////////////////////////////////////////////////
                         LIQUIDATION ATTACKS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test flash loan liquidation attack
    /// @param lendingProtocol The lending protocol to attack
    /// @param targetUser User to liquidate
    /// @param collateralToken Collateral token
    /// @param debtToken Debt token
    function testFlashLoanLiquidation(
        address lendingProtocol,
        address targetUser,
        address collateralToken,
        address debtToken,
        uint256 repayAmount
    ) internal returns (uint256 profit) {
        uint256 balanceBefore = _getBalance(collateralToken, address(this));

        // Flash loan the debt token
        simulateFlashLoan(debtToken, repayAmount);

        // Liquidate the user
        _executeLiquidation(lendingProtocol, targetUser, debtToken, collateralToken, repayAmount);

        uint256 balanceAfter = _getBalance(collateralToken, address(this));
        profit = balanceAfter - balanceBefore;
    }

    /*//////////////////////////////////////////////////////////////
                          GOVERNANCE ATTACKS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test flash loan governance attack
    /// @param governanceToken Token used for voting
    /// @param governor Governor contract
    /// @param proposalId Proposal to vote on
    /// @param amount Amount to flash loan for voting power
    function testGovernanceAttack(
        address governanceToken,
        address governor,
        uint256 proposalId,
        uint256 amount
    ) internal returns (bool votePassed) {
        // Flash loan governance tokens
        simulateFlashLoan(governanceToken, amount);

        // Delegate to self (if required)
        _delegateVotes(governanceToken, address(this));

        // Cast vote
        _castVote(governor, proposalId, true);

        // Check if vote changed outcome
        votePassed = _isProposalPassing(governor, proposalId);
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL HELPERS
    //////////////////////////////////////////////////////////////*/

    function _getBalance(
        address token,
        address account
    ) internal view returns (uint256) {
        (bool success, bytes memory data) =
            token.staticcall(abi.encodeWithSignature("balanceOf(address)", account));
        return success ? abi.decode(data, (uint256)) : 0;
    }

    // Override these in your specific test implementations
    function _getOraclePrice(
        address oracle
    ) internal view virtual returns (uint256);
    function _manipulatePool(
        address pool,
        address token,
        uint256 amount
    ) internal virtual;
    function _executeFrontrun(
        address pool
    ) internal virtual;
    function _executeBackrun(
        address pool
    ) internal virtual;
    function _executeLiquidation(
        address protocol,
        address user,
        address debtToken,
        address collateralToken,
        uint256 amount
    ) internal virtual;
    function _delegateVotes(
        address token,
        address delegatee
    ) internal virtual;
    function _castVote(
        address governor,
        uint256 proposalId,
        bool support
    ) internal virtual;
    function _isProposalPassing(
        address governor,
        uint256 proposalId
    ) internal view virtual returns (bool);
}
