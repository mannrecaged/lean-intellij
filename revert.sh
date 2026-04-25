#!/usr/bin/env bash
# lean-intellij/revert.sh
# Restores the most recent backup created by apply.sh.
# Run: ./revert.sh

set -euo pipefail

# ─── Locate JetBrains config base ────────────────────────────────────────────
if [[ "$OSTYPE" == "darwin"* ]]; then
    JB_BASE="$HOME/Library/Application Support/JetBrains"
elif [[ "$OSTYPE" == "linux"* ]]; then
    JB_BASE="${XDG_CONFIG_HOME:-$HOME/.config}/JetBrains"
else
    echo "❌  Windows is not supported by this script."
    echo "   Run revert.ps1 in PowerShell instead."
    exit 1
fi

# ─── Pick IDEA config directory ──────────────────────────────────────────────
IDEA_DIRS=()
while IFS= read -r dir; do
    IDEA_DIRS+=("$dir")
done < <(find "$JB_BASE" -maxdepth 1 -name "IntelliJIdea*" -type d 2>/dev/null | sort -V)

if [[ ${#IDEA_DIRS[@]} -eq 0 ]]; then
    echo "❌  No IntelliJ IDEA config directory found under $JB_BASE."
    exit 1
elif [[ ${#IDEA_DIRS[@]} -eq 1 ]]; then
    IDEA_CONFIG="${IDEA_DIRS[0]}"
else
    echo "Multiple IntelliJ IDEA versions found:"
    for i in "${!IDEA_DIRS[@]}"; do
        printf "  [%d] %s\n" "$((i+1))" "$(basename "${IDEA_DIRS[$i]}")"
    done
    echo ""
    read -rp "Revert which? (press Enter for latest) " choice
    if [[ -z "$choice" ]]; then
        IDEA_CONFIG="${IDEA_DIRS[${#IDEA_DIRS[@]}-1]}"
    else
        IDEA_CONFIG="${IDEA_DIRS[$((choice-1))]}"
    fi
fi

VERSION="$(basename "$IDEA_CONFIG")"
echo "Reverting lean settings for: $VERSION"
echo ""

# ─── Find most recent backup ─────────────────────────────────────────────────
BACKUP=""
while IFS= read -r dir; do
    BACKUP="$dir"
done < <(find "$IDEA_CONFIG" -maxdepth 1 -name ".lean-backup-*" -type d 2>/dev/null | sort -V)

# ─── Restore or remove ───────────────────────────────────────────────────────
restore_file() {
    local name="$1"
    local src="$BACKUP/$name"
    local dst="$IDEA_CONFIG/$name"
    if [[ -n "$BACKUP" && -f "$src" ]]; then
        cp "$src" "$dst"
        echo "  ✓ Restored $name"
    else
        rm -f "$dst"
        echo "  ✓ Removed $name"
    fi
}

if [[ -z "$BACKUP" ]]; then
    echo "⚠️  No backup found — removing the three files apply.sh created:"
else
    echo "Restoring from backup: $(basename "$BACKUP")"
fi
echo ""

restore_file "idea.vmoptions"
restore_file "disabled_plugins.txt"
restore_file "options/ide.general.xml"

# ─── Done ────────────────────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Done. Restart IntelliJ IDEA to apply original settings."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
