<#
.SYNOPSIS
  Builds and exports an unmanaged Power Platform solution containing all Icons of IO canvas apps (Windows).

.PREREQUISITES
  - Power Platform CLI installed: winget install Microsoft.PowerAppsCLI (or https://aka.ms/pac)

.USAGE
  PS> cd C:\Path\To\PowerApps-ICONS-JLR\Solutions
  PS> .\build-solution-with-pac.ps1
#>

param(
  [string]$SolutionName = 'IconsOfIOAwards',
  [string]$DisplayName = 'Icons of IO Awards',
  [string]$PublisherName = 'IconsOfIOPublisher',
  [string]$PublisherPrefix = 'iio',
  [string]$Version = '1.0.0'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Resolve PAC CLI path with fallback to dotnet global tool
$PacPath = $null
$pacCmd = Get-Command pac -ErrorAction SilentlyContinue
if ($pacCmd) {
  $PacPath = $pacCmd.Source
} else {
  $fallback = Join-Path $env:USERPROFILE '.dotnet\tools\pac.exe'
  if (Test-Path $fallback) {
    $PacPath = $fallback
    Write-Host "Using PAC from dotnet global tools: $PacPath" -ForegroundColor DarkCyan
  } else {
    Write-Error "Power Platform CLI 'pac' not found. Install via 'winget install Microsoft.PowerAppsCLI' or from https://aka.ms/pac, or install dotnet tool: 'dotnet tool install -g Microsoft.PowerApps.CLI.Tool'"
  }
}

try { & $PacPath auth list | Out-Null } catch { & $PacPath auth create --url https://make.powerapps.com }

Write-Host "Creating solution: $SolutionName" -ForegroundColor Cyan
if (-not ((& $PacPath solution list) -match $SolutionName)) {
  & $PacPath solution create --name $SolutionName --publisherName $PublisherName --publisherPrefix $PublisherPrefix --displayName $DisplayName
}

$root = Split-Path $PSScriptRoot -Parent
$apps = @('NominationApp','AdminDashboard','ReviewerInterface','FinalSelectionApp','ReportingDashboard')
foreach ($app in $apps) {
  $path = Join-Path $root $app
  if (-not (Test-Path $path)) { Write-Error "Missing app folder: $path" }
  Write-Host "Adding $app to solution..." -ForegroundColor Yellow
  & $PacPath solution add-canvas-app --path $path --solutionUniqueName $SolutionName
}

$exportDir = Join-Path $root 'build'
New-Item -ItemType Directory -Force -Path $exportDir | Out-Null
$exportPath = Join-Path $exportDir "$SolutionName`_v$Version.zip"
Write-Host "Exporting solution to: $exportPath" -ForegroundColor Cyan
& $PacPath solution export --path $exportPath --name $SolutionName --managed false --includeCanvasApps true

Write-Host "\n✅ Solution exported." -ForegroundColor Green
Write-Host "Import via Admin Center → Solutions → Import." -ForegroundColor Yellow
