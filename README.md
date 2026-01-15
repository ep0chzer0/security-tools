# Security Tools

Smart contract security utilities, Foundry templates, and audit helpers.

## Contents

### Foundry Templates
- **[oracle-testing](./foundry-templates/oracle-testing/)** - Templates for testing oracle integrations and timestamp manipulation
- **[reentrancy-patterns](./foundry-templates/reentrancy-patterns/)** - Common reentrancy attack patterns for testing
- **[access-control](./foundry-templates/access-control/)** - Access control vulnerability tests

### Utilities
- **[storage-analyzer](./utils/storage-analyzer/)** - Analyze contract storage layouts
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
import {OracleTestBase} from "security-tools/foundry-templates/oracle-testing/OracleTestBase.sol";

contract MyTest is OracleTestBase {
    // Your tests here
}
```

---

## License

MIT
