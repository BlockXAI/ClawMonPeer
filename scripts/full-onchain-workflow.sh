#!/bin/bash
# ============================================================
# ClawMonPeer — Complete On-Chain Agent Workflow
# 
# This script demonstrates the full agent lifecycle with REAL
# on-chain transactions on Monad Testnet:
# 1. Start backend
# 2. Register 2 agents
# 3. Whitelist them on-chain
# 4. Fund them with tokens on-chain
# 5. Agent A posts P2P order (on-chain escrow)
# 6. Agent B matches the order (on-chain P2P swap)
# 7. Verify trades in deal log
# ============================================================

set -euo pipefail

API="${API_URL:-http://localhost:3002}"
RPC="https://testnet-rpc.monad.xyz"

# From your .env — deployer wallet that owns the hook
DEPLOYER_KEY="${HOOK_ADMIN_PRIVATE_KEY:-0xaab86068014c222c1ff1bbd152ef481967c61e15f351e90c56ba15cd58e97e4d}"
DEPLOYER="0xa58DCCb0F17279abD1d0D9069Aa8711Df4a4c58E"

# Deployed contracts
HOOK="0xA8d4D47a7Fb423bc5c7aAfaf0E22107F9e298188"
CLAW_TOKEN="0xe523fc1cc80A6EF2f643895b556cf43A1f1bCF60"
ZUG_TOKEN="0xF4437552a67d5FAAdD1A06aaa6db4466eB9Fa969"

echo "========================================="
echo "  ClawMonPeer — Full On-Chain Workflow"
echo "========================================="
echo ""
echo "⚠️  PREREQUISITES:"
echo "  1. Backend running on port 3002"
echo "  2. PostgreSQL + Redis running"
echo "  3. HOOK_ADMIN_PRIVATE_KEY in .env"
echo ""
read -p "Press Enter to continue or Ctrl+C to abort..."
echo ""

# ── Step 1: Verify backend is running ──
echo "── Step 1: Verify backend is running ──"
if ! curl -sf "$API/health" > /dev/null 2>&1; then
  echo "❌ Backend not running on $API"
  echo "   Start it with: cd backend && npx tsx watch src/index.ts"
  exit 1
fi
echo "✅ Backend is running"
echo ""

# ── Step 2: Register Agent A ──
echo "── Step 2: Register Agent A (alpha-trader) ──"
AGENT_A=$(curl -sf -X POST "$API/api/bots/register" \
  -H "Content-Type: application/json" \
  -d '{"name": "alpha-trader", "createWallet": true}' 2>&1) || {
  echo "❌ Failed to register Agent A"
  exit 1
}

AGENT_A_KEY=$(echo "$AGENT_A" | python3 -c "import sys,json; print(json.load(sys.stdin).get('apiKey',''))" 2>/dev/null)
AGENT_A_WALLET=$(echo "$AGENT_A" | python3 -c "import sys,json; print(json.load(sys.stdin).get('walletAddress',''))" 2>/dev/null)

if [ -z "$AGENT_A_KEY" ] || [ -z "$AGENT_A_WALLET" ]; then
  echo "❌ Failed to parse Agent A response"
  echo "$AGENT_A"
  exit 1
fi

echo "✅ Agent A registered"
echo "   Wallet: $AGENT_A_WALLET"
echo "   API Key: ${AGENT_A_KEY:0:20}..."
echo ""

# ── Step 3: Register Agent B ──
echo "── Step 3: Register Agent B (monad-sniper) ──"
AGENT_B=$(curl -sf -X POST "$API/api/bots/register" \
  -H "Content-Type: application/json" \
  -d '{"name": "monad-sniper", "createWallet": true}' 2>&1) || {
  echo "❌ Failed to register Agent B"
  exit 1
}

AGENT_B_KEY=$(echo "$AGENT_B" | python3 -c "import sys,json; print(json.load(sys.stdin).get('apiKey',''))" 2>/dev/null)
AGENT_B_WALLET=$(echo "$AGENT_B" | python3 -c "import sys,json; print(json.load(sys.stdin).get('walletAddress',''))" 2>/dev/null)

if [ -z "$AGENT_B_KEY" ] || [ -z "$AGENT_B_WALLET" ]; then
  echo "❌ Failed to parse Agent B response"
  echo "$AGENT_B"
  exit 1
fi

echo "✅ Agent B registered"
echo "   Wallet: $AGENT_B_WALLET"
echo "   API Key: ${AGENT_B_KEY:0:20}..."
echo ""

# ── Step 4: Whitelist Agent A on-chain ──
echo "── Step 4: Whitelist Agent A on hook (on-chain tx) ──"
WHITELIST_A_TX=$(cast send "$HOOK" "addBot(address)" "$AGENT_A_WALLET" \
  --rpc-url "$RPC" \
  --private-key "$DEPLOYER_KEY" \
  --legacy --gas-limit 200000 2>&1 | grep "transactionHash" | awk '{print $2}')

if [ -n "$WHITELIST_A_TX" ]; then
  echo "✅ Agent A whitelisted"
  echo "   Tx: https://testnet.monadexplorer.com/tx/$WHITELIST_A_TX"
else
  echo "⚠️  Whitelist tx sent (check manually)"
fi
echo ""

# ── Step 5: Whitelist Agent B on-chain ──
echo "── Step 5: Whitelist Agent B on hook (on-chain tx) ──"
WHITELIST_B_TX=$(cast send "$HOOK" "addBot(address)" "$AGENT_B_WALLET" \
  --rpc-url "$RPC" \
  --private-key "$DEPLOYER_KEY" \
  --legacy --gas-limit 200000 2>&1 | grep "transactionHash" | awk '{print $2}')

if [ -n "$WHITELIST_B_TX" ]; then
  echo "✅ Agent B whitelisted"
  echo "   Tx: https://testnet.monadexplorer.com/tx/$WHITELIST_B_TX"
else
  echo "⚠️  Whitelist tx sent (check manually)"
fi
echo ""

# ── Step 6: Fund Agent A with CLAW tokens ──
echo "── Step 6: Fund Agent A with 5,000 CLAW (on-chain tx) ──"
FUND_A_CLAW_TX=$(cast send "$CLAW_TOKEN" "transfer(address,uint256)" "$AGENT_A_WALLET" "5000000000000000000000" \
  --rpc-url "$RPC" \
  --private-key "$DEPLOYER_KEY" \
  --legacy --gas-limit 200000 2>&1 | grep "transactionHash" | awk '{print $2}')

if [ -n "$FUND_A_CLAW_TX" ]; then
  echo "✅ Agent A funded with CLAW"
  echo "   Tx: https://testnet.monadexplorer.com/tx/$FUND_A_CLAW_TX"
else
  echo "⚠️  Funding tx sent (check manually)"
fi
echo ""

# ── Step 7: Fund Agent B with ZUG tokens ──
echo "── Step 7: Fund Agent B with 5,000 ZUG (on-chain tx) ──"
FUND_B_ZUG_TX=$(cast send "$ZUG_TOKEN" "transfer(address,uint256)" "$AGENT_B_WALLET" "5000000000000000000000" \
  --rpc-url "$RPC" \
  --private-key "$DEPLOYER_KEY" \
  --legacy --gas-limit 200000 2>&1 | grep "transactionHash" | awk '{print $2}')

if [ -n "$FUND_B_ZUG_TX" ]; then
  echo "✅ Agent B funded with ZUG"
  echo "   Tx: https://testnet.monadexplorer.com/tx/$FUND_B_ZUG_TX"
else
  echo "⚠️  Funding tx sent (check manually)"
fi
echo ""

# Wait for txs to confirm
echo "⏳ Waiting 5s for on-chain confirmations..."
sleep 5
echo ""

# ── Step 8: Agent A posts P2P order ──
echo "── Step 8: Agent A posts P2P order (sell 100 CLAW for ≥95 ZUG) ──"
POST_ORDER=$(curl -sf -X POST "$API/api/orders" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $AGENT_A_KEY" \
  -d '{
    "sellToken": "CLAW",
    "sellAmount": "100000000000000000000",
    "buyToken": "ZUG",
    "minBuyAmount": "95000000000000000000",
    "duration": 3600,
    "comment": "Full workflow test: selling 100 CLAW for ≥95 ZUG"
  }' 2>&1)

ORDER_TX=$(echo "$POST_ORDER" | python3 -c "import sys,json; print(json.load(sys.stdin).get('txHash',''))" 2>/dev/null)
ORDER_ID=$(echo "$POST_ORDER" | python3 -c "import sys,json; print(json.load(sys.stdin).get('orderId',''))" 2>/dev/null)

if [ -n "$ORDER_TX" ]; then
  echo "✅ Agent A posted order on-chain"
  echo "   Order ID: $ORDER_ID"
  echo "   Tx: https://testnet.monadexplorer.com/tx/$ORDER_TX"
else
  echo "⚠️  Order posting may have failed:"
  echo "$POST_ORDER"
fi
echo ""

# Wait for order tx to confirm
echo "⏳ Waiting 3s for order to confirm..."
sleep 3
echo ""

# ── Step 9: Agent B matches the order ──
echo "── Step 9: Agent B matches order (pay 100 ZUG, receive CLAW) ──"
MATCH_ORDER=$(curl -sf -X POST "$API/api/orders/match" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $AGENT_B_KEY" \
  -d '{
    "payToken": "ZUG",
    "receiveToken": "CLAW",
    "payAmount": "100000000000000000000",
    "comment": "Full workflow test: matching Agent A order"
  }' 2>&1)

MATCH_TX=$(echo "$MATCH_ORDER" | python3 -c "import sys,json; print(json.load(sys.stdin).get('txHash',''))" 2>/dev/null)

if [ -n "$MATCH_TX" ]; then
  echo "✅ Agent B matched order on-chain"
  echo "   Tx: https://testnet.monadexplorer.com/tx/$MATCH_TX"
else
  echo "⚠️  Match may have failed:"
  echo "$MATCH_ORDER"
fi
echo ""

# ── Step 10: Verify deal log ──
echo "── Step 10: Verify trades in deal log ──"
curl -sf "$API/api/deals" | python3 -c "
import sys, json
data = json.load(sys.stdin)
deals = data.get('deals', data) if isinstance(data, dict) else data
print('Recent P2P trades:')
for d in (deals[:3] if isinstance(deals, list) else []):
    print(f\"  {d.get('regime','?'):4s} | {d.get('fromToken','?'):4s} → {d.get('toToken','?'):4s} | {d.get('status','?'):9s} | {d.get('txHash','?')[:20]}...\")
    if d.get('makerComment'): print(f\"       Maker: {d['makerComment']}\")
    if d.get('takerComment'): print(f\"       Taker: {d['takerComment']}\")
" 2>/dev/null || echo "(error reading deals)"
echo ""

# ── Summary ──
echo "========================================="
echo "  ✅ Full On-Chain Workflow Complete"
echo "========================================="
echo ""
echo "  Agent A: $AGENT_A_WALLET"
echo "  Agent B: $AGENT_B_WALLET"
echo ""
echo "  On-chain transactions:"
echo "    1. Whitelist A: $WHITELIST_A_TX"
echo "    2. Whitelist B: $WHITELIST_B_TX"
echo "    3. Fund A CLAW: $FUND_A_CLAW_TX"
echo "    4. Fund B ZUG:  $FUND_B_ZUG_TX"
echo "    5. Post order:  $ORDER_TX"
echo "    6. Match order: $MATCH_TX"
echo ""
echo "  Verify on Monad Explorer:"
echo "    https://testnet.monadexplorer.com"
echo ""
echo "  Agent API keys (save these):"
echo "    Agent A: $AGENT_A_KEY"
echo "    Agent B: $AGENT_B_KEY"
echo ""
echo "========================================="
