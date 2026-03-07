---
status: complete
priority: p3
issue_id: "023"
tags: [code-review, quality, testing]
dependencies: []
---

# Mock Classes Redeclared Across 12+ Test Files

## Problem Statement

`MockAuthService` is declared in 5 test files, `MockUser` in 4, and other mocks
are similarly duplicated. This adds ~30+ lines of boilerplate and creates
maintenance burden when interfaces change.

**Why it matters:** When `AuthService` adds a method, 5 mock declarations need
updating. A shared mocks file is standard practice.

## Findings

- **Code Simplicity Reviewer:** Flagged duplicated mock declarations across 12+
  test files.
- **Pattern Recognition Specialist:** Related finding - test container creation
  patterns also vary.

## Proposed Solutions

### Option A: Create test/helpers/mocks.dart (Recommended)

Extract all shared mock classes to a single file.

**Pros:** DRY, single update point. **Effort:** Small **Risk:** Low

## Technical Details

**Affected files:**

- `test/helpers/mocks.dart` - new shared file
- 12+ test files with duplicated mock declarations

## Acceptance Criteria

- [ ] Shared mocks file exists at `test/helpers/mocks.dart`
- [ ] No duplicate mock class declarations across test files
- [ ] All tests still pass

## Work Log

| Date       | Action                        | Learnings                   |
| ---------- | ----------------------------- | --------------------------- |
| 2026-03-07 | Identified during code review | Simplicity + pattern agents |
