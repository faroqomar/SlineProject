# Verdict: Storage Signed URLs Verify

## 1. Score & Conclusion

- **OLD System Score (Baseline):** 6/10
- **NEW System Score (Proposed in Improvement Plan):** 9.5/10
- **Is NEW truly safer?** YES.

## 2. Production Blockers Found in OLD

Yes, there are **three critical production blockers** in the existing system:

1. **Broad RLS Access to Private Buckets (High Severity)**:
   - _Evidence_: `SUPABASE_SETUP.md` line 1251 shows `chat_attach_select_auth` allows ANY authenticated user to SELECT from the `chat-attachments` bucket: `bucket_id = 'chat-attachments'`.
   - _Result_: Path guessing allows data leaks of private conversation attachments.
2. **Missing Admin Dispute Path (High Severity)**:
   - _Evidence_: There is no mechanism in `can_access_chat_attachment` or `SUPABASE_SETUP.md` for Admins to override the participant-check and view reported chat attachments. Support is currently blind during disputes.
3. **Cache Stampede in Chat (Medium Severity)**:
   - _Evidence_: `lib/features/chat/attachments/widgets/attachment_message_tile.dart` (line 34) calls `createSignedUrl` directly in `initState` without utilizing `SignedUrlCache`. Scrolling a chat history with 20 images will slam the Supabase RPC endpoint.

## 3. Why the NEW Design is Required

The NEW design (`.TODO/improvement_the_system/17_storage-signed-urls-flow/`) correctly identified these exact gaps. It mandates object-level RLS (`can_access_chat_attachment(path, auth.uid()) OR is_admin()`), centralizes TTL, and specifies caching across all UI surfaces. These fixes are the bare minimum needed before production.
