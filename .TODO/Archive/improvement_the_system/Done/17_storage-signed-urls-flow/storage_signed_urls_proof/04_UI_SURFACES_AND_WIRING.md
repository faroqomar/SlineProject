# 04. UI Surfaces & Wiring

## E1) App UI Surfaces (Flutter)

### Profile Avatar Surface

- **Widget**: `SignedAvatar`
- **File Path**: `lib/core/widgets/signed_avatar.dart`
- **Service Called**: `AvatarService.createSignedUrl()`
- **DB Query**: Returns `profiles.avatar_url` path string.
- **Signed URL Call**: `bucket: 'avatars', TTL: 7200s (2 hrs)`.
- **Handling**:
  - _Cache Hit_: Returns cached URL immediately from `SignedUrlCache`.
  - _Cache Miss_: Fetches new signed URL, stores it, builds `CachedNetworkImage`.
  - _Forbidden (403)_: Loads fallback `Icons.person` placeholder.
  - _Expired URL_: The network request fails and `errorBuilder` kicks in, showing the placeholder.

### Chat Attachment Viewer

- **Widget**: `AttachmentMessageTile`
- **File Path**: `lib/features/chat/attachments/widgets/attachment_message_tile.dart`
- **Service Called**: `SupabaseAttachmentUploader().createSignedUrl()`
- **DB Query**: Returns `messages.attachment_url` path string.
- **Signed URL Call**: `bucket: 'chat-attachments', TTL: 3600s (1 hr)`.
- **Handling**:
  - _Cache Hit_: **CURRENTLY NOT IMPLEMENTED** (Cache Stampede blocker).
  - _Cache Miss_: Fires RPC `createSignedUrl` in `initState`.
  - _Forbidden (403)_: RLS Denies generation. UI `FutureBuilder` shows `_errorBox('Failed to load image')`.
  - _Expired URL_: Network fetch fails, image shows `_errorBox('Image error')`.

### Task Details Image Gallery

- **Widget**: `SignedImage`
- **File Path**: `lib/core/widgets/signed_image.dart`
- **Service Called**: `TaskImageService().createSignedUrl()`
- **DB Query**: Returns elements from `tasks.image_paths`.
- **Signed URL Call**: `bucket: 'task-images', TTL: 7200s (2 hrs)`.
- **Handling**:
  - _Cache Hit_: Uses `SignedUrlCache`. Memory footprint optimized using `memCacheWidth/memCacheHeight`.
  - _Cache Miss_: Resolves and caches new signed URL.
  - _Forbidden (403)_: Falls back to default placeholder icon.
  - _Expired URL_: Uses `errorWidget` to show default placeholder icon.

## E2) Admin/Auditor UI Surfaces

_SLine requires a reliable auditor path for dispute resolution and moderation. Below is the enforced pattern._

### Report Evidence Viewer

- **Route**: `/admin/disputes/:id` -> `DisputeEvidenceViewer`
- **DB Queried**: `messages.attachment_url` for a reported message.
- **Admin Override Mechanism**: The `can_access_chat_attachment` SQL helper (when updated) must include `OR (SELECT role FROM profiles WHERE id = p_uid) = 'admin'`. This ensures `createSignedUrl` does not fail with 403 when called by a support agent viewing a conversation they're not part of.
- **UI Proof**: Admin views the `AttachmentMessageTile` (or Admin web equivalent) and the image successfully resolves instead of showing the "Failed to load image" error box.
