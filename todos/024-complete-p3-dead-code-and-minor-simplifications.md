---
status: complete
priority: p3
issue_id: "024"
tags: [code-review, quality, simplicity]
dependencies: []
---

# Dead Code and Minor Simplification Opportunities

## Problem Statement

Several small issues identified across the codebase that individually are minor
but collectively add unnecessary complexity to a starter kit.

**Why it matters:** A starter kit should be as clean as possible since
developers use it as a reference.

## Findings

- **Code Simplicity Reviewer:**
  1. `goToPage()` in `onboarding_provider.dart` is never called - dead code
  2. `FirebaseService` is a one-line static wrapper - could inline into `main()`
  3. Empty FCM handlers in `fcm_service.dart` with no TODO markers
  4. Scattered feature-flag guards
     (`AppConfig.enableAnalytics && Firebase.apps.isNotEmpty`) repeated 5+ times
  5. `ErrorScreen` and `LoadingState` widgets overlap in error UI functionality
  6. Redundant null return in router redirect logic

## Proposed Solutions

### Option A: Address each individually (Recommended)

1. Remove `goToPage()` dead code
2. Keep `FirebaseService` (it's a clear extension point for the starter kit)
3. Add TODO comments to empty FCM handlers
4. Extract repeated feature-flag guard into `AppConfig.shouldLogAnalytics`
5. Clarify distinction between ErrorScreen and LoadingState
6. Remove redundant null return

**Effort:** Small **Risk:** Low

## Technical Details

**Affected files:**

- `lib/features/onboarding/providers/onboarding_provider.dart`
- `lib/features/notifications/services/fcm_service.dart`
- `lib/config/app_config.dart`
- `lib/routing/router.dart`

## Acceptance Criteria

- [ ] No dead code in provider files
- [ ] Empty handlers have TODO markers
- [ ] Feature-flag checks are DRY

## Work Log

| Date       | Action                        | Learnings                    |
| ---------- | ----------------------------- | ---------------------------- |
| 2026-03-07 | Identified during code review | Simplicity reviewer findings |
