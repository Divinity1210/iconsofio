# Packaging Guide: Import Without Manifest Errors

This guide ensures you can import the Icons of IO applications without the "manifest file could not be found" error.

## Recommended Import Paths

- Upload canvas apps as `.msapp` files via Power Apps Studio.
- Import an unmanaged Solution ZIP via Power Platform Admin Center for ALM.

> Why not ZIP packages? Canvas app "Import package" ZIPs must be exported from Power Apps; handcrafted packages are unsupported and often trigger manifest errors. Using `.msapp` or Solutions avoids this entirely.

## Build `.msapp` Files (Local)

1. Install Power Platform CLI:
   - macOS: `brew tap microsoft/pac && brew install microsoft/pac/pac`
   - Windows: `winget install Microsoft.PowerApps.CLI` (or download installer from `https://aka.ms/pac`)
2. Build msapps:
   - macOS/Linux: `Scripts/build-msapps.sh`
   - Windows: `Scripts\build-msapps.ps1`
   - Outputs: `build/*.msapp` and `build/IconsOfIOAwards_MSApps_YYYYMMDD.zip`
   - Optional: Windows bundle with mapping/README → `Scripts\prepare-upload-bundle.ps1 -SiteUrl "https://<tenant>.sharepoint.com/sites/IconsOfIO"` (creates `build\IconsOfIO_CanvasApps_UploadReady_YYYYMMDD.zip`)
3. Import:
   - Go to `make.powerapps.com` → `Apps` → `Upload canvas app`
   - Upload each `.msapp`
   - Repoint SharePoint connections to:
     - `IconsOfIO_nominations`, `IconsOfIO_categories`, `IconsOfIO_reviewers`, `IconsOfIO_reviews`

## Build & Export a Solution (Local)

1. Ensure PAC is installed and authenticated.
2. Run:
   - macOS/Linux: `Solutions/build-solution-with-pac.sh`
   - Windows: `Solutions\build-solution-with-pac.ps1`
3. Import the exported ZIP via Admin Center → Solutions → Import.

## Post‑Import Checklist

- Confirm SharePoint lists exist using `SharePoint/deploy-sharepoint-lists.ps1 -SiteUrl <your-site>`.
- Map data connections per app to the lists above.
- Validate flows and review KPIs as outlined in `Documentation/DATA_MODEL_AND_MAPPING_v2.md`.

## Troubleshooting

- Manifest error on ZIP import: Use `.msapp` or Solution import instead.
- PAC not found: Install via Homebrew and re-run scripts.
- Connection issues: Recreate SharePoint connections in each app and retarget to your site.

## Legacy Packages To Avoid

Do not import these handcrafted ZIPs; they are retained only for reference and will fail with manifest errors:
- `NominationApp_PowerApp.zip`
- `AdminDashboard_PowerApp.zip`
- `ReviewerInterface_PowerApp.zip`
- `FinalSelectionApp_PowerApp.zip`
- `ReportingDashboard_PowerApp.zip`
- `IconsOfIOAwards_PowerApps_Import_Ready.zip`