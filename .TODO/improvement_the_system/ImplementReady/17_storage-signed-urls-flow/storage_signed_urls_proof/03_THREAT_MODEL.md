# 03. Threat Model

## Scenario 1: Path Guessing

_Authenticated attacker tries to fetch someone else’s chat attachment._

- **Outcome (Current)**: Attacker authenticates, guesses (or intercepts) a path like `convos/uuid/file.jpg`, uses `createSignedUrl` on their own client, and Supabase grants it because the policy is only `bucket_id = 'chat-attachments'`.
- **Outcome (Required)**: Request fails with `403 Forbidden` because `can_access_chat_attachment(path, auth.uid())` evaluates to false.
- **Missing Guardrail**: Wiring the helper function into the `storage.objects` SELECT policy.

## Scenario 2: Signed URL Leakage

_A generated signed URL is shared or leaked (e.g., copied to clipboard)._

- **Outcome (Current)**: URL is valid and publicly viewable until expiry (1 to 2 hours).
- **Outcome (Required)**: URL expires quickly (e.g., 3600s), reducing attack window.
- **Missing Guardrail**: Currently implemented correctly via `limit` (3600s). No missing guardrail, but TTL centralization in code is recommended.

## Scenario 3: Admin Dispute Review Blocked

_Support staff needs to view a reported chat conversation's attachments._

- **Outcome (Current)**: If `can_access_chat_attachment` were applied today, Admins would be blocked because the helper strictly checks `user1_id` and `user2_id`.
- **Outcome (Required)**: Admins should bypass the participant check securely.
- **Missing Guardrail**: Helper function must include `OR (SELECT role FROM profiles WHERE id = p_uid) = 'admin'`.

## Scenario 4: Cache Stampede

_A user scrolls through a chat history filled with 20 image attachments._

- **Outcome (Current)**: `AttachmentMessageTile` calls `createSignedUrl` for each tile independently in `initState`. No caching mechanism exists here. 20 RPC calls are fired.
- **Outcome (Required)**: `AttachmentMessageTile` hits local memory cache first (`SignedUrlCache.get()`).
- **Missing Guardrail**: `AttachmentMessageTile.dart` needs to integrate `SignedUrlCache` similar to `SignedAvatar` and `SignedImage`.
