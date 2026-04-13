#!/bin/bash
# CodeIsland Release Script
# Usage: ./scripts/release.sh v2.0.2
#
# Ships unsigned builds. Users must right-click → Open or run
# `xattr -dr com.apple.quarantine` on first launch. Gatekeeper + the
# Homebrew cask's postflight handle this transparently.
#
# Signing / notarization were removed after Apple's statusCode 7000
# server-side issue kept recurring and blocking releases.

set -e

VERSION="${1:?Usage: $0 <version>}"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$HOME/Library/Developer/Xcode/DerivedData/ClaudeIsland-guzapwxyhrxjvgdvqogvkpjqjwht/Build/Products/Release"
APP_PATH="$BUILD_DIR/Code Island.app"
ZIP_PATH="$PROJECT_DIR/CodeIsland-${VERSION}.zip"

echo "=== CodeIsland Release $VERSION (unsigned) ==="

# 1. Update version in Xcode project
CLEAN_VERSION="${VERSION#v}"  # v2.0.2 -> 2.0.2
echo ">>> Setting version to $CLEAN_VERSION..."
sed -i '' "s/MARKETING_VERSION = [0-9.]*/MARKETING_VERSION = $CLEAN_VERSION/g" \
  "$PROJECT_DIR/ClaudeIsland.xcodeproj/project.pbxproj"

# 2. Build (unsigned, universal)
#
# ARCHS + ONLY_ACTIVE_ARCH are critical: xcodebuild defaults to building
# only the current machine's architecture, which would ship an arm64-only
# binary to Intel Mac users — who then see "Code Island can't be opened"
# with no recoverable error (xattr won't help, it's a pure architecture
# mismatch). Force a universal build so the same zip works on both archs.
echo ">>> Building Release (unsigned, universal arm64+x86_64)..."
cd "$PROJECT_DIR"
xcodebuild -scheme ClaudeIsland -configuration Release build \
  ARCHS="arm64 x86_64" ONLY_ACTIVE_ARCH=NO \
  CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY="" 2>&1 | tail -1

# 3. Bundle built-in plugins into the .app.
#    The repo ships prebuilt .bundle files under ClaudeIsland/Resources/Plugins/
#    (e.g. the stats plugin, source in ../mio-plugin-stats). NativePluginManager
#    scans Bundle.main.resourceURL/Plugins in addition to the user plugins dir,
#    so anything copied here is auto-loaded on launch.
BUNDLED_PLUGINS_SRC="$PROJECT_DIR/ClaudeIsland/Resources/Plugins"
BUNDLED_PLUGINS_DST="$APP_PATH/Contents/Resources/Plugins"
if [ -d "$BUNDLED_PLUGINS_SRC" ]; then
  echo ">>> Copying bundled plugins..."
  rm -rf "$BUNDLED_PLUGINS_DST"
  mkdir -p "$BUNDLED_PLUGINS_DST"
  # Only copy .bundle directories (ignore any stray files)
  for b in "$BUNDLED_PLUGINS_SRC"/*.bundle; do
    [ -d "$b" ] || continue
    cp -R "$b" "$BUNDLED_PLUGINS_DST/"
    echo "    $(basename "$b")"
  done
fi

# 4. Ad-hoc sign.
#
# launchd on macOS Sonoma+ refuses to spawn completely unsigned binaries
# ("Launchd job spawn failed", POSIX error 163), even if the user has
# cleared com.apple.quarantine. An ad-hoc signature gives the binary a
# minimal cryptographic identity with no team / no Developer ID — enough
# to satisfy launchd, still no Gatekeeper trust, still doesn't need Apple
# notarization. This is what Chromium, Homebrew, and most unsigned-but-
# runnable macOS distributions do.
#
# --deep makes sure nested bundles (stats.bundle, etc.) also get the
# ad-hoc treatment. --force overrides any residual xcodebuild signature.
echo ">>> Ad-hoc signing..."
codesign --force --deep --sign - "$APP_PATH"

# 4. Package (ALWAYS ditto, never zip — regular zip adds ._* AppleDouble files)
echo ">>> Packaging..."
rm -f "$ZIP_PATH"
ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"
echo "    $(du -h "$ZIP_PATH" | cut -f1)"

# 5. Commit version bump and tag
echo ">>> Tagging $VERSION..."
git add "$PROJECT_DIR/ClaudeIsland.xcodeproj/project.pbxproj"
git commit -m "$VERSION: Release" --allow-empty || true
git tag "$VERSION"

echo ""
echo "=== Done! ==="
echo "Unsigned package: $ZIP_PATH"
echo ""
echo "Next steps:"
echo "  git push origin main --tags"
echo "  gh release create $VERSION \"$ZIP_PATH\" --title \"$VERSION\""
