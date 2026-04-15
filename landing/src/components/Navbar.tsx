import { useState, useEffect } from "react"
import { Download, Globe, Users } from "lucide-react"
import { useI18n } from "../lib/i18n"
import CommunityModal from "./CommunityModal"
import logo from "../lib/logo"

export default function Navbar() {
  const [scrolled, setScrolled] = useState(false)
  const [communityOpen, setCommunityOpen] = useState(false)
  const { lang, setLang, t } = useI18n()

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 40)
    window.addEventListener("scroll", onScroll)
    return () => window.removeEventListener("scroll", onScroll)
  }, [])

  return (
    <>
      <nav
        className={`fixed top-0 left-0 right-0 z-50 transition-all duration-500 ${
          scrolled
            ? "bg-deep/70 backdrop-blur-xl border-b border-white/[0.04]"
            : "bg-transparent"
        }`}
      >
        <div className="max-w-6xl mx-auto px-4 sm:px-6 h-14 sm:h-16 flex items-center justify-between">
          <a href="#" className="flex items-center gap-2 group">
            <img src={logo} alt="MioIsland" className="w-6 h-6 rounded group-hover:scale-110 transition-transform" />
            <span className="font-mono text-xs sm:text-sm font-bold text-text-primary tracking-[0.15em]">
              MIOISLAND
            </span>
          </a>

          <div className="flex items-center gap-3 sm:gap-6">
            {/* GitHub link - desktop only */}
            <a
              href="https://github.com/MioMioOS/MioIsland"
              className="hidden md:flex items-center gap-1.5 text-xs text-text-muted hover:text-text-primary transition-colors"
            >
              <svg width={14} height={14} viewBox="0 0 24 24" fill="currentColor"><path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"/></svg>
              <span className="hidden lg:inline">GitHub</span>
            </a>

            {/* Language switcher */}
            <button
              onClick={() => setLang(lang === "zh" ? "en" : "zh")}
              className="flex items-center gap-1 text-xs text-text-muted hover:text-text-primary transition-colors"
            >
              <Globe size={14} />
              <span className="hidden sm:inline">{lang === "zh" ? "EN" : "中文"}</span>
            </button>

            {/* Community button */}
            <button
              onClick={() => setCommunityOpen(true)}
              className="flex items-center gap-1.5 sm:gap-2 text-green-bright border border-green/25 px-3 sm:px-4 py-1.5 sm:py-2 rounded-lg text-xs sm:text-sm font-medium hover:bg-green/10 hover:border-green/40 transition-all cursor-pointer"
            >
              <Users size={14} />
              <span className="hidden sm:inline">{t("community.join")}</span>
            </button>

            {/* Download button */}
            <a
              href="https://github.com/MioMioOS/MioIsland/releases"
              className="flex items-center gap-1.5 sm:gap-2 bg-green/10 text-green border border-green/20 px-3 sm:px-4 py-1.5 sm:py-2 rounded-lg text-xs sm:text-sm font-medium hover:bg-green/20 hover:border-green/30 transition-all"
            >
              <Download size={14} />
              <span className="hidden sm:inline">{t("nav.download")}</span>
            </a>
          </div>
        </div>
      </nav>

      <CommunityModal open={communityOpen} onClose={() => setCommunityOpen(false)} />
    </>
  )
}
