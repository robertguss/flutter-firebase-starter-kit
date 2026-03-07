---
status: complete
priority: p2
issue_id: "006"
tags: [code-review, security, error-handling]
dependencies: []
---

# signOutProvider Has No Error Handling

## Problem Statement

`lib/shared/providers/sign_out_provider.dart` does not wrap its steps in
try-catch. If `clearFcmToken` or `PurchasesService.logout()` throws, the user
will not be signed out and no error is shown. The settings screen calls
`await ref.read(signOutProvider.future)` with no error handling around it
either.

**Why it matters:** A network error during FCM token cleanup would prevent
sign-out entirely, trapping the user in a signed-in state with no feedback.

## Proposed Solutions

### Option A: Wrap cleanup in try-catch, always sign out (Recommended)

Make FCM cleanup and RevenueCat logout best-effort. Always proceed to auth
sign-out even if cleanup fails.

**Effort:** Small **Risk:** Low

### Option B: Add error handling in settings_screen.dart

Catch errors at the call site and show a SnackBar.

**Effort:** Small **Risk:** Low (but sign-out still fails)

## Technical Details

**Affected files:**

- `lib/shared/providers/sign_out_provider.dart`
- `lib/features/settings/screens/settings_screen.dart`

## Acceptance Criteria

- [ ] Sign-out completes even if FCM cleanup or RevenueCat logout fails
- [ ] Cleanup failures are logged (Crashlytics) but don't block sign-out
- [ ] User always ends up signed out
