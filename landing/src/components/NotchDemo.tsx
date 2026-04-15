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

/* ─── Terminal badge colors (matches real app TerminalColors.swift) ─── */
const terminalColors: Record<string, string> = {
  cmux: "rgba(102,153,255,0.9)",      // blue
  ghostty: "rgba(204,102,204,0.9)",    // purple
  iTerm2: "rgba(74,222,128,0.9)",      // green
  Warp: "rgba(255,179,0,0.9)",         // amber
  Terminal: "rgba(255,179,0,0.9)",     // amber
}

/* ─── Status colors (matches real app) ─── */
const statusColors = {
  working: { color: "#66e8fa", shadow: "rgba(102,232,250,0.5)", bg: "rgba(102,232,250,0.12)" },
  approval: { color: "#f59e04", shadow: "rgba(245,158,4,0.5)", bg: "rgba(245,158,4,0.12)" },
  done: { color: "#4ade80", shadow: "rgba(74,222,128,0.5)", bg: "rgba(74,222,128,0.12)" },
}

/* ─── Session Row (matches InstanceRow in ClaudeInstancesView.swift) ─── */
function SessionRow({ name, status, statusKey, tool, terminal, duration, summary, rolePrefix, active = true }: {
  name: string; status: string; statusKey: keyof typeof statusColors;
  tool?: string; terminal: string; duration: string;
  summary?: string; rolePrefix?: "you" | "ai"; active?: boolean;
}) {
  const sc = statusColors[statusKey]
  const tc = terminalColors[terminal] || "rgba(255,255,255,0.4)"

  return (
    <div
      className="flex items-start gap-2.5 px-2.5 py-2.5 rounded-lg transition-colors"
      style={{ background: active ? `${sc.color}08` : 'transparent' }}
    >
      {/* Buddy + animated status dot */}
      <div className="relative shrink-0 mt-0.5">
        <span className="text-[20px] block w-7 h-7 flex items-center justify-center">🐢</span>
        <div
          className="absolute -bottom-0.5 -right-0.5 w-[7px] h-[7px] rounded-full"
          style={{ background: sc.color, boxShadow: `0 0 8px ${sc.shadow}`, animation: active ? 'pulse 1.2s ease-in-out infinite' : 'none' }}
        />
      </div>

      {/* Content */}
      <div className="flex-1 min-w-0">
        {/* Title row */}
        <div className="flex items-center gap-1.5">
          <span className="text-[12px] font-semibold text-white/90 truncate">{name}</span>
          <span className="text-[8px] font-bold px-1.5 py-0.5 rounded-full shrink-0" style={{ color: sc.color, background: sc.bg }}>{status}</span>
          <span className="flex-1" />
          {/* Terminal badge - color coded */}
          <span className="text-[8px] font-semibold font-mono px-1.5 py-0.5 rounded shrink-0" style={{ color: tc, background: `${tc}15` }}>{terminal}</span>
          <span className="text-[10px] font-mono shrink-0" style={{ color: active ? sc.color : 'rgba(255,255,255,0.3)' }}>{duration}</span>
          {/* Jump button */}
          <div className="w-5 h-5 rounded flex items-center justify-center shrink-0" style={{ background: 'rgba(74,222,128,0.1)' }}>
            <span className="text-[9px] font-bold" style={{ color: 'rgba(74,222,128,0.7)' }}>⌥</span>
          </div>
        </div>

        {/* Smart summary with role prefix */}
        {summary && (
          <div className="text-[10px] mt-1 truncate">
            {rolePrefix === "you" && <span className="text-white/35 font-medium">You: </span>}
            {rolePrefix === "ai" && <span className="font-medium" style={{ color: 'rgba(102,232,250,0.7)' }}>AI: </span>}
            <span className={rolePrefix === "ai" ? "text-white/45" : "text-white/55"}>{summary}</span>
          </div>
        )}

        {/* Tool action */}
        {tool && (
          <div className="flex items-center gap-1 mt-0.5">
            <span className="text-[9px] text-white/20">🔧</span>
            <span className="text-[9px] text-white/30 font-mono truncate">{tool}</span>
          </div>
        )}
      </div>
    </div>
  )
}

/* ─── Monitor View ─── */
function MonitorView() {
  const { t } = useI18n()
  return (
    <div className="space-y-1">
      <SessionRow
        name="CodeIsland" status={t("demo.monitor")} statusKey="working"
        tool="Edit: NotchView.swift" terminal="cmux" duration="31m"
        summary="帮我优化一下灵动岛布局" rolePrefix="you" active
      />
      <div className="mx-2 h-px bg-gradient-to-r from-transparent via-white/[0.06] to-transparent" />
      <SessionRow
        name="icare" status="已完成" statusKey="done"
        tool="" terminal="Terminal" duration="25m"
        summary="项目初始化完成，所有依赖已安装" rolePrefix="ai" active={false}
      />
    </div>
  )
}

/* ─── Approve View ─── */
function ApproveView() {
  const { t } = useI18n()
  return (
    <div className="space-y-2.5">
      <div className="flex items-center gap-1.5">
        <div className="w-2.5 h-2.5 rounded-full" style={{ background: '#f59e04', boxShadow: '0 0 8px rgba(245,158,4,0.4)' }} />
        <span className="text-[11px] font-semibold" style={{ color: '#ffb333' }}>{t("demo.permissionRequest")}</span>
      </div>
      <div className="flex items-center gap-1.5">
        <span className="text-[10px]" style={{ color: '#ffb333' }}>⚠</span>
        <span className="text-[11px] font-medium text-white/90">Write</span>
        <span className="text-[10px] font-mono text-white/40">src/auth/middleware.ts</span>
      </div>
      {/* Diff preview */}
      <div className="rounded-lg overflow-hidden" style={{ background: '#0a0a12' }}>
        <div className="px-2.5 py-1.5 text-[10px] font-mono" style={{ background: 'rgba(74,222,128,0.08)', color: 'rgba(74,222,128,0.8)' }}>+ if (!token) throw new AuthError('missing');</div>
        <div className="px-2.5 py-1.5 text-[10px] font-mono" style={{ background: 'rgba(74,222,128,0.08)', color: 'rgba(74,222,128,0.8)' }}>+ validateRefreshToken(req.cookies);</div>
        <div className="px-2.5 py-1.5 text-[10px] font-mono" style={{ background: 'rgba(239,68,68,0.08)', color: 'rgba(239,68,68,0.8)' }}>- jwt.verify(token);</div>
      </div>
      <div className="flex gap-2">
        <span className="text-[10px] font-mono font-semibold" style={{ color: '#4ade80' }}>+2</span>
        <span className="text-[10px] font-mono font-semibold" style={{ color: '#ef4444' }}>-1</span>
      </div>
      {/* 3 buttons - matches real app: Chat, Deny, Allow */}
      <div className="flex gap-2">
        <button className="w-9 h-9 rounded-lg flex items-center justify-center" style={{ background: 'rgba(255,255,255,0.08)', border: '1px solid rgba(255,255,255,0.1)' }}>
          <span className="text-[13px]">💬</span>
        </button>
        <button className="flex-1 py-2 rounded-lg text-[11px] font-medium text-white/60" style={{ background: 'rgba(255,255,255,0.08)', border: '1px solid rgba(255,255,255,0.1)' }}>
          {t("demo.deny")} <span className="text-white/25 text-[9px]">⌘N</span>
        </button>
        <button className="flex-1 py-2 rounded-lg text-[11px] font-bold text-black" style={{ background: 'rgba(255,255,255,0.9)' }}>
          {t("demo.allow")} <span className="text-black/35 text-[9px]">⌘Y</span>
        </button>
      </div>
    </div>
  )
}

/* ─── Ask View (AskUserQuestion inline options) ─── */
function AskView() {
  const { t } = useI18n()
  return (
    <div className="space-y-2.5">
      <div className="flex items-center gap-1.5">
        <span className="text-[11px] font-semibold" style={{ color: 'rgba(245,158,4,0.8)' }}>Claude Needs Input</span>
      </div>
      <div className="p-2.5 rounded-lg" style={{ background: 'rgba(255,255,255,0.03)', border: '1px solid rgba(255,255,255,0.05)' }}>
        <p className="text-[10px] text-white/70 leading-relaxed">"{t("demo.claudeQuestion")}"</p>
      </div>
      {/* Inline option buttons - amber capsules like real app */}
      <div className="flex gap-1.5">
        <button className="px-3 py-1.5 rounded text-[10px] font-semibold text-white/80" style={{ background: 'rgba(245,158,4,0.12)', border: '1px solid rgba(245,158,4,0.2)' }}>{t("demo.yes")}</button>
        <button className="px-3 py-1.5 rounded text-[10px] font-semibold text-white/80" style={{ background: 'rgba(245,158,4,0.12)', border: '1px solid rgba(245,158,4,0.2)' }}>{t("demo.no")}</button>
        <span className="flex-1" />
        <button className="w-7 h-7 rounded flex items-center justify-center" style={{ background: 'rgba(245,158,4,0.08)' }}>
          <span className="text-[10px]" style={{ color: 'rgba(245,158,4,0.5)' }}>⌥</span>
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
      <SessionRow
        name="CodeIsland" status={t("demo.monitor")} statusKey="working"
        tool="Edit: NotchView.swift" terminal="cmux" duration="31m" active
      />
      <div className="mt-2 p-3 rounded-lg text-center" style={{ background: 'rgba(74,222,128,0.05)', border: '1px solid rgba(74,222,128,0.12)' }}>
        <div className="font-mono text-lg mb-1" style={{ color: '#4ade80', textShadow: '0 0 12px rgba(74,222,128,0.3)' }}>→→→</div>
        <div className="text-[11px] text-white/80 font-medium">{t("demo.jumpToTerminal")}</div>
        <div className="text-[9px] text-white/35 font-mono mt-1">cmux · tab 2 · CodeIsland</div>
      </div>
    </div>
  )
}

const views: Record<DemoState, React.FC> = { monitor: MonitorView, approve: ApproveView, ask: AskView, jump: JumpView }

/* pulse animation for status dot */
const pulseStyle = `
@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.5; }
}
`

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
      <style>{pulseStyle}</style>
      <div className="absolute inset-0 bg-[radial-gradient(ellipse_80%_60%_at_50%_50%,rgba(52,211,153,0.04)_0%,transparent_70%)]" />

      <div className="max-w-3xl mx-auto relative z-10">
        <div style={{ animation: 'heroEnter 0.8s ease-out both' }} className="text-center mb-12 sm:mb-16">
          <span className="font-mono text-xs text-green uppercase tracking-[0.3em]">{t("demo.sectionTag")}</span>
          <h2 className="font-display text-3xl sm:text-4xl sm:text-5xl font-extrabold text-text-primary mt-4">{t("demo.sectionTitle")}</h2>
        </div>

        <div style={{ animation: 'heroEnter 0.8s ease-out 0.1s both' }} className="mx-auto max-w-2xl">
          <div className="relative">
            {/* Notch shape — matches NotchShape.swift rounded corners */}
            <div
              className="pt-3 pb-5 px-5 sm:px-6"
              style={{
                background: '#000',
                borderRadius: '0 0 24px 24px',
                border: '1px solid rgba(255,255,255,0.06)',
                borderTop: 'none',
                boxShadow: '0 20px 80px rgba(0,0,0,0.6), inset 0 0 0 1px rgba(255,255,255,0.03)',
              }}
            >
              {/* Header bar */}
              <div className="flex items-center justify-between mb-3 pb-2" style={{ borderBottom: '1px solid rgba(255,255,255,0.05)' }}>
                <div className="flex items-center gap-2">
                  <span className="text-[15px]">🐢</span>
                  <span className="font-mono text-[11px] text-white/50">{t("demo.activeSessions")}</span>
                </div>
                <span className="text-[11px] text-white/20">⚙</span>
              </div>

              {/* Dynamic content */}
              <AnimatePresence mode="wait">
                <motion.div
                  key={active}
                  initial={{ opacity: 0, y: 6 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, y: -6 }}
                  transition={{ duration: 0.2, ease: [0.16, 1, 0.3, 1] }}
                  className="min-h-[200px]"
                >
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
          <motion.div
            key={active}
            initial={{ opacity: 0, y: 6 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.2, ease: [0.16, 1, 0.3, 1] }}
            className="text-center mt-6 sm:mt-8 px-4"
          >
            <h3 className="font-display text-xl sm:text-2xl font-bold text-text-primary">{t(desc.titleKey as any)}</h3>
            <p className="text-sm text-text-muted mt-2 max-w-md mx-auto">{t(desc.subKey as any)}</p>
          </motion.div>
        </AnimatePresence>
      </div>
    </section>
  )
}
