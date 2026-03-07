# Performance Review: Production Readiness Refactor Plan

**Date:** 2026-03-07 **Reviewer:** Performance Oracle **Scope:** 9 specific
performance concerns raised against the refactor plan **Status:** Research only
-- no code changes

---

## 1. Router with refreshListenable vs Current Rebuild Approach

**Current problem (confirmed):** `routerProvider` calls
`ref.watch(authStateProvider)` on line 12 of `router.dart`, which recreates the
entire `GoRouter` instance on every auth stream emission. This is a real
performance bug -- it destroys and rebuilds the navigation stack, resets scroll
positions, and triggers full widget subtree rebuilds.

**Plan's fix:** `AuthChangeNotifier` wrapping `ref.listen()` +
`refreshListenable`.

**Performance verdict: Significant improvement, no concerns.** The
`refreshListenable` approach calls only `GoRouter.refresh()`, which re-evaluates
the `redirect` callback without recreating the router. This is O(number of
redirect rules) per auth event, which is trivial. The `ChangeNotifier`
allocation is a single object for the app's lifetime. This is the canonical
GoRouter pattern and eliminates the current bug entirely.

---

## 2. Profile Check on Every Redirect

**Plan (section 1.4):** The redirect callback will read `userProfileProvider` to
check `onboardingComplete` status.

**Performance concern: Moderate -- needs careful implementation.**

- GoRouter's `redirect` fires on every navigation event, not just auth changes.
  If the profile provider is a `FutureProvider` that fetches from Firestore on
  each read, every route change triggers a network round-trip. At ~100-300ms per
  Firestore read, this would add noticeable latency to every navigation.
- **Mitigation already hinted in the plan:** The existing TODO in `router.dart`
  says "cached onboardingComplete provider." The plan's `userProfileProvider`
  should be a `StreamProvider` listening to
  `firestore.collection('users').doc(uid).snapshots()`, which keeps data in
  memory after the first fetch. Alternatively, cache the boolean in a simple
  `StateProvider` that is set once on sign-in.
- **Recommendation:** Do NOT call `await profileService.getProfile()` inside
  `redirect`. Use `ref.read(userProfileProvider).valueOrNull` and only redirect
  when the value is already loaded. If the profile is still loading, let the
  user through to a loading screen rather than blocking navigation.

---

## 3. CustomerInfo Fetch on App Start -- Blocking vs Async

**Current code:** `PurchasesService.initialize()` is awaited in `main()` (line
16 of `main.dart`). This blocks app startup until RevenueCat SDK configures.

**Plan (section 1.5):** Adds `purchasesService.login(uid)` after sign-in and
derives `isPremiumProvider` from `customerInfoProvider`.

**Performance concern: Low, but watch the chain.**

- `Purchases.configure()` is already blocking startup. RevenueCat SDK caches
  `CustomerInfo` locally, so `getCustomerInfo()` in `customerInfoProvider`
  returns from cache in <10ms on subsequent launches. The first-ever launch may
  take 200-500ms for a network fetch.
- The `login(uid)` call after sign-in is async and does not block navigation (it
  runs in a listener). This is correct.
- **Recommendation:** Consider moving `Purchases.configure()` to run in parallel
  with `FirebaseService.initialize()` using `Future.wait()` to shave ~100-200ms
  off cold start. Currently they run sequentially.

---

## 4. SharedPreferences Sync Read in Theme Provider

**Current code (confirmed bug):** `ThemeModeNotifier.build()` returns
`ThemeMode.light` synchronously, then fires-and-forgets `_loadFromPrefs()`. This
causes a visible light-to-dark flash.

**Plan (section 1.8):** Pre-initialize `SharedPreferences` in `main()`, inject
via provider override, read synchronously in `build()`.

**Performance verdict: Improvement with negligible startup cost.**

- `SharedPreferences.getInstance()` is ~2-5ms on most devices (it reads a small
  XML/plist file from disk). Adding it to `main()` extends cold start by this
  amount -- imperceptible.
- The synchronous read in `build()` eliminates both the flash AND the second
  async `getInstance()` call that currently happens. Net performance gain.
- **No concerns.** This is the standard Flutter pattern.

---

## 5. Provider Invalidation Cascade on Sign-Out

**Plan (section 1.6):** Sign-out calls `ref.invalidate()` on 4-5 providers
sequentially.

**Performance concern: Negligible -- no jank risk.**

- `ref.invalidate()` is a synchronous operation that marks a provider as needing
  rebuild. It does NOT trigger immediate rebuilds. Riverpod batches
  notifications and delivers them in the next microtask. Invalidating 5
  providers costs microseconds.
- The providers only rebuild when something watches them again (e.g., after the
  next sign-in). Since the user is being redirected to `/auth` after sign-out,
  none of these providers have active watchers, so no rebuild work happens at
  all.
- The one async operation -- `purchasesService.logout()` -- is a network call
  (~100-300ms) but runs before `authService.signOut()`, so the user sees the
  sign-out UI response promptly.
- **No concerns.**

---

## 6. StatefulShellRoute with Two Tabs -- Memory Implications

**Plan (section 1.9):** Replace `ShellRoute` with
`StatefulShellRoute.indexedStack` for Home + Profile tabs.

**Performance concern: Low, acceptable trade-off.**

- `IndexedStack` keeps both tab widgets alive in memory simultaneously. With two
  simple tabs (HomeScreen + ProfileScreen), this is negligible -- each tab is a
  lightweight widget tree.
- The benefit is that tab state (scroll positions, form inputs) is preserved
  when switching tabs. Without `IndexedStack`, switching tabs would dispose and
  recreate widgets, which is more expensive than keeping two small trees alive.
- **Scaling note:** This pattern would become a concern with 5+ tabs where some
  contain heavy content (large lists, images, maps). Two tabs is well within
  acceptable bounds.
- **Current waste:** The existing `HomeShell` has 3 `NavigationDestination`
  widgets (Home, Explore, Profile) but only one route. The plan correctly
  reduces to 2 functional tabs, which is actually less memory than the current
  broken 3-tab shell.

---

## 7. Firestore Reads for Profile on Every Auth State Change

**Plan (section 1.3):** After sign-in, check if Firestore profile exists; if
not, create one.

**Performance concern: Moderate -- depends on implementation location.**

- `FirebaseAuth.authStateChanges` can emit multiple times: on app start (null
  then user), on token refresh, on sign-in, on sign-out. If the profile check
  runs on every emission, that is 2-3 unnecessary Firestore reads per app
  launch.
- The plan's code sample shows this in an "auth state listener or router
  redirect." If placed in the redirect, it fires on every navigation. If placed
  in an auth state listener, it fires on every auth emission.
- **Recommendation:** Gate the profile check behind a local flag or use
  `authStateChanges().distinct()` to avoid duplicate emissions. Better yet, use
  `userChanges()` only for the initial check and cache the result in a provider.
  The profile existence check should run exactly once per sign-in session, not
  on every auth emission.
- **Firestore cost:** Each `getProfile()` call is one document read. At
  Firestore's free tier (50K reads/day), this is not a billing concern, but
  unnecessary reads add 100-300ms latency each time.

---

## 8. flutter_animate Impact on Low-End Devices

**Plan (section 4.4):** Add entrance animations to onboarding pages using
`flutter_animate`.

**Performance concern: Low, with one mandatory requirement.**

- `flutter_animate` uses standard Flutter `AnimationController` and `Tween`
  under the hood. It does not use heavy shaders or custom render objects. Simple
  fade/slide animations run at 60fps even on low-end devices.
- The animations are scoped to onboarding (viewed once per user) and screen
  transitions, not continuous UI elements. This limits exposure.
- **Mandatory:** The plan's acceptance criterion already includes "respect
  `MediaQuery.disableAnimations`." This is correct and must be enforced. On
  devices where the user has enabled "reduce motion" in accessibility settings,
  animations should be skipped entirely. The implementation should check
  `MediaQuery.of(context).disableAnimations` and set duration to `Duration.zero`
  when true.
- **Bundle size:** `flutter_animate` adds ~50-80KB to the compiled app.
  Negligible.

---

## 9. Analytics Observer Overhead on Navigation

**Plan (section 4.3):** Wire a `NavigatorObserver` for automatic screen tracking
via Firebase Analytics.

**Performance concern: Negligible.**

- `FirebaseAnalyticsObserver` logs a single `screen_view` event per navigation.
  The Firebase Analytics SDK batches events and sends them in bulk (typically
  every ~60 seconds or when the app backgrounds). There is no synchronous
  network call on each navigation.
- The observer's `didPush`/`didPop` callbacks are O(1) -- they extract the route
  name and queue an event. This adds single-digit microseconds per navigation.
- **One caveat:** If custom event logging is added inside screen `build()`
  methods (not just the observer), ensure events are not logged on rebuilds. Use
  `initState()` or `ref.listen()` for one-time event logging, never inside
  `build()`.

---

## Summary: Prioritized Concerns

| #   | Item                            | Risk         | Action Required                                                  |
| --- | ------------------------------- | ------------ | ---------------------------------------------------------------- |
| 2   | Profile check in redirect       | **Moderate** | Must use cached/streamed data, never await Firestore in redirect |
| 7   | Firestore reads on auth changes | **Moderate** | Gate profile check to run once per sign-in, not per emission     |
| 3   | CustomerInfo fetch on start     | **Low**      | Consider parallel init with Firebase to reduce cold start        |
| 6   | StatefulShellRoute memory       | **Low**      | Acceptable for 2 tabs, document the scaling limit                |
| 8   | flutter_animate on low-end      | **Low**      | Enforce disableAnimations check                                  |
| 1   | refreshListenable router        | **None**     | Pure improvement over current approach                           |
| 4   | SharedPreferences sync read     | **None**     | Pure improvement, eliminates theme flash                         |
| 5   | Provider invalidation cascade   | **None**     | Riverpod batches invalidations, no jank                          |
| 9   | Analytics observer              | **None**     | Negligible overhead, standard pattern                            |

## Critical Recommendation

The plan should explicitly add a performance constraint to section 1.4: **the
router redirect must never perform a synchronous Firestore read.** The
`userProfileProvider` should be a `StreamProvider` backed by a Firestore
snapshot listener so that profile data is always available in memory after the
initial load. The redirect should read
`ref.read(userProfileProvider).valueOrNull` and treat a null/loading state as
"allow navigation to a loading screen" rather than blocking. This single
constraint prevents the two moderate-risk items (2 and 7) from becoming real
latency problems.
