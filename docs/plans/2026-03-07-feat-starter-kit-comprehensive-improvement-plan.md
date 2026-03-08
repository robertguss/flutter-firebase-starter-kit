---
title: "feat: Comprehensive Starter Kit Improvement"
type: feat
status: active
date: 2026-03-07
origin: docs/brainstorms/2026-03-07-starter-kit-improvements-brainstorm.md
---

# Comprehensive Starter Kit Improvement

## Enhancement Summary

**Deepened on:** 2026-03-07 **Research agents used:** 9 (Flutter Expert,
Firebase Skills, Riverpod Codegen, Flutter Flavors, Architecture, Security,
Performance, Simplicity, SpecFlow)

### Critical Corrections (would have caused bugs)

1. **`--flavor` does not set Dart defines** -- Task 2.5 used
   `String.fromEnvironment('FLAVOR')` which silently returns empty string. Must
   pass `--dart-define=FLAVOR=dev` alongside `--flavor dev`.
2. **Task 1.4e would DOWNGRADE Firestore rules** -- Existing rules already have
   `hasOnly()` allowlisting, type validation, and immutable `createdAt`. Must
   augment with string length limits, not replace.
3. **Firestore rules tests need Node.js** -- Task 4.6 proposed Dart-based tests.
   Firestore rules testing requires `@firebase/rules-unit-testing` (Node.js).
4. **Consent gate timing impossible as written** -- Crashlytics must init before
   `runApp()`. Consent dialog renders after. Solution: init Crashlytics in
   disabled mode, enable after consent.
5. **No Firebase Storage rules** -- Task 4.1a adds avatar uploads but plan had
   no `storage.rules`. Added with auth, 5MB limit, content-type restriction.
6. **FCM token refresh race condition** -- Can write token to wrong user during
   sign-out. Subscription never cancelled. Must use service layer, not direct
   Firestore.

### Simplification (from simplicity review)

7. **Phase 4 significantly trimmed** -- Eliminated ConsentService (too
   jurisdiction-specific), AnalyticsService wrapper (premature abstraction), and
   Profile Firestore sync (over-engineered for starter kit).
   SecureStorageService reduced to dependency + comment.
8. **Cut 3 of 4 doc guides** -- Keep removing-features guide only. State
   restoration, deep links, and offline docs removed.

### Key Technical Discoveries

9. **Target Riverpod 3.0** (Sept 2025) -- Unified `Ref` type, `@mutation` for
   side effects, `ref.mounted` check required after async gaps. Function
   providers must become class-based Notifiers.
10. **Flavors != Environments** -- Flavors are build variants (bundle ID,
    Firebase config). Environments are runtime behavior (logging, Crashlytics).
    Keep them as separate concepts that compose.
11. **Avatar uploads need compression** -- 512x512 max, JPEG quality 75, target
    <150KB. Delete old avatar before uploading new one.
12. **Commit .g.dart files** -- Avoids requiring codegen on clone. Add
    `build.yaml` with targeted `generate_for` globs.

### Detailed Review Reports

- `docs/reviews/2026-03-07-flutter-expert-plan-review.md`
- `docs/reviews/2026-03-07-firebase-best-practices-review.md`
- `docs/reviews/2026-03-07-security-review-improvement-plan.md`
- `docs/reviews/2026-03-07-architecture-review-improvement-plan.md`
- `docs/reviews/2026-03-07-plan-simplicity-review.md`
- `docs/plans/2026-03-07-performance-review.md`
- `docs/analysis/2026-03-07-spec-flow-analysis.md`
- `docs/riverpod-codegen-migration-guide.md`
- `docs/flutter-flavors-best-practices.md`

---

## Overview

Four-phase upgrade to the Flutter Firebase Starter Kit covering architectural
integrity, developer experience, test quality, and new capabilities. Each phase
is a discrete release (v1.1-v1.4) that keeps the kit buildable and usable
throughout.

**Origin:**
[Brainstorm document](../brainstorms/2026-03-07-starter-kit-improvements-brainstorm.md)
-- all decisions below were made collaboratively and are documented there.

## Problem Statement

The current kit has a solid foundation but several issues undermine confidence:

- Architectural violation: 3 shared providers import from features/auth/ (6
  import statements)
- Environment config exists but controls nothing
- 37% of source files have no tests; some existing tests are zero-value
- No setup automation, no CI/CD, no l10n, no Flutter flavors
- Riverpod uses manual providers while `riverpod_annotation` sits unused
- ~50+ hardcoded user-facing strings
- ThemeMode missing system default
- Security gaps: missing `allowBackup="false"`, no `flutter_secure_storage`,
  placeholder legal URLs

## Proposed Solution

Four phased releases, each independently valuable:

1. **v1.1 Foundation Integrity** -- fix what's broken or misleading
2. **v1.2 Developer Experience** -- setup automation, flavors, l10n, CI/CD
3. **v1.3 Test Quality** -- fix anti-patterns, shared helpers, close coverage
   gaps
4. **v1.4 New Capabilities** -- profile expansion, analytics, consent gate

## Technical Approach

### Architecture

The kit follows a feature-folder architecture with a composition root in
`main.dart`. Key architectural patterns:

- **Providers** are the dependency injection layer (Riverpod)
- **Services** encapsulate Firebase SDK calls
- **Feature hooks** enable lifecycle coordination without coupling
- **GoRouter** with auth redirect guard gates all routes

All changes preserve these patterns. The Riverpod codegen migration changes
provider declaration syntax but not the architecture.

### Implementation Phases

---

## Phase 1: Foundation Integrity (v1.1) ✅ COMPLETE

_Goal: After this phase, the kit is architecturally honest and sound._

> **Status:** Phase 1 complete as of 2026-03-07. Tasks 1.1, 1.3–1.6 shipped in
> PR #6. Task 1.2 (Riverpod codegen) remains deferred — will migrate directly to
> Riverpod 3.0 when stable to avoid a double migration.

### Task 1.1: Fix shared/ importing from features/auth/

**Problem:** Three shared providers violate the rule that shared/ never imports
from features/:

- `lib/shared/providers/sign_out_provider.dart` -- imports
  `authServiceProvider`, `userProfileServiceProvider`
- `lib/shared/providers/delete_account_provider.dart` -- imports
  `authServiceProvider`, `userProfileServiceProvider`, `authStateProvider`
- `lib/shared/providers/post_auth_bootstrap_provider.dart` -- imports
  `authServiceProvider`, `userProfileProvider`, `userProfileServiceProvider`

**Solution:** Move all three files to `lib/features/auth/providers/`. Update all
imports across the codebase.

**Files to modify:**

- Move `lib/shared/providers/sign_out_provider.dart` ->
  `lib/features/auth/providers/sign_out_provider.dart`
- Move `lib/shared/providers/delete_account_provider.dart` ->
  `lib/features/auth/providers/delete_account_provider.dart`
- Move `lib/shared/providers/post_auth_bootstrap_provider.dart` ->
  `lib/features/auth/providers/post_auth_bootstrap_provider.dart`
- Update imports in: `lib/main.dart`,
  `lib/features/settings/screens/settings_screen.dart`,
  `lib/features/settings/providers/sign_out_test.dart`, and any other files
  referencing these providers
- Remove `lib/shared/providers/feature_hooks.dart` if it only serves these
  providers, or keep if used elsewhere

**Acceptance criteria:**

- [x] Zero imports from `features/` in any file under `lib/shared/`
- [x] All existing tests pass after the move
- [x] `flutter analyze` passes clean

**Ordering:** Do this BEFORE the Riverpod codegen migration (Task 1.2) to avoid
migrating files that will move.

---

### Task 1.2: Migrate to Riverpod codegen ⏳ DEFERRED

> **Status:** Deferred to its own branch. Riverpod 3.0 introduces breaking
> changes (sealed `Override` type, `StreamProvider` disposal behavior,
> `valueOrNull` removal) that cascade across 22 tests. Needs dedicated effort
> with careful test migration. See `docs/riverpod-codegen-migration-guide.md`.

**Problem:** Kit uses manual provider declarations while `riverpod_annotation`
sits unused. No `build_runner` or `riverpod_generator` in pubspec.

**Solution:** Add Riverpod 3.0 codegen pipeline and migrate all 20 providers.

> **RESEARCH INSIGHT (Riverpod 3.0, Sept 2025):** Riverpod 3.0 unified `Ref`
> into a single type, removed AutoDispose interfaces, and added experimental
> `@mutation` for side-effect methods. Notifier instances are now recreated on
> every dependency rebuild -- do not store controllers as instance fields.
> Always check `ref.mounted` before setting state after async gaps. See
> `docs/riverpod-codegen-migration-guide.dart` for complete patterns.

**Step 1: Add dependencies to `pubspec.yaml`**

```yaml
dependencies:
  flutter_riverpod: ^3.0.0
  riverpod_annotation: ^3.0.0

dev_dependencies:
  riverpod_generator: ^3.0.0
  build_runner: ^2.4.14
  custom_lint: ^0.7.0 # already present
  riverpod_lint: ^3.0.0
```

**Step 1b: Add `build.yaml` for targeted codegen**

```yaml
targets:
  $default:
    builders:
      riverpod_generator:
        generate_for:
          - lib/features/**/providers/*.dart
          - lib/shared/providers/*.dart
```

This limits build_runner's scan scope for faster builds. Commit all `.g.dart`
files to avoid requiring codegen on clone.

**Step 2: Migrate providers (leaf-first ordering)**

Migrate service providers (no dependencies) first, then composite providers.

Each provider file gets:

1. `import 'package:riverpod_annotation/riverpod_annotation.dart';`
2. `part '<filename>.g.dart';`
3. Replace manual declaration with `@riverpod` or `@Riverpod(keepAlive: true)`
   annotation

**Migration rules:**

- `Provider` -> `@Riverpod(keepAlive: true)` (was not autoDispose)
- `StreamProvider` -> `@Riverpod(keepAlive: true)` returning `Stream<T>`
- `FutureProvider` -> `@riverpod` returning `Future<T>` (autoDispose is correct
  for data fetching)
- `NotifierProvider` -> `@riverpod` class extending generated `_$ClassName`
- `StateProvider` -> `@riverpod` class with explicit setter methods
  (StateProvider is legacy in 3.0)
- `Provider<Function>` -> **class-based Notifier with action methods** (cannot
  return Function with codegen)

> **CRITICAL:** `Provider<Function>` types (sign_out, delete_account) MUST
> become class-based AsyncNotifiers. This is a behavioral change, not just
> syntax. Example:
>
> ```dart
> @riverpod
> class SignOutAction extends _$SignOutAction {
>   @override
>   FutureOr<void> build() {}
>
>   @mutation
>   Future<void> signOut() async {
>     // ... sign out logic
>     // Always check ref.mounted after async gaps:
>     if (!ref.mounted) return;
>   }
> }
> ```

**Providers to migrate (20 total):**

| File                                                 | Current Type                 | Codegen Annotation           |
| ---------------------------------------------------- | ---------------------------- | ---------------------------- |
| `auth/providers/auth_provider.dart`                  | StreamProvider<User?>        | `@Riverpod(keepAlive: true)` |
| `auth/providers/user_profile_provider.dart`          | StreamProvider<UserProfile?> | `@Riverpod(keepAlive: true)` |
| `auth/providers/auth_service_provider.dart`          | Provider<AuthService>        | `@Riverpod(keepAlive: true)` |
| `auth/providers/user_profile_service_provider.dart`  | Provider<UserProfileService> | `@Riverpod(keepAlive: true)` |
| `auth/providers/sign_out_provider.dart`              | Provider<Function>           | `@Riverpod(keepAlive: true)` |
| `auth/providers/delete_account_provider.dart`        | Provider<Function>           | `@Riverpod(keepAlive: true)` |
| `auth/providers/post_auth_bootstrap_provider.dart`   | FutureProvider               | `@riverpod`                  |
| `home/providers/`                                    | (if any)                     | case-by-case                 |
| `notifications/providers/notification_provider.dart` | Provider                     | `@Riverpod(keepAlive: true)` |
| `onboarding/providers/onboarding_provider.dart`      | NotifierProvider             | `@riverpod` class            |
| `paywall/providers/purchases_provider.dart`          | Provider + StateProvider     | `@Riverpod(keepAlive: true)` |
| `paywall/providers/premium_provider.dart`            | Provider<bool>               | `@Riverpod(keepAlive: true)` |
| `settings/providers/theme_provider.dart`             | NotifierProvider             | `@riverpod` class            |
| `settings/providers/package_info_provider.dart`      | FutureProvider               | `@riverpod`                  |
| `shared/providers/shared_preferences_provider.dart`  | Provider                     | `@Riverpod(keepAlive: true)` |

**Step 3: Update all test files**

Test files that use `provider.overrideWith(...)` or
`provider.overrideWithValue(...)` need updated syntax for codegen providers. The
generated provider types are slightly different.

**Step 4: Run codegen and verify**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test
flutter analyze
```

**Acceptance criteria:**

- [ ] All providers use `@riverpod` or `@Riverpod(keepAlive: true)` annotations
- [ ] `dart run build_runner build` completes without errors
- [ ] All `.g.dart` files are generated and committed
- [ ] All existing tests pass with updated override syntax
- [ ] `flutter analyze` passes clean
- [ ] No manual provider declarations remain

**Edge cases to watch:**

- Providers returning `Function` types (sign_out, delete_account) may need
  restructuring as Notifier classes
- `StateProvider<bool>` for isPremium needs migration to a Notifier with
  explicit state
- Provider overrides in tests need updated syntax (`provider.overrideWith(...)`
  may change)

---

### Task 1.3: Clean up dead artifacts

**Files to remove:**

- `todos/` directory (all 25 items marked complete)
- `CODEBASE_ANALYSIS.md` (agent-generated, not part of kit)
- `SECURITY_AUDIT.md` (agent-generated, not part of kit)
- `dx-analysis.md` (agent-generated, not part of kit)
- `todos/research-report-current-state.md` (agent-generated)

**Files to audit:**

- `pubspec.yaml` -- verify no unused dependencies after codegen migration

**Acceptance criteria:**

- [x] `todos/` directory removed
- [x] No agent-generated analysis files in project root
- [x] `flutter pub get` succeeds
- [x] `flutter analyze` clean

---

### Task 1.4: Security fixes

**1.4a: AndroidManifest.xml -- disable backup**

Add `android:allowBackup="false"` to `<application>` tag in
`android/app/src/main/AndroidManifest.xml`.

**1.4b: Add flutter_secure_storage**

> **SIMPLIFICATION (Simplicity review):** No wrapper class needed. Just add the
> dependency and a comment explaining when to use it.

Add to `pubspec.yaml`:

```yaml
dependencies:
  flutter_secure_storage: ^9.2.4
```

Add a comment in `lib/shared/services/` (or README) explaining:

- Use `FlutterSecureStorage` for: auth tokens, API keys, sensitive user data
- Use `SharedPreferences` for: theme mode, onboarding state, non-sensitive
  preferences
- No wrapper service needed -- use `FlutterSecureStorage()` directly with a
  Riverpod provider

> **NOTE (Architecture review):** Storing API keys in secure storage adds
> complexity for zero real security gain -- keys ship in the binary regardless.
> The primary use case is protecting user-generated secrets (e.g., custom API
> tokens the user enters).

**1.4c: Replace placeholder legal URLs**

In `lib/features/settings/screens/settings_screen.dart`, replace `example.com`
URLs with:

```dart
// TODO: Replace with your app's legal URLs before publishing
const _privacyPolicyUrl = 'https://example.com/privacy';
const _termsOfServiceUrl = 'https://example.com/terms';
```

Add an `assert` in debug mode that warns if these are still `example.com`:

```dart
assert(!_privacyPolicyUrl.contains('example.com'), 'Replace placeholder privacy policy URL before publishing');
```

**1.4d: FCM token refresh**

> **RESEARCH INSIGHT (Firebase + Security reviews):** The original plan called
> Firestore directly, bypassing the service layer. This creates a race condition
> during sign-out (token written to wrong user's document). The subscription is
> also never cancelled (memory leak).

Use the existing service layer and manage the subscription lifecycle:

```dart
// In FCM service - store subscription for cleanup
StreamSubscription? _tokenRefreshSubscription;

void startListening(String uid, UserProfileService profileService) {
  _tokenRefreshSubscription = FirebaseMessaging.instance.onTokenRefresh.listen(
    (newToken) async {
      await profileService.updateFcmToken(uid, newToken);
    },
  );
}

void stopListening() {
  _tokenRefreshSubscription?.cancel();
  _tokenRefreshSubscription = null;
}
```

Call `stopListening()` during sign-out hooks. Also clear the Crashlytics user
identifier on sign-out:

```dart
FirebaseCrashlytics.instance.setUserIdentifier('');
```

**1.4e: Firestore rules -- augment, do NOT replace**

> **RESEARCH INSIGHT (Firebase + Security reviews):** The existing
> `firestore.rules` already has `hasOnly()` field allowlisting, type validation,
> immutable `createdAt`, and email pinning. These are BETTER than what the
> original plan proposed. Only ADD string length limits inside the existing
> `validFields()` function.

Add string length limits to existing validation:

```
function validFields() {
  // ... existing field validation ...
  && request.resource.data.displayName.size() <= 100
  && request.resource.data.email.size() <= 254
  && (!('fcmToken' in request.resource.data) || request.resource.data.fcmToken.size() <= 500)
}
```

**Important:** When Phase 4 adds avatar URL and preferences to the user profile,
update the Firestore rules allowlist to include the new fields, or writes will
be silently rejected.

**Acceptance criteria:**

- [x] `android:allowBackup="false"` in AndroidManifest.xml
- [x] `flutter_secure_storage` in pubspec with usage guidance (no wrapper)
- [x] Legal URLs have debug assert warning + CI gate
- [x] FCM `onTokenRefresh` uses service layer with subscription lifecycle
- [x] Crashlytics user ID cleared on sign-out
- [x] Firestore rules augmented with string length limits (not replaced)
- [x] All tests pass

---

### Task 1.5: ThemeMode system default

**Problem:** Theme toggle is binary light/dark stored as boolean. No
system-follow option.

**Solution:** Change storage from boolean to string enum. Add three-way toggle.

**Files to modify:**

- `lib/features/settings/providers/theme_provider.dart` -- store
  `'system'|'light'|'dark'` string instead of `bool`
- `lib/features/settings/screens/settings_screen.dart` -- three-way toggle
  (system/light/dark) instead of switch
- `lib/config/theme.dart` -- if any changes needed

**Migration:** On first read, if stored value is boolean (`true`/`false`),
migrate to string (`'dark'`/`'light'`). Default to `'system'` for new installs.

**Acceptance criteria:**

- [x] Three theme options: System, Light, Dark
- [x] Default is System for new installs
- [x] Existing boolean values migrate without data loss
- [x] Tests updated for new storage format

---

### Task 1.6: Environment config that works

**Problem:** `dev/staging/prod` enum exists but nothing uses it.

**Solution:** Wire environment to actual behavior changes.

**Files to modify:**

- `lib/config/environment.dart` -- add behavior properties
- `lib/main.dart` -- use environment for Crashlytics, logging
- `lib/app.dart` -- debug banner based on environment

**Implementation:**

```dart
enum Environment {
  dev,
  staging,
  prod;

  bool get enableCrashlytics => this == prod;
  bool get showDebugBanner => this == dev;
  bool get verboseLogging => this != prod;
}
```

Wire in `main.dart`:

```dart
if (EnvironmentConfig.current.enableCrashlytics) {
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
}
```

Wire in `app.dart`:

```dart
debugShowCheckedModeBanner: EnvironmentConfig.current.showDebugBanner,
```

**Acceptance criteria:**

- [x] Crashlytics only enabled in prod
- [x] Debug banner only shown in dev
- [x] Verbose logging in dev/staging, minimal in prod
- [x] Existing `--dart-define=ENV=dev` still works

---

## Phase 2: Developer Experience (v1.2)

_Goal: After this phase, time-to-first-feature is dramatically faster._

### Task 2.1: Setup automation

**Create `Makefile`** at project root:

```makefile
.PHONY: setup get analyze test build-runner clean

setup: ## Initial project setup
	@echo "Checking Flutter version..."
	@flutter --version
	@echo ""
	@echo "Installing dependencies..."
	@flutter pub get
	@echo ""
	@echo "Running code generation..."
	@dart run build_runner build --delete-conflicting-outputs
	@echo ""
	@echo "Running analysis..."
	@flutter analyze
	@echo ""
	@echo "Setup complete! Next steps:"
	@echo "  1. Run 'flutterfire configure' to generate firebase_options.dart"
	@echo "  2. Edit lib/config/app_config.dart (app name, API keys)"
	@echo "  3. Edit lib/config/theme.dart (colors, fonts)"
	@echo "  4. Run 'flutter run' to launch the app"

get: ## Install dependencies
	flutter pub get

analyze: ## Run static analysis
	flutter analyze

test: ## Run all tests
	flutter test

build-runner: ## Run code generation
	dart run build_runner build --delete-conflicting-outputs

watch: ## Watch for changes and regenerate
	dart run build_runner watch --delete-conflicting-outputs

clean: ## Clean build artifacts
	flutter clean
	dart run build_runner clean
	flutter pub get
```

**Acceptance criteria:**

- [x] `make setup` runs full setup flow
- [x] `make test` runs all tests
- [x] `make build-runner` generates codegen files
- [x] `make watch` runs build_runner in watch mode
- [x] All commands documented with `## comments` (visible via `make help`
      pattern)

---

### Task 2.2: Honest the "3 files" promise

**File to modify:** `README.md`

Reframe the setup narrative:

- "3 files to customize your app" (app_config, theme, environment) -- this stays
- "Plus standard Firebase setup" (flutterfire configure)
- "Plus platform config" (bundle IDs in Xcode/Android)
- Add a "Quick Start" section: `git clone` -> `make setup` ->
  `flutterfire configure` -> `flutter run`

**Acceptance criteria:**

- [x] README accurately describes all setup steps
- [x] No false simplicity claims
- [x] Quick Start section with copy-pasteable commands

---

### Task 2.3: Feature surgery guides

**Create `docs/guides/removing-features.md`**

Three sections, one per removable feature:

**Removing Paywall:**

- Delete: `lib/features/paywall/` (entire directory)
- Delete: `test/features/paywall/` (entire directory)
- Remove from `lib/main.dart`: RevenueCat initialization block
- Remove from `lib/routing/router.dart`: paywall route
- Remove from `pubspec.yaml`: `purchases_flutter`
- Set `AppConfig.enablePaywall = false`
- Remove from `lib/shared/widgets/premium_gate.dart` (or keep as no-op)

**Removing Notifications:**

- Delete: `lib/features/notifications/` (entire directory)
- Remove from `lib/main.dart`: FCM initialization block
- Remove from `pubspec.yaml`: `firebase_messaging`
- Set `AppConfig.enableNotifications = false`

**Removing Onboarding:**

- Delete: `lib/features/onboarding/` (entire directory)
- Delete: `test/features/onboarding/` (entire directory)
- Remove from `lib/routing/router.dart`: onboarding route and redirect logic
- Remove `onboardingComplete` field from UserProfile model and Firestore rules

**Acceptance criteria:**

- [x] Each feature has a step-by-step removal checklist
- [ ] Following the checklist results in a compiling, test-passing app
- [ ] Verified by actually performing each removal on a branch (test in CI or
      manually)

---

### Task 2.4: CLAUDE.md improvements

**File to modify:** `CLAUDE.md`

Add:

- Reference to `docs/` directory: "See `docs/guides/` for detailed setup,
  architecture, and feature removal guides"
- Build runner commands:
  `dart run build_runner build --delete-conflicting-outputs`
- Architectural rules: "shared/ never imports from features/. Features may
  import from shared/ and from other features only through the composition root
  (main.dart)."
- Makefile commands reference

**Acceptance criteria:**

- [x] AI assistants can discover docs/ guides
- [x] Build runner commands documented
- [x] Architectural rules explicit

---

### Task 2.5: Flutter flavors setup

**This is the most complex task in Phase 2.**

> **RESEARCH INSIGHT (Flutter Expert + Flavors research):** `--flavor` is an
> Android/iOS build system flag. It does NOT set Dart defines. Using
> `String.fromEnvironment('FLAVOR')` will silently return empty string. Must
> pass `--dart-define=FLAVOR=dev` alongside `--flavor dev`, or use
> `--dart-define-from-file`.

> **ARCHITECTURE INSIGHT:** Flavors != Environments. Flavors are build variants
> (bundle ID, Firebase config). Environments are runtime behavior (logging,
> Crashlytics). Keep them as separate concepts that compose: the flavor
> determines which Firebase project, the environment (passed via
> `--dart-define`) determines runtime behavior.

**Android (`android/app/build.gradle.kts`):**

```kotlin
flavorDimensions += "environment"
productFlavors {
    create("dev") {
        dimension = "environment"
        applicationIdSuffix = ".dev"
        resValue("string", "app_name", "StarterKit Dev")
    }
    create("staging") {
        dimension = "environment"
        applicationIdSuffix = ".staging"
        resValue("string", "app_name", "StarterKit Staging")
    }
    create("prod") {
        dimension = "environment"
        resValue("string", "app_name", "StarterKit")
    }
}
```

**iOS:** Create 9 build configurations (Debug/Release/Profile x 3 flavors) and 3
shared schemes. This is error-prone -- consider `flutter_flavorizr` for initial
bootstrap, then own the generated files.

- `ios/Flutter/Dev.xcconfig`
- `ios/Flutter/Staging.xcconfig`
- `ios/Flutter/Prod.xcconfig`

> **PITFALL (Flavors research):** iOS schemes MUST be marked "Shared" or CI will
> break. Configuration naming must follow `Debug-dev`/`Release-dev` pattern
> exactly. Run `pod install` after adding configurations.

**Firebase config per flavor:**

Use `flutterfire configure` with flavor-specific flags:

```bash
#!/bin/bash
# scripts/flutterfire-config.sh
for flavor in dev staging prod; do
  flutterfire configure \
    --project=your-project-$flavor \
    --out=lib/firebase_options_$flavor.dart \
    --ios-bundle-id=com.example.app.$flavor \
    --android-app-id=com.example.app.$flavor \
    --android-out=android/app/src/$flavor/google-services.json \
    --ios-out=ios/config/$flavor/GoogleService-Info.plist
done
```

**Multiple entry points pattern (recommended):**

```dart
// lib/main_dev.dart
void main() => bootstrap(Environment.dev);

// lib/main_staging.dart
void main() => bootstrap(Environment.staging);

// lib/main_prod.dart
void main() => bootstrap(Environment.prod);

// lib/bootstrap.dart
Future<void> bootstrap(Environment env) async {
  EnvironmentConfig.init(env);
  // ... rest of initialization
}
```

**Update run commands:**

```bash
flutter run --flavor dev -t lib/main_dev.dart
flutter run --flavor staging -t lib/main_staging.dart
flutter run --flavor prod -t lib/main_prod.dart
```

**Keep `--dart-define=ENV=` as fallback** in the single `main.dart` for
developers who don't need flavors yet.

**Acceptance criteria:**

- [x] `flutter run --flavor dev -t lib/main_dev.dart` launches with `.dev`
      suffix
- [x] `flutter run --flavor prod -t lib/main_prod.dart` launches with production
      bundle ID
- [ ] Each flavor uses its own Firebase config (requires multiple Firebase
      projects — see `docs/guides/ios-flavor-schemes.md`)
- [x] App name differs per flavor
- [x] Environment is set via entry point, not `String.fromEnvironment`
- [x] `--dart-define=ENV=` still works as fallback in `main.dart`
- [x] CLAUDE.md and Makefile updated with flavor commands
- [ ] iOS schemes marked as "Shared" (requires manual Xcode setup — see
      `docs/guides/ios-flavor-schemes.md`)

**Edge cases:**

- Run `flutterfire configure` per flavor using the script above
- iOS scheme setup requires Xcode project modifications (document manual steps)
- CocoaPods needs `pod install` after adding iOS configurations
- Flavor names must be lowercase

---

### Task 2.6: l10n scaffolding

**Step 1: Enable in `pubspec.yaml`:**

```yaml
flutter:
  generate: true
```

**Step 2: Create `l10n.yaml`:**

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
```

**Step 3: Create `lib/l10n/app_en.arb`:**

Extract ~50+ hardcoded strings from across the codebase. Key files:

- `lib/features/auth/screens/auth_screen.dart`
- `lib/features/onboarding/screens/onboarding_screen.dart`
- `lib/features/settings/screens/settings_screen.dart`
- `lib/features/paywall/screens/paywall_screen.dart`
- `lib/features/home/screens/home_screen.dart`
- `lib/shared/widgets/loading_state.dart`
- `lib/shared/widgets/premium_gate.dart`
- `lib/shared/widgets/error_screen.dart`
- `lib/shared/widgets/empty_state.dart`

**Step 4: Update `lib/app.dart`:**

```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

MaterialApp.router(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  // ...
)
```

**Step 5: Replace hardcoded strings in widgets:**

```dart
// Before:
Text('Sign in to continue')
// After:
Text(AppLocalizations.of(context)!.signInPrompt)
```

**Acceptance criteria:**

- [x] `flutter gen-l10n` generates localization files
- [x] All user-facing strings extracted to `app_en.arb`
- [x] Widgets use `AppLocalizations.of(context)` for strings
- [x] Adding a new locale is documented (create `app_XX.arb`, add locale to
      supported list)
- [x] Dynamic strings with interpolation handled correctly (e.g., "Hello,
      {name}")

**Edge cases:**

- Error messages from Firebase exceptions should NOT be localized (they come
  from the SDK)
- Strings in `AppConfig` (app name) stay as config, not l10n
- Plural forms documented but not required for English-only

---

### Task 2.7: CI/CD with GitHub Actions

**Create `.github/workflows/ci.yml`:**

```yaml
name: CI
on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

jobs:
  analyze-and-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: "3.27.x"
          channel: "stable"
      - run: flutter pub get
      - run: dart run build_runner build --delete-conflicting-outputs
      - run: flutter analyze
      - run: flutter test
```

**Acceptance criteria:**

- [x] CI runs on PR and push to main
- [x] Runs analyze + test
- [x] Uses current Flutter stable version
- [x] Build runner step included for codegen

---

### Task 2.8: Visual identity

- Run the app on iOS simulator, capture 3 screenshots: Auth screen, Home screen,
  Settings screen
- Add to `docs/screenshots/` directory
- Reference in README with relative paths

**Acceptance criteria:**

- [x] At least 3 screenshots in README (placeholder table + capture instructions
      added; requires running app on simulator to capture actual images)
- [ ] Screenshots show actual app UI, not mockups (requires manual capture)

---

## Phase 3: Test Quality (v1.3)

_Goal: After this phase, the test suite inspires confidence, not doubt._

### Task 3.1: Delete zero-value tests

**Delete or rewrite:**

- `test/features/paywall/services/purchases_service_test.dart` -- tests
  mocktail, not code. Delete entirely.
- `test/app_test.dart` -- misleadingly named, duplicates
  `auth_provider_test.dart`. Delete.

**Acceptance criteria:**

- [x] No test file exists that only tests mock framework behavior
- [x] `flutter test` still passes

---

### Task 3.2: Fix router redirect tests

**File:** `test/routing/router_test.dart`

Lines 116-184 assert provider state but never invoke the redirect function.
Rewrite to actually test the redirect:

```dart
test('redirects unauthenticated user to /auth', () {
  final redirect = routerRedirect(authState: null, userProfile: null);
  final location = redirect(GoRouterState(/* path: '/home' */));
  expect(location, '/auth');
});

test('redirects authenticated user on /auth to /home', () {
  final redirect = routerRedirect(authState: mockUser, userProfile: completedProfile);
  final location = redirect(GoRouterState(/* path: '/auth' */));
  expect(location, '/home');
});

test('redirects to /onboarding when onboarding not complete', () {
  final redirect = routerRedirect(authState: mockUser, userProfile: incompleteProfile);
  final location = redirect(GoRouterState(/* path: '/home' */));
  expect(location, '/onboarding');
});
```

**Acceptance criteria:**

- [x] Router redirect tests invoke the actual redirect logic
- [x] Tests cover: unauth -> /auth, auth on /auth -> /home, onboarding
      incomplete -> /onboarding
- [x] Tests pass

---

### Task 3.3: Create shared test helpers

> **ORDERING INSIGHT (SpecFlow analysis):** Consider creating these helpers
> during Phase 1's codegen migration (Task 1.2), since every test file will be
> touched anyway for provider override syntax updates. Creating helpers at the
> same time avoids double-touching all test files.

**Create `test/helpers/mocks.dart`:**

```dart
import 'package:mocktail/mocktail.dart';
// ... imports

class MockAuthService extends Mock implements AuthService {}
class MockUser extends Mock implements User {}
class MockUserProfileService extends Mock implements UserProfileService {}
class MockUserCredential extends Mock implements UserCredential {}
// ... other shared mocks
```

**Create `test/helpers/pump_app.dart`:**

```dart
extension PumpApp on WidgetTester {
  Future<void> pumpApp(
    Widget widget, {
    List<Override> overrides = const [],
  }) async {
    await pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(home: widget),
      ),
    );
  }
}
```

**Create `test/helpers/fixtures.dart`:**

```dart
UserProfile createTestProfile({
  String uid = 'test-uid',
  String? email = 'test@example.com',
  String? displayName = 'Test User',
  bool onboardingComplete = true,
}) {
  return UserProfile(
    uid: uid,
    email: email,
    displayName: displayName,
    onboardingComplete: onboardingComplete,
    createdAt: DateTime(2026, 1, 1),
  );
}
```

**Migrate existing tests** to use shared helpers. Remove duplicate mock
declarations from individual test files.

**Acceptance criteria:**

- [x] `test/helpers/mocks.dart` contains all shared mock classes
- [x] `test/helpers/pump_app.dart` provides `pumpApp` helper
- [x] `test/helpers/fixtures.dart` provides test data factories
- [x] No duplicate mock class declarations across test files
- [x] All tests pass after migration

---

### Task 3.4: Close critical coverage gaps

**3.4a: Sign-in flow tests**
(`test/features/auth/services/auth_service_test.dart`)

Add tests for `signInWithGoogle()` and `signInWithApple()`:

- Successful sign-in returns UserCredential
- Cancelled sign-in throws appropriate exception
- Network error propagates
- Mock GoogleSignIn and SignInWithApple at the service boundary

**3.4b: Onboarding screen widget test**
(`test/features/onboarding/screens/onboarding_screen_test.dart`)

- Renders first page by default
- Swiping advances to next page
- "Get Started" button appears on last page
- Completing onboarding navigates away

**3.4c: Notification provider test**
(`test/features/notifications/providers/notification_provider_test.dart`)

- Provider creates FCM service correctly
- Feature flag disables notification init

**3.4d: Environment config test** (`test/config/environment_test.dart`)

- Parses `dev`, `staging`, `prod` correctly
- Defaults to `dev` when no value provided
- Environment properties return correct values per environment

**Acceptance criteria:**

- [x] Sign-in flows have tests for success, cancellation, and error paths
- [x] Onboarding screen has widget tests for navigation and completion
- [x] Notification provider has basic wiring test
- [x] Environment config parsing is tested
- [x] All new tests pass

---

### Task 3.5: Fix purchases_provider_test

**File:** `test/features/paywall/providers/purchases_provider_test.dart`

Stop re-implementing `isPremiumProvider` logic in test overrides. Instead,
provide mock dependencies and test the actual provider:

```dart
test('isPremiumProvider returns true when active entitlement exists', () async {
  // Mock the customerInfo that purchases_provider depends on
  // Let the actual isPremiumProvider derive the value
  // Assert the result
});
```

**Acceptance criteria:**

- [x] Test exercises real provider logic, not re-implemented logic
- [x] Covers: no entitlements -> false, active entitlement -> true
- [x] Test passes

---

### Task 3.6: Integration test foundation

**Create `integration_test/app_test.dart`:**

A single end-to-end flow with all Firebase services mocked via provider
overrides:

1. App launches -> auth screen shown
2. Sign in -> post-auth bootstrap runs -> onboarding shown (if first time)
3. Complete onboarding -> home screen shown
4. Navigate tabs -> profile visible

**Acceptance criteria:**

- [x] Integration test runs with `flutter test integration_test/`
- [x] Tests the full auth -> onboarding -> home flow
- [x] All external services mocked (no Firebase dependency)
- [x] Establishes the pattern for future integration tests

---

## Phase 4: New Capabilities (v1.4)

_Goal: After this phase, the kit teaches real-world patterns Robert will use._

### Task 4.1a: Profile CRUD (core)

**Add Firebase Storage dependency:**

```yaml
dependencies:
  firebase_storage: ^12.4.4
  image_picker: ^1.1.2
```

> **RESEARCH INSIGHT (Flutter Expert + Performance + Security reviews):**
>
> - Add `NSCameraUsageDescription` and `NSPhotoLibraryUsageDescription` to iOS
>   `Info.plist`
> - Add `android.permission.CAMERA` to AndroidManifest.xml
> - Compress images before upload: 512x512 max, JPEG quality 75, target <150KB
> - Delete old avatar before uploading new one
> - Debounce display name saves by 500ms
> - Use `CachedNetworkImage` for avatar display
> - Inject `FirebaseStorage` and `ImagePicker` via providers for testability

**Create `storage.rules`** (CRITICAL -- missing from original plan):

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{uid}/avatar.jpg {
      allow read: if request.auth != null;
      allow write: if request.auth != null
        && request.auth.uid == uid
        && request.resource.size < 5 * 1024 * 1024
        && request.resource.contentType.matches('image/.*');
      allow delete: if request.auth != null && request.auth.uid == uid;
    }
  }
}
```

**Create/modify files:**

- `lib/features/profile/services/profile_storage_service.dart` -- upload/delete
  avatar with compression
- `lib/features/profile/providers/profile_edit_provider.dart` -- edit state as
  AsyncNotifier
- `lib/features/profile/screens/profile_screen.dart` -- expand with edit
  capabilities
- `lib/features/profile/widgets/avatar_picker.dart` -- camera/gallery picker +
  upload
- `storage.rules` -- Firebase Storage security rules

**Profile screen layout:**

- Tappable avatar with camera overlay icon
- Editable display name with inline save (debounced 500ms)
- Email (read-only, from auth)
- Profile completion indicator

**Account deletion must also delete Storage avatars** -- add to the delete
account flow.

**Acceptance criteria:**

- [x] User can upload/change avatar from camera or gallery
- [x] Images compressed before upload (<150KB target)
- [x] Old avatar deleted before new upload
- [x] Avatar stored in Firebase Storage at `users/{uid}/avatar.jpg`
- [x] `storage.rules` deployed with auth, size, and content-type restrictions
- [x] Display name editable via dialog
- [x] Profile completion shows percentage based on filled fields
- [x] Delete account flow removes Storage avatar
- [x] All new code has tests

---

### Task 4.1b: Account actions migration

**Move from Settings to Profile:**

- Sign out button
- Delete account button (with confirmation dialog)

**Settings retains:**

- Appearance (theme toggle)
- Subscription status / manage subscription
- About (version, legal links, feedback)

**Files to modify:**

- `lib/features/settings/screens/settings_screen.dart` -- remove Account section
- `lib/features/profile/screens/profile_screen.dart` -- add Account section at
  bottom

**Acceptance criteria:**

- [x] Sign out and delete account accessible from Profile
- [x] Settings no longer has Account section
- [x] Navigation still works correctly
- [x] Existing tests updated

---

### Task 4.1c: Profile preferences

> **SIMPLIFICATION (Simplicity + Architecture reviews):** Bidirectional
> SharedPreferences-to-Firestore sync is real application logic, not starter
> scaffolding. Use SharedPreferences only -- it's the right default.
> Cross-device sync is a feature developers add when they need it.

**Add to profile screen:**

- Notification toggle (stored in SharedPreferences, controls FCM)
- Theme selection (already exists in settings -- add to profile as well, or move
  here)

**Acceptance criteria:**

- [x] Notification preference persists locally
- [ ] Theme selection works from profile (kept in Settings only — avoids
      duplication)
- [x] Tests cover toggle behavior

---

### Task 4.2: Analytics example

> **SIMPLIFICATION (Simplicity review):** `FirebaseAnalytics` already has a
> clean API. A wrapper class is premature abstraction. Instead, add 2-3 inline
> usage examples directly in screens.

Add `FirebaseAnalytics` calls directly to 2-3 screens as examples:

```dart
// In auth screen after successful sign-in:
FirebaseAnalytics.instance.logLogin(loginMethod: 'google');

// In paywall screen:
FirebaseAnalytics.instance.logEvent(name: 'purchase_started', parameters: {'product_id': productId});

// Screen views (add to any screen's initState or build):
FirebaseAnalytics.instance.logScreenView(screenName: 'settings');
```

Add a Riverpod provider for `FirebaseAnalytics.instance` to enable mocking in
tests.

**Acceptance criteria:**

- [x] 2-3 screens demonstrate analytics usage inline
- [x] Analytics observer on router for screen views
- [x] No wrapper service class -- use Firebase API directly

---

### Task 4.3: Consent gate (simplified)

> **SIMPLIFICATION (Simplicity + Firebase + Security reviews):** Full
> ConsentService with GDPR granular categories is jurisdiction-specific -- every
> app's requirements differ. Provide a minimal pattern and a TODO.

> **RESEARCH INSIGHT (Firebase review):** Crashlytics must initialize BEFORE
> `runApp()` to catch early crashes. Init in disabled mode, enable after
> consent. Firebase provides NO client-side API to delete existing Crashlytics
> data -- don't claim it does.

**Minimal implementation:**

1. In `main.dart`, init Crashlytics with
   `setCrashlyticsCollectionEnabled(false)`
2. Check SharedPreferences for `analytics_consent` boolean
3. If consent given, enable collection: `setCrashlyticsCollectionEnabled(true)`
4. If no consent yet, show a simple dialog after first auth
5. Add a TODO comment:
   `// TODO: Customize consent flow for your jurisdiction (GDPR, CCPA, etc.)`

**No separate ConsentService file.** Just a SharedPreferences read + a dialog
widget.

**Acceptance criteria:**

- [x] Crashlytics inits disabled, enables after consent
- [x] Consent stored in SharedPreferences
- [x] Simple consent dialog exists
- [x] TODO comment guides jurisdiction-specific customization

---

### Task 4.4: Firestore rules testing

> **RESEARCH INSIGHT (Firebase review):** Firestore rules tests require Node.js
> `@firebase/rules-unit-testing`. Cannot use Dart.

**Set up Firebase emulator:**

- Update `firebase.json` with emulator config (file exists but is empty)
- Create `test/rules/firestore.test.js` using `@firebase/rules-unit-testing`
- Add `test/rules/package.json` with test dependencies

**Test scenarios:**

- Authenticated user can read/write own document
- Authenticated user cannot read/write other user's document
- Unauthenticated user cannot read/write anything
- String length limits enforced
- Required fields validated
- Storage rules: file size and content-type restrictions

**Acceptance criteria:**

- [x] Firebase emulator config in `firebase.json`
- [x] Node.js rules tests cover all CRUD operations
- [x] `npm test` in `test/rules/` runs the tests
- [x] Storage rules tested alongside Firestore rules
- [x] Documented as separate step (not part of `flutter test`)

---

## System-Wide Impact

### Interaction Graph

- **Riverpod codegen migration** touches every provider and every test file that
  overrides a provider. This is the highest-risk change.
- **Flavor setup** touches Android build.gradle, iOS project.pbxproj, and
  environment.dart. Interacts with Firebase config generation.
- **l10n** touches every widget file with user-facing strings (~10 files).
- **Profile expansion** creates new dependency on Firebase Storage and
  image_picker.
- **Consent gate** inserts itself before Crashlytics/Analytics initialization in
  main.dart.

### Error Propagation

- Provider migration errors surface as compile-time errors (type mismatches) or
  runtime errors (incorrect override syntax in tests). Both are caught by
  `flutter analyze` + `flutter test`.
- Flavor misconfiguration surfaces as build failures -- caught early.
- l10n missing keys surface as null assertion errors at runtime -- mitigated by
  `AppLocalizations.of(context)!` pattern.

### State Lifecycle Risks

- **ThemeMode migration:** Old boolean -> new string. Must handle both formats
  during transition. Risk: user loses theme preference on upgrade. Mitigation:
  migration logic in provider.
- **Consent gate:** Must not block app launch if consent state is unknown.
  Default to "not consented" (safe) and prompt.

### Integration Test Scenarios

1. Fresh install -> consent prompt -> auth -> onboarding -> home (full happy
   path)
2. Returning user -> auto-auth -> home (skip onboarding)
3. Sign out -> clears state -> returns to auth
4. Delete account -> reauth -> data deleted -> auth screen
5. Theme change -> persists across app restart

---

## Acceptance Criteria

### Functional Requirements

- [ ] All architectural violations resolved
- [ ] All 20 providers use Riverpod codegen
- [ ] Environment config controls real behavior
- [ ] Flutter flavors work for dev/staging/prod
- [ ] All user-facing strings in l10n .arb files
- [ ] CI/CD runs on every PR
- [ ] Feature surgery guides verified by actual removal
- [ ] Profile CRUD with avatar upload works
- [ ] Analytics events fire correctly
- [ ] Consent gate blocks data collection until approved

### Non-Functional Requirements

- [ ] `flutter analyze` passes clean after each phase
- [ ] All tests pass after each phase
- [ ] No regression in app startup time
- [ ] Kit remains usable (buildable, runnable) after each phase

### Quality Gates

- [ ] Each phase is a separate PR/branch
- [ ] Tests cover all new code
- [ ] CLAUDE.md updated after each phase
- [ ] README updated if user-facing changes

---

## Dependencies & Prerequisites

| Phase   | Depends On                                                        | Blocked By |
| ------- | ----------------------------------------------------------------- | ---------- |
| Phase 1 | Nothing                                                           | --         |
| Phase 2 | Phase 1 (codegen must be done for Makefile build-runner commands) | --         |
| Phase 3 | Phase 1 (provider syntax must be stable before writing new tests) | --         |
| Phase 4 | Phase 1 + 2 (l10n must be in place for new UI strings)            | --         |

**Within Phase 1:** Task 1.1 (move files) MUST complete before Task 1.2 (codegen
migration).

**Within Phase 2:** Task 2.5 (flavors) and Task 2.6 (l10n) are independent and
can be parallelized.

---

## Risk Analysis & Mitigation

| Risk                                      | Likelihood | Impact | Mitigation                                           |
| ----------------------------------------- | ---------- | ------ | ---------------------------------------------------- |
| Riverpod codegen migration breaks tests   | High       | Medium | Migrate one provider at a time, run tests after each |
| Flutter flavors break iOS build           | Medium     | High   | Test on real device after setup, not just simulator  |
| l10n extraction misses strings            | Medium     | Low    | Run app through all screens to verify, add lint rule |
| Firebase config per flavor confuses setup | Medium     | Medium | Document clearly, add to setup script                |
| Profile CRUD scope creep                  | High       | Medium | Strict scope per 4.1a/b/c split                      |

---

## Sources & References

### Origin

- **Brainstorm document:**
  [docs/brainstorms/2026-03-07-starter-kit-improvements-brainstorm.md](../brainstorms/2026-03-07-starter-kit-improvements-brainstorm.md)
- Key decisions carried forward: Riverpod codegen adoption, full Flutter
  flavors, l10n scaffolding, profile split into 3 tasks, deep links as docs-only

### Internal References

- Provider files: `lib/features/*/providers/*.dart`
- Shared providers (violation): `lib/shared/providers/sign_out_provider.dart`,
  `delete_account_provider.dart`, `post_auth_bootstrap_provider.dart`
- Settings screen: `lib/features/settings/screens/settings_screen.dart`
- Profile screen: `lib/features/profile/screens/profile_screen.dart`
- Firestore rules: `firestore.rules`
- AndroidManifest: `android/app/src/main/AndroidManifest.xml`
- Environment config: `lib/config/environment.dart`
- Theme provider: `lib/features/settings/providers/theme_provider.dart`

### Institutional Learnings

- Account deletion order: re-auth -> Firestore delete -> auth delete (not
  auth-first, which breaks Firestore rules)
- Router redirect is synchronous: cannot await Firestore in redirect function
- Firestore rules: granular rules must be merged into each statement (OR logic
  gotcha)
- RevenueCat: mock at service level, not instance level (`Purchases.instance`
  doesn't exist)
