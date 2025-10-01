#!/bin/bash

# Local iOS build test script
# Use this to test framework integration before pushing to CI

set -e

echo "=== OpenList iOS Local Build Test ==="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

echo "Project root: $PROJECT_ROOT"
echo ""

# Step 1: Check prerequisites
echo "Step 1: Checking prerequisites..."

if ! command -v flutter &> /dev/null; then
    echo -e "${RED}✗ Flutter not found${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Flutter found: $(flutter --version | head -n 1)${NC}"

if ! command -v go &> /dev/null; then
    echo -e "${RED}✗ Go not found${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Go found: $(go version)${NC}"

if ! command -v pod &> /dev/null; then
    echo -e "${RED}✗ CocoaPods not found${NC}"
    echo "Install with: sudo gem install cocoapods"
    exit 1
fi
echo -e "${GREEN}✓ CocoaPods found: $(pod --version)${NC}"

if ! command -v gomobile &> /dev/null; then
    echo -e "${YELLOW}⚠ gomobile not found, will install${NC}"
fi

echo ""

# Step 2: Download OpenList source
echo "Step 2: Downloading OpenList source code..."
cd "$PROJECT_ROOT/openlist-lib/scripts"
chmod +x *.sh

if [ ! -d "../OpenList" ]; then
    echo "Running init_openlist.sh..."
    ./init_openlist.sh
else
    echo -e "${GREEN}✓ OpenList source already exists${NC}"
fi

if [ ! -d "../OpenList-Frontend/dist" ]; then
    echo "Running init_web_ios.sh..."
    ./init_web_ios.sh
else
    echo -e "${GREEN}✓ Web assets already exist${NC}"
fi

echo ""

# Step 3: Initialize gomobile
echo "Step 3: Initializing gomobile..."
./init_gomobile.sh

echo ""

# Step 4: Build iOS framework
echo "Step 4: Building iOS framework..."
export OPENLIST_VERSION="dev-test"
export OPENLIST_WEB_VERSION="dev"
export OPENLIST_GIT_COMMIT="local"
export OPENLIST_BUILT_AT="$(date +'%F %T %z')"
export OPENLIST_GIT_AUTHOR="Local Build"

./gobind_ios.sh

echo ""

# Step 5: Verify framework
echo "Step 5: Verifying framework..."
FRAMEWORKS_DIR="$PROJECT_ROOT/ios/Frameworks"

if [ ! -d "$FRAMEWORKS_DIR" ]; then
    echo -e "${RED}✗ Frameworks directory not found${NC}"
    exit 1
fi

FRAMEWORK_COUNT=$(find "$FRAMEWORKS_DIR" -name "*.xcframework" -maxdepth 1 -type d | wc -l)
if [ "$FRAMEWORK_COUNT" -eq 0 ]; then
    echo -e "${RED}✗ No xcframework found${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Found $FRAMEWORK_COUNT framework(s):${NC}"
find "$FRAMEWORKS_DIR" -name "*.xcframework" -maxdepth 1 -type d -exec basename {} \;

echo ""

# Step 6: Run CocoaPods
echo "Step 6: Running CocoaPods integration..."
cd "$PROJECT_ROOT/ios"

echo "Running pod install..."
pod install

if [ ! -d "Runner.xcworkspace" ]; then
    echo -e "${RED}✗ Xcode workspace not created${NC}"
    exit 1
fi

echo -e "${GREEN}✓ CocoaPods integration complete${NC}"

echo ""

# Step 7: Flutter dependencies
echo "Step 7: Installing Flutter dependencies..."
cd "$PROJECT_ROOT"
flutter pub get

echo ""

# Step 8: Build iOS
echo "Step 8: Building iOS app..."
echo "This will take several minutes..."
echo ""

flutter build ios --release --no-codesign

echo ""

# Step 9: Verify build output
echo "Step 9: Verifying build output..."

IPA_DIR="$PROJECT_ROOT/build/ios/iphoneos"
APP_PATH="$IPA_DIR/Runner.app"

if [ ! -d "$APP_PATH" ]; then
    echo -e "${RED}✗ App bundle not found${NC}"
    exit 1
fi

echo -e "${GREEN}✓ App bundle created: $APP_PATH${NC}"

# Check if frameworks are embedded
APP_FRAMEWORKS="$APP_PATH/Frameworks"
if [ -d "$APP_FRAMEWORKS" ]; then
    EMBEDDED_COUNT=$(find "$APP_FRAMEWORKS" -name "*.framework" -maxdepth 1 -type d | wc -l)
    echo -e "${GREEN}✓ Found $EMBEDDED_COUNT embedded framework(s)${NC}"
    find "$APP_FRAMEWORKS" -name "*.framework" -maxdepth 1 -type d -exec basename {} \;
    
    # List all frameworks
    echo ""
    echo "All frameworks in app bundle:"
    ls -lh "$APP_FRAMEWORKS"
else
    echo -e "${YELLOW}⚠ No Frameworks directory in app bundle${NC}"
    echo "This might be okay if frameworks are statically linked"
fi

echo ""
echo -e "${GREEN}=== Build Test Complete ===${NC}"
echo ""
echo "Next steps:"
echo "1. Check build output above for any warnings"
echo "2. Test the app on a real device or simulator"
echo "3. If successful, push changes to trigger CI build"
echo ""
