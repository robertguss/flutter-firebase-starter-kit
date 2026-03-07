---
status: complete
priority: p3
issue_id: "009"
tags: [code-review, cleanup, documentation]
dependencies: []
---

# Cleanup: widget_test.dart and CLAUDE.md Inaccuracies

## Problem Statement

Two cleanup items remain:

1. **C4 partial:** `widget_test.dart` still exists alongside the renamed test
   files. The old default Flutter test file should be removed or consolidated.
2. **CLAUDE.md inaccuracies:** References `flutter_animate` and `mockito` as
   dependencies, but both have been removed from pubspec.yaml.

## Proposed Solutions

1. Remove `widget_test.dart` if its content is covered by other test files.
2. Update CLAUDE.md to remove references to `flutter_animate` and `mockito`, and
   add `firebase_crashlytics`, `firebase_analytics`, `package_info_plus` to the
   dependencies list.

**Effort:** Small **Risk:** Low

## Acceptance Criteria

- [ ] `widget_test.dart` removed or consolidated
- [ ] CLAUDE.md dependency list matches actual pubspec.yaml
