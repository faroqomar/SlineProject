# Manual E2E: Inbox Realtime (Messages-Driven)

**Plan:** PLAN_RealtimeSubscriptionTopology_2026-03-07  
**Purpose:** Verify Inbox updates when the current user receives a message without full refetch; confirm no N+1.

## Prerequisites

- Two test accounts (User A, User B) or two devices/emulators.
- App built from branch with realtime topology changes (subscribeToInboxMessages, no conversations stream).

## Steps

1. **Login User A**  
   Open app, sign in as User A. Navigate to Inbox (Messages / conversation list screen).

2. **Login User B**  
   On second device or after switching account, sign in as User B.

3. **B sends message to A**  
   User B opens a conversation with User A (or starts one) and sends a text message.

4. **A on Inbox (no refresh)**  
   With User A remaining on the Inbox screen (conversation list), verify:
   - **Expected:** The conversation with B moves to the top of the list.
   - **Expected:** The preview text (last message) updates to the new message.
   - **Expected:** No full-page loading spinner; update is instantaneous (realtime).
   - **Fail:** If A must pull-to-refresh or reopen the screen to see the new message.

5. **New conversation (first message)**  
   Optional: User B starts a brand-new conversation with User A (first message).  
   - **Expected:** User A’s Inbox shows the new conversation (after at most one background fetch).
   - **Expected:** No duplicate entries; no spinner storm.

6. **Check logs (no N+1)**  
   In debug run, inspect AppLogger / console:
   - **Pass:** No log lines containing `SELECT` and `conversations` and `IN` (or equivalent bulk select for all conversation IDs).
   - **Pass:** You see `[REALTIME] inbox messages` and `[REALTIME] Inbox merged` when a message arrives.
   - **Fail:** Repeated bulk conversation fetches on every message (N+1).

## Verification Checklist

- [ ] Inbox updates without full refetch when new message arrives.
- [ ] Conversation moves to top; preview updates.
- [ ] No N+1: logs do not show bulk `conversations ... IN (...)` per message.
- [ ] New conversation appears in Inbox (single fetch, no duplicate).
- [ ] Chat screen (active conversation) still receives messages in realtime (regression check).
- [ ] Notifications stream unchanged (regression check).

## Sign-off

- **Date:** _____________
- **Tester:** _____________
- **Result:** Pass / Fail
- **Notes:** _____________
