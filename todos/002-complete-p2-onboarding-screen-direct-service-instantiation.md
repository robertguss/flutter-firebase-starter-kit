---
status: complete
priority: p2
issue_id: "002"
tags: [code-review, architecture, pattern-consistency]
dependencies: []
---

# OnboardingScreen Creates UserProfileService Directly

## Problem Statement

`lib/features/onboarding/screens/onboarding_screen.dart` line 59 creates a new
`UserProfileService()` instance directly instead of using
`ref.read(userProfileServiceProvider)`. This bypasses the Riverpod provider
pattern, making the code harder to test and inconsistent with the rest of the
codebase.

## Findings

- **Architecture Strategist:** Identified
  `UserProfileService().markOnboardingComplete(user.uid)` as a direct
  instantiation violation.
- **Code Simplicity Reviewer:** Flagged as pattern inconsistency.

## Proposed Solutions

Replace `UserProfileService()` with `ref.read(userProfileServiceProvider)`.

**Effort:** Small **Risk:** Low

## Technical Details

**Affected files:**

- `lib/features/onboarding/screens/onboarding_screen.dart`

## Acceptance Criteria

- [ ] `onboarding_screen.dart` uses `ref.read(userProfileServiceProvider)`
      instead of `UserProfileService()`
- [ ] All services consumed exclusively via providers in screen/widget code
