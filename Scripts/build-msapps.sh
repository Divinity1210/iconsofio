#!/bin/bash

# Icons of IO Awards – Build Canvas .msapp files
# This script uses Power Platform CLI (pac) to pack each app source folder into an importable .msapp.
# It also bundles the outputs into a single ZIP for convenience.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")"/.. && pwd)"
BUILD_DIR="$ROOT_DIR/build"
mkdir -p "$BUILD_DIR"

APPS=(
  "NominationApp"
  "AdminDashboard"
  "ReviewerInterface"
  "FinalSelectionApp"
  "ReportingDashboard"
)

echo "🏗️  Building .msapp files for Icons of IO Awards"

# Resolve PAC CLI path with fallback to dotnet global tool
PAC_BIN=${PAC_BIN:-pac}
if ! command -v "$PAC_BIN" >/dev/null 2>&1; then
  DOTNET_PAC="$HOME/.dotnet/tools/pac"
  if [ -x "$DOTNET_PAC" ]; then
    PAC_BIN="$DOTNET_PAC"
    echo "ℹ️  Using PAC from dotnet global tools: $PAC_BIN"
  else
    echo "⚠️  Power Platform CLI (pac) not found in PATH or dotnet tools. Install with one of:"
    echo "   brew tap microsoft/pac && brew install microsoft/pac/pac"
    echo "   dotnet tool install -g Microsoft.PowerApps.CLI.Tool"
    exit 1
  fi
fi

# No authentication needed for local canvas pack, skipping auth checks

for app in "${APPS[@]}"; do
  src="$ROOT_DIR/build/${app}_src"
  out="$BUILD_DIR/${app}.msapp"
  if [ ! -d "$src" ]; then
    echo "❌ Missing app source folder: $src" && exit 1
  fi
  echo "📱 Packing $app from $src → $out"
  if ! "$PAC_BIN" canvas pack --msapp "$out" --sources "$src"; then
    echo "⚠️  Pack failed for $app. Attempting without Themes.json"
    if [ -f "$src/Themes.json" ]; then
      mv "$src/Themes.json" "$src/_Themes.disabled.json"
      if "$PAC_BIN" canvas pack --msapp "$out" --sources "$src"; then
        echo "✅ Packed $app without theme. Restoring Themes.json"
        mv "$src/_Themes.disabled.json" "$src/Themes.json"
      else
        echo "❌ Failed to pack $app even after disabling theme"
        # Restore original file before exiting
        [ -f "$src/_Themes.disabled.json" ] && mv "$src/_Themes.disabled.json" "$src/Themes.json"
        exit 1
      fi
    else
      echo "❌ No Themes.json present to disable. Please check source structure at $src"
      exit 1
    fi
  fi
done

ZIP_NAME="IconsOfIOAwards_MSApps_$(date +%Y%m%d).zip"
echo "🗜️  Creating bundle: $ZIP_NAME"
cd "$BUILD_DIR" && zip -r "$ZIP_NAME" *.msapp >/dev/null && cd "$ROOT_DIR"

echo "✅ Done. Outputs in: $BUILD_DIR"
echo "   Upload each .msapp via Power Apps Studio → Apps → Upload canvas app"
echo "   Or import via Solution using pac (see Solutions/build-solution-with-pac.sh)"
