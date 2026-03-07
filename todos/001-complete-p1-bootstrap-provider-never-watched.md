---
status: complete
priority: p1
issue_id: "001"
tags: [code-review, architecture, bug]
dependencies: []
---

# postAuthBootstrapProvider Never Watched - Bootstrap Logic Never Executes

## Problem Statement

`postAuthBootstrapProvider` in
`lib/shared/providers/post_auth_bootstrap_provider.dart` orchestrates critical
post-sign-in side effects (profile creation, RevenueCat login, FCM token save),
but it is never watched or read by any widget. This means the bootstrap logic
**never actually executes** after sign-in.

The plan specifies: "Watched by the App widget to show loading state during
bootstrap."

**Why it matters:** First-time users will have no Firestore profile created,
RevenueCat won't be logged in (breaking premium state), and FCM tokens won't be
saved (breaking push notifications).

## Findings

- **Architecture Strategist:** Confirmed `App` widget in `lib/app.dart` does NOT
  watch `postAuthBootstrapProvider`. Only watches `routerProvider` and
  `themeModeProvider`.
- **Code Simplicity Reviewer:** Independently confirmed the provider is never
  watched or read by any widget, calling it "a likely bug."
- Two agents converged on the same finding.

## Proposed Solutions

### Option A: Watch in App widget (Recommended)

Add `ref.watch(postAuthBootstrapProvider)` in the `App` widget and show a
loading screen while it's in `AsyncLoading` state.

**Pros:** Matches the plan exactly, provides loading UX during bootstrap.
**Cons:** Adds complexity to App widget. **Effort:** Small **Risk:** Low

### Option B: Watch in router redirect

Read the bootstrap provider state in the router redirect and redirect to a
loading route while pending.

**Pros:** Keeps App widget simple. **Cons:** More complex redirect logic.
**Effort:** Medium **Risk:** Medium

## Recommended Action

Option A - Watch in App widget.

## Technical Details

**Affected files:**

- `lib/app.dart` - needs to watch `postAuthBootstrapProvider`
- Potentially a new loading/splash screen widget

## Acceptance Criteria

- [ ] `postAuthBootstrapProvider` is watched by a widget after sign-in
- [ ] Profile creation, RevenueCat login, and FCM token save execute on first
      sign-in
- [ ] Loading state shown while bootstrap runs
- [ ] Returning users proceed to home without visible delay

## Work Log

| Date       | Action                        | Learnings                                                    |
| ---------- | ----------------------------- | ------------------------------------------------------------ |
| 2026-03-07 | Identified during code review | Two independent agents caught this - high confidence finding |

## Resources

- Plan:
  `docs/plans/2026-03-07-refactor-starter-kit-production-readiness-plan.md`
  (Step 1.3)
- File: `lib/shared/providers/post_auth_bootstrap_provider.dart`
- File: `lib/app.dart`
