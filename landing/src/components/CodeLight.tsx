import { Smartphone, Download, Zap, ShieldCheck, Terminal, Camera, Link, Lock, MessageCircle } from "lucide-react"
import { useI18n } from "../lib/i18n"
import SpotlightCard from "./reactbits/SpotlightCard"
import TiltedCard from "./reactbits/TiltedCard"

const base = import.meta.env.BASE_URL

const featureIcons = [Smartphone, ShieldCheck, Terminal, Zap, Camera, Link, Lock]

export default function CodeLight() {
  const { t } = useI18n()

  const features = [1, 2, 3, 4, 5, 6, 7].map((i) => ({
    Icon: featureIcons[i - 1],
    title: t(`codelight.f${i}.title` as any),
    desc: t(`codelight.f${i}.desc` as any),
  }))

  return (
    <section id="codelight" className="relative z-20 bg-deep py-20 sm:py-32 px-4 sm:px-6 noise overflow-hidden">
      <div className="absolute inset-0 bg-[radial-gradient(ellipse_70%_50%_at_50%_0%,rgba(52,211,153,0.06)_0%,transparent_60%)]" />

      <div className="max-w-5xl mx-auto relative z-10">
        {/* Header */}
        <div className="text-center mb-12 sm:mb-16" style={{ animation: 'heroEnter 0.8s ease-out both' }}>
          <div className="flex items-center justify-center gap-2 mb-4">
            <Smartphone size={16} className="text-green" />
            <span className="font-mono text-xs text-green uppercase tracking-[0.3em]">{t("codelight.tag")}</span>
          </div>

          <h2 className="font-display text-3xl sm:text-5xl font-extrabold text-text-primary">
            {t("codelight.title")}
          </h2>

          <p className="text-base sm:text-lg text-text-muted mt-4 max-w-lg mx-auto italic">
            "{t("codelight.subtitle")}"
          </p>

          <p className="text-sm text-text-muted mt-4 max-w-xl mx-auto leading-relaxed">
            {t("codelight.desc")}
          </p>

          {/* Beta badge */}
          <div className="mt-6 inline-flex items-center gap-2 px-4 py-2 rounded-full border border-amber/20 bg-amber/5">
            <span className="w-2 h-2 rounded-full bg-amber animate-pulse" />
            <span className="font-mono text-xs text-amber font-medium">{t("codelight.beta")}</span>
          </div>
          <p className="text-xs text-text-muted/70 mt-2 max-w-md mx-auto">
            {t("codelight.betaDesc")}
          </p>
        </div>

        {/* Showcase - tilted screenshots */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-8 mb-16 max-w-3xl mx-auto" style={{ animation: 'heroEnter 0.8s ease-out 0.1s both' }}>
          {[
            { src: `${base}codelight/lockscreen-dynamic.png`, label: t("codelight.showcase.lockscreen") },
            { src: `${base}codelight/chat-workflow.png`, label: t("codelight.showcase.workflow") },
            { src: `${base}codelight/appstore-pairing.png`, label: t("codelight.showcase.appstore") },
          ].map((img, i) => (
            <TiltedCard
              key={i}
              imageSrc={img.src}
              altText={img.label}
              captionText={img.label}
              containerHeight="300px"
              containerWidth="100%"
              imageHeight="280px"
              imageWidth="100%"
              rotateAmplitude={8}
              scaleOnHover={1.04}
              showMobileWarning={false}
              showTooltip={false}
              displayOverlayContent={false}
            />
          ))}
        </div>

        {/* Feature cards grid */}
        <div style={{ animation: 'heroEnter 0.8s ease-out 0.3s both' }}>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3 sm:gap-4 mb-12">
            {features.map((f, i) => (
              <SpotlightCard
                key={i}
                className="!rounded-2xl !p-5 !bg-green/[0.03] !border-green/[0.12]"
                spotlightColor="rgba(52, 211, 153, 0.2)"
              >
                <div className="w-9 h-9 rounded-xl flex items-center justify-center mb-3" style={{ background: 'rgba(52,211,153,0.15)' }}>
                  <f.Icon size={18} className="text-green" />
                </div>
                <h4 className="text-sm font-bold text-text-primary mb-1">{f.title}</h4>
                <p className="text-xs text-text-muted leading-relaxed">{f.desc}</p>
              </SpotlightCard>
            ))}
          </div>
        </div>

        {/* Beta + CTA */}
        <div className="text-center" style={{ animation: 'heroEnter 0.8s ease-out 0.4s both' }}>
          <p className="text-xs text-text-muted mb-5">
            <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-amber/10 border border-amber/20 text-amber">
              <span className="w-1.5 h-1.5 rounded-full bg-amber animate-pulse" />
              {t("codelight.status")}
            </span>
          </p>

          <div className="flex flex-col sm:flex-row items-center justify-center gap-3">
            <a
              href="https://apps.apple.com/us/app/code-light/id6761744871"
              className="inline-flex items-center gap-2.5 px-8 py-3.5 rounded-xl font-mono text-sm text-deep font-bold bg-green transition-all duration-300 hover:scale-[1.03] hover:shadow-[0_0_30px_rgba(52,211,153,0.3)]"
            >
              <Download size={16} />
              {t("codelight.appstore")}
            </a>
          </div>

          <div className="mt-6 flex items-center justify-center gap-2 text-xs text-text-muted/60">
            <MessageCircle size={12} />
            <span>{t("codelight.feedbackCta")}</span>
          </div>

          <p className="text-xs text-text-muted/60 mt-3 max-w-md mx-auto">
            {t("codelight.regionNote")}
          </p>
        </div>
      </div>
    </section>
  )
}
