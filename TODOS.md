# TODOS

Project-level deferred work. Each entry: priority, what, why, where to start.

---

## P2: Wire `ClaudeIslandTests/` into the Xcode project as a real test target

**What:** Add a unit test target to `ClaudeIsland.xcodeproj` so the `ClaudeIslandTests/*Tests.swift` files actually compile and run. Currently the directory exists with ~12 test files (AutoWidthTests, NotchThemeTests, RedemptionTests, etc.) but `pbxproj` has zero references to XCTest or any test target — the files are orphans.

**Why:** Right now any contract regression silently goes unnoticed. `RedemptionTests.swift` was added in the redeem-code migration to lock down the 9 server error keys + ISO8601 dual-fallback + `RedemptionRecord.isActive`/`remainingDays` boundaries. Those tests can't catch a future change to `Redemption.swift` because they never run. Same for every other historical test file in the directory.

**Pros:**
- Existing 12 test files become live regression net (~free coverage win)
- New tests can be written knowing they'll actually run
- CI hook becomes possible (`xcodebuild test` would pass meaningfully)

**Cons:**
- 30-min edit to `project.pbxproj` (manual — Xcode UI handles it cleanly)
- May surface dormant test failures from tests that have rotted

**Context:** Discovered during redeem-code CEO review (2026-05-02). The migration's `RedemptionTests.swift` covers 11 cases including all server error key mappings — high value if wired up. To start: open `ClaudeIsland.xcodeproj` in Xcode → File → New → Target → macOS Unit Testing Bundle → name "ClaudeIslandTests" → drag-drop the existing `ClaudeIslandTests/` files into the new target's membership. Then `xcodebuild test` should run them.

**Effort:** S (human: 30 min / CC+gstack: 5 min)

**Priority:** P2 (not blocking ship, but every day without it = silent regression risk on paid path)

**Depends on / blocked by:** Nothing.
