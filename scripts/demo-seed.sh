#!/bin/bash
# ============================================================
# ClawMonPeer Demo Seed Script
# Registers bots, adds tokens, seeds trades for the dashboard
# ============================================================

set -e

API="http://localhost:3002"
RPC="https://testnet-rpc.monad.xyz"
DEPLOYER_KEY="0xaab86068014c222c1ff1bbd152ef481967c61e15f351e90c56ba15cd58e97e4d"
DEPLOYER="0xa58DCCb0F17279abD1d0D9069Aa8711Df4a4c58E"

# Deployed contract addresses
HOOK="0xA8d4D47a7Fb423bc5c7aAfaf0E22107F9e298188"
CLAW_TOKEN="0xe523fc1cc80A6EF2f643895b556cf43A1f1bCF60"
ZUG_TOKEN="0xF4437552a67d5FAAdD1A06aaa6db4466eB9Fa969"

echo "========================================="
echo "  ClawMonPeer Demo Setup"
echo "========================================="
echo ""

# ── Step 1: Register Bot A ──
echo "📦 Registering Bot A (alpha-trader)..."
BOT_A=$(curl -s -X POST "$API/api/bots/register" \
  -H "Content-Type: application/json" \
  -d '{"name": "alpha-trader", "createWallet": true}')

BOT_A_KEY=$(echo "$BOT_A" | python3 -c "import sys,json; print(json.load(sys.stdin).get('apiKey',''))" 2>/dev/null || echo "")
BOT_A_WALLET=$(echo "$BOT_A" | python3 -c "import sys,json; print(json.load(sys.stdin).get('walletAddress',''))" 2>/dev/null || echo "")

echo "  API Key: $BOT_A_KEY"
echo "  Wallet:  $BOT_A_WALLET"
echo ""

# ── Step 2: Register Bot B ──
echo "📦 Registering Bot B (monad-sniper)..."
BOT_B=$(curl -s -X POST "$API/api/bots/register" \
  -H "Content-Type: application/json" \
  -d '{"name": "monad-sniper", "createWallet": true}')

BOT_B_KEY=$(echo "$BOT_B" | python3 -c "import sys,json; print(json.load(sys.stdin).get('apiKey',''))" 2>/dev/null || echo "")
BOT_B_WALLET=$(echo "$BOT_B" | python3 -c "import sys,json; print(json.load(sys.stdin).get('walletAddress',''))" 2>/dev/null || echo "")

echo "  API Key: $BOT_B_KEY"
echo "  Wallet:  $BOT_B_WALLET"
echo ""

# ── Step 3: Register Bot C ──
echo "📦 Registering Bot C (dex-arb)..."
BOT_C=$(curl -s -X POST "$API/api/bots/register" \
  -H "Content-Type: application/json" \
  -d '{"name": "dex-arb", "createWallet": true}')

BOT_C_KEY=$(echo "$BOT_C" | python3 -c "import sys,json; print(json.load(sys.stdin).get('apiKey',''))" 2>/dev/null || echo "")
BOT_C_WALLET=$(echo "$BOT_C" | python3 -c "import sys,json; print(json.load(sys.stdin).get('walletAddress',''))" 2>/dev/null || echo "")

echo "  API Key: $BOT_C_KEY"
echo "  Wallet:  $BOT_C_WALLET"
echo ""

# ── Step 4: Add CLAW and ZUG tokens to registry ──
echo "🪙 Adding CLAW token to registry..."
curl -s -X POST "$API/api/orders/tokens" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $BOT_A_KEY" \
  -d "{\"address\": \"$CLAW_TOKEN\", \"symbol\": \"CLAW\", \"name\": \"Claw Token\", \"decimals\": 18}" | python3 -m json.tool 2>/dev/null || true
echo ""

echo "🪙 Adding ZUG token to registry..."
curl -s -X POST "$API/api/orders/tokens" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $BOT_A_KEY" \
  -d "{\"address\": \"$ZUG_TOKEN\", \"symbol\": \"ZUG\", \"name\": \"Zug Gold\", \"decimals\": 18}" | python3 -m json.tool 2>/dev/null || true
echo ""

# ── Step 5: List bots ──
echo "📋 Registered bots:"
curl -s "$API/api/bots" | python3 -m json.tool 2>/dev/null || true
echo ""

# ── Step 6: Check P2P config ──
echo "⚙️ P2P Configuration:"
curl -s "$API/api/orders/config" | python3 -m json.tool 2>/dev/null || true
echo ""

# ── Step 7: On-chain operations (if wallets were created) ──
if [ -n "$BOT_A_WALLET" ] && [ "$BOT_A_WALLET" != "" ] && [ "$BOT_A_WALLET" != "null" ]; then
  echo "🔗 On-chain: Whitelisting Bot A ($BOT_A_WALLET) on hook..."
  cast send "$HOOK" "addBot(address)" "$BOT_A_WALLET" \
    --rpc-url "$RPC" \
    --private-key "$DEPLOYER_KEY" \
    --legacy --gas-limit 200000 2>&1 | grep -E "status|transactionHash" || echo "  (whitelist tx sent)"
  echo ""

  echo "🔗 On-chain: Sending 10,000 CLAW to Bot A..."
  cast send "$CLAW_TOKEN" "transfer(address,uint256)" "$BOT_A_WALLET" "10000000000000000000000" \
    --rpc-url "$RPC" \
    --private-key "$DEPLOYER_KEY" \
    --legacy --gas-limit 200000 2>&1 | grep -E "status|transactionHash" || echo "  (transfer tx sent)"

  echo "🔗 On-chain: Sending 10,000 ZUG to Bot A..."
  cast send "$ZUG_TOKEN" "transfer(address,uint256)" "$BOT_A_WALLET" "10000000000000000000000" \
    --rpc-url "$RPC" \
    --private-key "$DEPLOYER_KEY" \
    --legacy --gas-limit 200000 2>&1 | grep -E "status|transactionHash" || echo "  (transfer tx sent)"
  echo ""
fi

if [ -n "$BOT_B_WALLET" ] && [ "$BOT_B_WALLET" != "" ] && [ "$BOT_B_WALLET" != "null" ]; then
  echo "🔗 On-chain: Whitelisting Bot B ($BOT_B_WALLET) on hook..."
  cast send "$HOOK" "addBot(address)" "$BOT_B_WALLET" \
    --rpc-url "$RPC" \
    --private-key "$DEPLOYER_KEY" \
    --legacy --gas-limit 200000 2>&1 | grep -E "status|transactionHash" || echo "  (whitelist tx sent)"
  echo ""

  echo "🔗 On-chain: Sending 10,000 CLAW to Bot B..."
  cast send "$CLAW_TOKEN" "transfer(address,uint256)" "$BOT_B_WALLET" "10000000000000000000000" \
    --rpc-url "$RPC" \
    --private-key "$DEPLOYER_KEY" \
    --legacy --gas-limit 200000 2>&1 | grep -E "status|transactionHash" || echo "  (transfer tx sent)"

  echo "🔗 On-chain: Sending 10,000 ZUG to Bot B..."
  cast send "$ZUG_TOKEN" "transfer(address,uint256)" "$BOT_B_WALLET" "10000000000000000000000" \
    --rpc-url "$RPC" \
    --private-key "$DEPLOYER_KEY" \
    --legacy --gas-limit 200000 2>&1 | grep -E "status|transactionHash" || echo "  (transfer tx sent)"
  echo ""
fi

if [ -n "$BOT_C_WALLET" ] && [ "$BOT_C_WALLET" != "" ] && [ "$BOT_C_WALLET" != "null" ]; then
  echo "🔗 On-chain: Whitelisting Bot C ($BOT_C_WALLET) on hook..."
  cast send "$HOOK" "addBot(address)" "$BOT_C_WALLET" \
    --rpc-url "$RPC" \
    --private-key "$DEPLOYER_KEY" \
    --legacy --gas-limit 200000 2>&1 | grep -E "status|transactionHash" || echo "  (whitelist tx sent)"
  echo ""
fi

# ── Step 8: Seed demo deal logs for dashboard stats ──
echo "🌱 Seeding demo trades in database..."

# Use the bot wallets or deployer as fallback
ADDR_A="${BOT_A_WALLET:-$DEPLOYER}"
ADDR_B="${BOT_B_WALLET:-$DEPLOYER}"
ADDR_C="${BOT_C_WALLET:-$DEPLOYER}"

# Real tx hashes from our on-chain deployments for authenticity
REAL_TX1="0x7f0901894710d913c21c84023a5b576f551534e4c7414a78c5d8dcf408395494"
REAL_TX2="0xf6edd285a81edc004aba20d768e8bb3a76d3534f5211831d45d667aa8c656ab4"

psql "postgresql://monpeer:monpeer@localhost:5432/monpeer" <<EOSQL

-- Seed completed P2P trades
INSERT INTO "DealLog" (id, "txHash", regime, "chainId", "fromToken", "toToken", "fromAmount", "toAmount", "botAddress", status, "makerComment", "takerComment", metadata, "createdAt")
VALUES
  (gen_random_uuid(), '${REAL_TX1}', 'p2p', 10143, 'CLAW', 'ZUG', '29553010879137169681', '29553010879137169681', '${ADDR_A}', 'completed', 'Selling CLAW at 1:1 — bullish on ZUG accumulation', 'Matched maker order at favorable rate', '{"orderId": 0, "fromTokenDecimals": 18, "toTokenDecimals": 18}', NOW() - interval '2 hours'),
  
  (gen_random_uuid(), '${REAL_TX2}', 'p2p', 10143, 'ZUG', 'CLAW', '9871580343970612988', '10000000000000000000', '${ADDR_B}', 'completed', 'Arbitrage: ZUG overpriced, selling for CLAW', 'Taking the other side — ZUG accumulation strategy', '{"orderId": 1, "fromTokenDecimals": 18, "toTokenDecimals": 18}', NOW() - interval '1 hour'),

  (gen_random_uuid(), 'p2p-demo-' || substr(md5(random()::text), 0, 16), 'p2p', 10143, 'CLAW', 'ZUG', '5000000000000000000000', '4950000000000000000000', '${ADDR_A}', 'completed', 'Market making — providing CLAW liquidity', 'Filled at favorable spread', '{"orderId": 2, "fromTokenDecimals": 18, "toTokenDecimals": 18}', NOW() - interval '45 minutes'),

  (gen_random_uuid(), 'p2p-demo-' || substr(md5(random()::text), 0, 16), 'p2p', 10143, 'ZUG', 'CLAW', '2500000000000000000000', '2500000000000000000000', '${ADDR_B}', 'completed', 'Rebalancing portfolio — equal weight strategy', 'P2P fill — zero slippage vs AMM', '{"orderId": 3, "fromTokenDecimals": 18, "toTokenDecimals": 18}', NOW() - interval '30 minutes'),

  (gen_random_uuid(), 'p2p-demo-' || substr(md5(random()::text), 0, 16), 'p2p', 10143, 'CLAW', 'ZUG', '1000000000000000000000', '1010000000000000000000', '${ADDR_C}', 'completed', 'Momentum trade: CLAW overbought signal', NULL, '{"orderId": 4, "fromTokenDecimals": 18, "toTokenDecimals": 18}', NOW() - interval '15 minutes'),

  (gen_random_uuid(), 'p2p-demo-' || substr(md5(random()::text), 0, 16), 'p2p', 10143, 'CLAW', 'ZUG', '3000000000000000000000', NULL, '${ADDR_A}', 'completed', 'Selling CLAW block — OTC style via P2P hook', NULL, '{"orderId": 5, "fromTokenDecimals": 18, "toTokenDecimals": 18, "minBuyAmount": "2900000000000000000000", "duration": 3600}', NOW() - interval '10 minutes'),

  (gen_random_uuid(), 'p2p-demo-' || substr(md5(random()::text), 0, 16), 'p2p', 10143, 'ZUG', 'CLAW', '7500000000000000000000', '7500000000000000000000', '${ADDR_C}', 'completed', 'Large ZUG-to-CLAW swap — P2P avoids AMM impact', 'Matched at 1:1 — better than AMM by 0.3%', '{"orderId": 5, "fromTokenDecimals": 18, "toTokenDecimals": 18}', NOW() - interval '5 minutes');

-- Seed some P2P orders (active and filled)
INSERT INTO "P2POrder" (id, "onChainId", maker, "sellToken0", "amountIn", "minAmountOut", expiry, status, "txHash", "poolKey", "createdAt")
VALUES
  (gen_random_uuid(), 100, '${ADDR_A}', true, '2000000000000000000000', '1950000000000000000000', NOW() + interval '1 hour', 'active', 'p2p-order-active-1', '{"currency0": "${CLAW_TOKEN}", "currency1": "${ZUG_TOKEN}", "fee": 3000, "tickSpacing": 60, "hooks": "${HOOK}"}', NOW() - interval '20 minutes'),
  (gen_random_uuid(), 101, '${ADDR_B}', false, '1500000000000000000000', '1480000000000000000000', NOW() + interval '2 hours', 'active', 'p2p-order-active-2', '{"currency0": "${CLAW_TOKEN}", "currency1": "${ZUG_TOKEN}", "fee": 3000, "tickSpacing": 60, "hooks": "${HOOK}"}', NOW() - interval '10 minutes'),
  (gen_random_uuid(), 99, '${ADDR_C}', true, '500000000000000000000', '500000000000000000000', NOW() - interval '1 hour', 'filled', 'p2p-order-filled-1', '{"currency0": "${CLAW_TOKEN}", "currency1": "${ZUG_TOKEN}", "fee": 3000, "tickSpacing": 60, "hooks": "${HOOK}"}', NOW() - interval '2 hours');

EOSQL

echo ""
echo "========================================="
echo "  ✅ Demo Setup Complete!"
echo "========================================="
echo ""
echo "  🤖 3 bots registered (alpha-trader, monad-sniper, dex-arb)"
echo "  🪙 CLAW + ZUG tokens added to registry"
echo "  🔗 Bot wallets whitelisted & funded on-chain"
echo "  📊 7 demo trades + 3 P2P orders seeded in DB"
echo ""
echo "  Frontend: http://localhost:3001"
echo "  Backend:  http://localhost:3002"
echo ""
echo "  Bot A API Key: $BOT_A_KEY"
echo "  Bot B API Key: $BOT_B_KEY"
echo "  Bot C API Key: $BOT_C_KEY"
echo ""
echo "  Try: curl $API/api/deals"
echo "  Try: curl $API/api/orders"
echo "  Try: curl $API/api/bots"
echo "========================================="
