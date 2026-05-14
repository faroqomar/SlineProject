# Plan Critique: OpenDesign Amber Dusk Phone Phases 5-8

**Date:** 2026-05-12  
**Critic:** @PlanCritic  
**Mode:** Single-agent source-of-truth gate  
**Input Draft:** `.TODO/PLAN_OpenDesign_AmberDusk_Phases5_6_7_8_PhoneTrustMessagingWorkPayments_2026-05-12.md`  
**Corrected Plan:** `.TODO/PLAN_OpenDesign_AmberDusk_Phases5_6_7_8_PhoneTrustMessagingWorkPayments_2026-05-12.md`  
**Parent Plan:** `.TODO/PLAN_OpenDesign_AmberDusk_Phone_2026-05-10.md`  
**Session Log:** `docs/LOG/SESSION_PLAN_OpenDesign_AmberDusk_Phases5_6_7_8_PhoneTrustMessagingWorkPayments_2026-05-12.md`

This critique is the execution gate for the Phase 5-8 phone block. Execution must use the corrected plan plus this critique, not the pre-critique draft alone.

## A) Assumptions + Decision Needed

### Assumptions

- This critique is planning-only and does not implement Flutter source changes.
- Phase 5-8 scope comes from `.TODO/PLAN_OpenDesign_AmberDusk_Phone_2026-05-10.md`.
- Open Design project `1674a1db-7a74-4c80-8e2c-196a0385a8f7` remains the visual source, with entry `Sline V2 Amber Dusk.html`.
- Phase 0 and Phase 1 left Amber Dusk as a staged token/widget-adapter layer, not a global app theme.
- Backend, Supabase, data contracts, ViewModels, repositories, services, payment authority, ledger authority, RLS, storage policy, SQL tests, and Edge Functions are out of scope for this visual plan.
- Runtime visual closure requires implemented Flutter runtime evidence, not only Open Design evidence.

### Decision Needed (Blocking)

No blocking decision remains after this PlanCritic rewrite.

1. **Message mode copy**
   - Selected decision: use `Received` and `Sent`.
   - Reason: current Open Design files and the design-system file use this direction; the repo dashboard inbox already uses it.
   - Plan impact: Phase 6 must not keep `Responses`/`Requests` unless the product owner explicitly overrides the source-of-truth decision.

2. **Wallet withdrawal**
   - Selected decision: preserve current product behavior and do not add a new active withdrawal flow in Phase 8.
   - Reason: current standalone wallet body still presents withdrawal as Coming Soon/preview behavior, and active withdrawal changes require product, backend, ledger, and security review.
   - Plan impact: Phase 8 can style wallet cards/previews, but new withdrawal routes, request forms, or ledger-affecting UI paths require a separate plan.

3. **Missing exact design evidence**
   - Selected decision: adapt/token-normalize only where exact Open Design or user screenshot evidence is absent.
   - Reason: missing evidence cannot be turned into pixel parity.
   - Plan impact: auth/gates, attachment tile, notification modal, proposal detail, payment return, and WebView screens need evidence labels and cannot claim exact match without new screenshots.

4. **Open Design fonts**
   - Selected decision: do not bundle Open Design font binaries without license/source evidence.
   - Reason: prior Amber Dusk gates found font assets but no license/source proof.
   - Plan impact: use existing approved font strategy and Amber Dusk typography roles.

## B) Gate Status

| Gate | Draft Status | Corrected Status | Reason | Fix Applied |
|---|---|---|---|---|
| Gate 0: Test Infrastructure Gate | PARTIAL | PASS AFTER CORRECTION | Draft had test notes but not a blocking gate. | Added provider matrix, auto-load setup, singleton cleanup, bounded pump strategy, and coverage-floor handling. |
| Data / Contracts Gate | PASS | PASS | No DTO/model/ViewModel/repository/service contract changes are planned. | Added hard stop if visual work exposes missing data. |
| Security / RLS Gate | PASS | PASS | No RLS/storage/auth policy change is planned. | Added sensitive-flow negative checks. |
| Backend / Supabase Gate | PASS | PASS | Live Supabase reality is evidence only. | Added no-change gate for `supabase/migrations`, `supabase/functions`, and `supabase/tests`. |
| UI / Integration Gate | PARTIAL | PASS AFTER CORRECTION | Draft left copy/withdrawal decisions open and could over-claim missing designs. | Resolved decisions and added evidence-authority rules. |
| Release / QA Gate | PARTIAL | PASS AFTER CORRECTION; VISUAL CLOSURE STILL GATED | Draft included QA but not as a PlanCritic release blocker. | Added runtime visual matrix, final sensitive-flow review, docs sync, final report, and handoff gates. |

## C) Critical Gaps (Must-Fix)

### Gap 1: Draft was not a persisted PlanCritic source-of-truth gate.

- **Why it will break:** @Executor and @Sentinel need a durable gate artifact with risks, decisions, and acceptance checks.
- **Fix:** Create this critique file and reference it from the corrected plan.
- **Owner:** @PlanCritic.
- **Acceptance check:** this file exists and the corrected plan references it.

### Gap 2: Message copy conflict was left to the executor.

- **Why it will break:** Phone and web can diverge, and implementation may choose stale copy.
- **Fix:** select `Received`/`Sent` from current Open Design/design-system evidence.
- **Owner:** @PlanCritic + @Pixel.
- **Acceptance check:** Phase 6 evidence note records this decision and changed UI follows it unless product overrides.

### Gap 3: Wallet withdrawal could be accidentally activated by visual work.

- **Why it will break:** withdrawal touches ledger, payment, and security behavior beyond visual scope.
- **Fix:** preserve current behavior and block new withdrawal routes/forms/service calls.
- **Owner:** @Architect + @ThreatModeler.
- **Acceptance check:** Phase 8 diff review finds no new withdrawal flow or ledger-affecting UI path.

### Gap 4: Missing exact evidence could become invented pixel matching.

- **Why it will break:** Open Design lacks exact phone targets for several Phase 5-8 surfaces.
- **Fix:** label missing targets as adaptation-only unless new evidence is added.
- **Owner:** @Pixel + @Sentinel.
- **Acceptance check:** visual QA labels every evidence source and no missing-evidence surface claims exact parity.

### Gap 5: Test infrastructure was under-gated.

- **Why it will break:** auto-loading ViewModels, singleton coordinators, WebView routes, and Provider typing can produce flaky or false tests.
- **Fix:** require Gate 0 fixture/provider/state matrix before test work.
- **Owner:** @Sentinel.
- **Acceptance check:** session log records the matrix before widget tests are written.

### Gap 6: Runtime visual completion could be faked.

- **Why it will break:** Open Design references are not proof that the Flutter app renders correctly.
- **Fix:** require runtime Flutter screenshots or explicit manual runtime notes before visual completion.
- **Owner:** @Pixel + @Sentinel.
- **Acceptance check:** visual QA report exists or final report keeps the visual gate open.

### Gap 7: Sensitive-flow privacy checks were not hard blockers.

- **Why it will break:** chat, attachments, notifications, payments, wallet, work, and disputes can leak private data or move authority into UI.
- **Fix:** add final sensitive-flow review as a release blocker.
- **Owner:** @ThreatModeler + @Observability + @CodeGuard.
- **Acceptance check:** session log records no UI-only lifecycle/payment authority, no raw sensitive logs, and no backend changes.

## D) Invariants & Success Criteria

- No View imports or calls Supabase directly.
- No ViewModel, service, repository, Provider registration, route contract, payment helper, ledger helper, or backend contract changes occur in this visual plan.
- No schema, migration, RLS, RPC, trigger, storage policy, Edge Function, SQL test, or live backend mutation occurs.
- Messages, attachments, notifications, direct offers, booking, payment, wallet, tender, work, and dispute authority stay in existing ViewModels/services/DB/Edge/RLS boundaries.
- DB stores storage paths and existing services/widgets generate signed URLs at render time; no UI/log path exposes signed URL internals.
- New logs use `AppLogger` and avoid raw IDs, raw exceptions, message bodies, storage paths, payment URLs, gateway IDs, and correlation IDs in routine UI paths.
- Reusable Amber Dusk values live in theme/tokens/adapters, not feature-local constants.
- No global `MaterialApp` or `AppTheme` Amber Dusk activation occurs in this plan.
- No new `BackdropFilter`, `ImageFilter.blur`, frosted glass, deleted `glass_*`, or bundled Open Design font binaries are introduced.
- Every changed UI has focused tests or an explicit documented reason for deferral.
- Runtime Flutter visual evidence is required before visual completion is claimed.
- Docs and Mohammed handoff describe verified implementation only.

## E) Risk Register

| Risk | Where | Probability | Impact | Blast radius | Early signal | Prevention | Fallback |
|---|---:|---:|---:|---|---|---|---|
| Missing designs are invented | Auth/gates, attachment, notification, proposal, payment return/WebView | High | Medium | Visual drift | no evidence path | adaptation-only rule | request screenshots |
| Copy diverges | Messages | Medium | Medium | phone/web drift | `Responses`/`Requests` remains | `Received`/`Sent` decision | product override note |
| Withdrawal becomes active | Wallet | Medium | High | ledger/payment/security | new route/form/service call | preserve current behavior | revert withdrawal UI |
| Payment return breaks | Payment WebView/return | Medium | High | checkout | URL params remain, pending context lost | payment smoke tests | restore prior shell/route |
| Realtime duplicates | Chat/messages | Medium | High | realtime load | duplicate stream/message logs | preserve topology | revert stream-adjacent edits |
| Test harness flakes | Widget tests | Medium | Medium | CI | MissingStub/provider errors | Gate 0 matrix | lower-level harness |
| Raw tokens spread | Feature views | High | Medium | maintainability | raw-token scan hits | adapter/token-first work | centralize or document exception |
| Sensitive logs leak | Chat/payment/wallet/work | Medium | High | privacy | raw IDs/paths/URLs | privacy review | patch logs before closure |
| Visual closure is overstated | Final report | High | Medium | web handoff | only Open Design refs | runtime matrix | keep gate open |
| Backend changes sneak in | Supabase dirs | Low | High | data/security | `supabase/` diff | no-backend diff gate | split separate plan |

## F) Pre-Mortem

- This fails when execution starts from the old draft and ignores this critique.
- This fails when Open Design references are treated as implemented Flutter evidence.
- This fails when missing auth/payment/notification/proposal artboards are filled in as if exact evidence existed.
- This fails when `MessagesScreen` keeps stale copy without a recorded product override.
- This fails when Phase 8 makes withdrawal look newly active.
- This fails when payment return or WebView visuals change pending-store, callback, or URL-cleanup behavior.
- This fails when lifecycle CTAs are made visually available without ViewModel/service authority.
- This fails when widget tests construct auto-loading VMs before mocks and cleanup are ready.
- This fails when logs expose message bodies, storage paths, payment URLs, or raw IDs.
- This fails when final docs say complete without runtime visual QA.

## G) Plan Fixes

1. **Goal:** Persist this PlanCritic artifact.
   - **Why:** Execution needs durable gate evidence.
   - **How:** Add this file and reference it from the corrected plan.
   - **Output artifact:** this critique file.
   - **Stop condition:** missing critique blocks execution.

2. **Goal:** Resolve copy and withdrawal decisions before implementation.
   - **Why:** They affect product meaning and web handoff.
   - **How:** choose `Received`/`Sent`; preserve current wallet withdrawal behavior.
   - **Output artifact:** corrected plan decisions.
   - **Stop condition:** product override must be explicit.

3. **Goal:** Block fake exact matching.
   - **Why:** several screens lack exact Open Design evidence.
   - **How:** evidence authority matrix and adaptation-only labels.
   - **Output artifact:** session-log evidence matrix.
   - **Stop condition:** exact-match claims without evidence block phase closure.

4. **Goal:** Harden test setup before tests.
   - **Why:** phases touch Type B screens and auto-loading VMs.
   - **How:** provider/fixture/singleton/pump matrix.
   - **Output artifact:** Gate 0 session-log matrix.
   - **Stop condition:** missing matrix blocks test edits.

5. **Goal:** Make runtime visual QA non-optional.
   - **Why:** design references are not app evidence.
   - **How:** route/state/width screenshot checklist and visual report.
   - **Output artifact:** emulator checklist and VisualQA report.
   - **Stop condition:** no runtime evidence means visual gate remains open.

## H) Corrected Plan Reference

The corrected source-of-truth execution plan is:

`.TODO/PLAN_OpenDesign_AmberDusk_Phases5_6_7_8_PhoneTrustMessagingWorkPayments_2026-05-12.md`

Implementation must follow that corrected plan plus this critique file. The corrected plan now includes:

- PlanCritic assumptions and resolved decisions.
- Gate status table including Gate 0.
- Critical gaps with owners and acceptance checks.
- Non-negotiable invariants and verification methods.
- Risk register and pre-mortem.
- Corrected execution phases 0, 5, 6, 7, 8, cross-phase QA, docs, handoff, acceptance, rollback, references, and scan evidence.
- Change report.

## I) Change Report

### Original Issues Summary

- Draft lacked PlanCritic A-I source-of-truth structure.
- Draft lacked this persisted critique artifact.
- Draft left messaging copy and wallet withdrawal decisions too open.
- Draft could allow exact-match claims for surfaces with missing exact design evidence.
- Draft had test and visual QA detail but not enough gate authority.

### Added Steps

- Added this critique file.
- Added PlanCritic A-I sections to the corrected plan.
- Added Gate 0 and explicit gate status.
- Added resolved decisions for `Received`/`Sent` and wallet withdrawal behavior.
- Added critical gaps, risk register, pre-mortem, and non-negotiable invariants.
- Added runtime visual QA and sensitive-flow release blockers.

### Removed Steps

- Removed executor discretion for message mode copy.
- Removed implied permission to activate withdrawal in a visual-only phase.
- Removed implied exact parity for missing Open Design targets.

### Reordered Steps

- PlanCritic gate now comes before execution phases.
- Decision resolution now happens before Phase 0 evidence lock.
- Test infrastructure now gates test work before phase tests.
- Runtime visual QA now blocks release/closure after code verification.

### Expanded Steps

- Expanded Phase 6 copy decision with evidence.
- Expanded Phase 8 wallet behavior with product/security stop rules.
- Expanded evidence classification and missing-design handling.
- Expanded sensitive-flow review into a release blocker.

### Why

The draft was detailed but still allowed ambiguity in the highest-risk areas. The rewrite turns those ambiguities into explicit decisions and makes the plan safe enough for execution.

### Residual Risks

- Exact Open Design evidence remains missing for several Phase 5-8 targets.
- Runtime visual QA still needs to be captured during execution.
- Payment/WebView tests remain brittle unless Gate 0 is done carefully.
- Large screen files increase review risk and should be handled phase by phase.
