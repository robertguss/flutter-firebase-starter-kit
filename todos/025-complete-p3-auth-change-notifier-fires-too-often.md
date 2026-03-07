---
status: complete
priority: p3
issue_id: "025"
tags: [code-review, performance]
dependencies: []
---

# AuthChangeNotifier Fires on Every Profile Field Change

## Problem Statement

`AuthChangeNotifier` listens to both `authStateProvider` and
`userProfileProvider`. Every Firestore document field change (including
`fcmToken` writes) triggers `notifyListeners()`, causing GoRouter to re-evaluate
redirect logic unnecessarily.

**Why it matters:** FCM token refresh happens periodically and triggers a full
router redirect evaluation each time, even though auth/onboarding status hasn't
changed.

## Findings

- **Performance Oracle:** `AuthChangeNotifier` fires on every Firestore user
  document change, not just onboarding status changes. `profileStream` streams
  the entire user document; `fcmToken` writes trigger rebuilds of all profile
  watchers.

## Proposed Solutions

### Option A: Filter notifications to relevant fields (Recommended)

Only call `notifyListeners()` when auth state or `onboardingComplete` actually
changes. Cache the previous values and compare.

**Pros:** Eliminates unnecessary redirect evaluations. **Cons:** Slightly more
logic in notifier. **Effort:** Small **Risk:** Low

## Technical Details

**Affected files:**

- `lib/routing/router.dart` - `AuthChangeNotifier` class

## Acceptance Criteria

- [ ] FCM token refresh doesn't trigger router redirect
- [ ] Auth state changes still trigger redirect correctly
- [ ] Onboarding completion still triggers redirect correctly

## Work Log

| Date       | Action                        | Learnings                  |
| ---------- | ----------------------------- | -------------------------- |
| 2026-03-07 | Identified during code review | Performance oracle finding |
