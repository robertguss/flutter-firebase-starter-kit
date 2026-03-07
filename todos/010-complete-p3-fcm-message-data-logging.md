---
status: complete
priority: p3
issue_id: "010"
tags: [code-review, security]
dependencies: []
---

# FCM message.data Logged in Non-Production Environments

## Problem Statement

`lib/features/notifications/services/fcm_service.dart` line 41 prints
`message.data` in non-prod environments. While guarded behind an environment
check, `message.data` could contain sensitive payload data (user IDs, deep link
tokens) that should not appear in device logs.

## Proposed Solutions

Log only `message.data.keys` instead of full values, or remove the log entirely.

**Effort:** Small **Risk:** Low

## Acceptance Criteria

- [ ] `message.data` values not printed to console in any environment
