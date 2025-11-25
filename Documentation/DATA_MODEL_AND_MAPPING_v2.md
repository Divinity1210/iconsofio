# Icons of IO Awards – Data Model and Requirements Mapping (v2)

This version makes the requirements explicit, hardens the data model, and adds concrete SharePoint list definitions and import steps so you can upload apps and immediately test end‑to‑end.

## Objectives (from proposal)
- Simplify nomination submission.
- Automate data capture and storage.
- Enable collaborative shortlisting and final selection.
- Improve data visibility and reporting.
- Ensure scalability, security, and ease of use.

## Functional Coverage → App Mapping
- Nomination Submission Form → NominationApp
- Automated Data Capture & Storage → SharePoint lists + Power Automate
- Scoring & Filtering → ReviewerInterface + AdminDashboard
- Shortlisting Workflow → AdminDashboard
- Final Review & Approval → FinalSelectionApp
- Reporting & Analytics → ReportingDashboard

## SharePoint Data Model (robust)

All lists will be created with the prefix `IconsOfIO_` for clarity. Columns below show the display name and type.

- `IconsOfIO_nominations`
  - Title (Text; nominee name)
  - Category (Choice; values from `categories`)
  - Summary (Note)
  - EvidenceLinks (Text)
  - SubmittedBy (Person)
  - SubmittedDate (DateTime)
  - Status (Choice: Submitted, InReview, Shortlisted, Rejected, Winner)
  - AverageScore (Number)
  - ReviewCount (Number)
  - Year (Number)
  - Region (Text)
  - Shortlisted (Boolean)
  - Winner (Boolean)
  - Attachments (enabled)

- `IconsOfIO_categories`
  - Title (Text; category name)
  - Description (Note)
  - IsActive (Boolean)
  - DisplayOrder (Number)

- `IconsOfIO_reviewers`
  - Title (Text; reviewer name)
  - Email (Text)
  - Role (Choice: Reviewer, Admin, Leadership)
  - ExpertiseCategories (MultiChoice)
  - IsActive (Boolean)

- `IconsOfIO_reviews` (new; child list for auditable scoring)
  - Title (Text; optional)
  - Nomination (Lookup → `IconsOfIO_nominations`)
  - Reviewer (Lookup → `IconsOfIO_reviewers`)
  - ScoreOverall (Number)
  - CriteriaScores (Note; JSON blob of criterion→score)
  - Comments (Note)
  - SubmittedDate (DateTime)
  - Status (Choice: Draft, Submitted)

The `reviews` list enables many reviewers per nomination with full auditability. Aggregates (AverageScore, ReviewCount) are stored on `nominations` and updated by the ReviewerInterface app or scheduled flow.

## End‑to‑End Workflow
1. NominationApp: submit nominations → `IconsOfIO_nominations` (`Status=Submitted`).
2. AdminDashboard: assign reviewers, manage statuses, shortlist.
3. ReviewerInterface: reviewers score assigned nominations → create `IconsOfIO_reviews` items; app updates aggregates on nominations.
4. FinalSelectionApp: leadership marks winners; audit via versions and `reviews`.
5. ReportingDashboard: visualize KPIs and distributions.

## Importing Historic Data (Excel)

Recommended: Place each worksheet into an Excel Table and import via Power Automate; or export to CSV and use the PnP PowerShell script below.

```powershell
# Connect to your site (replace tenant/site)
Connect-PnPOnline -Url "https://<tenant>.sharepoint.com/sites/<site>" -Interactive

# Import categories
Import-Csv ./categories.csv | ForEach-Object {
  Add-PnPListItem -List "IconsOfIO_categories" -Values @{ Title = $_.Name; Description = $_.Description; IsActive = $true }
}

# Import reviewers
Import-Csv ./reviewers.csv | ForEach-Object {
  Add-PnPListItem -List "IconsOfIO_reviewers" -Values @{ Title = $_.Name; Email = $_.Email; Role = $_.Role; IsActive = $true }
}

# Import nominations
Import-Csv ./nominations.csv | ForEach-Object {
  Add-PnPListItem -List "IconsOfIO_nominations" -Values @{
    Title = $_.NomineeName
    Category = $_.Category
    Summary = $_.Summary
    EvidenceLinks = $_.Evidence
    SubmittedDate = ([datetime]$_.SubmittedDate)
    Status = "Submitted"
    Year = [int]$_.Year
    Region = $_.Region
  }
}

# (Optional) Import existing review scores
Import-Csv ./reviews.csv | ForEach-Object {
  Add-PnPListItem -List "IconsOfIO_reviews" -Values @{
    Title = $_.Title
    Nomination = $_.NominationTitle
    Reviewer = $_.ReviewerName
    ScoreOverall = [double]$_.ScoreOverall
    CriteriaScores = $_.CriteriaJson
    Comments = $_.Comments
    SubmittedDate = ([datetime]$_.SubmittedDate)
    Status = "Submitted"
  }
}
```

## Robustness, Security, and Governance
- Enforce required fields in apps; validate emails and category selection.
- Role‑based views and permissions map to `security-roles.json`.
- Enable attachments on nominations; store links to evidence where needed.
- Use SharePoint versioning on `nominations` and `reviews` for auditing.

## Packaging and Import Guidance

There are two reliable ways to import the apps:
- Import each app as a Canvas `.msapp` file using Power Apps Studio.
- Import as a Solution ZIP via Power Platform Admin Center.

To create `.msapp` files locally, install Power Platform CLI (`pac`) and pack the app sources:

```bash
# Install pac (macOS)
brew tap microsoft/pac
brew install --cask pac

# Authenticate
pac auth create --url https://make.powerapps.com

# Pack each app (paths are app source folders)
mkdir -p build
pac canvas pack --msapp build/NominationApp.msapp --source NominationApp
pac canvas pack --msapp build/AdminDashboard.msapp --source AdminDashboard
pac canvas pack --msapp build/ReviewerInterface.msapp --source ReviewerInterface
pac canvas pack --msapp build/FinalSelectionApp.msapp --source FinalSelectionApp
pac canvas pack --msapp build/ReportingDashboard.msapp --source ReportingDashboard
```

Then upload each `.msapp` via Power Apps Studio (Apps → Upload canvas app). If you prefer solution import, create a solution and add the `.msapp` files using `pac solution` commands.

## Ready‑to‑Run SharePoint Setup
- Run `SharePoint/deploy-sharepoint-lists.ps1 -SiteUrl <your-site>` to create `nominations`, `categories`, `reviewers`, and `reviews` with the `IconsOfIO_` prefix.
- Schemas are in `SharePoint/*-list-schema.json`. You can adjust choices and defaults before running.

## Data Source Policy
- The applications use Microsoft Lists (SharePoint) exclusively as the data store.
- No CSV or Excel data sources are connected in the apps; an optional one‑time import from Excel to seed lists is supported via PnP PowerShell but not required for operation.

---
This v2 mapping converts your proposal, workbook, and event artifacts into a concrete, auditable model with clear import paths. It ensures the apps plug into SharePoint lists you can create immediately and supports robust reporting and governance.