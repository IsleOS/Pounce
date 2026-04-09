import { useState, useEffect, useCallback } from "react"
import { motion, AnimatePresence } from "motion/react"
import { LayoutGrid, ShieldCheck, MessageSquare, ArrowRight } from "lucide-react"
import type { LucideIcon } from "lucide-react"
import { useI18n } from "../lib/i18n"

type DemoState = "monitor" | "approve" | "ask" | "jump"

const pillDefs: { id: DemoState; labelKey: string; Icon: LucideIcon }[] = [
  { id: "monitor", labelKey: "demo.monitor", Icon: LayoutGrid },
  { id: "approve", labelKey: "demo.approve", Icon: ShieldCheck },
  { id: "ask", labelKey: "demo.ask", Icon: MessageSquare },
  { id: "jump", labelKey: "demo.jump", Icon: ArrowRight },
]

/* ─── Session Row (reusable) ─── */
function SessionRow({ name, status, statusColor, shadowColor, tool, terminal, terminalColor, duration, summary, active = true }: {
  name: string; status: string; statusColor: string; shadowColor: string;
  tool: string; terminal: string; terminalColor: string; duration: string;
  summary?: string; active?: boolean;
}) {
  return (
    <div className={`flex items-start gap-2.5 p-2.5 rounded-lg transition-colors ${active ? 'bg-white/[0.04]' : ''}`}>
      {/* Buddy + status dot */}
      <div className="relative shrink-0 mt-0.5">
        <span className="text-[18px]">🐢</span>
        <div className="absolute -bottom-0.5 -right-0.5 w-[6px] h-[6px] rounded-full" style={{ background: statusColor, boxShadow: `0 0 6px ${shadowColor}` }} />
      </div>
      {/* Content */}
      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-1.5">
          <span className="text-[11px] font-semibold text-white/90 truncate">{name}</span>
          {/* Status badge */}
          <span className="text-[8px] font-semibold px-1.5 py-0.5 rounded-full shrink-0" style={{ color: statusColor, background: `${statusColor}22` }}>{status}</span>
          <span className="flex-1" />
          {/* Terminal tag */}
          <span className="text-[7px] font-semibold font-mono px-1.5 py-0.5 rounded-full shrink-0" style={{ color: terminalColor, background: `${terminalColor}1a` }}>{terminal}</span>
          <span className="text-[9px] text-white/30 font-mono shrink-0">{duration}</span>
          {/* Jump button */}
          <div className="w-[16px] h-[16px] rounded flex items-center justify-center shrink-0" style={{ background: 'rgba(74,222,128,0.1)' }}>
            <span className="text-[8px]" style={{ color: 'rgba(74,222,128,0.7)' }}>⌥</span>
          </div>
        </div>
        {summary && <div className="text-[9px] text-white/40 mt-0.5 truncate">{summary}</div>}
        {tool && <div className="flex items-center gap-1 mt-0.5"><span className="text-[8px] text-white/20">🔧</span><span className="text-[8px] text-white/30 font-mono truncate">{tool}</span></div>}
      </div>
    </div>
  )
}

/* ─── Monitor View ─── */
function MonitorView() {
  const { t } = useI18n()
  return (
    <div className="space-y-1">
      <SessionRow name="CodeIsland" status={t("demo.monitor")} statusColor="#66e8fa" shadowColor="rgba(102,232,250,0.5)" tool="Edit: NotchView.swift" terminal="cmux" terminalColor="#4ade80" duration="31m" summary="你: 帮我优化一下布局" />
      <div className="mx-3 h-px bg-gradient-to-r from-transparent via-white/[0.06] to-transparent" />
      <SessionRow name="icare" status="已完成" statusColor="#4ade80" shadowColor="rgba(74,222,128,0.5)" tool="Bash: npm run build" terminal="Terminal" terminalColor="#f59e04" duration="25m" summary="AI: 项目初始化完成" active={false} />
    </div>
  )
}

/* ─── Approve View ─── */
function ApproveView() {
  const { t } = useI18n()
  return (
    <div className="space-y-2.5">
      {/* Header */}
      <div className="flex items-center gap-1.5">
        <div className="w-2 h-2 rounded-full" style={{ background: '#f59e04' }} />
        <span className="text-[11px] font-semibold" style={{ color: '#ffb333' }}>{t("demo.permissionRequest")}</span>
      </div>
      {/* Tool info */}
      <div className="flex items-center gap-1.5">
        <span className="text-[9px]" style={{ color: '#ffb333' }}>⚠</span>
        <span className="text-[10px] font-medium text-white/90">Write</span>
        <span className="text-[9px] font-mono text-white/40">src/auth/middleware.ts</span>
      </div>
      {/* Diff preview */}
      <div className="rounded-lg overflow-hidden" style={{ background: '#111118' }}>
        <div className="px-2 py-1 text-[9px] font-mono" style={{ background: 'rgba(74,222,128,0.1)', color: 'rgba(74,222,128,0.8)' }}>+ if (!token) throw new AuthError('missing');</div>
        <div className="px-2 py-1 text-[9px] font-mono" style={{ background: 'rgba(74,222,128,0.1)', color: 'rgba(74,222,128,0.8)' }}>+ validateRefreshToken(req.cookies);</div>
        <div className="px-2 py-1 text-[9px] font-mono" style={{ background: 'rgba(239,68,68,0.1)', color: 'rgba(239,68,68,0.8)' }}>- jwt.verify(token);</div>
      </div>
      {/* Diff summary */}
      <div className="flex gap-2">
        <span className="text-[9px] font-mono font-medium" style={{ color: '#4ade80' }}>+2</span>
        <span className="text-[9px] font-mono font-medium" style={{ color: '#ef4444' }}>-1</span>
      </div>
      {/* Buttons */}
      <div className="flex gap-2">
        <button className="flex-1 py-2 rounded-lg text-[11px] font-medium text-white/70" style={{ background: 'rgba(255,255,255,0.08)', border: '1px solid rgba(255,255,255,0.12)' }}>{t("demo.deny")} <span className="text-white/30 text-[9px]">⌘N</span></button>
        <button className="flex-1 py-2 rounded-lg text-[11px] font-bold text-black" style={{ background: '#4ade80' }}>{t("demo.allow")} <span className="text-black/40 text-[9px]">⌘Y</span></button>
      </div>
    </div>
  )
}

/* ─── Ask View ─── */
function AskView() {
  const { t } = useI18n()
  return (
    <div className="space-y-2.5">
      <div className="flex items-center gap-1.5">
        <span className="text-[10px]" style={{ color: '#f59e04' }}>💬</span>
        <span className="text-[10px] font-medium" style={{ color: 'rgba(245,158,4,0.8)' }}>{t("demo.claudeAsking")}</span>
      </div>
      <div className="p-2.5 rounded-lg" style={{ background: 'rgba(255,255,255,0.03)', border: '1px solid rgba(255,255,255,0.04)' }}>
        <p className="text-[10px] text-white/70 leading-relaxed">"{t("demo.claudeQuestion")}"</p>
      </div>
      {/* Option buttons - amber style like real app */}
      <div className="flex gap-1.5">
        <button className="flex-1 py-1.5 rounded text-[9px] font-medium text-white/80" style={{ background: 'rgba(245,158,4,0.15)', border: '0.5px solid rgba(245,158,4,0.2)' }}>{t("demo.yes")}</button>
        <button className="flex-1 py-1.5 rounded text-[9px] font-medium text-white/80" style={{ background: 'rgba(245,158,4,0.15)', border: '0.5px solid rgba(245,158,4,0.2)' }}>{t("demo.no")}</button>
        <button className="w-8 py-1.5 rounded flex items-center justify-center" style={{ background: 'rgba(245,158,4,0.1)' }}>
          <span className="text-[9px]" style={{ color: 'rgba(245,158,4,0.5)' }}>⌥</span>
        </button>
      </div>
    </div>
  )
}

/* ─── Jump View ─── */
function JumpView() {
  const { t } = useI18n()
  return (
    <div className="space-y-2.5">
      <SessionRow name="CodeIsland" status={t("demo.monitor")} statusColor="#66e8fa" shadowColor="rgba(102,232,250,0.5)" tool="Edit: NotchView.swift" terminal="cmux" terminalColor="#4ade80" duration="31m" />
      <div className="mt-3 p-3 rounded-lg text-center" style={{ background: 'rgba(74,222,128,0.06)', border: '1px solid rgba(74,222,128,0.15)' }}>
        <div className="font-mono text-xl mb-1" style={{ color: '#4ade80', textShadow: '0 0 12px rgba(74,222,128,0.4)' }}>→→→</div>
        <div className="text-[11px] text-white/80 font-medium">{t("demo.jumpToTerminal")}</div>
        <div className="text-[9px] text-white/40 font-mono mt-1">cmux · tab 2 · CodeIsland</div>
      </div>
    </div>
  )
}

const views: Record<DemoState, React.FC> = { monitor: MonitorView, approve: ApproveView, ask: AskView, jump: JumpView }

export default function NotchDemo() {
  const { t } = useI18n()
  const [active, setActive] = useState<DemoState>("monitor")
  const [paused, setPaused] = useState(false)

  const descMap: Record<DemoState, { titleKey: string; subKey: string }> = {
    monitor: { titleKey: "demo.monitorTitle", subKey: "demo.monitorSub" },
    approve: { titleKey: "demo.approveTitle", subKey: "demo.approveSub" },
    ask: { titleKey: "demo.askTitle", subKey: "demo.askSub" },
    jump: { titleKey: "demo.jumpTitle", subKey: "demo.jumpSub" },
  }

  const cycle = useCallback(() => {
    setActive((p) => {
      const idx = pillDefs.findIndex((x) => x.id === p)
      return pillDefs[(idx + 1) % pillDefs.length].id
    })
  }, [])

  useEffect(() => {
    if (paused) return
    const timer = setInterval(cycle, 4500)
    return () => clearInterval(timer)
  }, [paused, cycle])

  const pick = (id: DemoState) => {
    setActive(id)
    setPaused(true)
    setTimeout(() => setPaused(false), 12000)
  }

  const View = views[active]
  const desc = descMap[active]

  return (
    <section id="demo" className="relative z-20 py-20 sm:py-32 px-4 sm:px-6 noise bg-deep">
      <div className="absolute inset-0 bg-[radial-gradient(ellipse_80%_60%_at_50%_50%,rgba(124,58,237,0.05)_0%,transparent_70%)]" />

      <div className="max-w-3xl mx-auto relative z-10">
        <div style={{ animation: 'heroEnter 0.8s ease-out both' }} className="text-center mb-12 sm:mb-16">
          <span className="font-mono text-xs text-green uppercase tracking-[0.3em]">{t("demo.sectionTag")}</span>
          <h2 className="font-display text-3xl sm:text-4xl sm:text-5xl font-extrabold text-text-primary mt-4">{t("demo.sectionTitle")}</h2>
        </div>

        <div style={{ animation: 'heroEnter 0.8s ease-out 0.1s both' }} className="mx-auto max-w-2xl">
          <div className="relative">
            {/* Notch shape */}
            <div className="bg-black rounded-b-3xl pt-3 pb-5 px-5 sm:px-6 border border-white/[0.06] border-t-0 shadow-[0_20px_80px_rgba(0,0,0,0.6),0_0_0_1px_rgba(255,255,255,0.03)_inset]">
              {/* Header bar - matches real app */}
              <div className="flex items-center justify-between mb-3 pb-2 border-b border-white/[0.05]">
                <div className="flex items-center gap-2">
                  <span className="text-[14px]">🐢</span>
                  <span className="font-mono text-[11px] text-white/50">{t("demo.activeSessions")}</span>
                </div>
                <span className="text-[11px] text-white/20">⚙</span>
              </div>

              {/* Dynamic content */}
              <AnimatePresence mode="wait">
                <motion.div key={active} initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -8 }} transition={{ duration: 0.2 }} className="min-h-[200px]">
                  <View />
                </motion.div>
              </AnimatePresence>
            </div>
          </div>
        </div>

        {/* Pills */}
        <div className="flex flex-wrap justify-center gap-2 mt-8 sm:mt-10">
          {pillDefs.map((p) => (
            <button
              key={p.id}
              onClick={() => pick(p.id)}
              className={`flex items-center gap-1.5 font-mono text-xs px-3 sm:px-4 py-2 rounded-full border transition-all duration-300 cursor-pointer ${
                active === p.id
                  ? "bg-green/10 border-green/25 text-green shadow-[0_0_16px_rgba(52,211,153,0.1)]"
                  : "border-white/[0.06] text-text-muted hover:border-white/[0.12] hover:text-text-secondary"
              }`}
            >
              <p.Icon size={12} />
              {t(p.labelKey as any)}
            </button>
          ))}
        </div>

        {/* Description */}
        <AnimatePresence mode="wait">
          <motion.div key={active} initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0 }} transition={{ duration: 0.2 }} className="text-center mt-6 sm:mt-8 px-4">
            <h3 className="font-display text-xl sm:text-2xl font-bold text-text-primary">{t(desc.titleKey as any)}</h3>
            <p className="text-sm text-text-muted mt-2 max-w-md mx-auto">{t(desc.subKey as any)}</p>
          </motion.div>
        </AnimatePresence>
      </div>
    </section>
  )
}
