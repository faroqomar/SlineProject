# SLine App — What the App Must Have So All Dashboard Features Work

**Purpose**: List every dashboard feature, what the (Flutter) marketplace app must implement (schema + behavior), and how they link so all dashboard features work 100%.  
**Last updated**: 2025-03-03  
**Produced by**: `.agent/workflows/architecture/app_link_doc.md` (App Link Doc — scan dashboard codebase and write this file).

---

## How the app and dashboard link

- **Same Supabase project**: Dashboard API (Fastify) uses **Service Role** to read/write; the Flutter app uses **Supabase client** with **RLS** (authenticated users).
- **Same schema**: Migrations the dashboard depends on must exist in the **app repo** (or in a shared DB that both use). Copy the SQL from `MIGRATIONS/for_sline_app/` and referenced `supabase/migrations/` into `sline_app/supabase/migrations/` in the right order so the app owns the canonical schema.
- **No dashboard API from the app**: End users do **not** call the dashboard API. They use the app only. The app talks to Supabase (and optionally your own app API). The dashboard is for admins only.
- **Link summary**:
  - **Data**: One database. App creates/updates users, profiles, tasks, bookings, conversations, messages, reports, ledger/withdrawals. Dashboard reads the same tables/views and calls RPCs that mutate them (ban, force logout, cancel booking, refund, triage report, approve withdrawal, etc.).
  - **Enforcement**: Some dashboard actions only take effect when the app **enforces** them (e.g. force logout: dashboard sets `profiles.force_logout_after`, app must sign the user out when that is after session start).

---

## 1. Feature list and app requirements

### 1.1 Force Logout (PAGE 06)

| Dashboard side | App side (what you must have) | How they link |
|----------------|--------------------------------|----------------|
| Admin clicks "Force logout" on user detail → API calls RPC `admin_force_logout_user` → sets `profiles.force_logout_after = now()` and writes to `audit_logs`. | **Schema**: Column `profiles.force_logout_after` (timestamptz, nullable). **Migration**: Copy `MIGRATIONS/for_sline_app/20260302140000_force_logout.sql` into app and apply. **Behavior**: On session use (startup / resume / before sensitive ops), read current user's `profiles.force_logout_after` (e.g. from profile fetch or "me" response). If it is set and **after** the token `iat` or session start → treat session as revoked: call `Supabase.auth.signOut()`, clear caches, redirect to login. | Same `profiles` row. Dashboard writes the column; app reads it and enforces re-auth. |

**App checklist**

- [ ] Migration applied: `profiles.force_logout_after` exists; RPC `admin_force_logout_user` exists (dashboard calls it).
- [ ] Profile / "me" response includes `force_logout_after` (or app reads it from Supabase `profiles` with RLS).
- [ ] Session validator: compare `force_logout_after` with token `iat` or session start; if after → sign out and go to login.
- [ ] Optional: on app resume or periodic check, re-fetch profile and re-run the check.

**Ref**: `MIGRATIONS/for_sline_app/FORCE_LOGOUT_APP_ENFORCEMENT.md`, `Docs/features/force-logout.md`

---

### 1.2 User moderation (Ban / Suspend / Unban) (PAGE 05)

| Dashboard side | App side | How they link |
|----------------|----------|----------------|
| Admin bans/suspends/unbans user → API calls RPC `admin_set_user_moderation` → updates `profiles` (account_status, moderation_reason, etc.) and writes to `audit_logs`. | **Schema**: `profiles.account_status`, `moderation_reason`, `moderated_at`, `moderated_by_admin_id`, `restriction_scope`. **Behavior**: Before allowing sensitive actions (e.g. create task, send message), check `profiles.account_status`. If `banned` or `suspended`, show a message and block the action (and optionally redirect to login or a "restricted" screen). | Same `profiles` row. Dashboard sets status; app reads it and enforces. |

**App checklist**

- [ ] Migration applied: `profiles` has moderation columns; RPC `admin_set_user_moderation` exists (from `supabase/migrations/20260302120000_profiles_moderation_and_rpc.sql`).
- [ ] App reads `account_status` (e.g. from profile or "me").
- [ ] App blocks or restricts UX when `account_status` is `banned` or `suspended`.

**Ref**: `supabase/migrations/20260302120000_profiles_moderation_and_rpc.sql`, `Docs/features/users.md`

---

### 1.3 Bookings Admin (PAGE 07)

| Dashboard side | App side | How they link |
|----------------|----------|----------------|
| Dashboard lists bookings, opens detail, cancels (reason), refunds (reason + optional idempotency_key). API calls RPCs `admin_cancel_booking` and `admin_refund_booking`; they update `bookings.status` and write to `audit_logs`. | **Schema**: Table `bookings` with at least: id, task_id, client_id, provider_id, status, payment_status, price, created_at, completed_at, delivered_at. **Migrations**: RPCs `admin_cancel_booking` and `admin_refund_booking` must exist (copy `MIGRATIONS/for_sline_app/20260302120000_admin_booking_rpcs.sql`). **Behavior**: App is where bookings are **created** (user books a task). App shows booking state; when admin cancels or refunds, `status` (and optionally `payment_status`) change in DB — app should reflect that (e.g. "Canceled" or "Refunded") and, if you have wallet/ledger, trigger any refund flow. | Same `bookings` table. App creates and displays; dashboard mutates via RPCs; app shows updated status. |

**App checklist**

- [ ] Table `bookings` exists with expected columns; app creates bookings in normal flow.
- [ ] Migration applied: `admin_cancel_booking`, `admin_refund_booking` exist (and optionally wire refund to your ledger in app SQL).
- [ ] App UI shows booking status; when status is `canceled` or `refunded`, show that and apply any in-app refund logic.

**Ref**: `Docs/features/bookings-admin.md`, `MIGRATIONS/for_sline_app/20260302120000_admin_booking_rpcs.sql`

---

### 1.4 Cases (PAGE 08) & Chat Moderation (PAGE 09)

| Dashboard side | App side | How they link |
|----------------|----------|----------------|
| Dashboard creates cases, attaches entities (task, user, conversation, booking, dispute). Dashboard views chat thread **only** when a case is linked to that thread (case_id in query); every view/grant is logged in `admin_chat_access_logs`. API reads `conversations` / messages for that thread. | **Schema**: Tables `admin_cases`, `admin_case_entities`, `admin_chat_access_logs`; table `admin_users` (referenced by assignee_id / viewer_admin_id). **Conversations**: App has `conversations` (or equivalent) and `messages`; dashboard uses **thread_id** = conversation id. **Behavior**: App does **not** create cases or write to admin_chat_access_logs; those are dashboard-only. App only needs the same DB so that when an admin opens a thread from a case, the API can read the same `conversations`/`messages` the app uses. | Same DB. App owns conversation/message data; dashboard reads it via API when case is linked; RLS on admin tables is service_role only (app never reads them). |

**App checklist**

- [ ] Migrations applied: `admin_users`, `admin_cases`, `admin_case_entities`, `admin_chat_access_logs` (from `supabase/migrations/20260302120000_admin_users.sql`, `supabase/migrations/20260302130000_admin_cases_and_chat_access.sql`). Ensure `admin_cases.assignee_admin_id` / `admin_chat_access_logs.viewer_admin_id` match your schema.
- [ ] App has `conversations` and `messages` (or equivalent) so dashboard chat API can read by thread_id.
- [ ] No app-side logic required for cases or chat moderation — schema only so dashboard can operate.

**Ref**: `Docs/features/cases.md`, `Docs/features/chat-moderation.md`, `supabase/migrations/20260302130000_admin_cases_and_chat_access.sql`

---

### 1.5 Reports Queue (PAGE 10)

| Dashboard side | App side | How they link |
|----------------|----------|----------------|
| Dashboard lists reports, opens detail, triages (dismiss, warn_user, escalate, close), closes. API reads `reports` and `report_actions`; mutations call RPCs `admin_triage_report` and `admin_close_report`. | **Schema**: Tables `reports` and `report_actions` (see `supabase/migrations/20260302130000_reports_queue.sql`). **Behavior**: **Users in the app** must be able to **create** reports (e.g. "Report this task", "Report this user", "Report this chat"). So either: (1) RLS policy allowing `INSERT` into `reports` where `reporter_user_id = auth.uid()`, or (2) an RPC that inserts one row and returns id. Dashboard only reads/triages/closes; it does not create reports. | Same `reports` table. App inserts new reports; dashboard reads and updates status via RPCs. |

**App checklist**

- [ ] Migration applied: `reports`, `report_actions`, `admin_triage_report`, `admin_close_report` (and enum/constraint for `entity_type`: task, user, chat).
- [ ] App UI: "Report task", "Report user", "Report conversation" that create a row in `reports` (via RLS insert or RPC). Store at least: reporter_user_id, entity_type, entity_id, reason, category (optional), status default `open`.
- [ ] No app-side triage/close — dashboard only.

**Ref**: `Docs/features/reports-queue.md`, `supabase/migrations/20260302130000_reports_queue.sql`

---

### 1.6 Users list & detail (dashboard)

| Dashboard side | App side | How they link |
|----------------|----------|----------------|
| Dashboard lists and shows `profiles` (and auth user); ban, unban, suspend, force logout. | **Schema**: Table `profiles` with columns expected by dashboard (id, email, full_name, avatar_url, role/active_role, account_status, force_logout_after, moderation columns, etc.). App creates/updates profiles on sign-up/profile edit. | Same `profiles` (and auth.users). Dashboard reads via API (service role); app writes via Supabase client (RLS). |

**App checklist**

- [ ] `profiles` exists and is kept in sync with auth (e.g. trigger or app code on sign-up).
- [ ] Optional: if dashboard expects `admin_users` for RBAC, ensure `admin_users` exists and is populated for admin accounts.

**Ref**: `Docs/features/users.md`

---

### 1.7 Tasks (dashboard)

| Dashboard side | App side | How they link |
|----------------|----------|----------------|
| Dashboard lists tasks, may force-cancel. | **Schema**: Tables `tasks` (and related) that dashboard API queries. App creates/updates tasks in normal flow. | Same `tasks` table; dashboard reads and may call an RPC to cancel/update status. |

**App checklist**

- [ ] `tasks` (and any task_requests / status fields) exist; app uses them.
- [ ] If dashboard implements force-cancel via RPC (e.g. `admin_update_task_status`), add that RPC in app migrations so dashboard can call it.

**Ref**: `Docs/features/task-activity.md`, `apps/api/src/routes/tasks.ts`

---

### 1.8 Finance (dashboard) + PAGE 12 (Transaction Detail, Audit Export, User Lookup)

| Dashboard side | App side | How they link |
|----------------|----------|----------------|
| Dashboard shows metrics, transaction list/detail, withdrawals, approvals (PAGE 16), **audit log list/export**, **user wallet lookup**. Approve/reject withdrawals via RPC `admin_process_withdrawal`. **PAGE 12**: GET transaction detail (masked; reveal inserts into `audit_logs` then returns meta); GET audit list/export (reads `audit_logs` with cursor); GET user wallet + timeline (reads `vw_wallet_balances_user`, `vw_wallet_activity_user`). | **Schema**: (1) **Ledger**: `journal_entries` / ledger tables and view **`vw_admin_journal_ledger`** (for transaction list and detail). (2) **Withdrawals**: `withdrawal_requests`; RPC **`admin_process_withdrawal`** (copy `MIGRATIONS/for_sline_app/20260302110000_admin_process_withdrawal.sql`). (3) **audit_logs**: Must have columns **`id`** (uuid PK), **`created_at`** (timestamptz), `actor_user_id`, `action`, `related_entity_type`, `related_entity_id`, `meta` (jsonb); optional `journal_entry_id`. Required for dashboard audit list/export and for transaction-detail "reveal" (dashboard inserts one row then returns meta). See `MIGRATIONS/PAGE_12_audit_logs_and_wallet_views_columns.md`. (4) **PAGE 12 user lookup**: Views **`vw_wallet_balances_user`** (user_id, available_balance, held_balance, pending_withdrawal_balance, currency, is_wallet_frozen) and **`vw_wallet_activity_user`** (user_id, activity rows compatible with journal/ledger shape). Canonical DDL in sline_app (e.g. `20260225_create_ledger_core_schema.sql`, `20260225_create_wallet_views.sql`). **Behavior**: App creates ledger entries and withdrawal requests in normal flow (payments, payout requests). No app behavior required for audit list/export or user lookup — dashboard reads only; same DB. | Same DB. App creates ledger/withdrawals; dashboard reads views and `audit_logs`, mutates via RPCs; dashboard inserts into `audit_logs` on transaction-detail reveal. |

**App checklist**

- [ ] Ledger and withdrawal schema + RPC `admin_process_withdrawal` exist in app migrations; app creates withdrawals/ledger events when users request payouts or complete payments.
- [ ] **audit_logs** has `id`, `created_at`, and columns above so dashboard GET /finance/audit and GET /finance/audit/export and transaction-detail reveal work.
- [ ] **vw_admin_journal_ledger** exists for transaction list and detail.
- [ ] For PAGE 12 user lookup: **vw_wallet_balances_user** and **vw_wallet_activity_user** exist (dashboard returns 501 if not); canonical DDL in sline_app.

**Ref**: `Docs/features/finance.md`, `MIGRATIONS/for_sline_app/20260302110000_admin_process_withdrawal.sql`, `MIGRATIONS/PAGE_12_audit_logs_and_wallet_views_columns.md`

---

### 1.9 Disputes (dashboard)

| Dashboard side | App side | How they link |
|----------------|----------|----------------|
| Dashboard lists disputes, views evidence, may release funds / refund / split. | **Schema**: Disputes/tickets table; link to tasks/bookings and chat. RPCs for resolution if any. App may create disputes when a user escalates. | Same DB; app may insert disputes; dashboard reads and resolves. |

**App checklist**

- [ ] Dispute/ticket schema exists; app can create a dispute (e.g. from a booking or task).
- [ ] Any RPCs the dashboard calls for dispute resolution exist in app migrations.

**Ref**: `Docs/features/disputes.md`, `apps/api/src/routes/disputes.ts`

---

### 1.10 Settings / System config (PAGE 13)

| Dashboard side | App side | How they link |
|----------------|----------|----------------|
| Dashboard GET/PATCH `/api/v1/settings/config`; reads/updates `system_config` (maintenance_mode, app_banner, disable_signups, min_app_version). API calls RPC `admin_update_system_config` for PATCH (atomic update + audit). | **Schema**: Table `system_config` (key, value jsonb, description, updated_by, updated_at); RPC `admin_update_system_config(p_key, p_value, p_actor_user_id)`. Copy `MIGRATIONS/for_sline_app/20260303100000_system_config.sql`. **Behavior**: Dashboard is sole writer. If the **app** wants to show a maintenance screen or enforce `min_app_version`, the app must be able to **read** these keys. Currently RLS on `system_config` allows only service_role — so either: (1) add a read-only RLS policy or an RPC/Edge Function that returns public keys (e.g. maintenance_mode, min_app_version) to app clients, or (2) expose them via your app backend. No app behavior required for dashboard to work; optional app behavior for maintenance/force-update UX. | Same `system_config` table. Dashboard reads/writes; app may read selected keys for UX (maintenance, min version) if you add a read path. |

**App checklist**

- [ ] Migration applied: `system_config` table and RPC `admin_update_system_config` exist (dashboard uses them).
- [ ] Optional: if you want app to show "Under maintenance" or "Update required": add a read path (policy or API) for keys like `maintenance_mode`, `min_app_version` and enforce in app UI.

**Ref**: `MIGRATIONS/for_sline_app/20260303100000_system_config.sql`, `Docs/features/settings-system-config.md`, `MIGRATIONS/README.md` (PAGE 13)

---

### 1.11 Observability / System Health (PAGE 14)

| Dashboard side | App side | How they link |
|----------------|----------|----------------|
| Dashboard GET `/api/v1/observability` for service status (DB, Auth, Storage) and optional error rates from `audit_logs`. Read-only; no mutations. | **Schema**: None required for this feature. Dashboard API uses `admin_users` (RBAC + DB ping) and optional read from `audit_logs` for error counts — those tables already exist for other features. **Behavior**: None. | Dashboard only. No app-side schema or behavior required. |

**App checklist**

- [ ] No app changes required for Observability to work.

**Ref**: `Docs/features/system_health.md`, `MIGRATIONS/README.md` (PAGE 14)

---

### 1.12 Global Search (PAGE 11)

| Dashboard side | App side | How they link |
|----------------|----------|----------------|
| Dashboard global search (users, tasks, bookings, disputes, transactions) via GET `/api/v1/search`. Reads same tables/views as list/detail features: `profiles`, `tasks`, `bookings`, `disputes`, `vw_admin_journal_ledger`. | **Schema**: Same as Users, Tasks, Bookings, Finance (profiles, tasks, bookings, disputes, ledger). **Behavior**: None. Dashboard searches data the app already creates. | Same DB; app creates the data; dashboard queries it. |

**App checklist**

- [ ] No additional app schema or behavior beyond what Users, Tasks, Bookings, Disputes, and Finance require.

**Ref**: `Docs/features/global-search.md`, `Docs/PAGE_11_search_discovery.md`

---

### 1.13 User Investigation (PAGE 15)

| Dashboard side | App side | How they link |
|----------------|----------|----------------|
| Dashboard shows aggregated user view (profile, tasks, offers, bookings, disputes, finance, reports, conversations); PII masked by default; admin/super_admin can reveal PII via POST reveal-pii (logged in `admin_pii_access_logs` and `audit_logs` action `admin.pii.reveal`); evidence-pack export. GET investigation and GET evidence-pack write `audit_logs` (`admin.users.investigation_view`, `admin.export.evidence_pack`). | **Schema**: Table **`admin_pii_access_logs`** must exist so the dashboard API can insert a row on every PII reveal. Copy `supabase/migrations/20260303100000_admin_pii_access_logs.sql` from the dashboard repo into sline_app and apply. All other data (profiles, tasks, bookings, disputes, ledger, messages for conversation summaries) is already required by other features. **Behavior**: None. App does not use User Investigation; it is dashboard-only. | Same DB; dashboard reads shared tables and writes to `admin_pii_access_logs` and `audit_logs`; app has no behavior. |

**App checklist**

- [ ] Table `admin_pii_access_logs` exists in app (copy `supabase/migrations/20260303100000_admin_pii_access_logs.sql` from dashboard repo to sline_app). No app-side logic required.

**Ref**: `Docs/features/user-investigation.md`, `Docs/ADMIN_FEATURES.md` (User Investigation), `apps/api/src/routes/users.ts`, `supabase/migrations/20260303100000_admin_pii_access_logs.sql`

---

### 1.14 Finance Approvals / Dual approval (PAGE 16)

| Dashboard side | App side | How they link |
|----------------|----------|----------------|
| Dashboard uses approval queue for dangerous ops (wallet adjust above threshold, reversal, large refund). API calls RPCs `admin_request_approval`, `admin_approve_or_reject_approval`; execute (e.g. wallet adjust) calls `admin_adjust_wallet`. Table `admin_approvals` stores pending/approved/rejected/consumed. | **Schema**: Table `admin_approvals` and RPCs from `MIGRATIONS/for_sline_app/20260302150000_admin_approvals.sql` (`admin_request_approval`, `admin_approve_or_reject_approval`, `admin_adjust_wallet`). **Behavior**: None for approval queue itself — app does not create or consume approvals; dashboard admins do. **Ledger (app repo)**: The migration’s `admin_adjust_wallet` currently only sets `consumed_at` and writes `audit_logs`; it has a **TODO** to perform the actual wallet/ledger mutation (e.g. journal entry). When you want dashboard “Execute” to change real balances, add that mutation inside the RPC in the app repo (or call an existing ledger RPC). | Same DB; dashboard-only writes to `admin_approvals`; app has no approval UI; app repo owns the ledger so must implement the actual adjust in `admin_adjust_wallet` when needed. |

**App checklist**

- [ ] Migration applied: `admin_approvals` table and RPCs exist so dashboard can request, approve/reject, and call execute. No app-side approval logic required.
- [ ] **Optional (when enabling real wallet adjust)**: In app repo, add the actual wallet/ledger mutation inside `admin_adjust_wallet` (or call existing ledger RPC) so “Execute” from the dashboard changes balances; until then, execute only marks approval consumed and writes audit.

**Ref**: `MIGRATIONS/for_sline_app/20260302150000_admin_approvals.sql`, `Docs/ADMIN_APPROVALS.md`, `Docs/features/PAGE_16_approval_queue.md`, `MIGRATIONS/README.md` (PAGE 16)

---

### 1.15 Auth (dashboard admin identity)

| Dashboard side | App side | How they link |
|----------------|----------|----------------|
| Dashboard login: admins sign in via Supabase Auth; dashboard API verifies JWT and resolves role from `admin_users`. No dashboard API is called from the app. | **Schema**: Table `admin_users` (id, email, role, etc.) — required for dashboard RBAC, team, and case/chat logs. **Behavior**: None. App users never call the dashboard; only admins use the dashboard. Populate `admin_users` for accounts that should access the dashboard. | Dashboard only. App does not use dashboard auth; `admin_users` lives in same DB so dashboard API can enforce RBAC. |

**App checklist**

- [ ] `admin_users` table exists and is populated for dashboard admins (see 1.4, 1.6). No app-side auth logic for dashboard.

**Ref**: `Docs/features/auth.md`, `apps/api/src/routes/auth.ts`

---

### 1.16 Team (admin member management)

| Dashboard side | App side | How they link |
|----------------|----------|----------------|
| Dashboard invites/updates/removes admin members via `/api/v1/team` (invite, update role, remove). Uses `admin_users` and Supabase Auth Admin (inviteUserByEmail). | **Schema**: Table `admin_users` (id, email, role, etc.) — already required for RBAC and cases/chat. **Behavior**: None. App does not invite or manage admins; dashboard only. | Dashboard only. App needs `admin_users` so dashboard RBAC and team routes work; no app-side logic. |

**App checklist**

- [ ] `admin_users` table exists and is populated for dashboard admins (see 1.4, 1.6, 1.15). No app-side team logic required.

**Ref**: `apps/api/src/routes/team.ts`

---

### 1.17 Dashboard overview & Logs

| Dashboard side | App side | How they link |
|----------------|----------|----------------|
| Dashboard index (`/`) shows overview metrics; Sidebar "System Logs" → `/logs` (placeholder). Finance Audit (`/finance/audit`) lists and exports `audit_logs`. | **Schema**: Table `audit_logs` (canonical) with `id`, `created_at`, and columns required by Finance PAGE 12 (see 1.8) — already required for all RPCs that write audit and for audit list/export. **Behavior**: None. | Dashboard only. No app API or behavior; dashboard reads `audit_logs` for audit list/export and overview. |

**App checklist**

- [ ] No app changes required beyond audit_logs shape (see 1.8). `audit_logs` already required by other features.

**Ref**: `apps/api/src/routes/dashboard.ts`, `apps/admin-ui/src/routes/Logs.tsx` (placeholder), `Docs/features/finance.md` (PAGE 12)

---

## 2. Migrations to copy into the app (order)

Copy these into **sline_app** (`sline_app/supabase/migrations/`) so the app repo owns the schema. Apply in dependency order (after existing tables like `profiles`, `bookings`, `audit_logs`, ledger, etc.):

| Order | Migration (dashboard repo path) | Purpose |
|-------|--------------------------------|---------|
| 1 | `MIGRATIONS/for_sline_app/20260302100000_extend_related_entity_type_enum.sql` | Extend `related_entity_type_enum` for audit_logs (task, admin_user, profile). |
| 2 | `supabase/migrations/20260302120000_admin_users.sql` | Admin identity for RBAC, team, cases/chat logs. |
| 3 | `supabase/migrations/20260302120000_profiles_moderation_and_rpc.sql` | Profiles moderation columns + `admin_set_user_moderation`. |
| 4 | `MIGRATIONS/for_sline_app/20260302110000_admin_process_withdrawal.sql` | Withdrawal approve/reject RPC. |
| 5 | `MIGRATIONS/for_sline_app/20260302140000_force_logout.sql` | Force logout column + `admin_force_logout_user`. |
| 6 | `MIGRATIONS/for_sline_app/20260302120000_admin_booking_rpcs.sql` | `admin_cancel_booking`, `admin_refund_booking`. |
| 7 | `supabase/migrations/20260302130000_admin_cases_and_chat_access.sql` | admin_cases, admin_case_entities, admin_chat_access_logs. |
| 8 | `supabase/migrations/20260302130000_reports_queue.sql` | reports, report_actions, admin_triage_report, admin_close_report. |
| 9 | `MIGRATIONS/for_sline_app/20260303100000_system_config.sql` | system_config table + RPC `admin_update_system_config` (PAGE 13). |
| 10 | `MIGRATIONS/for_sline_app/20260302150000_admin_approvals.sql` | admin_approvals table + RPCs (PAGE 16). |
| 11 | `supabase/migrations/20260303100000_admin_pii_access_logs.sql` | admin_pii_access_logs (PAGE 15; if dashboard uses it). |

**Note**: Ledger core schema (`audit_logs` with `id`, `created_at`, etc.), `vw_admin_journal_ledger`, and wallet views (`vw_wallet_balances_user`, `vw_wallet_activity_user`) are defined in **sline_app** (e.g. `20260225_create_ledger_core_schema.sql`, `20260225_create_wallet_views.sql`). Ensure they exist so Finance PAGE 12 (transaction list/detail, audit list/export, user lookup) works.

**Ref**: `MIGRATIONS/README.md`, `MIGRATIONS/for_sline_app/README.md`, `MIGRATIONS/PAGE_12_audit_logs_and_wallet_views_columns.md`

---

## 3. Summary: per-feature app requirements

| Feature | App must have (schema) | App must do (behavior) | Link |
|---------|------------------------|------------------------|------|
| **Force Logout** | `profiles.force_logout_after`; RPC `admin_force_logout_user` | Read `force_logout_after`; if after session start → sign out and go to login | Same profiles row |
| **User moderation** | `profiles` moderation columns; RPC `admin_set_user_moderation` | Check `account_status`; block/restrict when banned/suspended | Same profiles row |
| **Bookings Admin** | `bookings` table; RPCs `admin_cancel_booking`, `admin_refund_booking` | Create bookings; show status; handle canceled/refunded in UI (and ledger if any) | Same bookings table |
| **Cases & Chat** | `admin_cases`, `admin_case_entities`, `admin_chat_access_logs`, `admin_users`; `conversations`/`messages` | None (dashboard-only); same DB so dashboard can read threads | Same DB; app owns chat data |
| **Reports Queue** | `reports`, `report_actions`; RPCs `admin_triage_report`, `admin_close_report` | **Create** reports from app (Report task/user/chat) via RLS or RPC | Same reports table; app inserts, dashboard reads/updates |
| **Users** | `profiles` (and optionally `admin_users`) | Create/update profiles; sync with auth | Same profiles |
| **Tasks** | `tasks` (and related) | Create/update tasks; optional RPC for admin force-cancel | Same tasks table |
| **Finance** | Ledger + `vw_admin_journal_ledger`; `withdrawal_requests`; RPC `admin_process_withdrawal`; **audit_logs** with `id`, `created_at` (+ columns for list/export/reveal); **PAGE 12**: `vw_wallet_balances_user`, `vw_wallet_activity_user` | Create ledger/withdrawal rows when users pay/request payout | Same DB; dashboard reads views and audit_logs |
| **Disputes** | Dispute/ticket schema and RPCs | Create disputes when user escalates; dashboard resolves | Same DB |
| **Settings / System config** | `system_config` table; RPC `admin_update_system_config` | Optional: read maintenance_mode / min_app_version for maintenance or force-update UX (requires read path) | Same system_config; dashboard writes |
| **Observability** | None | None | Dashboard only |
| **Global Search** | Same as Users/Tasks/Bookings/Finance | None | Same DB |
| **User Investigation** | `admin_pii_access_logs` (dashboard inserts on reveal-pii; copy migration from dashboard repo) | None | Dashboard only; app has table so dashboard API can write |
| **Finance Approvals** | `admin_approvals` table + RPCs; optional: ledger mutation inside `admin_adjust_wallet` in app repo when enabling real wallet adjust | None (approval queue); app repo adds ledger mutation in RPC when needed | Dashboard only; app repo owns ledger |
| **Auth (admin identity)** | `admin_users` (for dashboard RBAC) | None | Dashboard only |
| **Team** | `admin_users` (already required) | None | Dashboard only |
| **Dashboard / Logs / Finance Audit** | `audit_logs` (id, created_at, etc.); see Finance 1.8 | None | Dashboard only; audit list/export read audit_logs |

---

## 4. Quick checklist for "all features work fully"

- [ ] All migrations above applied in sline_app in order.
- [ ] **Force logout**: App reads `force_logout_after`, compares to session, signs out when revoked.
- [ ] **Moderation**: App checks `account_status` and restricts banned/suspended users.
- [ ] **Bookings**: App creates bookings; shows status; RPCs for cancel/refund exist and are used by dashboard.
- [ ] **Reports**: App lets users submit reports (insert into `reports` with entity_type task/user/chat).
- [ ] **Cases/Chat**: admin_cases, admin_chat_access_logs and conversations/messages in same DB; no app logic for cases.
- [ ] **Admin identity**: `admin_users` populated for dashboard admins so RBAC, team, and case/chat logs work.
- [ ] **Finance**: Ledger, `vw_admin_journal_ledger`, `audit_logs` (with id, created_at), withdrawal RPC; PAGE 12: `vw_wallet_balances_user` and `vw_wallet_activity_user` for user lookup (or dashboard returns 501).
- [ ] **System config**: `system_config` table and RPC exist; optional: app reads maintenance_mode / min_app_version for UX.
- [ ] **Finance Approvals (PAGE 16)**: `admin_approvals` table + RPCs applied; no app approval UI. Optional: when enabling real wallet adjust from dashboard, add ledger mutation inside `admin_adjust_wallet` in app repo.
- [ ] **User Investigation (PAGE 15)**: Table `admin_pii_access_logs` exists (copy `supabase/migrations/20260303100000_admin_pii_access_logs.sql` from dashboard repo). No app behavior.
- [ ] **Observability / Global Search / Team / Dashboard / Logs**: No app behavior; schema only where listed.

This document is the single place to see what the app should have and how it links to the dashboard for each feature. Maintained per `.agent/workflows/architecture/app_link_doc.md`.
