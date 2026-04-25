# lean-intellij/apply.ps1
# Applies lean settings to an existing IntelliJ IDEA Ultimate installation on Windows.
# Run in PowerShell: .\apply.ps1

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# ─── Locate JetBrains config base ────────────────────────────────────────────
$JbBase = Join-Path $env:APPDATA "JetBrains"
if (-not (Test-Path $JbBase)) {
    Write-Error "No JetBrains config found at $JbBase. Launch IDEA at least once, then re-run."
    exit 1
}

# ─── Pick IDEA config directory ──────────────────────────────────────────────
$IdeaDirs = Get-ChildItem -Path $JbBase -Directory -Filter "IntelliJIdea*" |
    Sort-Object Name

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
    $choice = Read-Host "Apply to which? (press Enter for latest)"
    if ([string]::IsNullOrWhiteSpace($choice)) {
        $IdeaConfig = $IdeaDirs[-1].FullName
    } else {
        $IdeaConfig = $IdeaDirs[[int]$choice - 1].FullName
    }
}

$Version = Split-Path -Leaf $IdeaConfig
Write-Host "Applying lean settings to: $Version"
Write-Host ""

# ─── Backup ──────────────────────────────────────────────────────────────────
$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$Backup = Join-Path $IdeaConfig ".lean-backup-$Timestamp"
New-Item -ItemType Directory -Path (Join-Path $Backup "options") -Force | Out-Null

foreach ($f in @("idea.vmoptions", "disabled_plugins.txt")) {
    $src = Join-Path $IdeaConfig $f
    if (Test-Path $src) { Copy-Item $src (Join-Path $Backup $f) }
}
$regSrc = Join-Path $IdeaConfig "options\ide.general.xml"
if (Test-Path $regSrc) { Copy-Item $regSrc (Join-Path $Backup "options\ide.general.xml") }
Write-Host "✓ Backup saved → $Backup"

# ─── JVM memory flags ────────────────────────────────────────────────────────
Copy-Item (Join-Path $ScriptDir "config\idea.vmoptions") (Join-Path $IdeaConfig "idea.vmoptions") -Force
Write-Host "✓ JVM flags: Xmx=1024m · CodeCache=128m · cycle.buffer=disabled"

# ─── Disable unused plugins ──────────────────────────────────────────────────
Copy-Item (Join-Path $ScriptDir "config\disabled_plugins.txt") (Join-Path $IdeaConfig "disabled_plugins.txt") -Force
$PluginCount = (Get-Content (Join-Path $ScriptDir "config\disabled_plugins.txt") | Where-Object { $_ -match '\S' }).Count
Write-Host "✓ $PluginCount plugins disabled"

# ─── Merge registry settings ─────────────────────────────────────────────────
$OptionsDir = Join-Path $IdeaConfig "options"
New-Item -ItemType Directory -Path $OptionsDir -Force | Out-Null
python (Join-Path $ScriptDir "scripts\merge-registry.py") `
    (Join-Path $OptionsDir "ide.general.xml") `
    (Join-Path $ScriptDir "config\options\ide.general.xml")

# ─── Done ────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
Write-Host "  Done. Restart IntelliJ IDEA to apply all changes."
Write-Host ""
Write-Host "  To restore original settings:"
Write-Host "    Copy-Item `"$Backup\*`" `"$IdeaConfig\`" -Recurse -Force"
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
