#!/bin/bash

# Icons of IO Awards - Solution Package Creator
# Creates a deployable Power Platform solution package

echo "🏆 Icons of IO Awards - Solution Packager"
echo "==========================================="

# Set variables
SOLUTION_NAME="IconsOfIOAwardsSolution"
VERSION="1.0.0"
OUTPUT_DIR="../"
PACKAGE_NAME="${SOLUTION_NAME}_v${VERSION}_PowerPlatform.zip"
TEMP_DIR="/tmp/IconsOfIOSolution_$(date +%Y%m%d_%H%M%S)"

echo "📦 Creating solution package: $PACKAGE_NAME"

# Create temporary directory structure
mkdir -p "$TEMP_DIR/$SOLUTION_NAME"

# Copy all solution files
echo "📁 Copying solution files..."
cp -r ../AdminDashboard "$TEMP_DIR/$SOLUTION_NAME/"
cp -r ../NominationApp "$TEMP_DIR/$SOLUTION_NAME/"
cp -r ../ReviewerInterface "$TEMP_DIR/$SOLUTION_NAME/"
cp -r ../FinalSelectionApp "$TEMP_DIR/$SOLUTION_NAME/"
cp -r ../ReportingDashboard "$TEMP_DIR/$SOLUTION_NAME/"
cp -r ../SharePoint "$TEMP_DIR/$SOLUTION_NAME/"
cp -r ../Security "$TEMP_DIR/$SOLUTION_NAME/"
cp -r ../Documentation "$TEMP_DIR/$SOLUTION_NAME/"
cp ../README.md "$TEMP_DIR/$SOLUTION_NAME/"
cp ./solution.xml "$TEMP_DIR/$SOLUTION_NAME/"

# Create deployment instructions
echo "📋 Creating deployment instructions..."
cat > "$TEMP_DIR/DEPLOYMENT_INSTRUCTIONS.md" << 'EOF'
# Icons of IO Awards - Power Platform Solution

## 🚀 One-Click Deployment Options

### Option 1: Power Platform Admin Center (Recommended)

1. **Go to Power Platform Admin Center**
   - Navigate to: https://admin.powerplatform.microsoft.com
   - Select your target environment

2. **Import Solution**
   - Go to "Solutions" > "Import solution"
   - Click "Browse" and select this ZIP file
   - Click "Next" and follow the import wizard

3. **Configure Connections**
   - After import, configure SharePoint connections
   - Set up environment variables if prompted

### Option 2: PowerShell Deployment

```powershell
# Run these commands in PowerShell
cd IconsOfIOAwardsSolution
.\SharePoint\deploy-sharepoint-lists.ps1
.\Security\deploy-security.ps1
```

### Option 3: Manual Setup

1. **Import Each App Individually**
   - Go to https://make.powerapps.com
   - Select "Apps" > "Import canvas app"
   - Import each .json file from the app folders

2. **Set Up SharePoint Lists**
   - Run the PowerShell scripts in the SharePoint folder
   - Or manually create lists using the provided schemas

## 📱 Applications Included

- **NominationApp**: Public nomination submission form
- **AdminDashboard**: Administrative management interface
- **ReviewerInterface**: Reviewer workspace for scoring
- **FinalSelectionApp**: Leadership selection tool
- **ReportingDashboard**: Analytics and reporting

## 🔧 Post-Deployment Configuration

1. **Test All Applications**
   - Verify each app loads correctly
   - Test SharePoint connections
   - Validate user permissions

2. **Configure Categories**
   - Add your award categories to the SharePoint list
   - Customize scoring criteria as needed

3. **Set Up Users**
   - Assign security roles to users
   - Configure reviewer assignments

## 📚 Documentation

Refer to the Documentation folder for:
- Complete deployment guide
- User manual
- Troubleshooting tips

## 🆘 Support

If you encounter issues:
1. Check the troubleshooting section in the user manual
2. Verify all prerequisites are met
3. Ensure proper permissions in your environment

---
**Ready to transform your awards process!** 🎯
EOF

# Create automated deployment script
echo "🔧 Creating automated deployment script..."
cat > "$TEMP_DIR/Deploy-Solution.sh" << 'EOF'
#!/bin/bash

# Automated deployment script for Icons of IO Awards
echo "🚀 Starting Icons of IO Awards Solution Deployment..."

# Check if PowerShell is available
if command -v pwsh &> /dev/null; then
    echo "📋 Setting up SharePoint lists..."
    cd IconsOfIOAwardsSolution/SharePoint
    pwsh ./deploy-sharepoint-lists.ps1
    
    echo "🔒 Configuring security roles..."
    cd ../Security
    pwsh ./deploy-security.ps1
    
    echo "✅ Automated deployment completed!"
else
    echo "⚠️  PowerShell not found. Please run deployment scripts manually:"
    echo "   1. Run SharePoint/deploy-sharepoint-lists.ps1"
    echo "   2. Run Security/deploy-security.ps1"
fi

echo "📱 Next steps:"
echo "   1. Import Power Apps through Power Platform Admin Center"
echo "   2. Configure connections and test applications"
echo "   3. Train users with provided documentation"
EOF

chmod +x "$TEMP_DIR/Deploy-Solution.sh"

# Create the final ZIP package
echo "🗜️  Creating ZIP package..."
cd "$TEMP_DIR"
zip -r "$OUTPUT_DIR/$PACKAGE_NAME" . -x "*.DS_Store" "*/.git/*"

# Cleanup
rm -rf "$TEMP_DIR"

# Show results
echo ""
echo "✅ Solution package created successfully!"
echo "📦 Package: $OUTPUT_DIR/$PACKAGE_NAME"
echo "📏 Size: $(du -h "$OUTPUT_DIR/$PACKAGE_NAME" | cut -f1)"
echo ""
echo "🎯 Ready for deployment!"
echo "To deploy:"
echo "  1. Extract the ZIP file in your target environment"
echo "  2. Follow the DEPLOYMENT_INSTRUCTIONS.md"
echo "  3. Or run ./Deploy-Solution.sh for automated setup"
echo ""
echo "🚀 Transform your awards process with this enterprise-grade solution!"