import { Cat, Zap, ShieldCheck, Monitor, Terminal, Bell, Activity, Globe } from "lucide-react"
import type { LucideIcon } from "lucide-react"
import { useI18n } from "../lib/i18n"
import SpotlightCard from "./reactbits/SpotlightCard"

export default function Features() {
  const { t } = useI18n()

  const features: { Icon: LucideIcon; titleKey: string; descKey: string; ascii: string }[] = [
    { Icon: Monitor, ascii: "[● ● ●]\n[  ...  ]\n[_______]", titleKey: "features.monitor.title", descKey: "features.monitor.desc" },
    { Icon: ShieldCheck, ascii: " [+3 -1]\n ───────\n  allow", titleKey: "features.approval.title", descKey: "features.approval.desc" },
    { Icon: Activity, ascii: "5h 74%\n7d 89%\n ████", titleKey: "features.smart.title", descKey: "features.smart.desc" },
    { Icon: Terminal, ascii: "  > _\n jump!\n  > _", titleKey: "features.jump.title", descKey: "features.jump.desc" },
    { Icon: Cat, ascii: "/\\_/\\\n( o.o )\n > ^ <", titleKey: "features.buddy.title", descKey: "features.buddy.desc" },
    { Icon: Bell, ascii: "  .-.\n | ! |\n  '-'", titleKey: "features.sound.title", descKey: "features.sound.desc" },
    { Icon: Zap, ascii: "  [*]\n  /|\\\n / | \\", titleKey: "features.zero.title", descKey: "features.zero.desc" },
    { Icon: Globe, ascii: " 中/EN\n ─────\n  auto", titleKey: "features.i18n.title", descKey: "features.i18n.desc" },
  ]

  return (
    <section id="features" className="relative z-20 bg-deep py-20 sm:py-32 px-4 sm:px-6 noise">
      <div className="absolute inset-0 bg-[radial-gradient(ellipse_80%_50%_at_50%_0%,rgba(52,211,153,0.04)_0%,transparent_60%)]" />
      <div className="max-w-6xl mx-auto relative z-10">
        <div style={{ animation: 'heroEnter 0.8s ease-out both' }} className="text-center mb-12 sm:mb-20">
          <span className="font-mono text-xs text-green uppercase tracking-[0.3em]">{t("features.tag")}</span>
          <h2 className="font-display text-3xl sm:text-4xl sm:text-5xl font-extrabold text-text-primary mt-4">{t("features.title")}</h2>
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-6">
          {features.map((f, i) => (
            <SpotlightCard
              key={f.titleKey}
              className="!rounded-2xl !p-5 sm:!p-7 !bg-white/[0.02] !border-white/[0.06] transition-all duration-500 hover:translate-y-[-4px]"
              spotlightColor="rgba(52, 211, 153, 0.15)"
            >
              <div style={{ animation: `heroEnter 0.6s ease-out ${i * 0.08}s both` }} className="group">
                <div className="flex items-start justify-between mb-4 sm:mb-5">
                  <div className="w-9 h-9 sm:w-10 sm:h-10 rounded-xl bg-green/10 border border-green/15 flex items-center justify-center">
                    <f.Icon size={18} className="text-green" />
                  </div>
                  <pre className="font-mono text-[9px] sm:text-[10px] leading-tight text-green/40 group-hover:text-green/70 transition-colors duration-500 text-right">{f.ascii}</pre>
                </div>
                <h3 className="font-display text-base sm:text-lg font-bold text-text-primary group-hover:text-green transition-colors duration-300">{t(f.titleKey as any)}</h3>
                <p className="text-xs sm:text-sm text-text-muted mt-2 leading-relaxed">{t(f.descKey as any)}</p>
              </div>
            </SpotlightCard>
          ))}
        </div>
      </div>
    </section>
  )
}
