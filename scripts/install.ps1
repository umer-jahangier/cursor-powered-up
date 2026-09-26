<#
.SYNOPSIS
    cursor-powered-up — Multi-Agent Installer (Windows)

.DESCRIPTION
    One install for every AI coding agent (Claude Code, Cursor, Codex CLI, Gemini CLI,
    Antigravity, GitHub Copilot, Windsurf/Devin, OpenCode, Kiro, Cline).
    Skills, MCP servers and rules are applied per agent by scripts/lib/powerup.mjs,
    the same engine scripts/install.sh uses. GSD workflows are installed for Cursor.

.PARAMETER Agents
    detected (default) | all | comma list, e.g. "claude-code,cursor,codex".

.PARAMETER Packs
    Skill packs: default | all | none | ui-design,motion,3d,dataflow,workflow.

.PARAMETER Mcp
    MCP servers: core (default) | extra | all | none | server names.

.PARAMETER DryRun
    Print what would be installed; change nothing.

.PARAMETER Force
    Overwrite existing installation without prompting.

.PARAMETER GsdOnly
    Only copy GSD files (skip npm/MCP/skills phases).

.PARAMETER PowerupOnly
    Only run power-up phases (skip GSD file copy).

.EXAMPLE
    .\scripts\install.ps1
    .\scripts\install.ps1 -Agents "claude-code,cursor,codex" -Packs "default,workflow"
    .\scripts\install.ps1 -DryRun
    .\scripts\install.ps1 -GsdOnly
#>

param(
    [string]$Agents = "detected",
    [string]$Packs = "default",
    [string]$Mcp = "core",
    [switch]$DryRun,
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
$Powerup    = Join-Path $ScriptDir "lib\powerup.mjs"
$AgentsLib  = Join-Path $ScriptDir "lib\agents.mjs"

# ── Helpers ───────────────────────────────────────────────────────────────────
function Phase($n, $title) { Write-Host "`n▶ Phase ${n}: $title" -ForegroundColor Cyan }
function Ok($msg)   { Write-Host "  ✓ $msg" -ForegroundColor Green }
function Warn($msg) { Write-Host "  ⚠ $msg" -ForegroundColor Yellow }
function Info($msg) { Write-Host "    $msg" -ForegroundColor Gray }

# ── Header ────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║   cursor-powered-up — Multi-Agent Setup  ║" -ForegroundColor Green
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

# ── Agent selection ───────────────────────────────────────────────────────────
$Selected = (node $AgentsLib $Agents)
if ($LASTEXITCODE -ne 0) { exit 1 }
$HasCursor = ($Selected -split ' ') -contains 'cursor'
Write-Host ""
Write-Host "  Agents: $Selected" -ForegroundColor Cyan
Write-Host "  Packs:  $Packs    MCP: $Mcp" -ForegroundColor Cyan

$PowerupArgs = @('--agents', $Agents, '--packs', $Packs, '--mcp', $Mcp)
if ($DryRun) { $PowerupArgs += '--dry-run' }
if ($Force)  { $PowerupArgs += '--force' }

if ($DryRun) {
    node $Powerup all @PowerupArgs
    exit 0
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
# PHASE 4 — Copy GSD files to ~/.cursor (Cursor only)
# =============================================================================
if ($HasCursor -and -not $PowerupOnly) {
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

    # settings.json — merge hooks/statusline, never replace user keys (shared with install.sh)
    node (Join-Path $ScriptDir "lib\cursor-settings.mjs") (Join-Path $CursorDir "settings.json")
    if ($LASTEXITCODE -eq 0) { Ok "settings.json: GSD hooks + statusline ensured" }
    else { Warn "settings.json merge skipped — file left untouched" }

    "2.0.0" | Set-Content (Join-Path $CursorDir "get-shit-done\VERSION") -Encoding UTF8
}

# =============================================================================
# PHASE 5 — agentmemory connect cursor
# =============================================================================
if ($HasCursor -and -not $GsdOnly) {
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
# PHASE 7 — antigravity safe skills (Cursor)
# =============================================================================
if ($HasCursor -and -not $GsdOnly) {
    Phase 7 "antigravity safe skills bundle"
    New-Item -ItemType Directory -Path (Join-Path $CursorDir "skills") -Force | Out-Null
    try {
        npx --yes antigravity-awesome-skills `
            --path (Join-Path $CursorDir "skills") `
            --category development,backend `
            --risk safe 2>$null
        Ok "antigravity skills installed"
    } catch {
        Warn "antigravity install skipped or failed (non-fatal)"
    }
}

# =============================================================================
# PHASE 7b — Cross-agent power-up: skill packs, bundled skills, MCP, rules
# =============================================================================
if (-not $GsdOnly) {
    Phase "7b" "Skills + MCP + rules for: $Selected"
    node $Powerup all @PowerupArgs
    if ($LASTEXITCODE -ne 0) { Warn "Some items failed (see table above) — re-run with -Force to retry" }
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
| Version | 4.0.0 |
| Date    | $installedAt |
| Source  | $ScriptDir |
| Agents  | $Selected |
| Packs   | $Packs |
| MCP     | $Mcp |

Check state any time: ``node $Powerup status``

## Update

``````powershell
cd <cursor-powered-up-repo>
git pull
.\scripts\install.ps1 -Force
``````
"@

$agentsHome = Join-Path $HomeDir ".agents"
New-Item -ItemType Directory -Path $agentsHome -Force | Out-Null
Set-Content (Join-Path $agentsHome "POWERUP-INSTALLED.md") $installedMd -Encoding UTF8
if ($HasCursor) { Set-Content (Join-Path $CursorDir "POWERUP-INSTALLED.md") $installedMd -Encoding UTF8 }
Ok "Wrote ~/.agents/POWERUP-INSTALLED.md"

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
Write-Host " NEXT STEPS (docs/POST-INSTALL.md):" -ForegroundColor Yellow
Write-Host "   • Restart your agents / IDEs" -ForegroundColor Yellow
Write-Host "   • GITHUB_PERSONAL_ACCESS_TOKEN in your PowerShell profile" -ForegroundColor Yellow
Write-Host "   • agentmemory each session" -ForegroundColor Yellow
Write-Host "   • Per repo: node $Powerup project-init --dir .   (AGENTS.md for every agent)" -ForegroundColor Yellow
Write-Host "   • Optional: 21st.dev Magic MCP (needs your API key)" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host ""
