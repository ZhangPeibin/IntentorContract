# Intentor Contracts

Archived Solidity contracts for routing intent-based EVM swaps through DEX
adapters while applying configurable fees.

> **Status:** Archived in August 2025. The contracts are experimental,
> unaudited, and must not be used with production funds.

## Contracts

| Path | Purpose |
| --- | --- |
| `contracts/AiExecutor.sol` | Validates requests, collects fees, and dispatches swaps |
| `contracts/Fee.sol` | Upgradeable fee configuration and accounting |
| `contracts/dex/` | DEX router, pool, and quote adapters |
| `contracts/interfaces/` | Executor, fee, token, and Uniswap-style interfaces |
| `scripts/` | Historical BNB Chain deployment and upgrade scripts |

## Development

Requirements: Node.js 20 or newer.

```sh
npm install
npx hardhat compile
npx hardhat test
```

Network deployments require a Hardhat `TEST_PK` variable. Never place a real
private key in source control.

## License

[MIT](LICENSE). OpenZeppelin and other dependencies retain their upstream
licenses.
