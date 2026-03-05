# CodeGuard Report: AuthRefactor

**Date:** 2026-03-05
**Scope:** AuthRefactor
**Agent:** @CodeGuard

## Overview

Evaluated `PLAN_AuthFix_2026-03-01.md` against Supabase RLS policies, PostgreSQL triggers, and Flutter widget performance standards.

## Findings

1. **Security (RLS):**
   - The Postgres trigger `on_auth_user_created` defers to a `SECURITY DEFINER` function (`handle_new_user()`) correctly mapping `NEW.id` to the `id` field of `public.profiles`. The context executes under the postgres role so it naturally passes RLS to bootstrap profiles on creation.
   - The backup RPC `rpc_ensure_self_profile` correctly gates via `auth.uid()` validation, ensuring it can only create or return a profile matching the currently signed-in user.
   - `public.profiles` policy drift is cleaned up down to a single valid `INSERT` policy where `auth.uid() = id`.
2. **Performance:**
   - Client is no longer required to make synchronous consecutive insert statements to bootstrap profiles during registration. This inherently resolves race conditions.
   - Timer leaks resulting from `Future.delayed` blocks inside test mocks (`_FakeAuthFormViewModel`) have been successfully removed, preventing infinite suite hangs.
3. **Compatibility:**
   - Previous users who somehow missed profile creation due to the legacy client bug have a fallback through `AuthSessionViewModel` -> `rpc_ensure_self_profile()`.

## Conclusion

✅ **APPROVED.** No blockers found. The implementation exhibits robust boundaries and eliminates several brittle async client operations.
