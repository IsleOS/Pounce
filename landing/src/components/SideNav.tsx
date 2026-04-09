import { useState, useEffect } from "react"
import { motion, AnimatePresence } from "motion/react"
import { useI18n } from "../lib/i18n"

const sections = [
  { id: "demo", labelKey: "nav.demo" as const, icon: "▶" },
  { id: "features", labelKey: "nav.features" as const, icon: "◆" },
  { id: "codelight", labelKey: "sidenav.codelight" as const, icon: "📱" },
  { id: "how-it-works", labelKey: "nav.howItWorks" as const, icon: "⚡" },
  { id: "open-source", labelKey: "sidenav.opensource" as const, icon: "♡" },
]

export default function SideNav() {
  const { t } = useI18n()
  const [activeId, setActiveId] = useState("")
  const [visible, setVisible] = useState(false)
  const [hovered, setHovered] = useState<string | null>(null)

  useEffect(() => {
    const handleScroll = () => {
      // Show after scrolling past hero
      setVisible(window.scrollY > 400)

      // Determine active section
      let current = ""
      for (const section of sections) {
        const el = document.getElementById(section.id)
        if (el) {
          const rect = el.getBoundingClientRect()
          if (rect.top <= window.innerHeight / 3) {
            current = section.id
          }
        }
      }
      setActiveId(current)
    }

    window.addEventListener("scroll", handleScroll, { passive: true })
    handleScroll()
    return () => window.removeEventListener("scroll", handleScroll)
  }, [])

  const scrollTo = (id: string) => {
    const el = document.getElementById(id)
    if (el) {
      el.scrollIntoView({ behavior: "smooth", block: "start" })
    }
  }

  return (
    <AnimatePresence>
      {visible && (
        <motion.nav
          initial={{ opacity: 0, x: 20 }}
          animate={{ opacity: 1, x: 0 }}
          exit={{ opacity: 0, x: 20 }}
          transition={{ duration: 0.3 }}
          className="fixed right-4 top-1/2 -translate-y-1/2 z-50 hidden lg:flex flex-col items-end gap-1"
        >
          {sections.map((section) => {
            const isActive = activeId === section.id
            const isHovered = hovered === section.id

            return (
              <button
                key={section.id}
                onClick={() => scrollTo(section.id)}
                onMouseEnter={() => setHovered(section.id)}
                onMouseLeave={() => setHovered(null)}
                className="group flex items-center gap-2 cursor-pointer py-1.5 pr-1"
              >
                {/* Label — slides in on hover/active */}
                <AnimatePresence>
                  {(isHovered || isActive) && (
                    <motion.span
                      initial={{ opacity: 0, x: 8, width: 0 }}
                      animate={{ opacity: 1, x: 0, width: "auto" }}
                      exit={{ opacity: 0, x: 8, width: 0 }}
                      transition={{ duration: 0.2 }}
                      className="overflow-hidden whitespace-nowrap font-mono text-[11px] tracking-wide"
                      style={{ color: isActive ? '#34d399' : 'rgba(255,255,255,0.5)' }}
                    >
                      {t(section.labelKey as any)}
                    </motion.span>
                  )}
                </AnimatePresence>

                {/* Dot / line indicator */}
                <div className="relative flex items-center justify-center w-3">
                  <motion.div
                    animate={{
                      height: isActive ? 16 : 6,
                      width: isActive ? 3 : 3,
                      backgroundColor: isActive ? '#34d399' : isHovered ? 'rgba(255,255,255,0.4)' : 'rgba(255,255,255,0.15)',
                      boxShadow: isActive ? '0 0 8px rgba(52,211,153,0.4)' : 'none',
                    }}
                    transition={{ duration: 0.2 }}
                    className="rounded-full"
                  />
                </div>
              </button>
            )
          })}
        </motion.nav>
      )}
    </AnimatePresence>
  )
}
