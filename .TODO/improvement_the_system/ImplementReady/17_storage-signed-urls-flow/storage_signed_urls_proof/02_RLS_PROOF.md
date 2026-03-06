# 02. RLS Proof

## A) Private Buckets Are Private

- **Evidence**: `storage.buckets` configuration in `SUPABASE_SETUP.md` sets `public = false` for `avatars`, `task-images`, and `chat-attachments`.
- **Verdict**: PASS. The buckets themselves require authentication to read headers or metadata.

## B) Broad SELECT Policy (The Blocker)

- **Claim**: The current `SELECT` policy is overly broad and allows any authenticated user to fetch images from any path in private buckets.
- **Evidence**:
  ```sql
  -- SUPABASE_SETUP.md (line 1251)
  CREATE POLICY "chat_attach_select_auth"
  ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id = 'chat-attachments');
  ```
- **Verdict**: FAIL (Blocker). `chat-attachments` and `task-images` are highly sensitive and currently lack object-scoped `USING` clauses.

## C) Object-Level Checks Missing

- **`chat-attachments`**: Requires participant OR admin authorization.
  - _Current_: Broad SELECT.
  - _Helper_: `can_access_chat_attachment(name, auth.uid())` exists but is not wired into the `storage.objects` policy.
- **`task-images`**: Requires task participant OR admin.
  - _Current_: Broad SELECT (`task_img_select_auth`). No helper function exists.
- **`avatars`**:
  - _Current_: Broad SELECT.
  - _Status_: Acceptable, since avatars are typically public/discoverable profile properties (even if stored in a private bucket to enforce signed URLs). But for strictness, `auth.uid()` could be checked or left open.

## D) Conclusion

The DB policies as they stand in `SUPABASE_SETUP.md` do **NOT** strictly protect sensitive chat and task images from path guessing by authenticated attackers.
