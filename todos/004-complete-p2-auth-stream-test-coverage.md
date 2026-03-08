---
status: complete
priority: p2
issue_id: "004"
tags: [code-review, testing, riverpod]
dependencies: []
---

# Auth stream-to-provider wiring no longer tested

## Problem Statement

`auth_provider_test.dart` now overrides `authStateProvider` directly instead of
mocking the underlying `FirebaseAuth.authStateChanges()` stream. The
stream-to-provider wiring path is no longer exercised by tests.

## Findings

- **Found by:** Pattern Recognition Specialist
- **File:** `test/features/auth/providers/auth_provider_test.dart`

## Proposed Solutions

### Option A: Add one integration test

Add a single test that mocks `FirebaseAuth.authStateChanges()` and verifies the
stream flows through to `authStateProvider`.

- **Effort:** Small
- **Risk:** None

## Acceptance Criteria

- [x] At least one test verifies the auth stream wiring end-to-end
