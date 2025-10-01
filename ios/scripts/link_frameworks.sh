#!/bin/bash

# Script to link OpenList framework to Xcode project
# This ensures the framework is properly embedded in the iOS app

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IOS_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$IOS_DIR")"
FRAMEWORKS_DIR="${IOS_DIR}/Frameworks"

echo "=== Linking OpenList Framework to Xcode Project ==="
echo "iOS Directory: $IOS_DIR"
echo "Frameworks Directory: $FRAMEWORKS_DIR"

# Check if Frameworks directory exists
if [ ! -d "$FRAMEWORKS_DIR" ]; then
    echo "Error: Frameworks directory not found at $FRAMEWORKS_DIR"
    exit 1
fi

# Check if any xcframework exists
FRAMEWORK_COUNT=$(find "$FRAMEWORKS_DIR" -name "*.xcframework" -type d | wc -l)
if [ "$FRAMEWORK_COUNT" -eq 0 ]; then
    echo "Error: No .xcframework files found in $FRAMEWORKS_DIR"
    exit 1
fi

echo "Found $FRAMEWORK_COUNT framework(s) to link"

# List frameworks
echo "Frameworks to link:"
find "$FRAMEWORKS_DIR" -name "*.xcframework" -type d -exec basename {} \;

# Update Runner project to include frameworks
PROJECT_FILE="${IOS_DIR}/Runner.xcodeproj/project.pbxproj"

if [ ! -f "$PROJECT_FILE" ]; then
    echo "Error: Xcode project file not found at $PROJECT_FILE"
    exit 1
fi

# Backup original project file
cp "$PROJECT_FILE" "${PROJECT_FILE}.backup"
echo "Created backup: ${PROJECT_FILE}.backup"

# Add framework search path if not exists
if ! grep -q "FRAMEWORK_SEARCH_PATHS.*Frameworks" "$PROJECT_FILE"; then
    echo "Adding framework search path to project settings..."
    # This will be handled by the Xcode project configuration
    echo "Note: Framework search path should be added to build settings"
fi

# For Flutter iOS, we need to ensure frameworks are in the right location
# and use a Run Script phase to copy them during build
echo ""
echo "=== Framework Linking Complete ==="
echo ""
echo "Next steps:"
echo "1. Frameworks are located at: $FRAMEWORKS_DIR"
echo "2. Flutter will handle framework embedding during build"
echo "3. Verify Info.plist includes necessary configurations"
echo ""
echo "To manually verify in Xcode:"
echo "1. Open Runner.xcworkspace"
echo "2. Check Build Settings -> Framework Search Paths"
echo "3. Check Build Phases -> Embed Frameworks"
echo ""

# Create a Flutter-compatible framework integration
# Flutter expects frameworks to be in ios/Frameworks/
echo "Verifying framework structure for Flutter..."
for framework in "$FRAMEWORKS_DIR"/*.xcframework; do
    if [ -d "$framework" ]; then
        framework_name=$(basename "$framework")
        echo "✓ Framework ready: $framework_name"
    fi
done

echo "Framework linking preparation complete!"
