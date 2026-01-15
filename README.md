# Security Tools

Smart contract security utilities, Foundry templates, and audit helpers.

## Contents

### Foundry Templates
- **[oracle-testing](./foundry-templates/oracle-testing/)** - Templates for testing oracle integrations and timestamp manipulation
- **[reentrancy-patterns](./foundry-templates/reentrancy-patterns/)** - Common reentrancy attack patterns for testing
- **[access-control](./foundry-templates/access-control/)** - Access control vulnerability tests
- **[flashloan-attacks](./foundry-templates/flashloan-attacks/)** - Flash loan attack vector templates (Aave V3)
- **[storage-analysis](./foundry-templates/storage-analysis/)** - Storage collision detection for upgradeable contracts

### Utilities
- **[signature-utils](./utils/signature-utils/)** - Signature replay and validation helpers

### Checklists
- **[audit-checklist](./checklists/audit-checklist.md)** - Smart contract audit checklist
- **[defi-checklist](./checklists/defi-checklist.md)** - DeFi-specific security checklist

---

## Installation

```bash
forge install ep0chzer0/security-tools
```

## Usage

```solidity
// Oracle testing
import {OracleTestBase} from "security-tools/foundry-templates/oracle-testing/OracleTestBase.sol";

// Flash loan attacks
import {AaveFlashLoanTemplate} from "security-tools/foundry-templates/flashloan-attacks/AaveFlashLoanTemplate.sol";

// Access control testing
import {AccessControlTestBase} from "security-tools/foundry-templates/access-control/AccessControlTestBase.sol";

// Storage analysis
import {StorageCollisionChecker} from "security-tools/foundry-templates/storage-analysis/StorageCollisionChecker.sol";

// Reentrancy testing
import {ReentrancyTestBase} from "security-tools/foundry-templates/reentrancy-patterns/ReentrancyTestBase.sol";

// Signature analysis
import {SignatureAnalyzer} from "security-tools/utils/signature-utils/SignatureAnalyzer.sol";
```

## Templates Overview

### Oracle Testing
Test oracle integrations for staleness, timestamp manipulation, cross-chain replay, and price extremes.

### Flash Loan Attacks
Ready-to-use templates for testing flash loan attack vectors including:
- Price manipulation
- Liquidation attacks
- Governance attacks
- Sandwich attacks

### Access Control
Test access control vulnerabilities:
- Unauthorized access
- Role escalation
- Ownership transfer security
- Initializer protection

### Storage Analysis
Detect storage collisions in upgradeable contracts:
- EIP-1967 slot verification
- Storage gap validation
- Upgrade collision detection

### Reentrancy Patterns
Test for reentrancy vulnerabilities:
- Single-function reentrancy
- Cross-function reentrancy
- Read-only reentrancy

---

## License

MIT
