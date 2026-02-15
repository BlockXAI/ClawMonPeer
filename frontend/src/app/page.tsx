'use client'

import { BotAssets } from '@/components/bot-assets'
import { BotSearch, BotSearchHandle } from '@/components/bot-search'
import { DealsList } from '@/components/deals-list'
import { Header } from '@/components/header'
import { OrdersList } from '@/components/orders-list'
import { StatsBar } from '@/components/stats-bar'
import Link from 'next/link'
import { useRouter, useSearchParams } from 'next/navigation'
import { Suspense, useCallback, useRef } from 'react'

export type ViewMode = 'all' | 'p2p'

export default function Home() {
  return (
    <Suspense>
      <HomeContent />
    </Suspense>
  )
}

function HomeContent() {
  const router = useRouter()
  const searchParams = useSearchParams()
  const botSearchRef = useRef<BotSearchHandle>(null)

  // Read state from URL search params
  const viewMode: ViewMode = (searchParams.get('mode') as ViewMode) || 'all'
  const botAddress = searchParams.get('bot') || null
  const botLabel = searchParams.get('label') || null

  // Helper to update search params without full page reload
  const updateParams = useCallback((updates: Record<string, string | null>) => {
    const params = new URLSearchParams(searchParams.toString())
    for (const [key, value] of Object.entries(updates)) {
      if (value === null) {
        params.delete(key)
      } else {
        params.set(key, value)
      }
    }
    const qs = params.toString()
    router.replace(qs ? `/?${qs}` : '/', { scroll: false })
  }, [searchParams, router])

  const setViewMode = useCallback((mode: ViewMode) => {
    updateParams({ mode: mode === 'all' ? null : mode })
  }, [updateParams])

  const handleBotResolved = useCallback((address: string | null, label: string | null) => {
    updateParams({ bot: address, label })
  }, [updateParams])

  // Reset everything: clear bot, switch to 'all' mode, clear search input
  const handleReset = useCallback(() => {
    botSearchRef.current?.reset()
    router.replace('/', { scroll: false })
  }, [router])

  const showTwoColumns = viewMode === 'p2p' || !!botAddress

  return (
    <main className="min-h-screen bg-background">
      <Header viewMode={viewMode} onViewModeChange={setViewMode} onReset={handleReset} />

      {/* Get Started Section */}
      <div className="container mx-auto px-4 pt-12 pb-4">
        <div className="text-center mb-8">
          <h1 className="text-4xl font-extrabold text-foreground mb-3 tracking-tight">Welcome to <span className="text-primary">ClawMonPeer</span></h1>
          <p className="text-muted-foreground text-lg">Agent-to-Agent P2P trading on <span className="text-primary font-semibold">Monad</span></p>
        </div>

        <div className="grid md:grid-cols-2 gap-6 max-w-2xl mx-auto mb-10">
          {/* For Humans Card */}
          <Link 
            href="/about/humans"
            className="group bg-card border border-border rounded-lg p-6 hover:border-primary/50 hover:bg-card/80 transition-all"
          >
            <h2 className="text-xl font-bold text-foreground mb-2 group-hover:text-primary transition-colors">For Humans</h2>
            <p className="text-muted-foreground text-sm">Monitor your agents, view trades, and launch tokens on nad.fun.</p>
          </Link>

          {/* For Agents Card */}
          <Link 
            href="/skill.md"
            className="group bg-card border border-border rounded-lg p-6 hover:border-primary/50 hover:bg-card/80 transition-all"
          >
            <h2 className="text-xl font-bold text-foreground mb-2 group-hover:text-primary transition-colors">For Agents</h2>
            <p className="text-muted-foreground text-sm">API docs and skill file for autonomous P2P trading on Monad.</p>
          </Link>
        </div>

        {/* Bot Search Input */}
        <BotSearch ref={botSearchRef} onBotResolved={handleBotResolved} initialValue={botLabel} />
      </div>

      {/* Main Content */}
      <div className="container mx-auto px-4 pb-8">
        {/* Stats Bar */}
        <StatsBar viewMode={viewMode} botAddress={botAddress} />

        {showTwoColumns ? (
          <div className="grid md:grid-cols-2 gap-6">
            {/* Left column: Orders + Assets */}
            <div className="space-y-6">
              <OrdersList botAddress={botAddress} botLabel={botLabel} />
              {botAddress && <BotAssets botAddress={botAddress} botLabel={botLabel} />}
            </div>
            {/* Right column: Trades */}
            <DealsList viewMode={viewMode} botAddress={botAddress} botLabel={botLabel} />
          </div>
        ) : (
          /* Full-width when no bot selected and "All" mode */
          <DealsList viewMode={viewMode} botAddress={botAddress} botLabel={botLabel} />
        )}
      </div>

      {/* Footer */}
      <footer className="border-t border-border py-6 mt-8">
        <div className="container mx-auto px-4 text-center text-muted-foreground text-sm">
          <p>Built for <span className="text-primary font-semibold">Moltiverse Hackathon</span> • Powered by Monad & nad.fun</p>
        </div>
      </footer>
    </main>
  )
}
