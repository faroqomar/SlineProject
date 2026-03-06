# FULL REPORT: 17 Storage Signed URLs Flow

## 0) Skill Selection

- **Skills selected**: Evidence-First Reading, Threat Modeling (Security), RLS & Privilege Boundaries, Diagram Crafting, State Machine & Lifecycle.
- **Why these fit**: Exposing SLine's private buckets (avatars, attachments, portfolios) via signed URLs is a massive privacy risk if RLS drops the ball. Tracking the TTL lifecycle, local caching, and Admin overrides ensures production stability.
- **Skills not used**: Repo Mapping.

## 1) Folder Identity

- **Folder name + path**: `.TODO/improvement_the_system/ImplementReady/17_storage-signed-urls-flow`
- **What system/feature it describes**: How the app converts a protected database string (e.g. `convos/456/attachment.png`) into a temporary `https://` link authenticated by Supabase specifically for the requesting user.
- **Entities involved**: `AvatarService`, `AttachmentService`, `storage.objects`, DB tables containing `_url` columns.

## 2) Human Explanation

If the DB stored raw URLs, they would expire and break images. Instead, the DB stores just the bucket path. When the Flutter app renders an image, it asks Supabase Storage to `createSignedUrl` for that path. Supabase evaluates RLS. If the user is authorized (e.g. they are a participant in the chat, or it's a public avatar), it returns a tokenized URL valid for ~10 to 60 minutes. The app locally caches this URL so it doesn't hammer the API on every scroll.

## 3) Symbol Legend

- **Rectangles**: Processing actors (App Cache vs Storage Service).
- **Solid Arrows**: Caching checks and RLS evaluations.
- **Dashed Arrows**: Fallbacks to Postgres DB for path fetching.

## 4) Extracted Contracts & Invariants

1. **Separation of Concerns**: The database MUST NOT store signed URLs. Only Paths.
2. **Short-Lived Access**: All private URLs MUST have a strict TTL (Time To Live).
3. **Path Authority**: Paths must uniquely identify the context (e.g. `convos/ID/file.png`).
4. **Authenticity**: Signed URL generation MUST require an authenticated session for private buckets.

## 5) Conflict Scan Results

### 5.1 Naming Drift

- **Conflict**: TTL values varied widely (600s vs 3600s).
- **Resolution**: Use `SharedStorageConfig` in Dart to standardize exactly.

### 5.2 Logic Drift

- **Conflict**: App re-requested URLs on every list scroll.
- **Resolution**: A local `TimedCache` must map `Path -> SignedUrl` in Memory until `now() > TTL`.

### 5.3 Data Model Drift

- **Conflict**: Broad `SELECT` open for all authenticated users could allow path-guessing.
- **Resolution**: RLS policy `can_access_chat_attachment(path, auth.uid())` must be applied to `chat-attachments` bucket.

## 6) Security & Failure Modes (Adversarial)

- **Path Guessing**: User iterates `convos/` paths trying to generate signed links for other people's chats.
  - _Mitigation_: Supabase evaluates the RLS `SELECT` policy _during_ `createSignedUrl`. If `auth.uid()` isn't in that specific conversation, the generation fails with 403 Forbidden.
- **Admin Audit Lockout**: Support admins investigating disputes couldn't see attachments because they aren't "participants".
  - _Mitigation_: Expand RLS `SELECT` on storage objects to `auth.uid() = participant OR is_admin(auth.uid())`.

## 7) UI Mapping

### 7.1 Mobile App UI

- **Screens**: Everywhere images load (`SignedAvatar`, `AttachmentViewer`, Task Imagery).
- **States**: Rendering a placeholder/spinner while `createSignedUrl` executes.
- **Guardrails**: If 403 Forbidden, render a "Content Unavailable" broken image icon rather than crashing.

### 7.2 Admin Dashboard UI

- **Pages**: Dispute Arbitration, Profile Moderation.
- **Metrics**: Bandwidth usage spikes.

### 7.3 Implementation Hooks

- `AvatarService.createSignedUrl(path)`.
- `AttachmentService.createSignedUrl(path)`.

## 8) Diagram Verdict + Best Diagram Type

- **Score now**: 9.5/10 (Post-fixes)
- **Best Diagram Type**: Sequence Diagram capturing Cache hit vs miss, combined with RLS auth gating.

## 9) Upgrade Plan

- **Phase 0: Observability**: Log all 403s on Storage Generation.
- **Phase 1: Contracts**: Enforce the standardized TTL mapping.
- **Phase 2: Hardening**: Apply `can_access_chat_attachment` strictly in Postgres.
- **Phase 3: Scale**: Implement `TimedCache` Dart singleton to radically drop Storage API costs.

## 10) Risks

### 10.1 Risks if current version kept

- **Privacy Breach**: Broad SELECT on storage allows random users to fetch images if they guess the UUID path.

### 10.2 Risks introduced by fixes

- **Stale Cache**: A user replaces their avatar but the app still shows the old one for 60 minutes because it's cached. _Mitigation_: Invalidate cache key specifically upon user-initiated avatar upload.

## 11) Test Plan (High-value)

- **Security**: Authenticated User A tries to get a Signed URL for User B's private chat attachment -> Assert 403 Exception.
- **Performance**: Scroll a list of 50 messages -> Assert `createSignedUrl` API fires exactly once per unique path.

## 12) Production Checklist

- [ ] RLS tightened on `task-images` and `chat-attachments`.
- [ ] Local cache map clears on Logout/Token Expiry.
- [ ] Admin bypass established in storage policies.
