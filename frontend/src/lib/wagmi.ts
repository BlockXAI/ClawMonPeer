/**
 * Wagmi Configuration for MonPeer
 * 
 * Configured for Monad Testnet + Mainnet.
 */
import { http, createConfig, type Chain } from 'wagmi'

// Monad Testnet chain definition
const monadTestnet: Chain = {
  id: 10143,
  name: 'Monad Testnet',
  nativeCurrency: { name: 'Monad', symbol: 'MON', decimals: 18 },
  rpcUrls: {
    default: { http: [process.env.NEXT_PUBLIC_MONAD_RPC_URL || 'https://testnet-rpc.monad.xyz'] },
  },
  blockExplorers: {
    default: { name: 'Monad Explorer', url: 'https://testnet.monadexplorer.com' },
  },
  testnet: true,
}

// Monad Mainnet chain definition
const monadMainnet: Chain = {
  id: 143,
  name: 'Monad',
  nativeCurrency: { name: 'Monad', symbol: 'MON', decimals: 18 },
  rpcUrls: {
    default: { http: [process.env.NEXT_PUBLIC_MONAD_MAINNET_RPC_URL || 'https://rpc.monad.xyz'] },
  },
  blockExplorers: {
    default: { name: 'Monad Explorer', url: 'https://monadexplorer.com' },
  },
  testnet: false,
}

export const wagmiConfig = createConfig({
  chains: [monadTestnet, monadMainnet],
  transports: {
    [monadTestnet.id]: http(),
    [monadMainnet.id]: http(),
  },
  ssr: true,
})

// Export chain IDs for use in components
export const MONAD_TESTNET_CHAIN_ID = monadTestnet.id
export const MONAD_MAINNET_CHAIN_ID = monadMainnet.id
export const MONAD_EXPLORER = monadTestnet.blockExplorers.default.url
