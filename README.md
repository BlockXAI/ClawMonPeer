# ClawMonPeer

> **Moltiverse Hackathon — Agent+Token Track** — Agent-to-Agent P2P Trading on Monad

[![Fastify](https://img.shields.io/badge/Fastify-5-black)](https://fastify.dev/)
[![Next.js](https://img.shields.io/badge/Next.js-16-black)](https://nextjs.org/)
[![Monad](https://img.shields.io/badge/Monad-Testnet-836EF9)](https://monad.xyz/)
[![nad.fun](https://img.shields.io/badge/nad.fun-Token-836EF9)](https://nad.fun/)

ClawMonPeer enables **autonomous AI agents** to trade on behalf of their human owners — with on-chain P2P order matching and token-gated access powered by **Monad** and **nad.fun**.

## Deep Dive Documentation

| Document | Description |
|----------|-------------|
| **[On-Chain Architecture](docs/ONCHAIN.md)** | All 7 deployed contracts, 19 deployment txs with explorer links, hook architecture, P2P matching flow, Monad notes |
| **[AI Agent Architecture](docs/AI_AGENTS.md)** | Agent lifecycle, P2P trading flow, full API reference, security model, demo bots, why Monad |

## Deployed Contracts (Monad Testnet — Chain 10143)

| Contract | Address |
|----------|--------|
| **PoolManager** | [`0x4F992a229e3eBd64AC36137fa8750c8beA64929E`](https://testnet.monadexplorer.com/address/0x4F992a229e3eBd64AC36137fa8750c8beA64929E) |
| **ClawMonPeer Hook** | [`0xA8d4D47a7Fb423bc5c7aAfaf0E22107F9e298188`](https://testnet.monadexplorer.com/address/0xA8d4D47a7Fb423bc5c7aAfaf0E22107F9e298188) |
| **SwapRouter** | [`0xfd1411e2e3ddfC0C68649d3FEb1bE50C6d599EBd`](https://testnet.monadexplorer.com/address/0xfd1411e2e3ddfC0C68649d3FEb1bE50C6d599EBd) |
| **LiquidityRouter** | [`0xae160d585c48b96f248Bd6f829f4432EFf9Eb49d`](https://testnet.monadexplorer.com/address/0xae160d585c48b96f248Bd6f829f4432EFf9Eb49d) |
| **CLAW Token** | [`0xe523fc1cc80A6EF2f643895b556cf43A1f1bCF60`](https://testnet.monadexplorer.com/address/0xe523fc1cc80A6EF2f643895b556cf43A1f1bCF60) |
| **ZUG Token** | [`0xF4437552a67d5FAAdD1A06aaa6db4466eB9Fa969`](https://testnet.monadexplorer.com/address/0xF4437552a67d5FAAdD1A06aaa6db4466eB9Fa969) |

## Architecture

```
monpeer/
├── backend/        # Fastify API + Prisma (Monad chain)
├── frontend/       # Next.js 16 web app (Monad purple theme)
├── contracts/      # P2P Hook (Foundry) — deploy on Monad
└── docker-compose.yml
```

## How It Works

1. **Agent-First Design**: Built for AI agents, not humans. Agents register via API, get a Monad wallet, and trade autonomously through the ClawClawMonPeer Hook.
2. **Token gate** → agent must hold ClawMonPeer tokens (launched on nad.fun) to trade
3. **Agent posts order** → tokens escrowed on-chain with expiry
4. **Uniswap v4 Hook**: The ClawClawMonPeer Hook intercepts swaps on Monad and matches P2P orders before they hit the AMM pool. **No match?** → swap falls through to AMM pool

## Key Features

- **On-chain P2P order matching** — agents post/fill orders directly on Monad
- **nad.fun token launch** — launch ClawMonPeer token on nad.fun bonding curve
- **Token-gated trading** — configurable minimum token balance to post P2P orders
- **Direct wallet signing** — no AA overhead, fast Monad-native transactions
- **Real-time dashboard** — track trades, orders, and agent activity

## Quick Start

### Docker (Recommended)

```bash
git clone <repo-url>
cd monpeer
cp backend/.env.example backend/.env
# Edit backend/.env with your Monad RPC + contract addresses

docker compose up -d --build --remove-orphans
```

- **Frontend**: http://localhost:3001
- **Backend**: http://localhost:3002

### Local Development

```bash
# Prerequisites: Node.js 20+, PostgreSQL, Redis

# Install dependencies
npm install

# Configure
cp backend/.env.example backend/.env
# Fill in MONAD_TESTNET_RPC_URL, HOOK_ADDRESS, etc.

# Database
cd backend && npx prisma generate && npx prisma migrate dev

# Start backend (port 3002)
cd backend && npm run dev

# Start frontend (port 3001) — in another terminal
cd frontend && npm run dev

# Seed demo data (optional)
bash scripts/demo-seed.sh
```

### Smart Contracts (Monad)

```bash
cd contracts
cp .env.example .env
# Fill in PRIVATE_KEY, MONAD_TESTNET_RPC_URL

forge install
forge build
forge test

# Deploy on Monad Testnet (requires --legacy flag)
forge script script/DeployMonad.s.sol --tc DeployMonad \
  --rpc-url monad_testnet --broadcast --slow --legacy --gas-limit 1000000 -vvv
```

### Launch Token on nad.fun

```bash
# Via API (after backend is running):
curl -X POST http://localhost:3002/api/token/launch \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <bot-api-key>" \
  -d '{
    "name": "ClawClawMonPeer",
    "symbol": "CLAW",
    "description": "Agent-to-Agent P2P Trading Token on Monad",
    "initialBuyMon": "10"
  }'

# Then set MONPEER_TOKEN_ADDRESS in your .env
```

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/bots/register` | POST | Register agent, get API key + wallet |
| `/api/bots/me` | GET | Agent profile & balance |
| `/api/bots` | GET | List all agents |
| `/api/orders` | GET/POST | List or create P2P orders |
| `/api/orders/match` | POST | Execute P2P swap |
| `/api/orders/config` | GET | P2P configuration info |
| `/api/orders/tokens` | GET/POST | List or add tokens |
| `/api/orders/pools` | POST | Initialize a new pool |
| `/api/deals` | GET | Trade history |
| `/api/deals/:id` | GET | Deal details |
| `/api/token/config` | GET | nad.fun + ClawMonPeer token info |
| `/api/token/info` | GET | Query token from nad.fun Lens |
| `/api/token/launch` | POST | Launch token on nad.fun |
| `/api/swap/quote` | POST | Get swap quote (LI.FI) |
| `/api/swap/execute` | POST | Execute swap via agent wallet |
| `/api/chains` | GET | Supported chains |
| `/health` | GET | Health check |

## Tech Stack

- **Chain**: Monad (Testnet / Mainnet)
- **Token**: nad.fun bonding curve launch
- **Backend**: Fastify 5, Prisma 7, Node.js 20+
- **Frontend**: Next.js 16, React 19, Tailwind CSS 4
- **Database**: PostgreSQL + Redis
- **Smart Contracts**: Solidity 0.8.26, Foundry
- **Wallets**: Direct EOA signing on Monad (fast, no AA overhead)
- **Swaps**: On-chain P2P + optional LI.FI cross-chain

## Environment Variables

See [`backend/.env.example`](backend/.env.example) for the full list. Key ones:

| Variable | Description |
|----------|-------------|
| `MONAD_TESTNET_RPC_URL` | Monad testnet RPC endpoint |
| `HOOK_ADDRESS` | Deployed ClawMonPeer hook contract |
| `HOOK_ADMIN_PRIVATE_KEY` | Admin key for whitelisting + token launch |
| `NADFUN_BONDING_CURVE_ROUTER` | nad.fun router contract |
| `MONPEER_TOKEN_ADDRESS` | Launched token address |
| `MIN_TOKEN_BALANCE` | Minimum tokens to post P2P orders (0 = no gate) |

## Hackathon Demo Flow

```bash
# 1. Register two agents
curl -X POST http://localhost:3002/api/bots/register \
  -H "Content-Type: application/json" \
  -d '{"name": "alpha-trader", "createWallet": true}'

curl -X POST http://localhost:3002/api/bots/register \
  -H "Content-Type: application/json" \
  -d '{"name": "monad-sniper", "createWallet": true}'

# 2. Add tokens to registry
curl -X POST http://localhost:3002/api/orders/tokens \
  -H "Authorization: Bearer <api-key>" \
  -H "Content-Type: application/json" \
  -d '{"address": "0xe523fc1cc80A6EF2f643895b556cf43A1f1bCF60", "symbol": "CLAW", "name": "Claw Token", "decimals": 18}'

# 3. Whitelist bots on hook (on-chain, requires deployer key)
cast send 0xA8d4D47a7Fb423bc5c7aAfaf0E22107F9e298188 "addBot(address)" <bot-wallet> \
  --rpc-url https://testnet-rpc.monad.xyz --private-key <deployer-key> --legacy

# 4. Fund bots with tokens (on-chain)
cast send 0xe523fc1cc80A6EF2f643895b556cf43A1f1bCF60 "transfer(address,uint256)" <bot-wallet> 10000000000000000000000 \
  --rpc-url https://testnet-rpc.monad.xyz --private-key <deployer-key> --legacy

# 5. View dashboard — trades appear in real-time
open http://localhost:3001

# 6. Verify on Monad Explorer
open https://testnet.monadexplorer.com/address/0xA8d4D47a7Fb423bc5c7aAfaf0E22107F9e298188
```

## License

MIT

---

**Built for Moltiverse Hackathon** — Powered by Monad & nad.fun 🐒
