# Icons of IO Awards – Data Model and Requirements Mapping

This document synthesizes the requirements screenshot, the working Excel file (`ICONs Data sheet working file.xlsx`), and the app assets to produce a clear, testable data model and end‑to‑end workflow for the Icons of IO Awards solution.

## Sources Considered
- Requirements proposal image (solution purpose, objectives, functional and non‑functional requirements; preparer name redacted)
- Excel workbook: `ICONs Data sheet working file.xlsx` (assumed historical nominations and event records)
- App artifacts and documentation within the repository (Nomination, Admin, Reviewer, Final Selection, Reporting; Deployment Guide and User Manual)

## Core Entities
- **Nominations**
  - Key fields: `NominationId`, `NomineeName`, `CategoryId`, `CategoryName`, `Summary`, `EvidenceLinks`, `AttachmentIds`, `SubmittedByName`, `SubmittedByEmail`, `SubmittedDate`, `Status` (Submitted, InReview, Shortlisted, Rejected, Winner), `AverageScore`, `ReviewCount`, `Shortlisted` (bool), `Winner` (bool), `Year`, `Region`, `Tags`.
  - Storage: SharePoint list `nominations` (already scaffolded).

- **Categories**
  - Key fields: `CategoryId`, `Name`, `Description`, `IsActive`, `WeightingRules` (optional), `MaxWinners` (optional), `DisplayOrder`.
  - Storage: SharePoint list `categories` (already scaffolded).

- **Reviewers**
  - Key fields: `ReviewerId`, `Name`, `Email`, `Role` (Reviewer, Admin, Leadership), `ExpertiseCategories` (multi‑value), `IsActive`.
  - Storage: SharePoint list `reviewers` (already scaffolded).

- **Reviews (recommended child list)**
  - Rationale: A separate child list makes scoring auditable and many‑to‑many (one nomination → many reviews). If you prefer simplicity, scores can live on `nominations` as aggregate columns.
  - Key fields: `ReviewId`, `NominationId` (lookup), `ReviewerId` (lookup), `ScoreOverall`, `CriteriaScores` (JSON for Innovation/Impact/Execution, etc.), `Comments`, `SubmittedDate`, `Status` (Draft, Submitted).
  - Storage: SharePoint list `reviews` (optional extension).

- **Settings (optional)**
  - Key fields: `EventYear`, `SubmissionWindowStart`, `SubmissionWindowEnd`, `ScoringCriteria`, `EmailTemplates`.
  - Storage: SharePoint list `settings` or environment variables.

## End‑to‑End Workflow
1. **Nomination Submission** (NominationApp)
   - Public form captures nominee details, category, summary, and attachments.
   - Saves a record in `nominations` with `Status = Submitted`.

2. **Assignment & Administration** (AdminDashboard)
   - Admin filters by category/year, assigns reviewers (stores reviewer IDs on the nomination or creates review tasks).
   - Bulk actions for status changes and shortlist marking.

3. **Reviewer Scoring** (ReviewerInterface)
   - Reviewers see only assigned nominations.
   - Enter scores per criteria with comments; submit to create/commit `reviews` records.
   - Nomination aggregates update: `AverageScore`, `ReviewCount`.

4. **Shortlisting & Final Selection** (AdminDashboard → FinalSelectionApp)
   - Admin shortlists based on thresholds or manual selection.
   - Leadership reviews shortlisted candidates; marks winners with audit trail.

5. **Reporting & Analytics** (ReportingDashboard)
   - KPIs: Total nominations, pending/completed reviews, shortlist rate, winners by category, average scores by category, reviewer throughput, cycle time.
   - Charts: Nominations by category, review progress by status, score distribution.

## Functional Requirements → App Coverage
- Nomination Submission Form → NominationApp
- Automated Data Capture & Storage → SharePoint lists + Power Automate notifications
- Scoring & Filtering Mechanism → ReviewerInterface + AdminDashboard filters
- Shortlisting Workflow → AdminDashboard (shortlist) + FinalSelectionApp (approval)
- Final Review & Approval → FinalSelectionApp (leadership actions)
- Reporting & Analytics → ReportingDashboard

## Non‑Functional Requirements Mapping
- Simplicity → Single‑purpose apps with clear roles and minimal inputs
- Scalability → SharePoint lists with growth path to Dataverse; batch operations supported
- Security → Role‑based access (security‑roles.json), restricted connections, audit via list permissions
- Integration → Power Automate for email/Teams notifications; export to CSV/XLSX
- Maintainability → Documented deployment (`DEPLOYMENT_GUIDE.md`), environment variables, modular apps

## Using the Excel Workbook (Data Seeding)
While we can’t inspect the workbook contents here, typical sheets include nominations, categories, reviewers, and historic outcomes. You can seed SharePoint with this data using either approach:

### Option A: Power Automate (No‑code)
- Flow: `Excel → Apply to each row → Create item in SharePoint`.
- Use an Excel table per sheet (e.g., `tblNominations`, `tblCategories`).

### Option B: PnP PowerShell (Scripted)
```powershell
# 1) Save each worksheet to CSV (e.g., nominations.csv, categories.csv, reviewers.csv)
# 2) Then run a one‑time import (replace <siteUrl> and list names if different)
Connect-PnPOnline -Url "https://<tenant>.sharepoint.com/sites/<site>" -Interactive

Import-Csv ./nominations.csv | ForEach-Object {
  Add-PnPListItem -List "nominations" -Values @{
    Title = $_.NomineeName
    Category = $_.Category
    Summary = $_.Summary
    SubmittedBy = $_.SubmittedBy
    SubmittedDate = ([datetime]$_.SubmittedDate)
    Status = "Submitted"
  }
}

Import-Csv ./categories.csv | ForEach-Object {
  Add-PnPListItem -List "categories" -Values @{ Title = $_.Name; Description = $_.Description }
}

Import-Csv ./reviewers.csv | ForEach-Object {
  Add-PnPListItem -List "reviewers" -Values @{ Title = $_.Name; Email = $_.Email; Role = $_.Role }
}
```

## Data Quality & Governance
- Normalize category names/codes; deduplicate nominations; ensure emails are valid.
- Enforce required fields at submission; use consistent year/region tags for reporting.
- Maintain an audit trail via the `reviews` child list or SharePoint version history.

## KPIs & Reports (Ready for Testing)
- Throughput: `Total Nominations`, `Shortlisted`, `Winners`.
- Review Progress: `Pending`, `In Review`, `Completed` by category.
- Quality: `Average Score` by category, score distribution, reviewer variance.
- Operations: `Cycle Time` from submission to decision; reviewer workload.

## How the Images Help
- Event images can seed demo content (attachments on nominations) and illustrate reporting views.
- Use them as sample evidence files during testing to validate upload/preview flows.

## Next Steps
- Import the individual app ZIPs in the recommended order and click Play to preview.
- Seed SharePoint lists from the Excel workbook using one of the options above.
- Validate KPIs in the Reporting Dashboard once data is loaded.

---
This mapping ensures the artifacts you shared line up cleanly with the implemented apps, lists, and dashboards. It gives you a clear path to seed real event data and test the full workflow end‑to‑end.