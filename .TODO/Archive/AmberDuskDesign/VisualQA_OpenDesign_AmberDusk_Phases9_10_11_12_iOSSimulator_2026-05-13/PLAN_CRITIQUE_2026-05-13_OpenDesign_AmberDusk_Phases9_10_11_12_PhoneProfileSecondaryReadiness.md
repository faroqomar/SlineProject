# Plan Critique: Open Design Amber Dusk Phone Phases 9-12

**Date:** 2026-05-13
**Critic:** @PlanCritic
**Mode:** single-agent source-of-truth gate
**Input draft:** `.TODO/PLAN_OpenDesign_AmberDusk_Phases9_10_11_12_PhoneProfileSecondaryReadiness_2026-05-13.md`
**Corrected plan:** `.TODO/PLAN_OpenDesign_AmberDusk_Phases9_10_11_12_PhoneProfileSecondaryReadiness_2026-05-13.md`
**Parent plan:** `.TODO/PLAN_OpenDesign_AmberDusk_Phone_2026-05-10.md`
**Companion web plan:** `.TODO/PLAN_OpenDesign_AmberDusk_Web_Mohammed_2026-05-10.md`
**Session log:** `docs/LOG/SESSION_PLAN_OpenDesign_AmberDusk_Phases9_10_11_12_PhoneProfileSecondaryReadiness_2026-05-13.md`

This critique is the execution gate for the Phase 9-12 phone closure block. Execution must use the corrected plan plus this critique, not the pre-critique draft alone.

---

## A) Assumptions And Decisions Needed

### Assumptions

- This critique is planning-only and does not implement Flutter source changes.
- The user requested one agent only for this source-of-truth gate. No subagents were spawned.
- Phase 9-11 scope comes from the corrected parent phone plan.
- Phase 12 is a new closure phase and must be explicitly defined by this critique.
- Open Design project `1674a1db-7a74-4c80-8e2c-196a0385a8f7` remains the visual source of truth.
- Profile/settings/services/portfolio have strong Open Design evidence; categories/favorites/saved/notification-list states do not.
- Backend, Supabase schema, RLS, RPCs, storage policy, Edge Functions, payment, role switch, notification creation, favorites privacy, saved privacy, and portfolio storage contracts are out of scope.
- Runtime Flutter visual evidence is separate from Open Design reference evidence.

### Decisions Needed

No blocking decision remains after this rewrite.

1. **Phase 12**
   - Selected decision: Phase 12 is phone-to-web handoff, docs closure, evidence index, gap register, and artifact routing only.
   - Plan impact: No new runtime UI or backend work belongs in Phase 12.

2. **Missing exact secondary designs**
   - Selected decision: Adapt/token-normalize secondary screens unless exact Open Design or user screenshot evidence exists.
   - Plan impact: Favorites, saved, categories, notifications, loading, empty, error, status, and CTA helper states cannot claim pixel parity without evidence.

3. **Old profile UI docs**
   - Selected decision: Use archived profile docs as code/surface inventory and old-state reference, not as the new visual source.
   - Plan impact: Old teal/gold/glass patterns are not authoritative.

4. **Theme activation**
   - Selected decision: Keep Amber Dusk scoped through staged tokens/adapters. Do not flip global `AppTheme`.
   - Plan impact: New reusable values go into theme/token/widget layers.

---

## B) Gate Status

| Gate | Draft Status | Corrected Status | Notes |
| --- | --- | --- | --- |
| Gate 0: Test Infrastructure Gate | PARTIAL | PASS AFTER CORRECTION | Added provider/screen classification, singleton/auth setup, and bounded pump rules. |
| Data / Contracts Gate | PASS | PASS | Visual-only. Missing data stops the phase and requires a separate plan. |
| Security / RLS Gate | PASS | PASS | No RLS/auth/storage authority changes. Direct Supabase in views remains blocked. |
| Backend / Supabase Gate | PASS | PASS | No backend files should change. `SUPABASE_SETUP.md` stays unchanged unless backend objects change. |
| UI / Integration Gate | PARTIAL | PASS AFTER CORRECTION | Added A-I structure, required source set, Open Design evidence labels, and affected inventory rows. |
| Release / QA Gate | PARTIAL | PASS AFTER CORRECTION; VISUAL CLOSURE STILL GATED | Added runtime phone matrix and final PlanCritic approval before handoff. |
| Web Handoff / Docs Gate | PARTIAL | PASS AFTER CORRECTION | Phase 12 now owns handoff/docs closure, not new implementation. |

---

## C) Critical Gaps Found

### Gap 1: Critique Artifact Was Missing

- Why it will break: Executors and reviewers need a persisted risk/gate artifact.
- Fix: Create this file and reference it from the corrected plan.
- Owner: @PlanCritic.
- Acceptance check: This file exists and the session log records the rewrite.

### Gap 2: Draft Was Not In PlanCritic A-I Format

- Why it will break: A Planner-format document can skip source-of-truth decisions and gate status.
- Fix: Rewrite the plan into A-I sections.
- Owner: @PlanCritic.
- Acceptance check: Corrected plan starts with `PLANCRITIC CORRECTED PLAN`.

### Gap 3: Related TODO Sources Were Not Strong Enough

- Why it will break: Phase 9-12 inherits constraints from root plans, old UI docs, archived prior phases, handoffs, master reports, emulator checklists, and SystemEvolution findings.
- Fix: Add the `Required Source Set` to the corrected plan.
- Owner: @PlanCritic + @DocsKeeper.
- Acceptance check: Executor re-reads the source set before edits.

### Gap 4: Phase 12 Scope Was Ambiguous

- Why it will break: Older roadmap numbering and archived broad design plans used Phase 12 differently.
- Fix: Resolve Phase 12 as handoff/docs closure only.
- Owner: @PlanCritic.
- Acceptance check: Phase 12 has no runtime `lib/` implementation scope.

### Gap 5: Missing Secondary Designs Could Be Invented

- Why it will break: The live Open Design scan returned no favorites evidence and only weak saved/categories/notifications evidence.
- Fix: Mark those screens adaptation-only unless new evidence appears.
- Owner: @Pixel + @Sentinel.
- Acceptance check: Visual QA labels exact vs adaptation proof.

### Gap 6: Existing Raw Visual Debt Needs A Diff Rule

- Why it will break: Current profile, portfolio, notification/helper files contain legacy visual constants. A simple scan is not enough.
- Fix: Baseline existing hits and block new unapproved hits in changed files.
- Owner: @CodeGuard + @Sentinel.
- Acceptance check: Before/after scan and exception list are logged.

### Gap 7: Type B Tests Can Touch Real Dependencies

- Why it will break: Several screens create ViewModels internally, and some VMs auto-initialize auth/listeners.
- Fix: Add Gate 0 fixture/provider matrix before tests.
- Owner: @Sentinel.
- Acceptance check: Session log records Type A/Type B test strategy before test edits.

### Gap 8: Runtime Visual Completion Could Be Faked

- Why it will break: Open Design reference screenshots are not Flutter screenshots.
- Fix: Require phone runtime evidence at 360, 390, 402, and 430 logical widths, or carry explicit blockers.
- Owner: @Pixel + @Sentinel.
- Acceptance check: Phase 11 cannot approve visual completion without runtime proof.

### Gap 9: Bottom Nav Contract Could Drift

- Why it will break: Older docs and Open Design variants show more shell destinations than the live repo contract.
- Fix: Preserve Home, Dashboard, Messages, Profile as the authenticated shell unless a separate nav plan changes it.
- Owner: @Architect.
- Acceptance check: No Phase 9-12 bottom-nav destination expansion.

---

## D) Invariants And Success Criteria

- No View imports or calls Supabase directly.
- No ViewModel, repository, service, Provider registration, storage, notification, favorites, saved, role-switch, or backend contract changes occur in this visual plan.
- No schema, RLS, RPC, trigger, storage policy, Edge Function, SQL test, or live backend mutation occurs.
- Profile role switching remains atomic and service/RPC owned.
- Portfolio storage behavior remains in repositories/services and existing widgets.
- Notifications remain server-authoritative.
- Favorites and saved tasks keep privacy and DM guard contracts.
- Reusable design values live in theme/tokens/adapters/shared widgets.
- No global Amber Dusk `AppTheme` activation.
- No blur, glass, deleted `glass_*`, or unlicensed Open Design font binaries.
- Runtime visual QA is required for visual completion.
- Corrected plan, this critique, and session-log entries exist before execution.

---

## E) Risk Register

| Risk | Probability | Impact | Prevention | Fallback |
| --- | ---: | ---: | --- | --- |
| Phase 12 expands into feature work | Medium | High | Handoff/docs-only decision | Split new Planner pass |
| Missing designs get invented | High | Medium | Adaptation-only labels | Request screenshots |
| Old profile teal/gold remains | High | Medium | Raw-token baseline/diff scan | Centralize or document exception |
| Role switch regresses | Low | High | UI-only boundary | Revert behavior-adjacent edits |
| Portfolio storage changes accidentally | Medium | High | Storage boundary invariant | Separate storage plan |
| Notification authority moves client-side | Low | High | Server-authority invariant | Revert and split backend plan |
| Widget tests touch real Supabase | Medium | Medium | Gate 0 fixture matrix | Lower-level harness/manual note |
| Visual QA is overstated | High | Medium | Runtime matrix | Keep gate open |
| Web handoff is too narrative | Medium | Medium | Evidence index and route map | Block Mohammed handoff until fixed |
| Broad execution agents collide | Medium | High | File ownership checkpoints | Main executor integration review |

---

## F) Pre-Mortem

- This fails if execution starts from the draft instead of the corrected plan.
- This fails if archived UI docs are treated as the new visual truth.
- This fails if Phase 10 claims exact parity for missing designs.
- This fails if profile visual changes alter role switch, logout, avatar upload, favorites, chat, safety, or portfolio CRUD behavior.
- This fails if Type B tests use plain provider assumptions and accidentally touch real dependencies.
- This fails if runtime visual QA is skipped but docs say complete.
- This fails if Mohammed receives handoff prose without exact route/state/evidence mapping.
- This fails if `.TODO` cleanup archives active plans or open visual gates.

---

## G) Plan Fixes

1. Persisted this PlanCritic artifact.
2. Rewrote the plan into A-I source-of-truth format.
3. Added the full related source set.
4. Resolved Phase 12 as handoff/docs closure.
5. Added Gate 0 test infrastructure.
6. Added Open Design evidence authority labels.
7. Added raw-token baseline/diff rules.
8. Added four-tab shell contract.
9. Added runtime phone matrix and final approval gate.
10. Added Mohammed web handoff details.
11. Added artifact routing and docs sync conditions.

---

## H) Corrected Plan Reference

The corrected source-of-truth execution plan is:

`.TODO/PLAN_OpenDesign_AmberDusk_Phases9_10_11_12_PhoneProfileSecondaryReadiness_2026-05-13.md`

Implementation must follow that corrected plan plus this critique file, not the pre-critique draft and not the broad parent phone-plan sections alone.

Corrected plan structure:

- PlanCritic assumptions and resolved decisions.
- Gate status table including Gate 0.
- Critical gaps with owners and acceptance checks.
- Non-negotiable invariants and verification methods.
- Risk register and pre-mortem.
- Corrected execution phases H.0, 9, 10, 11, and 12.
- Verification, handoff, docs sync, rollback, and change report.

---

## I) Change Report

### Original Issues Summary

- Draft lacked PlanCritic A-I source-of-truth structure.
- Draft lacked this persisted critique artifact.
- Draft did not fully promote related TODO/docs evidence to a mandatory source set.
- Phase 12 needed a resolved non-code meaning.
- Missing exact evidence needed hard adaptation-only labels.
- Test setup needed a blocking Gate 0.
- Runtime visual proof needed stronger release gating.

### Added Steps

- Added critique artifact.
- Added required source set.
- Added Gate 0.
- Added exact/adaptation/runtime/blocker evidence labels.
- Added raw-token/no-glass/backend no-change scans.
- Added Phase 12 handoff/docs closure.
- Added final runtime phone matrix.

### Removed Steps

- Removed implicit permission to use old UI docs as visual truth.
- Removed implicit Phase 12 implementation scope.
- Removed implicit exact-match claims for missing design states.

### Reordered Steps

- PlanCritic gate before execution.
- Evidence lock before edits.
- Test matrix before test work.
- Runtime visual QA before handoff/docs closure.

### Expanded Steps

- Expanded Phase 9 profile, public profile, portfolio, settings, and services coverage.
- Expanded Phase 10 secondary/helper/a11y coverage.
- Expanded Phase 11 final readiness gates.
- Expanded Phase 12 docs, handoff, evidence index, and artifact routing.

### Residual Risks

- Runtime visual parity remains unproven until emulator/manual QA.
- Several secondary surfaces still lack exact Open Design evidence.
- Font licensing remains unresolved.
- Future execution may still need careful ownership if implementation is delegated.
