# Current State Research Report

Generated: 2026-03-07

---

## 1. Provider Inventory (Riverpod Codegen Migration Scope)

All providers use manual declaration (no `@riverpod` annotations, no `.g.dart`
files).

### Feature Providers

| Provider                     | Type                                             | File                                                              | Notes                    |
| ---------------------------- | ------------------------------------------------ | ----------------------------------------------------------------- | ------------------------ |
| `authServiceProvider`        | `Provider<AuthService>`                          | `lib/features/auth/providers/auth_provider.dart`                  | Service singleton        |
| `authStateProvider`          | `StreamProvider<User?>`                          | `lib/features/auth/providers/auth_provider.dart`                  | Wraps `authStateChanges` |
| `userProfileServiceProvider` | `Provider<UserProfileService>`                   | `lib/features/auth/providers/user_profile_provider.dart`          | Service singleton        |
| `userProfileProvider`        | `StreamProvider<UserProfile?>`                   | `lib/features/auth/providers/user_profile_provider.dart`          | Watches authState        |
| `fcmServiceProvider`         | `Provider<FcmService>`                           | `lib/features/notifications/providers/notification_provider.dart` | Service singleton        |
| `onboardingProvider`         | `NotifierProvider<OnboardingNotifier, int>`      | `lib/features/onboarding/providers/onboarding_provider.dart`      | Page index notifier      |
| `purchasesServiceProvider`   | `Provider<PurchasesService>`                     | `lib/features/paywall/providers/purchases_provider.dart`          | Service singleton        |
| `customerInfoProvider`       | `FutureProvider<CustomerInfo>`                   | `lib/features/paywall/providers/purchases_provider.dart`          | Uses `ref.keepAlive()`   |
| `offeringsProvider`          | `FutureProvider<Offerings>`                      | `lib/features/paywall/providers/purchases_provider.dart`          | Uses `ref.keepAlive()`   |
| `packageInfoProvider`        | `FutureProvider<PackageInfo>`                    | `lib/features/settings/providers/package_info_provider.dart`      | Uses `ref.keepAlive()`   |
| `themeModeProvider`          | `NotifierProvider<ThemeModeNotifier, ThemeMode>` | `lib/features/settings/providers/theme_provider.dart`             | Persists to SharedPrefs  |

### Shared Providers

| Provider                         | Type                                   | File                                                     | Notes                                       |
| -------------------------------- | -------------------------------------- | -------------------------------------------------------- | ------------------------------------------- |
| `deleteAccountProvider`          | `FutureProvider<void>`                 | `lib/shared/providers/delete_account_provider.dart`      | 5-step deletion sequence                    |
| `bootstrapHooksProvider`         | `Provider<List<FeatureHook>>`          | `lib/shared/providers/feature_hooks.dart`                | Default empty list                          |
| `signOutHooksProvider`           | `Provider<List<FeatureHook>>`          | `lib/shared/providers/feature_hooks.dart`                | Default empty list                          |
| `deleteAccountHooksProvider`     | `Provider<List<FeatureHook>>`          | `lib/shared/providers/feature_hooks.dart`                | Default empty list                          |
| `restorePurchasesActionProvider` | `Provider<Future<String> Function()?>` | `lib/shared/providers/feature_hooks.dart`                | Default null                                |
| `isPremiumProvider`              | `Provider<bool>`                       | `lib/shared/providers/premium_provider.dart`             | Default false, overridden via ProviderScope |
| `postAuthBootstrapProvider`      | `FutureProvider<void>`                 | `lib/shared/providers/post_auth_bootstrap_provider.dart` | Profile creation + hooks                    |
| `sharedPreferencesProvider`      | `Provider<SharedPreferences>`          | `lib/shared/providers/shared_preferences_provider.dart`  | Throws if not overridden                    |
| `signOutProvider`                | `FutureProvider<void>`                 | `lib/shared/providers/sign_out_provider.dart`            | 5-step sign-out sequence                    |

### Summary by Type

- **Provider**: 9 (service singletons, hooks, isPremium, sharedPrefs,
  restoreAction)
- **StreamProvider**: 2 (authState, userProfile)
- **FutureProvider**: 5 (customerInfo, offerings, packageInfo, deleteAccount,
  signOut, postAuthBootstrap)
- **NotifierProvider**: 2 (onboarding, themeMode)
- **StateProvider / StateNotifierProvider / AsyncNotifierProvider**: 0

**Total: 20 providers to migrate to codegen**

---

## 2. Architectural Violations (shared/ importing features/)

Six import violations across 3 files in `lib/shared/providers/`:

```
delete_account_provider.dart:2  -> features/auth/providers/auth_provider.dart
delete_account_provider.dart:3  -> features/auth/providers/user_profile_provider.dart
post_auth_bootstrap_provider.dart:7  -> features/auth/providers/auth_provider.dart
post_auth_bootstrap_provider.dart:8  -> features/auth/providers/user_profile_provider.dart
sign_out_provider.dart:5  -> features/auth/providers/auth_provider.dart
sign_out_provider.dart:6  -> features/auth/providers/user_profile_provider.dart
```

All 3 shared providers import the same 2 feature providers:
`authServiceProvider`/`authStateProvider` from auth_provider.dart and
`userProfileServiceProvider`/`userProfileProvider` from
user_profile_provider.dart.

**Resolution path**: Move `authServiceProvider`, `authStateProvider`,
`userProfileServiceProvider`, and `userProfileProvider` to
`lib/shared/providers/` since they are effectively shared infrastructure.

---

## 3. pubspec.yaml Dependencies (Exact Versions)

**SDK**: `^3.7.0`

### Production Dependencies

| Package              | Version |
| -------------------- | ------- |
| flutter_riverpod     | ^2.6.1  |
| riverpod_annotation  | ^2.6.1  |
| go_router            | ^14.8.1 |
| firebase_core        | ^3.12.1 |
| firebase_auth        | ^5.5.1  |
| cloud_firestore      | ^5.6.5  |
| firebase_messaging   | ^15.2.4 |
| firebase_crashlytics | ^4.3.2  |
| firebase_analytics   | ^11.4.2 |
| google_sign_in       | ^6.2.2  |
| sign_in_with_apple   | ^7.0.1  |
| purchases_flutter    | ^9.13.1 |
| shared_preferences   | ^2.5.3  |
| url_launcher         | ^6.3.1  |
| package_info_plus    | ^8.2.1  |

### Dev Dependencies

| Package              | Version |
| -------------------- | ------- |
| flutter_lints        | ^5.0.0  |
| mocktail             | ^1.0.4  |
| riverpod_lint        | ^2.6.4  |
| custom_lint          | ^0.7.5  |
| fake_cloud_firestore | ^3.1.0  |

**Missing for codegen**: `riverpod_generator`, `build_runner` (note: todo 004
says build_runner was _removed_ previously)

---

## 4. Firestore Security Rules

**File**: `firestore.rules` (project root)

- Rules version 2
- Single collection: `/users/{uid}`
- Owner-only access (auth.uid == uid)
- Field validation via `validFields()` helper
- Allowed fields: `email`, `displayName`, `photoUrl`, `onboardingComplete`,
  `fcmToken`, `createdAt`
- Type checks: `onboardingComplete` is bool, strings validated, `createdAt` is
  timestamp
- `createdAt` immutability enforced on update
- `email` must match auth token email on create/update
- Delete: owner-only, no additional validation
- Default deny for all other paths

**No rate limiting rules. No admin/service-account paths.**

---

## 5. AndroidManifest.xml

**File**: `android/app/src/main/AndroidManifest.xml`

**`android:allowBackup` is NOT set.** The `<application>` tag has:

- `android:label="flutter_starter_kit"`
- `android:name="${applicationName}"`
- `android:icon="@mipmap/ic_launcher"`

No `android:allowBackup="false"` attribute present. This defaults to `true` on
Android, which is a security concern for apps with sensitive user data.

---

## 6. Environment Configuration

**File**: `lib/config/environment.dart`

```dart
enum Environment { dev, staging, prod }

class EnvironmentConfig {
  static Environment current = Environment.dev;

  static void init() {
    const envString = String.fromEnvironment('ENV', defaultValue: 'dev');
    current = Environment.values.firstWhere(
      (environment) => environment.name == envString,
      orElse: () => Environment.dev,
    );
  }
}
```

- Uses `--dart-define=ENV=dev|staging|prod`
- No flavor support (no separate Firebase config files per environment)
- No per-environment API URLs, Firebase project IDs, or feature flag overrides
- Static mutable state (not Riverpod-managed)

---

## 7. Theme Provider (ThemeMode System Default Gap)

**File**: `lib/features/settings/providers/theme_provider.dart`

The `ThemeModeNotifier.build()` method:

```dart
final isDark = prefs.getBool(_key) ?? false;
return isDark ? ThemeMode.dark : ThemeMode.light;
```

**Problem**: `ThemeMode.system` is never used. The default is always
`ThemeMode.light` (isDark defaults to false). The toggle is binary (light/dark),
never three-state. Users cannot follow system theme.

**File**: `lib/config/theme.dart` -- `AppTheme` class provides `light` and
`dark` getters only (no system-aware logic needed there, but `app.dart` would
need `themeMode: ThemeMode.system`).

---

## 8. Hardcoded User-Facing Strings (l10n Migration Scope)

### auth/screens/auth_screen.dart

- `'Sign in to get started'`
- `'Authentication error. Please try again.'`
- `'Something went wrong. Please try again.'` (x2)

### auth/widgets/social_login_buttons.dart

- `'Continue with Apple'`
- `'Continue with Google'`

### onboarding/screens/onboarding_screen.dart

- `'Welcome to AppName'`
- `'Your all-in-one solution for staying organized and productive...'`
- `'Stay on Track'`
- `'Set goals, track your progress, and celebrate your wins...'`
- `'Get Started'` (title and button)
- `'You\'re all set! Dive in and explore everything the app has...'`
- `'Skip'`
- `'Next'`

### onboarding/widgets/progress_dots.dart

- `'Page ${current + 1} of $total'` (semantic label)

### settings/screens/settings_screen.dart

- `'Settings'`, `'Appearance'`, `'Dark Mode'`
- `'Subscription'`, `'Current Plan'`, `'Premium'`, `'Free'`
- `'Restore Purchases'`, `'Something went wrong. Please try again.'`
- `'About'`, `'Privacy Policy'`, `'Terms of Service'`
- `'Account'`, `'Sign Out'`, `'Delete Account'`
- `'This will permanently delete your account and all data. This action cannot be undone.'`
- `'Cancel'`, `'Delete'`
- `'Please sign in again to continue.'`,
  `'Authentication error. Please try again.'`

### home/screens/home_screen.dart

- `'Home'` (nav label), `'Profile'` (nav label)
- `'Home Screen - replace with your app content'`

### profile/screens/profile_screen.dart

- `'Profile'`
- `'No profile data'`
- `'Something went wrong. Please try again.'`

### paywall/screens/paywall_screen.dart

- `'Unlock Premium'`, `'Get access to all features'`
- `'Basic Access'`, `'Premium Feature 1'`, `'Premium Feature 2'`
- `'Loading...'`, `'Subscribe - ${package.storeProduct.priceString}'`
- `'Unable to load offerings. Please try again.'`
- `'Purchases restored!'`
- `'Restore Purchases'`

### paywall/widgets/feature_comparison_row.dart

- `'Free'`, `'Premium'` (column headers, likely)

**Estimated total: ~50+ unique user-facing strings across 10 files.**

---

## 9. Settings Screen Structure (Profile vs Settings Split)

**File**: `lib/features/settings/screens/settings_screen.dart`

Current sections in settings:

1. **Appearance** -- Dark Mode toggle
2. **Subscription** (conditional on `AppConfig.enablePaywall`) -- Current Plan,
   Restore Purchases
3. **About** -- Privacy Policy, Terms of Service (external links)
4. **Account** -- Sign Out, Delete Account
5. **Version info** at bottom (from packageInfoProvider)

**File**: `lib/features/profile/screens/profile_screen.dart`

Current profile screen shows: avatar, display name, email. Settings gear icon in
AppBar navigates to settings.

**Potential split**:

- Profile screen could absorb: theme preference, subscription status display
- Settings stays: legal links, sign out, delete account, version info

---

## 10. Todos Directory Contents

**Path**:
`/Users/robertguss/Projects/github/flutter-firebase-starter-kit/todos/`

25 completed todo files (all prefixed `complete`):

| #   | Priority | Title                                          |
| --- | -------- | ---------------------------------------------- |
| 001 | P1       | Bootstrap provider never watched               |
| 002 | P2       | Onboarding screen direct service instantiation |
| 003 | P2       | Onboarding provider not invalidated on signout |
| 004 | P2       | Remove build-runner riverpod generator         |
| 005 | P2       | Firestore rules type validation gaps           |
| 006 | P2       | SignOut provider no error handling             |
| 007 | P2       | Delete account provider caches failures        |
| 008 | P3       | Home screen test only one widget test          |
| 009 | P3       | Cleanup widget test and CLAUDE.md              |
| 010 | P3       | FCM message data logging                       |
| 011 | P3       | Unused price card widget                       |
| 012 | P1       | Features not independently deletable           |
| 013 | P2       | Customer info provider goes stale              |
| 014 | P2       | App root rebuilds too broadly                  |
| 015 | P2       | Sign-in buttons lack double-tap protection     |
| 016 | P2       | Google sign-out incomplete                     |
| 017 | P2       | Duplicated sign-in logic                       |
| 018 | P2       | Inconsistent error handling patterns           |
| 019 | P2       | Feature flags compile-time only                |
| 020 | P2       | Package info provider misplaced                |
| 021 | P2       | createdAt overwritten on every sign-in         |
| 022 | P2       | Account deletion no subcollection cascade      |
| 023 | P3       | Mock classes redeclared across tests           |
| 024 | P3       | Dead code and minor simplifications            |
| 025 | P3       | Auth change notifier fires too often           |

**All 25 are marked complete.** No open todos remain.
