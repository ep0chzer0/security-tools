# DeFi Security Checklist

## Oracle Security
- [ ] Multiple oracle sources / fallbacks
- [ ] TWAP vs spot price consideration
- [ ] Staleness threshold appropriate
- [ ] Price bounds / circuit breakers
- [ ] Cross-chain oracle replay impossible
- [ ] Oracle update frontrunning mitigated
- [ ] Decimal handling across different feeds

## Lending Protocols
- [ ] Liquidation incentives balanced
- [ ] Bad debt socialization mechanism
- [ ] Interest rate model tested at extremes
- [ ] Collateral factor appropriate for asset volatility
- [ ] Flash loan attacks on liquidations
- [ ] Price manipulation during borrow/repay

## AMMs / DEXs
- [ ] Slippage protection enforced
- [ ] Deadline parameter respected
- [ ] LP token inflation attacks prevented
- [ ] Price impact calculations correct
- [ ] Sandwich attack resistance
- [ ] Constant product invariant maintained

## Vaults / Yield
- [ ] Share inflation / first depositor attack
- [ ] Vault token exchange rate manipulation
- [ ] Strategy migration security
- [ ] Emergency withdrawal mechanism
- [ ] Harvest frontrunning protection
- [ ] Yield calculation precision

## Bridges / Cross-Chain
- [ ] Message replay across chains
- [ ] Chain ID in all signed messages
- [ ] Finality assumptions correct
- [ ] Sequencer uptime for L2s
- [ ] Native token handling differences

## Staking / Rewards
- [ ] Reward rate manipulation
- [ ] Staking/unstaking delay attacks
- [ ] Reward calculation overflow
- [ ] Last-second deposits before rewards
- [ ] Abandoned rewards handling

## Governance
- [ ] Flash loan governance attacks
- [ ] Timelock duration appropriate
- [ ] Quorum manipulation
- [ ] Vote delegation security
- [ ] Proposal execution restrictions

## Token Economics
- [ ] Minting / burning access control
- [ ] Max supply enforcement
- [ ] Vesting schedule manipulation
- [ ] Fee-on-transfer compatibility
- [ ] Blacklist / pause functionality risks

## MEV Considerations
- [ ] Transaction ordering sensitivity
- [ ] Private mempool usage where needed
- [ ] Commit-reveal schemes for sensitive operations
- [ ] Auction mechanisms resistant to manipulation
- [ ] Batch processing for MEV reduction
