---
status: complete
priority: p2
issue_id: "016"
tags: [code-review, auth, ux]
dependencies: []
---

# GoogleSignIn().signOut() Not Called During Sign-Out

## Problem Statement

`AuthService.signOut()` only calls `firebaseAuth.signOut()` but doesn't call
`GoogleSignIn().signOut()`. This means Google's cached account selection
persists, so the next sign-in skips the account picker and auto-selects the
previous account.

**Why it matters:** Users on shared devices can't switch Google accounts. Users
who want to sign in with a different account are stuck.

## Findings

- **Security Sentinel:** Flagged as L4 - Google account picker is skipped on
  next login because cached credentials aren't cleared.

## Proposed Solutions

### Option A: Add GoogleSignIn().signOut() to signOut method (Recommended)

```dart
Future<void> signOut() async {
  await GoogleSignIn().signOut();
  await firebaseAuth.signOut();
}
```

**Pros:** One line fix, standard practice. **Cons:** None. **Effort:** Small
**Risk:** Low

## Technical Details

**Affected files:**

- `lib/features/auth/services/auth_service.dart`

## Acceptance Criteria

- [ ] Google account picker appears on subsequent sign-in after sign-out
- [ ] Sign-out still works correctly for Apple sign-in users

## Work Log

| Date       | Action                        | Learnings                 |
| ---------- | ----------------------------- | ------------------------- |
| 2026-03-07 | Identified during code review | Security sentinel finding |
