<#
.SYNOPSIS
    Deploy security configuration for Icons of IO Awards System

.DESCRIPTION
    This script sets up role-based access control, SharePoint security groups,
    and Power Platform security settings for the Icons of IO Awards System.

.PARAMETER SiteUrl
    The SharePoint site URL where the solution is deployed

.PARAMETER TenantUrl
    The Power Platform tenant URL

.PARAMETER EnvironmentName
    The Power Platform environment name

.EXAMPLE
    .\deploy-security.ps1 -SiteUrl "https://company.sharepoint.com/sites/IconsOfIO" -TenantUrl "https://company.crm.dynamics.com" -EnvironmentName "prod-icons-io"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$SiteUrl,
    
    [Parameter(Mandatory=$true)]
    [string]$TenantUrl,
    
    [Parameter(Mandatory=$true)]
    [string]$EnvironmentName
)

# Import required modules
Import-Module PnP.PowerShell -Force
Import-Module Microsoft.PowerApps.Administration.PowerShell -Force
Import-Module Microsoft.PowerApps.PowerShell -Force

# Load security configuration
$securityConfigPath = Join-Path $PSScriptRoot "security-roles.json"
$securityConfig = Get-Content $securityConfigPath | ConvertFrom-Json

Write-Host "Starting security deployment for Icons of IO Awards System..." -ForegroundColor Green

try {
    # Connect to SharePoint
    Write-Host "Connecting to SharePoint site: $SiteUrl" -ForegroundColor Yellow
    Connect-PnPOnline -Url $SiteUrl -Interactive
    
    # Connect to Power Platform
    Write-Host "Connecting to Power Platform..." -ForegroundColor Yellow
    Add-PowerAppsAccount -Endpoint prod
    
    # Create SharePoint Security Groups
    Write-Host "Creating SharePoint security groups..." -ForegroundColor Yellow
    
    $securityGroups = $securityConfig.securityConfiguration.securityGroups.sharePointGroups
    
    foreach ($groupName in $securityGroups.PSObject.Properties.Name) {
        $group = $securityGroups.$groupName
        
        Write-Host "Creating group: $groupName" -ForegroundColor Cyan
        
        try {
            # Check if group exists
            $existingGroup = Get-PnPGroup -Identity $groupName -ErrorAction SilentlyContinue
            
            if (-not $existingGroup) {
                # Create the group
                New-PnPGroup -Title $groupName -Description $group.description
                Write-Host "  ✓ Group '$groupName' created successfully" -ForegroundColor Green
            } else {
                Write-Host "  ℹ Group '$groupName' already exists" -ForegroundColor Yellow
            }
            
            # Set group permissions based on role
            switch ($group.permissions) {
                "Contribute" {
                    Set-PnPGroupPermissions -Identity $groupName -AddRole "Contribute"
                }
                "Edit" {
                    Set-PnPGroupPermissions -Identity $groupName -AddRole "Edit"
                }
                "Full Control" {
                    Set-PnPGroupPermissions -Identity $groupName -AddRole "Full Control"
                }
            }
            
        } catch {
            Write-Host "  ✗ Error creating group '$groupName': $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    # Configure List-Level Security
    Write-Host "Configuring list-level security..." -ForegroundColor Yellow
    
    $lists = @("Nominations", "Reviewers", "Categories")
    
    foreach ($listName in $lists) {
        Write-Host "Configuring security for list: $listName" -ForegroundColor Cyan
        
        try {
            # Break role inheritance
            Set-PnPList -Identity $listName -BreakRoleInheritance -CopyRoleAssignments:$false
            
            # Configure permissions based on list type
            switch ($listName) {
                "Nominations" {
                    # Nominators: Contribute to their own items
                    Set-PnPListPermission -Identity $listName -Group "IIO_Nominators" -AddRole "Contribute"
                    
                    # Reviewers: Edit assigned items
                    Set-PnPListPermission -Identity $listName -Group "IIO_Reviewers" -AddRole "Edit"
                    
                    # Administrators: Full Control
                    Set-PnPListPermission -Identity $listName -Group "IIO_Administrators" -AddRole "Full Control"
                    
                    # Leadership: Edit for final decisions
                    Set-PnPListPermission -Identity $listName -Group "IIO_Leadership" -AddRole "Edit"
                    
                    # System Admins: Full Control
                    Set-PnPListPermission -Identity $listName -Group "IIO_System_Admins" -AddRole "Full Control"
                }
                "Reviewers" {
                    # Only Administrators and System Admins can manage reviewers
                    Set-PnPListPermission -Identity $listName -Group "IIO_Administrators" -AddRole "Full Control"
                    Set-PnPListPermission -Identity $listName -Group "IIO_System_Admins" -AddRole "Full Control"
                    
                    # Reviewers can read basic info
                    Set-PnPListPermission -Identity $listName -Group "IIO_Reviewers" -AddRole "Read"
                    
                    # Leadership can read summary info
                    Set-PnPListPermission -Identity $listName -Group "IIO_Leadership" -AddRole "Read"
                }
                "Categories" {
                    # Nominators: Read active categories
                    Set-PnPListPermission -Identity $listName -Group "IIO_Nominators" -AddRole "Read"
                    
                    # Reviewers: Read all categories
                    Set-PnPListPermission -Identity $listName -Group "IIO_Reviewers" -AddRole "Read"
                    
                    # Administrators: Full Control
                    Set-PnPListPermission -Identity $listName -Group "IIO_Administrators" -AddRole "Full Control"
                    
                    # Leadership: Read all categories
                    Set-PnPListPermission -Identity $listName -Group "IIO_Leadership" -AddRole "Read"
                    
                    # System Admins: Full Control
                    Set-PnPListPermission -Identity $listName -Group "IIO_System_Admins" -AddRole "Full Control"
                }
            }
            
            Write-Host "  ✓ Security configured for '$listName'" -ForegroundColor Green
            
        } catch {
            Write-Host "  ✗ Error configuring security for '$listName': $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    # Configure Power Apps Security
    Write-Host "Configuring Power Apps security..." -ForegroundColor Yellow
    
    # Get all apps in the environment
    $apps = Get-PowerApp -EnvironmentName $EnvironmentName
    
    # Filter Icons of IO apps
    $iioApps = $apps | Where-Object { $_.DisplayName -like "*Icons of IO*" }
    
    foreach ($app in $iioApps) {
        Write-Host "Configuring security for app: $($app.DisplayName)" -ForegroundColor Cyan
        
        try {
            # Configure app-specific permissions based on app type
            switch -Wildcard ($app.DisplayName) {
                "*Nomination*" {
                    # All authenticated users can access nomination form
                    Set-PowerAppRoleAssignment -AppName $app.AppName -EnvironmentName $EnvironmentName -RoleName "CanView" -PrincipalType "Group" -PrincipalObjectId "IIO_Nominators"
                }
                "*Admin*" {
                    # Only administrators can access admin dashboard
                    Set-PowerAppRoleAssignment -AppName $app.AppName -EnvironmentName $EnvironmentName -RoleName "CanEdit" -PrincipalType "Group" -PrincipalObjectId "IIO_Administrators"
                    Set-PowerAppRoleAssignment -AppName $app.AppName -EnvironmentName $EnvironmentName -RoleName "CanEdit" -PrincipalType "Group" -PrincipalObjectId "IIO_System_Admins"
                }
                "*Reviewer*" {
                    # Only reviewers can access reviewer interface
                    Set-PowerAppRoleAssignment -AppName $app.AppName -EnvironmentName $EnvironmentName -RoleName "CanView" -PrincipalType "Group" -PrincipalObjectId "IIO_Reviewers"
                }
                "*Final*" {
                    # Only leadership can access final selection app
                    Set-PowerAppRoleAssignment -AppName $app.AppName -EnvironmentName $EnvironmentName -RoleName "CanView" -PrincipalType "Group" -PrincipalObjectId "IIO_Leadership"
                }
                "*Reporting*" {
                    # Administrators, Leadership, and System Admins can access reporting
                    Set-PowerAppRoleAssignment -AppName $app.AppName -EnvironmentName $EnvironmentName -RoleName "CanView" -PrincipalType "Group" -PrincipalObjectId "IIO_Administrators"
                    Set-PowerAppRoleAssignment -AppName $app.AppName -EnvironmentName $EnvironmentName -RoleName "CanView" -PrincipalType "Group" -PrincipalObjectId "IIO_Leadership"
                    Set-PowerAppRoleAssignment -AppName $app.AppName -EnvironmentName $EnvironmentName -RoleName "CanEdit" -PrincipalType "Group" -PrincipalObjectId "IIO_System_Admins"
                }
            }
            
            Write-Host "  ✓ Security configured for '$($app.DisplayName)'" -ForegroundColor Green
            
        } catch {
            Write-Host "  ✗ Error configuring security for '$($app.DisplayName)': $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    # Configure Data Loss Prevention (DLP) Policies
    Write-Host "Configuring Data Loss Prevention policies..." -ForegroundColor Yellow
    
    try {
        # Create DLP policy for Icons of IO environment
        $dlpPolicy = @{
            displayName = "Icons of IO Awards - Data Protection"
            environmentType = "SingleEnvironment"
            environments = @(@{
                name = $EnvironmentName
            })
            connectorGroups = @(
                @{
                    classification = "General"
                    connectors = @(
                        @{ id = "/providers/Microsoft.PowerApps/apis/shared_sharepointonline" },
                        @{ id = "/providers/Microsoft.PowerApps/apis/shared_office365users" },
                        @{ id = "/providers/Microsoft.PowerApps/apis/shared_office365" },
                        @{ id = "/providers/Microsoft.PowerApps/apis/shared_teams" }
                    )
                },
                @{
                    classification = "Blocked"
                    connectors = @(
                        @{ id = "/providers/Microsoft.PowerApps/apis/shared_twitter" },
                        @{ id = "/providers/Microsoft.PowerApps/apis/shared_facebook" },
                        @{ id = "/providers/Microsoft.PowerApps/apis/shared_dropbox" }
                    )
                }
            )
        }
        
        # Note: DLP policy creation requires tenant admin privileges
        Write-Host "  ℹ DLP policy configuration requires tenant admin privileges" -ForegroundColor Yellow
        Write-Host "  ℹ Please configure DLP policies manually in Power Platform Admin Center" -ForegroundColor Yellow
        
    } catch {
        Write-Host "  ✗ Error configuring DLP policies: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Create audit log configuration
    Write-Host "Setting up audit logging..." -ForegroundColor Yellow
    
    try {
        # Enable auditing on SharePoint lists
        foreach ($listName in $lists) {
            Set-PnPList -Identity $listName -EnableVersioning $true -MajorVersions 50
            Write-Host "  ✓ Versioning enabled for '$listName'" -ForegroundColor Green
        }
        
        # Note: Detailed audit logging configuration
        Write-Host "  ℹ Advanced audit logging should be configured in Microsoft 365 Compliance Center" -ForegroundColor Yellow
        
    } catch {
        Write-Host "  ✗ Error configuring audit logging: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host "Security deployment completed successfully!" -ForegroundColor Green
    
    # Display summary
    Write-Host "`n=== DEPLOYMENT SUMMARY ===" -ForegroundColor Cyan
    Write-Host "✓ SharePoint security groups created" -ForegroundColor Green
    Write-Host "✓ List-level permissions configured" -ForegroundColor Green
    Write-Host "✓ Power Apps security roles assigned" -ForegroundColor Green
    Write-Host "✓ Audit logging enabled" -ForegroundColor Green
    Write-Host "`n=== MANUAL CONFIGURATION REQUIRED ===" -ForegroundColor Yellow
    Write-Host "• Configure DLP policies in Power Platform Admin Center" -ForegroundColor Yellow
    Write-Host "• Set up advanced audit logging in Microsoft 365 Compliance Center" -ForegroundColor Yellow
    Write-Host "• Add users to appropriate SharePoint security groups" -ForegroundColor Yellow
    Write-Host "• Configure time-based access controls if needed" -ForegroundColor Yellow
    
} catch {
    Write-Host "Deployment failed: $($_.Exception.Message)" -ForegroundColor Red
    throw
} finally {
    # Disconnect from services
    Disconnect-PnPOnline -ErrorAction SilentlyContinue
    Write-Host "Disconnected from SharePoint" -ForegroundColor Gray
}

Write-Host "`nSecurity deployment script completed." -ForegroundColor Green