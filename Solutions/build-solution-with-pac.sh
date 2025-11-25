#!/bin/bash

# Icons of IO Awards – Build & Export Solution via PAC CLI
# Creates an unmanaged solution containing the five canvas apps for import via Solutions.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")"/.. && pwd)"
SOLUTION_NAME="IconsOfIOAwards"
DISPLAY_NAME="Icons of IO Awards"
PUBLISHER_NAME="IconsOfIOPublisher"
PUBLISHER_PREFIX="iio"
VERSION="1.0.0"
EXPORT_PATH="$ROOT_DIR/build/${SOLUTION_NAME}_v${VERSION}.zip"

echo "🏗️  Building Power Platform Solution: $SOLUTION_NAME"

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
    echo "   dotnet tool install -g Microsoft.PowerApps.CLI"
    exit 1
  fi
fi

echo "🔐 Checking authentication..."
if ! "$PAC_BIN" auth list >/dev/null 2>&1; then
  "$PAC_BIN" auth create --url https://make.powerapps.com
fi

echo "📦 Creating solution shell (unmanaged)"
# Create solution if it doesn't exist
if ! "$PAC_BIN" solution list | grep -q "$SOLUTION_NAME"; then
  "$PAC_BIN" solution create --name "$SOLUTION_NAME" --publisherName "$PUBLISHER_NAME" \
    --publisherPrefix "$PUBLISHER_PREFIX" --displayName "$DISPLAY_NAME"
fi

echo "📥 Adding canvas apps to solution"
APPS=(
  "NominationApp"
  "AdminDashboard"
  "ReviewerInterface"
  "FinalSelectionApp"
  "ReportingDashboard"
)

for app in "${APPS[@]}"; do
  src="$ROOT_DIR/build/${app}_src"
  if [ ! -d "$src" ]; then
    echo "❌ Missing app source folder: $src" && exit 1
  fi
  echo "➕ Adding $app from $src"
  if ! "$PAC_BIN" solution add-canvas-app --path "$src" --solutionUniqueName "$SOLUTION_NAME"; then
    echo "⚠️  add-canvas-app failed for $app. Attempting without Themes.json"
    if [ -f "$src/Themes.json" ]; then
      mv "$src/Themes.json" "$src/_Themes.disabled.json"
      if "$PAC_BIN" solution add-canvas-app --path "$src" --solutionUniqueName "$SOLUTION_NAME"; then
        echo "✅ Added $app without theme. Restoring Themes.json"
        mv "$src/_Themes.disabled.json" "$src/Themes.json"
      else
        echo "❌ Failed to add $app even after disabling theme"
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

echo "📤 Exporting solution to: $EXPORT_PATH"
mkdir -p "$ROOT_DIR/build"
"$PAC_BIN" solution export --path "$EXPORT_PATH" --name "$SOLUTION_NAME" --managed false --includeCanvasApps true

echo "✅ Solution exported. Import via Power Platform Admin Center → Solutions → Import"
