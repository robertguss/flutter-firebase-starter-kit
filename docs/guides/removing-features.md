# Removing Features

This starter kit is designed so that each feature can be independently removed.
Below are step-by-step checklists for cleanly removing the Paywall,
Notifications, and Onboarding features.

---

## Removing Paywall

1. Delete the entire `lib/features/paywall/` directory (includes screens,
   providers, services, and widgets such as `premium_gate.dart`).

2. Delete the entire `test/features/paywall/` directory (if it exists).

3. Delete `test/shared/widgets/premium_gate_test.dart`.

4. In `lib/main.dart`:
   - Remove the imports for `purchases_provider.dart`, `purchases_service.dart`,
     and `premium_provider.dart`.
   - Remove the `PurchasesService().initialize()` call inside `Future.wait`.
   - Remove the entire `if (AppConfig.enablePaywall)` block that registers
     bootstrap, sign-out, and delete-account hooks (lines adding to
     `bootstrapHooks`, `signOutHooks`, and `deleteAccountHooks`).
   - Remove the `if (AppConfig.enablePaywall) ...[` override block inside
     `ProviderScope` that overrides `isPremiumProvider` and
     `restorePurchasesActionProvider`.

5. In `lib/routing/router.dart`:
   - Remove the import for `paywall_screen.dart`.
   - Remove the `GoRoute` entry for `AppRoutes.paywall`.

6. In `lib/routing/routes.dart`:
   - Remove the line `static const String paywall = '/paywall';`.

7. In `lib/shared/providers/premium_provider.dart`:
   - Either delete the file entirely, or simplify `isPremiumProvider` to always
     return `false` and remove `restorePurchasesActionProvider`.

8. In `pubspec.yaml`:
   - Remove the `purchases_flutter` dependency under `# Payments`.

9. In `lib/config/app_config.dart`:
   - Set `enablePaywall` to `false`, or remove the flag entirely.

10. Search the codebase for any remaining references to `PremiumGate`,
    `isPremiumProvider`, `restorePurchasesActionProvider`, `PaywallScreen`, or
    `AppRoutes.paywall` and remove them.

11. **Verify:** Run `flutter pub get`, then `flutter analyze`, then
    `flutter test`. Fix any compilation errors from dangling references.

---

## Removing Notifications

1. Delete the entire `lib/features/notifications/` directory (includes
   providers, services, and screens).

2. Delete `test/features/notifications/` (if it exists).

3. In `lib/main.dart`:
   - Remove the imports for `notification_provider.dart` and `fcm_service.dart`.
   - Remove the `FcmService().initialize()` call inside `Future.wait`.
   - Remove the entire `if (AppConfig.enableNotifications)` block that registers
     bootstrap and sign-out hooks (the block that calls `fcmService.getToken()`,
     `profileService.updateFcmToken()`, `startTokenRefreshListener()`, and
     `stopTokenRefreshListener()`).

4. In `pubspec.yaml`:
   - Remove the `firebase_messaging` dependency under `# Firebase`.

5. In `lib/config/app_config.dart`:
   - Set `enableNotifications` to `false`, or remove the flag entirely.

6. If your `UserProfile` model has an `fcmToken` field, decide whether to keep
   it. If notifications are gone permanently, remove the field and any Firestore
   writes that reference it.

7. Search the codebase for remaining references to `fcmService`,
   `NotificationProvider`, `FcmService`, or `firebase_messaging` and remove
   them.

8. **Verify:** Run `flutter pub get`, then `flutter analyze`, then
   `flutter test`. Fix any compilation errors from dangling references.

---

## Removing Onboarding

1. Delete the entire `lib/features/onboarding/` directory (includes providers,
   screens, and widgets).

2. Delete `test/features/onboarding/` (if it exists).

3. In `lib/main.dart`:
   - Remove the import for `onboarding_provider.dart`.
   - Remove the sign-out hook that invalidates `onboardingProvider`:
     ```dart
     signOutHooks.add((ref, uid) async {
       ref.invalidate(onboardingProvider);
     });
     ```

4. In `lib/routing/router.dart`:
   - Remove the import for `onboarding_screen.dart`.
   - Remove the `GoRoute` entry for `AppRoutes.onboarding`.
   - In `AuthChangeNotifier`, remove the `ref.listen(userProfileProvider, ...)`
     block and the `_wasOnboardingComplete` field (the notifier only needs to
     track auth state).
   - In `routerRedirect()`, remove the `isOnOnboardingPage` variable and the
     `if (isLoggedIn && !isOnOnboardingPage)` block that checks
     `profile.onboardingComplete`.

5. In `lib/routing/routes.dart`:
   - Remove the line `static const String onboarding = '/onboarding';`.

6. In your `UserProfile` model (likely in `lib/features/auth/` or
   `lib/shared/`):
   - Remove the `onboardingComplete` field.
   - Update the `fromMap()` / `toMap()` serialization to exclude it.

7. In your Firestore security rules (`firestore.rules`):
   - Remove any references to the `onboardingComplete` field if it is explicitly
     validated.

8. Search the codebase for remaining references to `onboardingComplete`,
   `OnboardingScreen`, `onboardingProvider`, or `AppRoutes.onboarding` and
   remove them.

9. **Verify:** Run `flutter pub get`, then `flutter analyze`, then
   `flutter test`. Fix any compilation errors from dangling references.
