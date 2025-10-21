#!/bin/bash

VERSION_FILE="$GITHUB_WORKSPACE/openlist_version"
PUBSPEC_FILE="$GITHUB_WORKSPACE/pubspec.yaml"

if [ ! -f "$VERSION_FILE" ]; then
    echo "Error: openlist_version file not found"
    exit 1
fi

if [ ! -f "$PUBSPEC_FILE" ]; then
    echo "Error: pubspec.yaml file not found"
    exit 1
fi

OPENLIST_VERSION=$(cat "$VERSION_FILE")

BASE_VERSION=${OPENLIST_VERSION#v}

echo "Updating pubspec.yaml version to: $BASE_VERSION"

sed -i "s/^version: [0-9]\+\.[0-9]\+\.[0-9]\++[0-9]\+.*/version: ${BASE_VERSION}+1/" "$PUBSPEC_FILE"

echo "pubspec.yaml version updated successfully"