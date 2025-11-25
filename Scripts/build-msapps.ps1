<#
.SYNOPSIS
  Builds importable Canvas .msapp files for all Icons of IO apps on Windows.

.DESCRIPTION
  Uses Power Platform CLI (pac) to pack each app source folder into a .msapp.
  Outputs individual .msapp files and a convenience ZIP bundle in ../build.

.PREREQUISITES
  - Windows 10/11 with PowerShell 5.1+
  - Power Platform CLI installed:
      winget install Microsoft.PowerAppsCLI
    or download from https://aka.ms/pac

.USAGE
  PS> cd C:\Path\To\PowerApps-ICONS-JLR\Scripts
  PS> .\build-msapps.ps1
#>

param(
  [string]$OutDir = (Join-Path (Split-Path $PSScriptRoot -Parent) 'build')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$apps = @(
  'NominationApp',
  'AdminDashboard',
  'ReviewerInterface',
  'FinalSelectionApp',
  'ReportingDashboard'
)

# Resolve PAC CLI path, preferring a pinned dotnet global tool version
$PacPath = $null
$pacCmd = Get-Command pac -ErrorAction SilentlyContinue
if ($pacCmd) {
  $PacPath = $pacCmd.Source
} else {
  $dotnetPac = Join-Path $env:USERPROFILE '.dotnet\tools\pac.exe'
  if (-not (Test-Path $dotnetPac)) {
    Write-Host "Installing PAC via dotnet tool (v1.50.1)..." -ForegroundColor Yellow
    try { dotnet tool install -g Microsoft.PowerApps.CLI.Tool --version 1.50.1 | Out-Null } catch { }
  }
  if (-not (Test-Path $dotnetPac)) {
    Write-Host "Attempting PAC install via dotnet tool (fallback v1.49.0)..." -ForegroundColor Yellow
    try { dotnet tool install -g Microsoft.PowerApps.CLI.Tool --version 1.49.0 | Out-Null } catch { }
  }
  if (Test-Path $dotnetPac) {
    $PacPath = $dotnetPac
    Write-Host "Using PAC from dotnet tools: $PacPath" -ForegroundColor DarkCyan
  } else {
    Write-Error "Power Platform CLI 'pac' not found. Install via winget or dotnet tool: https://aka.ms/pac"
  }
}

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

# Create logs directory for validation/pack output
$LogDir = Join-Path $OutDir 'pack-logs'
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

try {
  # Canvas pack does not require an authenticated profile.
  # Avoid interactive auth in CI to keep this script Azure-free.
  & $PacPath --help | Out-Null
} catch {
  Write-Host "PAC CLI invocation check failed, continuing without auth." -ForegroundColor DarkYellow
}

# Disable telemetry to avoid interactive prompts in some environments
try { & $PacPath telemetry disable | Out-Null } catch { }

foreach ($app in $apps) {
  $src = Join-Path (Split-Path $PSScriptRoot -Parent) ("build\{0}_src" -f $app)
  if (-not (Test-Path $src)) { Write-Host "Skipping: source not found → $src" -ForegroundColor DarkYellow; continue }
  $out = Join-Path $OutDir ("{0}.msapp" -f $app)
  Write-Host "Validating $app sources → $src" -ForegroundColor Cyan
  try {
    & $PacPath canvas validate --sources "$src" 2>&1 | Tee-Object -FilePath (Join-Path $LogDir ("{0}-validate.log" -f $app)) | Out-Null
  } catch {
    Write-Host "⚠️  Validation failed for $app. See log: $(Join-Path $LogDir ("{0}-validate.log" -f $app))" -ForegroundColor Red
    continue
  }

  Write-Host "Packing $app → $out" -ForegroundColor Cyan
  try {
    & $PacPath canvas pack --msapp "$out" --sources "$src" --verbose 2>&1 | Tee-Object -FilePath (Join-Path $LogDir ("{0}-pack.log" -f $app)) | Out-Null
    if (-not (Test-Path $out)) {
      Write-Host "⚠️  Pack did not produce $out. See log: $(Join-Path $LogDir ("{0}-pack.log" -f $app))" -ForegroundColor Red
    }
  } catch {
    Write-Host "⚠️  Pack failed for $app. See log: $(Join-Path $LogDir ("{0}-pack.log" -f $app)). You can try a Solution import then use 'pac canvas download' to export the .msapp from your environment." -ForegroundColor Red
  }
}

$dateStamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$zipPath = Join-Path $OutDir "IconsOfIOAwards_MSApps_$dateStamp.zip"
Write-Host "Creating bundle: $zipPath" -ForegroundColor Cyan
try {
  $toZip = Get-ChildItem $OutDir -Filter *.msapp
  if ($toZip.Count -eq 0) {
    Write-Host "No .msapp files found to zip. Bundle will include docs only." -ForegroundColor DarkYellow
  }
  Compress-Archive -Path $toZip -DestinationPath $zipPath -Force
  # Append helpful docs if present
  $root = Split-Path $PSScriptRoot -Parent
  $docs = @(
    (Join-Path $root 'build\README_Upload.md'),
    (Join-Path $root 'build\Connections-Mapping.json')
  ) | Where-Object { Test-Path $_ }
  if ($docs.Count -gt 0) {
    Compress-Archive -Path $docs -DestinationPath $zipPath -Update
  }
} catch {
  Write-Host "⚠️  Failed to create bundle: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "\n✅ Build complete." -ForegroundColor Green
Write-Host "Outputs located in: $OutDir" -ForegroundColor Yellow
Write-Host "Import via Power Apps Studio → Apps → Upload canvas app (.msapp), or use the solution export script." -ForegroundColor Yellow
