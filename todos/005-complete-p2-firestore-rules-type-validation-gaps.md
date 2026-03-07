---
status: complete
priority: p2
issue_id: "005"
tags: [code-review, security, firestore]
dependencies: []
---

# Firestore Rules Missing Type Validation for photoUrl, createdAt, and email on Update

## Problem Statement

The `firestore.rules` file has three validation gaps:

1. **`photoUrl`** has no type validation. A malicious client could write
   `photoUrl: 123` or `photoUrl: true`.
2. **`createdAt`** has no type check on create. A user could set it to a string
   or number instead of a timestamp.
3. **`email`** is validated against `request.auth.token.email` on create, but
   NOT on update. A user could change their email field to any arbitrary string
   value after creation.

## Findings

- **Security Sentinel:** Identified all three gaps independently.

## Proposed Solutions

Add to `validFields()`:

- `&& (request.resource.data.get('photoUrl', '') is string)`
- `&& (request.resource.data.get('createdAt', request.time) is timestamp)`

Add to `allow update` rule:

- `&& request.resource.data.email == request.auth.token.email`

**Effort:** Small **Risk:** Low

## Technical Details

**Affected files:**

- `firestore.rules`

## Acceptance Criteria

- [ ] `photoUrl` type validated as string
- [ ] `createdAt` type validated as timestamp
- [ ] `email` validated against auth token on both create and update
