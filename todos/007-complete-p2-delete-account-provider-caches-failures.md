---
status: complete
priority: p2
issue_id: "007"
tags: [code-review, architecture, usability]
dependencies: []
---

# deleteAccountProvider Caches Failures - No Retry Path

## Problem Statement

`deleteAccountProvider` is a `FutureProvider`, which caches results. If the
first call fails (e.g., re-auth failure with `requires-recent-login`),
subsequent calls may return the cached error without retrying. The settings
screen does not `ref.invalidate(deleteAccountProvider)` before retrying.

**Why it matters:** A user who gets `requires-recent-login`, re-authenticates,
and taps "Delete Account" again may still see the cached error.

## Proposed Solutions

### Option A: Invalidate before retry (Recommended)

Add `ref.invalidate(deleteAccountProvider)` in the settings screen before
calling it again, or invalidate it after showing the re-auth dialog.

**Effort:** Small **Risk:** Low

### Option B: Convert to a method-based approach

Use a regular async method instead of a FutureProvider for one-shot operations
like account deletion.

**Effort:** Medium **Risk:** Low

## Technical Details

**Affected files:**

- `lib/features/settings/screens/settings_screen.dart`
- `lib/shared/providers/delete_account_provider.dart`

## Acceptance Criteria

- [ ] User can retry account deletion after re-authentication
- [ ] Cached error does not prevent retry
