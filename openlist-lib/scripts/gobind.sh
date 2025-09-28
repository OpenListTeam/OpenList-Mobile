#!/bin/bash

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
  gomobile bind -ldflags "-s -w" -v -androidapi 19 -target="android/arm64"
else
  gomobile bind -ldflags "-s -w" -v -androidapi 19
fi

echo "Moving aar and jar files to android/app/libs"
mkdir -p ../../android/app/libs
mv -f ./*.aar ../../android/app/libs
mv -f ./*.jar ../../android/app/libs
