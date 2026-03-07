# Flutter Flavors Best Practices (2025-2026)

Comprehensive guide for configuring Flutter flavors with Firebase for
dev/staging/prod environments.

**Sources**: Flutter official docs (flutter.dev), FlutterFire CLI docs, Andrea
Bizzotto's guide (codewithandrea.com), flutter_flavorizr package docs, project
brainstorm doc.

---

## Table of Contents

1. [Android productFlavors Configuration](#1-android-productflavors-configuration)
2. [iOS Scheme and Configuration Setup](#2-ios-scheme-and-configuration-setup)
3. [Per-Flavor Firebase Configuration](#3-per-flavor-firebase-configuration)
4. [Per-Flavor App Icons and App Names](#4-per-flavor-app-icons-and-app-names)
5. [How flutter run --flavor Interacts with Build Modes](#5-how-flutter-run---flavor-interacts-with-build-modes)
6. [Common Pitfalls](#6-common-pitfalls)
7. [CI/CD with GitHub Actions](#7-cicd-with-github-actions)
8. [flutter_flavorizr Assessment](#8-flutter_flavorizr-assessment)
9. [Testing with Flavors](#9-testing-with-flavors)
10. [Per-Flavor Environment Variables](#10-per-flavor-environment-variables)

---

## 1. Android productFlavors Configuration

**Source: Flutter official docs + project brainstorm**

Edit `android/app/build.gradle.kts`:

```kotlin
android {
    // ...existing config...

    buildTypes {
        getByName("debug") {
            // debug config
        }
        getByName("release") {
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    flavorDimensions += "environment"
    productFlavors {
        create("dev") {
            dimension = "environment"
            applicationIdSuffix = ".dev"
            resValue(
                type = "string",
                name = "app_name",
                value = "StarterKit Dev"
            )
        }
        create("staging") {
            dimension = "environment"
            applicationIdSuffix = ".staging"
            resValue(
                type = "string",
                name = "app_name",
                value = "StarterKit Staging"
            )
        }
        create("prod") {
            dimension = "environment"
            resValue(
                type = "string",
                name = "app_name",
                value = "StarterKit"
            )
            // No applicationIdSuffix -- this is the production bundle ID
        }
    }
}
```

**Key points:**

- `flavorDimensions` groups related flavors. Use a single dimension
  ("environment") for most apps.
- `applicationIdSuffix` lets all three flavors coexist on the same device.
- `resValue` injects the app name as a string resource (use `@string/app_name`
  in AndroidManifest.xml).
- The resulting build variants are: `devDebug`, `devRelease`, `stagingDebug`,
  `stagingRelease`, `prodDebug`, `prodRelease`.

**Update AndroidManifest.xml** to use the dynamic app name:

```xml
<application
    android:label="@string/app_name"
    ...>
```

---

## 2. iOS Scheme and Configuration Setup

**Source: Flutter official iOS flavors docs**

iOS does not have "flavors" -- instead you use Xcode **schemes** and **build
configurations**.

### Step-by-step:

#### 2a. Create Build Configurations in Xcode

1. Open `ios/Runner.xcworkspace` in Xcode.
2. Select the **Runner** project in the navigator.
3. Under **Info > Configurations**, duplicate existing configs:
   - Duplicate `Debug` -> `Debug-dev`, `Debug-staging`, `Debug-prod`
   - Duplicate `Release` -> `Release-dev`, `Release-staging`, `Release-prod`
   - Duplicate `Profile` -> `Profile-dev`, `Profile-staging`, `Profile-prod`

#### 2b. Create Schemes

1. **Product > Scheme > New Scheme**
2. Target: **Runner**, Name: `dev`
3. Repeat for `staging` and `prod`
4. For each scheme, edit it (**Product > Scheme > Edit Scheme**) and assign:
   - Run -> Build Configuration: `Debug-<flavor>`
   - Test -> Build Configuration: `Debug-<flavor>`
   - Profile -> Build Configuration: `Profile-<flavor>`
   - Analyze -> Build Configuration: `Debug-<flavor>`
   - Archive -> Build Configuration: `Release-<flavor>`
5. **CRITICAL**: Ensure all schemes are **Shared** (check in **Manage Schemes**
   window). Unshared schemes break CI/CD.

#### 2c. Create xcconfig Files

Create per-flavor xcconfig files (optional but recommended for cleaner config):

**`ios/Flutter/Dev.xcconfig`**:

```
#include "Debug.xcconfig"
PRODUCT_BUNDLE_IDENTIFIER = com.example.starterkit.dev
FLUTTER_TARGET = lib/main_dev.dart
APP_DISPLAY_NAME = StarterKit Dev
```

**`ios/Flutter/Staging.xcconfig`**:

```
#include "Debug.xcconfig"
PRODUCT_BUNDLE_IDENTIFIER = com.example.starterkit.staging
FLUTTER_TARGET = lib/main_staging.dart
APP_DISPLAY_NAME = StarterKit Staging
```

**`ios/Flutter/Prod.xcconfig`**:

```
#include "Release.xcconfig"
PRODUCT_BUNDLE_IDENTIFIER = com.example.starterkit
FLUTTER_TARGET = lib/main_prod.dart
APP_DISPLAY_NAME = StarterKit
```

#### 2d. Set Per-Configuration Bundle Identifiers

In Xcode, under **TARGETS > Runner > Build Settings > Packaging > Product Bundle
Identifier**:

- `Debug-dev`, `Profile-dev`, `Release-dev`: `com.example.starterkit.dev`
- `Debug-staging`, `Profile-staging`, `Release-staging`:
  `com.example.starterkit.staging`
- `Debug-prod`, `Profile-prod`, `Release-prod`: `com.example.starterkit`

#### 2e. Set Per-Configuration App Display Names

1. Add a User-Defined Setting called `APP_DISPLAY_NAME`.
2. Set values per configuration:
   - `Debug-dev`, `Profile-dev`, `Release-dev`: `StarterKit Dev`
   - `Debug-staging`, etc.: `StarterKit Staging`
   - `Debug-prod`, etc.: `StarterKit`
3. In `Info.plist`, set `CFBundleDisplayName` to `$(APP_DISPLAY_NAME)`.

---

## 3. Per-Flavor Firebase Configuration

**Source: Andrea Bizzotto guide + FlutterFire CLI docs**

### Recommended approach: FlutterFire CLI with `--flavor`

Create a **separate Firebase project** per environment (e.g., `myapp-dev`,
`myapp-staging`, `myapp-prod`).

#### 3a. Shell Script for Configuration

Create `flutterfire-config.sh` at project root:

```bash
#!/bin/bash
# Generate Firebase configuration files for each flavor

if [[ $# -eq 0 ]]; then
  echo "Error: No environment specified. Use 'dev', 'staging', or 'prod'."
  exit 1
fi

case $1 in
  dev)
    flutterfire config \
      --project=myapp-dev \
      --out=lib/firebase_options_dev.dart \
      --ios-bundle-id=com.example.starterkit.dev \
      --ios-out=ios/flavors/dev/GoogleService-Info.plist \
      --android-package-name=com.example.starterkit.dev \
      --android-out=android/app/src/dev/google-services.json
    ;;
  staging)
    flutterfire config \
      --project=myapp-staging \
      --out=lib/firebase_options_staging.dart \
      --ios-bundle-id=com.example.starterkit.staging \
      --ios-out=ios/flavors/staging/GoogleService-Info.plist \
      --android-package-name=com.example.starterkit.staging \
      --android-out=android/app/src/staging/google-services.json
    ;;
  prod)
    flutterfire config \
      --project=myapp-prod \
      --out=lib/firebase_options_prod.dart \
      --ios-bundle-id=com.example.starterkit \
      --ios-out=ios/flavors/prod/GoogleService-Info.plist \
      --android-package-name=com.example.starterkit \
      --android-out=android/app/src/prod/google-services.json
    ;;
  all)
    $0 dev && $0 staging && $0 prod
    ;;
  *)
    echo "Error: Unknown environment '$1'. Use 'dev', 'staging', or 'prod'."
    exit 1
    ;;
esac
```

Run: `chmod +x flutterfire-config.sh && ./flutterfire-config.sh all`

When prompted, select **"Build configuration"** and pick the matching
`Debug-<flavor>` config.

#### 3b. File Structure After Configuration

```
android/app/src/
├── dev/google-services.json
├── staging/google-services.json
└── prod/google-services.json

ios/flavors/
├── dev/GoogleService-Info.plist
├── staging/GoogleService-Info.plist
└── prod/GoogleService-Info.plist

lib/
├── firebase_options_dev.dart
├── firebase_options_staging.dart
└── firebase_options_prod.dart
```

#### 3c. Firebase Initialization (Two Approaches)

**Option A: Single main.dart with flavor detection (simpler)**

```dart
// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options_dev.dart' as dev;
import 'firebase_options_staging.dart' as staging;
import 'firebase_options_prod.dart' as prod;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  final FirebaseOptions options;
  switch (flavor) {
    case 'prod':
      options = prod.DefaultFirebaseOptions.currentPlatform;
    case 'staging':
      options = staging.DefaultFirebaseOptions.currentPlatform;
    default:
      options = dev.DefaultFirebaseOptions.currentPlatform;
  }

  await Firebase.initializeApp(options: options);
  runApp(const MyApp());
}
```

> Warning: This bundles ALL Firebase configs into every build. Fine for most
> apps, but not ideal if configs contain sensitive data.

**Option B: Multiple entry points (more secure, recommended)**

```dart
// lib/main_dev.dart
import 'firebase_options_dev.dart';
import 'main_common.dart';
void main() => runMainApp(DefaultFirebaseOptions.currentPlatform);

// lib/main_staging.dart
import 'firebase_options_staging.dart';
import 'main_common.dart';
void main() => runMainApp(DefaultFirebaseOptions.currentPlatform);

// lib/main_prod.dart
import 'firebase_options_prod.dart';
import 'main_common.dart';
void main() => runMainApp(DefaultFirebaseOptions.currentPlatform);

// lib/main_common.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void runMainApp(FirebaseOptions firebaseOptions) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: firebaseOptions);
  runApp(const MyApp());
}
```

Run with: `flutter run --flavor dev -t lib/main_dev.dart`

---

## 4. Per-Flavor App Icons and App Names

### Android App Icons

Place flavor-specific icons in the flavor source sets:

```
android/app/src/
├── dev/res/
│   ├── mipmap-hdpi/ic_launcher.png
│   ├── mipmap-mdpi/ic_launcher.png
│   ├── mipmap-xhdpi/ic_launcher.png
│   ├── mipmap-xxhdpi/ic_launcher.png
│   └── mipmap-xxxhdpi/ic_launcher.png
├── staging/res/
│   └── (same structure)
└── prod/res/
    └── (same structure)
```

Android merges flavor-specific resources over the `main` source set
automatically.

### iOS App Icons

For iOS, use an asset catalog per flavor or use a build phase script:

1. Create separate `Assets.xcassets` per flavor under
   `ios/flavors/<flavor>/Assets.xcassets`
2. In Xcode Build Settings, set `ASSETCATALOG_COMPILER_APPICON_NAME` per
   configuration.
3. Or use `flutter_launcher_icons` package with flavor support:

```yaml
# flutter_launcher_icons-dev.yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/launcher_icon/dev.png"

# flutter_launcher_icons-prod.yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/launcher_icon/prod.png"
```

Run: `dart run flutter_launcher_icons -f flutter_launcher_icons-dev.yaml`

### App Names

- **Android**: Use `resValue` in `build.gradle.kts` (shown in section 1) +
  `@string/app_name` in manifest.
- **iOS**: Use `APP_DISPLAY_NAME` user-defined setting + `$(APP_DISPLAY_NAME)`
  in Info.plist (shown in section 2).

---

## 5. How flutter run --flavor Interacts with Build Modes

**Source: Flutter official docs**

Flutter has three build modes: **debug**, **release**, **profile**. Flavors are
orthogonal to build modes, creating a matrix:

| Flavor  | Debug        | Release        | Profile        |
| ------- | ------------ | -------------- | -------------- |
| dev     | devDebug     | devRelease     | devProfile     |
| staging | stagingDebug | stagingRelease | stagingProfile |
| prod    | prodDebug    | prodRelease    | prodProfile    |

**Commands:**

```bash
# Debug mode (default)
flutter run --flavor dev

# Release mode
flutter run --flavor prod --release

# Profile mode (for performance testing)
flutter run --flavor prod --profile

# Build APK
flutter build apk --flavor prod --release

# Build iOS
flutter build ios --flavor prod --release

# With custom entry point
flutter run --flavor dev -t lib/main_dev.dart
```

**Key insight**: `flutter run --flavor dev` defaults to debug mode. The flavor
selects which `productFlavor` (Android) or scheme (iOS) to use. The build mode
selects which `buildType` (Android) or configuration suffix (iOS) to use. They
combine: `devDebug`, `prodRelease`, etc.

---

## 6. Common Pitfalls

### iOS-Specific Pitfalls (the most painful)

1. **Unshared schemes**: If schemes are not marked as "Shared" in Xcode, they
   will not be available in CI/CD or to other developers. Always verify in
   **Product > Scheme > Manage Schemes**.

2. **Configuration naming mismatch**: Flutter expects configurations named
   `Debug-<flavor>`, `Release-<flavor>`, `Profile-<flavor>`. If you name them
   differently (e.g., `Dev-Debug` instead of `Debug-dev`), Flutter will not find
   them.

3. **Missing Profile configurations**: Forgetting to create `Profile-<flavor>`
   configurations causes `flutter run --profile --flavor <x>` to fail silently
   or fall back to the wrong config.

4. **CocoaPods configuration**: After adding new build configurations, run
   `pod install` again. CocoaPods needs to regenerate its config for each build
   configuration. If you see "Unable to find a specification" errors, this is
   often the cause.

5. **GoogleService-Info.plist location**: iOS does not use source sets like
   Android. You must either:
   - Use a Build Phase script to copy the correct plist, OR
   - Use `--ios-out` with FlutterFire CLI to place it in `ios/flavors/<flavor>/`
     and add a "Copy Files" build phase
   - The plist must end up in the app bundle root as `GoogleService-Info.plist`

6. **Provisioning profiles**: Each bundle ID needs its own provisioning profile
   in Apple Developer Console. Three flavors = three App IDs + three profiles.

7. **Xcode 15+ changes**: If using Xcode 15+, build settings may need the
   `ENABLE_USER_SCRIPT_SANDBOXING = NO` setting for Flutter's build phases to
   work.

### Android-Specific Pitfalls

8. **google-services.json location**: Must be at
   `android/app/src/<flavor>/google-services.json`. The Google Services Gradle
   plugin automatically picks the correct one based on the active flavor.

9. **Flavor dimension mismatch**: If you use libraries that define their own
   `flavorDimensions`, you may get build errors. Use `missingDimensionStrategy`
   in `defaultConfig`:

   ```kotlin
   defaultConfig {
       // ...
       missingDimensionStrategy("someLibraryDimension", "defaultValue")
   }
   ```

10. **applicationIdSuffix vs applicationId**: Use `applicationIdSuffix` (not
    full `applicationId`) so that the base package name is preserved. This
    avoids issues with Firebase and deep links.

### Cross-Platform Pitfalls

11. **Flavor name casing**: Use lowercase flavor names (`dev`, not `Dev`).
    Android requires lowercase product flavor names. iOS scheme names are
    case-sensitive.

12. **--dart-define vs --flavor**: These are separate concerns. `--flavor`
    selects the native build variant. `--dart-define` passes compile-time
    constants to Dart. You can use both together:
    `flutter run --flavor dev --dart-define=API_URL=https://dev.api.com`

13. **FlutterFire CLI "Build configuration" prompt**: When running
    `flutterfire config` with `--flavor`, select "Build configuration" (not
    "Target"). Then select the `Debug-<flavor>` configuration. Selecting wrong
    option causes misconfigured plist/json files.

---

## 7. CI/CD with GitHub Actions

### Build Workflow Example

```yaml
name: Build & Test

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: "3.41.x"
          channel: "stable"
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test

  build-android:
    runs-on: ubuntu-latest
    needs: test
    strategy:
      matrix:
        flavor: [dev, staging, prod]
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: "3.41.x"
          channel: "stable"
      - run: flutter pub get
      - run:
          flutter build apk --flavor ${{ matrix.flavor }} --release -t
          lib/main_${{ matrix.flavor }}.dart
      - uses: actions/upload-artifact@v4
        with:
          name: apk-${{ matrix.flavor }}
          path:
            build/app/outputs/flutter-apk/app-${{ matrix.flavor }}-release.apk

  build-ios:
    runs-on: macos-latest
    needs: test
    strategy:
      matrix:
        flavor: [dev, staging, prod]
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: "3.41.x"
          channel: "stable"
      - run: flutter pub get
      - name: Install CocoaPods
        run: cd ios && pod install
      - run:
          flutter build ios --flavor ${{ matrix.flavor }} --release
          --no-codesign -t lib/main_${{ matrix.flavor }}.dart
      - uses: actions/upload-artifact@v4
        with:
          name: ios-${{ matrix.flavor }}
          path: build/ios/iphoneos/Runner.app

  # For production releases, add signing + deployment steps
  deploy-prod:
    runs-on: macos-latest
    needs: [build-android, build-ios]
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4
      # Add Fastlane, code signing, and store upload steps here
```

### CI/CD Tips

- **Cache Flutter SDK**: Use `subosito/flutter-action` with caching built in.
- **Cache pub dependencies**: Add a cache step for `~/.pub-cache`.
- **iOS signing**: Use Fastlane Match or manual provisioning in CI. Each flavor
  needs its own provisioning profile.
- **Secrets management**: Store `google-services.json` and
  `GoogleService-Info.plist` as GitHub Secrets (base64 encoded) and decode them
  in CI:
  ```yaml
  - name: Decode google-services.json (prod)
    run:
      echo ${{ secrets.GOOGLE_SERVICES_PROD }} | base64 --decode >
      android/app/src/prod/google-services.json
  ```
- **Matrix builds**: Use `strategy.matrix.flavor` to build all flavors in
  parallel.
- **Scheme availability**: Ensure all iOS schemes are "Shared" and committed to
  git under `ios/Runner.xcodeproj/xcshareddata/xcschemes/`.

---

## 8. flutter_flavorizr Assessment

**Source: pub.dev/packages/flutter_flavorizr (v2.4.2, 951 likes)**

### What It Does

Automates all the manual Xcode and Gradle configuration:

- Creates Android `productFlavors` in `build.gradle`
- Creates iOS schemes, configurations, and xcconfig files
- Generates per-flavor app icons
- Sets up per-flavor Firebase config (google-services.json,
  GoogleService-Info.plist)
- Creates launch screens per flavor

### Configuration (pubspec.yaml)

```yaml
flutter_flavorizr:
  flavors:
    dev:
      app:
        name: "StarterKit Dev"
      android:
        applicationId: "com.example.starterkit.dev"
        firebase:
          config: ".firebase/dev/google-services.json"
      ios:
        bundleId: "com.example.starterkit.dev"
        firebase:
          config: ".firebase/dev/GoogleService-Info.plist"

    staging:
      app:
        name: "StarterKit Staging"
      android:
        applicationId: "com.example.starterkit.staging"
        firebase:
          config: ".firebase/staging/google-services.json"
      ios:
        bundleId: "com.example.starterkit.staging"
        firebase:
          config: ".firebase/staging/GoogleService-Info.plist"

    prod:
      app:
        name: "StarterKit"
      android:
        applicationId: "com.example.starterkit"
        firebase:
          config: ".firebase/prod/google-services.json"
      ios:
        bundleId: "com.example.starterkit"
        firebase:
          config: ".firebase/prod/GoogleService-Info.plist"
```

Run: `flutter pub run flutter_flavorizr`

### Prerequisites

- Ruby + Gem + Xcodeproj gem (for iOS/macOS manipulation)
- Works best on a **clean/new** project. Running on existing projects can
  conflict.

### Verdict: When to Use

| Scenario                                  | Recommendation                                                  |
| ----------------------------------------- | --------------------------------------------------------------- |
| New project, want fast setup              | **Use flutter_flavorizr** -- saves hours of Xcode clicking      |
| Existing project with custom Xcode config | **Manual setup** -- flavorizr may overwrite your customizations |
| Need deep understanding of what changed   | **Manual setup** -- you learn the internals                     |
| Team with mixed experience levels         | **Use flutter_flavorizr** -- reproducible setup                 |
| CI/CD heavy workflow                      | **Either** -- both work, but verify flavorizr output in CI      |

**My recommendation for this starter kit**: Use flutter_flavorizr for initial
setup, then own the generated files manually going forward. This gives you the
speed of automation plus the understanding of what was generated.

---

## 9. Testing with Flavors

### Unit and Widget Tests

Unit and widget tests (`flutter test`) do **not** use flavors. They run in a
pure Dart VM without native platform code. This means:

- `flutter test` works without `--flavor`
- Tests cannot detect which flavor is active (no native context)
- Mock your environment configuration in tests instead:

```dart
// test/helpers/test_config.dart
void setupTestEnvironment(Environment env) {
  EnvironmentConfig.current = env;
}

// In tests:
setUp(() {
  setupTestEnvironment(Environment.dev);
});
```

### Integration Tests

Integration tests (`flutter test integration_test/`) run on a real
device/emulator and DO require flavors:

```bash
flutter test integration_test/ --flavor dev -t lib/main_dev.dart
```

### Testing Environment-Specific Behavior

```dart
// Use dependency injection via Riverpod to swap configs in tests
final apiBaseUrlProvider = Provider<String>((ref) {
  switch (EnvironmentConfig.current) {
    case Environment.dev:
      return 'https://dev-api.example.com';
    case Environment.staging:
      return 'https://staging-api.example.com';
    case Environment.prod:
      return 'https://api.example.com';
  }
});

// In tests, override the provider:
final container = ProviderContainer(
  overrides: [
    apiBaseUrlProvider.overrideWithValue('https://test-api.example.com'),
  ],
);
```

### VS Code Launch Configurations

Add to `.vscode/launch.json` for easy flavor-based debugging:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Dev",
      "request": "launch",
      "type": "dart",
      "program": "lib/main_dev.dart",
      "args": ["--flavor", "dev"]
    },
    {
      "name": "Staging",
      "request": "launch",
      "type": "dart",
      "program": "lib/main_staging.dart",
      "args": ["--flavor", "staging"]
    },
    {
      "name": "Prod",
      "request": "launch",
      "type": "dart",
      "program": "lib/main_prod.dart",
      "args": ["--flavor", "prod"]
    }
  ]
}
```

---

## 10. Per-Flavor Environment Variables and Configuration

### Recommended Pattern: Flavor-Aware AppConfig

Replace the current `--dart-define` approach with flavor-aware configuration:

```dart
// lib/config/environment.dart
enum Environment { dev, staging, prod }

class EnvironmentConfig {
  static late Environment current;

  // Determine environment from the flavor name passed at build time
  static void init() {
    const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
    current = Environment.values.firstWhere(
      (e) => e.name == flavor,
      orElse: () => Environment.dev,
    );
  }
}
```

```dart
// lib/config/app_config.dart
class AppConfig {
  static String get appName {
    switch (EnvironmentConfig.current) {
      case Environment.dev:
        return 'StarterKit Dev';
      case Environment.staging:
        return 'StarterKit Staging';
      case Environment.prod:
        return 'StarterKit';
    }
  }

  static String get apiBaseUrl {
    switch (EnvironmentConfig.current) {
      case Environment.dev:
        return 'https://dev-api.example.com';
      case Environment.staging:
        return 'https://staging-api.example.com';
      case Environment.prod:
        return 'https://api.example.com';
    }
  }

  static bool get enableDebugBanner =>
      EnvironmentConfig.current != Environment.prod;

  static bool get enableVerboseLogging =>
      EnvironmentConfig.current == Environment.dev;

  // Feature flags can vary by environment
  static bool get enablePaywall =>
      EnvironmentConfig.current == Environment.prod;
}
```

### Alternative: Multiple Entry Points (Preferred for Firebase)

With the multiple entry points pattern from section 3c, each
`main_<flavor>.dart` can set the environment explicitly:

```dart
// lib/main_dev.dart
import 'firebase_options_dev.dart';
import 'config/environment.dart';
import 'main_common.dart';

void main() {
  EnvironmentConfig.current = Environment.dev;
  runMainApp(DefaultFirebaseOptions.currentPlatform);
}
```

This is more explicit and avoids relying on `--dart-define` for the flavor name.

### Combining --flavor with --dart-define

You can still use `--dart-define` for secrets that should not be committed:

```bash
flutter run \
  --flavor dev \
  -t lib/main_dev.dart \
  --dart-define=REVENUECAT_APPLE_KEY=appl_xxx \
  --dart-define=REVENUECAT_GOOGLE_KEY=goog_xxx
```

Or use `--dart-define-from-file` for multiple values:

```bash
flutter run \
  --flavor dev \
  -t lib/main_dev.dart \
  --dart-define-from-file=config/dev.env
```

Where `config/dev.env` contains:

```
REVENUECAT_APPLE_KEY=appl_xxx
REVENUECAT_GOOGLE_KEY=goog_xxx
SENTRY_DSN=https://xxx@sentry.io/xxx
```

Add `config/*.env` to `.gitignore`.

---

## Summary: Migration Path for This Starter Kit

The current project uses `--dart-define=ENV=dev|staging|prod` for environment
selection. To migrate to proper flavors:

1. **Android**: Add `productFlavors` to `build.gradle.kts` (section 1)
2. **iOS**: Create schemes + configurations in Xcode (section 2)
3. **Firebase**: Run `flutterfire-config.sh all` to generate per-flavor configs
   (section 3)
4. **Entry points**: Create `main_dev.dart`, `main_staging.dart`,
   `main_prod.dart` (section 3c)
5. **App config**: Update `environment.dart` and `app_config.dart` (section 10)
6. **Commands**: Change from `flutter run --dart-define=ENV=dev` to
   `flutter run --flavor dev -t lib/main_dev.dart`
7. **CI/CD**: Update GitHub Actions workflows (section 7)
8. **VS Code**: Add launch configurations (section 9)

This gives you proper native-level isolation (different bundle IDs, different
Firebase projects, different app icons) rather than just Dart-level environment
switching.
