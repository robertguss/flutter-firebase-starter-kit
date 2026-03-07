---
status: complete
priority: p2
issue_id: "014"
tags: [code-review, performance]
dependencies: []
---

# App Root Widget Rebuilds Too Broadly

## Problem Statement

`App` widget in `lib/app.dart` watches 4 providers (auth state, bootstrap,
theme, router), causing the entire `MaterialApp.router` to rebuild on every auth
transition.

**Why it matters:** Full MaterialApp rebuilds are expensive - they re-evaluate
theme, recreate the router delegate, and force all descendant widgets to
rebuild.

## Findings

- **Performance Oracle:** Confirmed App watches `authStateProvider`,
  `postAuthBootstrapProvider`, `themeModeProvider`, and `routerProvider`. Auth
  state changes trigger full MaterialApp rebuilds.

## Proposed Solutions

### Option A: Split into focused consumer widgets (Recommended)

Extract theme-watching and bootstrap-watching into separate `Consumer` widgets
lower in the tree. Only `routerProvider` and `themeModeProvider` need to be at
the MaterialApp level.

**Pros:** Targeted rebuilds, better performance. **Cons:** Slightly more widget
nesting. **Effort:** Small **Risk:** Low

## Technical Details

**Affected files:**

- `lib/app.dart`

## Acceptance Criteria

- [ ] Auth state changes don't rebuild MaterialApp
- [ ] Theme changes still apply correctly
- [ ] Bootstrap loading state still shows

## Work Log

| Date       | Action                        | Learnings                  |
| ---------- | ----------------------------- | -------------------------- |
| 2026-03-07 | Identified during code review | Performance oracle finding |
