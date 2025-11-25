# Icons of IO Awards System - Deployment Guide

## Overview

This guide provides comprehensive instructions for deploying the Icons of IO Awards Power Apps solution. The system streamlines the nomination, evaluation, and selection process for awards, replacing manual Excel-based workflows.

## Prerequisites

### Required Licenses
- Microsoft 365 Business Premium or Enterprise (E3/E5)
- Power Apps Premium licenses for app creators and heavy users
- SharePoint Online included in Microsoft 365

### Required Permissions
- **SharePoint Admin**: To create sites and configure permissions
- **Power Platform Admin**: To create environments and deploy apps
- **Global Admin**: For tenant-level security configurations (optional)

### Required Tools
- PowerShell 5.1 or later (Windows)
- PnP PowerShell module
- Microsoft.PowerApps.Administration.PowerShell module
- Power Platform CLI (`pac`) for packaging/import via solutions or `.msapp` (Windows: `winget install Microsoft.PowerApps.CLI`)

## Pre-Deployment Setup

### 1. Install Required PowerShell Modules

```powershell
# Install PnP PowerShell
Install-Module PnP.PowerShell -Force -AllowClobber

# Install Power Apps modules
Install-Module Microsoft.PowerApps.Administration.PowerShell -Force
Install-Module Microsoft.PowerApps.PowerShell -Force

# Verify installations
Get-Module PnP.PowerShell -ListAvailable
Get-Module Microsoft.PowerApps* -ListAvailable
```

### 2. Create Power Platform Environment

1. Navigate to [Power Platform Admin Center](https://admin.powerplatform.microsoft.com/)
2. Click **Environments** > **New**
3. Configure environment:
   - **Name**: `Icons of IO Awards - Production`
   - **Type**: `Production`
   - **Region**: Select appropriate region
   - **Create database**: `Yes`
   - **Language**: `English`
   - **Currency**: Select appropriate currency
4. Click **Save**

### 3. Create SharePoint Site

1. Navigate to [SharePoint Admin Center](https://admin.microsoft.com/sharepoint)
2. Click **Sites** > **Active sites** > **Create**
3. Select **Team site**
4. Configure site:
   - **Site name**: `Icons of IO Awards`
   - **Site address**: `IconsOfIO`
   - **Language**: `English`
   - **Privacy settings**: `Private`
5. Click **Finish**

## Deployment Steps

### Step 1: Deploy SharePoint Lists (Microsoft Lists only)

1. **Navigate to project directory**:
   ```powershell
   cd "C:\Path\To\PowerApps-ICONS-JLR"
   ```

2. **Run SharePoint deployment script**:
   ```powershell
   .\SharePoint\deploy-sharepoint-lists.ps1 -SiteUrl "https://yourtenant.sharepoint.com/sites/IconsOfIO"
   ```

3. **Verify list creation**:
   - Navigate to your SharePoint site
   - Confirm these lists exist (Microsoft Lists are the sole data store):
     - `IconsOfIO_nominations`
     - `IconsOfIO_categories`
     - `IconsOfIO_reviewers`
     - `IconsOfIO_reviews`

### Step 2: Configure Security

1. **Run security deployment script**:
   ```powershell
   .\Security\deploy-security.ps1 -SiteUrl "https://yourtenant.sharepoint.com/sites/IconsOfIO" -TenantUrl "https://yourtenant.crm.dynamics.com" -EnvironmentName "your-environment-id"
   ```

2. **Add users to security groups**:
   - Navigate to SharePoint site > **Settings** > **Site permissions**
   - Add users to appropriate groups:
     - `IIO_Nominators`: All employees who can submit nominations
     - `IIO_Reviewers`: Designated reviewers
     - `IIO_Administrators`: Awards process administrators
     - `IIO_Leadership`: Senior leadership for final decisions
     - `IIO_System_Admins`: Technical administrators

### Step 3: Import Power Apps

#### Option A: Upload Canvas Apps (.msapp) — Windows

1. **Navigate to Power Apps portal**: [make.powerapps.com](https://make.powerapps.com)
2. **Select your environment**
3. **Upload each app**:
   - Click **Apps** → **Upload canvas app**
   - Build on Windows using: `Scripts\build-msapps.ps1` (produces `.msapp` in `build\`)
   - Upload each `.msapp` and configure SharePoint connections during import

#### Option B: Import as Solution — Windows (ALM)

1. Build solution: `Solutions\build-solution-with-pac.ps1`
2. Import via Admin Center → **Solutions** → **Import** → select `build\IconsOfIOAwards_v1.0.0.zip`

### Step 4: Configure Connections

For each Power App:

1. **Open the app in edit mode**
2. **Configure SharePoint connection (Microsoft Lists)**:
   - Go to **Data** > **Add data**
   - Select **SharePoint**
   - Connect to your site: `https://yourtenant.sharepoint.com/sites/IconsOfIO`
   - Add all four lists: `IconsOfIO_nominations`, `IconsOfIO_categories`, `IconsOfIO_reviewers`, `IconsOfIO_reviews`

3. **Configure Office 365 Users connection** (if needed):
   - Add **Office 365 Users** connector
   - Use for user profile information

### Step 5: Test Applications

#### Nomination App Testing
1. Open the Nomination App
2. Test form submission with sample data
3. Verify data appears in SharePoint Nominations list
4. Test file upload functionality

#### Admin Dashboard Testing
1. Open Admin Dashboard
2. Verify nomination data displays correctly
3. Test scoring functionality
4. Test reviewer assignment
5. Test filtering and search

#### Reviewer Interface Testing
1. Assign test nominations to a reviewer
2. Open Reviewer Interface as that user
3. Test scoring and commenting
4. Verify status updates

#### Final Selection App Testing
1. Mark some nominations as "Shortlisted"
2. Open Final Selection App as leadership user
3. Test final decision functionality
4. Verify winner selection process

#### Reporting Dashboard Testing
1. Open Reporting Dashboard
2. Verify all metrics display correctly
3. Test export functionality
4. Verify charts and visualizations

## Post-Deployment Configuration

### 1. Configure Award Categories

1. Navigate to SharePoint site
2. Open **Categories** list
3. Add your award categories:
   ```
   Example categories:
   - Innovation Excellence
   - Leadership Impact
   - Team Collaboration
   - Customer Focus
   - Operational Excellence
   ```

### 2. Set Up Reviewers

1. Open **Reviewers** list
2. Add reviewer information:
   - Name, Email, Department
   - Specialization areas
   - Maximum assignments

### 3. Configure Notification Settings

1. **Set up Power Automate flows** (optional):
   - Nomination confirmation emails
   - Reviewer assignment notifications
   - Status update alerts
   - Final decision communications

### 4. Customize Branding

1. **Update app themes**:
   - Open each app in edit mode
   - Go to **Settings** > **Display**
   - Apply company colors and branding

2. **Add company logo**:
   - Upload logo to SharePoint site assets
   - Update image controls in apps

## Security Configuration

### Data Loss Prevention (DLP)

1. Navigate to [Power Platform Admin Center](https://admin.powerplatform.microsoft.com/)
2. Go to **Data policies** > **New policy**
3. Configure policy:
   - **Name**: `Icons of IO Awards - Data Protection`
   - **Scope**: Select your environment
   - **Connectors**: Allow only necessary connectors
     - SharePoint (Business)
     - Office 365 Users (Business)
     - Office 365 Outlook (Business)
     - Microsoft Teams (Business)

### Conditional Access (Optional)

1. Navigate to [Azure AD Admin Center](https://aad.portal.azure.com/)
2. Go to **Security** > **Conditional Access**
3. Create policy for Power Apps access:
   - Require MFA for external access
   - Block access from unmanaged devices
   - Restrict to corporate network (if needed)

## Monitoring and Maintenance

### 1. Set Up Monitoring

- **Power Platform Analytics**: Monitor app usage and performance
- **SharePoint Analytics**: Track list usage and storage
- **Microsoft 365 Audit Logs**: Monitor security events

### 2. Regular Maintenance Tasks

- **Weekly**: Review new nominations and assignments
- **Monthly**: Check system performance and usage
- **Quarterly**: Review and update security settings
- **Annually**: Archive old award cycles and prepare for new cycle

### 3. Backup Strategy

- **Power Apps**: Export apps regularly
- **SharePoint Data**: Use built-in versioning and recycle bin
- **Configuration**: Keep deployment scripts updated

## Troubleshooting

### Common Issues

#### Connection Errors
**Problem**: Apps can't connect to SharePoint
**Solution**: 
1. Verify SharePoint site permissions
2. Re-authenticate connections in Power Apps
3. Check if lists exist and have correct names

#### Permission Denied
**Problem**: Users can't access certain features
**Solution**:
1. Verify user is in correct SharePoint group
2. Check list-level permissions
3. Verify Power Apps sharing settings

#### Performance Issues
**Problem**: Apps load slowly or timeout
**Solution**:
1. Optimize data queries with filters
2. Implement data source delegation
3. Consider data archiving for large datasets

#### Data Not Syncing
**Problem**: Changes don't appear across apps
**Solution**:
1. Check SharePoint list permissions
2. Verify connection refresh settings
3. Clear Power Apps cache

### Support Contacts

- **Technical Issues**: IT Support Team
- **Process Questions**: Awards Committee
- **Access Requests**: SharePoint Administrators
- **Training**: Power Platform Center of Excellence

## Appendix

### A. File Structure
```
PowerApps-ICONS-JLR/
├── solution.xml
├── README.md
├── NominationApp/
│   ├── NominationForm.json
│   └── CanvasManifest.json
├── AdminDashboard/
│   ├── AdminDashboard.json
│   └── CanvasManifest.json
├── ReviewerInterface/
│   ├── ReviewerInterface.json
│   └── CanvasManifest.json
├── FinalSelectionApp/
│   ├── FinalSelectionApp.json
│   └── CanvasManifest.json
├── ReportingDashboard/
│   ├── ReportingDashboard.json
│   └── CanvasManifest.json
├── SharePoint/
│   ├── nominations-list-schema.json
│   ├── reviewers-list-schema.json
│   ├── categories-list-schema.json
│   └── deploy-sharepoint-lists.ps1
├── Security/
│   ├── security-roles.json
│   └── deploy-security.ps1
└── Documentation/
    └── DEPLOYMENT_GUIDE.md
```

### B. Required URLs
- **Power Apps Portal**: https://make.powerapps.com
- **Power Platform Admin**: https://admin.powerplatform.microsoft.com
- **SharePoint Admin**: https://admin.microsoft.com/sharepoint
- **Microsoft 365 Admin**: https://admin.microsoft.com

### C. PowerShell Command Reference

```powershell
# Connect to SharePoint
Connect-PnPOnline -Url "https://tenant.sharepoint.com/sites/site" -Interactive

# Connect to Power Apps
Add-PowerAppsAccount

# List environments
Get-PowerAppEnvironment

# List apps in environment
Get-PowerApp -EnvironmentName "environment-id"

# Export app
Export-PowerApp -AppName "app-id" -EnvironmentName "environment-id" -PackageDisplayName "App Name"
```

---

**Document Version**: 1.0  
**Last Updated**: January 2024  
**Next Review**: Quarterly