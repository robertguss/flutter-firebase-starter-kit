---
status: complete
priority: p2
issue_id: "015"
tags: [code-review, security, ux]
dependencies: []
---

# Sign-In Buttons Lack Double-Tap Protection

## Problem Statement

Auth screen sign-in buttons (`Continue with Google`, `Continue with Apple`) have
no loading/disabled state. Users can tap multiple times, triggering concurrent
sign-in flows that may cause race conditions or duplicate accounts.

**Why it matters:** Duplicate sign-in requests can cause confusing errors,
especially on slow networks. This is also a common mobile UX anti-pattern.

## Findings

- **Security Sentinel:** Flagged as L3 - no loading/disabled state on sign-in
  buttons to prevent double-tap.
- **Code Simplicity Reviewer:** Related finding - the duplicated sign-in methods
  make it harder to add consistent loading state.

## Proposed Solutions

### Option A: Add isLoading state and disable buttons (Recommended)

Add `_isLoading` state to `AuthScreen`, disable buttons and show spinner during
sign-in. Since sign-in methods are already in a `ConsumerStatefulWidget`, just
add a `bool` field.

**Pros:** Simple, standard mobile pattern. **Cons:** None. **Effort:** Small
**Risk:** Low

## Technical Details

**Affected files:**

- `lib/features/auth/screens/auth_screen.dart`

## Acceptance Criteria

- [ ] Buttons show loading indicator during sign-in
- [ ] Buttons are disabled while sign-in is in progress
- [ ] Loading state resets on error

## Work Log

| Date       | Action                        | Learnings                       |
| ---------- | ----------------------------- | ------------------------------- |
| 2026-03-07 | Identified during code review | Security + simplicity converged |
