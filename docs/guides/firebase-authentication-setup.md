# Firebase and Authentication Setup

This guide explains how to configure Firebase for this starter kit and wire up
Google and Apple sign-in.

Use this guide if:

- You already ran the general getting-started flow and want more detail
- You are stuck on authentication setup
- You want to understand what parts are Firebase Console work versus code work

## Starter Kit Expectations

The codebase currently expects:

- Firebase Core
- Firebase Auth
- Cloud Firestore
- Firebase Cloud Messaging
- Google sign-in
- Apple sign-in

Relevant files:

- `lib/shared/services/firebase_service.dart`
- `lib/features/auth/services/auth_service.dart`
- `lib/features/auth/services/user_profile_service.dart`
- `lib/features/notifications/services/fcm_service.dart`

## 1. Create a Firebase Project

In [Firebase Console](https://console.firebase.google.com/):

1. Create a project.
2. Add an iOS app.
3. Add an Android app.
4. Enable:
   - Authentication
   - Cloud Firestore
   - Cloud Messaging

## 2. Configure FlutterFire

Official reference:

- [Add Firebase to your Flutter app](https://firebase.google.com/docs/flutter/setup)

From the repo root:

```bash
flutterfire configure
```

This should generate `lib/firebase_options.dart`.

## 3. Update Firebase Initialization

The starter template currently initializes Firebase without generated options.

For a production app, update `lib/shared/services/firebase_service.dart` to use:

```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

That requires:

- importing `firebase_options.dart`
- regenerating that file whenever your Firebase app configuration changes

## 4. Enable Google Sign-In

Official reference:

- [Federated identity and social sign-in for Flutter](https://firebase.google.com/docs/auth/flutter/federated-auth)

In Firebase Console:

1. Open `Authentication`.
2. Open `Sign-in method`.
3. Enable `Google`.

Also complete platform-specific setup:

### Android

- Add your Android app's SHA-1 fingerprint
- Add your Android app's SHA-256 fingerprint
- Re-run `flutterfire configure` if needed afterward

### iOS

- Verify the iOS Firebase app matches your bundle identifier
- Verify Google Sign-In requirements in the current Firebase docs

## 5. Enable Apple Sign-In

Official references:

- [Federated identity and social sign-in for Flutter](https://firebase.google.com/docs/auth/flutter/federated-auth)
- [Authenticate Using Apple with Firebase](https://firebase.google.com/docs/auth/ios/apple)

### Firebase side

1. Open `Authentication`.
2. Open `Sign-in method`.
3. Enable `Apple`.

### Apple side

1. Enroll in the Apple Developer Program.
2. Open Certificates, Identifiers & Profiles.
3. Enable `Sign In with Apple` on your app identifier.
4. In Xcode, add the `Sign in with Apple` capability to the iOS app target.

## 6. Create Firestore Data for Users

The starter kit writes user data into:

- `users/{uid}`

The profile service currently creates and updates fields such as:

- `displayName`
- `email`
- `photoUrl`
- `onboardingComplete`
- `createdAt`
- `fcmToken`

Recommended next step:

- Define security rules before real user testing beyond local experiments

## 7. Finish Notification Setup

Official reference:

- [Get started with Firebase Cloud Messaging in Flutter apps](https://firebase.google.com/docs/cloud-messaging/flutter/get-started)

### iOS

In Xcode:

1. Open `ios/Runner.xcworkspace`
2. Enable `Push Notifications`
3. Enable `Background Modes`
4. Turn on:
   - `Background fetch`
   - `Remote notifications`

In Apple Developer + Firebase:

1. Create an APNs auth key
2. Upload it to Firebase Console

### Current starter-kit behavior

`FcmService` currently:

- requests permission
- fetches and logs tokens
- listens for foreground messages
- listens for notification opens

It does not yet:

- render a custom in-app banner
- deep-link into a specific screen based on notification data
- register a background message handler

Document that for your team early, because many developers assume "FCM setup
complete" means "notifications are fully productized."
