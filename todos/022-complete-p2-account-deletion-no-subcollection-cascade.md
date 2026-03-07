---
status: complete
priority: p2
issue_id: "022"
tags: [code-review, security, data-integrity]
dependencies: []
---

# Account Deletion Doesn't Cascade Firestore Sub-Collections

## Problem Statement

`deleteAccount` flow deletes the user's Firestore document and Firebase Auth
account, but does not delete any Firestore sub-collections. Firestore does not
cascade-delete sub-collections when a parent document is deleted.

**Why it matters:** Orphaned user data remains in Firestore after account
deletion, creating GDPR/privacy compliance risk and storage cost accumulation.

## Findings

- **Security Sentinel:** Flagged as M3 - account deletion does not
  cascade-delete Firestore sub-collections.

## Proposed Solutions

### Option A: Cloud Function for recursive delete (Recommended)

Use `firebase-tools` recursive delete or a Cloud Function triggered on user
deletion to clean up all sub-collections.

**Pros:** Reliable, handles any depth of nesting. **Cons:** Requires Cloud
Functions deployment. **Effort:** Medium **Risk:** Low

### Option B: Client-side batch delete known sub-collections

Delete known sub-collections before deleting the parent document.

**Pros:** No Cloud Function needed. **Cons:** Fragile - must be updated when new
sub-collections are added. **Effort:** Small **Risk:** Medium

## Technical Details

**Affected files:**

- `lib/shared/providers/delete_account_provider.dart`
- Potentially a new Cloud Function

## Acceptance Criteria

- [ ] All user data is removed from Firestore on account deletion
- [ ] No orphaned sub-collections remain

## Work Log

| Date       | Action                        | Learnings                 |
| ---------- | ----------------------------- | ------------------------- |
| 2026-03-07 | Identified during code review | Security sentinel finding |
