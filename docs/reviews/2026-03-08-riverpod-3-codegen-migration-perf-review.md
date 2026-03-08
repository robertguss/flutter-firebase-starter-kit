# Performance Review: Riverpod 3 Codegen Migration

**Branch:** `feat/riverpod-3-codegen-migration` **Date:** 2026-03-08 **Scope:**
46 files, 1874 insertions, 467 deletions

---

## Performance Summary

The migration is mechanically sound. Provider names, override APIs, and test
patterns all translate correctly to Riverpod 3 codegen. However, there are two
behavioral changes with real memory and correctness implications that need
attention before merge.

---

## Critical Issues

### 1. NotificationPreference is now autoDispose -- previously keepAlive

**Files:**

- `lib/features/notifications/providers/notification_preference_provider.dart`
- `lib/features/notifications/providers/notification_preference_provider.g.dart`

**What changed:** The old code used
`NotifierProvider<NotificationPreferenceNotifier, bool>` which is keepAlive by
default. The new code uses bare `@riverpod` (lowercase), which defaults to
`isAutoDispose: true`. The generated code confirms: `isAutoDispose: true`.

**Impact:** When no widget is actively watching this provider, it will be
disposed and its state lost. The next reader will re-read from
SharedPreferences, so correctness is preserved, but this introduces unnecessary
disk I/O on every navigation that unmounts/remounts the notification settings
UI. More importantly, if any code calls
`ref.read(notificationPreferenceProvider.notifier).setEnabled()` without an
active listener, the state is silently discarded.

**Fix:** Change `@riverpod` to `@Riverpod(keepAlive: true)` to match the
original behavior, or verify that autoDispose is intentional and all call sites
hold an active subscription.

### 2. Onboarding provider is now autoDispose -- previously keepAlive

**Files:**

- `lib/features/onboarding/providers/onboarding_provider.dart`
- `lib/features/onboarding/providers/onboarding_provider.g.dart`

**What changed:** The old `NotifierProvider<OnboardingNotifier, int>` was
keepAlive. The new `@riverpod class Onboarding` defaults to autoDispose.

**Impact:** The onboarding step index (0, 1, 2) will reset to 0 if the provider
is disposed mid-flow. This can happen if a rebuild cycle temporarily unmounts
the `OnboardingScreen` consumer. The user would be sent back to step 0.

**Fix:** Change `@riverpod` to `@Riverpod(keepAlive: true)`. Onboarding state
must survive across the full multi-step flow.

---

## Optimization Opportunities

### 3. deleteAccount and signOut are autoDispose FutureProviders -- correct but requires careful test patterns

The test for `deleteAccountProvider` already handles this correctly by adding
`container.listen(deleteAccountProvider, (_, __) {})` to keep the provider alive
during the async operation. The `signOut` tests should follow the same pattern
for the error case if one is added later. No action needed now, but worth noting
for future test authors.

### 4. `.valueOrNull` changed to `.value` throughout

In Riverpod 3, `AsyncValue.value` returns `T?` (the last known value or null),
which is equivalent to the old `.valueOrNull`. This is a correct API migration.
No behavioral change.

---

## keepAlive Audit (Full Provider Inventory)

| Provider                         | Annotation                   | autoDispose? | Correct?                                      |
| -------------------------------- | ---------------------------- | ------------ | --------------------------------------------- |
| `authServiceProvider`            | `@Riverpod(keepAlive: true)` | No           | Yes -- singleton service                      |
| `authStateProvider`              | `@Riverpod(keepAlive: true)` | No           | Yes -- auth stream must persist               |
| `userProfileServiceProvider`     | `@Riverpod(keepAlive: true)` | No           | Yes -- singleton service                      |
| `userProfileProvider`            | `@Riverpod(keepAlive: true)` | No           | Yes -- profile stream for router redirect     |
| `deleteAccountProvider`          | `@riverpod`                  | Yes          | Yes -- one-shot action                        |
| `signOutProvider`                | `@riverpod`                  | Yes          | Yes -- one-shot action                        |
| `postAuthBootstrapProvider`      | `@riverpod`                  | Yes          | Yes -- re-runs on auth change via `ref.watch` |
| `fcmServiceProvider`             | `@Riverpod(keepAlive: true)` | No           | Yes -- singleton service                      |
| `notificationPreferenceProvider` | `@riverpod`                  | Yes          | **NO** -- see Issue #1                        |
| `onboardingProvider`             | `@riverpod`                  | Yes          | **NO** -- see Issue #2                        |
| `purchasesServiceProvider`       | `@Riverpod(keepAlive: true)` | No           | Yes -- singleton service                      |
| `customerInfoProvider`           | `@Riverpod(keepAlive: true)` | No           | Yes -- matches old `ref.keepAlive()`          |
| `offeringsProvider`              | `@Riverpod(keepAlive: true)` | No           | Yes -- matches old `ref.keepAlive()`          |
| `profileStorageServiceProvider`  | `@Riverpod(keepAlive: true)` | No           | Yes -- singleton service                      |
| `packageInfoProvider`            | `@Riverpod(keepAlive: true)` | No           | Yes -- static platform data                   |
| `themeModeNotifierProvider`      | `@Riverpod(keepAlive: true)` | No           | Yes -- persists user preference               |
| `routerProvider`                 | `@Riverpod(keepAlive: true)` | No           | Yes -- GoRouter must outlive all routes       |
| `sharedPreferencesProvider`      | `@Riverpod(keepAlive: true)` | No           | Yes -- initialized at startup                 |
| `isPremiumProvider`              | `@Riverpod(keepAlive: true)` | No           | Yes -- overridden in ProviderScope            |
| `bootstrapHooksProvider`         | `@Riverpod(keepAlive: true)` | No           | Yes -- config set once at startup             |
| `signOutHooksProvider`           | `@Riverpod(keepAlive: true)` | No           | Yes -- config set once at startup             |
| `deleteAccountHooksProvider`     | `@Riverpod(keepAlive: true)` | No           | Yes -- config set once at startup             |
| `restorePurchasesActionProvider` | `@Riverpod(keepAlive: true)` | No           | Yes -- config set once at startup             |

---

## Scalability Assessment

### Generated Code Size

- 16 `.g.dart` files totaling 1,243 lines
- Adds ~40KB of Dart source, but tree-shaking and AOT compilation mean the
  runtime cost is near zero. The generated provider classes are `const`
  constructors with no dynamic allocation at startup.
- **Bundle size impact:** Negligible. Dart AOT compiles to native; the generated
  boilerplate is structurally identical to what the framework would create at
  runtime anyway. Estimate <2KB compiled increase.

### Startup Time

- No regression. Generated providers use `const` constructors (allocated at
  compile time, not runtime). The old `final` providers allocated at first
  access, which is the same behavior.

### Rebuild Behavior

- No changes to rebuild characteristics. All `ref.watch` / `ref.read` /
  `ref.listen` call sites are preserved. The codegen wrappers delegate to the
  same underlying functions.

### Memory

- The two autoDispose regressions (Issues #1 and #2) are the only memory
  behavior changes. All other providers maintain their original lifecycle.
- The migration from `ProviderContainer` to `ProviderContainer.test()` in tests
  is correct -- `.test()` auto-disposes the container, eliminating the need for
  manual `tearDown(() => container.dispose())`.

---

## Recommended Actions (Priority Order)

1. **[Must Fix]** Add `keepAlive: true` to `NotificationPreference` provider
2. **[Must Fix]** Add `keepAlive: true` to `Onboarding` provider
3. **[Verified OK]** All other keepAlive/autoDispose settings are correct
4. **[Verified OK]** `.valueOrNull` to `.value` migration is semantically
   correct
5. **[Verified OK]** Test patterns properly handle autoDispose providers
6. **[Verified OK]** Generated code has no startup or bundle size concerns
