/**
 * nad.fun Token Routes for ClawMonPeer
 *
 * POST /api/token/launch    — Launch a new token on nad.fun bonding curve
 * GET  /api/token/info      — Get token info from nad.fun Lens contract
 * GET  /api/token/config    — Get nad.fun contract addresses and ClawMonPeer token info
 */
import { FastifyInstance, FastifyReply, FastifyRequest } from 'fastify'
import { authenticateBot } from '../auth.js'
import { DEFAULT_CHAIN_ID, getBlockExplorerUrl } from '../config/chains.js'
import { MONPEER_TOKEN_ADDRESS, NADFUN_CONTRACTS } from '../services/p2p.js'
import { getTokenInfo, launchToken } from '../services/nadfun.js'
import type { Hex } from 'viem'

interface LaunchTokenBody {
  name: string
  symbol: string
  description: string
  imageUrl?: string
  initialBuyMon?: string
}

export async function nadfunRoutes(fastify: FastifyInstance) {

  // GET /api/token/config — nad.fun configuration info (public)
  fastify.get('/config', async () => {
    return {
      success: true,
      nadfun: {
        bondingCurveRouter: NADFUN_CONTRACTS.BONDING_CURVE_ROUTER,
        curve: NADFUN_CONTRACTS.CURVE,
        lens: NADFUN_CONTRACTS.LENS,
        dexRouter: NADFUN_CONTRACTS.DEX_ROUTER,
        wmon: NADFUN_CONTRACTS.WMON,
      },
      monpeerToken: MONPEER_TOKEN_ADDRESS,
      chainId: DEFAULT_CHAIN_ID,
      explorer: getBlockExplorerUrl(DEFAULT_CHAIN_ID),
    }
  })

  // GET /api/token/info?address=0x... — Get token info from Lens contract
  fastify.get('/info', async (request: FastifyRequest<{ Querystring: { address: string } }>, reply: FastifyReply) => {
    const { address } = request.query as { address?: string }
    if (!address || !/^0x[a-fA-F0-9]{40}$/.test(address)) {
      return reply.status(400).send({ error: 'Valid token address required (?address=0x...)' })
    }

    try {
      const info = await getTokenInfo(address as Hex)
      if (!info) {
        return reply.status(404).send({ error: 'Token not found or Lens contract not configured' })
      }
      return { success: true, token: info }
    } catch (error) {
      return reply.status(500).send({
        error: 'Failed to fetch token info',
        details: (error as Error).message,
      })
    }
  })

  // POST /api/token/launch — Launch a new token on nad.fun (admin only)
  fastify.post<{ Body: LaunchTokenBody }>('/launch', async (request: FastifyRequest<{ Body: LaunchTokenBody }>, reply: FastifyReply) => {
    const bot = await authenticateBot(request)
    if (!bot) {
      return reply.status(401).send({ error: 'Unauthorized' })
    }

    const adminKey = process.env.HOOK_ADMIN_PRIVATE_KEY
    if (!adminKey) {
      return reply.status(503).send({
        error: 'Token launch not configured',
        reason: 'HOOK_ADMIN_PRIVATE_KEY environment variable is required for token launches',
      })
    }

    const { name, symbol, description, imageUrl, initialBuyMon } = request.body

    if (!name || !symbol || !description) {
      return reply.status(400).send({
        error: 'Missing required fields: name, symbol, description',
      })
    }

    try {
      const result = await launchToken({
        name,
        symbol,
        description,
        imageUrl,
        adminPrivateKey: adminKey,
        initialBuyMon,
      })

      return {
        success: true,
        token: result,
        message: `Token ${result.symbol} launched on nad.fun!`,
        nextSteps: [
          `Set MONPEER_TOKEN_ADDRESS=${result.tokenAddress} in your .env`,
          'Optionally set MIN_TOKEN_BALANCE to enable token-gated P2P trading',
        ],
      }
    } catch (error) {
      console.error('[nad.fun] Token launch failed:', error)
      return reply.status(500).send({
        error: 'Token launch failed',
        details: (error as Error).message,
      })
    }
  })
}
