# Gaps and Fixes: Storage Signed URLs Flow

## 1. Security Gaps

### G1: Permissive SELECT Policies on Private Buckets

- **Gap**: Current policies for `avatars` and `task-images` allow `SELECT` for _any_ authenticated user. While URLs are signed, the underlying objects are reachable by any logged-in user if they can guess the path.
- **Evidence**: `SUPABASE_SETUP.md` (§11.2) - `avatars_select_authenticated` rule is simply `bucket_id = 'avatars'`.
- **Fix**: Apply participant-based or owner-based scoping to the `SELECT` command on `storage.objects`.
  - For `avatars`: `SELECT` allowed for all (avatars are usually public/discoverable).
  - For `task-images`: Only allowed if user is the `client_id` or `freelancer_id` of the task.
  - For `chat-attachments`: Use the existing `can_access_chat_attachment` helper in the RLS policy.

### G2: TTL Inconsistency

- **Gap**: Signed URLs for profile pictures last 2 hours, but chat attachments last only 1 hour. This creates an inconsistent user experience.
- **Fix**: Centralize the TTL policy in `SharedStorageConfig`. Recommend `3600` (1 hour) as the standard for sensitive data (Chat/Bids) and `7200` (2 hours) for discoverable data (Avatars).

### G3: Lack of Admin/Auditor Path

- **Gap**: Support staff cannot view private chat images during a dispute because the `SELECT` policy and `can_access_chat_attachment` helper only check for participants.
- **Fix**: Update `can_access_chat_attachment` and storage policies to allow users with an `admin` role (verified via `profiles.roles`).

## 2. Technical Gaps

### T1: No Upload Size/Type Enforcement

- **Gap**: `AttachmentService.uploadBytes` takes raw bytes without verifying if they match a valid image or exceed a size limit.
- **Fix**: Add `CHECK` constraints or Storage Bucket limits for size. Implement server-side MIME type validation if possible, or enforce it in the Flutter Service layer via a `Config` check.

### T2: Missing Caching Strategy for Signed URLs

- **Gap**: Every widget rebuild might trigger a new signed URL request if not properly handled in the ViewModel/State.
- **Fix**: Implement a `TimedCache` in the Flutter client for signed URLs, storing them as `(path, url, expiry)`. Only re-request if `now() > expiry - 5 minutes`.

## 3. Redesign Requirements

- The improved diagram must show the **Admin/Auditor path**.
- The improved diagram must show the **RLS Policy execution** at the object level, not just bucket level.
- The improved diagram must include the **Caching layer** on the App side.
