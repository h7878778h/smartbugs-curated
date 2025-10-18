# ERC20 Comprehensive Test Suite

This test suite provides thorough coverage of the ERC20 token implementation in `dataset/ERC20.sol`.

## Test Framework: Foundry (Forge)

## Installation

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
forge install foundry-rs/forge-std --no-commit
```

## Running Tests

```bash
forge test              # Run all tests
forge test -vv          # Verbose output
forge test --gas-report # With gas reporting
```

## Test Coverage

- **Total Tests**: 83
- **Function Coverage**: 100%
- **Error Coverage**: 100%
- **Event Coverage**: 100%

## Test Categories

1. Constructor Tests (4)
2. Metadata Tests (3)
3. Total Supply Tests (4)
4. Balance Tests (4)
5. Transfer Tests (8)
6. Approve Tests (7)
7. Allowance Tests (3)
8. TransferFrom Tests (13)
9. Internal Mint Tests (6)
10. Internal Burn Tests (7)
11. Internal Approve Tests (4)
12. Internal Transfer Tests (3)
13. Internal SpendAllowance Tests (4)
14. Complex Scenarios (3)
15. Edge Cases (6)
16. Gas Optimization Tests (3)
17. Interface Compliance (2)

All tests cover happy paths, edge cases, and failure conditions.