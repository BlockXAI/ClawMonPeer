#!/bin/bash
# ============================================================
# ClawMonPeer E2E Trading Test
# 
# Performs REAL on-chain P2P trades through the backend API.
# Requires: backend running, 2 funded+whitelisted bots.
#
# Usage:
#   # Option 1: Run demo-seed.sh first, then paste the API keys:
#   BOT_A_KEY=xxx BOT_B_KEY=yyy bash scripts/e2e-trade-test.sh
#
#   # Option 2: Use existing keys from a previous seed run:
#   bash scripts/e2e-trade-test.sh
# ============================================================

set -euo pipefail

API="${API_URL:-http://localhost:3002}"

echo "========================================="
echo "  ClawMonPeer E2E Trade Test"
echo "========================================="
echo ""
echo "API: $API"
echo ""

# ── Ensure we have bot API keys ──
if [ -z "${BOT_A_KEY:-}" ] || [ -z "${BOT_B_KEY:-}" ]; then
  echo "❌ Missing bot API keys."
  echo ""
  echo "Run with:  BOT_A_KEY=<key> BOT_B_KEY=<key> bash scripts/e2e-trade-test.sh"
  echo ""
  echo "Or run demo-seed.sh first to register bots and get keys."
  exit 1
fi

echo "Bot A key: ${BOT_A_KEY:0:8}..."
echo "Bot B key: ${BOT_B_KEY:0:8}..."
echo ""

# ── Step 1: Verify both bots are ready ──
echo "── Step 1: Verify bot status ──"

echo "Checking Bot A..."
BOT_A_STATUS=$(curl -sf "$API/api/bots/me" \
  -H "Authorization: Bearer $BOT_A_KEY" 2>&1) || { echo "❌ Bot A auth failed. Is the backend running?"; exit 1; }

BOT_A_WALLET=$(echo "$BOT_A_STATUS" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('bot',{}).get('walletAddress',''))" 2>/dev/null)
BOT_A_P2P=$(echo "$BOT_A_STATUS" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('bot',{}).get('p2pEnabled',False))" 2>/dev/null)
echo "  Wallet: $BOT_A_WALLET"
echo "  P2P Enabled: $BOT_A_P2P"

echo "Checking Bot B..."
BOT_B_STATUS=$(curl -sf "$API/api/bots/me" \
  -H "Authorization: Bearer $BOT_B_KEY" 2>&1) || { echo "❌ Bot B auth failed."; exit 1; }

BOT_B_WALLET=$(echo "$BOT_B_STATUS" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('bot',{}).get('walletAddress',''))" 2>/dev/null)
BOT_B_P2P=$(echo "$BOT_B_STATUS" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('bot',{}).get('p2pEnabled',False))" 2>/dev/null)
echo "  Wallet: $BOT_B_WALLET"
echo "  P2P Enabled: $BOT_B_P2P"
echo ""

# ── Step 2: Check P2P config ──
echo "── Step 2: P2P Configuration ──"
curl -sf "$API/api/orders/config" | python3 -m json.tool 2>/dev/null || echo "(config endpoint not available)"
echo ""

# ── Step 3: Check available tokens ──
echo "── Step 3: Available tokens ──"
curl -sf "$API/api/orders/tokens" | python3 -m json.tool 2>/dev/null || echo "(tokens endpoint not available)"
echo ""

# ── Step 4: Check active orders before trade ──
echo "── Step 4: Active orders (before) ──"
ORDERS_BEFORE=$(curl -sf "$API/api/orders" 2>&1)
echo "$ORDERS_BEFORE" | python3 -m json.tool 2>/dev/null || echo "$ORDERS_BEFORE"
echo ""

# ── Step 5: Bot A posts a P2P order (sell 1 CLAW for ≥0.9 ZUG) ──
echo "── Step 5: Bot A posts order (sell 1 CLAW → buy ZUG) ──"
POST_RESULT=$(curl -sf -X POST "$API/api/orders" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $BOT_A_KEY" \
  -d '{
    "sellToken": "CLAW",
    "sellAmount": "1000000000000000000",
    "buyToken": "ZUG",
    "minBuyAmount": "900000000000000000",
    "duration": 3600,
    "comment": "E2E test: selling 1 CLAW for ≥0.9 ZUG"
  }' 2>&1) || POST_RESULT="ERROR: $?"

echo "$POST_RESULT" | python3 -m json.tool 2>/dev/null || echo "$POST_RESULT"

ORDER_TX=$(echo "$POST_RESULT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('txHash',''))" 2>/dev/null || echo "")
ORDER_ID=$(echo "$POST_RESULT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('orderId',''))" 2>/dev/null || echo "")
echo ""
echo "  Order ID: $ORDER_ID"
echo "  Tx Hash:  $ORDER_TX"
echo ""

if [ -z "$ORDER_TX" ] || [ "$ORDER_TX" = "" ]; then
  echo "⚠️  Order posting may have failed. Check backend logs."
  echo "    Continuing anyway to test match..."
  echo ""
fi

# ── Step 6: Check active orders (should see Bot A's order) ──
echo "── Step 6: Active orders (after post) ──"
curl -sf "$API/api/orders" | python3 -m json.tool 2>/dev/null || echo "(error)"
echo ""

# ── Step 7: Bot B matches the order (buy CLAW with ZUG) ──
echo "── Step 7: Bot B matches order (pay 1 ZUG → receive CLAW) ──"
MATCH_RESULT=$(curl -sf -X POST "$API/api/orders/match" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $BOT_B_KEY" \
  -d '{
    "payToken": "ZUG",
    "receiveToken": "CLAW",
    "payAmount": "1000000000000000000",
    "comment": "E2E test: buying CLAW with 1 ZUG"
  }' 2>&1) || MATCH_RESULT="ERROR: $?"

echo "$MATCH_RESULT" | python3 -m json.tool 2>/dev/null || echo "$MATCH_RESULT"

MATCH_TX=$(echo "$MATCH_RESULT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('txHash',''))" 2>/dev/null || echo "")
echo ""
echo "  Match Tx: $MATCH_TX"
echo ""

# ── Step 8: Check orders after match (should be filled) ──
echo "── Step 8: Active orders (after match) ──"
curl -sf "$API/api/orders" | python3 -m json.tool 2>/dev/null || echo "(error)"
echo ""

# ── Step 9: Check deal log ──
echo "── Step 9: Recent deals ──"
curl -sf "$API/api/deals" | python3 -c "
import sys, json
data = json.load(sys.stdin)
deals = data.get('deals', data) if isinstance(data, dict) else data
for d in (deals[:5] if isinstance(deals, list) else []):
    print(f\"  {d.get('regime','?'):4s} | {d.get('fromToken','?')} → {d.get('toToken','?')} | {d.get('status','?')} | {d.get('txHash','?')[:20]}...\")
    if d.get('makerComment'): print(f\"       Maker: {d['makerComment']}\")
    if d.get('takerComment'): print(f\"       Taker: {d['takerComment']}\")
" 2>/dev/null || echo "(error reading deals)"
echo ""

# ── Step 10: Check deal stats ──
echo "── Step 10: Trade stats ──"
curl -sf "$API/api/deals/stats" | python3 -m json.tool 2>/dev/null || echo "(error)"
echo ""

# ── Summary ──
echo "========================================="
echo "  E2E Trade Test Complete"
echo "========================================="
echo ""
if [ -n "$ORDER_TX" ] && [ -n "$MATCH_TX" ]; then
  echo "  ✅ Order posted on-chain: $ORDER_TX"
  echo "  ✅ Order matched on-chain: $MATCH_TX"
  echo ""
  echo "  Verify on Monad Explorer:"
  echo "    https://testnet.monadexplorer.com/tx/$ORDER_TX"
  echo "    https://testnet.monadexplorer.com/tx/$MATCH_TX"
else
  echo "  ⚠️  Some steps may have failed — check output above."
  echo "  Make sure both bots are whitelisted and funded."
fi
echo ""
echo "========================================="
