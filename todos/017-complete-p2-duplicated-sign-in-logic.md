---
status: complete
priority: p2
issue_id: "017"
tags: [code-review, quality, simplicity]
dependencies: ["015"]
---

# Duplicated Sign-In Logic in auth_screen.dart

## Problem Statement

`_signInWithGoogle()` and `_signInWithApple()` in `auth_screen.dart` are ~40
lines of near-identical code (set loading, try/catch, call service, handle
error, reset loading). This violates DRY and makes it harder to maintain
consistent behavior.

**Why it matters:** When adding loading state (todo 015) or error handling
improvements, changes must be made in two identical places.

## Findings

- **Code Simplicity Reviewer:** Flagged as HIGH priority - extract a shared
  helper to cut ~20 LOC.

## Proposed Solutions

### Option A: Extract shared \_signIn helper (Recommended)

```dart
Future<void> _signIn(Future<UserCredential> Function() method) async {
  setState(() => _isLoading = true);
  try {
    await method();
  } catch (e) {
    // unified error handling
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}
```

**Pros:** DRY, single place to add loading/error logic. **Cons:** None.
**Effort:** Small **Risk:** Low

## Technical Details

**Affected files:**

- `lib/features/auth/screens/auth_screen.dart`

## Acceptance Criteria

- [ ] Single sign-in helper method handles both providers
- [ ] Error handling is consistent for both sign-in methods
- [ ] Loading state managed in one place

## Work Log

| Date       | Action                        | Learnings                   |
| ---------- | ----------------------------- | --------------------------- |
| 2026-03-07 | Identified during code review | Simplicity reviewer finding |
