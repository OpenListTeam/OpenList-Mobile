#!/bin/bash

# Script to ensure OpenList framework is properly integrated into iOS app
# This works by creating a podspec and using CocoaPods integration

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IOS_DIR="$(dirname "$SCRIPT_DIR")"
FRAMEWORKS_DIR="${IOS_DIR}/Frameworks"

echo "=== Integrating OpenList Framework ==="

# Check if Frameworks directory exists and has content
if [ ! -d "$FRAMEWORKS_DIR" ]; then
    echo "Error: Frameworks directory not found"
    exit 1
fi

FRAMEWORK_COUNT=$(find "$FRAMEWORKS_DIR" -name "*.xcframework" -maxdepth 1 -type d 2>/dev/null | wc -l)
if [ "$FRAMEWORK_COUNT" -eq 0 ]; then
    echo "Error: No xcframework found in $FRAMEWORKS_DIR"
    ls -la "$FRAMEWORKS_DIR" || echo "Cannot list directory"
    exit 1
fi

echo "Found $FRAMEWORK_COUNT framework(s)"

# Create Podfile if it doesn't exist
PODFILE="${IOS_DIR}/Podfile"

if [ ! -f "$PODFILE" ]; then
    echo "Error: Podfile not found. Flutter should have generated one."
    exit 1
fi

echo "Checking Podfile..."

# Check if Podfile already includes our framework configuration
if ! grep -q "# OpenList Framework Integration" "$PODFILE"; then
    echo "Adding OpenList framework configuration to Podfile..."
    
    # Create backup
    cp "$PODFILE" "${PODFILE}.backup"
    
    # Find the target 'Runner' do block and add framework configuration
    awk '
    BEGIN { in_runner = 0; added = 0 }
    /target .Runner. do/ { 
        in_runner = 1
        print
        next
    }
    in_runner && !added && /^[[:space:]]*end[[:space:]]*$/ {
        print "  # OpenList Framework Integration"
        print "  # Embed xcframeworks from Frameworks directory"
        print "  Dir.glob(File.join(File.dirname(__FILE__), '\''Frameworks'\'', '\''*.xcframework'\'')) do |framework|"
        print "    framework_name = File.basename(framework, '\''.xcframework'\'')"
        print "    puts \"Embedding framework: #{framework_name}\""
        print "  end"
        print ""
        added = 1
    }
    { print }
    ' "$PODFILE" > "${PODFILE}.tmp"
    
    mv "${PODFILE}.tmp" "$PODFILE"
    echo "✓ Podfile updated"
else
    echo "✓ Podfile already configured"
fi

# Create a post_install script to handle framework embedding
cat > "${IOS_DIR}/scripts/embed_frameworks.sh" << 'EMBED_SCRIPT'
#!/bin/bash
# Embed frameworks into app bundle

set -e

FRAMEWORKS_DIR="${BUILT_PRODUCTS_DIR}/${FRAMEWORKS_FOLDER_PATH}"
SOURCE_FRAMEWORKS="${SRCROOT}/Frameworks"

if [ ! -d "$SOURCE_FRAMEWORKS" ]; then
    echo "No frameworks to embed"
    exit 0
fi

echo "Embedding frameworks from $SOURCE_FRAMEWORKS"

for framework in "$SOURCE_FRAMEWORKS"/*.xcframework; do
    if [ ! -d "$framework" ]; then
        continue
    fi
    
    framework_name=$(basename "$framework" .xcframework)
    echo "Processing: $framework_name"
    
    # Find the appropriate framework slice for current architecture
    if [ "$PLATFORM_NAME" = "iphoneos" ]; then
        FRAMEWORK_PATH="$framework/ios-arm64"
    else
        FRAMEWORK_PATH="$framework/ios-arm64_x86_64-simulator"
    fi
    
    if [ ! -d "$FRAMEWORK_PATH" ]; then
        # Fallback: try to find any ios-* directory
        FRAMEWORK_PATH=$(find "$framework" -name "ios-*" -type d | head -n 1)
    fi
    
    if [ -d "$FRAMEWORK_PATH" ]; then
        echo "Copying from: $FRAMEWORK_PATH"
        cp -Rf "$FRAMEWORK_PATH/${framework_name}.framework" "$FRAMEWORKS_DIR/"
        
        # Code sign the framework
        codesign --force --sign "${EXPANDED_CODE_SIGN_IDENTITY}" --preserve-metadata=identifier,entitlements --timestamp=none "$FRAMEWORKS_DIR/${framework_name}.framework"
        echo "✓ Embedded and signed: $framework_name"
    else
        echo "Warning: Could not find framework binary in $framework"
    fi
done

echo "Framework embedding complete"
EMBED_SCRIPT

chmod +x "${IOS_DIR}/scripts/embed_frameworks.sh"
echo "✓ Created embed script"

echo ""
echo "=== Integration Complete ==="
echo ""
echo "The framework will be automatically embedded during build."
echo "Frameworks location: $FRAMEWORKS_DIR"
echo ""
