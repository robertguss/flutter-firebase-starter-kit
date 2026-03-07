# Security Review: Comprehensive Improvement Plan

**Date:** 2026-03-07 **Reviewer:** Security Sentinel (Automated) **Scope:**
Implementation plan security analysis across 8 focus areas **Risk Context:**
This is a starter kit template -- every vulnerability propagates to all
downstream apps.

---

## Executive Summary

The plan addresses several real security gaps (allowBackup, secure storage,
Firestore rules) but has **5 Critical/High** findings and **7 Medium** findings
that must be resolved before the plan is finalized. The most dangerous gaps are:
missing Firebase Storage rules for avatar uploads, FCM token refresh race
conditions, consent gate storing preferences in cleartext, and Firestore rules
that lack field-level validation for the new profile fields the plan itself
introduces.

---

## Finding 1: Firestore Rules (Task 1.4e) -- CRITICAL

### 1a. Plan's proposed rules conflict with existing rules

The plan proposes simplified rules that are **weaker** than the existing
`firestore.rules` already in the repo. The existing rules already have:

- `hasOnly()` field allowlisting
- Type validation per field
- `createdAt` immutability on update
- Email must match `request.auth.token.email`

The plan's Task 1.4e would **regress** security by replacing these with rules
that only check `displayName` and `email` length. **The plan should augment the
existing rules, not replace them.**

### 1b. Missing fields from Phase 4 expansion

Task 4.1 adds profile fields (avatar URL, notification preferences, theme
preference) and Task 4.1a adds Firebase Storage uploads. The Firestore rules
`hasOnly()` allowlist will reject writes containing these new fields. The plan
does not mention updating rules to accommodate new fields.

**Required rule additions:**

```
// Add to validFields() hasOnly list:
['email', 'displayName', 'photoUrl', 'onboardingComplete',
 'fcmToken', 'createdAt', 'avatarUrl', 'notificationEnabled', 'themePreference']

// Add type + length validation for new fields:
&& (request.resource.data.get('avatarUrl', '') is string)
&& (request.resource.data.get('avatarUrl', '').size() <= 2048)
&& (request.resource.data.get('notificationEnabled', true) is bool)
&& (request.resource.data.get('themePreference', 'system') is string)
&& (request.resource.data.get('themePreference', 'system').size() <= 10)
```

### 1c. Missing string length limits on existing fields

The existing rules validate types but not string lengths. The plan correctly
identifies this gap but only adds limits for `displayName` and `email`. Missing
limits:

| Field         | Max Length | Rationale                         |
| ------------- | ---------- | --------------------------------- |
| `displayName` | 100        | Plan has this -- good             |
| `email`       | 254        | Plan has this -- good             |
| `photoUrl`    | 2048       | URL can be used for storage abuse |
| `fcmToken`    | 4096       | FCM tokens are long but bounded   |

**Add to existing `validFields()` function:**

```
&& (request.resource.data.get('displayName', '').size() <= 100)
&& (request.resource.data.get('email', '').size() <= 254)
&& (request.resource.data.get('photoUrl', '').size() <= 2048)
&& (request.resource.data.get('fcmToken', '').size() <= 4096)
```

### 1d. No rate limiting or document size constraint

Firestore rules cannot enforce rate limiting natively, but the plan should
document that downstream apps should implement:

- Cloud Functions-based write rate limiting for abuse prevention
- Maximum document size awareness (1 MiB Firestore limit)

**Severity: CRITICAL** -- Plan as written would regress existing security
posture.

---

## Finding 2: FCM Token Refresh (Task 1.4d) -- HIGH

### 2a. Race condition between token refresh and auth state

The proposed pattern:

```dart
FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid != null) {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'fcmToken': newToken,
    });
  }
});
```

**Race condition:** Token refresh can fire during sign-out. Between checking
`currentUser?.uid` and executing the Firestore write, the user may have signed
out and another user may have signed in. The token would be written to the wrong
user's document.

**Fix:**

```dart
FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    try {
      // Re-verify auth state hasn't changed before writing
      await user.reload();
      if (FirebaseAuth.instance.currentUser?.uid == user.uid) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'fcmToken': newToken});
      }
    } on FirebaseAuthException {
      // User signed out between check and write -- safe to ignore
    }
  }
});
```

### 2b. Unsubscribed listener causes memory leak

The `onTokenRefresh.listen()` returns a `StreamSubscription` that is never
cancelled. If `FcmService` is re-created (e.g., on hot restart or provider
invalidation), listeners accumulate.

**Fix:** Store the subscription and cancel it in a dispose/cleanup method:

```dart
StreamSubscription<String>? _tokenRefreshSub;

void dispose() {
  _tokenRefreshSub?.cancel();
}
```

### 2c. FCM token not cleared on sign-out

The existing codebase has `clearFcmToken()` in `UserProfileService` but the
plan's sign-out hooks (in `main.dart`) do not call it. A stale FCM token means
push notifications could be sent to a device after the user has signed out.

**Fix:** Add to sign-out hooks in `main.dart`:

```dart
signOutHooks.add((ref, uid) async {
  await ref.read(userProfileServiceProvider).clearFcmToken(uid);
});
```

**Severity: HIGH** -- Race condition can associate push tokens with wrong user;
stale tokens leak notifications post-sign-out.

---

## Finding 3: flutter_secure_storage vs SharedPreferences (Task 1.4b) -- MEDIUM

### 3a. Boundary guidance is incomplete

The plan says: "Use for auth tokens, API keys, sensitive user data. Use
SharedPreferences for non-sensitive preferences like theme mode."

This is correct directionally but missing critical nuance for a starter kit:

**Must use flutter_secure_storage:**

- OAuth refresh tokens (if implementing custom auth flows)
- Any user PII cached locally (email, name)
- RevenueCat API keys (currently hardcoded in `AppConfig`)
- Consent state (if consent is revoked, it must not be trivially editable)

**Safe for SharedPreferences:**

- Theme preference (light/dark/system)
- Onboarding completion flag
- Feature flags / non-sensitive app state
- Locale preference

### 3b. Consent state should NOT be in SharedPreferences

Task 4.3 stores `analytics_consent` in SharedPreferences. This is a **compliance
risk**: SharedPreferences on Android is stored in plaintext XML. A user or
malicious app with root access could flip `analytics_consent: true` without the
user's knowledge. For GDPR compliance, consent state should be in
`flutter_secure_storage` and additionally synced to a server-side record.

### 3c. Missing migration guidance

When adding `flutter_secure_storage`, the plan should document how downstream
developers migrate existing SharedPreferences data to secure storage. Without
this, developers will store sensitive data in SharedPreferences out of habit.

**Severity: MEDIUM** -- Consent state in cleartext is a compliance risk.

---

## Finding 4: Consent Gate (Task 4.3) -- HIGH

### 4a. GDPR compliance gaps

The plan's consent gate is a good start but has these compliance gaps:

1. **No granular consent categories.** GDPR requires separate consent for
   analytics vs. crash reporting vs. marketing. The plan uses a single boolean.
   Must be at minimum:
   - `analytics_consent` (Firebase Analytics)
   - `crash_reporting_consent` (Crashlytics)
   - `marketing_consent` (push notifications / FCM)

2. **No consent record with timestamp.** GDPR Article 7(1) requires controllers
   to demonstrate that consent was given. The plan stores a boolean but no
   timestamp, consent version, or audit trail. Store:

   ```dart
   {
     'analytics': true,
     'crashReporting': true,
     'consentVersion': '1.0',
     'consentTimestamp': DateTime.now().toIso8601String(),
   }
   ```

3. **No server-side consent record.** Consent stored only on-device is lost on
   uninstall. Must sync to Firestore for audit purposes.

4. **No re-consent on policy change.** If privacy policy changes, users must
   re-consent. The plan has no mechanism for consent versioning.

### 4b. CCPA compliance gaps

1. **No "Do Not Sell" option.** CCPA requires a "Do Not Sell My Personal
   Information" toggle if the app shares data with third parties (RevenueCat,
   Firebase Analytics).

2. **No data deletion mechanism.** The plan has account deletion but no data
   export or targeted deletion flow required by CCPA's right to delete.

### 4c. Crashlytics "collection disabled" mode is incomplete

The plan says: "Crashlytics should be initialized in a 'collection disabled'
mode." The implementation must also:

- Set `FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false)`
  before any crash can occur
- This means it must happen in `main()` before `runApp()`
- If consent is later revoked, call `setCrashlyticsCollectionEnabled(false)` AND
  call the Firebase data deletion API

**Severity: HIGH** -- Missing granular consent and audit trail creates GDPR
non-compliance that propagates to all downstream apps.

---

## Finding 5: Firebase Storage Security Rules (Task 4.1a) -- CRITICAL

### 5a. No storage rules exist or are planned

The plan introduces avatar uploads to `users/{uid}/avatar.jpg` in Task 4.1a but
**never mentions Firebase Storage security rules**. No `storage.rules` file
exists in the repository. Without rules, Firebase Storage defaults to denying
all access (if in production mode) or allowing all access (if in test mode).

**Required `storage.rules`:**

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // User avatars: only the owner can read/write, with size and type limits
    match /users/{uid}/avatar.jpg {
      allow read: if request.auth != null;
      allow write: if request.auth != null
        && request.auth.uid == uid
        && request.resource.size < 5 * 1024 * 1024  // 5 MB max
        && request.resource.contentType.matches('image/.*');
    }

    // Deny everything else
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

### 5b. Missing client-side validation

The plan's `avatar_picker.dart` should also enforce:

- Image compression before upload (reduce to 512x512 or similar)
- File size check before upload attempt
- Content type validation (reject non-image files)

### 5c. Avatar URL injection risk

The `photoUrl` field in Firestore is user-writable. If the profile screen
renders this URL with `NetworkImage()`, a malicious user could set `photoUrl` to
a tracking pixel URL or an extremely large image to cause DoS. The Firestore
rules should validate URL format:

```
&& (request.resource.data.get('photoUrl', '').matches('^https://.*') ||
    request.resource.data.get('photoUrl', '') == '')
```

**Severity: CRITICAL** -- Uploading files without storage rules is a direct path
to abuse (storage cost attacks, malicious file hosting).

---

## Finding 6: API Key Management with Flavors (Task 2.5) -- MEDIUM

### 6a. google-services.json per flavor is correctly gitignored

The existing `.gitignore` includes `**/google-services.json` and
`**/GoogleService-Info.plist`. This correctly covers the per-flavor paths
(`android/app/src/dev/google-services.json`, etc.).

### 6b. RevenueCat API keys still hardcoded in source

`AppConfig` contains:

```dart
static const revenueCatApiKeyApple = 'your_apple_api_key';
static const revenueCatApiKeyGoogle = 'your_google_api_key';
```

The plan does not address moving these to `--dart-define` or a `.env` file per
flavor. These keys should:

1. Be passed via `--dart-define=RC_API_KEY_APPLE=xxx` per flavor
2. Never appear in source code
3. Be documented in a `.env.example` file

### 6c. iOS xcconfig files may contain secrets

The plan creates `ios/Flutter/Dev.xcconfig`, `Staging.xcconfig`,
`Prod.xcconfig`. If these contain API keys or bundle-specific secrets, they must
be gitignored. The current `.gitignore` does not exclude `.xcconfig` files.

**Add to `.gitignore`:**

```
# Flavor-specific configs that may contain secrets
ios/Flutter/Dev.xcconfig
ios/Flutter/Staging.xcconfig
ios/Flutter/Prod.xcconfig
```

Or better: use `.xcconfig.example` templates committed to git, with actual files
gitignored.

### 6d. firebase_options.dart per flavor

`flutterfire configure` generates `firebase_options.dart` which contains API
keys. The plan mentions running it per flavor but does not address:

- Each flavor needs its own `firebase_options_dev.dart`,
  `firebase_options_staging.dart`, etc.
- These files contain Firebase API keys and should be gitignored
- The current `.gitignore` already excludes `firebase_options.dart` -- good

**Severity: MEDIUM** -- RevenueCat keys in source and potential xcconfig secret
exposure.

---

## Finding 7: Legal URL Assert Pattern (Task 1.4c) -- MEDIUM

### 7a. Debug-only assert is insufficient

`assert()` in Dart is stripped in release builds. This means a developer could
ship to production with `example.com` legal URLs and receive zero warning. For a
starter kit, this is a liability risk.

**Better approach -- runtime check with visible warning:**

```dart
// In the settings screen build method:
if (kDebugMode && _privacyPolicyUrl.contains('example.com')) {
  // Show a red banner in debug builds
}

// In main.dart or app initialization:
if (kReleaseMode && _privacyPolicyUrl.contains('example.com')) {
  // Log to Crashlytics as a non-fatal error
  FirebaseCrashlytics.instance.recordError(
    Exception('Privacy policy URL not configured'),
    StackTrace.current,
    reason: 'Placeholder legal URLs detected in production',
  );
}
```

### 7b. CI/CD gate is the real solution

Task 2.7 adds GitHub Actions CI/CD. Add a step that greps for `example.com` in
production builds and fails the pipeline:

```yaml
- name: Check for placeholder URLs
  run: |
    if grep -r "example.com" lib/; then
      echo "ERROR: Placeholder URLs found in source code"
      exit 1
    fi
```

**Severity: MEDIUM** -- Debug-only assert creates false sense of security;
production builds silently pass.

---

## Finding 8: Security Considerations the Plan Misses Entirely -- HIGH

### 8a. No certificate pinning guidance

For a mobile app communicating with Firebase, the plan should document SSL/TLS
certificate pinning options. While Firebase SDKs handle their own connections,
any custom API endpoints added by downstream developers need pinning.

### 8b. No ProGuard/R8 obfuscation for Android

The plan adds `allowBackup="false"` but does not mention enabling code
obfuscation:

```bash
flutter build apk --obfuscate --split-debug-info=build/debug-info
```

This should be the default in the Makefile/build commands.

### 8c. No iOS App Transport Security (ATS) audit

The plan should verify that `Info.plist` does not contain
`NSAllowsArbitraryLoads = YES`. Firebase does not require ATS exceptions.

### 8d. Jailbreak/root detection not mentioned

For apps handling payments (RevenueCat), the plan should document jailbreak/root
detection as a recommendation, even if not implemented in the starter kit.

### 8e. No session timeout or re-authentication for sensitive operations

Account deletion (`_deleteAccount` in settings) does not require
re-authentication. Firebase Auth `delete()` will throw `requires-recent-login`
if the session is old, but the plan should document proper re-authentication UX.

### 8f. Crashlytics user identifier not cleared on sign-out

The bootstrap sets `setUserIdentifier(user.uid)` but sign-out hooks do not clear
it. Post-sign-out crashes will be attributed to the wrong user.

**Fix:** Add to sign-out hooks:

```dart
signOutHooks.add((ref, uid) async {
  if (AppConfig.enableCrashlytics) {
    await FirebaseCrashlytics.instance.setUserIdentifier('');
  }
});
```

### 8g. Debug logging in non-prod exposes sensitive data

`FcmService` prints message titles and data keys in non-prod environments. If a
staging build is distributed to testers, push notification content is logged to
the system console where other apps or `adb logcat` can read it.

**Fix:** Use `log()` from `dart:developer` instead of `debugPrint()` -- it is
only visible to attached debuggers, not `adb logcat`.

### 8h. No dependency vulnerability scanning

The plan adds CI/CD (Task 2.7) but does not include automated dependency
vulnerability scanning. Add:

```yaml
- name: Check for vulnerable dependencies
  run: |
    dart pub outdated --dependency-overrides
    # Consider integrating with OSV scanner
```

**Severity: HIGH** -- Multiple missing security controls that downstream apps
will inherit as "acceptable defaults."

---

## Risk Matrix

| #   | Finding                                    | Severity | Exploitability                             |
| --- | ------------------------------------------ | -------- | ------------------------------------------ |
| 5a  | No Firebase Storage rules for avatars      | CRITICAL | Trivial -- unauthenticated upload/download |
| 1a  | Plan regresses existing Firestore rules    | CRITICAL | N/A -- implementation error                |
| 4a  | Consent gate lacks GDPR granularity        | HIGH     | Regulatory -- audit failure                |
| 2a  | FCM token refresh race condition           | HIGH     | Moderate -- requires timing                |
| 8f  | Crashlytics identifier not cleared         | HIGH     | Low -- data attribution error              |
| 8g  | Debug logging exposes notification content | HIGH     | Moderate -- adb logcat                     |
| 6b  | RevenueCat API keys in source              | MEDIUM   | Trivial -- decompile APK                   |
| 7a  | Debug-only assert for legal URLs           | MEDIUM   | N/A -- compliance gap                      |
| 3b  | Consent in SharedPreferences cleartext     | MEDIUM   | Requires root access                       |
| 6c  | xcconfig files not gitignored              | MEDIUM   | Requires repo access                       |
| 8b  | No obfuscation in build commands           | MEDIUM   | Moderate -- reverse engineering            |
| 8h  | No dependency vulnerability scanning       | MEDIUM   | Variable                                   |

---

## Remediation Roadmap (Priority Order)

1. **Immediate (before Phase 1 implementation):**
   - Fix Task 1.4e to augment existing rules, not replace them
   - Add `storage.rules` to the plan as a new task (1.4f or within 4.1a)
   - Fix FCM token refresh race condition and add sign-out cleanup
   - Clear Crashlytics user identifier on sign-out

2. **Before Phase 2:**
   - Move RevenueCat API keys to `--dart-define`
   - Add xcconfig files to `.gitignore`
   - Add obfuscation flags to build commands
   - Replace `debugPrint` with `dart:developer` `log()` in services

3. **Before Phase 4:**
   - Redesign consent gate with granular categories + timestamps
   - Store consent in `flutter_secure_storage` + sync to Firestore
   - Add consent versioning mechanism
   - Add Firebase Storage rules before implementing avatar uploads

4. **CI/CD integration (Task 2.7):**
   - Add placeholder URL check to pipeline
   - Add dependency vulnerability scanning
   - Add `flutter analyze --fatal-infos` as gate
