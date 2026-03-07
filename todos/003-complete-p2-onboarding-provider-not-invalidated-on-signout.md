---
status: complete
priority: p2
issue_id: "003"
tags: [code-review, architecture, state-management]
dependencies: []
---

# onboardingProvider Not Invalidated on Sign-Out

## Problem Statement

`lib/shared/providers/sign_out_provider.dart` invalidates
`customerInfoProvider`, `offeringsProvider`, `userProfileProvider`, and
`postAuthBootstrapProvider` on sign-out, but does NOT invalidate
`onboardingProvider`. The plan explicitly lists it as one of the providers to
reset.

**Why it matters:** Onboarding page index state could leak between user sessions
if a different user signs in on the same device.

## Proposed Solutions

Add `ref.invalidate(onboardingProvider)` to the sign-out sequence.

**Effort:** Small **Risk:** Low

## Technical Details

**Affected files:**

- `lib/shared/providers/sign_out_provider.dart`

## Acceptance Criteria

- [ ] `onboardingProvider` invalidated during sign-out
- [ ] New sign-in starts with fresh onboarding state
