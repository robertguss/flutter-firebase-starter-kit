---
status: complete
priority: p2
issue_id: "021"
tags: [code-review, security, data-integrity]
dependencies: []
---

# createdAt Overwritten on Every Sign-In

## Problem Statement

`postAuthBootstrapProvider` sets `createdAt` on every sign-in, not just first
sign-in. This may conflict with Firestore rules that block mutation of the
`createdAt` field, or silently overwrite the original creation timestamp.

**Why it matters:** Loss of original account creation date breaks analytics,
billing calculations, and audit trails.

## Findings

- **Security Sentinel:** Flagged as M2 - `createdAt` overwritten on every
  sign-in via `postAuthBootstrapProvider`, conflicting with Firestore rules that
  block mutation.

## Proposed Solutions

### Option A: Use set with merge and only set createdAt on create (Recommended)

Check if the profile already exists before setting `createdAt`, or use Firestore
`FieldValue.serverTimestamp()` only in a create-if-not-exists pattern.

**Pros:** Preserves original timestamp, respects Firestore rules. **Cons:**
None. **Effort:** Small **Risk:** Low

## Technical Details

**Affected files:**

- `lib/shared/providers/post_auth_bootstrap_provider.dart`
- `lib/features/auth/services/user_profile_service.dart`

## Acceptance Criteria

- [ ] `createdAt` is set only on first profile creation
- [ ] Returning users retain their original `createdAt`
- [ ] No Firestore rules violations on sign-in

## Work Log

| Date       | Action                        | Learnings                 |
| ---------- | ----------------------------- | ------------------------- |
| 2026-03-07 | Identified during code review | Security sentinel finding |
