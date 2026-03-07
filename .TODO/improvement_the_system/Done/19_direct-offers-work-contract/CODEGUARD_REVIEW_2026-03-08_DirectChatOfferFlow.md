# CodeGuard Review Report: DirectChatOfferFlow

## Scope

- **Change Type:** HIGH (payments/wallet/escrow, RLS, triggers, cron)
- **Areas:** DB/SQL (migrations), MVVM (Flutter direct_offers feature), RLS, Security, Compatibility
- **Files Reviewed:**
  - SQL: `supabase/migrations/20260319000000_direct_offer_flow_harden.sql`, `20260319110000_direct_offer_guard_rls_ledger.sql`, `20260319120000_direct_offer_auto_release_cron.sql`
  - Flutter: `lib/features/direct_offers/` (model, service, viewmodel, view), `test/features/direct_offers/direct_offers_service_test.dart`
- **Plan Reference:** `.TODO/PLAN_DirectChatOfferFlow_2026-03-07_CRITIC.md`

---

## Evidence Collected

- **Commands run:**
  - `flutter analyze`: 3 issues in `test/services/repro_test.dart` (avoid_print) — **none in direct_offers**
  - `flutter test test/features/direct_offers/`: **All 3 tests passed** (role guards: client cannot cancelOffer, freelancer cannot payNow; state guard: markDelivered throws when !isActive)
  - `dart format --set-exit-if-changed lib/features/direct_offers/ test/features/direct_offers/`: **2 files reformatted** (service, test) — format was not applied before review
  - `flutter pub outdated`: see Dependency Status below
- **Docs scanned:** `Sline_everything/DEVELOPER_GUIDE/Direct_Offers_Feature.md`, `Sline_everything/SUPABASE_SETUP.md` §5.14 direct_offers, `Sline_everything/CODE_REVIEW.md`, plan CRITIC
- **Web freshness:** Not run for this review (scope limited to implementation evidence); recommended before release per CodeGuard protocol

---

## Risk Rating

| Area            | Rating   | Notes |
|-----------------|----------|--------|
| **Overall**     | HIGH     | Escrow, RLS, cron, fee-from-row — hard-gate review applied |
| **Security**    | MEDIUM   | RLS and triggers in place; fee immutability enabled (20260307_09) |
| **Performance** | LOW      | Batch getOffersByIds; cron FOR UPDATE SKIP LOCKED; optional index for cron query |
| **Compatibility**| LOW      | No deprecated APIs in direct_offers; supabase_flutter 1.x in use project-wide |

---

## Critical Issues (BLOCKERS)

**None.** No issues found that would halt the pipeline or block merge.

- RLS: disputes INSERT restricted to complainant as party to the direct_offer (or task); direct_offers policies unchanged and participant-scoped.
- Trigger: price/currency protected when not sent/unpaid; fee protected by existing immutability trigger (enabled in `20260307_09_enable_fee_locking.sql`).
- Fee tampering: `rpc_approve_delivery` and `run_auto_release_expired_direct_offers` read `fee_rate_applied_bps` from row; client cannot change it after set (immutability trigger).
- No service_role or secrets in client code; views use ViewModel/services only (no direct Supabase in view).

---

## Warnings (Should Fix)

1. **Format**
   - **Suggestion:** Run `dart format lib/features/direct_offers/ test/features/direct_offers/` and commit the result. Two files were reformatted during this review.
   - **Owner:** Implementer

2. **Developer guide sync**
   - **Suggestion:** Update `Sline_everything/DEVELOPER_GUIDE/Direct_Offers_Feature.md` to document `delivered_at`, `review_expires_at`, auto-release cron (`run_auto_release_expired_direct_offers`, hourly), and payment traceability columns (per Plan Phase 5).
   - **Owner:** @SlineDocs or implementer

3. **Analyzer (unrelated)**
   - **Suggestion:** Fix or remove `test/services/repro_test.dart` (3× avoid_print) so `flutter analyze` is clean project-wide.
   - **Owner:** Implementer

---

## Passed Checks

- **MVVM:** No direct Supabase in `DirectOfferDetailsScreen`; ViewModel uses `DirectOffersService` and `PaymentService`; service uses `AppLogger`.
- **SQL migrations:** Additive DDL with IF NOT EXISTS / DROP IF EXISTS; disputes `chk_dispute_entity` enforces exactly one of task_id or direct_offer_id; RLS disputes INSERT allows only party for direct_offer.
- **Trigger:** `fn_direct_offer_protect_price_currency` blocks UPDATE of price/currency when status/payment_status are not sent/unpaid.
- **Fee from row:** `rpc_approve_delivery` (direct_offer branch) and `run_auto_release_expired_direct_offers` pass `fee_rate_bps` from `direct_offers.fee_rate_applied_bps` (COALESCE to 1000) into `process_payment_event_ledger`; no client-supplied fee for release.
- **markDelivered:** Single UPDATE sets `status='delivered'`, `delivered_at`, `review_expires_at` (now + 3 days); cron can select on `review_expires_at < now()`.
- **Cron:** `run_auto_release_expired_direct_offers()` SECURITY DEFINER, `search_path = public`; uses `FOR UPDATE SKIP LOCKED`; idempotency key same shape as manual release; pg_cron hourly (`0 * * * *`); job name check avoids duplicate schedule.
- **Tests:** Role guards (client cannot cancelOffer, freelancer cannot payNow) and state guard (markDelivered when !isActive throws) pass with mocks.
- **Model:** `DirectOffer` includes currency, feeRateAppliedBps, payment_*, deliveredAt, reviewExpiresAt; fromJson/toJson aligned with DB.
- **Path/name validation:** File paths and class/method names match plan and references; no phantom docs in reviewed scope.

---

## Performance

- **N+1:** `getOffersByIds` batches by IDs; no N+1 in reviewed service flows.
- **Indexes:** Partial index `idx_direct_offers_processing` (accepted, unpaid, payment_request_id NOT NULL) for processing checkouts. Cron query (`status='delivered'`, `payment_status='held'`, `review_expires_at < now()`) has no dedicated index; volume is expected low and `FOR UPDATE SKIP LOCKED` limits lock contention. Optional later: partial index on (status, payment_status, review_expires_at) for cron if row count grows.
- **Cron load:** Hourly run; processes only expired rows; SKIP LOCKED avoids blocking; single transaction per batch — acceptable.

---

## Security

- **RLS:** direct_offers unchanged (participant SELECT/UPDATE). disputes INSERT: complainant must be auth.uid(); for direct_offer_id, EXISTS (direct_offers where client_id or freelancer_id = auth.uid()) — party-only dispute creation.
- **Trigger:** Price/currency cannot be changed after offer leaves sent/unpaid. Fee protected by `trg_protect_fee_rate_applied_direct_offers` (enabled in 20260307_09).
- **Fee tampering:** Release path uses only row-held fee; immutability trigger prevents client from changing fee after accept.
- **Auth:** RPC and service checks (client_id/freelancer_id vs current user); no service_role in client; cron runs as SECURITY DEFINER with controlled search_path.

---

## Compatibility

- **Dart/Flutter:** direct_offers code uses current patterns; no deprecated APIs in reviewed files. Minimum SDK per project unchanged.
- **Supabase client:** Calls match schema (direct_offers columns, `rpc_approve_delivery(entity_type, entity_id)`); realtime not used in this feature.
- **Dependencies:** supabase_flutter and others outdated (see below); no change in direct_offers code that depends on bleeding-edge versions.

---

## Verification Commands

| Command | Result |
|--------|--------|
| `flutter analyze` | 3 issues in `test/services/repro_test.dart` (avoid_print); **0 in direct_offers** |
| `flutter test test/features/direct_offers/` | 3/3 passed |
| `dart format --set-exit-if-changed lib/features/direct_offers/ test/features/direct_offers/` | 2 files changed (format applied) |
| Migrations present | 20260319000000, 20260319110000, 20260319120000 in `supabase/migrations/` |

**Suggested CI:** Run `flutter analyze`, `flutter test test/features/direct_offers/`, and `dart format --set-exit-if-changed .` (or scoped paths). Confirm migrations applied in target environment (e.g. `supabase db diff` or list applied migrations).

---

## Dependency Status

- **Outdated (direct):** app_links, file_picker, google_fonts, mime, rxdart, sign_in_with_apple, supabase_flutter; flutter_lints (dev). supabase_flutter 1.10.25 vs 2.12.0 — major jump; not required for this change.
- **Deprecated:** None identified in direct_offers code.
- **Security advisories:** Not checked this session; recommend running dependency audit and web search before release per CodeGuard freshness protocol.
- **Recommendation:** Schedule dependency upgrades (including supabase_flutter 2.x) in a dedicated change; keep this review scoped to Direct Chat Offer Flow implementation.

---

## Risk Notes

- **Threat model (from plan):** Fee tampering mitigated by fee-from-row + immutability trigger. Unauthorized cancel/release mitigated by role checks and RLS. Double webhook/recovery mitigated by idempotency in ledger.
- **Regression:** Old app versions that never set `review_expires_at` will not be auto-released (cron filters `review_expires_at IS NOT NULL`); documented in plan. No drop of columns or breaking RPC signature.

---

## Final Decision

**APPROVED**

- No blockers; security (RLS, trigger, fee-from-row, auth) and lifecycle (markDelivered timestamps, cron, rpc_approve_delivery) are correctly implemented.
- Address format (2 files) and, if desired, developer guide sync and repro_test.dart analyzer issues in follow-up.

**Next actions:**

1. Commit format changes for `lib/features/direct_offers/` and `test/features/direct_offers/` (or run format and commit).
2. Optionally: update `Sline_everything/DEVELOPER_GUIDE/Direct_Offers_Feature.md` with delivered_at, review_expires_at, cron, and payment columns.
3. Optionally: fix or remove `test/services/repro_test.dart` to clear `flutter analyze`.
4. Before release: run dependency freshness and security advisory check per CodeGuard protocol.
