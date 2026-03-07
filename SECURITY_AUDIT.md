# Security Audit Report - Flutter Firebase Starter Kit

**Date:** 2026-03-07 **Auditor:** Application Security Specialist **Scope:**
Full codebase review of the starter kit template

---

## Executive Summary

**Overall Risk Rating: LOW-MEDIUM**

This starter kit demonstrates strong security fundamentals for a template
project. The most critical areas -- Firestore rules, API key management,
authentication flow, and gitignore hygiene -- are handled well. The findings
below are mostly Medium and Low severity items that, if left unaddressed, would
propagate to every app built from this template.

---

## Risk Matrix

| #   | Finding                                                                                             | Severity | Category            |
| --- | --------------------------------------------------------------------------------------------------- | -------- | ------------------- |
| 1   | No android:allowBackup="false" in AndroidManifest                                                   | Medium   | Data Protection     |
| 2   | shared_preferences used for non-sensitive data (acceptable) but no flutter_secure_storage available | Medium   | Secure Storage      |
| 3   | No analytics/crashlytics consent gate before collection                                             | Medium   | Privacy/GDPR        |
| 4   | Placeholder legal URLs ship by default                                                              | Medium   | Compliance          |
| 5   | FCM token refresh listener is a no-op                                                               | Low      | Notifications       |
| 6   | No field-level length validation in Firestore rules                                                 | Low      | Input Validation    |
| 7   | No certificate pinning guidance                                                                     | Low      | Network Security    |
| 8   | No ProGuard/R8 obfuscation configuration documented                                                 | Low      | Reverse Engineering |

---

## Detailed Findings

### POSITIVE FINDINGS (What the kit does well)

#### P1. Firestore Security Rules - STRONG

File:
`/Users/robertguss/Projects/github/flutter-firebase-starter-kit/firestore.rules`

- Rules enforce owner-only access (read/write gated on
  `request.auth.uid == uid`)
- Field allowlisting via `hasOnly()` prevents arbitrary field injection
- Type validation on all fields (bool, string, timestamp)
- `createdAt` is immutable on update (prevents timestamp tampering)
- Email must match auth token email (prevents spoofing)
- Default deny for all other collections

#### P2. API Key Management - STRONG

File:
`/Users/robertguss/Projects/github/flutter-firebase-starter-kit/lib/config/app_config.dart`

- RevenueCat keys injected via `--dart-define` (compile-time environment
  variables), not hardcoded
- Default values are empty strings, so forgetting to set them fails safely
- `firebase_options.dart`, `google-services.json`, and
  `GoogleService-Info.plist` are all in `.gitignore`
- No hardcoded secrets, passwords, or private keys found anywhere in `lib/`

#### P3. Authentication Flow - STRONG

File:
`/Users/robertguss/Projects/github/flutter-firebase-starter-kit/lib/features/auth/services/auth_service.dart`

- Google Sign-In properly obtains ID token and access token, then creates
  Firebase credential
- Apple Sign-In uses Firebase's `signInWithProvider(AppleAuthProvider())` -- the
  recommended approach
- Cancelled sign-in throws a clear exception (not silently ignored)
- Account deletion calls `reauthenticate()` before `deleteAccount()` -- correct
  order
- Firestore profile is deleted before auth account (correct sequence to avoid
  orphaned data)
- Auth state is a `StreamProvider` wrapping `authStateChanges` -- reactive and
  secure

#### P4. Router Auth Guard - STRONG

File:
`/Users/robertguss/Projects/github/flutter-firebase-starter-kit/lib/routing/router.dart`

- Global `redirect` function gates all routes behind authentication
- Unauthenticated users redirected to `/auth`
- Authenticated users on `/auth` redirected to `/home`

#### P5. Error Handling - STRONG

File:
`/Users/robertguss/Projects/github/flutter-firebase-starter-kit/lib/main.dart`

- `FlutterError.onError` captures framework errors to Crashlytics
- `PlatformDispatcher.instance.onError` captures async errors
- Crashlytics collection disabled in debug mode (`!kDebugMode`)
- Error messages in UI are generic ("Something went wrong") -- no stack traces
  or internal details leaked

#### P6. No Cleartext Traffic

File:
`/Users/robertguss/Projects/github/flutter-firebase-starter-kit/android/app/src/main/AndroidManifest.xml`

- No `android:usesCleartextTraffic="true"` found
- No `NSAllowsArbitraryLoads` in Info.plist
- All Firebase/RevenueCat SDKs use HTTPS by default

---

### FINDING 1: Missing android:allowBackup="false" [MEDIUM]

**File:**
`/Users/robertguss/Projects/github/flutter-firebase-starter-kit/android/app/src/main/AndroidManifest.xml`

**Issue:** The `<application>` tag does not set `android:allowBackup="false"`.
On Android, this defaults to `true`, allowing `adb backup` to extract app data
including SharedPreferences, cached auth tokens, and any local databases.

**Impact:** An attacker with physical access or ADB access can extract all
locally stored app data.

**Remediation:**

```xml
<application
    android:allowBackup="false"
    android:fullBackupContent="false"
    ...>
```

---

### FINDING 2: No flutter_secure_storage for Sensitive Local Data [MEDIUM]

**File:**
`/Users/robertguss/Projects/github/flutter-firebase-starter-kit/pubspec.yaml`

**Issue:** The kit uses `shared_preferences` for theme mode (which is fine), but
does not include `flutter_secure_storage` as a dependency. Currently no
sensitive data is stored locally, but downstream developers building on this
template may store tokens, user preferences, or cached data in SharedPreferences
out of habit since that is the only local storage pattern demonstrated.

**Impact:** Downstream apps may inadvertently store sensitive data in plaintext
SharedPreferences.

**Remediation:** Add `flutter_secure_storage` to pubspec.yaml and include a
documented example showing when to use each:

- `shared_preferences` -- non-sensitive preferences (theme, locale)
- `flutter_secure_storage` -- tokens, sensitive user data, cached credentials

---

### FINDING 3: No Analytics/Crashlytics Consent Gate [MEDIUM]

**Files:**

- `/Users/robertguss/Projects/github/flutter-firebase-starter-kit/lib/main.dart`
- `/Users/robertguss/Projects/github/flutter-firebase-starter-kit/lib/features/onboarding/screens/onboarding_screen.dart`

**Issue:** Firebase Analytics and Crashlytics are enabled by default with no
user consent prompt. The onboarding screen logs analytics events
(`FirebaseAnalytics`) without asking for consent. While Crashlytics is disabled
in debug mode, it auto-enables in release builds. Under GDPR, CCPA, and similar
regulations, users must be informed and given the option to opt out of data
collection before it begins.

**Impact:** Apps built from this template may violate privacy regulations in the
EU, California, and other jurisdictions. App Store review may also flag this for
apps targeting EU users.

**Remediation:** Add a consent screen or dialog before first
analytics/crashlytics call:

```dart
// Before enabling collection:
final consent = await showConsentDialog();
await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(consent);
await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(consent);
```

---

### FINDING 4: Placeholder Legal URLs Ship by Default [MEDIUM]

**File:**
`/Users/robertguss/Projects/github/flutter-firebase-starter-kit/lib/config/app_config.dart`

**Issue:** Privacy policy and terms of service URLs are set to
`https://example.com/privacy` and `https://example.com/terms`. Unlike RevenueCat
keys (which default to empty and fail visibly), these placeholder URLs will
silently work -- they open a browser to example.com. A developer who forgets to
replace them ships an app with no real legal documents.

**Impact:** App Store rejection (Apple requires valid privacy policy URL), legal
liability, user trust issues.

**Remediation:** Either:

1. Default to empty string and add a runtime check that warns/blocks if unset,
   or
2. Add an `assert()` in debug mode that validates these are not example.com URLs

---

### FINDING 5: FCM Token Refresh Listener is a No-Op [LOW]

**File:**
`/Users/robertguss/Projects/github/flutter-firebase-starter-kit/lib/features/notifications/services/fcm_service.dart`

**Issue:** `messaging.onTokenRefresh.listen((_) {})` registers an empty
listener. The TODO comment says to send the refreshed token to the backend, but
the empty listener means token rotations are silently dropped. This causes push
notifications to stop working after token rotation.

**Impact:** Users stop receiving push notifications after a token refresh cycle.
This is a reliability issue but also a security surface -- stale tokens in
Firestore could theoretically be reused if the backend does not properly
validate them.

**Remediation:** At minimum, update the Firestore profile with the new token in
the listener callback, or remove the listener and document clearly that
downstream developers must implement this.

---

### FINDING 6: No String Length Validation in Firestore Rules [LOW]

**File:**
`/Users/robertguss/Projects/github/flutter-firebase-starter-kit/firestore.rules`

**Issue:** The `validFields()` function checks types but not string lengths. A
malicious client could write extremely long strings (megabytes) to
`displayName`, `photoUrl`, or `fcmToken` fields, consuming Firestore storage
quota and causing UI rendering issues.

**Impact:** Denial-of-service via storage exhaustion, potential UI crashes when
rendering oversized strings.

**Remediation:**

```
&& request.resource.data.get('displayName', '').size() <= 200
&& request.resource.data.get('photoUrl', '').size() <= 2048
&& request.resource.data.get('fcmToken', '').size() <= 4096
```

---

### FINDING 7: No Certificate Pinning Guidance [LOW]

**Issue:** The kit does not implement or document SSL certificate pinning. While
Firebase SDKs handle their own connections securely, downstream developers
adding custom API calls will default to trusting any valid certificate, making
MITM attacks possible on compromised networks.

**Remediation:** Document in README or CLAUDE.md that production apps handling
sensitive custom API calls should consider certificate pinning via packages like
`http_certificate_pinning` or custom `SecurityContext` configuration.

---

### FINDING 8: No ProGuard/R8 Obfuscation Documentation [LOW]

**Issue:** No ProGuard/R8 rules or obfuscation flags are documented for Android
release builds. Flutter's `--obfuscate` and `--split-debug-info` flags are not
mentioned in build commands.

**Remediation:** Add to build documentation:

```bash
flutter build apk --dart-define=ENV=prod --obfuscate --split-debug-info=build/symbols
flutter build ios --dart-define=ENV=prod --obfuscate --split-debug-info=build/symbols
```

---

## Security Requirements Checklist

- [x] All inputs validated and sanitized (Firestore rules enforce field
      allowlist and types)
- [x] No hardcoded secrets or credentials (RevenueCat keys via dart-define,
      Firebase config gitignored)
- [x] Proper authentication on all endpoints (GoRouter redirect guard)
- [x] SQL queries use parameterization (N/A -- uses Firestore, not SQL)
- [x] XSS protection implemented (N/A -- native mobile app, not web)
- [x] HTTPS enforced (no cleartext traffic enabled)
- [x] CSRF protection (N/A -- mobile app with Firebase Auth tokens)
- [ ] Security headers properly configured (add android:allowBackup="false")
- [x] Error messages don't leak sensitive information (generic UI messages)
- [ ] Privacy consent before data collection (no consent gate for
      analytics/crashlytics)

---

## Remediation Roadmap (Priority Order)

1. **Immediate:** Add `android:allowBackup="false"` to AndroidManifest.xml
2. **Immediate:** Add runtime validation or assert for placeholder legal URLs
3. **Short-term:** Implement analytics/crashlytics consent gate
4. **Short-term:** Add `flutter_secure_storage` with usage documentation
5. **Short-term:** Add string length limits to Firestore rules
6. **Medium-term:** Implement FCM token refresh handler
7. **Medium-term:** Document obfuscation flags for release builds
8. **Medium-term:** Document certificate pinning guidance for custom APIs
