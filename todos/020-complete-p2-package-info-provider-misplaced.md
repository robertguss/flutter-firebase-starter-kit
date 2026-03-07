---
status: complete
priority: p2
issue_id: "020"
tags: [code-review, quality, performance]
dependencies: []
---

# packageInfoProvider Misplaced and Auto-Disposed

## Problem Statement

`packageInfoProvider` is defined inline in `settings_screen.dart` instead of in
a `providers/` directory, breaking the project's own convention. It's also an
auto-disposed `FutureProvider` that re-fetches `PackageInfo` on every Settings
screen visit, despite the value being immutable at runtime.

**Why it matters:** Inconsistent provider placement confuses developers using
this as a template. Unnecessary re-fetches waste time on every screen visit.

## Findings

- **Pattern Recognition Specialist:** Flagged as #1 inconsistency - only
  provider defined inside a screen file.
- **Code Simplicity Reviewer:** Same finding - breaks the project's own
  convention.
- **Performance Oracle:** Auto-dispose causes unnecessary re-fetches.

## Proposed Solutions

### Option A: Move to providers/ and add keepAlive (Recommended)

Move to `lib/features/settings/providers/package_info_provider.dart` and add
`ref.keepAlive()` since package info never changes at runtime.

**Pros:** Follows convention, caches value. **Cons:** None. **Effort:** Small
**Risk:** Low

## Technical Details

**Affected files:**

- `lib/features/settings/screens/settings_screen.dart` - remove inline provider
- `lib/features/settings/providers/package_info_provider.dart` - new file

## Acceptance Criteria

- [ ] Provider lives in `providers/` directory
- [ ] PackageInfo is fetched once and cached
- [ ] Settings screen still displays version correctly

## Work Log

| Date       | Action                        | Learnings                           |
| ---------- | ----------------------------- | ----------------------------------- |
| 2026-03-07 | Identified during code review | 3 agents flagged this independently |
