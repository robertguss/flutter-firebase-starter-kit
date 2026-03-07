# Firebase Best Practices Review of Comprehensive Improvement Plan

**Date:** 2026-03-07 **Scope:** Tasks 1.4d, 1.4e, 2.5, 4.1a, 4.3, 4.6 + general
Firebase gotchas

---

## 1. Firestore Security Rules (Task 1.4e)

### Current State (Already Good)

The existing `firestore.rules` is **significantly better** than what Task 1.4e
proposes. The current rules already have:

- `hasOnly()` field allowlisting
- Type validation via `validFields()` helper
- Immutable `createdAt` on update
- Email pinned to `request.auth.token.email`

### What Task 1.4e Proposes is a DOWNGRADE

The plan's proposed rules remove the `validFields()` helper and field
allowlisting. **Do not replace the current rules with the plan's snippet.**
Instead, augment the existing rules.

### Recommended Additions to Existing Rules

```
// Add string length limits inside validFields():
function validFields() {
  return request.resource.data.keys().hasOnly(
    ['email', 'displayName', 'photoUrl', 'onboardingComplete',
     'fcmToken', 'createdAt']
  )
  && (request.resource.data.onboardingComplete is bool)
  && (request.resource.data.get('displayName', '') is string)
  && (request.resource.data.get('displayName', '').size() <= 100)
  && (request.resource.data.get('photoUrl', '') is string)
  && (request.resource.data.get('photoUrl', '').size() <= 2048)
  && (request.resource.data.get('fcmToken', '') is string)
  && (request.resource.data.get('fcmToken', '').size() <= 4096)
  && (request.resource.data.get('createdAt', request.time) is timestamp)
  && (request.resource.data.email is string)
  && (request.resource.data.email.size() <= 254);
}
```

### Missing Best Practice: Rate Limiting via Document Size

Firestore rules cannot rate-limit, but you can cap document size indirectly by
limiting all string fields. The above covers it.

---

## 2. FCM Token Refresh (Task 1.4d)

### Problem with the Plan's Approach

The plan proposes calling `FirebaseAuth.instance.currentUser` and
`FirebaseFirestore.instance` directly inside the `onTokenRefresh` listener. This
bypasses the existing `UserProfileService` abstraction and makes testing
impossible.

### Correct Pattern (Use Existing Service)

Wire the `onTokenRefresh` listener through the existing bootstrap hooks in
`main.dart`, not inside `FcmService`:

```dart
// In main.dart, inside the enableNotifications block:
if (AppConfig.enableNotifications) {
  bootstrapHooks.add((ref, uid) async {
    final fcmService = ref.read(fcmServiceProvider);
    final profileService = ref.read(userProfileServiceProvider);

    // Initial token
    final token = await fcmService.getToken();
    if (token != null) {
      await profileService.updateFcmToken(uid, token);
    }

    // Token refresh - use the service, not raw Firestore
    fcmService.messaging.onTokenRefresh.listen((newToken) async {
      await profileService.updateFcmToken(uid, newToken);
    });
  });
}
```

### Additional Gotcha: Sign-Out Cleanup

The plan does not mention cancelling the `onTokenRefresh` subscription on
sign-out. The listener holds a reference to `uid`. Add to `signOutHooks`:

```dart
// Store the subscription
StreamSubscription? _tokenRefreshSub;

// In bootstrap:
_tokenRefreshSub = fcmService.messaging.onTokenRefresh.listen(...);

// In sign-out hook:
signOutHooks.add((ref, uid) async {
  await _tokenRefreshSub?.cancel();
  await ref.read(userProfileServiceProvider).clearFcmToken(uid);
});
```

Better yet, manage this subscription inside a Riverpod provider that
auto-disposes on auth state change.

---

## 3. Firebase Storage for Avatar Uploads (Task 4.1a)

### Missing: Storage Security Rules

The plan mentions storing avatars at `users/{uid}/avatar.jpg` but provides **no
`storage.rules` file**. There is no existing `storage.rules` either.

### Required `storage.rules`

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{uid}/avatar.jpg {
      // Only the owner can read/write their avatar
      allow read: if request.auth != null && request.auth.uid == uid;

      // Restrict uploads: owner only, max 5MB, images only
      allow write: if request.auth != null && request.auth.uid == uid
        && request.resource.size < 5 * 1024 * 1024
        && request.resource.contentType.matches('image/.*');
    }

    // Deny everything else
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

### Missing Best Practices the Plan Should Add

1. **Client-side image compression** before upload. Use `image_picker`'s
   `maxWidth`/`maxHeight`/`imageQuality` params:

   ```dart
   final image = await picker.pickImage(
     source: ImageSource.gallery,
     maxWidth: 512,
     maxHeight: 512,
     imageQuality: 75,
   );
   ```

2. **Delete old avatar before uploading new one** -- otherwise orphaned files
   accumulate.

3. **Update `firestore.rules` `hasOnly` list** to include `photoUrl` (already
   present, good) and ensure `photoUrl` length accommodates Firebase Storage
   download URLs (they can be ~500+ chars, the 2048 limit above covers this).

4. **Add `firebase_storage` to `firebase.json`** for emulator support.

---

## 4. Consent Gate and Crashlytics (Task 4.3)

### Current Initialization (main.dart)

Crashlytics is initialized unconditionally before `runApp`. The plan correctly
identifies the need for a consent gate.

### Correct Pattern

```dart
// In main.dart - initialize Crashlytics in DISABLED mode first
if (AppConfig.enableCrashlytics) {
  // Always set up error handlers to prevent crashes from being lost
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Disable collection until consent is granted
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
}

// Later, after consent dialog:
Future<void> onConsentGranted() async {
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
  await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
}

Future<void> onConsentRevoked() async {
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
  await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(false);
  // Note: setCrashlyticsCollectionEnabled(false) does NOT delete
  // already-collected data. Deletion requires contacting Firebase support
  // or using the Firebase Admin SDK. Document this limitation.
}
```

### Gotcha the Plan Misses

The plan says "delete existing data" on consent revocation. **Firebase does not
provide a client-side API to delete Crashlytics data.** You can only disable
future collection. Document this limitation clearly in the consent dialog and
privacy policy.

### Timing Issue

The plan says "show consent dialog before analytics/crashlytics init." But
Crashlytics must be initialized (in disabled mode) before `runApp` to catch
early crashes. The consent dialog runs after `runApp`. The correct sequence is:

1. `FirebaseService.initialize()`
2. Set up Crashlytics error handlers (so no crashes are lost)
3. `setCrashlyticsCollectionEnabled(false)` (default disabled)
4. `runApp()`
5. Show consent dialog on first launch
6. If granted, `setCrashlyticsCollectionEnabled(true)`

---

## 5. Firebase Emulator Setup (Task 4.6)

### Required `firebase.json` Configuration

```json
{
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "storage": {
    "rules": "storage.rules"
  },
  "emulators": {
    "auth": {
      "port": 9099
    },
    "firestore": {
      "port": 8080
    },
    "storage": {
      "port": 9199
    },
    "ui": {
      "enabled": true,
      "port": 4000
    }
  }
}
```

### Rules Testing with `@firebase/rules-unit-testing` (Node.js)

The plan says "Create `test/rules/firestore_rules_test.dart`" -- **Firestore
rules tests cannot run in Dart.** They require the Node.js
`@firebase/rules-unit-testing` package. Create:

```
test_rules/
  package.json
  firestore.test.js
  storage.test.js
```

Example `firestore.test.js`:

```javascript
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require("@firebase/rules-unit-testing");
const fs = require("fs");

let testEnv;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: "starter-kit-test",
    firestore: {
      rules: fs.readFileSync("../firestore.rules", "utf8"),
    },
  });
});

afterAll(async () => {
  await testEnv.cleanup();
});

afterEach(async () => {
  await testEnv.clearFirestore();
});

test("user can read own profile", async () => {
  const alice = testEnv.authenticatedContext("alice", {
    email: "alice@example.com",
  });
  const db = alice.firestore();

  // Seed data first
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await ctx.firestore().doc("users/alice").set({
      email: "alice@example.com",
      onboardingComplete: false,
      createdAt: new Date(),
    });
  });

  await assertSucceeds(db.doc("users/alice").get());
});

test("user cannot read another user profile", async () => {
  const alice = testEnv.authenticatedContext("alice");
  await assertFails(alice.firestore().doc("users/bob").get());
});

test("unauthenticated user cannot read", async () => {
  const unauth = testEnv.unauthenticatedContext();
  await assertFails(unauth.firestore().doc("users/alice").get());
});

test("rejects displayName over 100 chars", async () => {
  const alice = testEnv.authenticatedContext("alice", {
    email: "alice@example.com",
  });
  await assertFails(
    alice
      .firestore()
      .doc("users/alice")
      .set({
        email: "alice@example.com",
        displayName: "a".repeat(101),
        onboardingComplete: false,
        createdAt: new Date(),
      }),
  );
});

test("rejects unknown fields", async () => {
  const alice = testEnv.authenticatedContext("alice", {
    email: "alice@example.com",
  });
  await assertFails(
    alice.firestore().doc("users/alice").set({
      email: "alice@example.com",
      onboardingComplete: false,
      createdAt: new Date(),
      isAdmin: true, // not in hasOnly list
    }),
  );
});
```

### Add to Makefile

```makefile
test-rules: ## Run Firestore/Storage rules tests (requires Firebase emulator)
	cd test_rules && npm test

emulators: ## Start Firebase emulators
	firebase emulators:start
```

---

## 6. Per-Flavor Firebase Config (Task 2.5)

### The `flutterfire configure` Workflow

Run once per flavor, specifying the output location:

```bash
# Dev flavor (separate Firebase project recommended)
flutterfire configure \
  --project=your-app-dev \
  --out=lib/firebase_options_dev.dart \
  --ios-bundle-id=com.example.app.dev \
  --android-package-name=com.example.app.dev

# Staging
flutterfire configure \
  --project=your-app-staging \
  --out=lib/firebase_options_staging.dart \
  --ios-bundle-id=com.example.app.staging \
  --android-package-name=com.example.app.staging

# Prod
flutterfire configure \
  --project=your-app-prod \
  --out=lib/firebase_options_prod.dart \
  --ios-bundle-id=com.example.app \
  --android-package-name=com.example.app
```

### Flavor-Aware Initialization

```dart
// lib/config/firebase_config.dart
import 'package:flutter_starter_kit/config/environment.dart';
import 'package:flutter_starter_kit/firebase_options_dev.dart' as dev;
import 'package:flutter_starter_kit/firebase_options_staging.dart' as staging;
import 'package:flutter_starter_kit/firebase_options_prod.dart' as prod;
import 'package:firebase_core/firebase_core.dart';

class FirebaseConfig {
  static FirebaseOptions get currentOptions {
    switch (EnvironmentConfig.current) {
      case Environment.dev:
        return dev.DefaultFirebaseOptions.currentPlatform;
      case Environment.staging:
        return staging.DefaultFirebaseOptions.currentPlatform;
      case Environment.prod:
        return prod.DefaultFirebaseOptions.currentPlatform;
    }
  }
}

// In FirebaseService.initialize():
await Firebase.initializeApp(options: FirebaseConfig.currentOptions);
```

### Gotcha: google-services.json Placement

The plan correctly places `google-services.json` under
`android/app/src/{flavor}/`. However, `flutterfire configure` generates
`google-services.json` at `android/app/google-services.json` by default. You
must **manually move** the file to the flavor directory after each run, or use
`--android-out`:

```bash
flutterfire configure \
  --project=your-app-dev \
  --android-out=android/app/src/dev/google-services.json \
  --ios-out=ios/Runner/GoogleService-Info-Dev.plist
```

### iOS: Use Xcode Build Phase Script

For iOS, you need a build phase script to copy the correct
`GoogleService-Info.plist`:

```bash
# In Xcode > Build Phases > Run Script (before "Compile Sources"):
case "${PRODUCT_BUNDLE_IDENTIFIER}" in
  *.dev)
    cp "${PROJECT_DIR}/Runner/GoogleService-Info-Dev.plist" \
       "${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/GoogleService-Info.plist"
    ;;
  *.staging)
    cp "${PROJECT_DIR}/Runner/GoogleService-Info-Staging.plist" \
       "${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/GoogleService-Info.plist"
    ;;
  *)
    cp "${PROJECT_DIR}/Runner/GoogleService-Info.plist" \
       "${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/GoogleService-Info.plist"
    ;;
esac
```

---

## 7. Firebase Gotchas the Plan Misses

### 7a. Firestore Offline Persistence Defaults

Firestore has offline persistence **enabled by default** on mobile. The plan's
Task 4.4 (offline-first docs) should mention that no code changes are needed for
basic offline support, but the app should handle `FirebaseException` with code
`unavailable` gracefully.

### 7b. `set()` with `merge: true` vs `update()`

`UserProfileService.createOrUpdateProfile` uses `set(merge: true)`, but
`updateFcmToken` uses `update()`. The difference: `update()` fails if the
document doesn't exist. If `onTokenRefresh` fires before the user profile is
created, it will throw. Use `set(merge: true)` for `updateFcmToken` too, or
guard with a document existence check.

### 7c. Firestore Rules and `FieldValue.delete()`

The `clearFcmToken` method uses `FieldValue.delete()`. The current `hasOnly()`
rule will **still pass** because `FieldValue.delete()` removes the field from
`request.resource.data`, so it won't appear in `keys()`. This is correct
behavior but worth a test case.

### 7d. Security: `fcmToken` Should Not Be Client-Readable

FCM tokens are sensitive -- they allow anyone to send push notifications to that
device. Consider a **server-side Cloud Function** to manage FCM tokens instead.
If keeping client-side, the current rules (owner-only read/write) are the
minimum. But if you ever add admin or social features, ensure other users cannot
read `fcmToken`.

### 7e. Firebase Auth: Account Deletion

When deleting a user account, the plan should ensure:

1. Delete Firestore user document (already in delete account hooks)
2. Delete Storage avatar (missing from plan)
3. Delete Firebase Auth account
4. Revoke FCM token

### 7f. `firebase.json` Already Exists but is Empty

The current `firebase.json` is empty (`{}`). Task 4.6 should update it, not
create it.

### 7g. Firestore Rules: `email` Field on Create

The current rule requires
`request.resource.data.email == request.auth.token.email`. Some auth providers
(Apple Sign-In with "Hide My Email") may relay a private email. This is fine
since `request.auth.token.email` reflects whatever email the provider gives, but
document this behavior.

### 7h. Missing `firestore.indexes.json`

No composite indexes file exists. If the profile feature adds queries (e.g.,
searching users), indexes will be needed. Create an empty
`firestore.indexes.json`:

```json
{ "indexes": [], "fieldOverrides": [] }
```
