# Evidence Map: Storage Signed URLs Flow

## 1. Code Evidence

### 1.1 Avatar Service

- **File**: `lib/features/profile/services/avatar_service.dart`
- **Bucket**: `avatars` (line 13)
- **TTL**: `Duration(hours: 2)` (7200s) (line 56)
- **Path Pattern**: `$userId/${DateTime.now().millisecondsSinceEpoch}.$fileExt` (line 37)

### 1.2 Chat Attachment Uploader

- **File**: `lib/features/chat/attachments/services/upload_service.dart`
- **Logic**: Thin wrapper around `AttachmentService` (lines 5, 13, 21)
- **TTL**: `3600`s (1 hour) (line 20)

### 1.3 Attachment Service

- **File**: `lib/features/chat/services/attachment_service.dart`
- **Bucket**: `chat-attachments` (line 8)
- **TTL**: `3600`s (1 hour) (line 34)
- **Path Pattern**: `$conversationId/${randomId}_$safeName` (line 19)

## 2. Database Evidence

### 2.1 Storage Buckets

- **Source**: `Sline_everything/SUPABASE_SETUP.md` (§11.1)
- **Bucket `avatars`**: Private
- **Bucket `task-images`**: Private
- **Bucket `chat-attachments`**: Private
- **Bucket `portfolio`**: Public

### 2.2 Storage Policies

- **Source**: `Sline_everything/SUPABASE_SETUP.md` (§11.2)
- **`avatars`**: `SELECT bucket_id = 'avatars'` (All authenticated)
- **`task-images`**: `SELECT bucket_id = 'task-images'` (All authenticated)
- **`chat-attachments`**: `SELECT bucket_id = 'chat-attachments'` (All authenticated)
- **Helper Function**: `public.can_access_chat_attachment(p_object_name text, p_uid uuid)`
  - Found in: `supabase/migrations/Archive/20260302_chat_archive_rpc_and_storage_helper.sql`
  - Purpose: Validates conversation participation from path `convos/<convo_id>/...`

## 3. Discrepancies Found

- **TTL**: Current diagram claims `600s`. Actual code uses `3600s` (Chat) and `7200s` (Avatars).
- **Security Scoping**: Current diagram implies bucket-level RLS check. Evidence shows `SELECT` is currently broad (all authenticated) for some buckets, but a specific helper `can_access_chat_attachment` exists but might not be fully applied.
- **portfolio**: Diagram (line 12) says portfolio is public, which is confirmed, but §5.10 of `SUPABASE_SETUP.md` says signed URLs are used for consistency.
