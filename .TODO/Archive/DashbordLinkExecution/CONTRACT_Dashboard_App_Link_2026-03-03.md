# API Contract - Dashboard App Link (2026-03-03)

## Profiles Contract (App Guard)

Table: `public.profiles`

Required fields for app read:
- `id` (uuid)
- `account_status` (text: `active` | `suspended` | `banned`)
- `moderation_reason` (text, nullable)
- `restriction_scope` (text, nullable)
- `force_logout_after` (timestamptz, nullable)

Rules:
- `force_logout_after > session_iat` means revoked session.
- `account_status in ('suspended','banned')` means restricted user.

## Public Config Contract (App Shell/Auth)

Source: `public.system_config` (public-safe read path)

Required keys and JSON shape:
- `maintenance_mode`:
  - `{ "enabled": boolean, "message": string }`
- `disable_signups`:
  - `{ "enabled": boolean }`
- `min_app_version`:
  - `{ "ios": string, "android": string }`
- `app_banner`:
  - `{ "enabled": boolean, "text": string, "type": string }`

## Report Contract (App -> DB)

Table: `public.reports`

Insert payload:
- `reporter_user_id` = `auth.uid()`
- `entity_type` in (`task`, `user`, `chat`)
- `entity_id` uuid
- `reason` text
- `category` text nullable
- `meta` jsonb nullable

## Dispute Contract (App -> DB)

Table: `public.disputes`

Insert payload:
- `task_id` uuid
- `complainant_id` = `auth.uid()`
- `defendant_id` uuid nullable
- `reason` text
- `status` default `open`

## Error Contract

UI-friendly mappings:
- unauthorized/rls -> "Not allowed. Please sign in again."
- blocked account -> "Your account is restricted."
- maintenance -> "System is under maintenance."
- update required -> "Please update the app to continue."
