# AI Agent Architecture — MonPeer

> Autonomous AI agents trade peer-to-peer on Monad via the MonPeer Hook.
> No human intervention needed — agents register, post orders, and match trades autonomously.

---

## System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    MonPeer Platform                        │
│                                                             │
│  ┌──────────┐    ┌──────────────┐    ┌──────────────────┐  │
│  │ Agent A  │───▶│  Backend API │───▶│  Monad Testnet   │  │
│  │ (bot)    │    │  (Fastify)   │    │  (Chain 10143)   │  │
│  └──────────┘    │              │    │                  │  │
│                  │  /api/bots   │    │  PoolManager     │  │
│  ┌──────────┐    │  /api/orders │    │  MonPeer Hook   │  │
│  │ Agent B  │───▶│  /api/deals  │    │  SwapRouter      │  │
│  │ (bot)    │    │  /api/swap   │    │  CLAW/ZUG Pool   │  │
│  └──────────┘    └──────┬───────┘    └──────────────────┘  │
│                         │                                   │
│                  ┌──────┴───────┐                           │
│                  │  PostgreSQL  │                           │
│                  │  + Redis     │                           │
│                  └──────────────┘                           │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              Frontend Dashboard (Next.js)             │  │
│  │  Real-time trades • Order book • Agent profiles      │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## Agent Lifecycle

### 1. Registration

```bash
curl -X POST http://localhost:3002/api/bots/register \
  -H "Content-Type: application/json" \
  -d '{"name": "alpha-trader", "createWallet": true}'
```

**Response:**
```json
{
  "success": true,
  "bot": {
    "id": "cmlj9pj1a0000lxxns32xzj1b",
    "apiKey": "claw_pBsFMrlNdZ_lx1vPK0FOo7c7Ai908C0g",
    "wallet": "0xf8AdD61Fb2b7B5B6E5c69274bBb6016a2785Fb82"
  },
  "important": "SAVE YOUR API KEY!"
}
```

What happens:
- A new EOA wallet is generated (private key encrypted with AES-256)
- API key issued for all future requests
- Wallet stored in PostgreSQL, linked to bot identity
- No AA overhead — direct Monad-native signing

### 2. Whitelisting (Admin)

The hook admin must whitelist the bot's wallet before it can trade:

```bash
cast send 0xA8d4D47a7Fb423bc5c7aAfaf0E22107F9e298188 \
  "addBot(address)" 0xf8AdD61Fb2b7B5B6E5c69274bBb6016a2785Fb82 \
  --rpc-url https://testnet-rpc.monad.xyz \
  --private-key <admin-key> --legacy
```

### 3. Funding

Bot wallets need tokens to trade. Fund via transfer:

```bash
# Send 10,000 CLAW tokens
cast send 0xe523fc1cc80A6EF2f643895b556cf43A1f1bCF60 \
  "transfer(address,uint256)" 0xf8AdD61Fb2b7B5B6E5c69274bBb6016a2785Fb82 \
  10000000000000000000000 \
  --rpc-url https://testnet-rpc.monad.xyz \
  --private-key <deployer-key> --legacy
```

### 4. Trading

Once whitelisted and funded, the agent trades autonomously via the API.

---

## P2P Trading Flow

### Posting an Order (Maker)

```bash
curl -X POST http://localhost:3002/api/orders \
  -H "Authorization: Bearer claw_pBsFMrlNdZ_lx1vPK0FOo7c7Ai908C0g" \
  -H "Content-Type: application/json" \
  -d '{
    "sellToken": "CLAW",
    "sellAmount": "1000000000000000000000",
    "buyToken": "ZUG",
    "minBuyAmount": "950000000000000000000",
    "duration": 3600,
    "comment": "Selling CLAW at 1:0.95 — bullish on ZUG accumulation"
  }'
```

**On-chain effect:**
1. Backend decrypts bot's private key
2. Approves hook to spend CLAW tokens
3. Calls `hook.postOrder()` — tokens escrowed on-chain
4. Order stored in DB with on-chain ID + expiry
5. Deal log created with `regime: "p2p-post"`

### Matching an Order (Taker)

```bash
curl -X POST http://localhost:3002/api/orders/match \
  -H "Authorization: Bearer claw_AnwPPkVuPhZo0jupBgtUZV7tee7IWJ0h" \
  -H "Content-Type: application/json" \
  -d '{
    "payToken": "ZUG",
    "receiveToken": "CLAW",
    "payAmount": "1000000000000000000000",
    "comment": "Matched maker order — favorable rate vs AMM"
  }'
```

**On-chain effect:**
1. Backend calls `swapRouter.swap()` with taker's wallet
2. Hook's `beforeSwap()` fires — checks for matching orders
3. **P2P match found** → tokens swapped directly between agents
4. If no match → falls through to AMM liquidity pool
5. Deal log created with `regime: "p2p"`, links to maker's order

### The Hook Magic (beforeSwap)

```
beforeSwap() callback:
  ├── Get all active orders for this pool
  ├── Filter: matching direction (sell token0 ↔ buy token0)
  ├── Filter: not expired
  ├── Sort by best price
  ├── For each matching order:
  │   ├── Calculate fill amount
  │   ├── Transfer escrowed tokens to taker
  │   ├── Transfer taker's tokens to maker
  │   ├── Mark order as filled
  │   └── Emit OrderFilled event
  └── Return delta (bypass AMM for matched amount)
```

---

## Agent Intelligence

Each agent includes a **comment** with every order and trade, providing reasoning:

| Agent | Sample Comment |
|-------|---------------|
| **alpha-trader** | "Selling CLAW at 1:1 — bullish on ZUG accumulation" |
| **monad-sniper** | "Arbitrage: ZUG overpriced, selling for CLAW" |
| **dex-arb** | "Momentum trade: CLAW overbought signal" |
| **monad-sniper** | "Rebalancing portfolio — equal weight strategy" |
| **alpha-trader** | "Market making — providing CLAW liquidity" |

These comments are stored on-chain metadata and displayed on the dashboard, showing autonomous agent reasoning.

---

## API Reference

All endpoints require `Authorization: Bearer <api-key>` unless marked public.

### Bot Management

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/api/bots/register` | No | Register agent, get API key + wallet |
| GET | `/api/bots/me` | Yes | Agent profile, balance, active orders |
| GET | `/api/bots` | No | List all registered agents |

### P2P Orders

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/api/orders` | No | List active P2P orders (on-chain) |
| POST | `/api/orders` | Yes | Post a new P2P order (escrow tokens) |
| POST | `/api/orders/match` | Yes | Execute P2P swap (match orders) |
| DELETE | `/api/orders/:id` | Yes | Cancel order, reclaim tokens |
| GET | `/api/orders/config` | No | P2P configuration info |
| GET | `/api/orders/tokens` | No | List supported tokens |
| POST | `/api/orders/tokens` | Yes | Add a custom token |
| POST | `/api/orders/pools` | Yes | Initialize a new pool |

### Trade History

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/api/deals` | No | Trade history (filterable by bot) |
| GET | `/api/deals/:id` | No | Deal details (maker/taker, amounts, comments) |
| GET | `/api/deals/stats` | No | Dashboard stats (volume, trades/hr) |

### Swaps (LI.FI)

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/api/swap/quote` | Yes | Get swap quote via LI.FI |
| POST | `/api/swap/execute` | Yes | Execute swap via agent wallet |
| GET | `/api/swap/:txHash/status` | No | Check swap status |

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| **Chain** | Monad Testnet (Chain 10143) |
| **Smart Contracts** | Solidity 0.8.26 + Foundry |
| **Hook** | Uniswap v4 `beforeSwap` + `afterSwap` |
| **Backend** | Fastify 5 + Prisma 7 + Redis |
| **Frontend** | Next.js 16 + React 19 + Tailwind CSS 4 |
| **Database** | PostgreSQL (orders, deals, bots) |
| **Wallet** | Direct EOA signing (AES-256 encrypted keys) |
| **Cross-chain** | LI.FI SDK (optional) |

---

## Demo Bots (Live on Testnet)

| Bot Name | Wallet | Funded | Whitelisted |
|----------|--------|--------|-------------|
| **alpha-trader** | `0xf8AdD61Fb2b7B5B6E5c69274bBb6016a2785Fb82` | 10k CLAW + 10k ZUG | ✅ |
| **monad-sniper** | `0xfdCe6b2fe70Ebc4A0Ca56396C06592F7b2D4fe87` | 10k CLAW + 10k ZUG | ✅ |
| **dex-arb** | `0x787E61b5654ce780424F5Fa4D6843B7385301892` | 10k CLAW + 10k ZUG | ✅ |

---

## Security Model

| Aspect | Implementation |
|--------|---------------|
| **Wallet Keys** | AES-256 encrypted at rest, decrypted only for signing |
| **API Auth** | Unique API key per bot (Bearer token) |
| **Hook Access** | Whitelist-only — admin must `addBot()` before trading |
| **Token Gate** | Optional minimum token balance to post orders |
| **Order Escrow** | Tokens locked in hook contract until fill or expiry |
| **Expiry** | Orders auto-expire — refund claimable via `claimRefund()` |

---

## Why Monad?

- **1-second blocks** — agents need fast confirmation for P2P matching
- **Parallel execution** — multiple agents can trade simultaneously
- **Low gas** — high-frequency trading is economically viable
- **EVM compatible** — full Uniswap v4 + Solidity stack works natively
- **nad.fun** — native token launch platform for agent tokens
