# Design: Flutter + Firebase Starter Kit

**Date:** 2026-03-06
**Status:** Approved

---

## Tech Stack

| Layer            | Technology                                         | Rationale                                                      |
| ---------------- | -------------------------------------------------- | -------------------------------------------------------------- |
| Framework        | Flutter                                            | Cross-platform iOS/Android, compiled to native ARM             |
| Language         | Dart                                               | Type-safe, strong async support                                |
| State Management | Riverpod                                           | Compile-safe, testable, excellent async/stream handling        |
| Navigation       | GoRouter                                           | Declarative routing, deep linking, redirect guards             |
| Backend          | Firebase (Auth, Firestore, Cloud Functions, FCM)   | Mature Flutter SDK, built-in offline persistence, fast to ship |
| Payments         | RevenueCat                                         | Best-in-class subscription management for mobile               |
| Local Storage    | shared_preferences + Firestore offline persistence | No custom sync engine needed                                   |

## Architecture

Feature-folder structure. Each feature is self-contained and deletable.

```
flutter_starter_kit/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── config/
│   │   ├── app_config.dart          # App name, bundle ID, feature flags
│   │   ├── theme.dart               # ThemeData, colors, fonts, light/dark
│   │   └── environment.dart         # Dev/staging/prod Firebase config
│   ├── features/
│   │   ├── auth/
│   │   │   ├── screens/
│   │   │   ├── providers/
│   │   │   └── services/
│   │   ├── onboarding/
│   │   │   ├── screens/
│   │   │   ├── providers/
│   │   │   └── widgets/
│   │   ├── paywall/
│   │   │   ├── screens/
│   │   │   ├── providers/
│   │   │   └── services/
│   │   ├── settings/
│   │   │   ├── screens/
│   │   │   └── providers/
│   │   └── notifications/
│   │       ├── providers/
│   │       └── services/
│   ├── routing/
│   │   └── router.dart              # GoRouter config, auth guards
│   └── shared/
│       └── services/
│           └── firebase_service.dart # Firebase initialization
├── test/
├── pubspec.yaml
├── firebase.json
└── README.md
```

## Auth System

- **Sign-in methods:** Apple Sign-In + Google Sign-In only (no email/password)
- Social auth covers 100% of users on both platforms
- Firebase Auth handles OAuth flows
- User profile stored in Firestore at `users/{uid}`:
  - `displayName`, `email`, `photoUrl`, `createdAt`, `onboardingComplete`
- Delete account: Firebase Auth deletion + Firestore profile deletion + RevenueCat cleanup
- GoRouter auth guard redirects unauthenticated users to auth screen

## Onboarding

- Starter kit provides the skeleton: PageView, progress indicator (dots), skip/next/done buttons
- Persists `onboardingComplete: true` to user's Firestore profile
- GoRouter guard checks this flag — completed users skip onboarding
- Each app provides its own screen widgets for each step
- Starter kit includes 3 placeholder screens as examples

## Paywall & Subscriptions

- RevenueCat SDK initialized in `main.dart`
- RevenueCat user identity linked to Firebase Auth UID on sign-in
- `SubscriptionProvider` (Riverpod) exposes current entitlements
- Template paywall screen with configurable product list
- `isPremium` check available anywhere via provider
- Restore purchases wired in settings
- Each app defines its own products/tiers in RevenueCat's dashboard
- No server-side receipt validation needed — RevenueCat handles it

## Settings Screen

Pre-built items:

| Setting                  | Implementation                                                                      |
| ------------------------ | ----------------------------------------------------------------------------------- |
| Dark mode toggle         | shared_preferences + ThemeMode Riverpod provider                                    |
| Notification preferences | Toggle push notifications, FCM token register/unregister                            |
| Subscription management  | Current plan display, RevenueCat manage subscription flow                           |
| Restore purchases        | `Purchases.restorePurchases()`                                                      |
| About / Legal            | App version, privacy policy link, terms of service link (configurable URLs)         |
| Sign out                 | Firebase Auth sign-out, clear local state, redirect to auth screen                  |
| Delete account           | Confirmation dialog, Firestore deletion, Firebase Auth deletion, RevenueCat cleanup |

Material 3 ListTile widgets grouped into sections. Each app can add app-specific settings.

## Push Notifications (FCM)

Fully wired in the starter kit:

- Firebase Messaging SDK initialized in `main.dart`
- Permission request flow on first launch (iOS)
- FCM token registration — saved to user's Firestore profile
- Foreground handler — in-app banner
- Background handler — system notification
- Tap routing — navigates to configurable screen via GoRouter deep linking
- Token refresh listener — updates Firestore when token rotates

Each app defines what to send, when, and which screen each notification type routes to.

## Navigation (GoRouter)

Route hierarchy:

```
/ (redirect based on auth + onboarding state)
├── /auth          (sign-in screen)
├── /onboarding    (onboarding flow)
├── /home          (shell route with bottom nav)
│   ├── /home/tab1
│   ├── /home/tab2
│   └── /home/tab3
└── /settings      (settings screen)
```

Guard logic (in order):

1. Not authenticated -> `/auth`
2. Authenticated but onboarding incomplete -> `/onboarding`
3. Authenticated + onboarding complete -> `/home`

Shell route with configurable bottom navigation bar (tab count, icons, labels per app). Deep linking support for push notification routing.

## Config & Environment

Three files each app overrides:

**`app_config.dart`** — App identity and feature flags:

- App name, bundle ID
- RevenueCat API keys (iOS/Android)
- Privacy policy and terms URLs
- Bottom nav tab count
- Feature flags (enablePaywall, enableNotifications)

**`environment.dart`** — Firebase config per environment:

- Dev, staging, prod Firebase projects
- Selected via `--dart-define=ENV=dev` at build time
- Uses FlutterFire CLI generated options files

**`theme.dart`** — Visual identity:

- Material 3 `ColorScheme.fromSeed()` from a single seed color
- Font family
- Light theme (default) and dark theme
- Dark mode is opt-in via settings toggle

## Theming

- Default theme: light mode
- Dark mode available via settings toggle, persisted in shared_preferences
- Material 3 design system — lean on built-in components (buttons, cards, inputs, typography)
- No custom component library — premature until patterns emerge across multiple apps

## What's Excluded (Added Per-App)

- AI chat infrastructure
- Sync engine / offline-first data layer beyond Firestore's built-in
- Analytics / error tracking
- App-specific screens, models, content
- Custom animations
- App-specific color palettes (override theme.dart)

## The Promise

Clone -> edit 3 config files (app_config, environment, theme) -> start building features.
