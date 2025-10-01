# iOS Framework Integration Guide

## Overview

This document explains how the OpenList xcframework is integrated into the iOS Flutter application to ensure it's properly embedded in the final IPA bundle.

## Problem

Previously, the OpenList backend framework (built as xcframework) was built successfully but not included in the final IPA package, causing the app's core functionality to fail.

## Solution

The integration uses a multi-layered approach to ensure frameworks are properly embedded:

### 1. Framework Build Process

The `gobind_ios.sh` script:
- Builds the OpenList backend as an xcframework using gomobile
- Places the xcframework in `ios/Frameworks/` directory
- Verifies the framework structure

### 2. CocoaPods Integration

The `ios/Podfile`:
- Automatically discovers xcframeworks in `ios/Frameworks/`
- Adds framework references to the Xcode project
- Configures build phases to embed frameworks
- Sets up proper framework search paths
- Handles code signing for embedded frameworks

Key features:
- Creates/updates Frameworks group in Xcode project
- Adds frameworks to "Link Binary with Libraries" phase
- Adds frameworks to "Embed Frameworks" phase with proper attributes
- Sets framework search paths in build configurations

### 3. Build Configuration

The `ios/Flutter/*.xcconfig` files:
- Add framework search paths: `$(PROJECT_DIR)/Frameworks`
- Ensure Xcode can locate the frameworks during build

### 4. Build Scripts

Additional helper scripts in `ios/scripts/`:

#### `embed_openlist_framework.sh`
- Runtime script that can be added as Xcode build phase
- Copies appropriate framework slice based on platform (device vs simulator)
- Handles code signing
- Validates framework architectures

#### `add_framework_to_project.py`
- Python script to directly modify project.pbxproj
- Alternative method for framework integration
- Can add build phases and framework references programmatically

## CI/CD Workflow

The GitHub Actions workflow (`build.yaml`):

```yaml
1. Download OpenList source and build dependencies
2. Initialize gomobile
3. Build OpenList xcframework (gobind_ios.sh)
4. Upload framework as artifact
5. Setup Flutter
6. Verify framework location
7. Run pod install (integrates frameworks)
8. Build iOS app with flutter build
9. Create IPA package
```

## Verification

To verify frameworks are properly embedded:

### Local Build
```bash
cd ios
pod install
cd ..
flutter build ios --release --no-codesign
```

Check the build output:
```bash
cd build/ios/iphoneos/Runner.app/Frameworks
ls -la
```

You should see the OpenList framework.

### In Xcode
1. Open `ios/Runner.xcworkspace` (not .xcodeproj)
2. Check Project Navigator -> Frameworks group
3. Check Build Phases -> Link Binary With Libraries
4. Check Build Phases -> Embed Frameworks
5. Check Build Settings -> Framework Search Paths

## Troubleshooting

### Framework not found at runtime
- Ensure `pod install` was run after adding frameworks
- Check framework is in `ios/Frameworks/` directory
- Verify framework search paths in build settings

### Code signing issues
- Frameworks are automatically signed during build
- For manual builds, ensure code signing identity is set
- The Podfile configures proper code sign attributes

### Architecture mismatch
- xcframework contains slices for different platforms
- iOS device: ios-arm64
- iOS simulator: ios-arm64_x86_64-simulator or ios-x86_64-simulator
- The embed script automatically selects correct slice

## Architecture

```
OpenListFlutter/
├── ios/
│   ├── Frameworks/               # xcframework files placed here
│   │   └── openlistlib.xcframework
│   ├── Podfile                   # CocoaPods configuration
│   ├── Flutter/
│   │   ├── Debug.xcconfig        # Debug build settings
│   │   └── Release.xcconfig      # Release build settings
│   └── scripts/
│       ├── embed_openlist_framework.sh    # Runtime embed script
│       └── add_framework_to_project.py    # Project modification tool
└── openlist-lib/
    └── scripts/
        └── gobind_ios.sh         # Framework build script
```

## References

- [Flutter iOS Integration](https://docs.flutter.dev/platform-integration/ios/platform-channels)
- [Xcode Framework Integration](https://developer.apple.com/documentation/xcode/embedding-frameworks-in-an-app)
- [CocoaPods](https://cocoapods.org/)
- [gomobile](https://pkg.go.dev/golang.org/x/mobile/cmd/gomobile)
