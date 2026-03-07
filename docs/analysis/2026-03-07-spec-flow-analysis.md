# Spec Flow Analysis: Flutter Firebase Starter Kit Improvements

**Date:** 2026-03-07 **Analyzed by:** spec-flow-analyzer **Source:**
docs/brainstorms/2026-03-07-starter-kit-improvements-brainstorm.md

---

## User Flow Overview

### Flow 1: Cold Start (First Launch)

1. App launches -> `main()` initializes Firebase, RevenueCat, FCM
2. Router checks auth state -> user is null -> redirect to `/auth`
3. User signs in (Google or Apple)
4. Auth state stream fires -> router redirect triggers
5. **GAP: No onboarding redirect.** Router TODO comment says "Add a cached
   onboardingComplete provider" but spec does not define when/how this check
   happens after Phase 1 changes.
6. User either sees Home or Onboarding (currently no automatic routing to
   onboarding)

### Flow 2: Cold Start (Returning User)

1. App launches -> Firebase auto-restores auth session
2. Router detects auth -> user goes to `/home`
3. **GAP: Premium state not restored until spec fix A5 -- but spec does not
   define what happens while `customerInfoProvider` is loading (FutureProvider
   async gap).**

### Flow 3: Sign-In

1. User taps Google or Apple button
2. OAuth flow launches
3. Success -> UserCredential returned -> auth stream fires -> router redirects
   to `/home`
4. **GAP: No `createProfile` call after sign-in.**
   `UserProfileService.createProfile` exists but is never called from auth flow.
   The spec mentions A6 (UserProfile model) but does not specify when profile
   creation occurs.

### Flow 4: Sign-Out

1. User taps "Sign Out" in Settings
2. `authService.signOut()` called
3. `context.go(AppRoutes.auth)` called manually
4. **GAP (identified in spec as S6):** RevenueCat session not cleared. But spec
   fix S6 does not specify whether FCM token should also be invalidated/removed
   from Firestore on sign-out.

### Flow 5: Account Deletion

1. User taps "Delete Account" -> confirmation dialog
2. Current order: delete Firestore profile -> RevenueCat logout -> delete
   Firebase auth
3. **GAP (identified in spec as S2):** No re-authentication step. But spec fix
   says "re-authenticate first" without specifying the UI flow for
   re-authentication (show password dialog? Re-trigger OAuth? What if re-auth
   fails?)

### Flow 6: Onboarding

1. User navigates to `/onboarding` (currently manually, no auto-redirect)
2. 3-page PageView with Skip and Next buttons
3. On completion, `markOnboardingComplete` writes to Firestore
4. Redirect to `/home`
5. **GAP: No mechanism to route new users to onboarding automatically.** The
   router has a TODO but no spec item addresses this.

### Flow 7: Purchase / Paywall

1. User hits PremiumGate or navigates to `/paywall`
2. Offerings loaded from RevenueCat
3. User purchases -> CustomerInfo returned
4. `isPremiumProvider` manually set to true
5. **GAP: No RevenueCat `login(uid)` call anywhere in the codebase.**
   `PurchasesService.login()` exists but is never called, meaning purchases are
   anonymous and cannot be restored across devices.

### Flow 8: Push Notifications

1. FCM initialized in `main()` (before auth)
2. Permission requested immediately
3. Token saved (currently just printed)
4. **GAP: `saveTokenForUser(uid)` exists but is never called from any flow.**
   Token is obtained before auth, but saving requires a uid.

### Flow 9: Theme Toggle

1. User toggles dark mode in Settings
2. SharedPreferences updated
3. **GAP (identified as A4):** `ThemeModeNotifier.build()` returns
   `ThemeMode.light` synchronously, then async loads preference. This causes a
   visible flash.

---

## Flow Permutations Matrix

| Scenario                      | Auth State    | Onboarding   | Premium     | Notification        | Current Behavior            | Expected After Fix          |
| ----------------------------- | ------------- | ------------ | ----------- | ------------------- | --------------------------- | --------------------------- |
| First launch, no account      | Unauth        | Not started  | N/A         | Not requested       | -> /auth                    | -> /auth                    |
| First launch, sign in         | Auth (new)    | Not done     | Free        | Requested at launch | -> /home (skips onboarding) | -> /onboarding -> /home     |
| Return user, free             | Auth          | Done         | Free        | Granted             | -> /home                    | -> /home                    |
| Return user, premium          | Auth          | Done         | Premium     | Granted             | -> /home (premium lost)     | -> /home (premium restored) |
| Return user, dark mode        | Auth          | Done         | Any         | Any                 | Flash of light mode         | No flash                    |
| Sign out, sign back in        | Auth          | Already done | Was premium | Token stale         | -> /home (no premium)       | -> /home (premium restored) |
| Delete account, re-register   | Auth (new)    | Reset        | Reset       | Token orphaned      | Crash risk (no re-auth)     | Clean flow                  |
| App killed mid-purchase       | Auth          | Done         | Unknown     | N/A                 | isPremium = false           | Restored from CustomerInfo  |
| Offline cold start            | Auth (cached) | Done         | Unknown     | N/A                 | Unspecified                 | Needs definition            |
| Notification tap (app killed) | Varies        | Varies       | N/A         | Granted             | Prints to console           | Needs navigation            |

---

## Missing Elements and Gaps

### Category: Auth Flow Completeness

**Gap 1: No automatic profile creation after sign-in**

- The `UserProfileService.createProfile()` method exists but is never called.
- Impact: The Firestore `/users/{uid}` document is never created, so
  `getProfile`, `markOnboardingComplete`, and `saveTokenForUser` all fail on new
  users.
- The spec mentions A6 (UserProfile model) but does not specify the trigger
  point for profile creation.
- Recommendation: Add profile creation (with check for existing) immediately
  after successful sign-in, before router redirect.

**Gap 2: No onboarding routing logic**

- The router has a TODO comment but no spec item addresses automatic onboarding
  redirect.
- Impact: New users never see onboarding unless manually navigated there.
- Recommendation: Add a spec item (suggest A10) to read `onboardingComplete`
  from user profile and redirect accordingly. This depends on A6 (UserProfile
  model) and Gap 1 (profile creation).

**Gap 3: Re-authentication UI for account deletion (S2)**

- The spec says "re-authenticate first" but does not define the user-facing
  flow.
- Questions: Does the user re-enter credentials? Re-trigger Google/Apple OAuth?
  What error message appears if re-auth fails? Is there a timeout?
- Impact: Implementation will stall without this definition.

### Category: Payment / Premium State

**Gap 4: RevenueCat `login(uid)` never called**

- `PurchasesService.login()` exists but no code calls it.
- Impact: All purchases are anonymous. Users cannot restore purchases on a new
  device. The spec's A5 fix (derive isPremium from CustomerInfo) will not work
  correctly without identifying the user to RevenueCat first.
- Recommendation: Add `PurchasesService.login(uid)` call after successful auth
  sign-in, and add this as a dependency for A5.

**Gap 5: Premium state during async loading**

- A5 replaces `StateProvider<bool>` with a derived provider from
  `customerInfoProvider` (a `FutureProvider`).
- The spec does not define what the UI shows while `customerInfoProvider` is
  loading. `PremiumGate` currently reads a synchronous bool. If it reads a
  `FutureProvider`, it needs loading/error states.
- Impact: PremiumGate will show either "locked" or "loading" briefly on every
  cold start, even for premium users. This is a degraded UX.
- Recommendation: Specify that `PremiumGate` should show a shimmer/skeleton
  while loading and handle the error state.

**Gap 6: Restore purchases error handling**

- Settings screen catches errors from `restorePurchases()` but shows
  `'Error: $error'` (identified in S5).
- The spec does not define specific error messages for: network failure, no
  purchases found, RevenueCat rate limit, store unavailable.

**Gap 7: Purchase flow error states**

- The spec does not address: user cancels purchase mid-flow, purchase succeeds
  but CustomerInfo fetch fails, duplicate purchase attempts, or subscription
  already active.

### Category: Notifications

**Gap 8: FCM initialization timing vs. auth state**

- FCM is initialized in `main()` before auth. Token is obtained. But
  `saveTokenForUser(uid)` requires auth.
- The spec item A7 says "delegate token storage to UserProfileService" but does
  not define when this delegation happens -- on auth state change? On token
  refresh?
- Impact: Without a clear trigger, the token-to-user association will remain
  broken.
- Recommendation: Listen to auth state changes, and when a user signs in, save
  the current FCM token. Also handle `onTokenRefresh` when auth is active.

**Gap 9: Notification permission denied flow**

- FCM requests permission at app launch (before the user even signs in).
- The spec does not define: what happens if permission is denied, whether to
  show a rationale screen first, whether to retry later, or how to handle iOS
  provisional notifications.
- Impact: Requesting permission before the user understands the app's value
  leads to lower opt-in rates.
- Recommendation: Defer notification permission request to after onboarding (the
  third onboarding page is "Stay Updated" -- perfect place to request
  permission).

**Gap 10: Notification tap navigation**

- `_handleMessageTap` currently just prints to console.
- The spec does not define notification deep-linking behavior.
- Impact: Users who tap notifications will see nothing happen.

### Category: Router / Navigation

**Gap 11: StatefulShellRoute migration (A3) interaction with existing routes**

- The spec says to use `StatefulShellRoute` for Home + Profile tabs. But
  `/settings` and `/paywall` are currently top-level routes outside the shell.
- The spec does not clarify whether Settings moves into the Profile tab, remains
  a separate pushed route, or becomes a tab. Same question for Paywall.
- Impact: If Profile tab contains settings, the current `/settings` route
  becomes redundant or conflicting.

**Gap 12: Deep link handling**

- The spec does not address deep links or universal links.
- With the router rebuild fix (A1), `refreshListenable` changes how the router
  responds to auth changes. The spec should clarify whether deep links need to
  be preserved across auth state changes.

**Gap 13: Back navigation from onboarding**

- If a user is routed to onboarding, can they press the system back button? What
  happens? Currently there is no `WillPopScope` / `PopScope` handling.

### Category: Error Handling (U1)

**Gap 14: Error boundary scope**

- The spec says to add `runZonedGuarded` + `FlutterError.onError` +
  `PlatformDispatcher.instance.onError`.
- It does not define: which errors show the custom error UI vs. which are
  silently logged, whether the error screen is dismissible, whether it replaces
  the current screen or overlays it, or whether there is a "retry" action.

**Gap 15: Crashlytics in debug mode**

- The spec says "wire to Crashlytics in non-debug builds" but does not specify
  what happens in debug builds. Just `debugPrint`? Or something else?

### Category: Analytics (U3)

**Gap 16: Analytics event schema**

- The spec lists example events (sign_in, purchase, onboarding_complete) but
  does not define their parameters, when exactly they fire, or whether custom
  user properties are set.
- Impact: Without defined parameters, analytics data will be inconsistent.

### Category: Connectivity (U8)

**Gap 17: Offline behavior definition**

- The spec adds `connectivity_plus` with a banner but does not define: does the
  app prevent actions while offline? Does Firestore offline persistence handle
  it? What happens to in-flight purchases if connectivity drops?

### Category: State Management

**Gap 18: Provider disposal and lifecycle**

- When a user signs out, multiple providers hold stale state:
  `isPremiumProvider`, `customerInfoProvider`, `onboardingProvider`, any cached
  `UserProfile`.
- The spec's S6 fix addresses RevenueCat logout but does not address
  invalidating/resetting all user-scoped providers.
- Recommendation: Either use `ref.invalidate()` on sign-out for all user-scoped
  providers, or scope them under a family provider keyed by uid.

**Gap 19: Concurrent auth state changes**

- The router watches `authStateProvider` which is a stream. If the user signs
  out and signs back in rapidly (or auth token refreshes), multiple redirects
  could queue up.
- The A1 fix (`refreshListenable` with ChangeNotifier bridge) helps but does not
  fully address debouncing.

---

## Critical Questions Requiring Clarification

### Critical (Blocks Implementation or Creates Security/Data Risks)

**Q1: When does user profile creation happen?**

- `UserProfileService.createProfile()` exists but is never called. After A6
  (UserProfile model), when exactly is `createProfile` invoked? On first sign-in
  only? On every sign-in with an upsert? What if the Firestore write fails --
  does auth succeed but profile fail?
- Default assumption if unanswered: Call `createProfile` after every successful
  sign-in with a set-with-merge to avoid overwriting existing data.

**Q2: What is the re-authentication UX for account deletion (S2)?**

- Does the user re-trigger Google/Apple OAuth silently? Is a confirmation dialog
  sufficient for recently-authenticated users (within Firebase's re-auth
  window)? What if re-auth fails?
- Default assumption: Show a dialog explaining re-auth is needed, re-trigger the
  same OAuth provider, show error and abort if it fails.

**Q3: When is `PurchasesService.login(uid)` called?**

- This method exists but is never invoked. Without it, A5 (premium state from
  CustomerInfo) will return empty entitlements because the user is anonymous to
  RevenueCat.
- Default assumption: Call `login(uid)` immediately after Firebase auth
  succeeds, before navigating away from auth screen.

**Q4: How are user-scoped providers reset on sign-out?**

- After S6 (RevenueCat logout on sign-out), are `isPremiumProvider`,
  `customerInfoProvider`, `offeringsProvider`, and future `userProfileProvider`
  all invalidated?
- Default assumption: Call `ref.invalidate()` on each user-scoped provider
  during the sign-out flow.

### Important (Significantly Affects UX or Maintainability)

**Q5: Should onboarding be a mandatory redirect or opt-in?**

- The router TODO suggests mandatory redirect for new users. But the spec does
  not include this as an item. Is this in scope for Phase 1?
- Default assumption: Add automatic redirect to onboarding for new users
  (onboardingComplete == false).

**Q6: What does PremiumGate show while CustomerInfo loads (after A5)?**

- Currently it reads a synchronous bool. After A5, it will depend on an async
  provider. Show locked? Show loading? Show the premium content optimistically?
- Default assumption: Show a loading shimmer, then resolve to locked or
  unlocked.

**Q7: Where do Settings and Paywall routes live after StatefulShellRoute
migration (A3)?**

- Are they pushed routes on top of the shell? Nested within a tab? Does Profile
  tab include settings inline?
- Default assumption: Profile tab shows user info + settings inline. Paywall
  remains a pushed full-screen route.

**Q8: When should FCM permission be requested?**

- Currently at app launch, before auth. After improvements, should it move to
  onboarding step 3? After onboarding? On first relevant feature use?
- Default assumption: Request during onboarding step 3 ("Stay Updated"), skip if
  notifications are disabled via feature flag.

**Q9: What errors show the custom error UI (U1) vs. log silently?**

- Network timeouts, Firestore permission denied, widget build errors, null
  reference errors -- which get UI treatment?
- Default assumption: Widget build errors show error UI. Network/Firestore
  errors show snackbar. Unhandled exceptions log to Crashlytics silently.

### Nice-to-Have (Improves Clarity but Has Reasonable Defaults)

**Q10: Should the app support system theme mode in addition to manual toggle?**

- Currently only light/dark toggle. `ThemeMode.system` is a third option.
- Default assumption: Keep manual toggle only for simplicity.

**Q11: What analytics parameters accompany each event?**

- sign_in: provider (google/apple)? new vs returning?
- purchase: product_id? price? currency?
- Default assumption: Include provider for sign_in, product_id for purchase,
  step count for onboarding.

**Q12: Does the connectivity banner block UI interactions?**

- Or is it purely informational?
- Default assumption: Informational banner only, no blocking.

---

## Cross-Phase Dependencies

### Dependency Chain 1 (Critical Path)

```
A2 (service standardization)
  -> T4 (notification tests) -- needs constructor injection
  -> T5 (purchases tests) -- needs instance methods
  -> A5 (premium state) -- needs proper service layer
  -> A7 (FCM boundaries) -- needs injectable services
```

### Dependency Chain 2 (Profile Creation)

```
A6 (UserProfile model)
  -> Gap 1 (profile creation trigger) -- MISSING FROM SPEC
  -> Gap 2 (onboarding routing) -- MISSING FROM SPEC
  -> A7 (FCM token storage delegation)
  -> S1 (Firestore rules) -- rules depend on document structure
```

### Dependency Chain 3 (Error Handling)

```
U1 (global error handler)
  -> U2 (Crashlytics) -- handler feeds into Crashlytics
  -> S5 (user-friendly errors) -- handler maps exceptions
  -> T2 (error tests) -- tests validate handler behavior
```

### Dependency Chain 4 (Premium)

```
Gap 4 (RevenueCat login call) -- MISSING FROM SPEC
  -> A5 (premium state from CustomerInfo)
  -> S6 (RevenueCat logout on sign-out)
  -> Gap 5 (PremiumGate loading state)
```

### Risk: Phase 1 A5 will not work without Gap 4 being addressed first.

The spec says to derive `isPremiumProvider` from `customerInfoProvider`, but
`customerInfoProvider` calls `PurchasesService.getCustomerInfo()` which will
return empty entitlements because `PurchasesService.login(uid)` is never called.
This is a silent failure -- the feature will appear to work but premium status
will never be restored.

### Risk: Phase 2 S1 (Firestore rules) depends on Phase 1 A6 (UserProfile model).

The Firestore rules need to know the document structure to add field validation.
If A6 changes the document schema, S1 rules will need updating. The suggested
implementation order (A6 before S1) is correct, but this dependency is implicit.

### Risk: Phase 3 tests may need rewriting if Phase 1 changes service interfaces.

T1-T3 are marked as critical tests, but if A1 (router) and A2 (service
standardization) significantly change the public API, tests written before those
changes will break. The suggested order (A1+A2 first, then T1-T3) handles this,
but the spec should note that test writing should wait until after service
interfaces stabilize.

---

## Recommended Next Steps

1. **Add spec items for the 4 most critical gaps:**
   - Profile creation trigger (Gap 1) -- without this, onboarding, FCM tokens,
     and account data are all broken
   - Onboarding auto-redirect (Gap 2) -- the router TODO is unfulfilled
   - RevenueCat login call (Gap 4) -- without this, A5 silently fails
   - Provider reset on sign-out (Gap 18) -- without this, stale state leaks
     between users

2. **Clarify the re-authentication UX for S2** before implementation begins.
   This is a user-facing flow with multiple error states that needs design
   input.

3. **Reconsider FCM permission timing** (Gap 9). Moving it from `main()` to
   onboarding step 3 would improve opt-in rates and is a small change with big
   impact.

4. **Define PremiumGate loading behavior** (Gap 5) before implementing A5. The
   current synchronous API will become async, and every call site needs
   updating.

5. **Document the implicit dependency between Gap 4 (RevenueCat login) and A5
   (premium state restoration).** Without calling `login(uid)`, the entire
   premium restoration feature silently returns empty data.

6. **Ensure test writing (Phase 3) begins only after Phase 1 service interfaces
   stabilize.** The spec's suggested order already handles this, but making it
   explicit prevents wasted effort.
