import { useState, useEffect } from "react"
import { motion } from "motion/react"
import { useI18n } from "../lib/i18n"

const sections = [
  { id: "demo", labelKey: "nav.demo" as const },
  { id: "features", labelKey: "nav.features" as const },
  { id: "codelight", labelKey: "sidenav.codelight" as const },
  { id: "how-it-works", labelKey: "nav.howItWorks" as const },
  { id: "open-source", labelKey: "sidenav.opensource" as const },
]

export default function SideNav() {
  const { t } = useI18n()
  const [activeId, setActiveId] = useState("")
  const [hovered, setHovered] = useState<string | null>(null)

  useEffect(() => {
    const handleScroll = () => {
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
    <nav className="fixed right-6 top-1/2 -translate-y-1/2 z-50 hidden lg:flex flex-col items-end gap-0.5">
      {sections.map((section) => {
        const isActive = activeId === section.id
        const isHovered = hovered === section.id
        return (
          <button
            key={section.id}
            onClick={() => scrollTo(section.id)}
            onMouseEnter={() => setHovered(section.id)}
            onMouseLeave={() => setHovered(null)}
            className="group flex items-center gap-3 cursor-pointer py-2 px-2 rounded-lg transition-colors duration-200"
            style={{ background: isHovered ? 'rgba(255,255,255,0.04)' : 'transparent' }}
          >
            {/* Label — always visible for active, hover for others */}
            <span
              className="font-mono text-xs tracking-wide transition-all duration-200 whitespace-nowrap"
              style={{
                color: isActive ? '#34d399' : isHovered ? 'rgba(255,255,255,0.7)' : 'rgba(255,255,255,0.25)',
                fontWeight: isActive ? 600 : 400,
              }}
            >
              {t(section.labelKey as any)}
            </span>

            {/* Bar indicator */}
            <motion.div
              animate={{
                height: isActive ? 24 : isHovered ? 12 : 8,
                width: 3,
                backgroundColor: isActive ? '#34d399' : isHovered ? 'rgba(255,255,255,0.4)' : 'rgba(255,255,255,0.12)',
                boxShadow: isActive ? '0 0 10px rgba(52,211,153,0.5)' : 'none',
              }}
              transition={{ duration: 0.2 }}
              className="rounded-full shrink-0"
            />
          </button>
        )
      })}
    </nav>
  )
}
