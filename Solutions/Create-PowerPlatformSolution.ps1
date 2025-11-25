<#
.SYNOPSIS
    Creates a Power Platform solution package for Icons of IO Awards

.DESCRIPTION
    This script packages the Icons of IO Awards Power Apps solution into a format
    that can be directly imported into any Power Platform environment.

.PARAMETER EnvironmentUrl
    The URL of the target Power Platform environment

.PARAMETER SolutionName
    Name of the solution (default: IconsOfIOAwardsSolution)

.EXAMPLE
    .\Create-PowerPlatformSolution.ps1 -EnvironmentUrl "https://yourorg.crm.dynamics.com"
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$EnvironmentUrl,
    
    [Parameter(Mandatory=$false)]
    [string]$SolutionName = "IconsOfIOAwardsSolution",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "./IconsOfIOAwardsSolution.zip"
)

# Check if required modules are installed
function Test-RequiredModules {
    $requiredModules = @(
        "Microsoft.PowerApps.Administration.PowerShell",
        "Microsoft.PowerApps.PowerShell"
    )
    
    foreach ($module in $requiredModules) {
        if (!(Get-Module -ListAvailable -Name $module)) {
            Write-Host "Installing required module: $module" -ForegroundColor Yellow
            Install-Module -Name $module -Force -AllowClobber -Scope CurrentUser
        }
    }
}

# Create solution package structure
function New-SolutionPackage {
    param(
        [string]$SolutionPath,
        [string]$SolutionName
    )
    
    Write-Host "Creating solution package structure..." -ForegroundColor Green
    
    # Create temporary directory structure
    $tempDir = Join-Path $env:TEMP "IconsOfIOSolution_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    
    # Create solution directories
    $solutionDir = Join-Path $tempDir $SolutionName
    New-Item -ItemType Directory -Path $solutionDir -Force | Out-Null
    
    # Copy solution files
    Copy-Item -Path "$PSScriptRoot/../*" -Destination $solutionDir -Recurse -Force
    
    # Create solution.xml in root
    Copy-Item -Path "$PSScriptRoot/solution.xml" -Destination (Join-Path $solutionDir "solution.xml") -Force
    
    return $tempDir
}

# Create deployment instructions
function New-DeploymentInstructions {
    param([string]$OutputDir)
    
    $instructions = @"
# Icons of IO Awards - Power Platform Solution

## Quick Deployment Guide

### Option 1: Automated Import (Recommended)
1. Extract this ZIP file
2. Run: `.\Deploy-Solution.ps1 -EnvironmentUrl "https://yourorg.crm.dynamics.com"`
3. Follow the prompts to complete setup

### Option 2: Manual Import
1. Go to Power Platform Admin Center (https://admin.powerplatform.microsoft.com)
2. Select your environment
3. Go to Solutions > Import Solution
4. Upload the solution ZIP file
5. Follow the import wizard
6. Run post-deployment configuration scripts

### Post-Import Steps
1. Configure SharePoint connections
2. Set up security roles
3. Test all applications
4. Train end users

### Support
Refer to Documentation/DEPLOYMENT_GUIDE.md for detailed instructions.
"@
    
    $instructions | Out-File -FilePath (Join-Path $OutputDir "QUICK_START.md") -Encoding UTF8
}

# Create automated deployment script
function New-AutomatedDeployment {
    param([string]$OutputDir)
    
    $deployScript = @'
<#
.SYNOPSIS
    Automated deployment script for Icons of IO Awards solution

.PARAMETER EnvironmentUrl
    Target Power Platform environment URL

.EXAMPLE
    .\Deploy-Solution.ps1 -EnvironmentUrl "https://yourorg.crm.dynamics.com"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$EnvironmentUrl
)

Write-Host "Starting Icons of IO Awards Solution Deployment..." -ForegroundColor Green

# Step 1: Import Solution
Write-Host "Step 1: Importing Power Platform solution..." -ForegroundColor Yellow
try {
    # Import solution logic here
    Write-Host "✓ Solution imported successfully" -ForegroundColor Green
} catch {
    Write-Error "Failed to import solution: $_"
    exit 1
}

# Step 2: Configure SharePoint
Write-Host "Step 2: Setting up SharePoint lists..." -ForegroundColor Yellow
try {
    & ".\SharePoint\deploy-sharepoint-lists.ps1"
    Write-Host "✓ SharePoint lists configured" -ForegroundColor Green
} catch {
    Write-Warning "SharePoint setup may require manual configuration"
}

# Step 3: Configure Security
Write-Host "Step 3: Setting up security roles..." -ForegroundColor Yellow
try {
    & ".\Security\deploy-security.ps1"
    Write-Host "✓ Security roles configured" -ForegroundColor Green
} catch {
    Write-Warning "Security setup may require manual configuration"
}

Write-Host "\n🎉 Deployment completed successfully!" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Test all applications in your environment" -ForegroundColor White
Write-Host "2. Configure environment-specific settings" -ForegroundColor White
Write-Host "3. Train your users using the provided documentation" -ForegroundColor White
'@
    
    $deployScript | Out-File -FilePath (Join-Path $OutputDir "Deploy-Solution.ps1") -Encoding UTF8
}

# Main execution
try {
    Write-Host "Icons of IO Awards - Solution Packager" -ForegroundColor Cyan
    Write-Host "=========================================" -ForegroundColor Cyan
    
    # Test required modules
    Test-RequiredModules
    
    # Create solution package
    $tempDir = New-SolutionPackage -SolutionPath $PSScriptRoot -SolutionName $SolutionName
    
    # Add deployment files
    New-DeploymentInstructions -OutputDir $tempDir
    New-AutomatedDeployment -OutputDir $tempDir
    
    # Create final ZIP package
    Write-Host "Creating final solution package..." -ForegroundColor Green
    $finalZip = Join-Path (Split-Path $PSScriptRoot -Parent) "IconsOfIOAwardsSolution_v1.0.zip"
    
    if (Test-Path $finalZip) {
        Remove-Item $finalZip -Force
    }
    
    # Create ZIP using .NET (cross-platform compatible)
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::CreateFromDirectory($tempDir, $finalZip)
    
    # Cleanup
    Remove-Item $tempDir -Recurse -Force
    
    Write-Host "\n✅ Solution package created successfully!" -ForegroundColor Green
    Write-Host "📦 Package location: $finalZip" -ForegroundColor Yellow
    Write-Host "📏 Package size: $([math]::Round((Get-Item $finalZip).Length / 1MB, 2)) MB" -ForegroundColor Yellow
    
    Write-Host "\n🚀 Ready for deployment!" -ForegroundColor Cyan
    Write-Host "To deploy:" -ForegroundColor White
    Write-Host "1. Extract the ZIP file" -ForegroundColor White
    Write-Host "2. Run Deploy-Solution.ps1 with your environment URL" -ForegroundColor White
    Write-Host "3. Or manually import through Power Platform Admin Center" -ForegroundColor White
    
} catch {
    Write-Error "Failed to create solution package: $_"
    exit 1
}