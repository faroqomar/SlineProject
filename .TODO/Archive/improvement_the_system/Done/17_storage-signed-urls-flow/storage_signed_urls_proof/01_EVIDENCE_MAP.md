# 01. Evidence Map

## A) Core Contract (Store Path, Sign URL)

- **DB Stores Path Only**:
  - _Evidence_: `SUPABASE_SETUP.md` - `profiles` table has `avatar_url` (but code expects a short path, e.g., `$userId/$timestamp.jpg`).
  - _Evidence_: `TaskImageService.uploadBytes` (line 67) returns `path; // return storage path only`.
- **On-Demand Signing**:
  - _Evidence_: `SignedAvatar._resolve` (line 131) calls `createSignedUrl`.
  - _Evidence_: `SignedImage._resolve` (line 99) calls `createSignedUrl`.

## B) TTL Consistency & Values

- **Avatar TTL**: 7200s (2 hours).
  - _Evidence_: `SignedImage._resolve` (line 101), `AvatarService.createSignedUrl` (default `const Duration(hours: 2)`).
- **Task Image TTL**: 7200s (2 hours).
  - _Evidence_: `TaskImageService.createSignedUrl` (line 108).
- **Chat Attachment TTL**: 3600s (1 hour).
  - _Evidence_: `AttachmentMessageTile.initState` (line 38) calls with `expiresInSeconds: 3600`.

## C) Current Storage Policies (The Baseline)

- **`avatars`**:
  - `SUPABASE_SETUP.md`: `avatars_select_authenticated` USING `bucket_id = 'avatars'`. (Broad)
- **`task-images`**:
  - `SUPABASE_SETUP.md`: `task_img_select_auth` USING `bucket_id = 'task-images'`. (Broad)
- **`chat-attachments`**:
  - `SUPABASE_SETUP.md`: `chat_attach_select_auth` USING `bucket_id = 'chat-attachments'`. (Broad)
- **`portfolio`**:
  - Public.

## D) Helper Functions Present

- **`can_access_chat_attachment(p_object_name, p_uid)`**:
  - _Evidence_: Found in `supabase/migrations/Archive/20260302_chat_archive_rpc_and_storage_helper.sql` (line 54). It validates the participant from the path `convos/<conversation_id>/...`. However, the migration file notes explicitly in line 97: `New RLS policies that USE this helper ... should be added in a follow-up migration`. Thus, the helper exists but is **not active** in protecting the bucket yet.
