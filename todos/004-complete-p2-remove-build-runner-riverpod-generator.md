---
status: complete
priority: p2
issue_id: "004"
tags: [code-review, cleanup, dependencies]
dependencies: []
---

# build_runner and riverpod_generator Still in pubspec.yaml

## Problem Statement

Cleanup task C3 requires removing `build_runner` and `riverpod_generator` from
`pubspec.yaml` dev_dependencies. Both are still present (lines 45-46) but
neither is used anywhere in the codebase.

## Proposed Solutions

Remove both from `dev_dependencies` in `pubspec.yaml` and run `flutter pub get`.

**Effort:** Small **Risk:** Low

## Technical Details

**Affected files:**

- `pubspec.yaml`

## Acceptance Criteria

- [ ] `build_runner` removed from dev_dependencies
- [ ] `riverpod_generator` removed from dev_dependencies
- [ ] `flutter pub get` succeeds
- [ ] All tests still pass
