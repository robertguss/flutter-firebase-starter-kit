---
status: complete
priority: p1
issue_id: "002"
tags: [code-review, performance, riverpod]
dependencies: []
---

# Onboarding provider missing keepAlive: true

## Problem Statement

The `Onboarding` notifier was migrated from `NotifierProvider` (keepAlive by
default) to `@riverpod` (autoDispose by default). This causes the **onboarding
step index to reset to 0** if the provider is disposed mid-flow, sending users
back to step 1 during the onboarding experience.

## Findings

- **Found by:** Performance Oracle
- **File:** `lib/features/onboarding/providers/onboarding_provider.dart`
- **Evidence:** Original used `NotifierProvider` (keepAlive). Migration used
  `@riverpod` (autoDispose). If the widget tree rebuilds or navigates, the step
  counter resets.

## Proposed Solutions

### Option A: Add keepAlive annotation (Recommended)

Change `@riverpod` to `@Riverpod(keepAlive: true)` and re-run
`make build-runner`.

- **Pros:** One-line fix, restores original semantics
- **Cons:** None
- **Effort:** Small
- **Risk:** None

## Acceptance Criteria

- [x] `@Riverpod(keepAlive: true)` annotation on Onboarding
- [x] Regenerated `.g.dart` file reflects keepAlive
- [x] Tests pass
- [x] Onboarding flow preserves step index across rebuilds

## Work Log

| Date       | Action                        | Learnings                                                   |
| ---------- | ----------------------------- | ----------------------------------------------------------- |
| 2026-03-08 | Identified during code review | NotifierProvider defaults differ between manual and codegen |
