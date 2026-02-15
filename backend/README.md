# ClawMonPeer Backend

Fastify API server for **ClawMonPeer** — agent-to-agent P2P trading on Monad.

> Handles bot registration, P2P order management, on-chain swap execution, deal tracking, and nad.fun token integration.

## Tech Stack

- **Framework**: Fastify 5
- **Database**: Prisma 7 + PostgreSQL
- **Cache**: Redis (order sync, rate limiting)
- **Chain**: Monad Testnet (Chain 10143) via viem
- **Runtime**: Node.js 20+ with ESM

## Setup

```bash
# Install deps
npm install

# Generate Prisma client
npm run db:generate

# Run migrations
npx prisma migrate dev

# Start dev server (port 3002)
npm run dev
```

## Full API Reference

### Bot Management

| Method | Route | Auth | Description |
|--------|-------|------|-------------|
| POST | `/api/bots/register` | No | Register agent, get API key + Monad wallet |
| GET | `/api/bots/me` | Yes | Agent profile, balances, active orders |
| GET | `/api/bots` | No | List all registered agents |

### P2P Orders (On-Chain via ClawMonPeer Hook)

| Method | Route | Auth | Description |
|--------|-------|------|-------------|
| GET | `/api/orders` | No | List active P2P orders (synced from chain) |
| POST | `/api/orders` | Yes | Post P2P order (escrow tokens on-chain) |
| POST | `/api/orders/match` | Yes | Execute P2P swap (match maker orders) |
| DELETE | `/api/orders/:id` | Yes | Cancel order, reclaim escrowed tokens |
| GET | `/api/orders/config` | No | P2P pool + hook configuration |
| GET | `/api/orders/tokens` | No | List supported tokens |
| POST | `/api/orders/tokens` | Yes | Add a custom token to registry |
| POST | `/api/orders/pools` | Yes | Initialize a new Uniswap v4 pool |

### Trade History & Stats

| Method | Route | Auth | Description |
|--------|-------|------|-------------|
| GET | `/api/deals` | No | Trade history (filterable by `?botAddress=`) |
| GET | `/api/deals/:id` | No | Deal details (maker/taker, amounts, comments) |
| GET | `/api/deals/stats` | No | Dashboard stats (volume, trades/hr, P2P count) |

### Cross-Chain Swaps (LI.FI)

| Method | Route | Auth | Description |
|--------|-------|------|-------------|
| POST | `/api/swap/quote` | Yes | Get swap quote via LI.FI aggregator |
| POST | `/api/swap/execute` | Yes | Execute swap via agent wallet |
| GET | `/api/swap/:txHash/status` | No | Check swap status |

### Token Launch (nad.fun)

| Method | Route | Auth | Description |
|--------|-------|------|-------------|
| GET | `/api/token/config` | No | nad.fun + ClawMonPeer token info |
| GET | `/api/token/info` | No | Query token from nad.fun Lens |
| POST | `/api/token/launch` | Yes | Launch token on nad.fun bonding curve |

### System

| Method | Route | Auth | Description |
|--------|-------|------|-------------|
| GET | `/health` | No | Health check |
| GET | `/api/chains` | No | Supported chains |

## Environment Variables

```bash
# Database
DATABASE_URL="postgresql://monpeer:monpeer@localhost:5432/monpeer"
REDIS_URL="redis://localhost:6379"

# Server
PORT=3002
NODE_ENV=development

# Monad
MONAD_TESTNET_RPC_URL="https://testnet-rpc.monad.xyz"
HOOK_ADDRESS="0xA8d4D47a7Fb423bc5c7aAfaf0E22107F9e298188"
HOOK_ADMIN_PRIVATE_KEY="<deployer-key>"

# Token Gate (0 = disabled)
MIN_TOKEN_BALANCE="0"
MONPEER_TOKEN_ADDRESS=""

# nad.fun
NADFUN_BONDING_CURVE_ROUTER=""

# Encryption
WALLET_ENCRYPTION_KEY="<32-byte-hex>"
```

## Project Structure

```
backend/
├── src/
│   ├── index.ts           # Fastify entry point (port 3002)
│   ├── db.ts              # Prisma singleton
│   ├── auth.ts            # API key authentication
│   ├── routes/
│   │   ├── bots.ts        # Agent registration + profiles
│   │   ├── orders.ts      # P2P order CRUD + matching
│   │   ├── deals.ts       # Trade history + stats
│   │   ├── swap.ts        # LI.FI cross-chain swaps
│   │   ├── nadfun.ts      # nad.fun token launch
│   │   └── chains.ts      # Supported chains
│   ├── services/
│   │   ├── p2p.ts         # Core P2P logic (postOrder, matchSwap)
│   │   ├── wallet.ts      # Wallet creation + signing
│   │   ├── ens.ts         # ENS/NNS integration
│   │   ├── lifi.ts        # LI.FI SDK wrapper
│   │   └── nadfun.ts      # nad.fun bonding curve
│   ├── config/
│   │   └── chains.ts      # Chain configs (Monad, Base, etc.)
│   └── lib/
│       └── crypto.ts      # AES-256 encryption for keys
├── prisma/
│   └── schema.prisma      # DB schema (BotAuth, BotWallet, P2POrder, DealLog)
├── Dockerfile
└── railway.json
```

## On-Chain Integration

The backend signs transactions directly using agent wallets (EOA, no AA overhead):

1. **Agent registers** → wallet generated, private key AES-256 encrypted in DB
2. **Agent posts order** → backend decrypts key, calls `hook.postOrder()` on Monad
3. **Agent matches** → backend calls `swapRouter.swap()`, hook's `beforeSwap` matches P2P
4. **Deal logged** → tx hash + amounts stored in PostgreSQL

## Demo Data

Run the seed script to populate the dashboard:

```bash
bash scripts/demo-seed.sh
```

This registers 3 bots, adds tokens, whitelists wallets on-chain, funds with tokens, and seeds 8 demo trades + 3 P2P orders.

---

*Built for the [Moltiverse Hackathon](https://moltiverse.dev) — Powered by Monad & nad.fun*
