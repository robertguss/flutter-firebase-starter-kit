# iOS Flavor Schemes Setup

Android flavors are configured automatically via `build.gradle.kts`. iOS
requires manual Xcode configuration.

## Overview

Flutter flavors on iOS require:

1. Build configurations per flavor (Debug-dev, Release-dev, Profile-dev, etc.)
2. Xcode schemes per flavor (dev, staging, prod)
3. Schemes marked as **Shared** (required for CI)

## Step-by-Step

### 1. Create Build Configurations

Open `ios/Runner.xcodeproj` in Xcode.

1. Click the project in the navigator (not the target)
2. Go to the **Info** tab
3. Under **Configurations**, duplicate each existing config:

| Base Config | Duplicate As                               |
| ----------- | ------------------------------------------ |
| Debug       | Debug-dev, Debug-staging, Debug-prod       |
| Release     | Release-dev, Release-staging, Release-prod |
| Profile     | Profile-dev, Profile-staging, Profile-prod |

Total: 9 build configurations (3 flavors x 3 build types).

### 2. Create xcconfig Files

Create flavor-specific xcconfig files in `ios/Flutter/`:

**ios/Flutter/Dev.xcconfig:**

```
#include "Debug.xcconfig"
PRODUCT_BUNDLE_IDENTIFIER = com.example.starterkit.dev
PRODUCT_NAME = StarterKit Dev
```

**ios/Flutter/Staging.xcconfig:**

```
#include "Debug.xcconfig"
PRODUCT_BUNDLE_IDENTIFIER = com.example.starterkit.staging
PRODUCT_NAME = StarterKit Staging
```

**ios/Flutter/Prod.xcconfig:**

```
#include "Debug.xcconfig"
PRODUCT_BUNDLE_IDENTIFIER = com.example.starterkit
PRODUCT_NAME = StarterKit
```

Assign each xcconfig to the corresponding build configuration in the project
Info tab.

### 3. Create Schemes

1. In Xcode, go to **Product > Scheme > Manage Schemes**
2. Click **+** to create three new schemes: `dev`, `staging`, `prod`
3. For each scheme, assign the corresponding build configurations:
   - **dev** scheme: Debug-dev (Run), Release-dev (Archive), Profile-dev
     (Profile)
   - **staging** scheme: Debug-staging, Release-staging, Profile-staging
   - **prod** scheme: Debug-prod, Release-prod, Profile-prod

### 4. Mark Schemes as Shared (Critical for CI)

In **Manage Schemes**, check the **Shared** checkbox for each flavor scheme.
This stores scheme files in `xcshareddata/xcschemes/` instead of user-specific
directories, making them available to CI and other developers.

Without this step, `flutter build ios --flavor dev` will fail on CI.

### 5. Run pod install

After adding configurations, CocoaPods needs to regenerate:

```bash
cd ios && pod install && cd ..
```

### 6. Firebase Config per Flavor

Each flavor needs its own `GoogleService-Info.plist`:

```bash
# Run for each flavor
flutterfire configure \
  --project=your-project-dev \
  --ios-bundle-id=com.example.starterkit.dev \
  --ios-out=ios/config/dev/GoogleService-Info.plist

flutterfire configure \
  --project=your-project-staging \
  --ios-bundle-id=com.example.starterkit.staging \
  --ios-out=ios/config/staging/GoogleService-Info.plist

flutterfire configure \
  --project=your-project-prod \
  --ios-bundle-id=com.example.starterkit \
  --ios-out=ios/config/prod/GoogleService-Info.plist
```

Add a Run Script build phase to copy the correct plist:

```bash
# Copy flavor-specific GoogleService-Info.plist
PLIST_SRC="${PROJECT_DIR}/config/${PRODUCT_FLAVOR}/GoogleService-Info.plist"
PLIST_DST="${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/GoogleService-Info.plist"
if [ -f "$PLIST_SRC" ]; then
  cp "$PLIST_SRC" "$PLIST_DST"
fi
```

## Verification

```bash
# Test each flavor builds
flutter run --flavor dev -t lib/main_dev.dart
flutter run --flavor staging -t lib/main_staging.dart
flutter run --flavor prod -t lib/main_prod.dart

# Verify bundle IDs differ
flutter build ios --flavor dev -t lib/main_dev.dart --no-codesign
flutter build ios --flavor prod -t lib/main_prod.dart --no-codesign
```

## Troubleshooting

- **"Unable to find a scheme named X"**: Ensure schemes are created and marked
  as Shared
- **Pod install fails**: Run `pod install` after adding any new build
  configurations
- **Wrong Firebase config**: Verify the Run Script phase copies the correct
  plist for the active scheme
- **Flavor names**: Must be lowercase and match exactly between Android and iOS
