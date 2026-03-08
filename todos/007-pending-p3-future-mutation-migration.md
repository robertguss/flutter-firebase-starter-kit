---
status: pending
priority: p3
issue_id: "007"
tags: [code-review, riverpod, future]
dependencies: []
---

# Consider @mutation for signOut/deleteAccount when available

## Problem Statement

`deleteAccount` and `signOut` are functional FutureProviders used as imperative
actions. When Riverpod's `@mutation` annotation stabilizes, these would benefit
from being class-based mutation methods for better UI loading/error state
tracking.

## Findings

- **Found by:** Pattern Recognition Specialist

## Proposed Solutions

### Option A: Convert when @mutation is stable

Wait for Riverpod `@mutation` to stabilize, then convert these to class-based
notifiers with explicit mutation methods.

- **Effort:** Medium (when the time comes)

## Acceptance Criteria

- [ ] Track Riverpod @mutation stabilization
- [ ] Convert when API is stable
