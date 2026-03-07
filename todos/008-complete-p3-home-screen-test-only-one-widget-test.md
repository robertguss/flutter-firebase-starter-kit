---
status: complete
priority: p3
issue_id: "008"
tags: [code-review, testing]
dependencies: []
---

# home_screen_test.dart Has Only 1 Widget Test

## Problem Statement

The plan requires at least 2 widget tests per screen.
`test/features/home/screens/home_screen_test.dart` has only 1 testWidgets
(navigation destinations).

## Proposed Solutions

Add a second widget test, e.g., testing that tapping a navigation destination
updates the selected index, or testing the scaffold structure.

**Effort:** Small **Risk:** Low

## Acceptance Criteria

- [ ] `home_screen_test.dart` has at least 2 widget tests
