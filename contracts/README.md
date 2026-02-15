# MonPeer Hook — P2P Order Matching on Uniswap v4 (Monad)

A Uniswap v4 hook enabling **agent-to-agent P2P order matching** on Monad, bypassing AMM pool liquidity when matching orders are available.

> **Moltiverse Hackathon** — Agent+Token Track | Built on Monad & nad.fun

## Overview

The MonPeer Hook acts as an on-chain order book integrated directly into a Uniswap v4 pool on Monad. Whitelisted AI agents can post orders, and when another agent swaps through the pool, the hook checks for matching orders and executes P2P trades directly between maker and taker — zero slippage, no AMM interaction.

### Key Features

- **On-chain Order Book**: Orders stored on-chain with expiry times
- **P2P Matching**: Direct token transfers between maker and taker when orders match
- **Fallback to Pool**: If no matching order exists, swaps fall through to normal pool liquidity
- **Agent Whitelist**: Only authorized AI agents can post orders and swap
- **BeforeSwapDelta**: Uses custom accounting to bypass pool liquidity for P2P trades
- **Monad-native**: Deployed on Monad Testnet (Chain 10143) with ~1s block time

## Deployed on Monad Testnet

| Contract | Address | Explorer |
|----------|---------|----------|
| **MonPeer Hook** | `0xA8d4D47a7Fb423bc5c7aAfaf0E22107F9e298188` | [View](https://testnet.monadexplorer.com/address/0xA8d4D47a7Fb423bc5c7aAfaf0E22107F9e298188) |
| **PoolManager** | `0x4F992a229e3eBd64AC36137fa8750c8beA64929E` | [View](https://testnet.monadexplorer.com/address/0x4F992a229e3eBd64AC36137fa8750c8beA64929E) |
| **SwapRouter** | `0xfd1411e2e3ddfC0C68649d3FEb1bE50C6d599EBd` | [View](https://testnet.monadexplorer.com/address/0xfd1411e2e3ddfC0C68649d3FEb1bE50C6d599EBd) |
| **LiquidityRouter** | `0xae160d585c48b96f248Bd6f829f4432EFf9Eb49d` | [View](https://testnet.monadexplorer.com/address/0xae160d585c48b96f248Bd6f829f4432EFf9Eb49d) |
| **CLAW Token** | `0xe523fc1cc80A6EF2f643895b556cf43A1f1bCF60` | [View](https://testnet.monadexplorer.com/address/0xe523fc1cc80A6EF2f643895b556cf43A1f1bCF60) |
| **ZUG Token** | `0xF4437552a67d5FAAdD1A06aaa6db4466eB9Fa969` | [View](https://testnet.monadexplorer.com/address/0xF4437552a67d5FAAdD1A06aaa6db4466eB9Fa969) |

### Verified On-Chain Transactions

| Step | Transaction | Status |
|------|-------------|--------|
| Deploy PoolManager | [`0x5f924ada...`](https://testnet.monadexplorer.com/tx/0x5f924ada45dcafbe90f22ad0ec253df5b2c353d4bc5496c7a4b199a38c009d76) | ✅ |
| Deploy Hook (CREATE2) | [`0x9535fc86...`](https://testnet.monadexplorer.com/tx/0x9535fc86991a3dd05462ed34657a893b08ce7fde110189830a4a411f2b96f3d4) | ✅ |
| Initialize CLAW/ZUG Pool | [`0xccdde885...`](https://testnet.monadexplorer.com/tx/0xccdde8855174cc8cea34db40300a4d94837f6d419b53a6620cbc087dc47de297) | ✅ |
| Add Liquidity (100K) | [`0x9dcbe4e9...`](https://testnet.monadexplorer.com/tx/0x9dcbe4e9e7433fd5117bb0037b3e393f86c241258c70ead9db6b50fdac28f347) | ✅ |
| **Test Swap (P2P matched!)** | [`0x7f090189...`](https://testnet.monadexplorer.com/tx/0x7f0901894710d913c21c84023a5b576f551534e4c7414a78c5d8dcf408395494) | ✅ |

> Full transaction log: [docs/ONCHAIN.md](../docs/ONCHAIN.md)

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    MonPeer Hook Flow                         │
└─────────────────────────────────────────────────────────────┘

1. AGENT A (Maker)
   │
   ├─> postOrder(sell 100 token0 for ≥95 token1)
   │   └─> Deposits 100 token0 to hook
   │       Order stored on-chain with ID, expiry
   │
2. AGENT B (Taker)
   │
   ├─> Initiates swap (sell 100 token1 for token0)
   │   via PoolManager.swap()
   │
3. beforeSwap Hook
   │
   ├─> Check whitelist (Agent B authorized?)
   ├─> Search for matching orders
   │   ├─> Check: opposite direction?
   │   ├─> Check: sufficient amount?
   │   └─> Check: not expired?
   │
   ├─> IF MATCH FOUND (inline settlement):
   │   ├─> poolManager.take(inputToken, maker)
   │   ├─> poolManager.sync(outputToken)
   │   ├─> outputToken.transfer(PM, amount)
   │   ├─> poolManager.settle()
   │   └─> Return BeforeSwapDelta (bypass AMM)
   │
   └─> IF NO MATCH:
       └─> Return (0,0) — swap proceeds through AMM pool
```

## Hook Flags

| Flag | Value | Purpose |
|------|-------|---------|
| `BEFORE_SWAP` | `0x100` (bit 8) | Pool Manager calls us before every swap |
| `AFTER_SWAP` | `0x080` (bit 7) | Called after swap (no-op) |
| `BEFORE_SWAP_RETURNS_DELTA` | `0x008` (bit 3) | Lets us return custom token deltas |
| **Total** | **`0x188`** | Combined flag bits |

We mine this address using **CREATE2** — iterate salts until we find one that produces an address with the right suffix.

## Deployment

### Deploy to Monad Testnet

```bash
source .env

# Deploy all contracts (requires --legacy for Monad)
forge script script/DeployMonad.s.sol --tc DeployMonad \
    --rpc-url monad_testnet \
    --broadcast --slow --legacy --gas-limit 1000000 -vvv
```

> **Monad Note**: Must use `--legacy` flag (no EIP-1559). Complex calls need explicit `--gas-limit`. Split multi-step operations into separate txs.

### What Gets Deployed

1. **PoolManager** (Uniswap v4 core)
2. **SwapRouter** + **LiquidityRouter** (periphery)
3. **MockTokens** (CLAW - Claw Token, ZUG - Zug Gold)
4. **CREATE2 Factory** (for address mining)
5. **MonPeer Hook** (with correct flag bits `0x188`)
6. **Pool Initialization** (CLAW/ZUG pool at 1:1)
7. **Liquidity Addition** (100K tokens for fallback swaps)
8. **Test Swap** (verify P2P matching works)

## Testing

```bash
forge install
forge test -vvv
```

## Contract Addresses

### Monad Testnet (Chain 10143)

| Contract | Address | Explorer |
|----------|---------|----------|
| **MonPeer Hook** | `0xA8d4D47a7Fb423bc5c7aAfaf0E22107F9e298188` | [View](https://testnet.monadexplorer.com/address/0xA8d4D47a7Fb423bc5c7aAfaf0E22107F9e298188) |
| PoolManager | `0x4F992a229e3eBd64AC36137fa8750c8beA64929E` | [View](https://testnet.monadexplorer.com/address/0x4F992a229e3eBd64AC36137fa8750c8beA64929E) |
| SwapRouter | `0xfd1411e2e3ddfC0C68649d3FEb1bE50C6d599EBd` | [View](https://testnet.monadexplorer.com/address/0xfd1411e2e3ddfC0C68649d3FEb1bE50C6d599EBd) |
| LiquidityRouter | `0xae160d585c48b96f248Bd6f829f4432EFf9Eb49d` | [View](https://testnet.monadexplorer.com/address/0xae160d585c48b96f248Bd6f829f4432EFf9Eb49d) |
| CLAW Token | `0xe523fc1cc80A6EF2f643895b556cf43A1f1bCF60` | [View](https://testnet.monadexplorer.com/address/0xe523fc1cc80A6EF2f643895b556cf43A1f1bCF60) |
| ZUG Token | `0xF4437552a67d5FAAdD1A06aaa6db4466eB9Fa969` | [View](https://testnet.monadexplorer.com/address/0xF4437552a67d5FAAdD1A06aaa6db4466eB9Fa969) |
| Create2Deployer | `0xf09b40dfc07a584970312d1f62ed84a4edd575c9` | [View](https://testnet.monadexplorer.com/address/0xf09b40dfc07a584970312d1f62ed84a4edd575c9) |

## Agent Wallets (Monad Testnet)

| Agent | Wallet | Role |
|-------|--------|------|
| **Deployer** | `0xa58DCCb0F17279abD1d0D9069Aa8711Df4a4c58E` | Admin, hook deployer |
| **alpha-trader** | `0xf8AdD61Fb2b7B5B6E5c69274bBb6016a2785Fb82` | Demo bot (whitelisted, funded) |
| **monad-sniper** | `0xfdCe6b2fe70Ebc4A0Ca56396C06592F7b2D4fe87` | Demo bot (whitelisted, funded) |
| **dex-arb** | `0x787E61b5654ce780424F5Fa4D6843B7385301892` | Demo bot (whitelisted, funded) |
| **Wallet 2** | `0x356435901c4bF97E2f695a4377087670201e5588` | Second operator (whitelisted, funded) |

All agent wallets are whitelisted on the hook and funded with 10K CLAW + 10K ZUG tokens.

## License

MIT

---

*Built for the [Moltiverse Hackathon](https://moltiverse.dev) — Powered by Monad & nad.fun*
