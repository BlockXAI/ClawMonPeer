/**
 * nad.fun Token Launch Integration for ClawMonPeer
 *
 * Provides the full flow to launch a token on nad.fun's bonding curve:
 *  1. Upload token image → get image_uri
 *  2. Upload metadata → get metadata_uri
 *  3. Get deterministic salt
 *  4. Call BondingCurveRouter.create() → get token address
 *
 * Also provides helpers for querying token info via the Lens contract,
 * and swapping via the DexRouter.
 *
 * All contract addresses are configurable via environment variables.
 */
import { createWalletClient, encodeFunctionData, http, parseEther, type Hex } from 'viem'
import { privateKeyToAccount } from 'viem/accounts'
import { DEFAULT_CHAIN_ID, getBlockExplorerUrl, getRpcUrl, getViemChain } from '../config/chains.js'
import { NADFUN_CONTRACTS } from './p2p.js'

// ── nad.fun API base URL ──
const NADFUN_API_URL = process.env.NADFUN_API_URL || 'https://testnet-api.nad.fun'

// ── ABIs (minimal for the functions we call) ──

const BONDING_CURVE_ROUTER_ABI = [
  {
    name: 'create',
    type: 'function',
    stateMutability: 'payable',
    inputs: [
      { name: 'token', type: 'address' },
      { name: 'name', type: 'string' },
      { name: 'symbol', type: 'string' },
      { name: 'tokenURI', type: 'string' },
    ],
    outputs: [],
  },
] as const

const LENS_ABI = [
  {
    name: 'getTokenInfo',
    type: 'function',
    stateMutability: 'view',
    inputs: [{ name: 'token', type: 'address' }],
    outputs: [
      {
        name: '',
        type: 'tuple',
        components: [
          { name: 'token', type: 'address' },
          { name: 'name', type: 'string' },
          { name: 'symbol', type: 'string' },
          { name: 'tokenURI', type: 'string' },
          { name: 'totalSupply', type: 'uint256' },
          { name: 'curveProgress', type: 'uint256' },
          { name: 'isListed', type: 'bool' },
        ],
      },
    ],
  },
] as const

const DEX_ROUTER_ABI = [
  {
    name: 'swapExactETHForTokens',
    type: 'function',
    stateMutability: 'payable',
    inputs: [
      { name: 'amountOutMin', type: 'uint256' },
      { name: 'path', type: 'address[]' },
      { name: 'to', type: 'address' },
      { name: 'deadline', type: 'uint256' },
    ],
    outputs: [{ name: 'amounts', type: 'uint256[]' }],
  },
  {
    name: 'swapExactTokensForETH',
    type: 'function',
    stateMutability: 'nonpayable',
    inputs: [
      { name: 'amountIn', type: 'uint256' },
      { name: 'amountOutMin', type: 'uint256' },
      { name: 'path', type: 'address[]' },
      { name: 'to', type: 'address' },
      { name: 'deadline', type: 'uint256' },
    ],
    outputs: [{ name: 'amounts', type: 'uint256[]' }],
  },
] as const


// ── Token Launch Flow ──

export interface TokenLaunchParams {
  name: string
  symbol: string
  description: string
  imageUrl?: string       // external image URL (will be uploaded to nad.fun)
  adminPrivateKey: string  // raw private key (0x...) for signing the create tx
  initialBuyMon?: string   // optional: MON amount to buy on the bonding curve at creation
}

export interface TokenLaunchResult {
  tokenAddress: Hex
  txHash: string
  explorer: string
  name: string
  symbol: string
}

/**
 * Step 1: Upload token image to nad.fun
 * Returns the image URI hosted by nad.fun
 */
export async function uploadTokenImage(imageUrl: string): Promise<string> {
  const res = await fetch(`${NADFUN_API_URL}/agent/token/image`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ image_url: imageUrl }),
  })
  if (!res.ok) throw new Error(`nad.fun image upload failed: ${res.status} ${await res.text()}`)
  const data = await res.json() as { image_uri: string }
  return data.image_uri
}

/**
 * Step 2: Upload token metadata to nad.fun
 * Returns the metadata URI
 */
export async function uploadTokenMetadata(params: {
  name: string
  symbol: string
  description: string
  imageUri: string
}): Promise<string> {
  const res = await fetch(`${NADFUN_API_URL}/agent/token/metadata`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      name: params.name,
      symbol: params.symbol,
      description: params.description,
      image_uri: params.imageUri,
    }),
  })
  if (!res.ok) throw new Error(`nad.fun metadata upload failed: ${res.status} ${await res.text()}`)
  const data = await res.json() as { metadata_uri: string }
  return data.metadata_uri
}

/**
 * Step 3: Get deterministic salt for token creation
 * Returns the salt and predicted token address
 */
export async function getTokenSalt(params: {
  deployer: string
  name: string
  symbol: string
  tokenURI: string
}): Promise<{ salt: Hex; tokenAddress: Hex }> {
  const res = await fetch(`${NADFUN_API_URL}/agent/salt`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      deployer: params.deployer,
      name: params.name,
      symbol: params.symbol,
      token_uri: params.tokenURI,
    }),
  })
  if (!res.ok) throw new Error(`nad.fun salt request failed: ${res.status} ${await res.text()}`)
  const data = await res.json() as { salt: string; token_address: string }
  return {
    salt: data.salt as Hex,
    tokenAddress: data.token_address as Hex,
  }
}

/**
 * Full token launch flow:
 *  1. Upload image (if provided)
 *  2. Upload metadata
 *  3. Get salt + predicted address
 *  4. Call BondingCurveRouter.create()
 */
export async function launchToken(params: TokenLaunchParams): Promise<TokenLaunchResult> {
  console.log(`[nad.fun] Launching token: ${params.name} (${params.symbol})`)

  // Step 1: Image
  let imageUri = ''
  if (params.imageUrl) {
    console.log('[nad.fun] Uploading image...')
    imageUri = await uploadTokenImage(params.imageUrl)
    console.log(`[nad.fun] Image URI: ${imageUri}`)
  }

  // Step 2: Metadata
  console.log('[nad.fun] Uploading metadata...')
  const metadataUri = await uploadTokenMetadata({
    name: params.name,
    symbol: params.symbol,
    description: params.description,
    imageUri,
  })
  console.log(`[nad.fun] Metadata URI: ${metadataUri}`)

  // Step 3: Salt
  const signer = privateKeyToAccount(params.adminPrivateKey as Hex)
  console.log(`[nad.fun] Getting salt for deployer ${signer.address}...`)
  const { salt, tokenAddress } = await getTokenSalt({
    deployer: signer.address,
    name: params.name,
    symbol: params.symbol,
    tokenURI: metadataUri,
  })
  console.log(`[nad.fun] Predicted token address: ${tokenAddress}`)

  // Step 4: Create on-chain
  const walletClient = createWalletClient({
    account: signer,
    chain: getViemChain(DEFAULT_CHAIN_ID),
    transport: http(getRpcUrl(DEFAULT_CHAIN_ID)),
  })

  const createData = encodeFunctionData({
    abi: BONDING_CURVE_ROUTER_ABI,
    functionName: 'create',
    args: [tokenAddress, params.name, params.symbol, metadataUri],
  })

  const value = params.initialBuyMon ? parseEther(params.initialBuyMon) : 0n

  console.log(`[nad.fun] Calling BondingCurveRouter.create() with ${value} MON...`)
  const txHash = await walletClient.sendTransaction({
    to: NADFUN_CONTRACTS.BONDING_CURVE_ROUTER,
    data: createData,
    value,
  })

  console.log(`[nad.fun] Token launched! tx: ${txHash}`)

  return {
    tokenAddress,
    txHash,
    explorer: `${getBlockExplorerUrl(DEFAULT_CHAIN_ID)}/tx/${txHash}`,
    name: params.name,
    symbol: params.symbol,
  }
}


// ── Token Info Query ──

export interface NadFunTokenInfo {
  token: string
  name: string
  symbol: string
  tokenURI: string
  totalSupply: string
  curveProgress: string
  isListed: boolean
}

/**
 * Query token info from the nad.fun Lens contract
 */
export async function getTokenInfo(tokenAddress: Hex): Promise<NadFunTokenInfo | null> {
  if (NADFUN_CONTRACTS.LENS === '0x0000000000000000000000000000000000000000') {
    return null
  }

  try {
    const { createBlockchainClient } = await import('./wallet.js')
    const publicClient = createBlockchainClient(DEFAULT_CHAIN_ID)

    const result = await publicClient.readContract({
      address: NADFUN_CONTRACTS.LENS,
      abi: LENS_ABI,
      functionName: 'getTokenInfo',
      args: [tokenAddress],
    }) as any

    return {
      token: result.token,
      name: result.name,
      symbol: result.symbol,
      tokenURI: result.tokenURI,
      totalSupply: result.totalSupply.toString(),
      curveProgress: result.curveProgress.toString(),
      isListed: result.isListed,
    }
  } catch (error) {
    console.error('[nad.fun] Failed to get token info:', error)
    return null
  }
}
