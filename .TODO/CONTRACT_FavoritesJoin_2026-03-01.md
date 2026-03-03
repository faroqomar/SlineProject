# Contract: Favorites joined read (with profile)

**Date**: 2026-03-01  
**Plan**: PLAN_FavoritesFix_2026-03-01.md

## Required root fields (from `favorites` row)

- `id` (string, required)
- `client_id` (string, required)
- `freelancer_id` (string, required) — **must be present on root row** for fallback when join is null
- `created_at` (string ISO8601, required)

## Joined relation: `freelancer` (nullable)

- The service returns favorites with optional `.select('*, freelancer:profiles(...)')` (or equivalent) so that `freelancer` can be null when the profile is missing (deleted, RLS, etc.).
- **Required when present**: `id`, `full_name`, `avatar_url` (all nullable in profile schema).
- **Nullability**: `freelancer` relation itself may be null; parser must not assume `freelancer != null`.

## Parser / model contract

- `FavoriteWithProfile.freelancerId`: must come from **root row `freelancer_id`** when `freelancer` is null; when `freelancer` is present, may use `freelancer.id` if consistent.
- `freelancerName`: `freelancer?.full_name` or null → display placeholder (e.g. "Freelancer").
- `freelancerAvatar`: `freelancer?.avatar_url` or null → show default avatar/icon.
- `createdAt`: from root `created_at` (required).
- **No crash**: Parsing must never throw on null join; use root `freelancer_id` and optional name/avatar.

## Placeholder rendering

When joined profile is absent: show `freelancerId` (e.g. for debugging only if needed), display name "Freelancer", default avatar icon; remove and chat actions still use `freelancerId`.
