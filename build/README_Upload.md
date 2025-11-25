# Icons Of IO Canvas Apps — Upload Guide

This guide covers uploading five Power Apps canvas apps that use Microsoft Lists (SharePoint) as the datastore. If `.msapp` files are present in `build/`, import each into Power Apps Studio; otherwise, import the Solution zip (`IconsOfIOAwards_PowerPlatform_v1.0.0.zip`) or generate `.msapp` on Windows using `Scripts\build-msapps.ps1`. After import, remove any legacy connectors, add ONE SharePoint connector pointing at your site, and map the lists per app.

Contents (after generating on Windows)
- NominationApp.msapp
- AdminDashboard.msapp
- ReviewerInterface.msapp
- FinalSelectionApp.msapp
- ReportingDashboard.msapp
- Connections-Mapping.json (pre-fill `siteUrl` before import)

If `.msapp` files are not present
- Use the Solution import (single artifact): import `IconsOfIOAwards_PowerPlatform_v1.0.0.zip` via Solutions.
- Or generate `.msapp` on Windows using the script below, then upload each `.msapp`.

Prerequisites
- SharePoint site URL available (e.g., `https://contoso.sharepoint.com/sites/IconsOfIOAwards`)
- The following Microsoft Lists exist in that site:
  - `IconsOfIO_nominations`
  - `IconsOfIO_categories`
  - `IconsOfIO_reviewers`
  - `IconsOfIO_reviews`

Recommended Import Order
1) NominationApp.msapp
2) AdminDashboard.msapp
3) ReviewerInterface.msapp
4) FinalSelectionApp.msapp
5) ReportingDashboard.msapp

Import Steps (per app)
1) Open `https://make.powerapps.com` → Apps → New app → Canvas → Import canvas app → upload the `.msapp`.
2) In Studio, open Data panel:
   - Remove any non-SharePoint connectors if present.
   - Add SharePoint → enter your `siteUrl`.
3) Map data sources to lists:
   - Nominations → `IconsOfIO_nominations`
   - Categories → `IconsOfIO_categories`
   - Reviewers → `IconsOfIO_reviewers`
   - Reviews → `IconsOfIO_reviews`
4) Save and Publish the app.

Generate .msapp on Windows
- Prereqs: Windows 10/11, PowerShell 5.1+, .NET SDK installed.
- Steps:
  - Open PowerShell and change directory: `cd C:\Path\To\PowerApps-ICONS-JLR`
  - Run: `Scripts\build-msapps.ps1`
    - Sign in when prompted.
    - The script packs from `build\<App>_src` and outputs five `.msapp` files in `build/`.
    - It also creates `build\IconsOfIOAwards_MSApps_<YYYYMMDD_HHMMSS>.zip` containing all `.msapp` plus docs.
  - Then upload each `.msapp` as described above.

Troubleshooting `.msapp` build (Windows)
- If PowerShell prompts about execution policy or security, run:
  - `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force`
- Confirm CLI version and path:
  - `~\.dotnet\tools\pac.exe --version` or `pac --version`
- Validate sources before packing (from repo root):
  - `pac canvas validate --sources build\NominationApp_src`
- Re-run the script and check logs:
  - Logs are written to `build\pack-logs\<App>-validate.log` and `build\pack-logs\<App>-pack.log`
- If pack still fails, try downgrading CLI:
  - `dotnet tool update -g Microsoft.PowerApps.CLI --version 1.48.1`
- Known issue: theme packing errors (e.g., `PA3001`). Workaround:
  - Temporarily rename `build\AdminDashboard_src\Themes.json` to `Themes.json.disabled` and pack.
  - After import, set the theme inside Power Apps Studio.

Per-App List Usage
- NominationApp: reads Categories; writes Nominations.
- AdminDashboard: reads Nominations/Categories/Reviewers/Reviews; writes Nominations/Categories/Reviewers.
- ReviewerInterface: reads Nominations/Categories/Reviewers; writes Reviews.
- FinalSelectionApp: reads Nominations/Reviews; writes Reviews.
- ReportingDashboard: reads Nominations/Reviews.

Notes
- These apps assume Microsoft Lists only (no Dataverse).
- Ensure lists exist before importing; if not, create them and include required columns.
- Keep a single SharePoint connection per app to the same `siteUrl`.

Teams App Packages (not for Power Apps import)
- The `*_PowerApp.zip` files under `build/UploadBundle_<timestamp>/` were Teams app packages (contain a Teams `manifest.json`). These are not valid for Power Apps import and have been removed to avoid confusion.
- Use either `.msapp` upload (Apps → Upload canvas app) or import the solution zip (`IconsOfIOAwards_PowerPlatform_v1.0.0.zip`) via Solutions.
CI Build on GitHub Actions (Mac-friendly)
- If you prefer to stay on mac, use the provided GitHub Actions workflows:
  - `.github/workflows/build-msapps.yml` builds `.msapp` files on a Windows runner and uploads them as artifacts.
  - `.github/workflows/export-solution.yml` exports a Dataverse solution zip from your environment using service principal auth.
- Steps:
  - Push this repo to GitHub (private recommended).
  - In repo → Settings → Secrets and variables → Actions, add:
    - `DATAVERSE_URL` = `https://org178d63d8.crm4.dynamics.com/`
    - `AAD_TENANT_ID` = your Azure AD tenant ID
    - `AAD_CLIENT_ID` = app registration (service principal) client ID
    - `AAD_CLIENT_SECRET` = client secret for the app registration
  - Run the “Build Canvas Apps (.msapp)” workflow and download the `msapps` artifact.
  - Upload each `.msapp` in Power Apps Studio → Apps → Upload canvas app.
  - Create a solution in Maker UI and add your apps.
  - Run “Export Power Platform Solution” workflow with `solution_name=IconsOfIOAwards` to get a solution zip artifact.
Release Workflow (one-click packaging and publishing)
- Use `.github/workflows/release-msapps-and-solution.yml` when you want both `.msapp` builds and a solution export published as a GitHub Release.
- Where you act:
  - GitHub → Actions → “Release Canvas Apps and Solution” → Run workflow.
  - Or push a tag like `v1.0.0` to trigger automatically.
- Inputs on manual run:
  - `solution_name`: unique name (e.g., `IconsOfIOAwards`).
  - `managed`: `true` for managed, `false` for unmanaged.
  - `version_tag`: release tag (e.g., `v1.0.0`).
- Prerequisites (GitHub secrets):
  - `DATAVERSE_URL`, `AAD_TENANT_ID`, `AAD_CLIENT_ID`, `AAD_CLIENT_SECRET` as described above.
- Outputs:
  - Release assets including `build/*.msapp` and exported solution zip.
- After the release:
  - Download assets from GitHub → Releases.
  - Import `.msapp` via Maker UI or import the solution zip via Solutions.

No‑Azure Option (packaging only)
- If you don’t have Azure or don’t want service principal setup:
  - Run `.github/workflows/build-msapps.yml` to get `.msapp` artifacts, OR
  - Run `.github/workflows/release-msapps-only.yml` to publish a release with `.msapp` assets.
- Where you act:
  - GitHub → Actions → “Build Canvas Apps (.msapp)” → Run workflow → download `msapps` artifact, or
  - GitHub → Actions → “Release Canvas Apps (.msapp only)” → Run workflow with `version_tag` (or push a tag like `v1.0.1`).
- No secrets required for packaging `.msapp`.
- After build/release:
  - Maker UI → Apps → Upload canvas app → select each `.msapp`.
  - Add one SharePoint connector to your `siteUrl` and map lists per app.

Where You Perform Each Action
- GitHub (CI): add secrets, run workflows, download artifacts, publish releases.
- Azure Portal (once): create the app registration and generate `AAD_CLIENT_SECRET` with minimal privileges to export solutions.
- Power Apps Maker UI: upload `.msapp`, set connections to your SharePoint `siteUrl`, add apps to a solution, import solution zip.

Minimal Permissions for Service Principal
- Assign the app registration the least privileges needed:
  - Power Platform → Environment Maker or a custom role that permits solution export.
  - SharePoint permissions are not required for packaging; they are configured via user connections in Maker UI after import.

Quick Start Checklist
- GitHub: add four secrets and run “Build Canvas Apps (.msapp)” or “Release Canvas Apps and Solution”.
- Maker UI: upload `.msapp` and repoint connections per `build/Connections-Mapping.json`.
- Optional: run “Export Power Platform Solution” to produce a zip for environment-to-environment moves.
