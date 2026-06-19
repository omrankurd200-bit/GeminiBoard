#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
#  build.sh — GeminiBoard Build & IPA Export Script
#  Usage:  chmod +x build.sh && ./build.sh
# ═══════════════════════════════════════════════════════════════

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log()  { echo -e "${BLUE}[GeminiBoard]${NC} $1"; }
ok()   { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
fail() { echo -e "${RED}[✗]${NC} $1"; exit 1; }

echo ""
echo -e "${BLUE}╔══════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   GeminiBoard Build Script           ║${NC}"
echo -e "${BLUE}║   AI Translator Keyboard for iPhone  ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════╝${NC}"
echo ""

# ── 1. Check Xcode ──────────────────────────────────────────────
log "Checking Xcode installation…"
if ! command -v xcodebuild &>/dev/null; then
    fail "Xcode not found. Install Xcode from the App Store."
fi
XCODE_VER=$(xcodebuild -version | head -1)
ok "Found: $XCODE_VER"

# ── 2. Install XcodeGen if needed ───────────────────────────────
log "Checking XcodeGen…"
if ! command -v xcodegen &>/dev/null; then
    warn "XcodeGen not found. Installing via Homebrew…"
    if ! command -v brew &>/dev/null; then
        fail "Homebrew not found. Install it from https://brew.sh then run this script again."
    fi
    brew install xcodegen
    ok "XcodeGen installed."
else
    ok "XcodeGen found: $(xcodegen --version 2>/dev/null || echo 'ok')"
fi

# ── 3. Generate Xcode Project ───────────────────────────────────
log "Generating Xcode project from project.yml…"
xcodegen generate --spec project.yml
ok "GeminiBoard.xcodeproj generated."

# ── 4. Build ─────────────────────────────────────────────────────
BUILD_DIR="$SCRIPT_DIR/build"
ARCHIVE_PATH="$BUILD_DIR/GeminiBoard.xcarchive"
IPA_DIR="$BUILD_DIR/IPA"

mkdir -p "$BUILD_DIR"

log "Building GeminiBoard (Release)…"
xcodebuild \
    -project GeminiBoard.xcodeproj \
    -scheme GeminiBoard \
    -configuration Release \
    -destination "generic/platform=iOS" \
    -archivePath "$ARCHIVE_PATH" \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    DEVELOPMENT_TEAM="" \
    archive \
    | xcpretty --color 2>/dev/null || true

if [ ! -d "$ARCHIVE_PATH" ]; then
    # fallback without xcpretty
    xcodebuild \
        -project GeminiBoard.xcodeproj \
        -scheme GeminiBoard \
        -configuration Release \
        -destination "generic/platform=iOS" \
        -archivePath "$ARCHIVE_PATH" \
        CODE_SIGN_IDENTITY="" \
        CODE_SIGNING_REQUIRED=NO \
        CODE_SIGNING_ALLOWED=NO \
        DEVELOPMENT_TEAM="" \
        archive
fi

ok "Archive created at: $ARCHIVE_PATH"

# ── 5. Package IPA ───────────────────────────────────────────────
log "Packaging IPA…"
mkdir -p "$IPA_DIR"

# Extract .app from archive
APP_PATH=$(find "$ARCHIVE_PATH/Products" -name "*.app" | head -1)
if [ -z "$APP_PATH" ]; then
    fail "Could not find .app bundle in archive."
fi

PAYLOAD_DIR="$BUILD_DIR/Payload"
mkdir -p "$PAYLOAD_DIR"
cp -R "$APP_PATH" "$PAYLOAD_DIR/"

IPA_PATH="$IPA_DIR/GeminiBoard.ipa"
cd "$BUILD_DIR"
zip -qr "$IPA_PATH" Payload/
rm -rf Payload/

ok "IPA packaged: $IPA_PATH"

# ── 6. Pseudo-sign with ldid (optional) ─────────────────────────
if command -v ldid &>/dev/null; then
    log "Pseudo-signing with ldid for TrollStore…"
    ldid -S "$IPA_PATH"
    ok "Pseudo-signed with ldid."
else
    warn "ldid not found — skipping pseudo-sign."
    warn "TrollStore can install unsigned IPAs directly, so this is usually fine."
    warn "To install ldid: brew install ldid"
fi

# ── 7. Done ──────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   ✅ Build Complete!                     ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
echo ""
echo -e "  📦 IPA Location:  ${YELLOW}$IPA_PATH${NC}"
echo ""
echo -e "  📲 Install steps:"
echo -e "     1. Transfer GeminiBoard.ipa to your iPhone"
echo -e "        (AirDrop, Files app, or use SideStore/AltStore)"
echo -e "     2. Open TrollStore on your iPhone"
echo -e "     3. Tap the IPA file → Install"
echo -e "     4. Open GeminiBoard app → Enter your Gemini API key"
echo -e "     5. Go to Settings → General → Keyboard → Add New Keyboard"
echo -e "     6. Add GeminiBoard → Enable 'Allow Full Access'"
echo -e "     7. Start typing and translate! ✨"
echo ""
