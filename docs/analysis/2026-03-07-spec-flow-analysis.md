# Spec Flow Analysis: 4-Phase Improvement Plan

Generated: 2026-03-07

## Phase 1: Riverpod Codegen Migration

### Critical Ordering Dependency
The shared/auth violation fix (1.1) MUST complete before codegen migration (1.2). Moving `sign_out_provider`, `delete_account_provider`, and `post_auth_bootstrap_provider` into `features/auth/providers/` changes file paths. If codegen runs first, generated `.g.dart` files will reference old paths and need regeneration.

### Provider Dependency Chain at Risk
The following chain must be preserved during migration:
```
authStateProvider (StreamProvider<User?>)
  -> userProfileProvider (StreamProvider<UserProfile?>) watches authStateProvider
  -> deleteAccountProvider (FutureProvider<void>) reads authStateProvider, authServiceProvider, userProfileServiceProvider
  -> signOutProvider reads authServiceProvider, userProfileServiceProvider
  -> postAuthBootstrapProvider reads authStateProvider, userProfileProvider
```

### Codegen Breaking Changes
1. **`overrideWithValue` not supported on generated providers.** Tests currently use `authServiceProvider.overrideWithValue(mockAuthService)` in at least 4 test files (sign_out_test.dart, settings_screen_test.dart, others). After codegen, these must change to `authServiceProvider.overrideWith((ref) => mockAuthService)`.

2. **`NotifierProvider` syntax changes.** `ThemeModeNotifier` extends `Notifier<ThemeMode>` with manual `NotifierProvider` construction. Under codegen, it becomes `@riverpod class ThemeModeNotifier` and the generated provider name changes from `themeModeProvider` to `themeModeNotifierProvider` unless explicitly annotated. Every `ref.watch(themeModeProvider)` call breaks.

3. **`keepAlive` semantics.** `packageInfoProvider` uses `ref.keepAlive()` inside the provider body. Under codegen, this becomes `@Riverpod(keepAlive: true)` on the annotation. If missed, the provider becomes autoDispose and will re-fetch `PackageInfo.fromPlatform()` on every screen rebuild.

4. **`isPremiumProvider` is overridden in main.dart** with complex conditional logic based on `AppConfig.enablePaywall`. Generated providers may not support the same override pattern. This provider needs special handling -- potentially remaining manual or using a dedicated abstract class.

5. **Provider names with "Provider" suffix.** Codegen auto-appends "Provider" to function names. A function named `authState` generates `authStateProvider`. If the migration names functions `authStateProvider`, the generated name becomes `authStateProviderProvider`. Every provider function must be renamed to drop the "Provider" suffix.

### Missing from Spec
- No rollback plan if codegen migration partially fails
- No mention of adding `part` directives to each provider file
- No mention of running `dart run build_runner build --delete-conflicting-outputs` and verifying output
- No guidance on whether to migrate all providers in one PR or incrementally

---

## Phase 1: Shared/Auth Violation Fix

### Import Cascade
Moving 3 providers creates a 12+ file import update. Files affected:
- `lib/features/settings/screens/settings_screen.dart` (imports delete_account, sign_out, feature_hooks)
- `lib/features/paywall/widgets/premium_gate.dart` (imports premium_provider)
- `lib/main.dart` (imports feature_hooks, premium_provider, shared_preferences_provider)
- `lib/app.dart` (imports post_auth_bootstrap_provider)
- All test files that override these providers (~6 test files)

### Circular Dependency Risk
After moving `sign_out_provider` and `delete_account_provider` to `features/auth/providers/`, the Settings screen will import from `features/auth/`. This is architecturally valid (features CAN import from other features), but creates a coupling where deleting the auth feature breaks settings. The spec should clarify whether this is acceptable or if an abstraction layer (interface in shared/) is needed.

### What Stays in shared/providers/?
The spec says to move 3 providers but does not address:
- `feature_hooks.dart` -- currently in shared/, imported by the 3 moved providers AND by main.dart. Does it stay or move?
- `premium_provider.dart` -- in shared/ but overridden conditionally in main.dart. If it moves to features/paywall/, it contradicts the "features are independently deletable" principle since settings_screen.dart imports it.
- `shared_preferences_provider.dart` -- stays, but should be documented as the one legitimate shared provider.

---

## Phase 2: Flutter Flavors Setup

### Breaking the Existing --dart-define Approach
Current code in `environment.dart` uses `String.fromEnvironment('ENV', defaultValue: 'dev')`. The spec says "Update environment.dart to read from flavor instead of --dart-define." This is a breaking change for any existing CI/CD, developer workflows, or documentation. The spec does not specify:
- Will `--dart-define=ENV=prod` still work as a fallback?
- How does a flavor map to the Environment enum?
- What happens on web/desktop where flavors don't exist? (Even if out of scope, the code should not crash.)

### Firebase Config Per Flavor -- Missing Details
Each flavor needs its own `google-services.json` (Android) and `GoogleService-Info.plist` (iOS). The spec mentions this but does not address:
- Do 3 separate Firebase projects exist, or 3 apps within one project?
- Where are the config files stored? (`android/app/src/dev/`, `android/app/src/staging/`, `android/app/src/prod/`?)
- The current `FirebaseService.initialize()` uses `DefaultFirebaseOptions` from `firebase_options.dart`. How do per-flavor options get selected?
- `flutterfire configure` generates a single `firebase_options.dart`. With flavors, you need per-flavor options or conditional logic.

### Android applicationId Implications
Different `applicationId` per flavor means:
- Separate Play Store listings OR separate tracks in the same listing
- Existing `google-services.json` must match each applicationId
- Deep links configured for one applicationId will not work for another
- FCM tokens are per-applicationId -- push notifications need separate setup per flavor

---

## Phase 2: l10n Migration

### Dynamic Strings with Interpolation
The codebase has interpolated strings that need parameterized ARB entries:
- `Text(isPremium ? 'Premium' : 'Free')` -- conditional string, needs two ARB keys or a parameterized one
- `Text('Version ...')` -- needs `"settingsVersion": "Version {version}"` with placeholder
- Error messages from Firebase (`e.code` switch) -- need parameterized error strings
- `SnackBar(content: Text(message))` where message comes from async operations -- the l10n context may not be available

### Missing from Spec
- How to handle strings in non-widget contexts (services, providers) where `BuildContext` is unavailable for `AppLocalizations.of(context)`
- Whether error messages from Firebase SDKs should be localized or passed through
- Plural forms (e.g., "1 item" vs "2 items") -- even if not currently used, the ARB scaffolding should demonstrate the pattern
- String keys naming convention (e.g., `settingsScreenTitle` vs `settings_screen_title` vs `settingsTitle`)
- Whether to use `context.l10n.key` extension method or `AppLocalizations.of(context)!.key`

---

## Phase 3: Test Helpers

### Risk: Over-Generalized Shared Mocks
The spec calls for shared test helpers but does not address:
- Tests that need slightly different mock return values (e.g., one test needs `authStateProvider` to emit a user, another needs null). A shared helper that always returns a logged-in user would force test authors to re-override.
- The `ProviderScope` override pattern in main.dart uses conditional overrides (`if (AppConfig.enablePaywall)`). Test helpers need to replicate this conditionality or tests will diverge from production behavior.
- Mock class instances vs mock provider overrides -- currently tests mix both patterns. The helpers should standardize on one approach.

### Ordering Dependency
Test helpers (Phase 3) should ideally be created BEFORE or DURING the Riverpod codegen migration (Phase 1), since every test file will need updating during migration. Doing them in Phase 3 means touching all test files twice.

---

## Phase 4: Profile Expansion and Account Actions Migration

### Navigation Flow Changes
Currently the bottom nav has tabs and adding Profile creates a new destination.

Missing specifications:
- Does Profile get its own tab in the bottom nav, or is it accessed from an avatar/icon in the app bar?
- If Profile is a new tab, the `StatefulShellRoute` in router.dart needs a third branch. What index does it get?
- What route path? `/profile` presumably, but this needs to be added to `AppRoutes`.
- What happens to the "Account" section in SettingsScreen after sign-out and delete-account move to Profile? The section becomes empty and should be removed, but the spec does not confirm this.

### Delete Account Flow After Migration
The delete account flow includes a confirmation dialog, re-authentication, and multi-step cleanup. Moving it to Profile means:
- The `_showDeleteConfirmation` dialog logic moves to ProfileScreen
- The `_isDeleting` state and error handling (FirebaseAuthException catch) must move too
- If re-authentication fails with `requires-recent-login`, the user needs to sign out and sign back in. But they are on the Profile screen, not Settings. The UX flow for this error state needs clarification.

---

## Phase 4: Consent Gate

### Critical: Crashlytics Initializes Before Any UI
In `main.dart`, Crashlytics error handlers are set up BEFORE `runApp()`. A consent gate that shows a UI prompt CANNOT gate this initialization because it happens before any widget renders. The spec does not address this fundamental timing problem.

### Proposed Resolution Options (Spec Should Pick One)
1. **Initialize Crashlytics disabled, enable after consent.** Call `setCrashlyticsCollectionEnabled(false)` in main.dart, show consent prompt on first frame, then call `setCrashlyticsCollectionEnabled(true)` if consented. Crashes before consent are lost.
2. **Deferred initialization.** Do not set up error handlers in main.dart. Instead, set them up after consent in a provider. Crashes during app startup before consent are unhandled.
3. **Consent on install, not on first launch.** Use app store descriptions to imply consent (legally weak in EU).

### Missing Consent Specifications
- What UI pattern? Full-screen modal, bottom sheet, or inline banner?
- Can the user dismiss without choosing? If so, what is the default (opt-out)?
- Where is consent state stored? SharedPreferences is mentioned, but this is not encrypted. For GDPR, consent records may need timestamps and version tracking.
- Can the user change their mind later? If so, where in the UI? (Settings screen presumably, but the spec does not say.)
- Does revoking consent require deleting already-collected data? GDPR says yes.
- Analytics events are currently fired directly in widget code (auth_screen.dart, onboarding_screen.dart). Every `FirebaseAnalytics.instance.logEvent()` call needs to check consent state first. The spec does not mention wrapping these calls.
- `post_auth_bootstrap_provider` sets Crashlytics user identifier and Analytics user properties. These must also be gated on consent.

---

## Cross-Phase Ordering Dependencies

```
1.1 (shared/auth fix) -> 1.2 (codegen migration)  [file paths must be stable before codegen]
1.2 (codegen migration) -> 3.x (all test work)     [test override syntax changes with codegen]
2.5 (flavors) -> 2.7 (CI/CD)                       [CI needs to know about flavors]
4.1a (profile CRUD) -> 4.1b (account actions move)  [profile screen must exist first]
4.3 (consent gate) -> 4.2 (analytics taxonomy)      [taxonomy is moot if analytics are gated]
```

### Risky Parallel Work
- Phase 2 l10n (2.6) touches every screen's strings. Phase 4 profile expansion (4.1) adds new screens with new strings. If done in parallel, merge conflicts are guaranteed. L10n should complete first, or profile strings should be added as l10n entries from the start.
- Phase 1 codegen (1.2) and Phase 3 test fixes (3.1-3.5) both modify test files. Doing them in sequence (1.2 first) avoids double-work.

---

## Summary of Critical Questions

1. **Codegen + overrideWithValue:** How will the ~15 test files using `overrideWithValue` be migrated? Will you accept `overrideWith` as a universal replacement, or do some providers need to remain manual?

2. **isPremiumProvider override in main.dart:** This provider is conditionally overridden with complex logic. How does this work under codegen? Does it stay manual?

3. **feature_hooks.dart location:** After moving 3 providers to auth, does `feature_hooks.dart` stay in shared/ or move? It is imported by main.dart (composition root) AND by the moved providers.

4. **Flavor fallback:** Will `--dart-define=ENV=prod` continue to work after flavors are added, for developers who have not set up Xcode schemes?

5. **Firebase config per flavor:** Are there 3 Firebase projects or 3 apps in one project? Where do the per-flavor config files live?

6. **Crashlytics timing vs consent:** Which of the three resolution options (initialize-disabled, deferred-init, or store-consent) will be used?

7. **Consent revocation:** Does revoking analytics consent trigger deletion of previously collected data?

8. **Profile tab position:** Is Profile a new bottom nav tab (requiring StatefulShellRoute changes) or accessed via app bar?

9. **l10n in non-widget contexts:** How will strings in providers and services be localized without BuildContext?

10. **Test helper timing:** Should shared test helpers be created during Phase 1 codegen migration to avoid touching test files twice?
