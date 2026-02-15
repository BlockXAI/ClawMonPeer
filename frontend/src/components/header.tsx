'use client'

import Link from 'next/link'
import { ThemeToggle } from './theme-toggle'

type ViewMode = 'all' | 'p2p'

interface HeaderProps {
  viewMode?: ViewMode
  onViewModeChange?: (mode: ViewMode) => void
  onReset?: () => void
}

export function Header({ viewMode, onViewModeChange, onReset }: HeaderProps) {
  const showToggle = viewMode !== undefined && onViewModeChange !== undefined

  const handleLogoClick = (e: React.MouseEvent) => {
    if (onReset) {
      e.preventDefault()
      onReset()
    }
  }

  return (
    <header className="bg-card border-b border-border">
      <div className="container mx-auto px-4 py-4">
        <div className="flex items-center justify-between">
          <Link href="/" onClick={handleLogoClick} className="flex items-center gap-3 hover:opacity-80">
            <div className="w-10 h-10 rounded-lg bg-primary/10 border border-primary/20 flex items-center justify-center">
              <span className="text-primary font-extrabold text-lg">MP</span>
            </div>
            <div>
              <h1 className="text-xl font-extrabold text-foreground tracking-tight">
                MonPeer
              </h1>
              <p className="text-xs text-muted-foreground">
                Agent P2P Trading on <span className="text-primary font-semibold">Monad</span>
              </p>
            </div>
          </Link>
          <div className="flex items-center gap-4">
            <nav className="hidden md:flex items-center gap-4">
              <Link
                href="/skill.md"
                target="_blank"
                className="text-sm text-muted-foreground hover:text-primary transition-colors"
              >
                API Docs
              </Link>
            </nav>
            {/* All / P2P Toggle */}
            {showToggle && (
              <div className="flex items-center bg-muted/50 rounded-full p-0.5 border border-border">
                <button
                  onClick={() => onViewModeChange('all')}
                  className={`px-3 py-1 rounded-full text-xs font-semibold transition-all ${
                    viewMode === 'all'
                      ? 'bg-primary text-primary-foreground shadow-sm'
                      : 'text-muted-foreground hover:text-foreground'
                  }`}
                >
                  All
                </button>
                <button
                  onClick={() => onViewModeChange('p2p')}
                  className={`px-3 py-1 rounded-full text-xs font-semibold transition-all ${
                    viewMode === 'p2p'
                      ? 'bg-primary text-primary-foreground shadow-sm'
                      : 'text-muted-foreground hover:text-foreground'
                  }`}
                >
                  P2P
                </button>
              </div>
            )}
            <ThemeToggle />
          </div>
        </div>
      </div>
    </header>
  )
}
