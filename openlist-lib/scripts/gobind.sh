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

# First check if we're in the right place
echo "Starting Android build from: $(pwd)"

# For Android, we need to find the bindable package directory, not just go.mod
# The original approach was correct - look for openlistlib directory
if [ -d ../openlistlib ]; then
    echo "Found openlistlib directory, using that for Android build"
    cd ../openlistlib || exit
else
    echo "Searching for bindable package directory..."
    cd ../ || exit
    
    # Look for directories that might contain bindable packages
    if [ -d openlistlib ]; then
        echo "Found openlistlib in current directory"
        cd openlistlib || exit
    elif [ -d cmd/openlistlib ]; then
        echo "Found openlistlib in cmd directory"
        cd cmd/openlistlib || exit
    else
        echo "Error: Cannot find openlistlib directory for Android binding"
        echo "Current directory: $(pwd)"
        echo "Directory contents:"
        ls -la
        echo "Looking for Go files that might be bindable..."
        find . -name "*.go" -type f | head -10
        exit 1
    fi
fi

echo "Current directory: $(pwd)"
echo "Building OpenList for Android..."

# Check if this directory has Go files suitable for binding
if ! ls *.go >/dev/null 2>&1; then
    echo "Warning: No Go files found in current directory"
    echo "Directory contents:"
    ls -la
fi

if [ "$1" == "debug" ]; then
  gomobile bind -ldflags "$ldflags" -v -androidapi 19 -target="android/arm64"
else
  gomobile bind -ldflags "$ldflags" -v -androidapi 19
fi

echo "Moving aar and jar files to android/app/libs"
mkdir -p ../../android/app/libs
mv -f ./*.aar ../../android/app/libs
mv -f ./*.jar ../../android/app/libs
