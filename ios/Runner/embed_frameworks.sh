#!/bin/sh
# Embed xcframework script for iOS build
# This script is called during Xcode build to embed OpenList xcframework

set -e

echo "🔧 Embedding OpenList xcframework..."

FRAMEWORKS_DIR="${SRCROOT}/Frameworks"
BUILT_PRODUCTS_DIR="${BUILT_PRODUCTS_DIR}"
FRAMEWORKS_FOLDER_PATH="${FRAMEWORKS_FOLDER_PATH}"

if [ ! -d "$FRAMEWORKS_DIR" ]; then
    echo "⚠️  Frameworks directory not found at $FRAMEWORKS_DIR"
    exit 0
fi

# Find and embed all xcframeworks
for FRAMEWORK_PATH in "$FRAMEWORKS_DIR"/*.xcframework; do
    if [ -d "$FRAMEWORK_PATH" ]; then
        FRAMEWORK_NAME=$(basename "$FRAMEWORK_PATH")
        echo "📦 Processing $FRAMEWORK_NAME..."
        
        # Determine the correct slice for current architecture
        FRAMEWORK_ARCHITECTURES=$(find "$FRAMEWORK_PATH" -name "*.framework" -type d)
        
        for ARCH_FRAMEWORK in $FRAMEWORK_ARCHITECTURES; do
            FRAMEWORK_EXECUTABLE_NAME=$(basename "$ARCH_FRAMEWORK" .framework)
            FRAMEWORK_EXECUTABLE_PATH="$ARCH_FRAMEWORK/$FRAMEWORK_EXECUTABLE_NAME"
            
            if [ -f "$FRAMEWORK_EXECUTABLE_PATH" ]; then
                # Check if this framework supports current architecture
                FRAMEWORK_ARCHS=$(lipo -info "$FRAMEWORK_EXECUTABLE_PATH" 2>/dev/null | grep "Architectures in" | sed 's/.*: //' || echo "")
                
                if echo "$FRAMEWORK_ARCHS" | grep -q "$ARCHS"; then
                    echo "  ✅ Embedding framework for architecture: $ARCHS"
                    
                    # Copy framework to app bundle
                    DESTINATION="${BUILT_PRODUCTS_DIR}/${FRAMEWORKS_FOLDER_PATH}"
                    mkdir -p "$DESTINATION"
                    
                    rsync -av --delete "$ARCH_FRAMEWORK" "$DESTINATION/" || true
                    
                    # Code sign if needed
                    if [ "${CODE_SIGNING_REQUIRED}" = "YES" ]; then
                        /usr/bin/codesign --force --sign "${EXPANDED_CODE_SIGN_IDENTITY}" --preserve-metadata=identifier,entitlements "$DESTINATION/$(basename "$ARCH_FRAMEWORK")" || true
                    fi
                    
                    break
                fi
            fi
        done
    fi
done

echo "✅ xcframework embedding complete"
