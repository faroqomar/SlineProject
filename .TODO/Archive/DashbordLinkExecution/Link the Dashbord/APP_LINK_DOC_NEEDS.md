# What Needs To Be Done (App Link Doc — `.agent/workflows/architecture/app_link_doc.md`)

**Workflow:** App Link Doc scans the dashboard codebase and writes **`.TODO/For_SlineApp.md`** with every feature, how dashboard and app link, and what the app must have for each feature to work 100%.

---

## 1. When to run the workflow

Run the App Link Doc when:

- **New dashboard features or API routes** are added (e.g. Support, Notifications, GET `/api/v1/logs`, new finance sub-routes).
- **New migrations** are added to `supabase/migrations/` or `MIGRATIONS/for_sline_app/` that the app must apply.
- **New feature docs** are added under `Docs/features/`.
- **You want a fresh “what the app must have”** report (e.g. before a release or handoff to the app team).

**Triggers:** `@AppLinkDoc`, “update For_SlineApp”, “what should the app have”, “app link”, “for sline app”, “rescan and write For_SlineApp”.

**Action:** Scan (see §2) and **overwrite** `.TODO/For_SlineApp.md` with the full structured report. Optionally set “Last updated” to today.

---

## 2. Scan sources (workflow expects these)

| Source | Purpose | Status |
|--------|---------|--------|
| `apps/api/src/app.ts` | Registered route modules (users, bookings, cases, chat, reports, auth, finance, tasks, disputes, team, dashboard, settings, search, observability). | ✅ Present |
| `apps/admin-ui/src/App.tsx` | Vite routes (Users, Bookings, Cases, Reports, Chat, Logs, UserInvestigation, SystemHealth, Search, Finance*, Disputes, Settings, etc.). | ✅ Present |
| `apps/admin-ui/src/components/layout/Sidebar.tsx` (or equivalent) | Nav items to correlate with routes. | ✅ Check path (e.g. `DashboardLayout` / `Sidebar`) |
| `Docs/features/*.md` | One file per feature (force-logout, bookings-admin, cases, chat-moderation, reports-queue, users, task-activity, user-investigation, finance, disputes, settings-system-config, system_health, global-search, auth, PAGE_16_approval_queue). | ✅ Present |
| `Docs/ADMIN_FEATURES.md` | High-level feature list and phases. | ✅ Present |
| `apps/api/src/routes/*.ts` | Endpoints, RPCs, tables, RBAC per feature. | ✅ Present |
| `supabase/migrations/*.sql` | Tables, columns, RPCs the dashboard depends on. | ✅ Present |
| `MIGRATIONS/for_sline_app/*.sql` | Migrations to **copy into sline_app**. | ✅ Present (README + SQL files) |
| `MIGRATIONS/for_sline_app/README.md` | Ordered list of migrations to copy. | ✅ Present (may be shorter than For_SlineApp §2; keep in sync if you maintain both) |
| `MIGRATIONS/for_sline_app/FORCE_LOGOUT_APP_ENFORCEMENT.md` | Example “app must do X” for force logout. | ✅ Present |
| `packages/shared/src/schemas/*.ts` | Entity types and request/response shapes that imply DB shape. | ✅ Present |

Nothing is **missing** for the scan; the workflow can run against the current repo.

---

## 3. Current `.TODO/For_SlineApp.md` coverage

As of the last run (2025-03-03), **For_SlineApp.md** already includes:

- **How the app and dashboard link** (same Supabase project, same schema, no dashboard API from app).
- **Feature list and app requirements** (§1): Force Logout, User moderation, Bookings, Cases & Chat, Reports, Users, Tasks, Finance (incl. PAGE 12), Disputes, Settings, Observability, Global Search, User Investigation (PAGE 15), Finance Approvals (PAGE 16), Auth, Team, Dashboard/Logs.
- **Migrations to copy into the app** (§2) in order (extend enum, admin_users, profiles moderation, admin_process_withdrawal, force_logout, admin_booking_rpcs, admin_cases_and_chat_access, reports_queue, system_config, admin_approvals, admin_pii_access_logs).
- **Summary table** (§3) and **Quick checklist** (§4).

**Not in For_SlineApp (by design until implemented):**

- **Support / complaints** — No dashboard API route yet (`apps/api` has no `support.ts`). When added: add a §1 subsection “Support”; likely “Dashboard only; no app schema or behavior” unless support tickets need an app-side table.
- **Notifications** — No dashboard API route yet. When added: add “Notifications”; likely “Dashboard only” or document if app must have a notifications table.
- **GET /api/v1/logs** — Not registered in `app.ts`. For_SlineApp §1.17 already covers “Dashboard overview & Logs” and says no app changes beyond `audit_logs`. When a logs API is added, rescan will keep that consistent.

So **no change is required** for App Link Doc **until** you add Support API, Notifications API, or a logs API; then run the workflow again.

---

## 4. Checklist for “App Link Doc is complete and up to date”

- [ ] **Run App Link Doc** (e.g. “rescan and write For_SlineApp”) after any new feature or migration that affects app–dashboard link.
- [ ] **Confirm output file** is `.TODO/For_SlineApp.md` and has the four sections: How they link, §1 Feature list, §2 Migrations to copy, §3 Summary, §4 Quick checklist.
- [ ] **Optional:** Keep `MIGRATIONS/for_sline_app/README.md` in sync with the migration order in For_SlineApp §2 so both “copy into app” instructions match.
- [ ] **Optional:** When Support/Notifications/Logs API exist, run the workflow so For_SlineApp explicitly lists them (Dashboard only or with app requirements).

---

## 5. One-line summary

**Nothing is missing for the App Link Doc workflow to run.** The scan sources exist; `.TODO/For_SlineApp.md` is present and already covers all current dashboard features that touch the app. Re-run the workflow whenever you add new dashboard features, new migrations for the app, or new feature docs so For_SlineApp stays the single source of truth for “what the app must have.”
