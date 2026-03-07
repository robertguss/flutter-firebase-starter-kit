# Brainstorm: Flutter Firebase Starter Kit Improvements

**Date:** 2026-03-07 **Status:** Draft **Goal:** Elevate the starter kit from
"good template" to "production-ready, educational, open-source starter kit"

---

## What We're Building

A systematic improvement plan across four dimensions: architecture, security,
testing, and UX/features. The starter kit serves three audiences: personal rapid
development, open-source community use, and educational reference.

---

## Why This Matters

The current kit has a solid foundation -- feature-folder structure, Riverpod
state management, GoRouter navigation, and Firebase backend. However,
inconsistencies in service patterns, missing security defaults, thin test
coverage, and incomplete UI patterns would trip up users who clone this
expecting production readiness.

---

## Key Decisions

### 1. Navigation: Two working tabs (Home + Profile)

- Demonstrates the `StatefulShellRoute` pattern properly
- Profile tab pulls from Firestore user data, showing a real data flow
- Avoids the current misleading 3-tab setup where only 1 works

### 2. Paywall: Client-side but correct

- Hydrate premium state from RevenueCat `CustomerInfo` on app start
- Replace the simple `StateProvider<bool>` with a derived provider reading from
  `customerInfoProvider`
- Document the server-side webhook approach as an upgrade path
- Rationale: RevenueCat SDK already verifies with Apple/Google servers;
  server-side adds infrastructure complexity inappropriate for a starter kit

### 3. Observability: Add both Crashlytics and Analytics

- Wire `FlutterError.onError` and `PlatformDispatcher.instance.onError` to
  Crashlytics
- Add Firebase Analytics with a few example events (sign_in, purchase,
  onboarding_complete)
- Feature-flag gated like notifications and paywall

### 4. Data models: Manual Dart classes with fromMap/toMap

- Create a `UserProfile` model with type-safe fields
- No code generation (freezed/json_serializable) -- keeps the kit simple and
  educational
- Remove unused `build_runner` and `riverpod_generator` dependencies

### 5. Error handling: Full global handler + error UI

- `runZonedGuarded` wrapping the entire app
- `FlutterError.onError` for widget errors
- `PlatformDispatcher.instance.onError` for platform errors
- Custom error screen widget for graceful degradation
- All wired to Crashlytics in non-debug builds

---

## Improvement Roadmap

### Phase 1: Architecture Fixes (Foundation)

These fix correctness issues that affect every user of the kit.

| #   | Issue                                                                         | Fix                                                                                                                            | Priority |
| --- | ----------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ | -------- |
| A1  | Router recreates GoRouter on auth changes, resetting nav stack                | Use `refreshListenable` with a `ChangeNotifier` bridge instead of rebuilding                                                   | Critical |
| A2  | Inconsistent service instantiation (some providers, some direct, some static) | Create Riverpod providers for all services; convert `PurchasesService` from static to instance methods; inject via constructor | Critical |
| A3  | Bottom nav is non-functional (3 tabs, only 1 works)                           | Implement `StatefulShellRoute` with Home + Profile tabs                                                                        | High     |
| A4  | Theme provider race condition (light flash on startup)                        | Initialize SharedPreferences in `main()`, pass to provider; or use `AsyncNotifierProvider`                                     | High     |
| A5  | Premium state not restored on cold start                                      | Derive `isPremiumProvider` from `customerInfoProvider` instead of manual `StateProvider<bool>`                                 | High     |
| A6  | No UserProfile data model (raw maps everywhere)                               | Create `UserProfile` class with `fromMap`/`toMap`, add `userProfileProvider`                                                   | High     |
| A7  | `FcmService` crosses feature boundaries (writes to users collection)          | Delegate token storage to `UserProfileService` or inject Firestore via constructor                                             | Medium   |
| A8  | `EnvironmentConfig` is initialized but never used                             | Wire it into Firebase config selection, log levels, and API endpoints                                                          | Medium   |
| A9  | `SocialLoginButtons` uses `dart:io` Platform (breaks web)                     | Use `defaultTargetPlatform` instead                                                                                            | Low      |

### Phase 2: Security Hardening

These prevent real vulnerabilities for anyone deploying apps from this kit.

| #   | Issue                                                                       | Fix                                                                                         | Priority |
| --- | --------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------- | -------- |
| S1  | No Firestore security rules                                                 | Add `firestore.rules` -- users can only read/write own `/users/{uid}` doc, field validation | Critical |
| S2  | Account deletion order is unsafe (data deleted before auth, which can fail) | Re-authenticate first, delete auth account, then clean up Firestore                         | Critical |
| S3  | RevenueCat API keys designed to be hardcoded                                | Move to `--dart-define` or `.env` file (gitignored), document clearly                       | High     |
| S4  | `.gitignore` missing Firebase config exclusions                             | Add `google-services.json`, `GoogleService-Info.plist`, `firebase_options.dart`, `.env`     | High     |
| S5  | Raw error messages shown to users (`error.toString()`)                      | Map known exceptions to user-friendly messages; log full errors internally                  | Medium   |
| S6  | Sign-out doesn't clear RevenueCat session                                   | Call `PurchasesService.logout()` during sign-out                                            | Medium   |
| S7  | RevenueCat debug logging enabled unconditionally                            | Conditional log level based on `EnvironmentConfig.current`                                  | Medium   |
| S8  | FCM token printed to console                                                | Remove or use structured logger                                                             | Low      |

### Phase 3: Testing Foundation

These ensure the kit demonstrates proper testing patterns.

| #   | Issue                                        | Fix                                                                                        | Priority |
| --- | -------------------------------------------- | ------------------------------------------------------------------------------------------ | -------- |
| T1  | Router redirect logic completely untested    | Add tests: unauth -> /auth redirect, auth on /auth -> /home redirect                       | Critical |
| T2  | Zero exception/error tests in entire suite   | Add error path tests for sign-in cancellation, Firestore failures, delete account failures | High     |
| T3  | Zero widget tests for any screen             | Add widget tests for AuthScreen, HomeScreen, SettingsScreen                                | High     |
| T4  | Notifications feature has zero coverage      | Add FcmService tests (requires constructor injection fix from A2)                          | Medium   |
| T5  | PurchasesService untestable (static methods) | Convert to instance methods, add tests (depends on A2)                                     | Medium   |
| T6  | Shared widgets untested                      | Add tests for `PremiumGate` and `LoadingState`                                             | Medium   |
| T7  | `mockito` in dev deps but never used         | Remove it                                                                                  | Low      |

### Phase 4: UX & Feature Polish

These make the kit feel production-ready and demonstrate best practices.

| #   | Issue                                                         | Fix                                                                                    | Priority |
| --- | ------------------------------------------------------------- | -------------------------------------------------------------------------------------- | -------- |
| U1  | No global error handling                                      | Add `runZonedGuarded` + error handlers + custom error screen, wire to Crashlytics      | Critical |
| U2  | Add Firebase Crashlytics                                      | Integrate crashlytics package, wire to global error handler                            | High     |
| U3  | Add Firebase Analytics                                        | Add analytics package, example events for key flows                                    | High     |
| U4  | `flutter_animate` imported but never used                     | Either use it (add entrance animations to onboarding, screen transitions) or remove it | Medium   |
| U5  | No empty states or skeleton loading                           | Add reusable `EmptyState` and `SkeletonLoader` shared widgets                          | Medium   |
| U6  | Missing accessibility: semantic labels, color-only indicators | Add `semanticLabel` to icons, add text labels alongside color indicators               | Medium   |
| U7  | Settings missing app version, feedback link                   | Add version display and feedback/support mechanism                                     | Low      |
| U8  | No offline connectivity indicator                             | Add `connectivity_plus` with a provider and banner widget                              | Low      |
| U9  | Onboarding has placeholder content only                       | Add example content with images/illustrations                                          | Low      |

### Cleanup Tasks

| #   | Task                                                                     |
| --- | ------------------------------------------------------------------------ |
| C1  | Remove unused `mockito` dev dependency                                   |
| C2  | Remove unused `flutter_animate` (or use it)                              |
| C3  | Remove unused `build_runner` and `riverpod_generator` (or use them)      |
| C4  | Fix `app_test.dart` naming (it's a unit test, not widget test)           |
| C5  | Standardize test patterns (`group()` nesting, consistent setUp/tearDown) |

---

## Approach: Phased Implementation

**Phase 1 first** because architecture fixes unblock everything else -- you
can't write proper tests (Phase 3) until services are properly injectable (A2),
and security fixes (Phase 2) depend on correct service patterns.

**Suggested order within phases:**

1. A1 (router) + A2 (service standardization) -- these are the foundation
2. A6 (UserProfile model) + A4 (theme fix) -- quick wins with high impact
3. S1 (Firestore rules) + S2 (account deletion) + S4 (.gitignore) -- security
   essentials
4. U1 (global error handling) + U2 (Crashlytics) -- observability
5. T1-T3 (critical tests) -- validate everything works
6. Remaining items by priority

---

## Resolved Questions

- **Navigation approach:** Two tabs (Home + Profile) using StatefulShellRoute
- **Paywall verification:** Client-side with proper CustomerInfo hydration
- **Observability:** Both Crashlytics and Analytics, feature-flagged
- **Data models:** Manual Dart classes, no code generation
- **Error handling:** Full global handler with custom error UI screen
- **Target audience:** All three (personal, open source, educational)
- **Documentation:** Both inline code comments (explaining "why") and a separate
  docs/ guide (architecture + setup)
- **CI/CD:** No GitHub Actions workflow -- keep the repo focused on Flutter
  code, users add their own CI
- **Onboarding:** Generic example content (e.g., "Welcome to AppName", "Track
  your goals") that demonstrates the pattern while being easy to replace
