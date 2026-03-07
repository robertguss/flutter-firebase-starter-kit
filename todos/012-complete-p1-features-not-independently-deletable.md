---
status: complete
priority: p1
issue_id: "012"
tags: [code-review, architecture]
dependencies: []
---

# Features Not Independently Deletable - Cross-Feature Imports Break Modularity

## Problem Statement

The starter kit's core promise is that features under `lib/features/` are
independently deletable. However, multiple cross-feature imports make this
impossible - deleting any single feature causes compile failures across the
codebase.

**Why it matters:** This is the fundamental architectural guarantee of the
starter kit. Developers expect to delete features they don't need (e.g.,
paywall, notifications) without breaking anything.

## Findings

- **Architecture Strategist:** `settings_screen.dart` directly imports from
  `paywall/providers/` and `paywall/services/`.
  `shared/widgets/premium_gate.dart` imports from `paywall/providers/`.
  `shared/providers/sign_out_provider.dart` and
  `post_auth_bootstrap_provider.dart` hard-import from auth, notifications, and
  paywall features.
- **Code Simplicity Reviewer:** Confirmed `premium_gate.dart` in shared layer
  depends on paywall feature (boundary inversion).

## Proposed Solutions

### Option A: Guard imports behind feature flags (Recommended)

Wrap cross-feature imports with conditional logic. Use optional provider
overrides so features can be removed by simply not providing overrides. For
shared providers that orchestrate multiple features, use a registry or optional
callback pattern.

**Pros:** Preserves current code structure, minimal refactor. **Cons:** Adds
conditional complexity. **Effort:** Medium **Risk:** Low

### Option B: Move shared dependencies to shared layer

Extract the interfaces/types that cross boundaries into `lib/shared/` so
features only depend on shared abstractions, never on each other.

**Pros:** Clean dependency graph. **Cons:** More files, more abstractions.
**Effort:** Large **Risk:** Medium

## Recommended Action

Option A for quick wins, evolve toward Option B for features with heavy
coupling.

## Technical Details

**Affected files:**

- `lib/features/settings/screens/settings_screen.dart` - imports paywall
- `lib/shared/widgets/premium_gate.dart` - imports paywall providers
- `lib/shared/providers/sign_out_provider.dart` - imports auth, notifications,
  paywall
- `lib/shared/providers/post_auth_bootstrap_provider.dart` - imports auth,
  notifications, paywall

## Acceptance Criteria

- [ ] Deleting `lib/features/paywall/` does not cause compile errors (with flag
      disabled)
- [ ] Deleting `lib/features/notifications/` does not cause compile errors (with
      flag disabled)
- [ ] Cross-feature imports are eliminated or guarded
- [ ] `premium_gate.dart` does not directly import from paywall feature

## Work Log

| Date       | Action                        | Learnings                                          |
| ---------- | ----------------------------- | -------------------------------------------------- |
| 2026-03-07 | Identified during code review | Architecture + simplicity agents both flagged this |

## Resources

- File: `lib/features/settings/screens/settings_screen.dart`
- File: `lib/shared/widgets/premium_gate.dart`
- File: `lib/shared/providers/sign_out_provider.dart`
- File: `lib/shared/providers/post_auth_bootstrap_provider.dart`
