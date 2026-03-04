# wallet — Feature Audit (Phase 1) + Verified Fix Plan

## 0) Overview
- What this feature does:
  - Displays wallet balances and activity in the full wallet screen. File References: `lib/features/wallet/view/wallet_screen.dart:32-209`, `lib/features/wallet/services/wallet_service.dart:12-45`, `supabase/migrations/20260225_create_wallet_views.sql:14-158`
  - Lets the signed-in user request a withdrawal. File References: `lib/features/wallet/view/wallet_screen.dart:147-177`, `lib/features/wallet/view/wallet_screen.dart:293-381`, `lib/features/wallet/viewmodels/wallet_view_model.dart:84-111`, `lib/features/wallet/services/wallet_service.dart:57-123`, `supabase/migrations/20260307_fix_ledger_event_type_enum.sql:583-722`
  - Shows a compact wallet summary in the dashboard overview. File References: `lib/features/dashboard/view/tabs/overview_tab.dart:24-31`, `lib/features/dashboard/view/tabs/overview_tab.dart:57-59`, `lib/features/wallet/view/widgets/wallet_snapshot_card.dart:14-61`
- Boundaries:
  - In scope: `lib/features/wallet/**` and the direct app entrypoints that open or preload wallet state. File References: `lib/features/wallet/viewmodels/wallet_view_model.dart:9-117`, `lib/app/main_navigation_screen.dart:17-18`, `lib/app/main_navigation_screen.dart:42-52`, `lib/features/profile/view/profile_screen.dart:471-483`, `lib/features/dashboard/view/tabs/overview_tab.dart:24-31`, `lib/features/dashboard/view/widgets/next_actions_list.dart:16-38`, `lib/features/dashboard/view/tabs/work_tab.dart:380-397`
  - In scope: direct backend dependencies used by wallet reads and writes. File References: `supabase/migrations/20260225_create_wallet_views.sql:14-158`, `supabase/migrations/20260225_create_ledger_core_schema.sql:90-247`, `supabase/migrations/20260225_create_ledger_rls_policies.sql:12-252`, `supabase/migrations/20260224_restrict_process_payment_event_ledger_execute.sql:4-42`, `supabase/migrations/20260307_fix_ledger_event_type_enum.sql:583-1000`, `supabase/functions/qicard_webhook_handler/index.ts:152-169`, `supabase/functions/qicard_webhook_handler/index.ts:389-411`
  - Out of scope: booking, task-request, and direct-offer UI/business flows except where their ledger side effects are consumed by wallet views or wallet settlement paths. File References: `supabase/migrations/20260225_create_wallet_views.sql:56-74`, `supabase/migrations/20260225_create_wallet_views.sql:87-158`, `supabase/migrations/20260317000000_fix_task_request_amount_gross.sql:1-20`
  - Live Supabase state is UNVERIFIED. This audit is based on repository migrations and edge-function source, not a live schema dump. Missing files: live `pg_get_functiondef(...)` output, live `pg_policies` output, applied migration history
- Entry points:
  - Bottom-nav wallet tab: `WalletDashboardScreen`. File Reference: `lib/app/main_navigation_screen.dart:42-52`
  - Profile menu wallet entry: `WalletScreen`. File Reference: `lib/features/profile/view/profile_screen.dart:471-483`
  - Dashboard overview preload + snapshot: `OverviewTab` + `WalletSnapshotCard`. File References: `lib/features/dashboard/view/tabs/overview_tab.dart:24-31`, `lib/features/dashboard/view/tabs/overview_tab.dart:57-59`, `lib/features/wallet/view/widgets/wallet_snapshot_card.dart:14-61`
  - Dashboard insufficient-funds dialogs route to `WalletScreen`. File References: `lib/features/dashboard/view/widgets/next_actions_list.dart:16-38`, `lib/features/dashboard/view/tabs/work_tab.dart:380-397`

## 1) Feature Map (Current Repo State)
- Primary feature files:
  - `WalletViewModel` manages wallet load state and withdrawal requests. File Reference: `lib/features/wallet/viewmodels/wallet_view_model.dart:9-117`
  - `WalletService` reads wallet views and writes `withdrawal_requests`. File Reference: `lib/features/wallet/services/wallet_service.dart:7-169`
  - `LedgerService` calls `process_payment_event_ledger`. File Reference: `lib/features/wallet/services/ledger_service.dart:5-164`
  - `WalletRepository` is a pass-through wrapper over `WalletService`. File Reference: `lib/features/wallet/data/wallet_repository.dart:6-27`
  - `WalletScreen` is the live wallet UI. File Reference: `lib/features/wallet/view/wallet_screen.dart:12-390`
  - `WalletDashboardScreen` is a second wallet UI with hard-coded data. File Reference: `lib/features/wallet/view/wallet_dashboard_screen.dart:8-519`
  - `WalletSnapshotCard` renders dashboard wallet totals. File Reference: `lib/features/wallet/view/widgets/wallet_snapshot_card.dart:11-103`
  - Wallet models map the SQL views. File References: `lib/features/wallet/models/wallet_balance_model.dart:1-27`, `lib/features/wallet/models/wallet_activity_model.dart:1-41`
- Direct dependencies:
  - `AccountGuardService` gates wallet withdrawal UX but does not replace RLS or RPC authorization. File Reference: `lib/core/services/account_guard_service.dart:15-67`
  - App-wide provider wiring creates `WalletViewModel` and `AccountGuardService`. File Reference: `lib/main.dart:205-214`
  - `MainNavigationScreen` routes the wallet tab to the mock wallet UI. File Reference: `lib/app/main_navigation_screen.dart:17-18`, `lib/app/main_navigation_screen.dart:42-52`
  - `ProfileScreen`, `NextActionsList`, and `WorkTab` route to the live wallet UI. File References: `lib/features/profile/view/profile_screen.dart:471-483`, `lib/features/dashboard/view/widgets/next_actions_list.dart:16-38`, `lib/features/dashboard/view/tabs/work_tab.dart:380-397`
  - `OverviewTab` preloads wallet state and shows the snapshot card. File Reference: `lib/features/dashboard/view/tabs/overview_tab.dart:24-31`, `lib/features/dashboard/view/tabs/overview_tab.dart:57-59`
  - `DashboardRepository` duplicates wallet balance reads. File Reference: `lib/features/dashboard/data/dashboard_repository.dart:534-576`
- Supabase touchpoints:
  - View `public.vw_wallet_balances_user`. File References: `lib/features/wallet/services/wallet_service.dart:31-45`, `lib/features/dashboard/data/dashboard_repository.dart:536-576`, `supabase/migrations/20260225_create_wallet_views.sql:14-77`
  - View `public.vw_wallet_activity_user`. File References: `lib/features/wallet/services/wallet_service.dart:12-29`, `supabase/migrations/20260225_create_wallet_views.sql:85-158`
  - Tables `public.accounts`, `public.journal_entries`, `public.ledger_lines`, `public.audit_logs`, `public.withdrawal_requests`. File References: `supabase/migrations/20260225_create_ledger_core_schema.sql:90-247`
  - RLS policies for the same ledger tables. File References: `supabase/migrations/20260225_create_ledger_rls_policies.sql:12-252`
  - RPC `public.process_payment_event_ledger(text,text,uuid,text,numeric,text,jsonb)`. File References: `lib/features/wallet/services/ledger_service.dart:21-87`, `supabase/migrations/20260224_restrict_process_payment_event_ledger_execute.sql:4-42`, `supabase/migrations/20260307_fix_ledger_event_type_enum.sql:572-1000`
  - Latest repo patch after the large RPC rewrite only changes task-request amount sourcing; it does not change the wallet withdrawal branch cited above. File Reference: `supabase/migrations/20260317000000_fix_task_request_amount_gross.sql:1-20`
  - Edge function `supabase/functions/qicard_webhook_handler` maps withdrawal PSP events to `withdrawal_complete` / `withdrawal_failed` and calls the ledger RPC. File References: `supabase/functions/qicard_webhook_handler/index.ts:152-169`, `supabase/functions/qicard_webhook_handler/index.ts:389-411`

## 2) Evidence Index (Ground Truth)
| FindingID | Claim | File Reference (path + line range) | Risk | Notes |
| --- | --- | --- | --- | --- |
| WAL-SEC-001 | Authenticated users can read platform-owned ledger rows through RLS | `supabase/migrations/20260225_create_ledger_rls_policies.sql:12-20`; `supabase/migrations/20260225_create_ledger_rls_policies.sql:110-121` | Critical | `owner_id IS NULL` exposes platform accounts and any ledger lines tied to them |
| WAL-SEC-002 | Clients can update their own `withdrawal_requests` rows directly and app code already uses that path | `supabase/migrations/20260225_create_ledger_rls_policies.sql:221-227`; `lib/features/wallet/services/wallet_service.dart:161-165` | Critical | Status is not server-owned today |
| WAL-SEC-003 | Raw backend errors are stored and rendered in the wallet UI | `lib/features/wallet/viewmodels/wallet_view_model.dart:48-50`; `lib/features/wallet/view/wallet_screen.dart:55-60` | High | Exposes SQL/RPC/policy text to end users |
| WAL-DATA-001 | `held_balance` logic is booking-only and does not scope to escrow-account lines or directions | `supabase/migrations/20260225_create_wallet_views.sql:56-74` | Critical | Can over-count, under-count, and ignore non-booking escrow |
| WAL-DATA-002 | Wallet balance sign rules do not match wallet journal directions, and the posted-status join still allows voided lines into the sum | `supabase/migrations/20260225_create_wallet_views.sql:34-54`; `supabase/migrations/20260307_fix_ledger_event_type_enum.sql:384-390`; `supabase/migrations/20260307_fix_ledger_event_type_enum.sql:537-541`; `supabase/migrations/20260307_fix_ledger_event_type_enum.sql:784-788`; `supabase/migrations/20260307_fix_ledger_event_type_enum.sql:987-991` | Critical | Displayed balances can drift from the ledger contract |
| WAL-DATA-003 | Completed withdrawals do not appear in wallet activity | `supabase/migrations/20260225_create_wallet_views.sql:89-100`; `supabase/migrations/20260307_fix_ledger_event_type_enum.sql:861-887` | High | Activity view only follows `user_available` lines; completion posts to `user_pending_withdrawal` |
| WAL-DATA-004 | Withdrawal creation is split across client insert + RPC, and the RPC balance check is not serialized per user/account | `lib/features/wallet/services/wallet_service.dart:72-121`; `supabase/migrations/20260307_fix_ledger_event_type_enum.sql:583-704` | Critical | Network timeouts or concurrent requests can desync state or oversubscribe balance |
| WAL-ARCH-001 | The app exposes two wallet entrypoints with different implementations | `lib/app/main_navigation_screen.dart:17-18`; `lib/app/main_navigation_screen.dart:42-52`; `lib/features/profile/view/profile_screen.dart:471-483`; `lib/features/wallet/view/wallet_dashboard_screen.dart:8-519`; `lib/features/wallet/view/wallet_screen.dart:12-390` | High | Bottom nav and pushed routes do not show the same feature |
| WAL-ARCH-002 | Wallet DI is self-constructed in the ViewModel and dashboard duplicates wallet reads outside the wallet module | `lib/features/wallet/viewmodels/wallet_view_model.dart:10-17`; `lib/main.dart:205-214`; `lib/features/dashboard/data/dashboard_repository.dart:534-576` | Medium | Weak test seams and read-path drift |
| WAL-QUAL-001 | The live wallet tab is a mock UI with hard-coded balances, dates, and no-op actions | `lib/features/wallet/view/wallet_dashboard_screen.dart:11-17`; `lib/features/wallet/view/wallet_dashboard_screen.dart:19-65`; `lib/features/wallet/view/wallet_dashboard_screen.dart:116-130`; `lib/features/wallet/view/wallet_dashboard_screen.dart:145-155` | High | User-facing behavior is fake on the tab route |
| WAL-QUAL-002 | “Add funds” CTAs route to a wallet screen that has no add-funds action; the mock tab has a top-up button with an empty callback | `lib/features/dashboard/view/widgets/next_actions_list.dart:20-38`; `lib/features/dashboard/view/tabs/work_tab.dart:380-397`; `lib/features/wallet/view/wallet_screen.dart:147-177`; `lib/features/wallet/view/wallet_dashboard_screen.dart:116-130` | Medium | Recovery path is a dead end |
| WAL-QUAL-003 | `withdrawal_failed` is rendered as money out even though the RPC credits `user_available` | `lib/features/wallet/view/wallet_screen.dart:219-229`; `supabase/migrations/20260307_fix_ledger_event_type_enum.sql:987-991` | Medium | Activity sign is wrong for returned funds |
| WAL-QUAL-004 | Wallet balance read failures are silently converted to zeros | `lib/features/wallet/services/wallet_service.dart:31-45`; `lib/features/dashboard/data/dashboard_repository.dart:542-575` | Medium | Broken backend state can look like a valid empty wallet |
| WAL-PERF-001 | Wallet data is loaded redundantly and whole-widget rebuild scope is broad | `lib/features/dashboard/view/tabs/overview_tab.dart:25-31`; `lib/features/wallet/view/wallet_screen.dart:21-25`; `lib/features/wallet/view/wallet_screen.dart:49-210`; `lib/features/wallet/view/wallet_screen.dart:368-369`; `lib/features/wallet/view/widgets/wallet_snapshot_card.dart:16-61`; `lib/features/wallet/viewmodels/wallet_view_model.dart:95-99` | Medium | Extra queries and unnecessary UI churn |
| WAL-TST-001 | Wallet-specific tests are missing | `test/integration_test/support/dashboard_env.dart:22-23`; `test/integration_test/support/dashboard_preflight.dart:29` | Medium | UNVERIFIED from file refs alone; repo search found wallet mentions only in support files. Missing files: `test/unit/wallet/**`, `test/widget/wallet/**`, `test/integration_test/wallet_*` |

## 3) Findings
### 3.1 Security (Highest Priority)
- `WAL-SEC-001` — File References: `supabase/migrations/20260225_create_ledger_rls_policies.sql:12-20`, `supabase/migrations/20260225_create_ledger_rls_policies.sql:110-121`. Impact: authenticated users can read platform-owned `accounts` and `ledger_lines` rows, which bypasses the wallet-view boundary and leaks platform cash / escrow / revenue ledger data. Exploit/Failure scenario: a signed-in user calls the public REST or RPC surface against `public.accounts` or `public.ledger_lines` and reads rows for `platform_cash`, `platform_escrow`, or `platform_revenue`.
- `WAL-SEC-002` — File References: `supabase/migrations/20260225_create_ledger_rls_policies.sql:221-227`, `lib/features/wallet/services/wallet_service.dart:161-165`. Impact: withdrawal request state is mutable from the client, so wallet settlement state is not server-owned. Exploit/Failure scenario: a client updates `status`, `failure_reason`, or gateway-related columns on its own `withdrawal_requests` row before webhook settlement or customer-support review.
- `WAL-SEC-003` — File References: `lib/features/wallet/viewmodels/wallet_view_model.dart:48-50`, `lib/features/wallet/view/wallet_screen.dart:55-60`. Impact: backend error text can be exposed directly to end users. Exploit/Failure scenario: an RLS error or RPC failure returns internal SQL / table / policy text that is rendered on the wallet screen.

### 3.2 Data Integrity
- `WAL-DATA-001` — File Reference: `supabase/migrations/20260225_create_wallet_views.sql:56-74`. Impact: `held_balance` is not a reliable wallet number. Exploit/Failure scenario: a booking escrow event is counted from every matching ledger line amount instead of the escrow-account movement only, while task-request and direct-offer escrow is ignored entirely.
- `WAL-DATA-002` — File References: `supabase/migrations/20260225_create_wallet_views.sql:34-54`, `supabase/migrations/20260225_create_wallet_views.sql:45-48`, `supabase/migrations/20260307_fix_ledger_event_type_enum.sql:384-390`, `supabase/migrations/20260307_fix_ledger_event_type_enum.sql:537-541`, `supabase/migrations/20260307_fix_ledger_event_type_enum.sql:784-788`, `supabase/migrations/20260307_fix_ledger_event_type_enum.sql:987-991`. Impact: `available_balance` and `pending_withdrawal_balance` can disagree with the ledger journal directions, and voided journal lines can still influence the sums. Exploit/Failure scenario: deposits, releases, refunds, or withdrawal failures credit `user_available`, but the view’s sign rules currently treat asset credits as negative.
- `WAL-DATA-003` — File References: `supabase/migrations/20260225_create_wallet_views.sql:89-100`, `supabase/migrations/20260307_fix_ledger_event_type_enum.sql:861-887`. Impact: wallet history is incomplete. Exploit/Failure scenario: the user sees a `withdrawal_request` activity row, but the later `withdrawal_complete` event never appears because the activity view only joins `user_available:%` lines and completion posts against `user_pending_withdrawal:%`.
- `WAL-DATA-004` — File References: `lib/features/wallet/services/wallet_service.dart:72-121`, `supabase/migrations/20260307_fix_ledger_event_type_enum.sql:583-704`. Impact: wallet write paths are not atomic and can race. Exploit/Failure scenario: the client inserts `withdrawal_requests`, then loses the RPC response and marks the request `failed`, or two concurrent requests both pass the available-balance check before either ledger journal is posted.

### 3.3 Architecture
- `WAL-ARCH-001` — File References: `lib/app/main_navigation_screen.dart:17-18`, `lib/app/main_navigation_screen.dart:42-52`, `lib/features/profile/view/profile_screen.dart:471-483`, `lib/features/wallet/view/wallet_dashboard_screen.dart:8-519`, `lib/features/wallet/view/wallet_screen.dart:12-390`. Impact: the app ships two wallet implementations with different behavior, copy, and data sources. Exploit/Failure scenario: the bottom-nav tab shows fake balances and dead actions, while profile/dashboard routes open the real provider-backed wallet screen.
- `WAL-ARCH-002` — File References: `lib/features/wallet/viewmodels/wallet_view_model.dart:10-17`, `lib/main.dart:205-214`, `lib/features/dashboard/data/dashboard_repository.dart:534-576`. Impact: dependency injection and read-path boundaries are weak. Exploit/Failure scenario: `WalletViewModel` constructs its own repository and guard service instead of receiving them, while the dashboard layer re-implements wallet balance reads rather than consuming wallet-owned state.

### 3.4 Code Quality
- `WAL-QUAL-001` — File References: `lib/features/wallet/view/wallet_dashboard_screen.dart:11-17`, `lib/features/wallet/view/wallet_dashboard_screen.dart:19-65`, `lib/features/wallet/view/wallet_dashboard_screen.dart:116-130`, `lib/features/wallet/view/wallet_dashboard_screen.dart:145-155`, `lib/features/wallet/view/wallet_dashboard_screen.dart:244-245`, `lib/features/wallet/view/wallet_dashboard_screen.dart:496-497`. Impact: the bottom-nav wallet route is user-facing demo code. Exploit/Failure scenario: users see stale 2023 sample transactions, dollar formatting, and buttons that do nothing.
- `WAL-QUAL-002` — File References: `lib/features/dashboard/view/widgets/next_actions_list.dart:20-38`, `lib/features/dashboard/view/tabs/work_tab.dart:380-397`, `lib/features/wallet/view/wallet_screen.dart:147-177`, `lib/features/wallet/view/wallet_dashboard_screen.dart:116-130`. Impact: the insufficient-funds recovery path is contradictory. Exploit/Failure scenario: dashboard prompts the user to “Add funds,” but the real wallet screen only supports withdrawal, while the mock tab exposes a “Top Up” button with an empty callback.
- `WAL-QUAL-003` — File References: `lib/features/wallet/view/wallet_screen.dart:219-229`, `supabase/migrations/20260307_fix_ledger_event_type_enum.sql:987-991`. Impact: wallet activity signs are wrong for at least one wallet-return event. Exploit/Failure scenario: `withdrawal_failed` credits funds back to `user_available`, but the UI does not treat it as a positive event and will render it like money leaving the wallet.
- `WAL-QUAL-004` — File References: `lib/features/wallet/services/wallet_service.dart:31-45`, `lib/features/dashboard/data/dashboard_repository.dart:542-575`. Impact: backend failures are hidden behind zero balances. Exploit/Failure scenario: a broken view, RLS policy, or network issue is surfaced to the user as a legitimate zero wallet instead of an actionable error state.

### 3.5 Performance
- `WAL-PERF-001` — File References: `lib/features/dashboard/view/tabs/overview_tab.dart:25-31`, `lib/features/wallet/view/wallet_screen.dart:21-25`, `lib/features/wallet/viewmodels/wallet_view_model.dart:95-99`, `lib/features/wallet/view/wallet_screen.dart:368-369`. Impact: the app issues redundant wallet reads during normal navigation and after successful withdrawals. Exploit/Failure scenario: overview preload fetches wallet data, opening the wallet screen fetches again, and a successful withdrawal fetches balance once in the ViewModel and again through `loadWallet()`.
- `WAL-PERF-002` — File References: `lib/features/wallet/view/wallet_screen.dart:49-210`, `lib/features/wallet/view/widgets/wallet_snapshot_card.dart:16-61`. Impact: rebuild scope is too broad. Exploit/Failure scenario: any `WalletViewModel` state change rebuilds the full wallet screen body and the dashboard wallet snapshot, even when only one small balance field changed.

### 3.6 Testing Gaps
- `WAL-TST-001` — File References: `test/integration_test/support/dashboard_env.dart:22-23`, `test/integration_test/support/dashboard_preflight.dart:29`. Impact: critical wallet flows have no verified feature-level regression coverage in the repository. Exploit/Failure scenario: SQL/RLS changes, wallet-route drift, or withdrawal lifecycle bugs can land without a wallet-specific unit, widget, or integration test failing. UNVERIFIED from file refs alone: missing files appear to include `test/unit/wallet/**`, `test/widget/wallet/**`, and `test/integration_test/wallet_*`.

## 4) Dead/Unused Code Candidates
- `lib/features/wallet/viewmodels/wallet_view_model.dart:57-79` — `loadMore()` is a candidate for dead code because `WalletScreen` has no scroll controller, no `NotificationListener`, and no visible call site for wallet paging. File References: `lib/features/wallet/view/wallet_screen.dart:64-209`, `lib/features/wallet/viewmodels/wallet_view_model.dart:57-79`. How to confirm: run `rg -n "loadMore\\(" lib/features/wallet lib/features/dashboard lib/features/profile`
- `lib/features/wallet/viewmodels/wallet_view_model.dart:114-117` — `clearError()` is a candidate for dead code because the wallet UI does not call it before or after rendering errors. File References: `lib/features/wallet/viewmodels/wallet_view_model.dart:114-117`, `lib/features/wallet/view/wallet_screen.dart:49-62`. How to confirm: run `rg -n "clearError\\(" lib`
- `lib/features/wallet/services/wallet_service.dart:126-141` — `getWithdrawalRequests()` is a candidate for dead code because no scoped UI or ViewModel consumes withdrawal history. File References: `lib/features/wallet/services/wallet_service.dart:126-141`, `lib/features/wallet/view/wallet_screen.dart:64-209`. How to confirm: run `rg -n "getWithdrawalRequests" lib`
- `lib/features/wallet/services/wallet_service.dart:143-167` — `cancelWithdrawalRequest()` is a candidate for dead code because no wallet screen exposes cancel controls. File References: `lib/features/wallet/services/wallet_service.dart:143-167`, `lib/features/wallet/view/wallet_screen.dart:64-209`. How to confirm: run `rg -n "cancelWithdrawalRequest" lib`
- `lib/features/dashboard/data/dashboard_repository.dart:536-576` — `fetchWalletBalances()` is a candidate for dead code because the dashboard snapshot already reads `WalletViewModel`, and no in-repo call site was found for this method. File References: `lib/features/dashboard/view/tabs/overview_tab.dart:24-31`, `lib/features/dashboard/view/tabs/overview_tab.dart:57-59`, `lib/features/dashboard/data/dashboard_repository.dart:536-576`. How to confirm: run `rg -n "fetchWalletBalances\\(" lib`

## 5) Duplicate Code Candidates
- Wallet balance fetching is duplicated between `lib/features/wallet/services/wallet_service.dart:31-45` and `lib/features/dashboard/data/dashboard_repository.dart:536-576`. Proposed shared abstraction: make `WalletRepository` the single read owner and inject it into both `WalletViewModel` and any dashboard adapter that truly needs direct wallet reads.
- Wallet UI is duplicated between `lib/features/wallet/view/wallet_screen.dart:32-389` and `lib/features/wallet/view/wallet_dashboard_screen.dart:72-519`. Proposed shared abstraction: keep one live `WalletScreen` and split reusable UI pieces into `view/widgets/` so all entrypoints render the same state.
- The repository layer is duplicated by its own service API: `lib/features/wallet/data/wallet_repository.dart:6-27` mirrors `lib/features/wallet/services/wallet_service.dart:12-123` without adding coordination. Proposed shared abstraction: either promote `WalletRepository` into a real orchestrator with injected read/write services or remove it and inject the services directly.

## 6) Refactor Plan (Exact Paths)
- Move the live wallet screen implementation:
  - From: `lib/features/wallet/view/wallet_screen.dart`
  - To: `lib/features/wallet/view/screens/wallet_screen.dart`
- Split the live wallet UI into focused widgets:
  - Create: `lib/features/wallet/view/widgets/wallet_balance_section.dart`
  - Create: `lib/features/wallet/view/widgets/wallet_activity_list.dart`
  - Create: `lib/features/wallet/view/widgets/request_withdrawal_sheet.dart`
- Retire the mock tab screen:
  - Delete: `lib/features/wallet/view/wallet_dashboard_screen.dart`
  - Migration strategy: keep a temporary one-line compat export at `lib/features/wallet/view/wallet_screen.dart` during import cleanup, then remove it after all imports move to `view/screens/wallet_screen.dart`
- Make wallet dependency injection explicit:
  - Keep path: `lib/features/wallet/data/wallet_repository.dart`
  - Refactor it into a real owner of wallet read/write orchestration
  - Create: `lib/features/wallet/services/wallet_read_service.dart`
  - Create: `lib/features/wallet/services/wallet_withdrawal_service.dart`
  - Update: `lib/features/wallet/viewmodels/wallet_view_model.dart` to receive `WalletRepository` and `AccountGuardService` via constructor injection
- Remove the dashboard duplicate read path:
  - Edit: `lib/features/dashboard/data/dashboard_repository.dart`
  - Delete method: `fetchWalletBalances()`
  - Consume injected wallet state instead through `WalletViewModel`
- Add wallet backend migrations after the latest repo migration prefix:
  - Create: `supabase/migrations/20260318000000_wallet_rls_and_views.sql`
  - Create: `supabase/migrations/20260318001000_wallet_withdrawal_request_rpc.sql`
  - Create: `supabase/migrations/20260318002000_wallet_activity_view_completion_fix.sql`
- Add missing wallet tests:
  - Create: `test/unit/wallet/wallet_view_model_test.dart`
  - Create: `test/unit/wallet/wallet_service_test.dart`
  - Create: `test/widget/wallet/wallet_screen_test.dart`
  - Create: `test/widget/wallet/wallet_snapshot_card_test.dart`
  - Create: `test/integration_test/wallet_withdrawal_flow_test.dart`

## 7) Fix Plan (Phases)
### Phase 1: Critical security & correctness
- Item 1. What to change: harden ledger RLS so authenticated users cannot read platform-owned `accounts` or `ledger_lines`, and remove direct client update rights on `withdrawal_requests.status`. Exact file(s) to edit/create: `supabase/migrations/20260318000000_wallet_rls_and_views.sql`. Acceptance criteria: direct authenticated reads of unrelated platform ledger rows fail; direct authenticated updates to `withdrawal_requests.status`, `failure_reason`, `gateway_payment_id`, and `gateway_request_id` fail; wallet views still return the current user’s rows.
- Item 2. What to change: fix `vw_wallet_balances_user` so it sums only posted journals, uses sign logic consistent with actual wallet ledger directions, and computes `held_balance` from escrow-specific lines across all supported related entity types. Exact file(s) to edit/create: `supabase/migrations/20260318000000_wallet_rls_and_views.sql`. Acceptance criteria: deposit/release/refund/withdrawal-failed events move balances in the expected direction; booking/task-request/direct-offer escrow affects `held_balance`; voided journals do not affect any wallet total.
- Item 3. What to change: move withdrawal request creation into one server-owned path that creates the request, locks funds, and transitions state atomically under serialization. Exact file(s) to edit/create: `supabase/migrations/20260318001000_wallet_withdrawal_request_rpc.sql`, `lib/features/wallet/services/wallet_withdrawal_service.dart`, `lib/features/wallet/services/ledger_service.dart`, `lib/features/wallet/data/wallet_repository.dart`, `lib/features/wallet/viewmodels/wallet_view_model.dart`. Acceptance criteria: the client no longer inserts into `withdrawal_requests` directly; two concurrent requests cannot overdraw the same balance; a client timeout cannot leave a successful ledger lock with a client-written `failed` status.
- Item 4. What to change: fix wallet activity semantics so completion/failure states appear correctly and signs match the actual money direction. Exact file(s) to edit/create: `supabase/migrations/20260318002000_wallet_activity_view_completion_fix.sql`, `lib/features/wallet/view/wallet_screen.dart` or `lib/features/wallet/view/screens/wallet_screen.dart`. Acceptance criteria: `withdrawal_complete` appears in activity history; `withdrawal_failed` renders as money returned; user-facing labels are explicit and in English.
- Item 5. What to change: sanitize wallet error output and stop silently converting backend failures to valid zero balances. Exact file(s) to edit/create: `lib/features/wallet/services/wallet_read_service.dart`, `lib/features/wallet/viewmodels/wallet_view_model.dart`, `lib/features/wallet/view/screens/wallet_screen.dart`, `lib/features/dashboard/data/dashboard_repository.dart` if still present. Acceptance criteria: wallet failures render user-safe copy; logs still retain diagnostic details; zero balances are only shown for real empty states.

### Phase 2: Refactor/structure
- Item 1. What to change: route every wallet entrypoint to one live wallet screen. Exact file(s) to edit/create: `lib/app/main_navigation_screen.dart`, `lib/features/profile/view/profile_screen.dart`, `lib/features/dashboard/view/widgets/next_actions_list.dart`, `lib/features/dashboard/view/tabs/work_tab.dart`, `lib/features/wallet/view/screens/wallet_screen.dart`. Acceptance criteria: bottom-nav, profile, and dashboard actions all open the same wallet UI and behavior.
- Item 2. What to change: split the live wallet screen into focused widgets and remove the mock screen. Exact file(s) to edit/create: `lib/features/wallet/view/screens/wallet_screen.dart`, `lib/features/wallet/view/widgets/wallet_balance_section.dart`, `lib/features/wallet/view/widgets/wallet_activity_list.dart`, `lib/features/wallet/view/widgets/request_withdrawal_sheet.dart`, delete `lib/features/wallet/view/wallet_dashboard_screen.dart`. Acceptance criteria: screen code is smaller, reusable, and the mock implementation is gone from production imports.
- Item 3. What to change: make wallet DI explicit and remove duplicated dashboard read logic. Exact file(s) to edit/create: `lib/main.dart`, `lib/features/wallet/data/wallet_repository.dart`, `lib/features/wallet/viewmodels/wallet_view_model.dart`, `lib/features/dashboard/data/dashboard_repository.dart`. Acceptance criteria: `WalletViewModel` receives dependencies from providers; dashboard no longer re-implements wallet SQL mapping.
- Item 4. What to change: remove or fully wire wallet dead-code candidates. Exact file(s) to edit/create: `lib/features/wallet/viewmodels/wallet_view_model.dart`, `lib/features/wallet/services/wallet_service.dart` or its replacements, `lib/features/dashboard/data/dashboard_repository.dart`. Acceptance criteria: no unused wallet paging/history/cancel API remains unless backed by a real UI flow.

### Phase 3: Tests
- Item 1. What to change: add unit coverage for wallet state transitions, sanitized errors, and withdrawal request orchestration. Exact file(s) to edit/create: `test/unit/wallet/wallet_view_model_test.dart`, `test/unit/wallet/wallet_service_test.dart`. Acceptance criteria: tests cover load success/error, withdrawal success/error, and sign/formatting behavior for returned funds.
- Item 2. What to change: add widget coverage for the live wallet screen and dashboard snapshot card. Exact file(s) to edit/create: `test/widget/wallet/wallet_screen_test.dart`, `test/widget/wallet/wallet_snapshot_card_test.dart`. Acceptance criteria: tests cover loading, empty, populated, error, and withdrawal form validation states.
- Item 3. What to change: add integration coverage for the wallet lifecycle. Exact file(s) to edit/create: `test/integration_test/wallet_withdrawal_flow_test.dart`. Acceptance criteria: tests cover request -> processing -> completion/failure, unified routing, and wallet activity updates.

### Phase 4: Polish/perf
- Item 1. What to change: narrow rebuild scope with `Selector` or smaller `Consumer` boundaries. Exact file(s) to edit/create: `lib/features/wallet/view/screens/wallet_screen.dart`, `lib/features/wallet/view/widgets/wallet_snapshot_card.dart`. Acceptance criteria: balance-only changes do not rebuild the full wallet activity list or unrelated dashboard sections.
- Item 2. What to change: remove redundant `loadWallet()` calls after successful withdrawal and align refresh behavior. Exact file(s) to edit/create: `lib/features/wallet/viewmodels/wallet_view_model.dart`, `lib/features/wallet/view/screens/wallet_screen.dart`, `lib/features/dashboard/view/tabs/overview_tab.dart`. Acceptance criteria: a successful withdrawal produces one balance refresh path, not two.
- Item 3. What to change: resolve the “Add funds” dead end by either implementing a verified funding path or rewriting the dashboard copy to match current product capability. Exact file(s) to edit/create: `lib/features/dashboard/view/widgets/next_actions_list.dart`, `lib/features/dashboard/view/tabs/work_tab.dart`, `lib/features/wallet/view/screens/wallet_screen.dart`. Acceptance criteria: every CTA leads to a real action and all UI strings remain English-only.

## 8) Verification Checklist
### Commands
- `flutter analyze`
- `flutter test test/unit/wallet/wallet_view_model_test.dart`
- `flutter test test/unit/wallet/wallet_service_test.dart`
- `flutter test test/widget/wallet/wallet_screen_test.dart`
- `flutter test test/widget/wallet/wallet_snapshot_card_test.dart`
- `flutter test test/integration_test/wallet_withdrawal_flow_test.dart`
- `rg -n "WalletDashboardScreen|wallet_dashboard_screen" lib test`
- `rg -n "getWithdrawalRequests|cancelWithdrawalRequest|fetchWalletBalances\\(" lib`
- `rg -n "withdrawal_requests_update_policy|accounts_select_policy|ledger_lines_select_policy" supabase/migrations`
- `rg -n "vw_wallet_balances_user|vw_wallet_activity_user" supabase/migrations`

### Manual Scenarios
- Open wallet from bottom navigation, profile, and dashboard insufficient-funds flow; verify all three open the same live screen.
- Trigger a deposit or admin credit on a test user; verify `available_balance` increases and wallet UI still formats currency as `IQD`.
- Trigger booking, task-request, and direct-offer escrow events; verify `held_balance` changes exactly once per escrow and returns to zero after release/refund.
- Submit a withdrawal request; verify `available_balance` decreases, `pending_withdrawal_balance` increases, and a wallet activity row is created.
- Simulate webhook success; verify `withdrawal_complete` appears in activity history and pending balance decreases.
- Simulate webhook failure; verify funds return to `available_balance` and the activity row renders as positive money returned.
- Force a backend error from wallet read or write paths; verify the UI shows safe English copy, not raw SQL or policy text.
- Repeat withdrawal requests concurrently from two sessions for the same user; verify the second request is rejected once funds are exhausted.

### Supabase/RLS Contract Checks
- Policy check: confirm `public.accounts` and `public.ledger_lines` no longer expose platform-owned rows to authenticated users except through wallet-specific views. Validate with `select * from pg_policies where schemaname = 'public' and tablename in ('accounts','ledger_lines');`
- Policy check: confirm authenticated users cannot directly update wallet settlement state on `public.withdrawal_requests`. Validate with `select * from pg_policies where schemaname = 'public' and tablename = 'withdrawal_requests';`
- View check: confirm `public.vw_wallet_balances_user` sums only posted journals and scopes `held_balance` correctly. Validate with `select pg_get_viewdef('public.vw_wallet_balances_user'::regclass, true);`
- View check: confirm `public.vw_wallet_activity_user` includes completion/failure lifecycle rows needed by the UI. Validate with `select pg_get_viewdef('public.vw_wallet_activity_user'::regclass, true);`
- RPC check: confirm the wallet write path is server-owned and serialized. Validate with `select pg_get_functiondef('public.process_payment_event_ledger(text,text,uuid,text,numeric,text,jsonb)'::regprocedure);` and by verifying the new withdrawal-request RPC/function definition.
- Webhook check: confirm server-side withdrawal settlement still maps PSP events to `withdrawal_complete` / `withdrawal_failed`. Validate with `supabase/functions/qicard_webhook_handler/index.ts:152-169` and an end-to-end webhook test.

## 9) Risks & Rollback Notes
- RLS hardening can break wallet reads if replacement policies are too narrow. Rollback steps: revert `supabase/migrations/20260318000000_wallet_rls_and_views.sql`, redeploy the previous policy set, and re-run direct wallet-read smoke tests.
- Wallet view fixes can change every displayed balance at once. Rollback steps: revert the wallet-view migration, capture before/after SQL samples for one affected user, and re-run wallet screen manual scenarios before reopening.
- Moving withdrawal creation to a server-owned path changes the client contract. Rollback steps: keep a temporary compatibility wrapper only if the old direct-insert path is still blocked from mutating final status fields.
- Removing `WalletDashboardScreen` changes a live navigation route. Rollback steps: restore the old import only if the live wallet screen is not stable on the wallet tab, and document that the tab will still show mock data until the real screen is fixed.
