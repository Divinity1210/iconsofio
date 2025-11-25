# Icons Of IO Canvas Apps — Upload Guide

This bundle includes five Power Apps canvas apps that use Microsoft Lists (SharePoint) as the datastore. Import each `.msapp` into Power Apps Studio, remove any legacy connectors, add ONE SharePoint connector pointing at your site, and map the lists per app.

Contents
- NominationApp.msapp
- AdminDashboard.msapp
- ReviewerInterface.msapp
- FinalSelectionApp.msapp
- ReportingDashboard.msapp
- Connections-Mapping.json (pre-fill `siteUrl` before import)

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