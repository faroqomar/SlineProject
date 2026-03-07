# FULL REPORT: 15 RLS Authorization Map

## 0) Skill Selection

- **Skills selected**: RLS & Privilege Boundaries, Threat Modeling, Evidence-First Reading, Invariants & Contracts, Diagram Crafting, Observability.
- **Why these fit**: This represents the exact boundary between untrusted public network calls and internal financial data. The zero-trust model depends 100% on analyzing bypasses, security definers, and schema exposure.
- **Skills not used**: DB-First Financial Modeling.

## 1) Folder Identity

- **Folder name + path**: `.TODO/improvement_the_system/Done/15_rls-authorization-map`
- **What system/feature it describes**: A matrix mapping out exactly what Database Roles (`public`, `authenticated`, `service_role`) have access to (`SELECT`/`INSERT`/`UPDATE`/`DELETE`) across all primary tables.
- **Entities involved**: `pg_policies`, all public tables, `public.users` (legacy view), `tasks_mvp` (view).

## 2) Human Explanation

Because the Flutter app uses Supabase (PostgREST), it sends queries directly from the client. RLS is the firewall that stops Malicious Client A from querying the database for Client B's private messages or modifying escrow balances. The map defines that `authenticated` users can only read/write rows matching their `auth.uid()`, while sensitive tables like `ledger_lines` completely block client writes, forcing clients to go through audited `SECURITY DEFINER` RPCs.

## 3) Symbol Legend

- **Rectangles**: Database schemas and tables.
- **Solid Borders**: Security barriers (RLS boundaries).
- **Paths**: Execution contexts (`auth.role = anon` vs `authenticated` vs `service_role`).

## 4) Extracted Contracts & Invariants

1. **Zero-Trust**: No internal state changes are trusted from the broad client without `uid` matching.
2. **Ownership PK**: Ownership checks must prioritize checking `owner_id = auth.uid()` or explicit participant IDs.
3. **Double-Entry Sanctity**: `ledger_lines` and `journal_entries` completely reject `INSERT/UPDATE` from `authenticated`.

## 5) Conflict Scan Results

### 5.1 Naming Drift

- **Conflict**: Broad usages of the unauthenticated `public` role where `authenticated` was meant.
- **Resolution**: Strict auditing. If it requires login, it uses `authenticated`.

### 5.2 Logic Drift

- **Conflict**: State transitions (e.g. changing Booking from `confirmed` to `completed`) could be arbitrarily forced via `UPDATE` by a malicious client.
- **Resolution**: Required adding `WITH CHECK` clauses to policies to block impossible state skips.

### 5.3 Data Model Drift

- **Conflict**: System exposed an aggressive vulnerability via `public.users` and `SECURITY DEFINER` views bypassing RLS entirely.
- **Resolution**: Dropping `public.users` immediately. Converting views to `SECURITY INVOKER`.

## 6) Security & Failure Modes (Adversarial)

- **PII Leakage**: Querying the `public.users` view exposes emails of everyone in the app.
  - _Mitigation_: Dropping the view. Reading `auth.users` must be strictly shielded behind admin RPCs.
- **Ghost Data Modification**: Using `tasks_mvp` (if Definer) to overwrite tasks.
  - _Mitigation_: Ensure all views use `WITH (security_invoker = true)`.

## 7) UI Mapping

### 7.1 Mobile App UI

- **Screens**: Almost everywhere. `try/catch` wrapping for Supabase calls must handle `42501` elegantly.
- **States**: If `PostgrestException 42501` hits, the app gracefully bumps the user back out or refreshes the session.
- **Guardrails**: No caching sensitive unauthorized data.

### 7.2 Admin Dashboard UI

- **Pages**: Admins bypass normal RLS using a Service Role key or a dedicated `active_role = 'admin'` JWT claim to see system health.

### 7.3 Implementation Hooks

- All Supabase Flutter Client queries implicitly attach the JWT.

## 8) Diagram Verdict + Best Diagram Type

- **Score now**: 9.5/10 (Post-fixes)
- **Best Diagram Type**: Hierarchical Authorization Flow (Identity -> Role -> Predicate -> Tables).

## 9) Upgrade Plan

- **Phase 0: Observability**: Tag 42501 hits in log explorer.
- **Phase 1: Contracts**: Eradicate `public.users` view. Update `tasks_mvp` to Security Invoker.
- **Phase 2: Hardening**: Add `WITH CHECK` to prevent status hijacking via basic updates on `bookings` and `tasks`.
- **Phase 3: Scale**: Add Index on `auth.uid()` mapped columns (e.g. `owner_id`, `freelancer_id`) to speed up RLS scans.

## 10) Risks

### 10.1 Risks if current version kept

- **CRITICAL**: PII breach via `auth.users` and malicious mutation via undefended Views.

### 10.2 Risks introduced by fixes

- **Regression**: Tightening RLS might block legitimate legacy queries. _Mitigation_: Verify against existing App logic.

## 11) Test Plan (High-value)

- **Security**: Authenticate as User A. Query `SELECT * FROM profiles`. Assert only 1 row (User A) returns.
- **Security**: Attempt `INSERT INTO ledger_lines`. Assert 42501 rejection.
- **Security**: Attempt to run `SELECT * FROM public.users`. Assert table/view doesn't exist.

## 12) Production Checklist

- [ ] `public.users` dropped.
- [ ] RLS enabled on every single table.
- [ ] `SECURITY INVOKER` active on views (`vw_unified_work_items`, etc).
