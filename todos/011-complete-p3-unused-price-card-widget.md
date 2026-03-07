---
status: complete
priority: p3
issue_id: "011"
tags: [code-review, cleanup, dead-code]
dependencies: []
---

# Unused price_card.dart Widget

## Problem Statement

`lib/features/paywall/widgets/price_card.dart` is never imported or used
anywhere in the codebase. Unlike the shared widgets (empty_state, error_screen,
etc.) which are starter kit building blocks, this widget appears to be genuinely
unused dead code.

## Proposed Solutions

Remove the file, or if it's intended as a starter kit example, document it with
a comment and add a usage example.

**Effort:** Small **Risk:** Low

## Acceptance Criteria

- [ ] `price_card.dart` either removed or documented as an example widget
