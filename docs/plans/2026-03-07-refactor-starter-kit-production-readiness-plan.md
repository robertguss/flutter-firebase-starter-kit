---
title: "refactor: Elevate starter kit to production readiness"
type: refactor
status: active
date: 2026-03-07
origin: docs/brainstorms/2026-03-07-starter-kit-improvements-brainstorm.md
---

# Refactor: Elevate Starter Kit to Production Readiness

## Enhancement Summary

**Deepened on:** 2026-03-07 **Research agents used:** Flutter Expert, Firebase
Skills (auth/firestore/basics), Architecture Strategist, Security Sentinel,
Performance Oracle, Code Simplicity Reviewer, Pattern Recognition Specialist,
Context7 (GoRouter + Riverpod docs)

### Critical Corrections (from deepening)

1. **Account deletion order fixed** -- re-auth first (validate), then Firestore
   delete, then auth delete. Auth-first breaks Firestore security rules since
   token is invalidated. (Security + Architecture + Firebase agents converged)
2. **Firestore rules rewritten** -- original `allow write` conflicted with
   granular rules via OR logic, making field validation bypassable. Now merged
   into each rule. (3 agents caught this)
3. **Profile creation moved out of router redirect** -- `redirect` is
   synchronous, cannot `await` Firestore. Now uses a dedicated
   `postAuthBootstrapProvider`. (Flutter Expert + Architecture)
4. **PurchasesService injection fixed** -- `Purchases.instance` does not exist
   in RevenueCat. Service wraps static calls internally; mock at service level.
   (Flutter Expert + Architecture)
5. **Phase reordering** -- UserProfile model (1.7) moved before profile creation
   (1.3). Firestore rules (2.1) moved to Phase 1 since it's standalone.

### Simplifications Applied

6. **Eliminated AnalyticsService abstraction** -- use `FirebaseAnalytics`
   directly with inline example calls
7. **Eliminated SkeletonLoader** -- keep `EmptyState` only;
   `CircularProgressIndicator` is sufficient for a starter kit
8. **Removed flutter_animate** -- zero functional value; remove the dependency
   entirely instead of trying to use it
9. **Simplified error handling** -- dropped `runZonedGuarded` since
   `PlatformDispatcher.instance.onError` covers async errors in Flutter 3.x+
10. **Simplified error mapper** -- inline switch at call sites, not a shared
    utility file

### New Insights Added

11. **Post-auth bootstrap provider** -- orchestrates profile creation,
    RevenueCat login, and FCM token save in one place with loading state
12. **FCM `onTokenRefresh` listener** -- tokens rotate; must listen and update
13. **FCM token cleanup on sign-out** -- prevent notifications to signed-out
    device
14. **Crashlytics `setUserIdentifier`** and `setCrashlyticsCollectionEnabled`
15. **UserProfile.email must be nullable** -- Apple Sign-In can return null
16. **`sharedPreferencesProvider` belongs in `lib/shared/`** not theme file
17. **`ref.onDispose(() => authNotifier.dispose())`** in router provider
18. **`navigationShell.goBranch()`** wiring for StatefulShellRoute
19. **Parallelize Firebase + RevenueCat init** with `Future.wait()`
20. **Router redirect must never perform blocking Firestore read** -- use cached
    provider value only

---

## Overview

Systematic improvement of the Flutter Firebase starter kit across four
dimensions: architecture, security, testing, and UX/features. The kit serves
three audiences (personal use, open source, educational) and must demonstrate
correct, secure, well-documented patterns throughout.

The brainstorm identified 35 specific items. SpecFlow analysis uncovered 4
additional critical gaps (silent failures in profile creation, onboarding
redirect, RevenueCat login, and provider reset on sign-out). This plan organizes
all 39 items into a phased implementation order with clear dependencies.

## Problem Statement

The starter kit has a solid foundation (feature-folder structure, Riverpod,
GoRouter, Firebase) but suffers from:

- **Inconsistent patterns** -- services use 3 different instantiation strategies
- **Critical bugs** -- router rebuilds on every auth change, theme flashes light
  mode, premium state lost on cold start
- **Missing flows** -- profile creation never triggered, onboarding never
  auto-redirected, RevenueCat login never called
- **Security gaps** -- no Firestore rules, unsafe account deletion, API keys in
  source
- **Thin testing** -- 24 tests, zero error paths, zero widget tests, zero router
  redirect tests
- **UX gaps** -- no error handling, no Crashlytics, no Analytics, no empty
  states, accessibility issues

## Proposed Solution

Four-phase refactor, ordered so each phase unblocks the next. Architecture fixes
come first because security fixes and tests depend on correct service patterns
(see brainstorm:
docs/brainstorms/2026-03-07-starter-kit-improvements-brainstorm.md).

---

## Technical Approach

### Architecture

The core architectural change is **standardizing all services behind Riverpod
providers with constructor injection**. This is the pattern already used by
`AuthService` and must be applied consistently to `UserProfileService`,
`FcmService`, and `PurchasesService`.

The router will be refactored to create `GoRouter` once and use
`refreshListenable` for auth-reactive redirects. Bottom navigation will use
`StatefulShellRoute` with two tabs.

### Implementation Phases

---

#### Phase 1: Architecture Fixes (Foundation)

All other phases depend on these fixes. Service standardization (1.1) must
complete before any testing work, since tests need injectable services.

##### 1.1 Standardize service instantiation (A2 + SpecFlow gaps)

**Files to modify:**

- `lib/features/paywall/services/purchases_service.dart` -- convert static
  methods to instance methods with constructor injection
- `lib/features/notifications/services/fcm_service.dart` -- add constructor
  injection for `FirebaseMessaging` only (Firestore access delegated to
  UserProfileService per 1.10)
- `lib/features/auth/services/user_profile_service.dart` -- already good
  pattern, just needs a Riverpod provider
- `lib/features/paywall/providers/purchases_provider.dart` -- update providers
  to use instance service
- `lib/features/notifications/providers/notification_provider.dart` -- use
  existing `fcmServiceProvider` consistently
- `lib/main.dart` -- use providers instead of direct instantiation

**New files:**

- `lib/features/auth/providers/user_profile_provider.dart` -- Riverpod provider
  for `UserProfileService` + `userProfileProvider` (StreamProvider or
  FutureProvider for current user's profile)

**Pattern to follow (existing in `AuthService`):**

> **Research insight:** `Purchases` from RevenueCat is a static API surface --
> there is no `Purchases.instance` to inject. Instead, convert static methods to
> instance methods that internally call `Purchases.*` statics. Mock at the
> service level in tests, not at the RevenueCat SDK level.

```dart
class PurchasesService {
  // No constructor injection for Purchases -- it's a static API.
  // Instance methods wrap static calls for testability via provider override.

  Future<CustomerInfo> getCustomerInfo() async {
    return await Purchases.getCustomerInfo();
  }
  Future<void> login(String uid) async {
    await Purchases.logIn(uid);
  }
  Future<void> logout() async {
    await Purchases.logOut();
  }
  Future<CustomerInfo> purchase(Package package) async {
    return await Purchases.purchasePackage(package);
  }
  Future<CustomerInfo> restorePurchases() async {
    return await Purchases.restorePurchases();
  }
}

// Provider -- mock PurchasesService itself in tests
final purchasesServiceProvider = Provider<PurchasesService>(
  (ref) => PurchasesService(),
);
```

> **Field convention note:** Use public fields (matching existing `AuthService`
> pattern: `final FirebaseAuth firebaseAuth`) not private underscored fields.

**Acceptance criteria:**

- [ ] `PurchasesService` uses instance methods wrapping static RevenueCat calls
- [ ] `purchasesServiceProvider` explicitly defined in providers file
- [ ] `FcmService` accepts `FirebaseMessaging` via constructor (not
      `FirebaseFirestore` -- delegated to UserProfileService per 1.10)
- [ ] `UserProfileService` has a Riverpod provider
      (`userProfileServiceProvider`)
- [ ] `userProfileProvider` exists as a provider for the current user's profile
      data
- [ ] All services are consumed via `ref.read`/`ref.watch` from providers, never
      via direct `new` or static calls
- [ ] `main.dart` uses providers for initialization

##### 1.2 Fix router rebuild bug (A1)

**File to modify:** `lib/routing/router.dart`

**Current problem:** `routerProvider` is a `Provider<GoRouter>` that calls
`ref.watch(authStateProvider)`, causing GoRouter to be recreated on every auth
state change. This resets the entire navigation stack.

**Fix:** Create the `GoRouter` once. Bridge auth state to `refreshListenable`
via a `ChangeNotifier`:

```dart
class AuthChangeNotifier extends ChangeNotifier {
  // Note: Ref is only used in provider scope -- safe because this object
  // lives exactly as long as the provider that creates it.
  AuthChangeNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = AuthChangeNotifier(ref);
  // IMPORTANT: dispose the ChangeNotifier when provider is invalidated
  ref.onDispose(() => authNotifier.dispose());

  return GoRouter(
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final user = ref.read(authStateProvider).valueOrNull;
      // CONSTRAINT: redirect must be synchronous. Never await Firestore here.
      // Read cached provider values only (e.g., userProfileProvider.valueOrNull).
      // ... existing redirect logic
    },
    routes: [ ... ],
  );
});
```

> **Research insight (Context7 GoRouter docs):** The `refreshListenable` pattern
> is confirmed as the canonical approach. When `loginInfo` (a ChangeNotifier) is
> passed to `refreshListenable`, GoRouter automatically re-evaluates the current
> route. No manual `context.go()` needed after sign-in/sign-out.
>
> **Performance note:** Do NOT invalidate `routerProvider` during sign-out
> provider reset. The router must be stable. Only `refreshListenable` should
> trigger redirect re-evaluation.
>
> **Note:** After this fix, remove the manual `context.go(AppRoutes.auth)` in
> the sign-out handler -- the router's `refreshListenable` handles it
> automatically.

**Acceptance criteria:**

- [ ] `GoRouter` instance is created once, not rebuilt on auth changes
- [ ] `refreshListenable` triggers redirect re-evaluation on auth state changes
- [ ] Navigation stack is preserved across auth state emissions
- [ ] Redirect logic still correctly gates routes behind auth
- [ ] `AuthChangeNotifier` disposed via `ref.onDispose`
- [ ] Router redirect never performs blocking async calls
- [ ] Manual `context.go()` calls removed from sign-out/sign-in flows

##### 1.3 Create post-auth bootstrap provider (SpecFlow G1 + G3 + architecture)

**Problem:** Multiple post-auth side effects (profile creation, RevenueCat
login, FCM token save) are scattered or missing. Router redirect is synchronous
and cannot `await` Firestore. A unified orchestration point is needed.

> **Research insight (Architecture + Flutter Expert):** Router `redirect` is
> synchronous by design -- you cannot `await` inside it. Profile creation and
> other post-auth work must happen in a provider that listens to auth state, not
> in the redirect. The redirect only reads cached values.

**New file:** `lib/shared/providers/post_auth_bootstrap_provider.dart`

```dart
/// Orchestrates all post-sign-in side effects in a defined order.
/// Watched by the App widget to show loading state during bootstrap.
final postAuthBootstrapProvider = FutureProvider<void>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return;

  final profileService = ref.read(userProfileServiceProvider);

  // 1. Check/create profile (use set+merge to avoid race conditions)
  await profileService.createOrUpdateProfile(user.uid, {
    'email': user.email,
    'displayName': user.displayName,
    'photoUrl': user.photoURL,
    'createdAt': FieldValue.serverTimestamp(), // ignored on merge if exists
  });

  // 2. RevenueCat login (if paywall enabled)
  if (AppConfig.enablePaywall) {
    await ref.read(purchasesServiceProvider).login(user.uid);
  }

  // 3. FCM token save (if notifications enabled)
  if (AppConfig.enableNotifications) {
    await ref.read(fcmServiceProvider).saveTokenForUser(user.uid);
  }
});
```

> **Research insight (Firebase):** Use `set` with `SetOptions(merge: true)`
> instead of check-then-create to avoid race conditions on concurrent sign-ins
> (e.g., two devices). Server timestamp `createdAt` is ignored on merge if the
> field already exists.

**Acceptance criteria:**

- [ ] `postAuthBootstrapProvider` orchestrates profile + RevenueCat + FCM
- [ ] Uses `set(merge: true)` to avoid race conditions
- [ ] App shows loading state while bootstrap runs
- [ ] First-time sign-in creates Firestore profile automatically
- [ ] Returning users do not get duplicate profile creation
- [ ] Profile contains email, displayName, photoUrl, createdAt,
      onboardingComplete fields

##### 1.4 Fix onboarding auto-redirect (SpecFlow G2)

**Problem:** The router has a TODO comment about onboarding redirect but it's
unimplemented. New users skip onboarding entirely.

**File to modify:** `lib/routing/router.dart`

**Fix:** In the router redirect, after confirming the user is authenticated,
read cached `userProfileProvider.valueOrNull` to check `onboardingComplete`. If
false or null, redirect to `/onboarding`.

> **Performance constraint:** Router redirect must NEVER perform a blocking
> Firestore read. Read `userProfileProvider.valueOrNull` which is cached by the
> Riverpod StreamProvider/FutureProvider. If profile is still loading (null),
> redirect to a splash/loading route.

**Dependency:** Requires 1.3 (bootstrap provider creates profile) and
`userProfileProvider` from 1.1 so the router can read cached onboarding status.

**Acceptance criteria:**

- [ ] New users (onboardingComplete == false) are redirected to `/onboarding`
- [ ] Users who completed onboarding go directly to `/home`
- [ ] Completing onboarding updates the Firestore profile and triggers redirect
      to `/home`
- [ ] Redirect reads cached value only -- no `await` in redirect

##### 1.5 Wire RevenueCat login + fix premium state (A5 + SpecFlow G3)

**Problem:** `PurchasesService.login(uid)` is never called after sign-in. This
means `customerInfoProvider` returns empty entitlements. The premium state is
also a simple `StateProvider<bool>` that's never hydrated on cold start.

**Files to modify:**

- `lib/main.dart` or auth state listener -- call `purchasesService.login(uid)`
  after sign-in
- `lib/features/paywall/providers/purchases_provider.dart` -- replace
  `isPremiumProvider` with a derived provider

**Fix:**

```dart
// Replace StateProvider<bool> with derived provider
final isPremiumProvider = Provider<bool>((ref) {
  final customerInfo = ref.watch(customerInfoProvider);
  return customerInfo.whenOrNull(
    data: (info) => info.entitlements.active.containsKey('premium'),
  ) ?? false;
});
```

**Acceptance criteria:**

- [ ] `PurchasesService.login(uid)` called after successful sign-in
- [ ] `PurchasesService.logout()` called on sign-out (see also S6)
- [ ] `isPremiumProvider` derives from `customerInfoProvider`, not manual bool
- [ ] Premium state persists across cold starts (via RevenueCat SDK cache)
- [ ] `customerInfoProvider` refreshes after purchase/restore operations

##### 1.6 Fix provider reset on sign-out (SpecFlow G4)

**Problem:** Sign-out only calls `authService.signOut()` but doesn't reset
`isPremiumProvider`, `customerInfoProvider`, `onboardingProvider`, or the future
`userProfileProvider`. Stale data from previous user session leaks.

**Files to modify:**

- `lib/features/settings/screens/settings_screen.dart` (sign-out handler)

**Fix:** Invalidate all user-specific providers on sign-out:

```dart
// 1. Clear FCM token from Firestore (prevent notifications to signed-out device)
if (AppConfig.enableNotifications) {
  await ref.read(userProfileServiceProvider).clearFcmToken(user.uid);
}
// 2. RevenueCat logout
if (AppConfig.enablePaywall) {
  await ref.read(purchasesServiceProvider).logout();
}
// 3. Invalidate all user-specific providers
ref.invalidate(customerInfoProvider);
ref.invalidate(offeringsProvider);
ref.invalidate(userProfileProvider);
ref.invalidate(onboardingProvider);
ref.invalidate(postAuthBootstrapProvider);
// 4. Sign out (triggers router refresh via refreshListenable)
await ref.read(authServiceProvider).signOut();
// NOTE: Do NOT invalidate routerProvider. Do NOT call context.go() --
// the router's refreshListenable handles redirect to /auth automatically.
```

> **Research insight (Riverpod docs):** `ref.invalidate` marks the provider as
> dirty so it rebuilds on next read/watch. Riverpod batches invalidations -- no
> jank risk since no active watchers exist after redirect to `/auth`.
>
> **Research insight (Firebase):** Clear FCM token from Firestore on sign-out to
> prevent push notifications being sent to a signed-out device.

**Acceptance criteria:**

- [ ] FCM token cleared from Firestore on sign-out
- [ ] `PurchasesService.logout()` called before auth sign-out
- [ ] All user-specific providers invalidated (including
      `postAuthBootstrapProvider`)
- [ ] `routerProvider` is NOT invalidated
- [ ] No manual `context.go()` -- router handles redirect automatically
- [ ] New sign-in starts with fresh provider state

##### 1.7 Create UserProfile data model (A6)

**New file:** `lib/features/auth/models/user_profile.dart`

**Current problem:** All Firestore data is `Map<String, dynamic>` with no type
safety.

> **Research insight (Pattern Consistency):** `email` must be nullable -- Apple
> Sign-In can return null email. The existing `createProfile` accepts
> `String? email`. Also add `photoUrl` to match existing data shape.
>
> **Research insight (Flutter Expert):** Add `copyWith` for immutable updates
> (e.g., marking onboarding complete). Implement `operator ==` and `hashCode` so
> Riverpod correctly detects state changes without `freezed`.
>
> **Note:** The `uid` is passed separately to `fromMap` because Firestore
> document IDs are not stored in document data. Add a "why" comment.
>
> **Note:** `createdAt` can be null in local snapshots before server timestamp
> resolves. Handle with `DateTime.now()` fallback.

```dart
class UserProfile {
  final String uid;
  final String? email;  // nullable: Apple Sign-In may not provide email
  final String? displayName;
  final String? photoUrl;
  final bool onboardingComplete;
  final String? fcmToken;
  final DateTime createdAt;

  const UserProfile({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    this.onboardingComplete = false,
    this.fcmToken,
    required this.createdAt,
  });

  // uid passed separately because Firestore doc IDs are not in doc data
  factory UserProfile.fromMap(String uid, Map<String, dynamic> map) {
    return UserProfile(
      uid: uid,
      email: map['email'] as String?,
      displayName: map['displayName'] as String?,
      photoUrl: map['photoUrl'] as String?,
      onboardingComplete: map['onboardingComplete'] as bool? ?? false,
      fcmToken: map['fcmToken'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'email': email,
    'displayName': displayName,
    'photoUrl': photoUrl,
    'onboardingComplete': onboardingComplete,
    'fcmToken': fcmToken,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  UserProfile copyWith({
    String? email,
    String? displayName,
    String? photoUrl,
    bool? onboardingComplete,
    String? fcmToken,
  }) => UserProfile(
    uid: uid,
    email: email ?? this.email,
    displayName: displayName ?? this.displayName,
    photoUrl: photoUrl ?? this.photoUrl,
    onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    fcmToken: fcmToken ?? this.fcmToken,
    createdAt: createdAt,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile && uid == other.uid && email == other.email &&
      displayName == other.displayName && photoUrl == other.photoUrl &&
      onboardingComplete == other.onboardingComplete &&
      fcmToken == other.fcmToken && createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
    uid, email, displayName, photoUrl, onboardingComplete, fcmToken, createdAt,
  );
}
```

**Files to update:**

- `lib/features/auth/services/user_profile_service.dart` -- return `UserProfile`
  instead of `Map<String, dynamic>?`; add `createOrUpdateProfile` using
  `set(merge: true)`; add `clearFcmToken` method
- All consumers of `UserProfileService`

**Acceptance criteria:**

- [ ] `UserProfile` model exists with `fromMap`/`toMap`/`copyWith`/equality
- [ ] `email` is nullable (Apple Sign-In compatibility)
- [ ] `photoUrl` field included
- [ ] `createdAt` handles null server timestamp gracefully
- [ ] `UserProfileService` methods accept/return `UserProfile`
- [ ] All Firestore user data goes through the model
- [ ] Existing tests updated to use the model

##### 1.8 Fix theme provider race condition (A4)

**File to modify:** `lib/features/settings/providers/theme_provider.dart`

**Current problem:** `build()` returns `ThemeMode.light` synchronously, then
fires-and-forgets `_loadFromPrefs()`, causing a light-mode flash.

**Fix option A (recommended):** Initialize `SharedPreferences` in `main()` and
pass the already-loaded value to the provider:

> **Research insight (Flutter Expert):** The `sharedPreferencesProvider` is a
> shared dependency -- place it in `lib/shared/providers/` not inside the theme
> feature. The `ProviderScope` in `main.dart` MUST have `overrides:` (cannot be
> `const`) after this change.

```dart
// In lib/shared/providers/shared_preferences_provider.dart
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Must be overridden in ProviderScope');
});

// In main.dart -- CRITICAL: ProviderScope cannot be const after this
final prefs = await SharedPreferences.getInstance();
runApp(ProviderScope(
  overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  child: const App(),
));

// In theme_provider.dart
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final stored = prefs.getString('theme_mode');
    return stored == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }
}
```

**Acceptance criteria:**

- [ ] No light-mode flash on startup when user has dark mode saved
- [ ] Theme preference loads synchronously from pre-initialized
      SharedPreferences
- [ ] Toggle still persists to SharedPreferences
- [ ] `sharedPreferencesProvider` lives in `lib/shared/providers/`
- [ ] `ProviderScope` in `main.dart` has `overrides:` (not `const`)

##### 1.9 Implement StatefulShellRoute with Home + Profile (A3)

**Files to modify:**

- `lib/routing/router.dart` -- replace `ShellRoute` with `StatefulShellRoute`
- `lib/features/home/screens/home_screen.dart` -- update `HomeShell` to use
  `StatefulNavigationShell`

**New files:**

- `lib/features/profile/screens/profile_screen.dart` -- Profile tab showing user
  data from Firestore

**Dependency:** Requires 1.2 (router fix) since both rewrite `router.dart`.

**Fix:** Implement two-tab `StatefulShellRoute`:

```dart
// In router.dart
StatefulShellRoute.indexedStack(
  builder: (context, state, navigationShell) {
    return HomeShell(navigationShell: navigationShell);
  },
  branches: [
    StatefulShellBranch(routes: [
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
    ]),
    StatefulShellBranch(routes: [
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
    ]),
  ],
)
```

> **Research insight (Flutter Expert):** The critical missing piece is wiring
> `navigationShell.goBranch()` in the bottom nav bar. Without this, taps update
> local state but don't actually navigate. This is the most common
> `StatefulShellRoute` mistake.

```dart
// In HomeShell -- the critical wiring
class HomeShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const HomeShell({required this.navigationShell, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          // goBranch navigates to the branch's last known location
          navigationShell.goBranch(index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
```

> **Note:** `settings` and `paywall` routes remain as top-level `GoRoute`
> entries outside the shell (pushed as full-screen pages). This is correct for
> modal-style screens.

**Acceptance criteria:**

- [ ] Two working tabs: Home and Profile
- [ ] Each tab maintains its own navigation stack
- [ ] Bottom nav correctly highlights the active tab
- [ ] Profile screen displays user data from `userProfileProvider`
- [ ] Remove the non-functional Explore tab

##### 1.10 Fix FcmService feature boundary crossing (A7)

**File to modify:** `lib/features/notifications/services/fcm_service.dart`

**Current problem:** `FcmService.saveTokenForUser()` directly writes to the
`users` Firestore collection, crossing into the auth feature's domain.

**Fix:** Delegate token storage to `UserProfileService`:

```dart
// In UserProfileService, add:
Future<void> updateFcmToken(String uid, String token) async {
  await firestore.collection('users').doc(uid).update({'fcmToken': token});
}

// FcmService calls UserProfileService instead of Firestore directly
```

**Acceptance criteria:**

- [ ] `FcmService` does not import or reference `FirebaseFirestore`
- [ ] Token storage delegated to `UserProfileService`
- [ ] FCM token actually saved on production builds (fix M6 -- currently a
      no-op)

##### 1.11 Wire EnvironmentConfig (A8)

**File to modify:** `lib/config/environment.dart`

**Current problem:** `EnvironmentConfig.init()` is called in `main()` but the
value is never used anywhere.

**Fix:** Use `EnvironmentConfig.current` for:

- RevenueCat log level (see S7)
- Debug print guards
- Any future per-environment API endpoints

**Acceptance criteria:**

- [ ] `EnvironmentConfig.current` is used in at least 2 places
- [ ] RevenueCat log level conditional on environment

##### 1.12 Fix Platform detection (A9)

**File to modify:** `lib/features/auth/widgets/social_login_buttons.dart`

**Fix:** Replace `Platform.isIOS` (dart:io) with
`defaultTargetPlatform == TargetPlatform.iOS`.

**Acceptance criteria:**

- [ ] No `dart:io` import in widget code
- [ ] Platform detection works on all platforms including web

---

#### Phase 2: Security Hardening

Depends on Phase 1 service standardization for proper provider-based
architecture.

##### 2.1 Add Firestore security rules (S1)

**New file:** `firestore.rules`

> **Research insight (3 agents converged):** The original rules had a standalone
> `allow write` that conflicted with granular rules via OR logic, making field
> validation bypassable. Field validation must be conditions WITHIN each
> granular rule, not a separate `allow write`.
>
> **Additional hardening (Firebase + Security agents):**
>
> - Validate `email == request.auth.token.email` on create
> - Enforce type validation on all fields
> - Make `createdAt` immutable on updates
> - Add `photoUrl` to allowed fields
> - Add size limits on string fields

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid} {
      // Helper: validate allowed fields and types
      function validFields() {
        return request.resource.data.keys().hasOnly(
          ['email', 'displayName', 'photoUrl', 'onboardingComplete',
           'fcmToken', 'createdAt']
        )
        && (request.resource.data.onboardingComplete is bool)
        && (request.resource.data.get('displayName', '') is string)
        && (request.resource.data.get('fcmToken', '') is string);
      }

      allow read: if request.auth != null && request.auth.uid == uid;

      allow create: if request.auth != null && request.auth.uid == uid
        && validFields()
        && request.resource.data.email == request.auth.token.email;

      allow update: if request.auth != null && request.auth.uid == uid
        && validFields()
        // createdAt must not change on updates
        && request.resource.data.createdAt == resource.data.createdAt;

      allow delete: if request.auth != null && request.auth.uid == uid;
    }
    // Deny everything else by default
  }
}
```

> **Future enhancement:** For production apps, consider a Cloud Function
> triggered by Auth `onDelete` to clean up Firestore server-side, bypassing
> security rules. This ensures cleanup even if the client crashes mid-deletion.

**Acceptance criteria:**

- [x] `firestore.rules` exists in repo root
- [x] Users can only read/write their own `/users/{uid}` document
- [x] Field validation merged into each granular rule (no standalone
      `allow write`)
- [x] Type validation on fields (`onboardingComplete` must be bool, etc.)
- [x] `createdAt` immutable on updates
- [x] `email` validated against auth token on create
- [x] No collection-wide list access

##### 2.2 Fix account deletion safety (S2 + M5 + H4)

**File to modify:** `lib/features/settings/screens/settings_screen.dart`

**Current problems:**

1. Firestore data deleted before auth account (which can fail with
   `requires-recent-login`)
2. No re-authentication flow
3. No loading state during deletion
4. No error handling

> **Research insight (ALL agents converged on this):** The original plan said
> "delete auth first, then Firestore." This is WRONG. Once auth is deleted, the
> user's token is invalidated and subsequent Firestore operations fail because
> security rules require `request.auth.uid == uid`.
>
> **Correct order:** Re-auth (validate) → Firestore delete → RevenueCat logout →
> Auth delete (point of no return). If Firestore delete fails, the user can
> retry while still authenticated.

**Fix:** Re-auth first, then Firestore, then auth last:

```dart
Future<void> _deleteAccount() async {
  setState(() => _isDeleting = true);
  try {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    // 1. Re-authenticate first (validates session is fresh)
    await _reauthenticate();

    // 2. Clean up Firestore FIRST (while auth token is still valid)
    await ref.read(userProfileServiceProvider).deleteProfile(user.uid);

    // 3. Clean up RevenueCat
    if (AppConfig.enablePaywall) {
      await ref.read(purchasesServiceProvider).logout();
    }

    // 4. Delete auth account LAST (point of no return)
    // After this, Firestore security rules reject any further operations
    await ref.read(authServiceProvider).deleteAccount();

    // 5. Invalidate providers (router handles redirect via refreshListenable)
    ref.invalidate(userProfileProvider);
    ref.invalidate(customerInfoProvider);
    ref.invalidate(postAuthBootstrapProvider);
  } on FirebaseAuthException catch (e) {
    if (e.code == 'requires-recent-login') {
      _showReauthDialog();
      return;
    }
    _showError('Account deletion failed. Please try again.');
  } catch (e) {
    _showError('Something went wrong. Please try again.');
  } finally {
    if (mounted) setState(() => _isDeleting = false);
  }
}
```

**Acceptance criteria:**

- [x] Re-authentication flow before any deletion
- [x] Firestore data deleted BEFORE auth account (while token is valid)
- [x] Auth account deleted LAST (point of no return)
- [x] Loading state shown during deletion
- [x] `requires-recent-login` handled with re-auth dialog
- [x] All user data cleaned up (Firestore profile, RevenueCat, FCM token)
- [x] Error messages are user-friendly, not raw exceptions
- [x] Provider invalidation after deletion (no manual `context.go()`)

##### 2.3 Move API keys out of source (S3)

**File to modify:** `lib/config/app_config.dart`

**Fix:** Move RevenueCat keys to `--dart-define`:

```dart
class AppConfig {
  static const revenueCatAppleApiKey = String.fromEnvironment(
    'REVENUECAT_APPLE_KEY',
    defaultValue: '',
  );
  static const revenueCatGoogleApiKey = String.fromEnvironment(
    'REVENUECAT_GOOGLE_KEY',
    defaultValue: '',
  );
}
```

**New file:** `.env.example` (documenting required keys)

**Acceptance criteria:**

- [x] API keys read from `--dart-define` environment variables
- [x] `.env.example` documents required keys
- [x] No real API keys in committed source code
- [ ] README documents how to set keys

##### 2.4 Fix .gitignore (S4)

**File to modify:** `.gitignore`

**Add entries for:**

```
# Firebase config files
**/google-services.json
**/GoogleService-Info.plist
lib/firebase_options.dart

# Environment files
.env
.env.*
!.env.example
```

**Acceptance criteria:**

- [x] Firebase config files excluded from git
- [x] `.env` files excluded (but `.env.example` tracked)
- [x] `firebase_options.dart` excluded

##### 2.5 Sanitize error messages (S5)

**Files to modify:**

- `lib/features/auth/screens/auth_screen.dart`
- `lib/features/paywall/screens/paywall_screen.dart`
- `lib/features/settings/screens/settings_screen.dart`

> **Research insight (Simplicity):** A shared utility file is overkill for a
> starter kit with 3 screens. Inline a short switch at each call site instead.
>
> **Research insight (Security):** Also handle `PlatformException` (from
> RevenueCat/Google Sign-In) and `SocketException` (network errors), not just
> `FirebaseAuthException`.
>
> **Canonical error handling pattern (Pattern Consistency):** Each screen's
> catch block should: (1) log the full error to Crashlytics, (2) show a
> user-friendly message via `ScaffoldMessenger.showSnackBar`.

**Fix:** Inline error mapping at each call site (no shared utility file):

```dart
// Example pattern for each screen's catch blocks:
} on FirebaseAuthException catch (e, stack) {
  FirebaseCrashlytics.instance.recordError(e, stack);
  final message = switch (e.code) {
    'requires-recent-login' => 'Please sign in again to continue.',
    _ => 'Authentication error. Please try again.',
  };
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
} on PlatformException catch (e, stack) {
  FirebaseCrashlytics.instance.recordError(e, stack);
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Something went wrong. Please try again.')),
  );
} catch (e, stack) {
  FirebaseCrashlytics.instance.recordError(e, stack);
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Something went wrong. Please try again.')),
  );
}
```

**Acceptance criteria:**

- [x] No `error.toString()` shown to users
- [x] Errors mapped inline at each call site (no shared utility file)
- [x] `FirebaseAuthException`, `PlatformException`, and generic errors handled
- [ ] Full errors logged to Crashlytics (not `print`)
- [x] User sees friendly message via SnackBar

##### 2.6 Fix sign-out RevenueCat cleanup (S6)

**File to modify:** `lib/features/settings/screens/settings_screen.dart`

Already covered in Phase 1.6 (provider reset on sign-out). Verify
`PurchasesService.logout()` is called.

##### 2.7 Conditional RevenueCat logging (S7)

**File to modify:** `lib/features/paywall/services/purchases_service.dart`

Already covered in Phase 1.11 (wire EnvironmentConfig). Set `LogLevel.debug`
only for dev, `LogLevel.error` for staging/prod.

##### 2.8 Fix FCM token logging (S8)

**File to modify:** `lib/features/notifications/services/fcm_service.dart`

**Fix:** Remove `print('FCM Token: $token')` entirely or replace with structured
logger.

**Acceptance criteria:**

- [x] No FCM token printed to console in any build mode

---

#### Phase 3: Testing Foundation

Depends on Phase 1 service standardization for injectable services.

##### 3.1 Add router redirect tests (T1)

**New file:** `test/routing/router_redirect_test.dart`

**Test cases:**

```dart
group('Router redirect', () {
  test('unauthenticated user redirected to /auth', ...);
  test('authenticated user on /auth redirected to /home', ...);
  test('new user (onboarding incomplete) redirected to /onboarding', ...);
  test('authenticated user can access /settings', ...);
  test('authenticated user can access /paywall', ...);
});
```

**Acceptance criteria:**

- [x] All redirect scenarios tested
- [x] Tests use mocked auth state (not real Firebase)
- [x] Onboarding redirect tested

##### 3.2 Add error path tests (T2)

**Files to modify/create:**

- `test/features/auth/services/auth_service_test.dart` -- add sign-in
  cancellation, sign-in failure, delete account failure tests
- `test/features/auth/services/user_profile_service_test.dart` -- add Firestore
  failure tests

**Test cases:**

```dart
group('error handling', () {
  test('signInWithGoogle throws on cancellation', ...);
  test('deleteAccount throws requires-recent-login', ...);
  test('createProfile handles Firestore failure', ...);
});
```

**Acceptance criteria:**

- [x] At least 6 error path tests across auth and profile services
- [x] Tests verify correct exception types are thrown
- [x] Tests verify error messages are appropriate

##### 3.3 Add widget tests for screens (T3)

**New files:**

- `test/features/auth/screens/auth_screen_test.dart`
- `test/features/home/screens/home_screen_test.dart`
- `test/features/settings/screens/settings_screen_test.dart`

**Test patterns:**

```dart
testWidgets('AuthScreen shows social login buttons', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authServiceProvider.overrideWith((_) => mockAuthService)],
      child: const MaterialApp(home: AuthScreen()),
    ),
  );
  expect(find.byType(SocialLoginButtons), findsOneWidget);
});
```

**Acceptance criteria:**

- [x] Each screen has at least 2 widget tests
- [x] Tests verify correct widgets render
- [x] Tests verify user interactions (tap handlers)
- [x] Tests use provider overrides for dependency injection

##### 3.4 Add notification tests (T4)

**New file:** `test/features/notifications/services/fcm_service_test.dart`

**Dependency:** Requires Phase 1.10 (FcmService constructor injection).

**Acceptance criteria:**

- [x] FcmService initialization tested
- [x] Token refresh handler tested
- [x] Token storage delegation tested

##### 3.5 Add PurchasesService tests (T5)

**New file:** `test/features/paywall/services/purchases_service_test.dart`

**Dependency:** Requires Phase 1.1 (instance methods with injection).

**Acceptance criteria:**

- [x] Login, logout, purchase, restore methods tested
- [x] Error handling tested
- [x] CustomerInfo parsing tested

##### 3.6 Add shared widget tests (T6)

**New files:**

- `test/shared/widgets/premium_gate_test.dart`
- `test/shared/widgets/loading_state_test.dart`

**Acceptance criteria:**

- [x] `PremiumGate` shows child when premium, shows paywall prompt when not
- [x] `LoadingState` renders correctly in loading/loaded/error states

##### 3.7 Remove unused test dependencies (T7)

**File to modify:** `pubspec.yaml`

- Remove `mockito` (only `mocktail` is used)

**Acceptance criteria:**

- [x] `mockito` removed from dev_dependencies
- [x] All tests still pass

---

#### Phase 4: UX & Feature Polish

##### 4.1 Add global error handling (U1)

**File to modify:** `lib/main.dart`

**New file:** `lib/shared/widgets/error_screen.dart`

> **Research insight (Simplicity):** Drop `runZonedGuarded` --
> `PlatformDispatcher.instance.onError` covers async errors in Flutter 3.x+. Two
> catch zones is sufficient and simpler.
>
> **Research insight (Firebase):** Must call
> `setCrashlyticsCollectionEnabled(!kDebugMode)` during init, not just gate the
> error forwarding. Also set `setUserIdentifier(uid)` after sign-in and clear on
> sign-out.
>
> **Research insight (Performance):** Parallelize Firebase and RevenueCat init
> with `Future.wait()` to reduce app startup time.

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase first (required by Crashlytics)
  await FirebaseService.initialize();

  // Set up error handlers AFTER Firebase init, BEFORE runApp
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Disable Crashlytics collection in debug mode
  await FirebaseCrashlytics.instance
      .setCrashlyticsCollectionEnabled(!kDebugMode);

  // Parallelize remaining initialization
  final prefs = await SharedPreferences.getInstance();
  await Future.wait([
    if (AppConfig.enablePaywall) PurchasesService.initialize(),
    if (AppConfig.enableNotifications) FcmService().initialize(),
  ]);

  // ProviderScope CANNOT be const -- has overrides for SharedPreferences
  runApp(ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: const App(),
  ));
}
```

**New file:** `lib/shared/widgets/error_screen.dart`

```dart
class ErrorScreen extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  // Shows friendly error message with optional retry button
}
```

**Acceptance criteria:**

- [ ] `FlutterError.onError` catches widget errors
- [ ] `PlatformDispatcher.instance.onError` catches async/platform errors
- [ ] `setCrashlyticsCollectionEnabled(!kDebugMode)` called during init
- [ ] Firebase + RevenueCat init parallelized with `Future.wait()`
- [ ] Custom `ErrorScreen` widget exists for graceful degradation
- [ ] Errors sent to Crashlytics (collection disabled in debug mode)

##### 4.2 Add Firebase Crashlytics (U2)

**File to modify:** `pubspec.yaml` -- add `firebase_crashlytics` **File to
modify:** `lib/config/app_config.dart` -- add `enableCrashlytics` feature flag
**File to modify:** `lib/main.dart` -- initialize Crashlytics

**Acceptance criteria:**

- [ ] `firebase_crashlytics` package added
- [ ] Feature-flag gated (`AppConfig.enableCrashlytics`)
- [ ] Wired to global error handler (4.1)
- [ ] `setUserIdentifier(uid)` called after sign-in (in bootstrap provider)
- [ ] User identifier cleared on sign-out
- [ ] `setCrashlyticsCollectionEnabled(!kDebugMode)` during init

##### 4.3 Add Firebase Analytics (U3)

**File to modify:** `pubspec.yaml` -- add `firebase_analytics` **File to
modify:** `lib/config/app_config.dart` -- add `enableAnalytics` feature flag

> **Research insight (Simplicity):** Do NOT create an `AnalyticsService`
> abstraction. Use `FirebaseAnalytics.instance` directly with inline calls. A
> wrapper class adds indirection with zero value for a starter kit.
>
> **Research insight (Firebase):** The event names `sign_in` and `purchase`
> collide with Firebase automatic events. Use `app_sign_in` prefix or rely on
> automatic events and only log custom parameters.
>
> **Research insight (Firebase):** Call
> `setAnalyticsCollectionEnabled(AppConfig.enableAnalytics)` to respect the
> feature flag. Wire `FirebaseAnalyticsObserver` into GoRouter's `observers`
> parameter. Also set user properties like `premium_status` for segmentation.

**Example events (inline, no service abstraction):**

```dart
// In auth flow:
FirebaseAnalytics.instance.logEvent(
  name: 'app_sign_in',
  parameters: {'method': 'google'},
);

// In onboarding:
FirebaseAnalytics.instance.logEvent(name: 'onboarding_complete');

// Set user properties for segmentation:
FirebaseAnalytics.instance.setUserProperty(
  name: 'premium_status',
  value: isPremium ? 'premium' : 'free',
);
```

**Acceptance criteria:**

- [ ] `firebase_analytics` package added
- [ ] Feature-flag gated (`AppConfig.enableAnalytics`)
- [ ] `setAnalyticsCollectionEnabled` called with feature flag
- [ ] NO `AnalyticsService` wrapper -- use `FirebaseAnalytics.instance` directly
- [ ] Example inline analytics calls in auth, onboarding, and paywall flows
- [ ] Custom event names avoid collision with Firebase automatic events
- [ ] `FirebaseAnalyticsObserver` wired into GoRouter for screen tracking
- [ ] User properties set for segmentation (`premium_status`)

##### 4.4 Remove flutter_animate (U4 + C2)

> **Research insight (Simplicity):** `flutter_animate` adds zero functional
> value. Remove the dependency entirely. If subtle animations are needed for
> onboarding, use Flutter's built-in implicit animations (`AnimatedOpacity`,
> `AnimatedSlide`, `AnimatedContainer`) which are simpler and have no dependency
> cost.

**File to modify:** `pubspec.yaml` -- remove `flutter_animate`

**Acceptance criteria:**

- [ ] `flutter_animate` removed from dependencies
- [ ] Any animations use built-in Flutter implicit animations only

##### 4.5 Add empty state widget (U5)

> **Research insight (Simplicity):** Eliminate `SkeletonLoader` --
> `CircularProgressIndicator` is the universally understood Flutter loading
> pattern. Shimmer effects are app-level polish, not starter kit territory. Keep
> only `EmptyState`.

**New file:**

- `lib/shared/widgets/empty_state.dart` -- reusable empty state with icon,
  title, subtitle, optional action button

**Acceptance criteria:**

- [ ] `EmptyState` widget with customizable icon, title, subtitle, action
- [ ] No `SkeletonLoader` -- use `CircularProgressIndicator` for loading
- [ ] Used in at least one screen (e.g., Profile when no data)

##### 4.6 Fix accessibility gaps (U6)

**Files to modify:**

- `lib/features/onboarding/widgets/progress_dots.dart` -- add semantic labels
- `lib/features/paywall/screens/paywall_screen.dart` -- add text labels to
  color-only checkmark indicators, add semantic labels to icons

**Acceptance criteria:**

- [ ] All icons have `semanticLabel` or are wrapped in `Semantics`
- [ ] Color-only indicators have text alternatives
- [ ] Touch targets meet 48dp minimum

##### 4.7 Add app version to settings (U7)

**File to modify:** `lib/features/settings/screens/settings_screen.dart`

**Add:** `package_info_plus` dependency, display version at bottom of settings.

**Acceptance criteria:**

- [ ] App version and build number shown in settings
- [ ] Feedback/support link or email in settings

##### 4.8 Add generic onboarding content (U9)

**File to modify:** `lib/features/onboarding/screens/onboarding_screen.dart`

**Fix:** Replace placeholder content with generic but real-looking copy:

- Page 1: "Welcome to AppName" + app overview
- Page 2: "Stay on Track" + feature highlights
- Page 3: "Get Started" + call to action

**Acceptance criteria:**

- [ ] Three onboarding pages with real-looking content
- [ ] Content is clearly generic/replaceable (documented in inline comments)
- [ ] Uses built-in implicit animations if needed (no `flutter_animate`)

---

### Cleanup Tasks (Throughout)

| #   | Task                                                                        | Phase        |
| --- | --------------------------------------------------------------------------- | ------------ |
| C1  | Remove unused `mockito` dev dependency                                      | Phase 3 (T7) |
| C2  | Remove `flutter_animate` dependency                                         | Phase 4 (U4) |
| C3  | Remove unused `build_runner` and `riverpod_generator`                       | Phase 1      |
| C4  | Rename `app_test.dart` to `auth_state_unit_test.dart`                       | Phase 3      |
| C5  | Standardize tests: setUp/tearDown, `overrideWithValue` (not `overrideWith`) | Phase 3      |

---

### Documentation (Throughout)

As decided in brainstorm: both inline comments and a docs/ guide.

**Inline comments:** Add "why" comments to non-obvious patterns:

- Router `refreshListenable` pattern
- Service constructor injection rationale
- Provider reset on sign-out
- Account deletion order
- Error handling setup in `main.dart`

**File to update:** `docs/reference/architecture.md` (or create if absent)

- Update architecture docs to reflect new patterns
- Document the provider dependency graph
- Document the auth flow (sign-in -> profile creation -> onboarding check)

**File to update:** `README.md`

- Add setup instructions for `--dart-define` API keys
- Add section on Firestore security rules deployment
- Document feature flags

---

## System-Wide Impact

### Interaction Graph

- Sign-in triggers: auth state change -> `postAuthBootstrapProvider` runs
  (profile creation via `set(merge:true)`, RevenueCat login, FCM token save) ->
  `userProfileProvider` updates -> router `refreshListenable` fires -> redirect
  evaluates cached profile -> onboarding or home
- Sign-out triggers: clear FCM token -> RevenueCat logout -> invalidate all user
  providers -> auth sign-out -> router `refreshListenable` fires -> redirect to
  `/auth` (no manual `context.go()`)
- Account deletion triggers: re-auth (validate) -> Firestore delete (while token
  valid) -> RevenueCat logout -> auth delete (point of no return) -> provider
  invalidation -> router redirect to `/auth`

### Error Propagation

- Widget errors caught by `FlutterError.onError` -> Crashlytics
- Async/platform errors caught by `PlatformDispatcher.instance.onError` ->
  Crashlytics
- Service errors caught inline in screens -> user-friendly SnackBar + full error
  to Crashlytics
- Firebase Auth errors surface as `FirebaseAuthException` with `.code`

### State Lifecycle Risks

- **Sign-in race:** Profile creation and RevenueCat login are async. If user
  navigates before completion, profile may be null. Mitigate with loading state
  in router redirect.
- **Sign-out stale state:** Addressed in 1.6 with provider invalidation.
- **Account deletion partial failure:** Addressed in 2.2 with correct operation
  ordering.

### API Surface Parity

All changes are internal. No external API surface. The starter kit's "API" is
its file structure and patterns -- these must remain consistent and
well-documented.

---

## Acceptance Criteria

### Functional Requirements

- [ ] All services use consistent constructor injection + Riverpod provider
      pattern
- [ ] Router creates GoRouter once, uses refreshListenable
- [ ] Two working tabs (Home + Profile) with StatefulShellRoute
- [ ] Profile created automatically on first sign-in
- [ ] Onboarding auto-redirect works
- [ ] Premium state hydrated from RevenueCat on cold start
- [ ] All providers reset on sign-out
- [ ] Theme loads without flash
- [ ] Firestore security rules deployed
- [ ] Account deletion is safe (re-auth + correct order)
- [ ] API keys not in source code
- [ ] Global error handling with Crashlytics
- [ ] Firebase Analytics with example events

### Non-Functional Requirements

- [ ] Zero `dart:io` imports in widget code
- [ ] Zero `error.toString()` shown to users
- [ ] Zero unused dependencies in pubspec.yaml
- [ ] All icons have semantic labels
- [ ] Touch targets meet 48dp minimum

### Quality Gates

- [ ] All existing tests still pass
- [ ] At least 15 new tests added (router, error paths, widgets, services)
- [ ] `flutter analyze` passes with zero warnings
- [ ] Inline "why" comments on non-obvious patterns
- [ ] Architecture docs updated

---

## Dependencies & Prerequisites

- Phase 1 must complete before Phase 2 (security fixes need correct service
  patterns)
- Phase 1 must complete before Phase 3 (tests need injectable services)
- Phase 4 items U1/U2 depend on `firebase_crashlytics` package
- Phase 4 item U3 depends on `firebase_analytics` package
- Item 1.4 (onboarding redirect) depends on 1.3 (profile creation) and 1.1
  (userProfileProvider)
- Item 1.5 (premium state) depends on 1.1 (PurchasesService instance methods)
- Items T4, T5 depend on Phase 1 service refactoring

---

## Risk Analysis & Mitigation

| Risk                                           | Impact | Likelihood | Mitigation                                             |
| ---------------------------------------------- | ------ | ---------- | ------------------------------------------------------ |
| Router refactor breaks navigation              | High   | Medium     | Write router redirect tests (T1) immediately after A1  |
| Service refactor breaks existing tests         | Medium | High       | Run tests after each service change, fix incrementally |
| Profile creation adds latency to first sign-in | Low    | Medium     | Show loading state, create profile async               |
| Firestore rules too restrictive                | Medium | Low        | Test rules with Firebase emulator before deploy        |
| flutter_animate adds jank on low-end devices   | Low    | Low        | Keep animations simple, respect disableAnimations      |

---

## Sources & References

### Origin

- **Brainstorm document:**
  [docs/brainstorms/2026-03-07-starter-kit-improvements-brainstorm.md](docs/brainstorms/2026-03-07-starter-kit-improvements-brainstorm.md)
  -- Key decisions carried forward: two tabs with StatefulShellRoute,
  client-side premium verification, manual data models, full global error
  handling with Crashlytics

### SpecFlow Analysis

- **Gap analysis:**
  [docs/analysis/2026-03-07-spec-flow-analysis.md](docs/analysis/2026-03-07-spec-flow-analysis.md)
  -- Identified 4 critical gaps: profile creation never triggered, onboarding
  redirect unimplemented, RevenueCat login never called, provider state not
  reset on sign-out

### Internal References

- Router: `lib/routing/router.dart`
- Auth service: `lib/features/auth/services/auth_service.dart`
- User profile service: `lib/features/auth/services/user_profile_service.dart`
- Purchases service: `lib/features/paywall/services/purchases_service.dart`
- FCM service: `lib/features/notifications/services/fcm_service.dart`
- Theme provider: `lib/features/settings/providers/theme_provider.dart`
- Home screen: `lib/features/home/screens/home_screen.dart`
- Settings screen: `lib/features/settings/screens/settings_screen.dart`
- App config: `lib/config/app_config.dart`
- Main entry: `lib/main.dart`
