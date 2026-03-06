# Risk Register: 08_chat-realtime-sync

## Current Risks (If kept as is)

| Risk                  | Severity | Likelihood | Impact                                            | Evidence                                                                |
| :-------------------- | :------- | :--------- | :------------------------------------------------ | :---------------------------------------------------------------------- |
| **Presence Dead-End** | Low      | High       | Poor UX (User never sees online status)           | `conversation_list_tile.dart:40` TODO                                   |
| **Race Conditions**   | Medium   | Medium     | Duplicate or missing messages on reconnect        | `ChatRealtimeMerger` exists but isn't used everywhere                   |
| **N+1 Performance**   | Medium   | High       | High latency in conversation list during activity | `message_service.dart:351` asyncMap fetch                               |
| **Security Leak**     | High     | Low        | Message exposure if RLS is misconfigured          | `messages` table has RLS enabled but not explicitly verified in diagram |
| **Delivery Drift**    | Low      | Medium     | Sent/Delivered status out of sync                 | RPC calls exist but stream updates are not explicitly handled in UI     |

## Risks Introduced by Improvements

| Risk                  | Impact                                          | Mitigation                                                          |
| :-------------------- | :---------------------------------------------- | :------------------------------------------------------------------ |
| **Presence Storm**    | High write load on `conversation_presence`      | Use a throttle (e.g., max 1 update per 5s) and 15s DB TTL.          |
| **Complexity Growth** | Harder to debug stream merges                   | Modularize merging logic and add verbose logging for stream events. |
| **Migration Drift**   | Existing conversations missing presence records | Presence is ephemeral; no migration needed, just feature rollout.   |

## Vulnerability Assessment

### Attack Scenario: Presence Spoofing

- **Vector**: A malicious user sends `is_typing: true` for a conversation they aren't part of.
- **Current Status**: RLS _should_ block this, but it must be explicitly verified.
- **Improvement**: Ensure RLS policy `conversation_presence_upsert` checks `auth.uid() = user_id` AND user is a participant.
