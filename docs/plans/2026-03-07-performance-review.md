# Performance Review: Comprehensive Improvement Plan

**Date:** 2026-03-07 **Reviewer:** Performance Oracle

---

## Performance Summary

The plan is architecturally sound but has 4 critical performance gaps and 6
optimization opportunities. The biggest risks are: unconstrained avatar uploads
hitting Firebase Storage costs and latency, Firestore reads on every app start
for preferences sync, and cascading provider rebuilds from the new consent +
analytics + profile provider chain.

---

## Critical Issues

### C1: Avatar Upload -- No Compression or Size Limits (Task 4.1a)

**Current plan:** Upload avatar to `users/{uid}/avatar.jpg` with no mention of
compression, resizing, or file size limits.

**Impact:** Users uploading 12MP photos (5-8MB) will cause 2-4 second upload
times on mobile data and inflate Firebase Storage costs.

**Recommendation:**

- Add `image` or `flutter_image_compress` package
- Resize to max 512x512 pixels before upload
- Compress to JPEG quality 75 (target: under 150KB)
- Enforce a 2MB hard limit client-side before compression
- Use `putData()` with metadata including
  `cacheControl: 'public, max-age=31536000'` for CDN caching
- Cache the download URL locally in SharedPreferences to avoid repeated
  `getDownloadURL()` calls

**Measurable target:** Avatar upload under 500ms on 4G, file size under 150KB.

### C2: Profile Preferences Firestore Read on Every App Start (Task 4.1c)

**Current plan:** "On app start, preferences loaded from Firestore and applied
locally."

**Impact:** Adds a sequential Firestore read (~100-300ms) to the critical
startup path on every cold start. This compounds with the existing
`postAuthBootstrapProvider` chain.

**Recommendation:**

- Use SharedPreferences as the primary source on startup (already cached
  locally)
- Sync from Firestore lazily AFTER the app is interactive, not during bootstrap
- Use Firestore's `snapshots()` stream for real-time sync after startup rather
  than a blocking read
- Only fetch from Firestore on first install or when local cache is empty

**Measurable target:** Zero additional startup latency from preferences sync.
Firestore sync completes within 2 seconds of app becoming interactive.

### C3: Consent Gate Checked on Every Analytics Call (Task 4.3)

**Current plan:** Analytics service should "respect consent gate from 4.3" but
no implementation detail on how.

**Impact:** If each `logEvent` call reads from SharedPreferences or checks a
provider, this adds ~1-2ms overhead per event. With screen view tracking and
feature usage events, this could mean 20-50 unnecessary checks per session.

**Recommendation:**

- Read consent state ONCE at analytics service initialization and cache it as a
  boolean field
- Listen for consent changes via a Riverpod provider and update the cached
  boolean
- Short-circuit in the analytics service methods with a simple
  `if (!_consentGranted) return;`
- Do NOT read SharedPreferences on every event call

**Measurable target:** Consent check overhead under 1 microsecond per analytics
call.

### C4: App Startup Time Regression Risk (Multiple Tasks)

**Current plan adds to startup:** consent dialog check, preferences Firestore
read, analytics initialization gating.

**Current startup sequence (sequential):**

1. `WidgetsFlutterBinding.ensureInitialized()`
2. `EnvironmentConfig.init()`
3. `FirebaseService.initialize()` (~200-400ms)
4. Crashlytics setup
5. `SharedPreferences.getInstance()` (~10-50ms)
6. `Future.wait([RevenueCat, FCM])` (~100-300ms)

**Plan adds:** 7. Consent check from SharedPreferences 8. Conditional
Crashlytics/Analytics enable/disable 9. Preferences Firestore fetch

**Recommendation:**

- Consent state from SharedPreferences is fast (synchronous after step 5) --
  read it during step 5, not as a separate step
- Move Crashlytics `setCrashlyticsCollectionEnabled()` into the existing
  Crashlytics block, gated by consent boolean
- Do NOT add Firestore preference sync to the startup path (see C2)
- Add a startup time measurement: `Stopwatch` from `main()` entry to first
  frame, log to analytics

**Measurable target:** Startup time increase under 50ms compared to current
baseline. Total cold start under 2 seconds on mid-range devices.

---

## Optimization Opportunities

### O1: Riverpod Codegen -- autoDispose Memory Profile Change (Task 1.2)

The migration table correctly uses `@Riverpod(keepAlive: true)` for auth,
services, and long-lived streams. The `@riverpod` (autoDispose) annotation for
`postAuthBootstrapProvider` and `onboardingProvider` is correct.

**One risk:** The `themeModeProvider` is marked as `@riverpod` (autoDispose) in
the plan. Since `themeModeProvider` is watched by `App.build()` which is always
mounted, it will never dispose -- so autoDispose is harmless here. However, if a
developer later restructures the widget tree, theme state could be lost
unexpectedly.

**Recommendation:** Mark `themeModeProvider` as `@Riverpod(keepAlive: true)`
since theme state should persist for the app's lifetime. Same for any provider
that holds user-facing state that should survive navigation.

### O2: l10n Rebuild Overhead (Task 2.6)

`AppLocalizations.of(context)!` uses
`Localizations.of<AppLocalizations>(context, AppLocalizations)` which calls
`context.dependOnInheritedWidgetOfExactType()`. This registers the widget as a
dependency of the `Localizations` inherited widget.

**Impact:** Minimal. The `Localizations` widget only triggers rebuilds when the
locale changes, which is extremely rare (user changes device language). This is
NOT a per-frame cost.

**Recommendation:** No action needed. This is a well-optimized Flutter pattern.
Optionally, create a BuildContext extension for brevity:

```dart
extension LocalizationX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
```

### O3: Analytics Event Batching (Task 4.2)

Firebase Analytics already batches events internally (sends every ~1 hour or
when 500 events accumulate, or on app background). No custom batching needed.

**Recommendation:**

- Do NOT add custom batching on top of Firebase Analytics -- it handles this
- DO add a debug mode that logs events to console instead of Firebase (saves
  network in development)
- Limit screen view logging to distinct screens only (deduplicate rapid
  back/forward navigation)
- Cap custom events to essential ones only (5-10 event types max for a starter
  kit)

### O4: Provider Dependency Chain -- Cascading Rebuild Risk

**Current chain:** `authStateProvider` -> `postAuthBootstrapProvider` ->
(profile, purchases, FCM, crashlytics, analytics)

**New chain with plan:** `authStateProvider` -> `postAuthBootstrapProvider` ->
`consentProvider` -> `analyticsService` -> (all screens logging events)

**Risk:** If `consentProvider` is watched (not read) by `analyticsService`,
changing consent will rebuild every widget that uses analytics. This is
unnecessary since consent changes are rare.

**Recommendation:**

- `analyticsService` should `ref.read(consentProvider)` at creation time, not
  `ref.watch`
- Use a `ref.listen` on `consentProvider` to update the cached consent boolean
  without triggering rebuilds
- Keep `analyticsService` as `@Riverpod(keepAlive: true)` since it is a
  singleton service

### O5: Build Time Impact of Code Generation (Task 1.2)

With 20 providers generating `.g.dart` files plus l10n generating
`app_localizations.dart`, `build_runner` will add 15-30 seconds to clean builds.

**Recommendation:**

- Use `build_runner watch` during development (incremental rebuilds are under 2
  seconds)
- Commit `.g.dart` files to version control so cloning does not require running
  build_runner
- Add `build.yaml` with targeted build filters to avoid scanning unrelated
  files:

```yaml
targets:
  $default:
    builders:
      riverpod_generator:
        generate_for:
          - lib/features/**/providers/*.dart
          - lib/shared/providers/*.dart
```

- CI should run `build_runner build` and fail if generated files are out of date

### O6: Firestore Profile Writes -- Debouncing (Task 4.1a, 4.1c)

Display name editing with "inline save" and preference toggles will trigger
Firestore writes on every change.

**Recommendation:**

- Debounce display name saves by 500ms (user may type multiple characters)
- Batch preference changes: if user toggles multiple settings quickly, coalesce
  into a single Firestore write
- Use `SetOptions(merge: true)` for partial updates (already implied in plan)

---

## Scalability Assessment

| Concern                 | Current    | After Plan                               | Risk Level                        |
| ----------------------- | ---------- | ---------------------------------------- | --------------------------------- |
| Provider count          | 20         | ~25-28                                   | Low -- Riverpod handles this well |
| Startup time            | ~500-800ms | ~600-900ms (if recommendations followed) | Medium                            |
| Memory baseline         | ~40MB      | ~45MB (avatar caching, l10n strings)     | Low                               |
| Firestore reads/session | 2-3        | 5-8 (profile, preferences, consent)      | Medium                            |
| Build time (clean)      | ~10s       | ~30-40s (with build_runner)              | Medium                            |

---

## Recommended Actions (Priority Order)

1. **[Critical]** Add image compression and size limits to avatar upload (C1)
2. **[Critical]** Make preferences sync lazy, not blocking startup (C2)
3. **[Critical]** Cache consent state in-memory in analytics service (C3)
4. **[Critical]** Add startup time measurement and enforce 2-second budget (C4)
5. **[High]** Mark `themeModeProvider` as `keepAlive: true` (O1)
6. **[High]** Use `ref.listen` not `ref.watch` for consent in analytics service
   (O4)
7. **[Medium]** Add `build.yaml` with targeted generation (O5)
8. **[Medium]** Debounce profile and preference Firestore writes (O6)
9. **[Low]** Add analytics debug mode for development (O3)
10. **[Low]** No action needed for l10n -- already optimal (O2)

---

## Flutter-Specific Performance Patterns to Follow

1. **Use `const` constructors** for all new widget classes (l10n widgets,
   consent dialog, profile screen)
2. **Use `select`** when watching providers in widgets that only need a subset
   of state: `ref.watch(profileProvider.select((p) => p.avatarUrl))`
3. **Use `RepaintBoundary`** around the avatar image widget to isolate repaints
   during upload progress
4. **Avoid `setState` in ConsumerStatefulWidget** when Riverpod state can handle
   it
5. **Use `CachedNetworkImage`** (or similar) for avatar display with disk
   caching -- do not re-download from Firebase Storage on every screen visit
6. **Use `AutomaticKeepAliveClientMixin`** on tab screens to avoid rebuilding
   when switching tabs in the `StatefulShellRoute`
