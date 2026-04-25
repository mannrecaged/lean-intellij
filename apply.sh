#!/usr/bin/env bash
# lean-intellij/apply.sh
# Applies lean settings to an existing IntelliJ IDEA Ultimate installation.
# Tested on IDEA 2025.x / 2026.x on macOS and Linux.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─── Locate JetBrains config base ────────────────────────────────────────────
if [[ "$OSTYPE" == "darwin"* ]]; then
    JB_BASE="$HOME/Library/Application Support/JetBrains"
elif [[ "$OSTYPE" == "linux"* ]]; then
    JB_BASE="${XDG_CONFIG_HOME:-$HOME/.config}/JetBrains"
else
    echo "❌  Windows is not supported by this script."
    echo "   Run apply.ps1 in PowerShell instead."
    exit 1
fi

# ─── Pick IDEA config directory ──────────────────────────────────────────────
mapfile -t IDEA_DIRS < <(find "$JB_BASE" -maxdepth 1 -name "IntelliJIdea*" -type d 2>/dev/null | sort -V)

if [[ ${#IDEA_DIRS[@]} -eq 0 ]]; then
    echo "❌  No IntelliJ IDEA config directory found under:"
    echo "   $JB_BASE"
    echo ""
    echo "   Launch IDEA at least once so the config directory is created,"
    echo "   then re-run this script."
    exit 1
elif [[ ${#IDEA_DIRS[@]} -eq 1 ]]; then
    IDEA_CONFIG="${IDEA_DIRS[0]}"
else
    echo "Multiple IntelliJ IDEA versions found:"
    for i in "${!IDEA_DIRS[@]}"; do
        printf "  [%d] %s\n" "$((i+1))" "$(basename "${IDEA_DIRS[$i]}")"
    done
    echo ""
    read -rp "Apply to which? (press Enter for latest) " choice
    if [[ -z "$choice" ]]; then
        IDEA_CONFIG="${IDEA_DIRS[-1]}"
    else
        IDEA_CONFIG="${IDEA_DIRS[$((choice-1))]}"
    fi
fi

VERSION="$(basename "$IDEA_CONFIG")"
echo "Applying lean settings to: $VERSION"
echo ""

# ─── Backup existing config ──────────────────────────────────────────────────
BACKUP="$IDEA_CONFIG/.lean-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP/options"
for f in idea.vmoptions disabled_plugins.txt; do
    [[ -f "$IDEA_CONFIG/$f" ]] && cp "$IDEA_CONFIG/$f" "$BACKUP/$f"
done
[[ -f "$IDEA_CONFIG/options/ide.general.xml" ]] \
    && cp "$IDEA_CONFIG/options/ide.general.xml" "$BACKUP/options/ide.general.xml"
echo "✓ Backup saved → $BACKUP"

# ─── JVM memory flags ────────────────────────────────────────────────────────
cp "$SCRIPT_DIR/config/idea.vmoptions" "$IDEA_CONFIG/idea.vmoptions"
echo "✓ JVM flags: Xmx=1024m · CodeCache=128m · cycle.buffer=disabled"

# ─── Disable unused plugins ──────────────────────────────────────────────────
cp "$SCRIPT_DIR/config/disabled_plugins.txt" "$IDEA_CONFIG/disabled_plugins.txt"
PLUGIN_COUNT=$(grep -c '[^[:space:]]' "$SCRIPT_DIR/config/disabled_plugins.txt")
echo "✓ $PLUGIN_COUNT plugins disabled (Spring, Docker, Angular, Maven, etc.)"

# ─── Merge registry settings ─────────────────────────────────────────────────
mkdir -p "$IDEA_CONFIG/options"
python3 "$SCRIPT_DIR/scripts/merge-registry.py" \
    "$IDEA_CONFIG/options/ide.general.xml" \
    "$SCRIPT_DIR/config/options/ide.general.xml"

# ─── Done ────────────────────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Done. Restart IntelliJ IDEA to apply all changes."
echo ""
echo "  To restore original settings:"
echo "    cp -r \"$BACKUP/\"* \"$IDEA_CONFIG/\""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
