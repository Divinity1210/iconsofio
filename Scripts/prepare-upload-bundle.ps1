<#
.SYNOPSIS
  Prepares a single Windows-friendly ZIP containing all Canvas .msapp files
  and a per-app SharePoint list mapping guide for quick upload.

.USAGE
  PS> cd C:\Path\To\PowerApps-ICONS-JLR\Scripts
  PS> .\prepare-upload-bundle.ps1 -SiteUrl "https://<tenant>.sharepoint.com/sites/IconsOfIO"

.NOTES
  - If .msapp files are missing, this script will invoke build-msapps.ps1
  - The bundle contains a JSON mapping and a README with step-by-step upload
#>

param(
  [Parameter(Mandatory=$false)]
  [string]$SiteUrl = "https://<yourtenant>.sharepoint.com/sites/IconsOfIO"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path $PSScriptRoot -Parent
$buildDir = Join-Path $root 'build'
New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

$apps = @('NominationApp','AdminDashboard','ReviewerInterface','FinalSelectionApp','ReportingDashboard')
$expectedMsapps = $apps | ForEach-Object { Join-Path $buildDir ("$_.msapp") }

# Build .msapp if not present
$missing = $expectedMsapps | Where-Object { -not (Test-Path $_) }
if ($missing.Count -gt 0) {
  Write-Host "Missing .msapp files; building them now..." -ForegroundColor Yellow
  & (Join-Path $PSScriptRoot 'build-msapps.ps1')
}

$dateStamp = Get-Date -Format 'yyyyMMdd'
$bundleDir = Join-Path $buildDir ("CanvasApps_UploadReady_$dateStamp")
New-Item -ItemType Directory -Force -Path $bundleDir | Out-Null

# Copy .msapp files
foreach ($msapp in $expectedMsapps) { Copy-Item $msapp -Destination $bundleDir -Force }

# Create mapping JSON
$mapping = [ordered]@{
  siteUrl = $SiteUrl
  lists = [ordered]@{
    nominations = 'IconsOfIO_nominations'
    categories  = 'IconsOfIO_categories'
    reviewers   = 'IconsOfIO_reviewers'
    reviews     = 'IconsOfIO_reviews'
  }
  apps = [ordered]@{
    NominationApp    = @('nominations','categories')
    AdminDashboard   = @('nominations','reviews','reviewers','categories')
    ReviewerInterface= @('nominations','reviews','reviewers','categories')
    FinalSelectionApp= @('nominations','reviews')
    ReportingDashboard=@('nominations','reviews','categories')
  }
}

$mapping | ConvertTo-Json -Depth 6 | Out-File (Join-Path $bundleDir 'Connections-Mapping.json') -Encoding UTF8

# Create README with upload steps
$readme = @"
# Icons of IO – Canvas Apps Upload Bundle (Windows)

This bundle contains all .msapp files and the SharePoint list mapping needed to upload the apps to Power Apps on Windows.

## Prerequisites
- Ensure Microsoft Lists exist (only Lists are used as the datastore):
  - Run: `..\SharePoint\deploy-sharepoint-lists.ps1 -SiteUrl "$SiteUrl"`
  - Lists: IconsOfIO_nominations, IconsOfIO_categories, IconsOfIO_reviewers, IconsOfIO_reviews

## Upload Steps
1. Go to https://make.powerapps.com and select your environment.
2. Apps → Upload canvas app → upload EACH .msapp from this folder.
3. After each upload, open the app → Data panel →
   - Remove any non‑SharePoint connectors (if present).
   - Add SharePoint connector → Site: `$SiteUrl`.
   - Add lists according to Connections-Mapping.json.

## Import Order
1) NominationApp  2) AdminDashboard  3) ReviewerInterface  4) FinalSelectionApp  5) ReportingDashboard

## Files Included
- *.msapp (five apps)
- Connections-Mapping.json (per‑app list mapping)

## Notes
- Do NOT use handcrafted ZIPs such as NominationApp_PowerApp.zip; they will fail with manifest errors.
- This bundle is sufficient to run all apps with Microsoft Lists only.
"@
$readme | Out-File (Join-Path $bundleDir 'README_Upload.md') -Encoding UTF8

# Zip the bundle
$zipPath = Join-Path $buildDir ("IconsOfIO_CanvasApps_UploadReady_${dateStamp}.zip")
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
Compress-Archive -Path (Join-Path $bundleDir '*') -DestinationPath $zipPath -Force

Write-Host "\n✅ Upload bundle ready." -ForegroundColor Green
Write-Host "Folder: $bundleDir" -ForegroundColor Yellow
Write-Host "ZIP:    $zipPath" -ForegroundColor Yellow

