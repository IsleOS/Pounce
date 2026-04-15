import { Palette, Cat, Volume2, Puzzle, ExternalLink, Code2 } from "lucide-react"
import type { LucideIcon } from "lucide-react"
import { useI18n } from "../lib/i18n"
import SpotlightCard from "./reactbits/SpotlightCard"

export default function Plugins() {
  const { t } = useI18n()

  const categories: { Icon: LucideIcon; titleKey: string; descKey: string; count: number; ascii: string }[] = [
    { Icon: Palette, ascii: "🎨 ███\n   ▓▓▓\n   ░░░", titleKey: "plugins.theme.title", descKey: "plugins.theme.desc", count: 12 },
    { Icon: Cat, ascii: "/\\_/\\\n( ♥.♥ )\n > ~ <", titleKey: "plugins.buddy.title", descKey: "plugins.buddy.desc", count: 8 },
    { Icon: Volume2, ascii: "♪ ♫ ♪\n█▄█▄█\n█████", titleKey: "plugins.sound.title", descKey: "plugins.sound.desc", count: 6 },
    { Icon: Puzzle, ascii: "┌──┐\n│🔧│+\n└──┘", titleKey: "plugins.utility.title", descKey: "plugins.utility.desc", count: 10 },
  ]

  return (
    <section id="plugins" className="relative z-20 bg-deep py-20 sm:py-32 px-4 sm:px-6 noise">
      <div className="absolute inset-0 bg-[radial-gradient(ellipse_80%_50%_at_50%_0%,rgba(52,211,153,0.04)_0%,transparent_60%)]" />
      <div className="max-w-5xl mx-auto relative z-10">
        <div style={{ animation: 'heroEnter 0.8s ease-out both' }} className="text-center mb-12 sm:mb-20">
          <span className="font-mono text-xs text-green uppercase tracking-[0.3em]">{t("plugins.tag")}</span>
          <h2 className="font-display text-3xl sm:text-4xl sm:text-5xl font-extrabold text-text-primary mt-4">{t("plugins.title")}</h2>
          <p className="text-sm sm:text-base text-text-muted mt-4 max-w-2xl mx-auto leading-relaxed">{t("plugins.desc")}</p>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 sm:gap-6">
          {categories.map((c, i) => (
            <SpotlightCard
              key={c.titleKey}
              className="!rounded-2xl !p-5 sm:!p-7 !bg-white/[0.02] !border-white/[0.06] transition-all duration-500 hover:translate-y-[-4px]"
              spotlightColor="rgba(52, 211, 153, 0.15)"
            >
              <div style={{ animation: `heroEnter 0.6s ease-out ${i * 0.1}s both` }} className="group">
                <div className="flex items-start justify-between mb-4 sm:mb-5">
                  <div className="w-9 h-9 sm:w-10 sm:h-10 rounded-xl bg-green/10 border border-green/15 flex items-center justify-center">
                    <c.Icon size={18} className="text-green" />
                  </div>
                  <pre className="font-mono text-[9px] sm:text-[10px] leading-tight text-text-muted/30 group-hover:text-green/40 transition-colors duration-500 text-right">{c.ascii}</pre>
                </div>
                <h3 className="font-display text-base sm:text-lg font-bold text-text-primary group-hover:text-green transition-colors duration-300">{t(c.titleKey as any)}</h3>
                <p className="text-xs sm:text-sm text-text-muted mt-2 leading-relaxed">{t(c.descKey as any)}</p>
                <span className="inline-block mt-3 font-mono text-[10px] text-green/50">{c.count}+ plugins</span>
              </div>
            </SpotlightCard>
          ))}
        </div>

        <div style={{ animation: 'heroEnter 0.8s ease-out 0.5s both' }} className="flex flex-col sm:flex-row items-center justify-center gap-3 sm:gap-4 mt-10 sm:mt-14">
          <a
            href="https://miomio.chat/"
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-2 px-6 py-3 rounded-full text-deep font-display font-bold text-sm bg-green transition-all duration-300 hover:shadow-[0_0_24px_rgba(52,211,153,0.3)] hover:scale-[1.03]"
          >
            <ExternalLink size={16} />
            {t("plugins.browse")}
          </a>
          <a
            href="https://miomio.chat/"
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-2 px-6 py-3 rounded-full font-display font-bold text-sm text-green border border-green/30 transition-all duration-300 hover:bg-green/5"
          >
            <Code2 size={16} />
            {t("plugins.developer")}
          </a>
        </div>
      </div>
    </section>
  )
}
