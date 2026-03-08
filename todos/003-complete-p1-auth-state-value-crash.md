---
status: complete
priority: p1
issue_id: "003"
tags: [code-review, architecture, security, riverpod]
dependencies: []
---

# authState.value — false positive (no crash risk)

## Problem Statement

Architecture reviewer flagged `authState.value` in `app.dart` as a crash risk,
recommending revert to `authState.valueOrNull`. However, `valueOrNull` does not
exist in Riverpod 3. In Riverpod 3, `.value` returns the latest value (or null
during loading) without throwing — this is safe and correct.

## Resolution

**False positive.** No code change needed. The original `.value` usage is
correct for Riverpod 3. Verified by compilation — `valueOrNull` causes a build
error.

## Work Log

| Date       | Action                        | Learnings                                                  |
| ---------- | ----------------------------- | ---------------------------------------------------------- |
| 2026-03-08 | Identified during code review | Architecture reviewer incorrectly flagged .value as unsafe |
| 2026-03-08 | Attempted fix, reverted       | valueOrNull does not exist in Riverpod 3 AsyncValue API    |
