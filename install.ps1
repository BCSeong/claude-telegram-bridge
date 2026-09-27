#Requires -Version 5.1
param(
    [string]$WorkDir
)
$ErrorActionPreference = 'Stop'

$RepoRoot   = $PSScriptRoot
$Plugin     = 'telegram@claude-plugins-official'
$ClaudeDir  = Join-Path $env:USERPROFILE '.claude'
$StateDir   = Join-Path $ClaudeDir 'channels\telegram'
$EnvFile    = Join-Path $StateDir '.env'
$SettingsFile = Join-Path $ClaudeDir 'telegram-session.json'

function Step($n, $msg) { Write-Host "`n[$n/6] $msg" -ForegroundColor Cyan }
function Ok($msg)       { Write-Host "  OK  $msg" -ForegroundColor Green }
function Skip($msg)     { Write-Host "  --  $msg" -ForegroundColor DarkGray }
function Fail($msg)     { Write-Host "  !!  $msg" -ForegroundColor Red; exit 1 }

Step 1 'Checking prerequisites'
foreach ($c in 'claude', 'node', 'npm') {
    if (-not (Get-Command $c -ErrorAction SilentlyContinue)) {
        Fail "'$c' not found. Install Claude Code (and Node.js) first, then re-run."
    }
}
Ok "claude $((claude --version) -split ' ' | Select-Object -First 1)"

Step 2 'Installing Bun (runtime for the Telegram plugin)'
if (Get-Command bun -ErrorAction SilentlyContinue) {
    Skip "bun $(bun --version) already installed"
} else {
    npm install -g bun | Out-Null
    if (-not (Get-Command bun -ErrorAction SilentlyContinue)) { Fail 'bun install failed. Open a new terminal and re-run.' }
    Ok "bun $(bun --version)"
}

Step 3 'Installing the official Telegram plugin'
$list = claude plugin list | Out-String
if ($list -match [regex]::Escape($Plugin)) {
    Skip 'plugin already installed'
} else {
    claude plugin install $Plugin --scope user | Out-Null
    Ok 'plugin installed'
}
# One bot token allows only one polling session, so keep the plugin off
# everywhere except the launcher session.
$block = ((claude plugin list | Out-String) -split '(?m)^\s*>\s*') | Where-Object { $_.StartsWith($Plugin) }
if ($block -match 'Status:.*\benabled') {
    claude plugin disable $Plugin --scope user | Out-Null
}
Ok 'plugin disabled globally; enabled only in the launcher session'
Set-Content -Path $SettingsFile -Encoding ascii -Value '{ "enabledPlugins": { "telegram@claude-plugins-official": true } }'

Step 4 'Bot token'
function Test-Token($t) {
    try { (Invoke-RestMethod "https://api.telegram.org/bot$t/getMe" -TimeoutSec 15).result.username } catch { $null }
}
$botName = $null
if (Test-Path $EnvFile) {
    $existing = ((Get-Content $EnvFile -Raw) -replace '^TELEGRAM_BOT_TOKEN=', '').Trim()
    $botName = Test-Token $existing
    if ($botName) { Skip "token already saved and valid (@$botName)" }
}
while (-not $botName) {
    Write-Host '  Paste the token from @BotFather (input is hidden):'
    $secure = Read-Host -AsSecureString
    $token = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)).Trim()
    $botName = Test-Token $token
    if (-not $botName) { Write-Host '  Telegram rejected that token. Try again.' -ForegroundColor Yellow; continue }
    New-Item -ItemType Directory -Force $StateDir | Out-Null
    Set-Content -Path $EnvFile -Value "TELEGRAM_BOT_TOKEN=$token" -Encoding ascii -NoNewline
    Ok "token saved (@$botName)"
}

Step 5 'Creating the desktop launcher'
if (-not $WorkDir) {
    $WorkDir = Read-Host '  Folder Claude should work in (Enter = your home folder)'
    if (-not $WorkDir) { $WorkDir = $env:USERPROFILE }
}
if (-not (Test-Path $WorkDir)) { Fail "Folder not found: $WorkDir" }
$WorkDir = (Resolve-Path $WorkDir).Path
$launcher = Join-Path ([Environment]::GetFolderPath('Desktop')) 'claude-telegram.bat'
$prompt = Join-Path $RepoRoot 'prompts\remote-role.md'
@"
@echo off
title Claude Code - Telegram
cd /d "$WorkDir"
call claude --settings "%USERPROFILE%\.claude\telegram-session.json" --append-system-prompt-file "$prompt" --channels plugin:telegram@claude-plugins-official -n telegram
pause
"@ | Set-Content -Path $launcher -Encoding Default
Ok "launcher: $launcher"
Ok "work folder: $WorkDir"

Step 6 'Next steps'
Write-Host @"
  1. Double-click claude-telegram.bat on the desktop.
  2. On your phone, message @$botName. It replies with a pairing command.
  3. Type that command into the Claude window, e.g.  /telegram:access pair abc123
  4. Lock the bot to you only:                       /telegram:access policy allowlist
"@
