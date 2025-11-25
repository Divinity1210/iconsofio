# PowerShell script to create SharePoint lists for Icons of IO Awards system
# Run this script in SharePoint Online Management Shell or PnP PowerShell

param(
    [Parameter(Mandatory=$true)]
    [string]$SiteUrl,
    
    [Parameter(Mandatory=$false)]
    [string]$ListPrefix = "IconsOfIO_"
)

# Connect to SharePoint site
Write-Host "Connecting to SharePoint site: $SiteUrl" -ForegroundColor Green
Connect-PnPOnline -Url $SiteUrl -Interactive

# Function to create list from JSON schema
function Create-ListFromSchema {
    param(
        [string]$SchemaPath,
        [string]$ListPrefix
    )
    
    $schema = Get-Content $SchemaPath | ConvertFrom-Json
    $listName = $ListPrefix + $schema.listName.Replace("IconsOfIO_", "")
    
    Write-Host "Creating list: $listName" -ForegroundColor Yellow
    
    # Create the list
    try {
        $list = New-PnPList -Title $listName -Template GenericList -Description $schema.description
        Write-Host "List '$listName' created successfully" -ForegroundColor Green
        
        # Add custom fields
        foreach ($field in $schema.fields) {
            if ($field.name -ne "Title") {
                Write-Host "Adding field: $($field.name)" -ForegroundColor Cyan
                
                switch ($field.type) {
                    "Text" {
                        Add-PnPField -List $listName -DisplayName $field.name -InternalName $field.name -Type Text -Required:$field.required
                    }
                    "Note" {
                        Add-PnPField -List $listName -DisplayName $field.name -InternalName $field.name -Type Note -Required:$field.required
                    }
                    "Choice" {
                        $choices = $field.choices -join ","
                        Add-PnPField -List $listName -DisplayName $field.name -InternalName $field.name -Type Choice -Choices $field.choices -Required:$field.required
                    }
                    "MultiChoice" {
                        Add-PnPField -List $listName -DisplayName $field.name -InternalName $field.name -Type MultiChoice -Choices $field.choices -Required:$field.required
                    }
                    "Number" {
                        Add-PnPField -List $listName -DisplayName $field.name -InternalName $field.name -Type Number -Required:$field.required
                    }
                    "DateTime" {
                        Add-PnPField -List $listName -DisplayName $field.name -InternalName $field.name -Type DateTime -Required:$field.required
                    }
                    "Boolean" {
                        Add-PnPField -List $listName -DisplayName $field.name -InternalName $field.name -Type Boolean -Required:$field.required
                    }
                    "Person" {
                        Add-PnPField -List $listName -DisplayName $field.name -InternalName $field.name -Type User -Required:$field.required
                    }
                    "Lookup" {
                        # Lookup to another list; the schema should provide base list name without prefix
                        $targetBase = $field.lookupList
                        $targetList = $ListPrefix + $targetBase
                        Add-PnPField -List $listName -DisplayName $field.name -InternalName $field.name -Type Lookup -LookupList $targetList -LookupField "Title" -Required:$field.required
                    }
                    "Attachments" {
                        # Attachments are enabled by default, just ensure it's enabled
                        Set-PnPList -Identity $listName -EnableAttachments $true
                    }
                }
            }
        }
        
        # Create custom views if defined
        if ($schema.views) {
            foreach ($view in $schema.views) {
                Write-Host "Creating view: $($view.name)" -ForegroundColor Cyan
                $viewFields = $view.fields -join ","
                
                if ($view.filter) {
                    Add-PnPView -List $listName -Title $view.name -Fields $view.fields -Query "<Where>$($view.filter)</Where>"
                } else {
                    Add-PnPView -List $listName -Title $view.name -Fields $view.fields
                }
            }
        }
        
        # Add default data if specified
        if ($schema.defaultData) {
            Write-Host "Adding default data to $listName" -ForegroundColor Cyan
            foreach ($item in $schema.defaultData) {
                Add-PnPListItem -List $listName -Values $item
            }
        }
        
    } catch {
        Write-Host "Error creating list '$listName': $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Create all lists
Write-Host "Starting SharePoint list creation process..." -ForegroundColor Green

# Get current script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Create lists from schemas
Create-ListFromSchema -SchemaPath "$scriptDir\nominations-list-schema.json" -ListPrefix $ListPrefix
Create-ListFromSchema -SchemaPath "$scriptDir\reviewers-list-schema.json" -ListPrefix $ListPrefix
Create-ListFromSchema -SchemaPath "$scriptDir\categories-list-schema.json" -ListPrefix $ListPrefix
Create-ListFromSchema -SchemaPath "$scriptDir\reviews-list-schema.json" -ListPrefix $ListPrefix

Write-Host "SharePoint list creation completed!" -ForegroundColor Green
Write-Host "Please verify the lists have been created correctly in your SharePoint site." -ForegroundColor Yellow

# Disconnect
Disconnect-PnPOnline

Write-Host "Deployment script completed. Next steps:" -ForegroundColor Green
Write-Host "1. Verify all lists are created correctly" -ForegroundColor White
Write-Host "2. Configure list permissions as needed" -ForegroundColor White
Write-Host "3. Import the Power Apps solution" -ForegroundColor White
Write-Host "4. Update connection references in Power Apps" -ForegroundColor White