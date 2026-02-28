# 📌 Plan: Bookin Remediation

## 1) Goal

- Goal: Secure, stabilize, and de-risk the Bookin flow across slot selection, booking draft creation, QiCard payment, webhook/recovery handling, booking state transitions, and direct side effects.
- Why: Current repo evidence shows critical payment/security exposure in the client, incomplete trust boundaries around webhook/recovery, integrity risks in booking transitions, and architecture drift in the booking service and view model stack.
- Result: A production-safe booking flow where privileged payment operations are server-side only, booking writes are validated/idempotent, UI state is isolated by flow, and the feature has contract, QA, rollback, and docs coverage.

## 2) Scope

### In-Scope

- `lib/features/booking/**`
- Direct booking dependencies only:
  - `lib/core/services/payment_service.dart`
  - `lib/core/services/demo_payment_service.dart`
  - `lib/core/services/qicard_payment_service.dart`
  - `lib/features/wallet/services/ledger_service.dart`
  - `lib/features/notifications/services/notification_service.dart`
  - `lib/features/chat/data/chat_repository.dart`
  - `supabase/functions/qicard_webhook_handler/index.ts`
  - `supabase/migrations/20260224_restrict_process_payment_event_ledger_execute.sql`
  - `supabase/migrations/20260225_create_process_payment_event_ledger_rpc.sql`
- Booking-related docs and setup references:
  - `Sline_everything/DEVELOPER_GUIDE.md`
  - `Sline_everything/SUPABASE_SETUP.md`
  - `Sline_everything/MVP_ROADMAP.md`
  - `Sline_everything/ARCHITECTURE_ANALYSIS.md`
  - `Sline_everything/CODE_REVIEW.md`
  - `Sline_everything/STRUCTURE.md`
- Existing audit baseline:
  - `.TODO/Bookin.TODO.md`

### Out-of-Scope

- Unrelated task, profile, auth, or dashboard refactors except where booking directly depends on them.
- Full wallet/ledger redesign outside the booking touchpoints already used by Bookin.
- Full notifications feature redesign outside the booking-triggered notification paths.
- Any destructive schema rename/drop intended only to make docs match code.
- Production rollout itself; this plan stops at an execution-ready remediation plan and verification gates.

## 3) Evidence & Findings (From Scan)

### Existing

- Booking is a feature-level MVVM module under `lib/features/booking/` with service, repository, model, viewmodel, and UI layers documented in `Sline_everything/DEVELOPER_GUIDE.md`.
- Docs define intended booking protections:
  - slot overlap guard
  - booking status guard trigger
  - party-scoped booking RLS
  - pay-first booking flow with escrow hold
- Current code confirms live booking entry points and dependency graph:
  - navigation and provider wiring in `lib/main.dart`
  - bottom-nav entry in `lib/app/main_navigation_screen.dart`
  - booking service/repository/viewmodel/UI flow in `lib/features/booking/**`
  - QiCard integration in `lib/core/services/qicard_payment_service.dart`
  - webhook/RPC path in `supabase/functions/qicard_webhook_handler/index.ts` and `supabase/migrations/20260225_create_process_payment_event_ledger_rpc.sql`
- Existing verified repo findings in `.TODO/Bookin.TODO.md` show:
  - client-side QiCard credentials and direct Basic Auth gateway calls
  - client-triggered webhook recovery path
  - fail-open signature behavior if webhook key config is missing
  - duplicate delivery write
  - non-atomic decline/refund flow
  - shared loading/error state contention in booking tabs
  - missing booking widget and edge-function tests
- Current repo search confirms `PaymentMethodScreen` has no call sites outside its own declaration, making it a strong legacy/unused flow candidate.

### Missing

- Live Supabase scan evidence is missing in this session because `@mcp:supabase-mcp-server:` is not available here. Live confirmation of tables, columns, enums, triggers, indexes, RLS policies, storage policies, and deployed edge functions is still required before implementation.
- Local SQL coverage for booking source-of-truth objects is incomplete in the repo snapshot:
  - no local migration files defining `public.bookings`
  - no local migration files defining `public.availability_slots`
  - no local migration files defining `public.notifications`
- No booking widget tests exist for:
  - slot selection and booking sheet flow
  - payment checkout UI states
  - payment WebView trust checks
  - booking details action gating
  - client/provider tab separation
- No repo-local tests exist for:
  - `supabase/functions/qicard_webhook_handler/index.ts`
  - any dedicated booking payment recovery function

### Conflicts / Risks (docs vs code vs live DB drift, naming mismatches, security/migration risks)

- Docs describe RLS and DB guards as the booking authority, but current Flutter code still performs privileged payment gateway operations directly in the client. This is an immediate security boundary violation.
- Docs describe a pay-first escrow flow, but the current implementation uses a mixed trust model:
  - client creates booking drafts
  - client opens gateway form
  - client can call a webhook-adjacent recovery endpoint
  - webhook uses service-role execution for ledger mutation
- Booking status naming is inconsistent across docs/code/SQL:
  - docs show older states such as `in_progress`
  - current code maps `in_progress` to `active`
  - setup docs include expanded states such as `delivered`, `refunded`, `expired_unanswered`
- Booking amount schema is inconsistent across artifacts:
  - app code uses `price`
  - ledger SQL references `amount_gross`
  - live DB confirmation is missing
- Notifications are documented as an app table under RLS, but current booking flow inserts cross-user notifications from the client. If live RLS is permissive, this is a spoofing risk; if strict, booking side effects can silently fail.
- Local docs are intent, not proof. Until Phase 1.0 live scan is completed, any DB-facing remediation must remain additive-first and reversible.

## 4) System Impact Map

- UI:
  - `lib/features/booking/view/availability_screen.dart`
  - `lib/features/booking/view/booking_sheet.dart`
  - `lib/features/booking/view/payment_checkout_screen.dart`
  - `lib/features/booking/view/payment_webview_screen.dart`
  - `lib/features/booking/view/bookings_list_screen.dart`
  - `lib/features/booking/view/booking_details_screen.dart`
- MVVM/App Logic:
  - `lib/features/booking/viewmodels/booking_view_model.dart`
  - `lib/features/booking/data/booking_repository.dart`
  - `lib/features/booking/services/booking_service.dart`
  - `lib/core/services/qicard_payment_service.dart`
- Database:
  - `bookings`
  - `availability_slots`
  - `notifications`
  - `process_payment_event_ledger`
- RLS/Security:
  - bookings/slots/notifications policies
  - webhook signature validation
  - service-role boundaries in edge functions
  - booking insert/update authorization and transition guards
- Realtime/Notifications (if any):
  - booking-triggered notification writes
  - notification table visibility/read status
- Storage:
  - No direct booking storage path observed in the audited code; verify none is introduced by remediation.
- Observability (if any):
  - payment correlation across booking draft, QiCard create-payment, WebView callback, recovery, webhook, ledger hold, and booking state update
- Compatibility & Migration:
  - additive-first DB changes only
  - compatibility window for legacy booking rows/statuses if schema or contract changes
  - route compatibility if `PaymentMethodScreen` is removed
- Contracts:
  - Flutter booking payloads
  - edge-function request/response bodies
  - RPC inputs/outputs
  - booking row shapes consumed by models/viewmodels/widgets

---

# ✅ Execution Phases (Checklist)

## Phase 0: Preconditions & Gates

> Primary: @Sentinel

### 0.1 Spec Lock

- [ ] (@Sentinel) Freeze the measurable acceptance and non-regression list using `.TODO/Bookin.TODO.md` as the audit baseline for security, integrity, architecture, performance, and testing.
- [ ] (@Architect) Confirm the exact Bookin entry points, direct dependency boundaries, and screens/routes that remain in scope: `lib/main.dart`, `lib/app/main_navigation_screen.dart`, `lib/features/booking/**`, `lib/core/services/qicard_payment_service.dart`, `lib/features/wallet/services/ledger_service.dart`, `lib/features/notifications/services/notification_service.dart`, `lib/features/chat/data/chat_repository.dart`, `supabase/functions/qicard_webhook_handler/index.ts`.
- **Verify (@Sentinel):** A single scope note exists in `.TODO/` and every implementation task maps back to a verified finding or required dependency.

### 0.2 Threat Model (If sensitive/high-risk)

- [ ] (@ThreatModeler) Create `.TODO/THREATMODEL_Bookin_2026-02-28.md` covering credential extraction, forged webhook/recovery requests, replay/idempotency abuse, tampered price/provider/slot payloads, cross-user notification abuse, WebView host spoofing, stale booking actions, and PII/log redaction.
- [ ] (@ThreatModeler) Define negative checks for unsigned webhook payloads, client-owned booking mismatch during recovery, untrusted callback hosts, double delivery submission, duplicate refund attempts, and arbitrary notification inserts.
- **Verify (@Sentinel):** Every threat has a testable negative case and at least one prevention control mapped into Phases 1-4.

### 0.3 Contracts (If payloads change)

- [ ] (@APIContract) Create `.TODO/CONTRACT_Bookin_Payment_2026-02-28.md` covering Flutter -> edge function -> QiCard -> webhook -> RPC -> booking row shape transitions.
- [ ] (@APIContract) Lock the payload contracts for:
  - server-side payment creation
  - payment status lookup
  - payment recovery
  - atomic decline/refund
  - booking list/detail selects used by `BookingModel`
- **Verify (@Sentinel):** Contract files specify required fields, nullability, auth context, and error shapes that match the schema and UI needs.

### 0.4 Migration Plan (If schema/data changes)

- [ ] (@DataMigration) Create `.TODO/MIGRATION_Bookin_2026-02-28.md` with introduce/backfill/enforce sequencing, compatibility window, and rollback strategy for any new booking/payment RPC, trigger, column, or index.
- [ ] (@DataMigration) Include explicit reconciliation checks for `price` vs `amount_gross`, booking status enum values, and any required backfill for legacy booking rows.
- **Verify (@Sentinel):** Migration steps are additive-first, reversible, and safe to run before app rollout.

### 0.5 Feature Flag/Rollout (If risky)

- [ ] (@Architect) Define a low-risk rollout toggle strategy for switching the client from direct QiCard gateway calls to server-side proxy/recovery endpoints.
- [ ] (@Observability) Define alert/telemetry criteria for rollback triggers: webhook signature failures, booking hold timeout rate, payment recovery failures, duplicate transition attempts.
- **Verify (@Sentinel):** Emergency disable path is documented for payment initiation, payment recovery, and legacy route fallback.

---

## Phase 1: Database & Security (If applicable)

> Primary: @Supabase_Ops

### 1.0 Live Supabase Confirmation (MANDATORY)

- [ ] (@Supabase_Ops) Re-scan via `@mcp:supabase-mcp-server:` for the touched objects: `bookings`, `availability_slots`, `notifications`, `process_payment_event_ledger`, booking-related enums, booking triggers, indexes, storage policies, and deployed edge functions.
- [ ] (@Supabase_Ops) Confirm whether live DB reality matches docs for:
  - booking status enum values
  - `payment_status` column presence
  - `price` and/or `amount_gross`
  - unique partial index on active slot booking
  - booking guard trigger
  - notifications RLS
  - execute grants on booking/payment RPCs
- **Verify (@Sentinel):** Drift between docs, repo SQL, and live DB is captured in `.TODO/` before any migration or app-layer change begins.

### 1.1 Schema (Additive-first)

- [ ] (@Supabase_Ops) Introduce additive booking/payment schema changes only if Phase 1.0 proves they are required, with exact migration files under `supabase/migrations/<timestamp>_*.sql`.
- [ ] (@Supabase_Ops) Add or verify indexes aligned to current booking queries and RLS filters, especially client/provider booking lists and active-slot uniqueness.
- [ ] (@DataMigration) Prepare additive migration paths for any contract fields needed to replace freeform note metadata or unify booking amount columns.
- **Verify (@Sentinel):** No schema change requires a destructive rename/drop to ship the fix set.

### 1.2 RLS

- [ ] (@Supabase_Ops) Verify live policies for `bookings`, `availability_slots`, and `notifications` against the intended rules documented in `Sline_everything/SUPABASE_SETUP.md` and `Sline_everything/DEVELOPER_GUIDE.md`.
- [ ] (@Supabase_Ops) Create `.TODO/RLS_Bookin_2026-02-28.md` with a matrix for client, provider, non-party authenticated user, and service role across booking draft creation, booking reads, booking status changes, slot creation, notification insert/read, and payment recovery.
- [ ] (@ThreatModeler) Require that cross-user notification creation is either removed from the client path or proven safe by RLS and server-side constraints.
- **Verify (@Sentinel):** Positive party access passes and non-party access fails for every touched table and RPC.

### 1.3 Triggers/RPC (If needed)

- [ ] (@Supabase_Ops) Add or harden server-side primitives for the critical transitions:
  - validated booking draft creation
  - atomic decline/refund
  - payment recovery ownership/status check
  - webhook idempotency enforcement
- [ ] (@APIContract) Define the request/response shapes for any new RPC or edge-function contracts before implementation begins.
- [ ] (@ThreatModeler) Require fail-closed behavior for unsigned QiCard webhook payloads outside explicit local-dev mode.
- **Verify (@Sentinel):** Booking/payment state rules are enforced server-side even if the client is tampered with.

### 1.4 Migration Execution (If needed)

- [ ] (@DataMigration) Execute introduce/backfill/enforce steps in the order defined by `.TODO/MIGRATION_Bookin_2026-02-28.md`.
- [ ] (@Supabase_Ops) Validate post-migration query plans and access behavior for booking list/detail/status transitions.
- **Verify (@Sentinel):** Booking creation, payment hold, refund, and status transitions work against migrated schema without breaking older rows.

---

## Phase 2: App Layer (MVVM)

> Primary: @Architect

### 2.1 Models & Contract Compliance

- [ ] (@Architect) Align `lib/features/booking/models/booking_model.dart` with the locked booking contract:
  - remove the zero-UUID masking fallback for null `slot_id`
  - align status mapping with the confirmed live enum set
  - align amount mapping with the confirmed schema
  - ensure required fields used by booking list/detail/checkout are present
- [ ] (@APIContract) Define and enforce one canonical booking row/select shape for:
  - booking list
  - booking detail
  - post-action refresh
- **Verify (@Sentinel):** Types, nullability, and booking status semantics match the contract and live schema.

### 2.2 Services/Repositories

- [ ] (@Architect) Remove privileged QiCard gateway calls from `lib/core/services/qicard_payment_service.dart` and replace them with authenticated calls to server-side endpoints such as:
  - `supabase/functions/qicard_payment_proxy/index.ts`
  - `supabase/functions/qicard_payment_recovery/index.ts`
- [ ] (@Architect) Refactor booking orchestration so data access, notification dispatch, and payment/refund orchestration are not all hidden inside `lib/features/booking/services/booking_service.dart`.
- [ ] (@Architect) Introduce service splits or a facade-compatible extraction path:
  - `lib/features/booking/services/booking_query_service.dart`
  - `lib/features/booking/services/booking_command_service.dart`
  - `lib/features/booking/services/booking_payment_service.dart`
  - `lib/features/booking/services/booking_notification_service.dart`
- [ ] (@Architect) Ensure every booking query/select used after an action returns a shape consistent with the model contract, including slot schedule fields needed for UI refresh.
- [ ] (@Architect) Remove or isolate client-side notification writes from core booking success/failure semantics.
- **Verify (@Sentinel):** No direct UI -> Supabase calls exist, no client-side privileged payment gateway operations remain, and service boundaries are testable.

### 2.3 ViewModels

- [ ] (@Architect) Reduce `lib/features/booking/viewmodels/booking_view_model.dart` into isolated state domains or split view models so slot state, booking list state, checkout state, and booking actions do not share one global loading/error surface.
- [ ] (@Architect) Fix correctness issues in the booking state layer:
  - remove duplicate `markDelivered()` mutation
  - make decline/refund path call the new atomic server-side primitive
  - restore missing success-state notifications where listeners are required
  - cancel or guard payment polling based on screen lifecycle/result
  - stop relying on default price fallback behavior
- [ ] (@Architect) Remove legacy-only APIs that become dead once `PaymentMethodScreen` is retired.
- **Verify (@Sentinel):** View model state is recoverable, transitions are correct, and one user action causes one authoritative mutation.

### 2.4 Observability (If needed)

- [ ] (@Observability) Create `.TODO/OBSERVABILITY_Bookin_2026-02-28.md` listing the required booking/payment events, correlation fields, and privacy rules.
- [ ] (@Architect) Instrument services/viewmodels, not widgets, with correlation across:
  - booking draft id
  - booking id
  - payment id / request id
  - webhook event id
  - refund/recovery attempt id
- [ ] (@ThreatModeler) Review logs for secret leakage, PII exposure, and replay-sensitive payload logging.
- **Verify (@Sentinel):** Telemetry is actionable for payment failures and abuse triage without exposing secrets or sensitive personal data.

---

## Phase 3: UI (After logic)

> Primary: @Pixel

### 3.1 Wiring

- [ ] (@Pixel) Update booking screens to consume only the corrected view model contracts and not infer trust from UI-only states:
  - `lib/features/booking/view/availability_screen.dart`
  - `lib/features/booking/view/booking_sheet.dart`
  - `lib/features/booking/view/payment_checkout_screen.dart`
  - `lib/features/booking/view/payment_webview_screen.dart`
  - `lib/features/booking/view/bookings_list_screen.dart`
  - `lib/features/booking/view/booking_details_screen.dart`
- [ ] (@Pixel) Harden the payment WebView UX so success/failure is accepted only for allowlisted callback hosts and correlated request data.
- [ ] (@Pixel) Split client/provider loading and error surfaces so the dual-tab booking list cannot leak state between tabs.
- [ ] (@Pixel) Remove or redirect the legacy `lib/features/booking/view/payment_method_screen.dart` to the active checkout flow.
- **Verify (@Sentinel):** Slow, failed, canceled, spoofed, and successful payment flows remain stable and understandable in the UI.

### 3.2 Polish (Optional)

- [ ] (@Pixel) Consolidate duplicated booking status presentation and action badges into shared components used by both booking feature widgets and dashboard booking widgets.
- [ ] (@Pixel) Add low-risk UX protections:
  - disable duplicate taps during booking actions
  - show explicit retry vs cancel states during payment recovery
  - keep English-only strings for any new copy
- **Verify (@Sentinel):** UI polish does not widen rebuild scope or reintroduce duplicate business rules in widgets.

---

## Phase 4: QA + Security (MANDATORY)

> Primary: @Sentinel

### 4.1 Contract + Migration Checks

- [ ] (@Sentinel) Run `flutter analyze` for the booking feature and direct dependencies after remediation.
- [ ] (@Sentinel) Run focused Flutter tests for booking unit/widget coverage and any new repository/service tests.
- [ ] (@Sentinel) Run SQL verification queries for the live schema/RLS/migration contract defined in Phase 1.
- [ ] (@APIContract) Confirm that Flutter shapes, edge-function responses, and RPC outputs all match the locked contract documents in `.TODO/`.
- **Verify (@Sentinel):** No contract mismatch remains between app code, repo SQL, docs, and live DB.

### 4.2 Security + Abuse Tests

- [ ] (@Sentinel) Execute the threat-model negative checks:
  - unsigned webhook payload rejected
  - forged recovery request for another user's booking rejected
  - untrusted WebView host/path rejected
  - tampered provider/slot/price payload rejected
  - duplicate delivery/refund attempts do not double-apply
  - arbitrary cross-user notification insert denied or removed from client path
- [ ] (@ThreatModeler) Perform a booking-focused RLS leak audit for client, provider, non-party authenticated user, and service role.
- [ ] (@Sentinel) Confirm no Flutter client artifact still contains QiCard merchant secrets or Basic Auth construction.
- **Verify (@Sentinel):** Unauthorized payment or booking state mutation is not possible through the client path.

### 4.3 Functional QA

- [ ] (@Sentinel) Execute a manual end-to-end script covering:
  - provider creates slot
  - client opens booking sheet
  - client pays successfully
  - booking becomes held/confirmed as designed
  - provider and client see the same booking state
  - provider delivery path
  - client/provider cancel/decline/refund paths where allowed
- [ ] (@Sentinel) Execute edge cases:
  - payment timeout
  - network loss during checkout
  - app background/resume during polling
  - stale or orphan draft recovery
  - duplicate taps on action buttons
  - booking refresh after action retains schedule/status data
- **Verify (@Sentinel):** No crashes, orphaned states, duplicate mutations, or contradictory UI states remain.

### 4.4 Observability Validation (If included)

- [ ] (@Sentinel) Verify required payment/booking logs and events exist and are usable for support/debugging.
- [ ] (@Observability) Confirm correlation ids are preserved across booking checkout, recovery, webhook handling, and refund flows.
- [ ] (@Sentinel) Confirm privacy redaction rules prevent credential, signature, or sensitive note leakage.
- **Verify (@Sentinel):** Operators can trace a payment/booking issue end-to-end without exposing secrets.

---

## Phase 5: Documentation Sync (MANDATORY)

> Primary: @SlineDocs

- [ ] (@SlineDocs) Update the booking sections of:
  - `Sline_everything/DEVELOPER_GUIDE.md`
  - `Sline_everything/SUPABASE_SETUP.md`
  - `Sline_everything/CODE_REVIEW.md`
  - `Sline_everything/STRUCTURE.md`
  - `Sline_everything/Sline_Log.md`
- [ ] (@SlineDocs) Record any docs-vs-live reconciliation discovered in Phase 1.0 instead of silently editing docs to match assumptions.
- **Verify (@Sentinel):** Docs match code and live DB reality, and all newly introduced edge functions/RPC/contracts are documented.

## 7) Acceptance Criteria (MANDATORY)

- Client builds contain no QiCard merchant credentials and no direct Basic Auth gateway calls.
- Client code no longer calls the webhook handler directly for payment recovery.
- Webhook processing is fail-closed for unsigned QiCard payloads outside explicit local-dev mode.
- Booking draft creation rejects tampered provider/slot/amount payloads through server-side validation.
- Decline/refund executes atomically or with a server-side compensating guarantee that prevents split payment/status state.
- `markDelivered()` performs exactly one authoritative state mutation per user action.
- Booking list tabs have isolated loading/error state and no cross-tab contention.
- Payment WebView accepts success/failure only from allowlisted callback hosts with correlated request context.
- Booking detail/list refreshes preserve schedule and status fields after actions.
- Booking widget tests, payment security tests, and edge-function tests cover the critical happy paths and abuse cases.
- Live Supabase scan evidence exists for the touched tables, policies, indexes, triggers, enums, and edge functions before rollout.
- Updated docs and rollback instructions exist for the shipped remediation set.

## 8) Rollback Plan

- DB rollback/forward-fix steps:
  - rollback only additive migrations introduced for Bookin if they are isolated and safe to revert
  - prefer forward-fix for schema contracts already consumed by the app
  - preserve old columns/functions during the compatibility window until the new app path is proven stable
  - keep migration verification queries in `.TODO/MIGRATION_Bookin_2026-02-28.md`
- app rollback (flag/revert):
  - retain a rollout toggle to disable new server-side payment proxy/recovery path if staging or production telemetry spikes
  - keep a short-lived compatibility wrapper/facade for refactored booking services/view models during rollout
  - if `PaymentMethodScreen` is removed, keep a redirect-compatible route until confirmed unused in shipped builds
- emergency disable strategy (if applicable):
  - disable payment initiation/recovery entry points server-side if webhook signature validation or booking hold integrity fails
  - disable the Bookin checkout CTA in the app if server-side payment flow is degraded
  - fall back to support/manual handling for in-flight payment incidents rather than letting the client continue unsafe mutations

## 9) References (From Scan)

- Workflow instruction:
  - `.agents/workflows/planner.md`
- Existing audit:
  - `.TODO/Bookin.TODO.md`
- Docs scanned:
  - `Sline_everything/DEVELOPER_GUIDE.md`
  - `Sline_everything/SUPABASE_SETUP.md`
  - `Sline_everything/MVP_ROADMAP.md`
  - `Sline_everything/ARCHITECTURE_ANALYSIS.md`
  - `Sline_everything/CODE_REVIEW.md`
  - `Sline_everything/STRUCTURE.md`
- App/code scanned:
  - `lib/main.dart`
  - `lib/app/main_navigation_screen.dart`
  - `lib/core/services/payment_service.dart`
  - `lib/core/services/demo_payment_service.dart`
  - `lib/core/services/qicard_payment_service.dart`
  - `lib/features/booking/data/booking_repository.dart`
  - `lib/features/booking/models/booking_model.dart`
  - `lib/features/booking/models/slot_model.dart`
  - `lib/features/booking/services/booking_service.dart`
  - `lib/features/booking/viewmodels/booking_view_model.dart`
  - `lib/features/booking/view/bookings_discovery_screen.dart`
  - `lib/features/booking/view/availability_screen.dart`
  - `lib/features/booking/view/bookings_list_screen.dart`
  - `lib/features/booking/view/booking_details_screen.dart`
  - `lib/features/booking/view/booking_sheet.dart`
  - `lib/features/booking/view/add_slot_sheet.dart`
  - `lib/features/booking/view/payment_checkout_screen.dart`
  - `lib/features/booking/view/payment_webview_screen.dart`
  - `lib/features/booking/view/payment_method_screen.dart`
  - `lib/features/booking/view/widgets/booking_card.dart`
  - `lib/features/dashboard/view/widgets/booking_card.dart`
  - `lib/features/wallet/services/ledger_service.dart`
  - `lib/features/notifications/services/notification_service.dart`
  - `lib/features/chat/data/chat_repository.dart`
  - `supabase/functions/qicard_webhook_handler/index.ts`
  - `supabase/migrations/20260224_restrict_process_payment_event_ledger_execute.sql`
  - `supabase/migrations/20260225_create_process_payment_event_ledger_rpc.sql`
- Tests scanned:
  - `test/unit/booking/booking_view_model_test.dart`
  - `test/unit/models/booking_model_test.dart`
  - `test/unit/core/demo_payment_service_test.dart`
- Live Supabase scan evidence:
  - `@mcp:supabase-mcp-server:` scan is REQUIRED by the workflow and is still pending because that tool is unavailable in this session.
