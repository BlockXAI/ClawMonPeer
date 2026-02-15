-- CreateTable
CREATE TABLE "BotAuth" (
    "id" TEXT NOT NULL,
    "apiKey" TEXT NOT NULL,
    "ensName" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "BotAuth_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "BotWallet" (
    "id" TEXT NOT NULL,
    "walletAddress" TEXT NOT NULL,
    "encryptedWalletKey" TEXT NOT NULL,
    "botAuthId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "BotWallet_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "DealLog" (
    "id" TEXT NOT NULL,
    "txHash" TEXT NOT NULL,
    "regime" TEXT NOT NULL,
    "chainId" INTEGER NOT NULL,
    "fromToken" TEXT NOT NULL,
    "toToken" TEXT NOT NULL,
    "fromAmount" TEXT NOT NULL,
    "toAmount" TEXT,
    "botAddress" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "makerComment" TEXT,
    "takerComment" TEXT,
    "metadata" JSONB,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "DealLog_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "P2POrder" (
    "id" TEXT NOT NULL,
    "onChainId" INTEGER NOT NULL,
    "maker" TEXT NOT NULL,
    "sellToken0" BOOLEAN NOT NULL,
    "amountIn" TEXT NOT NULL,
    "minAmountOut" TEXT NOT NULL,
    "expiry" TIMESTAMP(3) NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'active',
    "txHash" TEXT,
    "matchTxHash" TEXT,
    "poolKey" JSONB NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "P2POrder_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "BotAuth_apiKey_key" ON "BotAuth"("apiKey");

-- CreateIndex
CREATE UNIQUE INDEX "BotWallet_walletAddress_key" ON "BotWallet"("walletAddress");

-- CreateIndex
CREATE UNIQUE INDEX "BotWallet_botAuthId_key" ON "BotWallet"("botAuthId");

-- CreateIndex
CREATE UNIQUE INDEX "DealLog_txHash_key" ON "DealLog"("txHash");

-- CreateIndex
CREATE UNIQUE INDEX "P2POrder_onChainId_key" ON "P2POrder"("onChainId");

-- CreateIndex
CREATE INDEX "P2POrder_maker_idx" ON "P2POrder"("maker");

-- CreateIndex
CREATE INDEX "P2POrder_status_idx" ON "P2POrder"("status");

-- AddForeignKey
ALTER TABLE "BotWallet" ADD CONSTRAINT "BotWallet_botAuthId_fkey" FOREIGN KEY ("botAuthId") REFERENCES "BotAuth"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
