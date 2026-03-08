---
status: complete
priority: p1
issue_id: "001"
tags: [code-review, performance, architecture, riverpod]
dependencies: []
---

# NotificationPreference missing keepAlive: true

## Problem Statement

The `NotificationPreference` notifier was migrated from `NotifierProvider`
(which defaults to keepAlive) to `@riverpod` (which defaults to autoDispose).
This is a **behavioral regression** — the provider's state will be discarded
when the settings screen unmounts, causing unnecessary SharedPreferences reads
on re-mount and potential state loss.

## Findings

- **Found by:** Architecture Strategist, Performance Oracle
- **File:**
  `lib/features/notifications/providers/notification_preference_provider.dart`
- **Evidence:** Original used `NotifierProvider` (keepAlive by default).
  Migration used `@riverpod` (autoDispose by default). The notifier reads from
  SharedPreferences in `build()`, so disposal triggers re-reads.

## Proposed Solutions

### Option A: Add keepAlive annotation (Recommended)

Change `@riverpod` to `@Riverpod(keepAlive: true)` and re-run
`make build-runner`.

- **Pros:** One-line fix, restores original semantics
- **Cons:** None
- **Effort:** Small
- **Risk:** None

## Acceptance Criteria

- [x] `@Riverpod(keepAlive: true)` annotation on NotificationPreference
- [x] Regenerated `.g.dart` file reflects keepAlive
- [x] Tests pass

## Work Log

| Date       | Action                        | Learnings                                                           |
| ---------- | ----------------------------- | ------------------------------------------------------------------- |
| 2026-03-08 | Identified during code review | autoDispose default in codegen differs from manual NotifierProvider |
