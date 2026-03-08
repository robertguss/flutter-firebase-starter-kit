# PR Review: Riverpod 3.0 Codegen Migration

**Branch:** `feat/riverpod-3-codegen-migration` **Files changed:** 46 | +1874 /
-467

---

## Verdict: Approve with minor suggestions

This is a clean, well-executed migration. The patterns are consistent, naming
follows Riverpod codegen conventions, and the test updates are thorough. Below
are findings organized by category.

---

## 1. Naming Convention Consistency -- PASS

All 20 providers follow Riverpod codegen naming rules correctly:

| Pattern                | Convention                                           | Consistent? |
| ---------------------- | ---------------------------------------------------- | ----------- |
| Functional providers   | `camelCase` function -> `camelCaseProvider`          | Yes         |
| Class-based Notifiers  | `PascalCase` class -> `camelCaseProvider`            | Yes         |
| `keepAlive` annotation | `@Riverpod(keepAlive: true)` for services/singletons | Yes         |
| Auto-dispose (default) | `@riverpod` for transient/action providers           | Yes         |

Examples of correct mapping:

- `authService()` -> `authServiceProvider` (keepAlive)
- `authState()` -> `authStateProvider` (keepAlive)
- `deleteAccount()` -> `deleteAccountProvider` (auto-dispose)
- `ThemeModeNotifier` -> `themeModeProvider` (keepAlive, class-based)
- `Onboarding` -> `onboardingProvider` (auto-dispose, class-based)

No naming inconsistencies found.

---

## 2. Pattern Consistency -- PASS

Three distinct provider patterns are used consistently:

**A. Service providers** (sync, keepAlive) -- 6 providers

```dart
@Riverpod(keepAlive: true)
AuthService authService(Ref ref) => AuthService();
```

Used for: `authService`, `userProfileService`, `purchasesService`,
`profileStorageService`, `profileImageService`, `sharedPreferences`

**B. Data providers** (async, keepAlive) -- 7 providers

```dart
@Riverpod(keepAlive: true)
Stream<UserProfile?> userProfile(Ref ref) { ... }
```

Used for: `authState` (Stream), `userProfile` (Stream), `customerInfo` (Future),
`offerings` (Future), `isPremium`, `notificationService`, `packageInfo`

**C. Class-based Notifiers** -- 3 providers

```dart
@Riverpod(keepAlive: true)
class ThemeModeNotifier extends _$ThemeModeNotifier { ... }
```

Used for: `ThemeModeNotifier`, `Onboarding`, `NotificationPreference`

**D. Action providers** (auto-dispose Future) -- 4 providers

```dart
@riverpod
Future<void> deleteAccount(Ref ref) async { ... }
```

Used for: `deleteAccount`, `signOut`, `postAuthBootstrap`, feature hooks

All patterns are applied appropriately to their use case.

---

## 3. keepAlive vs Auto-Dispose Decisions -- PASS (with one note)

The `keepAlive` decisions are sound:

- **keepAlive: true** for services, auth state, user profile stream, router,
  theme, shared preferences -- these must survive widget disposal
- **Auto-dispose (default @riverpod)** for `deleteAccount`, `signOut`,
  `postAuthBootstrap`, `Onboarding`, `NotificationPreference` -- these are
  transient or per-session

**Note:** `postAuthBootstrap` is auto-dispose but is `ref.watch`-ed by
`_BootstrapGate`. This is fine because the watcher keeps it alive while mounted,
and it correctly re-runs when auth state changes. Good design.

---

## 4. Anti-Patterns and Issues

### 4a. MINOR: `valueOrNull` -> `value` change in app.dart (line 63)

```dart
// Before:
final user = authState.valueOrNull;
// After:
final user = authState.value;
```

This is semantically correct for Riverpod 3.0 where `.value` returns `null`
during loading/error (matching the old `valueOrNull` behavior). However, if this
codebase ever upgrades to a version where `.value` throws on error, this would
break. The change is correct for Riverpod 3.x.

### 4b. MINOR: Action providers as FutureProvider vs class-based AsyncNotifier

`deleteAccount` and `signOut` are implemented as functional
`@riverpod Future<void>` providers. In Riverpod 3.0, the recommended pattern for
imperative actions is `@mutation` on a class-based provider. However,
`@mutation` may not yet be stable in the generator. The current approach works
correctly -- the providers are read (not watched) to trigger the action, and
they auto-dispose afterward.

**Recommendation for future:** When `@mutation` stabilizes, consider migrating
`deleteAccount` and `signOut` to `@mutation` methods on an `AuthActions`
notifier class. This would provide better loading/error state tracking in the
UI. No action needed now.

### 4c. INFO: TODO comment in delete_account_provider.dart

```
/// TODO: Firestore does not cascade-delete sub-collections.
```

Pre-existing technical debt marker. Not introduced by this PR.

### 4d. GOOD: `ref.read` vs `ref.watch` usage is correct

- `ref.watch` used in `build()` methods and for reactive dependencies (auth
  state in `postAuthBootstrap`, `userProfile`)
- `ref.read` used in action handlers and one-time reads (service access in
  `deleteAccount`, `signOut`)

No misuse found.

---

## 5. Code Duplication

### 5a. LOW: Override boilerplate in tests

Tests for `deleteAccount`, `signOut`, and `postAuthBootstrap` each define
similar `createContainer()` helpers with overlapping override lists. This is
acceptable for test readability and independence.

### 5b. NONE in provider source files

Each provider file is focused and minimal. No duplicated logic across providers.

---

## 6. Test Migration Quality -- PASS

Key improvements in the test migration:

- **`ProviderContainer()` -> `ProviderContainer.test()`**: Correctly uses the
  test-specific constructor that auto-disposes
- **Removed manual `tearDown(() => container.dispose())`**: No longer needed
  with `.test()`
- **`overrideWithValue` for generated providers**: Correct approach for codegen
  providers
- **`pumpApp` helper updated**: Now accepts `ProviderContainer` and uses
  `UncontrolledProviderScope` -- this is the correct pattern for widget tests
  with codegen providers

### Potential concern in auth_provider_test.dart

The auth provider test now overrides `authStateProvider` directly with
`AsyncValue.data(...)` instead of mocking `authService.authStateChanges`. This
means the test no longer verifies the stream-to-provider wiring. This is a
trade-off: the test is simpler but tests less. Consider adding one
integration-style test that verifies `authState` actually reads from
`authService.authStateChanges` stream.

---

## 7. build.yaml Configuration -- PASS

```yaml
targets:
  $default:
    builders:
      riverpod_generator:
        generate_for:
          - lib/features/**/providers/*.dart
          - lib/shared/providers/*.dart
          - lib/routing/*.dart
```

Scoped generation is good practice -- avoids running the generator on files that
don't need it. The globs correctly cover all provider locations.

---

## 8. Generated Files (.g.dart)

16 `.g.dart` files added, matching all provider source files plus the router.
All source files have the correct `part 'filename.g.dart';` directive.

**Note:** Generated files are committed to the repo. This is a valid choice
(avoids requiring `build_runner` in CI for tests). Ensure `.g.dart` files are
regenerated before each PR merge. Consider adding a CI step:
`dart run build_runner build --delete-conflicting-outputs` with a diff check.

---

## Summary

| Category            | Status               |
| ------------------- | -------------------- |
| Naming conventions  | Clean                |
| Pattern consistency | Clean                |
| keepAlive decisions | Correct              |
| Anti-patterns       | None significant     |
| Code duplication    | Minimal              |
| Test migration      | Good (one minor gap) |
| build.yaml          | Well-scoped          |

### Recommended actions (non-blocking):

1. Consider adding one test that verifies `authStateProvider` actually
   subscribes to `authService.authStateChanges`
2. When `@mutation` stabilizes, migrate `deleteAccount`/`signOut` to mutation
   methods
3. Add CI step to verify `.g.dart` files are up to date
