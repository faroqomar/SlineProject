# 01 Notes

**Selected Skills**:

1. Evidence-First Reading: Verified code (`auth_form_view_model.dart`, `profile_repository.dart`) and schema references.
2. Threat Modeling (Security): Identified orphaned user risks.
3. State Machine & Lifecycle: Tracing anonymous -> auth -> profile active.
4. Idempotency & Concurrency: The race between app fetching profile and DB trigger inserting it.
5. Diagram Crafting (Mermaid): To replace the current basic sequence with a robust one.

**Observations:**

- The prompt provided `01_auth-profile-provisioning.md`.
- Evidence shows `auth.users` uses a DB trigger to populate `public.profiles`.
- The flutter code awaits `signUp()`, then immediately expects the profile to exist when it routes to the dashboard (or when `session_view_model` fetches it).
- **Major Issue**: Race condition. The Flutter app might request `from('profiles').select()` BEFORE the Supabase Postgres trigger finishes committing the new profile, leading to a missed profile.
- **Security Issue**: If the trigger fails, the `auth.users` row exists, but no profile. The user is in a broken state.
