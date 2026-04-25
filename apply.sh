#!/usr/bin/env bash
# lean-intellij/apply.sh
# Applies lean settings to an existing IntelliJ IDEA Ultimate installation.
# Tested on IDEA 2025.x / 2026.x on macOS and Linux.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─── Helper: merge registry XML without Python ───────────────────────────────
# Adds any <entry> keys from $2 (patch) to $1 (target) that are not already
# present. Preserves all existing user entries. Uses only POSIX awk + grep.
merge_registry() {
    local target="$1"
    local patch="$2"

    if [[ ! -f "$target" ]]; then
        cp "$patch" "$target"
        echo "✓ Registry settings written"
        return
    fi

    local added=0
    local pat='key="([^"]+)"'

    # If the target has no Registry component yet, extract it from patch and
    # insert the whole block before </application>.
    if ! grep -q 'name="Registry"' "$target"; then
        local tmpblk
        tmpblk=$(mktemp)
        awk '/<component[^>]*name="Registry"/{p=1} p{print} p && /<\/component>/{p=0}' \
            "$patch" > "$tmpblk"
        # FNR==NR trick: read tmpblk into `reg`, then emit it before </application>
        awk 'FNR==NR{reg=reg $0 "\n";next} /<\/application>/{printf "%s",reg} {print}' \
            "$tmpblk" "$target" > "${target}.tmp" \
            && mv "${target}.tmp" "$target"
        rm -f "$tmpblk"
    fi

    # Add each missing entry key into the Registry component only.
    while IFS= read -r entry_line; do
        if [[ "$entry_line" =~ $pat ]]; then
            local key="${BASH_REMATCH[1]}"
            if grep -qF "key=\"$key\"" "$target"; then
                continue  # already present — leave it untouched
            fi
            # Use awk state tracking so we only insert inside the Registry component.
            awk -v entry="    $entry_line" '
                /<component[^>]*name="Registry"/ { in_reg=1 }
                in_reg && /<\/component>/        { print entry; in_reg=0 }
                { print }
            ' "$target" > "${target}.tmp" && mv "${target}.tmp" "$target"
            added=$((added + 1))
        fi
    done < <(grep -oE '<entry [^/]+/>' "$patch")

    echo "✓ Registry settings merged ($added new entries added)"
}

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
IDEA_DIRS=()
while IFS= read -r dir; do
    IDEA_DIRS+=("$dir")
done < <(find "$JB_BASE" -maxdepth 1 -name "IntelliJIdea*" -type d 2>/dev/null | sort -V)

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
        IDEA_CONFIG="${IDEA_DIRS[${#IDEA_DIRS[@]}-1]}"
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
echo "✓ JVM flags: Xmx=1024m · CodeCache=240m · GC-tuned · cycle.buffer=disabled"

# ─── Disable unused plugins ──────────────────────────────────────────────────
cp "$SCRIPT_DIR/config/disabled_plugins.txt" "$IDEA_CONFIG/disabled_plugins.txt"
PLUGIN_COUNT=$(grep -c '[^[:space:]]' "$SCRIPT_DIR/config/disabled_plugins.txt")
echo "✓ $PLUGIN_COUNT plugins disabled (Spring, Docker, Angular, Maven, etc.)"

# ─── Merge registry settings ─────────────────────────────────────────────────
mkdir -p "$IDEA_CONFIG/options"
merge_registry \
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
