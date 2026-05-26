<#
.SYNOPSIS
    cursor-powered-up — Unified Installer (Windows)

.DESCRIPTION
    One script that does everything: GSD for Cursor + global power-up stack.
    Mirrors scripts/install.sh for Windows PowerShell.

.PARAMETER Force
    Overwrite existing installation without prompting.

.PARAMETER GsdOnly
    Only copy GSD files (skip npm/MCP/skills phases).

.PARAMETER PowerupOnly
    Only run power-up phases (skip GSD file copy).

.EXAMPLE
    .\scripts\install.ps1
    .\scripts\install.ps1 -Force
    .\scripts\install.ps1 -GsdOnly
#>

param(
    [switch]$Force,
    [switch]$GsdOnly,
    [switch]$PowerupOnly
)

$ErrorActionPreference = "Stop"

# ── Paths ─────────────────────────────────────────────────────────────────────
$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$SourcePath = (Resolve-Path (Join-Path $ScriptDir "..\src")).Path
$HomeDir    = if ($env:USERPROFILE) { $env:USERPROFILE } elseif ($env:HOME) { $env:HOME } else { throw "Cannot determine home directory" }
$CursorDir  = Join-Path $HomeDir ".cursor"
$NpmPrefix  = Join-Path $HomeDir ".npm-global"

# ── Helpers ───────────────────────────────────────────────────────────────────
function Phase($n, $title) { Write-Host "`n▶ Phase ${n}: $title" -ForegroundColor Cyan }
function Ok($msg)   { Write-Host "  ✓ $msg" -ForegroundColor Green }
function Warn($msg) { Write-Host "  ⚠ $msg" -ForegroundColor Yellow }
function Info($msg) { Write-Host "    $msg" -ForegroundColor Gray }

# ── Header ────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║   cursor-powered-up  —  Full Installer   ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "  Source:  $SourcePath" -ForegroundColor Gray
Write-Host "  Target:  $CursorDir"  -ForegroundColor Gray
Write-Host ""

# =============================================================================
# PHASE 1 — Prerequisites
# =============================================================================
Phase 1 "Check prerequisites"

$missingPrereqs = $false

function CheckCmd($cmd, $installHint) {
    $found = Get-Command $cmd -ErrorAction SilentlyContinue
    if ($found) {
        Ok "$cmd found ($($found.Source))"
    } else {
        Write-Host "  ✗ $cmd not found — $installHint" -ForegroundColor Red
        $script:missingPrereqs = $true
    }
}

# Node version check
$nodeCmd = Get-Command node -ErrorAction SilentlyContinue
if ($nodeCmd) {
    $nodeVer = [int](node -e "process.stdout.write(process.version.replace('v','').split('.')[0])")
    if ($nodeVer -ge 18) {
        Ok "node $(node --version) (≥18)"
    } else {
        Write-Host "  ✗ node v$nodeVer found but ≥18 required — download from https://nodejs.org" -ForegroundColor Red
        $missingPrereqs = $true
    }
} else {
    Write-Host "  ✗ node not found — download from https://nodejs.org" -ForegroundColor Red
    $missingPrereqs = $true
}

CheckCmd "npm"  "comes with Node.js — https://nodejs.org"
CheckCmd "npx"  "comes with Node.js — https://nodejs.org"
CheckCmd "git"  "download from https://git-scm.com"

if ($missingPrereqs -and -not $Force) {
    Write-Host ""
    Write-Host "  One or more prerequisites are missing." -ForegroundColor Red
    Write-Host "  Install them then re-run, or use -Force to skip this check." -ForegroundColor Yellow
    exit 1
}

# =============================================================================
# PHASE 2 — npm user prefix (no admin)
# =============================================================================
if (-not $GsdOnly) {
    Phase 2 "npm user prefix (no admin)"

    New-Item -ItemType Directory -Path $NpmPrefix -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $NpmPrefix "bin") -Force | Out-Null
    npm config set prefix $NpmPrefix 2>$null

    # Add to user PATH persistently
    $userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
    $npmBin = Join-Path $NpmPrefix "bin"
    if ($userPath -notlike "*npm-global*") {
        [System.Environment]::SetEnvironmentVariable("Path", "$npmBin;$userPath", "User")
        $env:Path = "$npmBin;$env:Path"
        Ok "Added $npmBin to user PATH"
    } else {
        Info "npm-global already in user PATH"
    }

    # PowerShell profile
    $profilePath = $PROFILE.CurrentUserAllHosts
    if ($profilePath -and (Test-Path (Split-Path $profilePath))) {
        if (-not (Test-Path $profilePath) -or -not (Get-Content $profilePath -ErrorAction SilentlyContinue | Select-String "npm-global")) {
            Add-Content $profilePath "`n`$env:Path = `"$npmBin;`$env:Path`""
            Ok "Added npm-global to PowerShell profile"
        } else {
            Info "npm-global already in PowerShell profile"
        }
    }
}

# =============================================================================
# PHASE 3 — npm global tools
# =============================================================================
if (-not $GsdOnly) {
    Phase 3 "npm global tools"

    foreach ($pkg in @("@agentmemory/agentmemory", "@colbymchenry/codegraph", "agnix")) {
        Write-Host "  Installing $pkg ..." -NoNewline
        try {
            npm install -g $pkg --prefix $NpmPrefix 2>$null
            Write-Host " ok" -ForegroundColor Green
        } catch {
            Write-Host " WARN — failed (non-fatal)" -ForegroundColor Yellow
        }
    }
}

# =============================================================================
# PHASE 4 — Copy GSD files to ~/.cursor
# =============================================================================
if (-not $PowerupOnly) {
    Phase 4 "Copy GSD files to ~/.cursor"

    if (-not (Test-Path $SourcePath)) {
        Write-Host "  ERROR: Source path not found: $SourcePath" -ForegroundColor Red
        exit 1
    }

    $existingGSD = Join-Path $CursorDir "get-shit-done"
    if ((Test-Path $existingGSD) -and -not $Force) {
        Write-Host "  Existing GSD installation found at: $existingGSD" -ForegroundColor Yellow
        $response = Read-Host "  Overwrite? (y/N)"
        if ($response -ne "y" -and $response -ne "Y") {
            Write-Host "  Skipping GSD file copy." -ForegroundColor Cyan
        }
    }

    $dirs = @(
        "commands\gsd", "agents",
        "get-shit-done\workflows", "get-shit-done\templates",
        "get-shit-done\templates\codebase", "get-shit-done\templates\research-project",
        "get-shit-done\references", "get-shit-done\scripts",
        "hooks", "skills", "cache", "repos"
    )
    foreach ($d in $dirs) {
        New-Item -ItemType Directory -Path (Join-Path $CursorDir $d) -Force | Out-Null
    }
    Ok "Directory structure ready"

    function CopyDir($srcSub, $destSub, $label) {
        $src  = Join-Path $SourcePath $srcSub
        $dest = Join-Path $CursorDir  $destSub
        if (Test-Path $src) {
            $srcFull = (Resolve-Path $src).Path
            Get-ChildItem -Path $srcFull -Recurse -File | ForEach-Object {
                $rel  = $_.FullName.Substring($srcFull.Length + 1)
                $dst  = Join-Path $dest $rel
                $dstF = Split-Path $dst -Parent
                if (-not (Test-Path $dstF)) { New-Item -ItemType Directory -Path $dstF -Force | Out-Null }
                Copy-Item -Path $_.FullName -Destination $dst -Force
            }
            Ok "Copied $label"
        } else {
            Info "SKIPPED (not found): $label"
        }
    }

    CopyDir "commands\gsd"  "commands\gsd"                    "commands/gsd"
    CopyDir "agents"        "agents"                           "agents"
    CopyDir "workflows"     "get-shit-done\workflows"          "workflows"
    CopyDir "templates"     "get-shit-done\templates"          "templates"
    CopyDir "references"    "get-shit-done\references"         "references"
    CopyDir "hooks"         "hooks"                            "hooks"

    # reindex script
    $reindexSrc = Join-Path $ScriptDir "cursor-powerup-reindex.sh"
    if (Test-Path $reindexSrc) {
        $reindexDst = Join-Path $CursorDir "get-shit-done\scripts\cursor-powerup-reindex.sh"
        Copy-Item $reindexSrc $reindexDst -Force
        Ok "Copied cursor-powerup-reindex.sh"
    }

    # GSD skill
    $skillSrc = Join-Path $SourcePath "skills\gsd-for-cursor\SKILL.md"
    if (Test-Path $skillSrc) {
        $skillDst = Join-Path $CursorDir "skills\gsd-for-cursor\SKILL.md"
        New-Item -ItemType Directory -Path (Split-Path $skillDst) -Force | Out-Null
        Copy-Item $skillSrc $skillDst -Force
        Ok "Copied gsd-for-cursor skill"
    }

    # settings.json
    $settingsPath = Join-Path $CursorDir "settings.json"
    $settingsObj = @{
        hooks = @{
            SessionStart = @(@{
                hooks = @(
                    @{ type = "command"; command = "node ~/.cursor/hooks/gsd-check-update.js" },
                    @{ type = "command"; command = "node ~/.cursor/hooks/gsd-powerup-reminder.js" }
                )
            })
        }
        statusLine = @{ type = "command"; command = "node ~/.cursor/hooks/gsd-statusline.js" }
    }
    if (Test-Path $settingsPath) {
        try {
            $existing = Get-Content $settingsPath -Raw | ConvertFrom-Json -AsHashtable -ErrorAction Stop
            $existing["hooks"]      = $settingsObj["hooks"]
            $existing["statusLine"] = $settingsObj["statusLine"]
            $settingsObj = $existing
        } catch {
            Warn "Could not parse existing settings.json — overwriting"
        }
    }
    $settingsObj | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding UTF8
    Ok "settings.json updated"

    "2.0.0" | Set-Content (Join-Path $CursorDir "get-shit-done\VERSION") -Encoding UTF8
}

# =============================================================================
# PHASE 5 — agentmemory connect cursor
# =============================================================================
if (-not $GsdOnly) {
    Phase 5 "agentmemory → Cursor MCP"
    $agentmemory = Get-Command agentmemory -ErrorAction SilentlyContinue
    if ($agentmemory) {
        try { agentmemory connect cursor 2>$null; Ok "agentmemory connect cursor done" }
        catch { Warn "agentmemory connect cursor failed — run manually in a new terminal" }
    } else {
        Warn "agentmemory not on PATH yet — open a new terminal and run: agentmemory connect cursor"
    }
}

# =============================================================================
# PHASE 6 — Ensure playwright + github in mcp.json
# =============================================================================
if (-not $GsdOnly) {
    Phase 6 "Ensure playwright + github in mcp.json"
    $mcpPath = Join-Path $CursorDir "mcp.json"

    if (Test-Path $mcpPath) {
        try {
            $mcp = Get-Content $mcpPath -Raw | ConvertFrom-Json -AsHashtable
        } catch { $mcp = @{} }
    } else { $mcp = @{} }

    if (-not $mcp.ContainsKey("mcpServers")) { $mcp["mcpServers"] = @{} }
    $s = $mcp["mcpServers"]

    if (-not $s.ContainsKey("playwright")) {
        $s["playwright"] = @{ command = "npx"; args = @("-y", "@playwright/mcp@latest") }
    }
    if (-not $s.ContainsKey("github")) {
        $s["github"] = @{
            url     = "https://api.githubcopilot.com/mcp/"
            headers = @{ Authorization = 'Bearer ${env:GITHUB_PERSONAL_ACCESS_TOKEN}' }
        }
    }
    if (-not $s.ContainsKey("agentmemory")) {
        $s["agentmemory"] = @{
            command = "npx"
            args    = @("-y", "@agentmemory/mcp")
            env     = @{ AGENTMEMORY_URL = '${AGENTMEMORY_URL:-http://localhost:3111}' }
        }
    }

    $mcp | ConvertTo-Json -Depth 10 | Set-Content $mcpPath -Encoding UTF8
    Ok "mcp.json updated (playwright + github + agentmemory)"
}

# =============================================================================
# PHASE 7 — antigravity safe skills
# =============================================================================
if (-not $GsdOnly) {
    Phase 7 "antigravity safe skills bundle"
    New-Item -ItemType Directory -Path (Join-Path $CursorDir "skills") -Force | Out-Null
    try {
        npx --yes antigravity-awesome-skills `
            --path (Join-Path $CursorDir "skills") `
            --category development,backend,frontend,security `
            --risk safe 2>$null
        Ok "antigravity skills installed"
    } catch {
        Warn "antigravity install skipped or failed (non-fatal)"
    }
}

# =============================================================================
# PHASE 8 — Clone reference repos
# =============================================================================
if (-not $GsdOnly) {
    Phase 8 "Clone reference repos to ~/.cursor/repos"
    New-Item -ItemType Directory -Path (Join-Path $CursorDir "repos") -Force | Out-Null

    $repos = @{
        "agentmemory"               = "https://github.com/rohitg00/agentmemory"
        "codegraph"                 = "https://github.com/colbymchenry/codegraph"
        "antigravity-awesome-skills"= "https://github.com/sickn33/antigravity-awesome-skills"
        "awesome-cursorrules"       = "https://github.com/PatrickJS/awesome-cursorrules"
    }
    foreach ($entry in $repos.GetEnumerator()) {
        $dest = Join-Path $CursorDir "repos\$($entry.Key)"
        if (-not (Test-Path $dest)) {
            Write-Host "  Cloning $($entry.Key) ..." -NoNewline
            try { git clone --depth 1 $entry.Value $dest 2>$null; Write-Host " ok" -ForegroundColor Green }
            catch { Write-Host " WARN — clone failed (non-fatal)" -ForegroundColor Yellow }
        } else {
            Info "Already exists: $($entry.Key)"
        }
    }
}

# =============================================================================
# PHASE 9 — gitnexus availability
# =============================================================================
if (-not $GsdOnly) {
    Phase 9 "gitnexus availability"
    $gnx = Get-Command gitnexus -ErrorAction SilentlyContinue
    if ($gnx) {
        Ok "gitnexus found ($($gnx.Source))"
    } else {
        Write-Host "  Installing gitnexus globally ..." -NoNewline
        try { npm install -g gitnexus 2>$null; Write-Host " ok" -ForegroundColor Green }
        catch { Write-Host " WARN — failed; use: npx gitnexus analyze" -ForegroundColor Yellow }
    }
}

# =============================================================================
# PHASE 10 — Write POWERUP-INSTALLED.md
# =============================================================================
Phase 10 "Finalize & write POWERUP-INSTALLED.md"

$installedAt = Get-Date -Format "yyyy-MM-dd HH:mm K"
$installedMd = @"
# cursor-powered-up installation record

| Field   | Value |
|---------|-------|
| Version | 2.0.0 |
| Date    | $installedAt |
| Source  | $ScriptDir |
| Target  | $CursorDir |

## What was installed

- GSD for Cursor (commands, agents, workflows, templates, references, hooks)
- Global npm tools: @agentmemory/agentmemory, @colbymchenry/codegraph, agnix
- MCP wired: agentmemory, playwright, github
- antigravity safe skills bundle
- Reference repos cloned to ~/.cursor/repos/
- Hooks: gsd-check-update, gsd-powerup-reminder, gsd-statusline

## Update

``````powershell
cd <cursor-powered-up-repo>
git pull
.\scripts\install.ps1 -Force
``````
"@

Set-Content (Join-Path $CursorDir "POWERUP-INSTALLED.md") $installedMd -Encoding UTF8
Ok "Wrote ~/.cursor/POWERUP-INSTALLED.md"

# =============================================================================
# PHASE 11 — Full power banner
# =============================================================================
Phase 11 "Full power banner"

Write-Host ""
Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║   cursor-powered-up  installed!          ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host " FULL POWER — complete these steps (required for 21st.dev + UI):" -ForegroundColor Yellow
Write-Host " See: docs/POST-INSTALL.md in this repo" -ForegroundColor Yellow
Write-Host "   • 21st.dev MCP (your API key)" -ForegroundColor Yellow
Write-Host "   • framer-motion in React projects" -ForegroundColor Yellow
Write-Host "   • GITHUB_PERSONAL_ACCESS_TOKEN" -ForegroundColor Yellow
Write-Host "   • agentmemory each session" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host ""
