# On-Chain Architecture — Monad Testnet

> All MonPeer smart contracts are deployed on **Monad Testnet (Chain ID: 10143)**.
> Explorer: [testnet.monadexplorer.com](https://testnet.monadexplorer.com)

---

## Deployed Contracts

| # | Contract | Address | Explorer | Purpose |
|---|----------|---------|----------|---------|
| 1 | **PoolManager** | `0x4F992a229e3eBd64AC36137fa8750c8beA64929E` | [View](https://testnet.monadexplorer.com/address/0x4F992a229e3eBd64AC36137fa8750c8beA64929E) | Uniswap v4 core — manages all pools and liquidity |
| 2 | **SwapRouter** | `0xfd1411e2e3ddfC0C68649d3FEb1bE50C6d599EBd` | [View](https://testnet.monadexplorer.com/address/0xfd1411e2e3ddfC0C68649d3FEb1bE50C6d599EBd) | Executes swaps through PoolManager |
| 3 | **LiquidityRouter** | `0xae160d585c48b96f248Bd6f829f4432EFf9Eb49d` | [View](https://testnet.monadexplorer.com/address/0xae160d585c48b96f248Bd6f829f4432EFf9Eb49d) | Adds/removes liquidity positions |
| 4 | **MonPeer Hook** | `0xA8d4D47a7Fb423bc5c7aAfaf0E22107F9e298188` | [View](https://testnet.monadexplorer.com/address/0xA8d4D47a7Fb423bc5c7aAfaf0E22107F9e298188) | P2P order matching hook (core innovation) |
| 5 | **CLAW Token** | `0xe523fc1cc80A6EF2f643895b556cf43A1f1bCF60` | [View](https://testnet.monadexplorer.com/address/0xe523fc1cc80A6EF2f643895b556cf43A1f1bCF60) | ERC-20 demo token (18 decimals) |
| 6 | **ZUG Token** | `0xF4437552a67d5FAAdD1A06aaa6db4466eB9Fa969` | [View](https://testnet.monadexplorer.com/address/0xF4437552a67d5FAAdD1A06aaa6db4466eB9Fa969) | ERC-20 demo token (18 decimals) |
| 7 | **Create2Deployer** | `0xf09b40dfc07a584970312d1f62ed84a4edd575c9` | [View](https://testnet.monadexplorer.com/address/0xf09b40dfc07a584970312d1f62ed84a4edd575c9) | Deterministic deployment of hook at correct address |

---

## Wallets

| Wallet | Address | Role |
|--------|---------|------|
| **Deployer** | `0xa58DCCb0F17279abD1d0D9069Aa8711Df4a4c58E` | Contract deployer, hook admin, token minter |
| **Wallet 2** | `0x356435901c4bF97E2f695a4377087670201e5588` | Second operator wallet (whitelisted, funded) |

---

## Core Deployment Transactions

All transactions were broadcast via `forge script` with `--legacy` flag (Monad does not support EIP-1559).

### Step 1: Contract Deployments

| # | Transaction | Contract | Block |
|---|-------------|----------|-------|
| 1 | [`0x5f924ada...`](https://testnet.monadexplorer.com/tx/0x5f924ada45dcafbe90f22ad0ec253df5b2c353d4bc5496c7a4b199a38c009d76) | Deploy **PoolManager** | 12,277,242 |
| 2 | [`0xe063c6c7...`](https://testnet.monadexplorer.com/tx/0xe063c6c70eaa796d16e7f6fb9d8aaa03441407054afc61ea95da1f354b218915) | Deploy **SwapRouter** (PoolSwapTest) | 12,277,244 |
| 3 | [`0xc680cda8...`](https://testnet.monadexplorer.com/tx/0xc680cda8499d25ba6256c15ff7416b720ad8b7fe76cfc8451c198ecd8e856cae) | Deploy **LiquidityRouter** (PoolModifyLiquidityTest) | 12,277,244 |
| 4 | [`0x4e15da1f...`](https://testnet.monadexplorer.com/tx/0x4e15da1f83e387f8a91d8d9b60495d4c8a3a8da94990a80090706981bed83b93) | Deploy **CLAW Token** (MockToken) | 12,277,244 |
| 5 | [`0x89387d76...`](https://testnet.monadexplorer.com/tx/0x89387d76466403fb4280d137471e68f3265ee0630f499a52eb871992d728869d) | Deploy **ZUG Token** (MockToken) | 12,277,244 |
| 6 | [`0xf3506531...`](https://testnet.monadexplorer.com/tx/0xf3506531dd8169fffe61fb26e23f24cdbf842df0505d258cb9d847cd579abfaa) | Deploy **Create2Deployer** | — |
| 7 | [`0x9535fc86...`](https://testnet.monadexplorer.com/tx/0x9535fc86991a3dd05462ed34657a893b08ce7fde110189830a4a411f2b96f3d4) | CREATE2 deploy **MonPeer Hook** | — |

### Step 2: Token Minting

| # | Transaction | Action |
|---|-------------|--------|
| 8 | [`0xf1969fca...`](https://testnet.monadexplorer.com/tx/0xf1969fca96aa5289472af61539f3c684a84425819bae5c1ab95aac83a66c22dc) | Mint 1,000,000 CLAW to deployer |
| 9 | [`0xb9457ed3...`](https://testnet.monadexplorer.com/tx/0xb9457ed3ed6f3414a0f03c856bd9095688e505366575d88e5831b3ad47713be0) | Mint 1,000,000 ZUG to deployer |

### Step 3: Bot Whitelisting

| # | Transaction | Action |
|---|-------------|--------|
| 10 | [`0xefa195af...`](https://testnet.monadexplorer.com/tx/0xefa195af4ee0884c9e243230ab70a4b24736a2d610e972ec4c628916b9848169) | Whitelist deployer on hook |
| 11 | [`0xd4772403...`](https://testnet.monadexplorer.com/tx/0xd4772403cd2fe63bf1a7f7dc5d2ee76443722c4ecb3fea44c19a8bbacede0227) | Whitelist SwapRouter on hook |
| 12 | [`0xd7f5ca9c...`](https://testnet.monadexplorer.com/tx/0xd7f5ca9c01d2cda31a87a175aee459f257f700586ea84b03ca858f31eeab8463) | Whitelist LiquidityRouter on hook |

### Step 4: Pool Initialization

| # | Transaction | Action |
|---|-------------|--------|
| 13 | [`0xccdde885...`](https://testnet.monadexplorer.com/tx/0xccdde8855174cc8cea34db40300a4d94837f6d419b53a6620cbc087dc47de297) | Initialize CLAW/ZUG pool (fee=3000, tickSpacing=60, sqrtPriceX96=1:1) |

### Step 5: Approvals

| # | Transaction | Action |
|---|-------------|--------|
| 14 | [`0x5e42947d...`](https://testnet.monadexplorer.com/tx/0x5e42947d062b9ddddd07442881ac08cd50e47344ac4b3d59c2210976deae554f) | Approve CLAW → LiquidityRouter (unlimited) |
| 15 | [`0x6ef48858...`](https://testnet.monadexplorer.com/tx/0x6ef48858b1c13fb219794566f96a862ba6ecf511ca156e3afed7bd03d4055c8c) | Approve ZUG → LiquidityRouter (unlimited) |
| 16 | [`0x269eae18...`](https://testnet.monadexplorer.com/tx/0x269eae18b97e6994f1e206c192d52b0e465d0a08d72d86228c6d97b90baf8681) | Approve CLAW → SwapRouter (unlimited) |
| 17 | [`0x4518ce70...`](https://testnet.monadexplorer.com/tx/0x4518ce70c32d389d156338922089710f63024a98756ca3f8c60756ceca60ce39) | Approve ZUG → SwapRouter (unlimited) |

### Step 6: Liquidity + Swap (via `cast send` with explicit gas)

| # | Transaction | Action |
|---|-------------|--------|
| 18 | [`0x9dcbe4e9...`](https://testnet.monadexplorer.com/tx/0x9dcbe4e9e7433fd5117bb0037b3e393f86c241258c70ead9db6b50fdac28f347) | Add liquidity: 100,000 CLAW + ZUG at tick range [-600, 600] |
| 19 | [`0x7f090189...`](https://testnet.monadexplorer.com/tx/0x7f0901894710d913c21c84023a5b576f551534e4c7414a78c5d8dcf408395494) | **Test swap**: 1,000 CLAW → ZUG (P2P hook matched!) |

---

## Hook Architecture (MonPeerHook.sol)

The MonPeer Hook is a **Uniswap v4 hook** that enables inline P2P order matching inside the `beforeSwap` callback.

### Hook Flags

```
BEFORE_SWAP         = 1 << 7  = 0x0080
AFTER_SWAP          = 1 << 6  = 0x0040
BEFORE_SWAP_RETURNS_DELTA = 1 << 3 = 0x0008
```

### Hook Functions

| Function | Description |
|----------|-------------|
| `addBot(address)` | Whitelist an agent wallet for P2P trading |
| `removeBot(address)` | Remove agent from whitelist |
| `postOrder(PoolKey, bool, uint128, uint128, uint32)` | Post a P2P sell order with escrow |
| `cancelOrder(PoolKey, bool)` | Cancel and reclaim escrowed tokens |
| `getPoolOrders(PoolKey)` | View all active orders for a pool |
| `beforeSwap(...)` | **Core**: matches P2P orders inline before AMM |
| `claimRefund(PoolKey, bool)` | Reclaim tokens after order expiry |

### P2P Order Matching Flow

```
Agent A: postOrder(CLAW→ZUG, 1000 CLAW, min 950 ZUG, 1hr)
  └── CLAW tokens escrowed in hook contract
  └── Order stored on-chain with orderId + expiry

Agent B: swap(ZUG→CLAW, 1000 ZUG)
  └── beforeSwap hook fires
  └── Hook checks: any matching CLAW→ZUG orders?
  └── YES → P2P fill: Agent B gets CLAW, Agent A gets ZUG
  └── NO  → Falls through to AMM liquidity pool
```

### Pool Key

```solidity
PoolKey({
    currency0: 0xe523fc1cc80A6EF2f643895b556cf43A1f1bCF60,  // CLAW
    currency1: 0xF4437552a67d5FAAdD1A06aaa6db4466eB9Fa969,  // ZUG
    fee:       3000,       // 0.3%
    tickSpacing: 60,
    hooks:     0xA8d4D47a7Fb423bc5c7aAfaf0E22107F9e298188   // MonPeer Hook
})
```

---

## Monad-Specific Notes

| Topic | Detail |
|-------|--------|
| **Gas** | Monad requires `--legacy` flag (no EIP-1559). Complex calls need explicit `--gas-limit 1000000`. |
| **Parallel Execution** | Multi-step operations (approve → modifyLiquidity) must be split into separate transactions to avoid state issues. |
| **Block Time** | ~1 second block time — transactions confirm almost instantly. |
| **RPC** | `https://testnet-rpc.monad.xyz` |
| **Chain ID** | `10143` |
| **Explorer** | [testnet.monadexplorer.com](https://testnet.monadexplorer.com) |

---

## Deployment Script

The full deployment is handled by [`contracts/script/DeployMonad.s.sol`](../contracts/script/DeployMonad.s.sol):

```bash
forge script script/DeployMonad.s.sol --tc DeployMonad \
  --rpc-url monad_testnet --broadcast --slow --legacy --gas-limit 1000000 -vvv
```

Post-deployment liquidity addition via [`contracts/script/FixLiquidity.s.sol`](../contracts/script/FixLiquidity.s.sol):

```bash
# Step 1: Approve tokens
forge script script/FixLiquidity.s.sol --tc Step1Approve \
  --rpc-url monad_testnet --broadcast --slow --legacy -vvv

# Step 2: Add liquidity (use cast for explicit gas)
cast send 0xae160d585c48b96f248Bd6f829f4432EFf9Eb49d \
  "modifyLiquidity(...)" ... \
  --rpc-url https://testnet-rpc.monad.xyz --legacy --gas-limit 1000000

# Step 3: Test swap
cast send 0xfd1411e2e3ddfC0C68649d3FEb1bE50C6d599EBd \
  "swap(...)" ... \
  --rpc-url https://testnet-rpc.monad.xyz --legacy --gas-limit 1000000
