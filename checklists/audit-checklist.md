# Smart Contract Audit Checklist

## Access Control
- [ ] Functions have appropriate visibility (public/external/internal/private)
- [ ] Admin functions protected by access control
- [ ] Role-based permissions properly implemented
- [ ] No unprotected initializers
- [ ] Ownership transfer is two-step

## Reentrancy
- [ ] CEI pattern followed (Checks-Effects-Interactions)
- [ ] ReentrancyGuard used where needed
- [ ] Cross-function reentrancy considered
- [ ] Read-only reentrancy in view functions
- [ ] Callbacks don't expose state inconsistencies

## Integer Handling
- [ ] SafeMath or Solidity 0.8+ overflow protection
- [ ] Unchecked blocks reviewed carefully
- [ ] Division before multiplication avoided
- [ ] Precision loss in calculations acceptable
- [ ] Type casting checked (uint256 to uint128, etc.)

## External Calls
- [ ] Return values checked
- [ ] Low-level calls (.call) handle failures
- [ ] Delegatecall targets are trusted
- [ ] No arbitrary external calls with user input
- [ ] Gas limits on external calls where needed

## Oracle Integration
- [ ] Staleness checks implemented
- [ ] Price deviation bounds checked
- [ ] Fallback oracle available
- [ ] Decimal normalization correct
- [ ] No same-block manipulation possible

## Token Handling
- [ ] ERC20 transfer return values handled (SafeERC20)
- [ ] Fee-on-transfer tokens considered
- [ ] Rebasing tokens considered
- [ ] ERC777 hooks don't cause reentrancy
- [ ] Token decimals handled correctly

## Signatures
- [ ] Replay protection (nonces)
- [ ] Chain ID included in signed message
- [ ] Deadline/expiry enforced
- [ ] Signature malleability handled
- [ ] EIP-712 used correctly

## Proxy Patterns
- [ ] Storage layout collision prevented
- [ ] Initializer can only be called once
- [ ] Implementation cannot be destroyed
- [ ] Upgrade authorization secure
- [ ] Storage gaps for future variables

## Gas & DoS
- [ ] Unbounded loops avoided
- [ ] Pull over push for payments
- [ ] Gas griefing vectors closed
- [ ] Block gas limit considered
- [ ] Array length limits enforced

## Logic Errors
- [ ] Edge cases tested (0, max, boundaries)
- [ ] Off-by-one errors checked
- [ ] First depositor attacks prevented
- [ ] Flash loan attacks considered
- [ ] MEV/sandwich attack resistance

## Code Quality
- [ ] No compiler warnings
- [ ] Events emitted for state changes
- [ ] Error messages are descriptive
- [ ] NatSpec documentation complete
- [ ] Test coverage adequate
