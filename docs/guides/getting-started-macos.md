# Getting Started on macOS

This guide walks a new developer through the exact steps needed to run the
starter kit locally and connect it to real backend services.

The guide assumes:

- You are developing on macOS
- You want to run the app on iOS and Android
- You are new to this codebase
- You are comfortable copying commands into Terminal, but not necessarily deeply
  familiar with Flutter or Firebase yet

## 1. Install Your Local Tooling

Before touching the project, make sure your machine can build Flutter apps.

### Required tools

- Flutter SDK
- Xcode
- Xcode command-line tools
- CocoaPods
- Android Studio
- Java SDK compatible with your Android toolchain
- Firebase CLI
- FlutterFire CLI

### Flutter and Apple tooling

Follow Flutter's official macOS installation docs:

- [Install Flutter](https://docs.flutter.dev/install)
- [Set up iOS development on macOS](https://docs.flutter.dev/platform-integration/ios/install-ios/install-ios-from-macos)

Useful verification commands:

```bash
flutter --version
flutter doctor -v
```

If Xcode is installed but not configured yet, Flutter's docs currently
recommend:

```bash
sudo sh -c 'xcode-select -s /Applications/Xcode.app/Contents/Developer && xcodebuild -runFirstLaunch'
sudo xcodebuild -license
```

If you are on Apple Silicon and do not already have Rosetta installed:

```bash
sudo softwareupdate --install-rosetta --agree-to-license
```

### CocoaPods

Flutter plugins still commonly rely on CocoaPods for iOS dependency
installation.

Install or update CocoaPods before you run the app.

### Android Studio

Install Android Studio and open the SDK Manager once so you can install:

- Android SDK
- Android SDK Command-line Tools
- Android platform tools
- At least one emulator image

Then verify Flutter can see your devices:

```bash
flutter devices
```

## 2. Clone the Repository

```bash
git clone <your-fork-or-repo-url> mobile-starter-kit
cd mobile-starter-kit
```

Install Dart and Flutter dependencies:

```bash
flutter pub get
```

At this point, do not expect the app to run successfully yet. It still needs
Firebase, authentication providers, and subscription configuration.

## 3. Read the Three Core Config Files

Before wiring third-party services, understand the files you are expected to
edit:

- `lib/config/app_config.dart`
- `lib/config/environment.dart`
- `lib/config/theme.dart`

You will come back to these after the external services are set up.

For a field-by-field reference, see
[Configuration Reference](../reference/configuration-reference.md).

## 4. Create the Firebase Project

Create a Firebase project that will back your local copy of the starter kit.

### In Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/).
2. Create a new project.
3. Decide whether you want Google Analytics enabled. It is optional for this
   starter kit.
4. Inside the project, create:
   - One iOS app
   - One Android app

Use a bundle identifier and Android application ID that match the app you plan
to ship. The template currently uses placeholder identifiers, so you will likely
change them later.

### Enable Firebase products used by this starter kit

Turn on:

- Authentication
- Cloud Firestore
- Cloud Messaging

For Firestore, if you are just getting started locally, you can create the
database in test mode first so the app can run. Do not ship open rules to
production.

## 5. Install Firebase CLI and FlutterFire CLI

Install the Firebase CLI:

```bash
npm install -g firebase-tools
firebase login
```

Activate the FlutterFire CLI:

```bash
dart pub global activate flutterfire_cli
```

If the activation path is not already in your shell path, add it:

```bash
export PATH="$PATH":"$HOME/.pub-cache/bin"
```

You may want to add that line to your `~/.zprofile` or `~/.zshrc`.

## 6. Connect This App to Firebase

FlutterFire's current official setup flow is documented here:

- [Add Firebase to your Flutter app](https://firebase.google.com/docs/flutter/setup)

Run this from the repository root:

```bash
flutterfire configure
```

Choose your Firebase project and select at least:

- `ios`
- `android`

This generates a `lib/firebase_options.dart` file and updates some platform
configuration.

## 7. Wire `firebase_options.dart` Into the Starter Kit

The starter kit currently initializes Firebase like this:

```dart
await Firebase.initializeApp();
```

That keeps the template lightweight, but most real apps should use the generated
FlutterFire options file instead.

Update `lib/shared/services/firebase_service.dart` to this:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_starter_kit/firebase_options.dart';

class FirebaseService {
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}
```

Why this matters:

- It makes the project portable across environments
- It matches FlutterFire's official generated setup
- It avoids relying on implicit native-only configuration

## 8. Enable Google and Apple Sign-In in Firebase Auth

The auth service in this starter kit supports:

- Google sign-in
- Apple sign-in

The current Firebase-auth docs for Flutter are here:

- [Federated identity and social sign-in for Flutter](https://firebase.google.com/docs/auth/flutter/federated-auth)

### Google sign-in setup

In Firebase Console:

1. Open `Authentication`.
2. Open the `Sign-in method` tab.
3. Enable `Google`.

Then finish the platform-specific setup:

- For Android, add your app's SHA-1 and SHA-256 fingerprints in Firebase.
- For iOS, make sure your app's iOS configuration is correct and that Google
  Sign-In requirements are satisfied.

Important note:

Google sign-in setup details can change over time. After enabling the provider,
verify the latest platform-specific steps in the official docs before shipping.

### Apple sign-in setup

In Firebase Console:

1. Open `Authentication`.
2. Open the `Sign-in method` tab.
3. Enable `Apple`.

You will also need Apple-side setup:

1. Join the Apple Developer Program.
2. Open Apple's Certificates, Identifiers & Profiles area.
3. Enable `Sign In with Apple` for your app identifier.
4. In Xcode, add the `Sign in with Apple` capability to the iOS target.

Reference:

- [Authenticate Using Apple with Firebase](https://firebase.google.com/docs/auth/ios/apple)

## 9. Create the Firestore `users` Collection Shape

The starter kit expects a `users/{uid}` document with fields such as:

- `displayName`
- `email`
- `photoUrl`
- `onboardingComplete`
- `createdAt`
- `fcmToken` (optional, added later by notifications)

You do not need to pre-create the collection manually. The starter kit writes
user documents when you integrate sign-in and profile creation in your app flow.

What you should do now:

- Make sure Firestore is enabled
- Decide on development and production security rules
- Plan how you want onboarding state to be enforced in routing

## 10. Configure RevenueCat

This starter kit initializes RevenueCat automatically when
`AppConfig.enablePaywall` is `true`.

You need to:

1. Create a RevenueCat account and project.
2. Add your iOS and Android apps in RevenueCat.
3. Create an entitlement named `premium` or change the code and docs to match
   your preferred entitlement ID.
4. Create products in App Store Connect and Google Play.
5. Attach those store products to the RevenueCat entitlement.
6. Create a default offering with packages.
7. Copy the public SDK keys into `lib/config/app_config.dart`.

Use the dedicated guide for the full flow:

- [RevenueCat Setup](./revenuecat-setup.md)

Reference docs:

- [RevenueCat Flutter SDK installation](https://www.revenuecat.com/docs/getting-started/installation/flutter)
- [RevenueCat SDK quickstart](https://www.revenuecat.com/docs/getting-started/quickstart)

## 11. Configure Firebase Cloud Messaging

This starter kit requests notification permission and starts listening for
tokens and message events, but you still need to finish platform setup.

### iOS notification setup

Per the current official FCM Flutter docs:

1. Open `ios/Runner.xcworkspace` in Xcode.
2. Enable `Push Notifications`.
3. Enable `Background Modes`.
4. Turn on:
   - `Background fetch`
   - `Remote notifications`
5. Upload an APNs authentication key to Firebase Console.

Reference:

- [Get started with Firebase Cloud Messaging in Flutter apps](https://firebase.google.com/docs/cloud-messaging/flutter/get-started)

### Android notification setup

Android usually needs less manual setup than iOS, but you should still verify:

- Your Firebase Android app is registered correctly
- The generated Firebase configuration is present
- Test devices are working

## 12. Replace the Placeholder App Configuration

Open `lib/config/app_config.dart` and replace the placeholder values:

- `appName`
- `bundleId`
- `revenueCatAppleApiKey`
- `revenueCatGoogleApiKey`
- `privacyPolicyUrl`
- `termsOfServiceUrl`

Also decide whether you want these feature flags enabled immediately:

- `enablePaywall`
- `enableNotifications`

For your first local run, it is reasonable to temporarily disable a feature if
its third-party setup is not finished yet.

## 13. Choose Your Environment

The app supports a simple `ENV` define with:

- `dev`
- `staging`
- `prod`

Run locally with:

```bash
flutter run --dart-define=ENV=dev
```

## 14. Run the App

### iOS Simulator

Start the iOS simulator:

```bash
open -a Simulator
```

Then run:

```bash
flutter run --dart-define=ENV=dev
```

### Android Emulator

Start an emulator from Android Studio, then run:

```bash
flutter run --dart-define=ENV=dev
```

## 15. Verify the Starter Flows

Once the app boots, check these flows in order:

1. The auth screen renders
2. Google sign-in starts correctly
3. Apple sign-in is available on iOS
4. The settings screen can toggle dark mode
5. The paywall opens without crashing
6. Firestore can store and retrieve a user profile
7. Notifications permission prompt appears on iOS if enabled

## 16. Run Local Quality Checks

Before you start editing the template, verify the current repo passes:

```bash
flutter analyze
flutter test
```

## 17. Known Gaps You Should Plan to Address

This project is a strong starting point, but a real product will usually need
these follow-up tasks:

- Replace placeholder copy and screens
- Finish onboarding routing based on persisted user profile state
- Add production-ready Firestore security rules
- Add analytics, error reporting, and crash reporting
- Decide how you want environments and secrets managed
- Add deep link handling for notifications
- Harden purchase error handling and subscription lifecycle management

## Quick Troubleshooting

### `flutter doctor` shows Xcode issues

Fix the Xcode setup first. Flutter iOS builds are unreliable until
`flutter doctor -v` is clean enough to build.

### `Firebase.initializeApp()` fails

Most often this means one of these is true:

- `flutterfire configure` was not run
- `firebase_options.dart` was not wired in
- The selected Firebase project does not match the app identifiers

### Google sign-in opens but fails

Usually this points to provider configuration:

- Google provider not enabled in Firebase Auth
- Missing SHA fingerprints for Android
- Incomplete iOS Google Sign-In setup

### RevenueCat returns no offerings

Usually this means:

- The public SDK keys are still placeholders
- No current offering exists
- The products are not attached to the `premium` entitlement
- Store-side products are not fully configured yet

### Notifications do nothing

The starter kit currently initializes FCM and logs events, but it does not yet
present custom in-app banners or navigate users based on notification payloads.
