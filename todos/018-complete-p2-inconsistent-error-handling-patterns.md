---
status: complete
priority: p2
issue_id: "018"
tags: [code-review, architecture, quality]
dependencies: []
---

# Inconsistent Error Handling Patterns Across App

## Problem Statement

Error handling varies across screens with no consistent convention:

- `AuthScreen` and `PaywallScreen` use inline `_error` state rendered in widget
  tree
- `SettingsScreen` uses `ScaffoldMessenger.showSnackBar`
- `AuthScreen` swallows exceptions with `catch (_)` - no logging or analytics
- `ProfileScreen` leaks raw error objects to UI

**Why it matters:** For a starter kit, inconsistent patterns confuse developers
who use these as templates. Swallowed exceptions make debugging impossible.

## Findings

- **Pattern Recognition Specialist:** Error display mechanism varies between
  inline state and SnackBar with no documented convention.
- **Agent-Native Reviewer:** Error states are UI-coupled via SnackBar only,
  invisible to automated tests. Should surface through provider state.
- **Security Sentinel:** Profile screen leaks raw error objects. Auth screen
  swallows exceptions silently.

## Proposed Solutions

### Option A: Establish and document a convention (Recommended)

Define: inline error state for multi-step flows (auth, paywall), SnackBar for
one-shot actions (restore purchases, delete account). Always log errors via
`debugPrint` in non-prod or Crashlytics in prod. Never show raw error objects.

**Pros:** Minimal code change, adds clarity for developers. **Cons:** Still two
patterns. **Effort:** Small **Risk:** Low

### Option B: Unified error provider pattern

Create a shared `errorProvider` that surfaces errors through Riverpod state,
observable by both UI and tests.

**Pros:** Testable, consistent, agent-native. **Cons:** More infrastructure for
a starter kit. **Effort:** Medium **Risk:** Low

## Technical Details

**Affected files:**

- `lib/features/auth/screens/auth_screen.dart` - swallows exceptions
- `lib/features/profile/screens/profile_screen.dart` - leaks raw errors
- `lib/features/settings/screens/settings_screen.dart` - SnackBar pattern
- `lib/features/paywall/screens/paywall_screen.dart` - inline error

## Acceptance Criteria

- [ ] No raw error objects shown to users
- [ ] No silently swallowed exceptions (at minimum log in non-prod)
- [ ] Error handling convention is consistent or documented

## Work Log

| Date       | Action                        | Learnings                                          |
| ---------- | ----------------------------- | -------------------------------------------------- |
| 2026-03-07 | Identified during code review | 3 agents independently flagged error inconsistency |
