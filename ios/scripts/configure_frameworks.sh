#!/bin/bash

# Configure iOS project to link xcframework
# This script should be run after xcframework is generated

set -e

echo "Configuring iOS project to link OpenList xcframework..."

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
IOS_DIR="$(dirname "$SCRIPT_DIR")"
FRAMEWORKS_DIR="$IOS_DIR/Frameworks"

echo "iOS directory: $IOS_DIR"
echo "Frameworks directory: $FRAMEWORKS_DIR"

# Check if Frameworks directory exists
if [ ! -d "$FRAMEWORKS_DIR" ]; then
    echo "Error: Frameworks directory not found at $FRAMEWORKS_DIR"
    exit 1
fi

# Find xcframework
XCFRAMEWORK=$(find "$FRAMEWORKS_DIR" -name "*.xcframework" -type d | head -n 1)

if [ -z "$XCFRAMEWORK" ]; then
    echo "Error: No xcframework found in $FRAMEWORKS_DIR"
    exit 1
fi

echo "Found xcframework: $XCFRAMEWORK"
FRAMEWORK_NAME=$(basename "$XCFRAMEWORK")
echo "Framework name: $FRAMEWORK_NAME"

# Configure Flutter Generated.xcconfig
GENERATED_CONFIG="$IOS_DIR/Flutter/Generated.xcconfig"

if [ ! -f "$GENERATED_CONFIG" ]; then
    echo "Warning: Generated.xcconfig not found, creating it..."
    mkdir -p "$IOS_DIR/Flutter"
    touch "$GENERATED_CONFIG"
fi

# Check if FRAMEWORK_SEARCH_PATHS already exists in the file
if grep -q "FRAMEWORK_SEARCH_PATHS" "$GENERATED_CONFIG"; then
    echo "FRAMEWORK_SEARCH_PATHS already configured in Generated.xcconfig"
else
    echo "Adding FRAMEWORK_SEARCH_PATHS to Generated.xcconfig..."
    echo "" >> "$GENERATED_CONFIG"
    echo "// OpenList Framework Search Paths" >> "$GENERATED_CONFIG"
    echo "FRAMEWORK_SEARCH_PATHS = \$(inherited) \$(PROJECT_DIR)/Frameworks" >> "$GENERATED_CONFIG"
fi

# Also add to Debug and Release configs
for config_file in "$IOS_DIR/Flutter/Debug.xcconfig" "$IOS_DIR/Flutter/Release.xcconfig"; do
    if [ -f "$config_file" ]; then
        if ! grep -q "FRAMEWORK_SEARCH_PATHS" "$config_file"; then
            echo "Adding FRAMEWORK_SEARCH_PATHS to $(basename $config_file)..."
            echo "" >> "$config_file"
            echo "// OpenList Framework Search Paths" >> "$config_file"
            echo "FRAMEWORK_SEARCH_PATHS = \$(inherited) \$(PROJECT_DIR)/Frameworks" >> "$config_file"
        fi
    fi
done

# Add OTHER_LDFLAGS to link the framework
if ! grep -q "OTHER_LDFLAGS.*framework.*${FRAMEWORK_NAME%.xcframework}" "$GENERATED_CONFIG"; then
    echo "Adding framework linking flags..."
    echo "OTHER_LDFLAGS = \$(inherited) -framework ${FRAMEWORK_NAME%.xcframework}" >> "$GENERATED_CONFIG"
fi

echo "✅ iOS project configuration completed"
echo ""
echo "Configuration summary:"
echo "  - Framework search path added: \$(PROJECT_DIR)/Frameworks"
echo "  - Framework to link: ${FRAMEWORK_NAME%.xcframework}"
echo ""
echo "If you encounter linking issues, you may need to manually add the framework in Xcode:"
echo "  1. Open Runner.xcworkspace in Xcode"
echo "  2. Select Runner target > General > Frameworks, Libraries, and Embedded Content"
echo "  3. Add the xcframework from ios/Frameworks directory"
echo "  4. Set 'Embed & Sign' for the framework"

