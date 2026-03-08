---
status: complete
priority: p3
issue_id: "006"
tags: [code-review, documentation, riverpod]
dependencies: []
---

# Document signOut/deleteAccount providers as ref.read-only

## Problem Statement

`signOutProvider` and `deleteAccountProvider` are autoDispose `FutureProvider`s
used as fire-and-forget actions via `ref.read`. If anyone ever uses `ref.watch`,
the future would re-execute on every rebuild. A doc comment would prevent this.

## Findings

- **Found by:** Architecture Strategist

## Proposed Solutions

### Option A: Add doc comments

Add `/// Use with ref.read only. Do not ref.watch.` above each provider
function.

- **Effort:** Small

## Acceptance Criteria

- [x] Doc comments on signOut and deleteAccount provider functions
