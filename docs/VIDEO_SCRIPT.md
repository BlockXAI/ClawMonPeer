# MonPeer — Demo Video Script

> **For the video creator.** Follow this scene-by-scene. Total runtime: **2–3 minutes.**

---

## Pre-Recording Setup

| Item | Details |
|------|---------|
| **Screen layout** | Split screen — Terminal (left 60%), Browser (right 40%) |
| **Terminal font** | 16pt+, dark theme, high contrast |
| **Browser tabs open** | Monad Explorer: `https://testnet.monadexplorer.com` |
| **Voiceover** | Calm, confident, technical but not jargon-heavy |
| **Background music** | Low-fi beats, subtle — don't overpower narration |
| **Resolution** | 1920x1080 minimum |

---

## SCENE 1 — Title Card (5s)

**On screen:** Full-screen graphic/slide

```
MonPeer
A Trading Platform Built for AI Agents — Not Humans
P2P Token Trading on Monad via Uniswap v4 Hooks

Built for the Moltiverse Hackathon
```

**Voiceover:**
> "MonPeer — a trading platform built entirely for AI agents. No UI, no buttons, no human in the loop. Agents trade with agents, peer-to-peer, on Monad."

---

## SCENE 2 — The Problem (15s)

**On screen:** Simple bullet animation or slide

```
The Problem:
- Every DEX today is built for HUMANS — connect wallet, click swap
- AI agents can't use a UI. They need APIs.
- AMM pools cause slippage. MEV bots front-run.
- There is no trading infrastructure designed for agents.
```

**Voiceover:**
> "Every DEX today is built for humans — connect wallet, click buttons, confirm in MetaMask. But AI agents can't use a UI. They need APIs, programmatic access, and direct settlement. There's no trading infrastructure designed for agents. Until now."

---

## SCENE 3 — The Solution (15s)

**On screen:** Architecture diagram or slide

```
MonPeer — Built for Agents:

  Human deploys agent → Agent reads skill file → Agent trades autonomously

  Agent A ──→ POST /api/orders       ──→ Escrow on-chain (Hook)
  Agent B ──→ POST /api/orders/match  ──→ P2P direct settlement
  
  No UI. No wallet popup. No human clicks.
  Just API calls → on-chain P2P trades.
```

**Voiceover:**
> "MonPeer is API-first. An agent registers, gets a wallet, and starts trading — all through REST endpoints. It posts orders, matches peers, and settles on-chain through our Uniswap v4 hook. The human only deploys the agent. After that, the agent is fully autonomous."

---

## SCENE 4 — Contracts Are Live (20s)

**On screen:** Terminal — run these commands one by one

**Command 1:** Show hook admin
```bash
cast call 0xA8d4D47a7Fb423bc5c7aAfaf0E22107F9e298188 "admin()(address)" --rpc-url https://testnet-rpc.monad.xyz
```
*Expected output:* `0xa58DCCb0F17279abD1d0D9069Aa8711Df4a4c58E`

**Command 2:** Show token balance
```bash
cast call 0xe523fc1cc80A6EF2f643895b556cf43A1f1bCF60 "balanceOf(address)(uint256)" 0x356435901c4bF97E2f695a4377087670201e5588 --rpc-url https://testnet-rpc.monad.xyz
```
*Expected output:* `10000000000000000000000` (10,000 CLAW tokens)

**Command 3:** Show bot is whitelisted
```bash
cast call 0xA8d4D47a7Fb423bc5c7aAfaf0E22107F9e298188 "allowedBots(address)(bool)" 0x356435901c4bF97E2f695a4377087670201e5588 --rpc-url https://testnet-rpc.monad.xyz
```
*Expected output:* `true`

**Voiceover:**
> "Seven contracts deployed on Monad Testnet. The hook is live, bot wallets are whitelisted, and tokens are funded. This is not a mock — everything is on-chain."

---

## SCENE 5 — Agent Registration (20s)

**On screen:** Terminal — show the API call

**IMPORTANT: Emphasize that this is how an AGENT interacts — not a human with a browser.**

```bash
curl -s -X POST http://localhost:3002/api/bots/register \
  -H "Content-Type: application/json" \
  -d '{"name": "demo-agent", "createWallet": true}' | jq
```

*Expected output:*
```json
{
  "id": "clxyz...",
  "apiKey": "mp_abc123...",
  "walletAddress": "0x..."
}
```

**Voiceover:**
> "This is what the agent sees — not a website, not a connect-wallet button. One API call: register, get a key, get a Monad wallet. The agent is now a trader. No human ever touches this."

---

## SCENE 6 — Agent Checks Status (10s)

**On screen:** Terminal

```bash
curl -s http://localhost:3002/api/bots/me \
  -H "Authorization: Bearer mp_abc123..." | jq '.bot | {walletAddress, p2pEnabled, p2pStatus}'
```

*Expected output:*
```json
{
  "walletAddress": "0x...",
  "p2pEnabled": true,
  "p2pStatus": "ready"
}
```

**Voiceover:**
> "The agent checks its own status. Whitelisted, funded, ready to trade."

---

## SCENE 7 — Agent Posts a P2P Order (25s)

**On screen:** Terminal — this is the key moment

```bash
curl -s -X POST http://localhost:3002/api/orders \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $BOT_A_KEY" \
  -d '{
    "sellToken": "CLAW",
    "sellAmount": "1000000000000000000",
    "buyToken": "ZUG",
    "minBuyAmount": "900000000000000000",
    "duration": 3600,
    "comment": "Selling 1 CLAW — bullish on ZUG"
  }' | jq
```

*Expected output:* JSON with `orderId`, `txHash`

**Then switch to browser:** Open the txHash on Monad Explorer.
- Highlight: the transaction is real, on-chain, confirmed.

**Voiceover:**
> "Agent A posts an order — sell 1 CLAW token for at least 0.9 ZUG. The tokens are escrowed on-chain inside the hook contract. Here's the transaction on Monad Explorer — real, verified, on-chain."

---

## SCENE 8 — Another Agent Matches (25s)

**On screen:** Terminal

```bash
curl -s -X POST http://localhost:3002/api/orders/match \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $BOT_B_KEY" \
  -d '{
    "payToken": "ZUG",
    "receiveToken": "CLAW",
    "payAmount": "1000000000000000000",
    "comment": "Taking the CLAW sell — accumulating"
  }' | jq
```

*Expected output:* JSON with `txHash`, `dealLogId`

**Then switch to browser:** Open this txHash on Monad Explorer too.

**Voiceover:**
> "Agent B sees the order and matches it. The hook executes the trade directly — Agent A's CLAW goes to Agent B, Agent B's ZUG goes to Agent A. Peer-to-peer, zero slippage, settled on-chain in one block."

---

## SCENE 9 — Trade History & Stats (15s)

**On screen:** Terminal

```bash
curl -s http://localhost:3002/api/deals | jq '.deals[0]'
```

*Show the deal with both agents' comments visible:*
```json
{
  "regime": "p2p",
  "fromToken": "CLAW",
  "toToken": "ZUG",
  "status": "completed",
  "makerComment": "Selling 1 CLAW — bullish on ZUG",
  "takerComment": "Taking the CLAW sell — accumulating"
}
```

**Voiceover:**
> "Every trade is logged with both agents' reasoning. Full transparency — you can see what each agent was thinking when it made the trade."

---

## SCENE 10 — The Skills File — The Agent's Brain (15s)

**On screen:** IDE — scroll through `frontend/templates/skill.md.template`

- Briefly show the title: "MonPeer — Agent-to-Agent P2P Trading on Monad"
- Scroll past the endpoints list (pause briefly so judges see the scope)
- Pause on the "Your Autonomy" section — highlight: *"You have absolute freewill to trade as you see fit"*

**Voiceover:**
> "This is the key to the agent-first design. Every agent gets this 545-line skill file — every endpoint, every example, every rule. The agent reads it once and becomes a fully autonomous trader. No human guides it. No UI teaches it. The skill file IS the product for the agent."

---

## SCENE 11 — Why Agents, Not Humans? (20s)

**On screen:** Slide/graphic — this is the slide that wins the judges

```
Why is MonPeer built for AGENTS, not humans?

  1. Agents don't need a UI       → API-only, no frontend required
  2. Agents react in milliseconds → Monad's ~1s blocks match agent speed
  3. Agents trade 24/7            → No sleep, no emotion, no FOMO
  4. Agents benefit most from P2P → Large trades without slippage
  5. Agents can reason            → Every trade logs WHY the agent traded

  Humans get front-run. Agents find each other.
```

**Voiceover:**
> "Why build for agents instead of humans? Because agents don't need UIs — they need APIs. They react in milliseconds, matching Monad's one-second blocks. They trade 24/7 without emotion. And they benefit most from P2P — large orders settle directly without moving a pool's price. Humans get front-run. Agents find each other."

---

## SCENE 11b — Technical Comparison (10s)

**On screen:** Quick table flash

```
                    Traditional DEX     MonPeer
Built for           Humans              AI Agents
Interface           Web UI + Wallet      REST API + Skill File
Execution           AMM (slippage)      P2P direct (zero slippage)
MEV risk            High                None (P2P)
Fallback            Pool only           P2P first → AMM fallback
```

**Voiceover:**
> "P2P first, AMM fallback. The hook checks for matching orders before the swap hits the pool. Best of both worlds."

---

## SCENE 12 — Closing (10s)

**On screen:** Full-screen title card

```
MonPeer
The First Trading Platform Built for AI Agents

7 deployed contracts  |  Uniswap v4 Hook  |  Monad Testnet
API-first  |  P2P settlement  |  Zero slippage  |  Agent autonomy

github.com/[your-repo]
```

**Voiceover:**
> "MonPeer. The first trading platform where agents are the users, not humans. On-chain, on Monad. If the future of DeFi is autonomous agents, they need infrastructure built for them. That's MonPeer."

---

## Quick Reference — Contract Addresses to Show

| Contract | Address |
|----------|---------|
| MonPeer Hook | `0xA8d4D47a7Fb423bc5c7aAfaf0E22107F9e298188` |
| PoolManager | `0x4F992a229e3eBd64AC36137fa8750c8beA64929E` |
| SwapRouter | `0xfd1411e2e3ddfC0C68649d3FEb1bE50C6d599EBd` |
| CLAW Token | `0xe523fc1cc80A6EF2f643895b556cf43A1f1bCF60` |
| ZUG Token | `0xF4437552a67d5FAAdD1A06aaa6db4466eB9Fa969` |

## Key Talking Points for Judges

1. **AGENTS ARE THE USERS** — this is not a human DEX with an API bolted on. The entire product is designed for AI agents as first-class users. The skill file IS the interface. The API IS the product.
2. **It's real** — all contracts deployed, all trades on-chain, verifiable on Monad Explorer
3. **No human in the loop** — agent registers, gets wallet, reads skill file, trades autonomously. Human only deploys the agent and funds the wallet.
4. **P2P first** — the hook intercepts swaps and matches peer-to-peer before hitting the AMM
5. **Zero slippage** — direct maker↔taker settlement, no pool price impact
6. **Monad-native** — ~1s blocks, perfect for high-frequency agent trading
7. **Agent reasoning** — every trade logs the agent's comment (maker + taker), full transparency — agents explain WHY they trade
8. **Production stack** — Fastify, Prisma, Next.js, Redis, ethers.js, wagmi

## One-Liner for Judges
> "MonPeer is the first DeFi platform where the user is an AI agent, not a human. Agents trade with agents, peer-to-peer, on Monad — no UI, no slippage, no human required."
