# CodeGuard Review Report: Booking Repeat Slotless Booking

## Scope
- Change Type: HIGH
- Areas: MVVM / DB / RPC / payments / booking lifecycle
- Files Reviewed:
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/booking/viewmodels/booking_view_model.dart`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/core/services/qicard_payment_service.dart`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/booking/data/booking_repository.dart`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/functions/qicard_payment_create/index.ts`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/migrations/20260301_remove_booking_slot_dependency.sql`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/migrations/20260301_allow_multiple_slotless_bookings_per_client.sql`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/booking/booking_view_model_test.dart`

## Evidence Collected
- Commands run + results summary:
  - `flutter analyze lib/features/booking/viewmodels/booking_view_model.dart test/unit/booking/booking_view_model_test.dart`
    - Result: no issues found.
  - `flutter test test/unit/booking/booking_view_model_test.dart`
    - Result: all tests passed.
  - `flutter pub outdated`
    - Result: large dependency lag; `supabase_flutter 1.10.25 -> resolvable 2.12.0`, `google_fonts 6.3.3 -> resolvable 8.0.2`, `js` transitive package flagged discontinued.
  - `flutter pub upgrade --dry-run`
    - Result: 11 dependency changes possible without changing constraints; 26 packages newer than current constraints.
- Docs scanned:
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/DEVELOPER_GUIDE.md`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/SUPABASE_SETUP.md`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/MVP_ROADMAP.md`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/CODE_REVIEW.md`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/STRUCTURE.md`
- Live DB checks:
  - verified `public.idx_bookings_task_client_active` exists
  - verified `public.uq_bookings_active_task_client` no longer exists
  - verified `public.rpc_create_booking_draft_validated(uuid,text,text,jsonb)` no longer raises `BOOKING_ALREADY_EXISTS_FOR_CLIENT`
- Web freshness checks performed:
  - Official Supabase docs search currently shows Flutter examples on `supabase_flutter: ^2.0.0`, while this repo is still on `1.10.25`.
    - Source: `https://supabase.com/docs/guides/getting-started/tutorials/with-flutter`
  - Dart package tooling reports transitive `js` as discontinued and points to the official Dart discontinuation notice.
    - Source: `https://dart.dev/go/package-discontinue`

## Critical Issues (BLOCKERS)
- None.

## Warnings (Should Fix)
1) Dependency baseline is stale.
   - Suggestion:
     - Plan a separate upgrade track for `supabase_flutter`, `supabase`, `postgrest`, `gotrue`, `realtime_client`, and `google_fonts`.
     - Do not bundle that upgrade into this booking-rule change.
   - Owner:
     - `@Architect`

2) This rule change removes a domain uniqueness guard, so downstream UX should be reviewed for repeated active bookings on the same task.
   - Suggestion:
     - Verify list/detail screens, provider dashboards, and notifications still behave correctly when the same client has multiple active bookings against one booking task.
   - Owner:
     - `@Sentinel`

3) Changelog trail is incomplete for this migration scope.
   - Suggestion:
     - Add changelog and execution-log linkage.
   - Owner:
     - `@SlineDocs`

## Passed Checks
- ✅ MVVM boundary preserved: view model delegates to service, no direct Supabase call in the reviewed view-model path.
- ✅ Payment-create path still remains server-authoritative through the edge function and RPC.
- ✅ No client-side service-role or privilege escalation introduced by this change.
- ✅ Replacement DB index preserves lookup performance on `(task_id, client_id, created_at)` for active slotless bookings.
- ✅ Focused analyzer and unit test passed.

## Risk Notes
- Threat model highlights:
  - This is a booking/payment flow, so any DB rule removal is high-sensitivity.
  - The removed uniqueness was a business rule, not an authorization control. RLS posture is unchanged in this scope.
- Regression risks:
  - Provider/client UIs may now surface multiple active bookings for one task-client pair where only one was previously seen in practice.
  - Any downstream reporting job that assumed one active slotless booking per client-task pair should be rechecked.

## Dependency Status
- Outdated:
  - Yes. Notably `supabase_flutter`, `supabase`, `postgrest`, `gotrue`, `realtime_client`, `google_fonts`, `app_links`, `sign_in_with_apple`.
- Deprecated:
  - Transitive `js` package flagged discontinued by Dart tooling.
- Security advisories:
  - No booking-scope security advisory found that blocks this isolated rule change.
- Recommended upgrade plan:
  - Run a separate dependency modernization pass after this booking-rule change is validated in QA.

## Final Decision
- APPROVED ✅
- Next actions:
  1. Smoke-test repeated slotless booking creation on iPhone and Chrome.
  2. Run targeted QA for provider/client lists with multiple active bookings on the same task.
  3. Add changelog linkage for the migration.
