#!/bin/bash

# Build version information
builtAt="${OPENLIST_BUILT_AT:-$(date +'%F %T %z')}"
gitAuthor="${OPENLIST_GIT_AUTHOR:-The OpenList Projects Contributors <noreply@openlist.team>}"
gitCommit="${OPENLIST_GIT_COMMIT:-$(git log --pretty=format:'%h' -1 2>/dev/null || echo 'unknown')}"
version="${OPENLIST_VERSION:-dev}"
webVersion="${OPENLIST_WEB_VERSION:-rolling}"

echo "Building with version info:"
echo "  Version: $version"
echo "  WebVersion: $webVersion"
echo "  GitCommit: $gitCommit"
echo "  BuiltAt: $builtAt"

# Construct ldflags
ldflags="-s -w"
ldflags="$ldflags -X 'github.com/OpenListTeam/OpenList/v4/internal/conf.BuiltAt=$builtAt'"
ldflags="$ldflags -X 'github.com/OpenListTeam/OpenList/v4/internal/conf.GitAuthor=$gitAuthor'"
ldflags="$ldflags -X 'github.com/OpenListTeam/OpenList/v4/internal/conf.GitCommit=$gitCommit'"
ldflags="$ldflags -X 'github.com/OpenListTeam/OpenList/v4/internal/conf.Version=$version'"
ldflags="$ldflags -X 'github.com/OpenListTeam/OpenList/v4/internal/conf.WebVersion=$webVersion'"

echo "Starting iOS build from: $(pwd)"

# Find openlistlib directory
if [ -d ../openlistlib ]; then
    cd ../openlistlib || exit
elif [ -d openlistlib ]; then
    cd openlistlib || exit
else
    echo "Error: Cannot find openlistlib directory"
    exit 1
fi

echo "Current directory: $(pwd)"

# Check if gomobile is available
if ! command -v gomobile &> /dev/null; then
    echo "Error: gomobile not found. Please run init_gomobile.sh first."
    exit 1
fi

echo "Go version: $(go version)"

# Work from module root if go.mod exists in parent
if [ -f ../go.mod ]; then
    echo "Found go.mod in parent directory"
    cd ..
    
    # Fix iOS incompatible dependencies
    echo "Fixing iOS incompatible dependencies..."
    chmod +x scripts/fix_ios_dependencies.sh
    ./scripts/fix_ios_dependencies.sh
    
    # Update mobile packages
    echo "Updating mobile packages..."
    go get -u golang.org/x/mobile/...
    go install golang.org/x/mobile/cmd/gobind@latest
    go install golang.org/x/mobile/cmd/gomobile@latest
    
    # Reinitialize gomobile
    echo "Reinitializing gomobile..."
    gomobile clean || true
    gomobile init
    
    # Set CGO environment for iOS
    export CGO_ENABLED=1
    
    # Build for iOS with iOS-specific build tags to exclude incompatible packages
    echo "Starting iOS build from module root..."
    echo "CGO_ENABLED: $CGO_ENABLED"
    
    # Use build tags to exclude problematic packages on iOS
    echo "Attempting gomobile bind with iOS tags..."
    gomobile bind -ldflags "$ldflags" -v -target="ios" -tags="ios,mobile" ./openlistlib 2>&1 | tee ios_build.log
    
    # Check the exit status
    if [ $? -ne 0 ]; then
        echo "Error: gomobile bind failed"
        echo "=== Build log ==="
        cat ios_build.log 2>/dev/null || echo "No build log available"
        echo "=== End build log ==="
        
        # Try to get more specific error information
        echo "Checking for specific issues..."
        
        # Check if it's a dependency issue
        if grep -q "cannot find package\|no Go files\|build constraints exclude all Go files" ios_build.log; then
            echo "Detected dependency or build constraint issues"
            
            # Try with minimal tags
            echo "Retrying with minimal build tags..."
            gomobile bind -ldflags "$ldflags" -v -target="ios" ./openlistlib 2>&1 | tee ios_build_minimal.log
            
            if [ $? -ne 0 ]; then
                echo "Minimal build also failed:"
                cat ios_build_minimal.log 2>/dev/null || echo "No minimal build log available"
                exit 1
            fi
        else
            echo "Unknown build error, exiting"
            exit 1
        fi
    fi
    
    echo "Listing generated files in current directory:"
    ls -la *.xcframework 2>/dev/null || echo "No .xcframework files found in current directory"
    
    # Also check if any frameworks were generated with different patterns
    ls -la Openlistlib.xcframework 2>/dev/null || echo "Openlistlib.xcframework not found"
    ls -la openlistlib.xcframework 2>/dev/null || echo "openlistlib.xcframework not found"
    
    # Find the Flutter project root by looking for pubspec.yaml
    echo "Locating Flutter project root..."
    FLUTTER_ROOT=""
    CURRENT_DIR=$(pwd)
    
    # Check various possible locations for pubspec.yaml
    if [ -f "pubspec.yaml" ]; then
        FLUTTER_ROOT="."
        echo "Found Flutter project root at current directory"
    elif [ -f "../pubspec.yaml" ]; then
        FLUTTER_ROOT="../"
        echo "Found Flutter project root at ../"
    elif [ -f "../../pubspec.yaml" ]; then
        FLUTTER_ROOT="../../"
        echo "Found Flutter project root at ../../"
    elif [ -f "../../../pubspec.yaml" ]; then
        FLUTTER_ROOT="../../../"
        echo "Found Flutter project root at ../../../"
    else
        # Try to find it by searching upwards
        SEARCH_DIR="$CURRENT_DIR"
        for i in {1..5}; do
            SEARCH_DIR="$(dirname "$SEARCH_DIR")"
            if [ -f "$SEARCH_DIR/pubspec.yaml" ]; then
                FLUTTER_ROOT=$(realpath --relative-to="$CURRENT_DIR" "$SEARCH_DIR")
                echo "Found Flutter project root at: $FLUTTER_ROOT"
                break
            fi
        done
        
        if [ -z "$FLUTTER_ROOT" ]; then
            echo "Warning: Cannot find Flutter project root (pubspec.yaml), using default relative path"
            FLUTTER_ROOT="../../"
        fi
    fi
    
    echo "Using Flutter project root: $FLUTTER_ROOT"
    echo "Creating iOS Frameworks directory at: ${FLUTTER_ROOT}ios/Frameworks"
    mkdir -p "${FLUTTER_ROOT}ios/Frameworks"
    
    # Check if xcframework files exist before moving
    if ls *.xcframework 1> /dev/null 2>&1; then
        echo "Moving xcframework files to Flutter iOS Frameworks directory..."
        
        # Ensure the target directory exists
        mkdir -p "${FLUTTER_ROOT}ios/Frameworks"
        
        # Copy files to Flutter project
        for framework in *.xcframework; do
            echo "Copying $framework to ${FLUTTER_ROOT}ios/Frameworks/"
            cp -rf "$framework" "${FLUTTER_ROOT}ios/Frameworks/"
        done
        
        echo "✅ iOS framework build completed successfully"
        echo "Files in Flutter iOS Frameworks directory:"
        ls -lah "${FLUTTER_ROOT}ios/Frameworks/"
        
        # Verify the files are in the expected location
        EXPECTED_PATH="${FLUTTER_ROOT}ios/Frameworks"
        ABSOLUTE_EXPECTED_PATH=$(cd "$EXPECTED_PATH" && pwd)
        if [ -d "$EXPECTED_PATH" ] && [ "$(ls -A "$EXPECTED_PATH")" ]; then
            echo "✅ Framework files successfully placed in: $ABSOLUTE_EXPECTED_PATH"
            
            # List all frameworks found
            echo ""
            echo "=== Frameworks Ready ==="
            find "$EXPECTED_PATH" -name "*.xcframework" -type d -exec basename {} \;
        else
            echo "❌ Warning: Framework files may not be in the expected location"
        fi
    else
        echo "Warning: No .xcframework files were generated"
        echo "Checking if files were generated with different names..."
        ls -la *.framework 2>/dev/null || echo "No .framework files found either"
        ls -la openlistlib* 2>/dev/null || echo "No openlistlib files found"
        exit 1
    fi
else
    echo "Error: No go.mod found in parent directory"
    exit 1
fi