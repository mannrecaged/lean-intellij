# lean-intellij/revert.ps1
# Restores the most recent backup created by apply.ps1.
# Run in PowerShell: .\revert.ps1

$ErrorActionPreference = "Stop"

# ─── Locate JetBrains config base ────────────────────────────────────────────
$JbBase = Join-Path $env:APPDATA "JetBrains"
if (-not (Test-Path $JbBase)) {
    Write-Error "No JetBrains config found at $JbBase. Has IDEA been launched at least once?"
    exit 1
}

# ─── Pick IDEA config directory ──────────────────────────────────────────────
$IdeaDirs = Get-ChildItem -Path $JbBase -Directory -Filter "IntelliJIdea*" | Sort-Object Name

if ($IdeaDirs.Count -eq 0) {
    Write-Error "No IntelliJ IDEA config directory found under $JbBase."
    exit 1
} elseif ($IdeaDirs.Count -eq 1) {
    $IdeaConfig = $IdeaDirs[0].FullName
} else {
    Write-Host "Multiple IntelliJ IDEA versions found:"
    for ($i = 0; $i -lt $IdeaDirs.Count; $i++) {
        Write-Host "  [$($i+1)] $($IdeaDirs[$i].Name)"
    }
    $choice = Read-Host "Revert which? (press Enter for latest)"
    if ([string]::IsNullOrWhiteSpace($choice)) {
        $IdeaConfig = $IdeaDirs[-1].FullName
    } else {
        $IdeaConfig = $IdeaDirs[[int]$choice - 1].FullName
    }
}

$Version = Split-Path -Leaf $IdeaConfig
Write-Host "Reverting lean settings for: $Version"
Write-Host ""

# ─── Find most recent backup ─────────────────────────────────────────────────
$Backup = Get-ChildItem -Path $IdeaConfig -Directory -Filter ".lean-backup-*" -ErrorAction SilentlyContinue |
    Sort-Object Name | Select-Object -Last 1

if (-not $Backup) {
    Write-Host "⚠️  No backup found — removing the three files apply.ps1 created:"
} else {
    Write-Host "Restoring from backup: $($Backup.Name)"
}
Write-Host ""

# ─── Restore or remove ───────────────────────────────────────────────────────
function Restore-File {
    param([string]$RelPath)
    $dst = Join-Path $IdeaConfig $RelPath
    if ($Backup) {
        $src = Join-Path $Backup.FullName $RelPath
        if (Test-Path $src) {
            $dstDir = Split-Path $dst -Parent
            if (-not (Test-Path $dstDir)) { New-Item -ItemType Directory -Path $dstDir -Force | Out-Null }
            Copy-Item $src $dst -Force
            Write-Host "  ✓ Restored $RelPath"
            return
        }
    }
    # No backup copy means the file didn't exist before apply — remove it
    if (Test-Path $dst) { Remove-Item $dst -Force }
    Write-Host "  ✓ Removed $RelPath"
}

Restore-File "idea.vmoptions"
Restore-File "disabled_plugins.txt"
Restore-File "options\ide.general.xml"

# ─── Done ────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
Write-Host "  Done. Restart IntelliJ IDEA to apply original settings."
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
