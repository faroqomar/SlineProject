# CodeGuard Review Report: Full_Review

**Date:** 2026-03-02  
**Scope:** Full_Review (entire codebase: lib/, direct_offers, dashboard, wallet, booking, migrations)  
**Plan reference:** Plan Missing — Risk Elevated  
**Reviewer:** CodeGuard (SLineCodeGuard)

---

## Scope

- **Change Type:** HIGH (full codebase scan; payments, wallet, direct offers, RLS, migrations in scope)
- **Areas:** UI, MVVM, DB, RLS, Storage, Realtime, direct_offers, dashboard, wallet, booking, migrations
- **Files Reviewed:** lib/ (all features), supabase/migrations (33 files), supabase/functions (qicard_webhook_handler, qicard_payment_create_direct_offer, qicard_payment_recovery_direct_offer), .cursor rules, Sline_everything docs

---

## Evidence Collected

- **Commands run:**
  - `flutter analyze` — 2 issues (see Critical/Warnings).
  - `flutter pub outdated` — 7 direct + transitive outdated; 1 discontinued (js).
  - `flutter pub deps --style=compact` — captured dependency tree.
  - `flutter test` — 117 tests passed.
  - `dart format --set-exit-if-changed .` — 47 files would change (format drift).
- **Docs scanned:** Sline_everything/DEVELOPER_GUIDE.md, SUPABASE_SETUP.md, CODE_REVIEW.md, STRUCTURE.md, MVP_ROADMAP.md, .cursor/PROJECT_CONTEXT.md, .cursor/rules/project-rules.mdc.
- **Codebase scans:** Grep for Supabase in views, service_role/secrets, Consumer/watch/read usage, ListView patterns, .from()/.rpc() in services, dispose/StreamSubscription in viewmodels, RLS policy files for direct_offers and ledger.
- **Web freshness:** Not run this session; recommend checking Dart/Flutter and Supabase security advisories and deprecation notices for supabase_flutter 2.x and dart:html → package:web.

---

## 1. Performance

### N+1 risks

- **Dashboard:** No N+1. `DashboardRepository.fetchWorkItems()` uses a single `vw_unified_work_items` query, a single `_fetchDirectOffers()` call, and batch profile enrichment via `_enrichWithProfiles()` / `ProfileSummaryService.fetchByIds(ids)` (single RPC).  
  **Files:** `lib/features/dashboard/data/dashboard_repository.dart` (lines 69–176, 136–176).
- **Direct offers:** Fetched in one query by client_id/freelancer_id; merged with unified work items. No per-item DB calls in the loop.
- **Other services:** `.from()` / `.rpc()` calls are in services/repositories, not inside loops over list items; no N+1 pattern identified in task_requests, message, wallet, or booking services.

### Rebuild storms

- Views use `Consumer<>` / `context.watch<>` / `context.read<>` appropriately across dashboard, chat, booking, profile, and other features. No broad `context.watch` on large trees without Selector/Consumer granularity identified; list UIs use `ListView.builder` / `SliverList` / `ListView.separated` where lists are dynamic (e.g. work_tab, messages_screen, bookings_list_screen, favorites, notifications).  
- A few places use `ListView(children: ...)` for small or static lists (e.g. overview_tab, work_tab section headers, categories_screen, wallet_screen empty state). Acceptable if item count is bounded.

### Heavy queries

- Dashboard loads work items, activity feed, bookings, inbox, pending items, and management data in parallel via `Future.wait([...])` in `DashboardViewModel._loadData()`. Counters then fetched sequentially after work items (dependent). No unbounded select(); views use `vw_unified_work_items` and RPCs with filters.  
  **File:** `lib/features/dashboard/viewmodels/dashboard_view_model.dart` (lines 355–438).
- Wallet uses `vw_wallet_activity_user` and `vw_wallet_balances_user` (user-scoped views). Ledger writes go through `process_payment_event_ledger` RPC with idempotency.

### Memory / lifecycle

- **ChatViewModel:** Disposes `_msgSub` and `_convoSub` in `dispose()` and on resubscribe.  
- **AuthViewModel:** Disposes `_authSubscription` in `dispose()`.  
- **SearchViewModel:** Cancels `_debounceTimer` in `dispose()`.  
- No obvious controller/stream leaks identified in the reviewed viewmodels.

**Passed:** Batch profile fetch, parallel dashboard load, lazy list builders where needed, subscription cancellation in key viewmodels.

---

## 2. Security

### RLS assumptions

- **direct_offers:** RLS enabled; policies: SELECT (client_id or freelancer_id = auth.uid()), INSERT (freelancer_id = auth.uid() and conversation participant), UPDATE (client or freelancer), DELETE (false). Guard trigger `fn_direct_offer_guard()` enforces status/payment_status lifecycle (e.g. active only with payment_status = held).  
  **File:** `supabase/migrations/20260303_direct_offers_table_rls_trigger.sql`.
- **Ledger:** `process_payment_event_ledger` is SECURITY DEFINER; actor taken from `auth.uid()` (not client input). Idempotency and currency checks present.  
  **File:** `supabase/migrations/20260307_fix_ledger_event_type_enum.sql` (and related ledger migrations).
- **Wallet views:** Documentation states RLS on ledger tables and user-scoped views; client uses anon key only.

### Secrets handling

- **Client:** Only anon key in `lib/core/services/supabase_config.dart`; commented as safe for client use with RLS. No `service_role` or other privileged keys in lib/.  
- **Edge functions:** Admin client created via `createAdminClient()` (service role server-side only). QiCard webhook uses `QICARD_RSA_PUBLIC_KEY_PEM` from env; `QICARD_ALLOW_UNSIGNED_LOCAL_DEV` for local dev only.  
  **Files:** `supabase/functions/qicard_webhook_handler/index.ts`, `supabase/functions/_shared/bookin_payment.ts`.

### Least privilege

- direct_offers INSERT restricted to freelancer and conversation participant; UPDATE to client/freelancer only; DELETE disabled.  
- Direct offer payment creation edge function validates `offer.client_id === auth.user.id` before creating payment.  
  **File:** `supabase/functions/qicard_payment_create_direct_offer/index.ts` (lines 71–76).

### Storage

- Docs: avatars, task-images, chat-attachments private; signed URLs at render time; portfolio public. No raw storage URLs stored in DB pattern violation identified in scanned code.

### BLOCKER / HIGH (Security-related)

- **None.** No RLS bypass, no service_role in client, no secret leakage in code. One **MVVM/architecture** BLOCKER is listed below (View layer Supabase access).

---

## 3. Compatibility

### Dependency freshness

- **flutter pub outdated** (summary):
  - **Direct:** app_links 3.5.1 → 7.0.0, file_picker 8.3.7 → 10.3.10, google_fonts 6.3.3 → 8.0.2, mime 1.0.6 → 2.0.0, rxdart 0.27.7 → 0.28.0, sign_in_with_apple 5.0.0 → 7.0.1, **supabase_flutter 1.10.25 → 2.12.0**.
  - **Transitive:** functions_client, gotrue, postgrest, realtime_client, storage_client, supabase (JS), etc. locked to older versions by supabase_flutter 1.x.
  - **Discontinued:** `js` (dart.dev/go/package-discontinue) — transitive via Supabase/plugins.
- **flutter pub deps:** Dart SDK 3.10.8, Flutter SDK 3.38.9; dependency tree consistent with pubspec.lock.

### Deprecations

- **dart:html** in `lib/core/utils/web_url_utils_web.dart` (line 1). Analyzer reports:
  - `deprecated_member_use`: 'dart:html' is deprecated; use package:web and dart:js_interop instead.
  - `avoid_web_libraries_in_flutter`: Don't use web-only libraries outside Flutter web plugins.  
  **File:** `lib/core/utils/web_url_utils_web.dart` (import and usage of `html.window`).

### Supabase / Flutter breaking changes

- Major upgrade path to supabase_flutter 2.x will involve API and possibly auth/realtime changes; not validated in this review. Recommend checking official migration guide and running tests after upgrade.
- dart:html deprecation will require moving to `package:web` / `dart:js_interop` for web-only URL cleanup (e.g. `clearPaymentReturnParamsFromUrl()`).

---

## 4. Risk Rating

- **Overall:** **MEDIUM–HIGH** (due to one MVVM BLOCKER, analyzer issues, and dependency/format drift).
- **BLOCKERs:**
  1. **MVVM violation — View uses Supabase directly.**  
     **File:** `lib/features/direct_offers/view/direct_offer_details_screen.dart` (line 40).  
     **Issue:** `currentUserId: Supabase.instance.client.auth.currentUser?.id` is used in the View layer when creating `DirectOfferDetailsViewModel`. Project rules require views to never call Supabase; data must come from ViewModel or injected provider.  
     **Risk:** Architecture drift, harder testing, and inconsistent pattern with rest of app.  
     **Fix:** Obtain current user id from a provider (e.g. AuthViewModel or a dedicated auth provider) via `context.read<>()` and pass it into the ViewModel, or have the ViewModel resolve current user from an injected auth/repository dependency.
  2. **Analyzer (compatibility/lint):** Two info-level issues in `lib/core/utils/web_url_utils_web.dart` (dart:html deprecated, avoid_web_libraries_in_flutter). Must be resolved for a clean analyze and future SDK compatibility.

- **Warnings (should fix):**
  - **Format drift:** 47 files not formatted (`dart format --set-exit-if-changed .` failed). Recommend running `dart format .` and committing.
  - **Outdated packages:** Plan upgrades for supabase_flutter and other direct deps; track discontinued `js` replacement when moving to Supabase 2.x.

---

## 5. Verification Commands

Run and ensure passing before merge:

```bash
flutter analyze
flutter test
dart format --set-exit-if-changed .
```

Recommended for HIGH-risk flows (payments, wallet, direct offers):

- **RLS:** Manually or via integration tests verify: (1) direct_offers SELECT/INSERT/UPDATE only for participant; (2) ledger RPC cannot be called with spoofed actor; (3) wallet views return only current user’s data.
- **Security:** Confirm no `service_role` or other secrets in client bundle (e.g. grep or build audit).
- **Regression:** After fixing the direct_offer_details_screen MVVM violation, run `flutter test` and any direct-offer or payment widget/unit tests.

---

## 6. Pipeline Gate

**Pipeline gate: BLOCK**

Fix first (in order):

1. **MVVM:** Remove direct Supabase usage from `lib/features/direct_offers/view/direct_offer_details_screen.dart`. Provide `currentUserId` via ViewModel or `context.read<AuthViewModel>()` (or equivalent) and pass into `DirectOfferDetailsViewModel`.
2. **Analyzer:** Replace `dart:html` in `lib/core/utils/web_url_utils_web.dart` with `package:web` / `dart:js_interop` (or equivalent) so that `flutter analyze` has zero issues and web-only usage is correctly scoped.
3. (Optional but recommended) Run `dart format .` and commit so that `dart format --set-exit-if-changed .` passes in CI.

Until (1) and (2) are done, treat the pipeline as **BLOCKED** for this full review. After fixes, re-run `flutter analyze` and `flutter test` and re-evaluate for **APPROVED**.

---

## 7. Evidence: Key Files / Scans Validated

| Area              | Files / scan                                                                 |
|-----------------------------------------------------------------------------------|
| MVVM violation    | `lib/features/direct_offers/view/direct_offer_details_screen.dart` (line 40) |
| Deprecation       | `lib/core/utils/web_url_utils_web.dart` (import dart:html)                   |
| Supabase config   | `lib/core/services/supabase_config.dart` (anon key only; no service_role)     |
| Dashboard data    | `lib/features/dashboard/data/dashboard_repository.dart` (batch profiles)     |
| Dashboard load    | `lib/features/dashboard/viewmodels/dashboard_view_model.dart` (Future.wait)  |
| RLS direct_offers | `supabase/migrations/20260303_direct_offers_table_rls_trigger.sql`           |
| Ledger RPC        | `supabase/migrations/20260307_fix_ledger_event_type_enum.sql` (auth.uid())   |
| Edge auth         | `supabase/functions/qicard_payment_create_direct_offer/index.ts` (client_id)  |
| Webhook secrets   | `supabase/functions/qicard_webhook_handler/index.ts` (env PEM, no key in code)|
| ViewModels dispose| `lib/features/chat/viewmodels/chat_view_model.dart`, auth, search            |
| List building     | ListView.builder / SliverList / ListView.separated in work_tab, messages, etc.|
| Tests             | `flutter test` → 117 passed                                                  |
| Analyzer          | `flutter analyze` → 2 issues (web_url_utils_web.dart)                         |
| Dependencies      | `flutter pub outdated` output cited above                                    |

---

## Final Decision

- **APPROVED:** No  
- **BLOCKED:** Yes — due to MVVM violation in `direct_offer_details_screen.dart` and analyzer issues in `web_url_utils_web.dart`.

**Next actions:**

1. Fix `DirectOfferDetailsScreen` to obtain `currentUserId` from ViewModel or provider; remove `Supabase.instance.client` from the view.
2. Update `web_url_utils_web.dart` to remove `dart:html` and use recommended web APIs so `flutter analyze` is clean.
3. Re-run `flutter analyze` and `flutter test`; then pipeline gate can be set to **APPROVED** for this review scope.
