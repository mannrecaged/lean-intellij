# lean-intellij/apply.ps1
# Applies lean settings to an existing IntelliJ IDEA Ultimate installation on Windows.
# Run in PowerShell: .\apply.ps1

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# ─── Helper: merge registry XML without Python ───────────────────────────────
# Adds any <entry> keys from $PatchPath that are not already in $TargetPath.
# Preserves all existing user entries. Uses only PowerShell built-in XML.
function Merge-Registry {
    param([string]$TargetPath, [string]$PatchPath)

    if (-not (Test-Path $TargetPath)) {
        Copy-Item $PatchPath $TargetPath
        Write-Host "✓ Registry settings written"
        return
    }

    [xml]$target = Get-Content $TargetPath -Raw
    [xml]$patch  = Get-Content $PatchPath  -Raw

    $tgtComp = $target.application.component |
        Where-Object { $_.name -eq 'Registry' }
    if (-not $tgtComp) {
        $tgtComp = $target.CreateElement('component')
        $tgtComp.SetAttribute('name', 'Registry')
        $target.application.AppendChild($tgtComp) | Out-Null
    }

    $added = 0
    foreach ($entry in $patch.application.component.entry) {
        $exists = $tgtComp.SelectNodes("entry[@key='$($entry.key)']").Count -gt 0
        if (-not $exists) {
            $node = $target.ImportNode($entry, $true)
            $tgtComp.AppendChild($node) | Out-Null
            $added++
        }
    }

    $target.Save($TargetPath)
    Write-Host "✓ Registry settings merged ($added new entries added)"
}

# ─── Helper: merge GeneralSettings XML options ───────────────────────────────
function Merge-GeneralSettings {
    param([string]$TargetPath, [string]$PatchPath)

    if (-not (Test-Path $TargetPath)) {
        Copy-Item $PatchPath $TargetPath
        Write-Host "✓ GeneralSettings written"
        return
    }

    [xml]$target = Get-Content $TargetPath -Raw
    [xml]$patch  = Get-Content $PatchPath  -Raw

    $tgtComp = $target.application.component |
        Where-Object { $_.name -eq 'GeneralSettings' }
    if (-not $tgtComp) {
        $tgtComp = $target.CreateElement('component')
        $tgtComp.SetAttribute('name', 'GeneralSettings')
        $target.application.AppendChild($tgtComp) | Out-Null
    }

    $patchComp = $patch.application.component |
        Where-Object { $_.name -eq 'GeneralSettings' }
    if (-not $patchComp) { return }

    $added = 0
    foreach ($option in $patchComp.option) {
        $exists = $tgtComp.SelectNodes("option[@name='$($option.name)']").Count -gt 0
        if (-not $exists) {
            $node = $target.ImportNode($option, $true)
            $tgtComp.AppendChild($node) | Out-Null
            $added++
        }
    }

    $target.Save($TargetPath)
    Write-Host "✓ GeneralSettings merged ($added new entries added)"
}

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
Write-Host "✓ JVM flags: Xmx=1024m · CodeCache=240m · GC-tuned · cycle.buffer=disabled"

# ─── Disable unused plugins ──────────────────────────────────────────────────
Copy-Item (Join-Path $ScriptDir "config\disabled_plugins.txt") (Join-Path $IdeaConfig "disabled_plugins.txt") -Force
$PluginCount = (Get-Content (Join-Path $ScriptDir "config\disabled_plugins.txt") | Where-Object { $_ -match '\S' }).Count
Write-Host "✓ $PluginCount plugins disabled"

# ─── Merge ide.general.xml settings ─────────────────────────────────────────
$OptionsDir = Join-Path $IdeaConfig "options"
New-Item -ItemType Directory -Path $OptionsDir -Force | Out-Null
$IdeGeneralTarget = Join-Path $OptionsDir "ide.general.xml"
$IdeGeneralPatch  = Join-Path $ScriptDir "config\options\ide.general.xml"
Merge-GeneralSettings -TargetPath $IdeGeneralTarget -PatchPath $IdeGeneralPatch
Merge-Registry        -TargetPath $IdeGeneralTarget -PatchPath $IdeGeneralPatch

# ─── Done ────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
Write-Host "  Done. Restart IntelliJ IDEA to apply all changes."
Write-Host ""
Write-Host "  To restore original settings:"
Write-Host "    Copy-Item `"$Backup\*`" `"$IdeaConfig\`" -Recurse -Force"
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
