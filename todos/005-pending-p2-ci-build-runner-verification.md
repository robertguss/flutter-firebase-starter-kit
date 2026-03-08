---
status: pending
priority: p2
issue_id: "005"
tags: [code-review, ci, dx, riverpod]
dependencies: []
---

# Add CI step to verify generated code is up-to-date

## Problem Statement

With codegen providers, `.g.dart` files can become stale if a developer modifies
a provider but forgets to run `make build-runner`. CI should catch this.

## Findings

- **Found by:** Pattern Recognition Specialist

## Proposed Solutions

### Option A: CI diff check

Add a CI step that runs
`dart run build_runner build --delete-conflicting-outputs` then checks
`git diff --exit-code` on `.g.dart` files.

- **Effort:** Small
- **Risk:** None

## Acceptance Criteria

- [ ] CI fails if `.g.dart` files are out of sync with source
