# RLS Authorization Map — Diagram Document

---

## What every diagram document must include (bullet checklist)

- [x] Diagram Title + Version
- [x] Diagram name (exact)
- [x] Version (v1/v2/final) + date
- [x] Owner/author (team or role)
- [x] Purpose
- [x] Scope
- [x] Assumptions
- [x] Glossary (Human-readable)
- [x] Legend: what each symbol means
- [x] Actors and Responsibilities
- [x] System Components (Where it lives)
- [x] Step-by-step Flow ("Human Story")
- [x] State Machine Explanation (if states exist)
- [x] Invariants (Must-always-be-true rules)
- [x] Guards & Validation Rules
- [x] Failure Modes (What can go wrong)
- [x] Security & Abuse Scenarios
- [x] Data Model Mapping
- [x] Observability & Forensics
- [x] Verification Checklist
- [x] Dependencies
- [x] Open Questions / Missing Evidence
- [x] Final Status

---

# OLD DIAGRAM (v1.0 — Superseded)

**Diagram name (exact):** `15_rls-authorization-map`  
**Version:** v1.0 (Partial)  
**Date:** 2026-03-05  
**Status:** **SUPERSEDED** — See NEW diagram below.

---

## Purpose (OLD)

A security permission matrix showing which roles can perform SELECT/INSERT/UPDATE/DELETE on core tables, derived from live `pg_policies`. Only 35 policies across 8 tables were documented; `qual`/`with_check` predicates were not extracted.

## Why v1 was superseded

| Issue | Impact |
|-------|--------|
| Only 35 policies documented | Missing 73 policies (108 total in DB) |
| Only 8 tables covered | Missing 19 tables with RLS |
| No `qual`/`with_check` predicates | Cannot verify policy safety |
| No view bypass analysis | SECURITY DEFINER risks not identified |
| No storage policy audit | Storage security not verified |
| No automated tests | No regression prevention |
| Verdict: **PARTIALLY VERIFIED** | Score: 3/10 |

**Critical findings missed by v1:**  
1. `public.users` view exposing PII  
2. Wide-open messages policies (`auth.uid() IS NOT NULL`)  
3. `admin_logs` INSERT on `public` role  
4. `bookings_update_status_only` NULL `with_check`

## OLD Diagram — Evidence-based RLS Matrix (8 tables, 35 policies)

| Table                | Policy Name                                   | Role             | Command |
| -------------------- | --------------------------------------------- | ---------------- | ------- |
| `profiles`           | `profiles_select_self`                        | authenticated    | SELECT  |
| `profiles`           | `profiles_update_self`                        | authenticated    | UPDATE  |
| `profiles`           | `Users can insert their own profile`          | public           | INSERT  |
| `profiles`           | `Users can update their own profile`          | public           | UPDATE  |
| `profiles`           | `Users can delete their own profile`          | public           | DELETE  |
| `tasks`              | `tasks_select_authenticated_open_or_involved` | authenticated    | SELECT  |
| `tasks`              | `tasks_insert_owner`                          | public           | INSERT  |
| `tasks`              | `tasks_update_owner`                          | public           | UPDATE  |
| ... (and 27 more rows for 8 tables) | ... | ... | ... |

**Evidence:** Live `pg_policies` query — 35 rows shown. Qual/Check conditions were **not** included in v1.

**Archive:** Full OLD content is in `15_rls-authorization-map_OLD_2026-03-05.md` if needed for reference.

---

# NEW DIAGRAM (v2.0 — Implemented, FINAL)

**Diagram name (exact):** `15_rls-authorization-map`  
**Version:** v2.0 FINAL  
**Date:** 2026-03-06  
**Owner/author:** @Executor / @Supabase_Ops (implementation); @SlineDocs (documentation)

---

## Purpose

**What this diagram is showing, in one paragraph.**  
This diagram shows the complete **Row Level Security (RLS) authorization architecture** for the SLine Supabase database after the 2026-03-06 hardening: all 108 RLS policies across 27 tables, full predicate logic (`qual`/`with_check`), the four critical security blockers that were fixed, policy migration from `public` to `authenticated`, view hardening with `security_invoker`, and the automated test infrastructure (26 tests) that prevents regressions.

**What problem it solves (why it exists).**  
Before this implementation, the database had PII exposure via `public.users`, wide-open message policies, admin log injection, and NULL `with_check` allowing unauthorized column updates. This diagram is the single source of truth for who can do what on each table/view and how the system prevents abuse and data leaks.

---

## Scope

**What's included (features/entities covered):**
- **Tables:** 27 tables with RLS (accounts, activity_log, admin_*, audit_logs, availability_slots, bookings, categories, change_requests, conversation_presence, conversations, direct_offers, disputes, extension_requests, favorites, journal_entries, ledger_lines, messages, notifications, portfolio_items, profiles, report_actions, reports, saved_tasks, services, support_tickets, system_config, task_requests, tasks, ticket_messages, wallet_transactions, withdrawal_requests, work_contracts, work_logs).
- **Views:** 14 views (tasks_mvp, user_conversations, vw_wallet_*, vw_orphaned_auth_users, vw_admin_journal_ledger, vw_financial_metrics_*, vw_analytics_*, vw_unified_*).
- **Storage:** 4 buckets (avatars, chat-attachments, portfolio, task-images) with 14 storage policies.
- **Test infrastructure:** `test/rls/` — 26 automated tests, 8 assertion methods, 5 test user fixtures.

**What's explicitly excluded (out of scope):**
- Application-level auth flows (login/signup) — see auth docs.
- Edge Functions security (separate diagram).
- Realtime subscription logic (uses same RLS; see chat diagram).
- Client-side validation only (no DB impact).

---

## Assumptions

- Supabase Auth is the identity provider; all RLS uses `auth.uid()`.
- JWT claims contain `active_role` in `app_metadata` for role-based policies (synced by trigger).
- Service role key is never exposed to clients (server-side only).
- RLS is enabled on all application tables (27/27 confirmed).
- Views without `security_invoker` run as definer and can bypass RLS (hence hardening).
- Test UUIDs (e.g. 11111111-1111-...) are deterministic and never used in production.

---

## Glossary (Human-readable)

| Term | Definition |
|------|------------|
| **RLS** | Row Level Security — PostgreSQL per-row access control. |
| **Policy** | A `CREATE POLICY` rule: which role can do which command under which condition. |
| **qual** | Policy `USING` clause — filter for SELECT/UPDATE/DELETE (which rows visible). |
| **with_check** | Policy `WITH CHECK` clause — validation for INSERT/UPDATE (which rows allowed). |
| **public role** | Supabase role used with anon key; no guaranteed session. |
| **authenticated role** | Supabase role for logged-in users; `auth.uid()` is set. |
| **service_role** | Supabase role that bypasses RLS; server-side only. |
| **security_invoker** | View option: run with caller's permissions (respects RLS). |
| **SECURITY DEFINER** | View option: run with owner's permissions (can bypass RLS). |
| **Entity** | Table or view (e.g. booking, task_request, conversation, message). |
| **RPC** | Remote Procedure Call — server-side function (e.g. `switch_active_role`). |
| **Idempotency** | Same request twice has same effect (e.g. role switch guard). |

**Status names (examples):** active, open, pending, confirmed, canceled, delivered, completed, disputed, refunded, held, released.

**Money events (examples):** escrow_hold, release_with_fee, refund.

---

## Legend (what each symbol means)

- **Table (⬜):** PostgreSQL table with RLS enabled.
- **View (👁️):** PostgreSQL view; if `security_invoker = true`, it respects base table RLS.
- **Policy row:** `[Table] → [Role] → [Command] → qual / with_check`.
- **🟢 Safe:** Policy correctly scoped (e.g. owner-only, participant-only).
- **🔴 Critical (fixed):** Was a blocker; now dropped or replaced.
- **🟡 Migrated:** Policy moved from `public` to `authenticated`.
- **→ Allow:** Policy permits the operation when condition holds.
- **⊘ Deny:** No policy or qual/with_check blocks the operation.
- **⚡ JWT check:** Policy uses `(auth.jwt()->'app_metadata'->>'active_role') = 'client'|'freelancer'`.

---

## Actors and Responsibilities

| Actor | Allowed | Forbidden |
|-------|--------|-----------|
| **Client** (`active_role = 'client'`) | SELECT own profile, bookings, messages, tasks, notifications; INSERT tasks, bookings, messages (own conversations); UPDATE own profile, task/booking status; DELETE own favorites/saved_tasks. | SELECT others' private data; INSERT task_requests (freelancer-only); UPDATE others' rows; INSERT admin_logs. |
| **Freelancer** (`active_role = 'freelancer'`) | SELECT own profile, bookings, messages, task_requests, availability_slots; INSERT task_requests, availability_slots, messages (own conversations); UPDATE own profile, slots, task request status; DELETE own portfolio items. | INSERT tasks (client-only); SELECT admin/analytics views; Modify other users' data. |
| **Admin** (in `admin_users`) | SELECT admin views and logs; backend uses service_role for admin tables. | Direct client-side admin writes (must go through backend). |
| **System / service_role** | INSERT admin_logs, audit_logs; SELECT all views; full access to accounts, journal_entries, ledger_lines. | N/A (trusted backend only). |
| **Anonymous (public)** | None (except profiles INSERT for signup where required). | All data access; must be authenticated for app usage. |

---

## System Components (Where it lives)

**App entry points:**  
All screens that read/write data — every Supabase call is gated by these policies (no single screen; entire app).

**Database objects involved:**
- **Tables:** 27 tables with RLS (see Scope).
- **Views:** 14 (tasks_mvp, user_conversations, vw_wallet_*, vw_orphaned_auth_users, vw_admin_journal_ledger, vw_financial_metrics_*, vw_analytics_*, vw_unified_*).
- **RPC:** `switch_active_role`, `check_role_switch_rate_limit`, `is_conversation_participant`, `is_work_log_participant`, etc.
- **Triggers:** `trg_sync_role_to_jwt` on `profiles` (syncs active_role to JWT).
- **Policies (RLS):** 108 policies across public schema; 14 storage policies.

**Test/code paths:**
- `test/rls/rls_test_helper.dart` — assertion library.
- `test/rls/fixtures/rls_test_users.dart` — test users.
- `test/rls/critical_blockers_test.dart`, `view_security_test.dart`, `role_switch_jwt_test.dart` — 26 tests.
- Plan: `.TODO/PLAN_RLS_Authorization_Map_CRITIC_2026-03-06.md`
- Execution log: `.TODO/EXECUTION_LOG_RLS_Authorization_Map_CRITIC_2026-03-06.md`

---

## Step-by-Step Flow ("Human Story")

**Hardening flow (what was done):**

1. **Drop PII view:** `DROP VIEW public.users` — removed exposure of auth.users (email, full_name, etc.).
2. **Fix message leak:** Dropped policies "Allow users to read messages" and "Allow users to insert messages" (qual was `auth.uid() IS NOT NULL` → any user could read/insert all messages). Now only conversation-participant policies apply.
3. **Fix admin log injection:** Dropped "Service Role can insert logs" on public; created `admin_logs_insert_service_only` for `service_role` only.
4. **Fix booking tampering:** Dropped `bookings_update_status_only` (NULL with_check allowed any column update). Other policies enforce status-only updates.
5. **Policy cleanup:** Dropped 17 redundant public policies; migrated ~30 policies from public to authenticated (notifications, services, activity_log, change_requests, extension_requests, work_logs, wallet_transactions, etc.).
6. **View hardening:** Recreated `tasks_mvp` and `user_conversations` with `security_invoker = true`; dropped `wallet_balances`; REVOKE SELECT on 6 admin/analytics views from authenticated.
7. **Verification:** 26 RLS tests run in CI to prevent regressions.

**Happy path (runtime):**  
User (client or freelancer) performs an action → app calls Supabase with anon key and session → RLS evaluates policies for `auth.uid()` and JWT role → only allowed rows/commands succeed.

**Common failure path:**  
User tries to read another user's messages → no policy allows it → 403 / empty result.

---

## State Machine Explanation (policy roles)

**States:** Policy role is either `public`, `authenticated`, or `service_role`.

**Transitions (v1 → v2):**
- Many policies: `public` → **dropped** (redundant) or **replaced** by `authenticated` with same logic.
- `admin_logs` INSERT: `public` → **service_role only**.
- Messages: two policies **dropped** (wide-open); rest remain `authenticated`.

**Invariant:** Only two policies remain on `public` by design: `bookings_deny_delete` (qual = false) and `profiles` INSERT (signup flow). All other write/read paths use `authenticated` or `service_role`.

---

## Invariants (Must-always-be-true rules)

- A user can only read messages from conversations where they are a participant (e.g. `is_conversation_participant()` in policy).
- Only `service_role` can insert into `admin_logs`.
- Users can only update/delete rows they own (e.g. `user_id = auth.uid()` or `owner_id = auth.uid()`).
- Role-based operations (e.g. task_requests INSERT, tasks INSERT) are enforced via JWT `active_role` in policy.
- Views that touch user data use `security_invoker = true` or are restricted to service_role.
- Admin-only views are not selectable by `authenticated` (REVOKE applied).

---

## Guards & Validation Rules

- **Ownership:** `qual` / `with_check` use `(owner_id|user_id|client_id|sender_id) = auth.uid()` as appropriate. Source of truth: DB policy.
- **Participant:** Messages/conversations use `EXISTS (SELECT 1 FROM conversations c WHERE c.id = messages.conversation_id AND (c.user1_id = auth.uid() OR c.user2_id = auth.uid()))` or helper `is_conversation_participant()`. Source of truth: DB policy.
- **Role (JWT):** `(auth.jwt()->'app_metadata'->>'active_role') = 'client'` or `'freelancer'` for task/task_requests/availability_slots. Source of truth: DB policy.
- **Admin:** `EXISTS (SELECT 1 FROM admin_users WHERE id = auth.uid())` for admin views/tables. Source of truth: DB policy.

All guards run server-side in RLS; client-side checks are for UX only.

---

## Failure Modes (What can go wrong)

| Failure | System response |
|--------|------------------|
| User reads another's messages | 403 / no rows — RLS blocks. |
| User inserts into admin_logs | 403 — only service_role can insert. |
| User updates booking price | 403 — with_check only allows status change. |
| Rapid role switch | Rate limit (3/min) — RPC returns error. |
| Concurrent role switch (two devices) | Stale state — RPC `expected_old_role` guard fails. |
| JWT out of sync with DB role | App refreshes session; trigger keeps JWT in sync. |
| View without security_invoker | (Before fix) Possible leak; (after fix) views recreated or restricted. |

---

## Security & Abuse Scenarios

| Attack | Prevention |
|--------|-------------|
| Spoofing identity | All policies use `auth.uid()` — valid Supabase session required. |
| Unauthorized state change | `with_check` validates every INSERT/UPDATE. |
| Cross-user data access | Participant/ownership checks in qual. |
| Admin log forgery | `service_role` only; key not in client. |
| PII harvesting | `public.users` view dropped. |
| View RLS bypass | Views use `security_invoker` or are admin-only. |

---

## Data Model Mapping

- "Own data" → `owner_id = auth.uid()` or `user_id = auth.uid()` (table-specific).
- "Participant" → `EXISTS (... conversations WHERE user1_id/user2_id = auth.uid())` or `is_conversation_participant()`.
- "Active role" → `(auth.jwt()->'app_metadata'->>'active_role')`.
- "Admin" → `EXISTS (SELECT 1 FROM admin_users WHERE id = auth.uid())`.
- Indexes that matter for RLS: e.g. on `conversations(user1_id, user2_id)`, `messages(conversation_id)`, `bookings(client_id, provider_id)` for fast policy evaluation.

---

## Observability & Forensics

- **Audit:** Role switches and important actions logged to `audit_logs` (e.g. role_switch action).
- **Admin views:** `vw_admin_journal_ledger`, `vw_orphaned_auth_users`, `vw_financial_metrics_*` for tracing (service_role only).
- **Logs:** AppLogger in app; Supabase logs for 403s and RLS failures.
- **Policy backup:** `.TODO/BACKUP_policies_2026-03-06.json` for rollback.

---

## Verification Checklist

- **Unit tests:** RoleSwitchResult and related model tests (e.g. 17 in `test/unit/profile/`).
- **RLS tests:** 26 tests in `test/rls/` — critical blockers, view security, JWT policies.
- **DB verification:** Policies confirmed in DB (e.g. public.users dropped, admin_logs INSERT service_role only, messages wide-open policies dropped).
- **Concurrency:** Role switch uses `expected_old_role` guard; double-submit handled by idempotency where applicable.

---

## Dependencies

- **Depends on:** Role switching flow (02_role-switching-flow.md) for JWT and role semantics; SUPABASE_SETUP.md for full schema.
- **Depended on by:** Payment/booking flows (use accounts, journal_entries, RLS); chat flows (use messages RLS); admin dashboards (use admin views).

---

## Open Questions / Missing Evidence

- Integration tests against a live Supabase project (with test users) — planned.
- Load testing of policy evaluation — optional.
- Auto-generation of this matrix from `pg_policies` — idea for later.

---

## Final Status

- **Verdict:** PASS  
- **Production ready?** YES — 4 critical blockers resolved, 108 policies hardened, 26 automated tests, documentation and diagram updated.  
- **Next actions:** Optional — integration tests with live DB; dependency update (e.g. supabase_flutter v2) when convenient.

---

## References

- Plan: `.TODO/PLAN_RLS_Authorization_Map_CRITIC_2026-03-06.md`
- Execution log: `.TODO/EXECUTION_LOG_RLS_Authorization_Map_CRITIC_2026-03-06.md`
- Master report: `.TODO/MASTER_REPORT_2026-03-06_RLS_Authorization_Map.md`
- Policy backup: `.TODO/BACKUP_policies_2026-03-06.json`
- Test README: `test/rls/README.md`
- Sline_Log entry: `Sline_everything/Sline_Log.md` (RLS Authorization Map section)
- Old diagram archive: `15_rls-authorization-map_OLD_2026-03-05.md`
