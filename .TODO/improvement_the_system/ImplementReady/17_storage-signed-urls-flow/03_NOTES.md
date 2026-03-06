# Research Notes: Storage Signed URLs Flow

## 1. Architectural Observations

- **Stateless/On-Demand**: The system correctly avoids storing temporary URLs in the database, preserving the "single source of truth" (the path).
- **Service Segregation**: Separate services (`AvatarService`, `AttachmentService`) manage different buckets, allowing for bucket-specific logic (e.g., path sanitization in `AttachmentService`).
- **Security Consistency**: Even for the public `portfolio` bucket, the app is moving towards signed URLs to unify the retrieval logic and allow future privacy toggles.

## 2. Identified Gaps

- **Broad SELECT Policies**: `SUPABASE_SETUP.md` suggests that `SELECT` on `avatars` and `chat-attachments` is restricted to `authenticated` users but lacks strict per-object path validation in some cases.
- **TTL Variance**: There is no centralized "Security Policy" for TTL. Avatars last 2 hours, chat attachments 1 hour. A uniform policy (e.g., matching the UI session length or typical viewing time) would be better.
- **Example vs Reality**: the diagram's `600s` TTL is likely a "placeholder" that wasn't updated to match implementation.
- **Admin Access**: There is no mention in the diagram or code of how admins (Auditors/Support) access these private files for dispute resolution. `can_access_chat_attachment` only checks `user1_id`/`user2_id`.

## 3. Risk Observations

- **Path Guessing**: If `SELECT` is allowed for all authenticated users on a bucket, and paths follow a predictable pattern (e.g., `userId/pic.jpg`), a malicious user could iterate IDs and download all avatars without needing a signed URL from the app.
- **Token Leakage**: If a signed URL is leaked, it is valid until expiration. Shorter TTLs mitigate this, but too short TTLs break the UI experience (images disappearing during browsing).
- **No Attachment Metadata Validation**: `AttachmentService` sanitizes filenames but doesn't appear to check file size or MIME types during upload at the DB/Storage level (though it might be done in Flutter).

## 4. Scaling Considerations

- **Storage Overhead**: Every image view requires a round-trip to Supabase for the signed URL. For a list of 50 profiles, that's 50 RPC calls.
- **Optimization**: The app could benefit from `SignedAvatar` caching the signed URL locally until it's close to expiration.
