# 05. Screenshot Checklist (Visual Proof)

## F1) Client/Freelancer App Screenshots

- [ ] **Avatar Initial Load**
  - _Description_: Wait for avatar image to appear on Home/Profile screen.
  - _Expected Elements_: Rounded container with image. No prolonged loading spinner.
  - _Backend State_: Valid `/avatars/user-id/...` path string in `profiles.avatar_url`.
  - _Authorization_: `avatars` bucket SELECT policy.
  - _Expected TTL_: 2 Hours (7200s).

- [ ] **Chat Attachment Viewer**
  - _Description_: Open a direct message thread containing an image attachment.
  - _Expected Elements_: The image thumbnail inside the message bubble with timestamp.
  - _Backend State_: `messages.attachment_url` matches `convos/<convo_id>/...`.
  - _Authorization_: `can_access_chat_attachment` evaluates to true for the active user.
  - _Expected TTL_: 1 Hour (3600s).

- [ ] **Unauthorized 403 Fallback**
  - _Description_: Hardcode a path from another user's conversation into the widget tree and attempt to render it.
  - _Expected Elements_: Error box showing "Failed to load image". Network tab shows 403 Forbidden on the `createSignedUrl` RPC.
  - _Authorization_: `can_access_chat_attachment` evaluates to false.

- [ ] **Task Details Gallery**
  - _Description_: View a task description with multiple images.
  - _Expected Elements_: Image gallery resolving quickly without jitter (due to `SignedUrlCache`).
  - _Backend State_: Array of paths in `tasks.image_paths`.
  - _Expected TTL_: 2 Hours (7200s).

## F2) Admin Dashboard Screenshots

- [ ] **Dispute Evidence Resolution**
  - _Description_: Logged in as Admin/Moderator reviewing a reported conversation attachment.
  - _Expected Elements_: The attachment image correctly rendered in the web dashboard/admin app despite the Admin not being `user1_id` or `user2_id`.
  - _Backend State_: Admin user session has role = `admin` in `profiles`.
  - _Authorization_: The SQL helper function overrides participant check and grants `SELECT` on `storage.objects` for an admin.
