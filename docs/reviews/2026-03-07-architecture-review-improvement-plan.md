# Architecture Review: Comprehensive Improvement Plan

**Reviewer:** Architecture Strategist Agent **Date:** 2026-03-07 **Scope:**
4-phase improvement plan (v1.1 through v1.4)

---

## 1. Phasing Assessment

The phase ordering is sound. Phase 1 (foundation) before Phase 2 (DX) before
Phase 3 (tests) before Phase 4 (features) is the correct sequence. However,
there are two hidden dependency issues:

**Issue A: Phase 3 partially depends on Phase 2, not just Phase 1.** Task 3.6
(integration test foundation) will need flavor awareness if flavors land in
Phase 2. If integration tests are written against `flutter run` and Phase 2
changes that to `flutter run --flavor dev`, those tests break. The plan should
note that 3.6 must account for the flavor setup from 2.5.

**Issue B: Task 1.6 (environment config) and Task 2.5 (flavors) have a
conflicting migration path.** Task 1.6 wires `--dart-define=ENV=` to real
behavior, then Task 2.5 deprecates `--dart-define` in favor of `--flavor`. This
means Phase 1 builds production logic around a mechanism that Phase 2
immediately replaces. Recommendation: In Task 1.6, implement the environment
behavior properties (the enum extension methods) but wire them through an
abstraction that can read from either `--dart-define` or flavor. This avoids
rework.

## 2. Provider Migration (Task 1.2)

The migration table is thorough. Two concerns:

**Providers returning `Function` types.** The plan flags `sign_out_provider` and
`delete_account_provider` as `Provider<Function>` needing restructuring as
Notifier classes. This is correct, but it is a behavioral change, not just a
syntax migration. These should be extracted as a sub-task with their own test
verification step, not batched into the general codegen sweep. A
`Provider<Function>` becoming a `Notifier` changes how consumers invoke it
(`ref.read(provider)()` becomes `ref.read(provider.notifier).execute()`).

**Migration ordering within 1.2.** The plan says to migrate all 20 providers but
does not specify an order. Providers with dependencies on other providers should
be migrated leaf-first (providers with no provider dependencies first, then
those that depend on them). Specifically: service providers first
(`authServiceProvider`, `userProfileServiceProvider`), then composite providers
(`signOutProvider`, `deleteAccountProvider`) that depend on them.

## 3. Moving Shared Providers to features/auth/ (Task 1.1)

The move is architecturally correct -- these providers belong in `auth/` because
they depend on auth internals. However, the plan creates a new coupling problem
it does not address:

**Settings now imports from auth.** After the move, `settings_screen.dart` will
import `sign_out_provider` and `delete_account_provider` from
`features/auth/providers/`. This means the settings feature cannot be
independently deleted without also modifying auth. The CLAUDE.md states
"Features are designed to be independently deletable."

**Recommendation:** The plan should acknowledge this as an acceptable
architectural trade-off (settings inherently depends on auth for sign-out and
account deletion) and document it in the feature surgery guide (Task 2.3). An
alternative would be to expose these as abstract interfaces in `shared/` with
implementations in `auth/`, but that is over-engineering for a starter kit.

**`premium_provider.dart` is missed.** The plan moves 3 providers out of
`shared/` but `lib/shared/providers/premium_provider.dart` remains. This
provider is imported by `settings_screen.dart` and `premium_gate.dart`. If
`premium_provider` depends on paywall feature internals, it has the same
violation. If it is truly shared (no feature imports), it is fine where it is.
The plan should explicitly state why it stays.

## 4. Flavors vs. environment.dart (Task 2.5)

The flavor approach is standard and correct. Two gaps:

**`firebase_options.dart` per flavor is underspecified.** The plan mentions
`flutterfire configure` needs to run per flavor but does not address the code
impact. Currently there is likely one `firebase_options.dart`. With flavors, you
need either: (a) three separate `firebase_options_*.dart` files selected at
runtime, or (b) the `flutterfire_cli` flavor support that generates flavor-aware
options. This is a non-trivial implementation detail that should be a documented
sub-task.

**The `FLAVOR` vs `ENV` naming.** Task 2.5 switches from
`String.fromEnvironment('ENV')` to `String.fromEnvironment('FLAVOR')`. These are
different concepts: a flavor is a build variant (affects bundle ID, app name,
Firebase config), while an environment is a runtime concern (affects API URLs,
logging verbosity). The plan conflates them. Recommendation: Keep `ENV` for the
Dart-side environment enum and use flavors purely for build configuration. The
flavor's build config can set the `ENV` dart-define automatically.

## 5. Profile Expansion Scope (Tasks 4.1a/b/c)

The three-task split is well-scoped. Concerns:

**4.1c introduces dual-write complexity.** Writing preferences to both
SharedPreferences and Firestore creates a consistency problem the plan does not
address: what happens on conflict? Which source wins on app start? The plan
should specify Firestore as source of truth with SharedPreferences as a
read-through cache, and define the sync direction explicitly (remote wins, local
is fallback for offline only).

**4.1a adds two new dependencies** (`firebase_storage`, `image_picker`). For a
starter kit, these increase the setup burden. The plan should note these are
optional and provide the feature surgery guide (Task 2.3) for removing the
profile feature.

## 6. Missing Architectural Patterns

**No error boundary strategy.** The plan adds new async operations (profile
CRUD, avatar upload, preference sync) but does not define a unified error
handling pattern. Each feature will ad-hoc its own error handling. The plan
should establish whether errors propagate through `AsyncValue`, a global error
provider, or per-feature error state.

**No data layer abstraction.** Services call Firebase SDKs directly. The plan
adds more services (profile storage, analytics taxonomy) without introducing a
repository pattern. For a starter kit this is acceptable, but the plan should
explicitly state that services ARE the repository layer to prevent future
contributors from adding a redundant abstraction.

**`feature_hooks.dart` needs a decision.** The plan mentions possibly removing
`feature_hooks.dart` but is ambiguous. This file coordinates lifecycle between
features (sign-out cleanup, etc.). If it moves to `auth/`, it becomes
auth-specific hooks, which is fine. If it stays in `shared/`, it must not import
from features. The plan should make a clear call.

## 7. Anti-Patterns Identified in Proposed Solutions

**Task 1.4 (security fixes) stores API keys in `flutter_secure_storage`.**
Storing RevenueCat API keys in secure storage does not meaningfully improve
security -- these keys ship in the binary regardless and are extractable. This
adds complexity (async initialization, error handling for keychain access) for
marginal security benefit. Recommendation: Keep API keys in `app_config.dart`
(compile-time constants) and use server-side validation as the real security
boundary.

**Task 2.6 (l10n) is premature for a starter kit.** Adding l10n scaffolding
before any user has requested it adds maintenance burden to every UI change.
Every string becomes an l10n key. For a starter kit meant to be cloned and
customized, raw strings with a documented "how to add l10n" guide would be more
appropriate than pre-wired l10n.

## Summary

| Area                   | Verdict                       | Action Needed                                                     |
| ---------------------- | ----------------------------- | ----------------------------------------------------------------- |
| Phase ordering         | Sound with caveats            | Address 1.6/2.5 conflict, 3.6/2.5 dependency                      |
| Provider migration     | Thorough but needs ordering   | Leaf-first migration, isolate Function->Notifier changes          |
| shared/ to auth/ move  | Correct direction             | Acknowledge settings->auth coupling, decide on premium_provider   |
| Flavors vs environment | Conflated concepts            | Separate build variant from runtime environment                   |
| Profile scope          | Well-split                    | Define sync conflict resolution for 4.1c                          |
| Missing patterns       | Error handling, feature_hooks | Add error boundary strategy, decide feature_hooks location        |
| Anti-patterns          | Two identified                | Reconsider secure storage for API keys, reconsider premature l10n |
