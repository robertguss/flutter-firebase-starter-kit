---
status: complete
priority: p2
issue_id: "013"
tags: [code-review, architecture, bug]
dependencies: []
---

# customerInfoProvider Goes Stale After In-App Purchase

## Problem Statement

`customerInfoProvider` is a plain `FutureProvider` that fetches once. After a
user completes an in-app purchase, `isPremiumProvider` remains stale (showing
"Free") until the app restarts.

**Why it matters:** Users who just paid won't see premium features activate
immediately - a terrible UX that will generate support tickets.

## Findings

- **Architecture Strategist:** Confirmed `customerInfoProvider` fetches once and
  is never invalidated post-purchase.
- **Performance Oracle:** Also flagged that `offeringsProvider` and
  `customerInfoProvider` lack `keepAlive`, causing unnecessary re-fetches on
  widget disposal/reattach cycles.

## Proposed Solutions

### Option A: Invalidate after purchase + add keepAlive (Recommended)

Call `ref.invalidate(customerInfoProvider)` after successful purchase in
`PurchasesService.purchasePackage()`. Add `ref.keepAlive()` to prevent
unnecessary re-fetches during normal navigation.

**Pros:** Minimal change, fixes both staleness and re-fetch issues. **Cons:**
None significant. **Effort:** Small **Risk:** Low

### Option B: Convert to StreamProvider with RevenueCat listener

Use `Purchases.addCustomerInfoUpdateListener` to stream updates.

**Pros:** Real-time updates from all sources (restore, promo codes, etc.).
**Cons:** More complex, needs proper disposal. **Effort:** Medium **Risk:** Low

## Technical Details

**Affected files:**

- `lib/features/paywall/providers/purchases_provider.dart`
- `lib/features/paywall/screens/paywall_screen.dart` (needs to invalidate after
  purchase)

## Acceptance Criteria

- [ ] `isPremiumProvider` updates immediately after successful purchase
- [ ] Provider doesn't re-fetch unnecessarily during normal navigation
- [ ] Restore purchases also updates premium state

## Work Log

| Date       | Action                        | Learnings                                   |
| ---------- | ----------------------------- | ------------------------------------------- |
| 2026-03-07 | Identified during code review | Architecture + performance agents converged |
