#!/bin/bash

# Simple and reliable framework embedding script
# This script is called during Xcode build phase to copy frameworks

set -e

echo "=== OpenList Framework Embedding Script ==="
echo "Configuration: ${CONFIGURATION}"
echo "Platform: ${PLATFORM_NAME}"
echo "Built Products: ${BUILT_PRODUCTS_DIR}"
echo "Source Root: ${SRCROOT}"

# Source frameworks directory
FRAMEWORKS_SRC="${SRCROOT}/Frameworks"

# Destination in app bundle
FRAMEWORKS_DEST="${BUILT_PRODUCTS_DIR}/${FRAMEWORKS_FOLDER_PATH}"

if [ ! -d "$FRAMEWORKS_SRC" ]; then
    echo "No Frameworks directory found at: $FRAMEWORKS_SRC"
    exit 0
fi

echo "Source: $FRAMEWORKS_SRC"
echo "Destination: $FRAMEWORKS_DEST"

# Ensure destination exists
mkdir -p "$FRAMEWORKS_DEST"

# Process each xcframework
for XCFRAMEWORK in "$FRAMEWORKS_SRC"/*.xcframework; do
    if [ ! -d "$XCFRAMEWORK" ]; then
        continue
    fi
    
    XCFRAMEWORK_NAME=$(basename "$XCFRAMEWORK")
    FRAMEWORK_NAME="${XCFRAMEWORK_NAME%.xcframework}"
    
    echo ""
    echo "Processing: $XCFRAMEWORK_NAME"
    
    # Determine which slice to use based on platform and architecture
    FRAMEWORK_SLICE=""
    
    if [ "$PLATFORM_NAME" = "iphoneos" ]; then
        # Device build - use arm64
        FRAMEWORK_SLICE="$XCFRAMEWORK/ios-arm64/${FRAMEWORK_NAME}.framework"
        echo "  Using device slice: ios-arm64"
    elif [ "$PLATFORM_NAME" = "iphonesimulator" ]; then
        # Simulator build - use simulator slice
        if [ -d "$XCFRAMEWORK/ios-arm64_x86_64-simulator" ]; then
            FRAMEWORK_SLICE="$XCFRAMEWORK/ios-arm64_x86_64-simulator/${FRAMEWORK_NAME}.framework"
            echo "  Using simulator slice: ios-arm64_x86_64-simulator"
        elif [ -d "$XCFRAMEWORK/ios-x86_64-simulator" ]; then
            FRAMEWORK_SLICE="$XCFRAMEWORK/ios-x86_64-simulator/${FRAMEWORK_NAME}.framework"
            echo "  Using simulator slice: ios-x86_64-simulator"
        elif [ -d "$XCFRAMEWORK/ios-arm64-simulator" ]; then
            FRAMEWORK_SLICE="$XCFRAMEWORK/ios-arm64-simulator/${FRAMEWORK_NAME}.framework"
            echo "  Using simulator slice: ios-arm64-simulator"
        fi
    fi
    
    # Fallback: try to find any slice
    if [ -z "$FRAMEWORK_SLICE" ] || [ ! -d "$FRAMEWORK_SLICE" ]; then
        echo "  Searching for available slices..."
        FRAMEWORK_SLICE=$(find "$XCFRAMEWORK" -name "${FRAMEWORK_NAME}.framework" -type d | head -n 1)
        if [ -n "$FRAMEWORK_SLICE" ]; then
            echo "  Found: $(dirname "$FRAMEWORK_SLICE" | xargs basename)"
        fi
    fi
    
    if [ -z "$FRAMEWORK_SLICE" ] || [ ! -d "$FRAMEWORK_SLICE" ]; then
        echo "  ⚠️  Warning: Could not find framework binary in $XCFRAMEWORK_NAME"
        continue
    fi
    
    # Copy framework to destination
    echo "  Copying framework..."
    rsync -av --delete "$FRAMEWORK_SLICE" "$FRAMEWORKS_DEST/" || {
        echo "  ⚠️  Warning: Failed to copy framework"
        continue
    }
    
    DEST_FRAMEWORK="$FRAMEWORKS_DEST/${FRAMEWORK_NAME}.framework"
    
    # Strip invalid architectures if needed
    FRAMEWORK_BINARY="$DEST_FRAMEWORK/${FRAMEWORK_NAME}"
    
    if [ -f "$FRAMEWORK_BINARY" ]; then
        echo "  Framework binary: $FRAMEWORK_BINARY"
        
        # Check architectures
        ARCHS=$(lipo -info "$FRAMEWORK_BINARY" 2>/dev/null | sed 's/.*are: //' || echo "unknown")
        echo "  Architectures: $ARCHS"
        
        # Code sign the framework if signing identity is available
        if [ -n "${EXPANDED_CODE_SIGN_IDENTITY}" ] && [ "${EXPANDED_CODE_SIGN_IDENTITY}" != "-" ]; then
            echo "  Code signing with: ${EXPANDED_CODE_SIGN_IDENTITY}"
            /usr/bin/codesign --force --sign "${EXPANDED_CODE_SIGN_IDENTITY}" \
                --preserve-metadata=identifier,entitlements \
                --timestamp=none \
                "$DEST_FRAMEWORK" || {
                echo "  ⚠️  Warning: Code signing failed"
            }
        else
            echo "  Skipping code signing (no identity)"
        fi
        
        echo "  ✅ Successfully embedded: $FRAMEWORK_NAME"
    else
        echo "  ⚠️  Warning: Framework binary not found at $FRAMEWORK_BINARY"
    fi
done

echo ""
echo "=== Framework Embedding Complete ==="
