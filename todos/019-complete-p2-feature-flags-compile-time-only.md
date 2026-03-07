---
status: complete
priority: p2
issue_id: "019"
tags: [code-review, architecture, testability]
dependencies: []
---

# Feature Flags Are Compile-Time Only

## Problem Statement

`AppConfig` feature flags (`enablePaywall`, `enableNotifications`,
`enableAnalytics`, `enableCrashlytics`) are `static const` values. They cannot
be toggled at runtime, overridden in tests, or controlled via Remote Config.

**Why it matters:** Tests can't disable features without recompilation. No path
to A/B testing or gradual rollouts. Contradicts the starter kit's goal of being
production-ready.

## Findings

- **Agent-Native Reviewer:** Flagged as top issue - compile-time flags can't be
  overridden in tests or toggled at runtime.

## Proposed Solutions

### Option A: Move to Riverpod providers backed by AppConfig defaults (Recommended)

Create `featureFlagProvider` family that defaults to `AppConfig` values but can
be overridden in tests via `ProviderContainer.overrides`.

**Pros:** Testable, backward-compatible, minimal change. **Cons:** Slightly more
complex than static const. **Effort:** Small **Risk:** Low

### Option B: Firebase Remote Config integration

Use Remote Config for runtime feature flags.

**Pros:** Full production feature flag system. **Cons:** Over-engineering for a
starter kit, adds Firebase dependency complexity. **Effort:** Large **Risk:**
Medium

## Technical Details

**Affected files:**

- `lib/config/app_config.dart`
- Test files that need to toggle features

## Acceptance Criteria

- [ ] Feature flags can be overridden in tests
- [ ] Default values match current AppConfig constants
- [ ] No breaking changes to existing code

## Work Log

| Date       | Action                        | Learnings                     |
| ---------- | ----------------------------- | ----------------------------- |
| 2026-03-07 | Identified during code review | Agent-native reviewer finding |
