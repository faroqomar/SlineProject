# Home Feed Threat Model

## Scope
- Home discovery feed
- Shared discovery surfaces: Home, Tenders, Bookings
- Cross-user profile summary reads used by task cards, saved items, search enrichment, work management, and public profile

## Threats
- Anonymous users can read `public.tasks` because permissive `SELECT` policies exist in live DB.
- Anonymous or cross-user callers can read `public.profiles` directly because broad `SELECT` policies exist in live DB.
- Client code enriches cross-user profile data from base `profiles`, which includes `email` and `metadata` in live schema.
- Timestamp-only feed cursors can skip or duplicate tasks when multiple rows share `created_at`.
- Home creates a local `SavedTasksViewModel`, allowing bookmark state divergence from the app-wide provider.
- Delivery-time and seller-level filter controls are exposed without enforcement, producing false-positive UX.

## Required Controls
- Replace cross-user base-table `profiles` reads with authenticated-only `rpc_get_profile_summaries`.
- Harden `tasks` reads to authenticated-only, with involved-user fallback for non-open rows.
- Harden base-table `profiles` reads to self-only.
- Use composite feed cursor: `created_at DESC, id DESC`.
- Keep a single global `SavedTasksViewModel` provider.
- Make advanced filters functional and covered by tests.

## Negative Checks
- Anonymous query against `public.tasks` returns permission denied.
- Direct authenticated read of another user's `email` or `metadata` from `public.profiles` returns permission denied.
- `rpc_get_profile_summaries` rejects unauthenticated callers.
- Feed pagination across same-timestamp rows produces no duplicates or gaps.
- Seller-level filter removes tender items when active.
