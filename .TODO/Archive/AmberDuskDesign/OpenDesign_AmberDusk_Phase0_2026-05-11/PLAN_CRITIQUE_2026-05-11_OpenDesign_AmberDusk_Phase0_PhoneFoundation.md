# Plan Critique: OpenDesign Amber Dusk Phase 0 Phone Foundation

Date: 2026-05-11
Critic: PlanCritic
Input plan: `.TODO/Archive/OpenDesign_AmberDusk_Phase0_2026-05-11/PLAN_OpenDesign_AmberDusk_Phase0_PhoneFoundation_2026-05-11.md`
Parent plan: `.TODO/PLAN_OpenDesign_AmberDusk_Phone_2026-05-10.md`
Related plan: `.TODO/PLAN_OpenDesign_AmberDusk_Web_Mohammed_2026-05-10.md`
Session log: `docs/LOG/SESSION_PLAN_OpenDesign_AmberDusk_Phase0_PhoneFoundation_2026-05-11.md`

## A. Assumptions And Decision Needed

### Assumptions

- This is a planning and critique pass only. No Flutter implementation files are edited in this step.
- Phase 0 is the phone-first Amber Dusk design-system foundation required by the parent phone plan and by Mohammed's web plan handoff.
- Open Design MCP is the visual source of truth for Amber Dusk evidence, but repository architecture docs and `.impeccable.md` remain mandatory project constraints.
- Existing SLine design-system files are real current code and must be adapted, not replaced wholesale.
- Backend, Supabase schema, RLS, storage policies, auth flows, and data contracts are out of scope for Phase 0. If implementation discovers backend need, Phase 0 stops and a separate backend plan is required.

### Decisions Needed Before Implementation

1. **Theme activation:** Do Amber Dusk tokens become globally active in Phase 0, or are they staged as a named token layer for Phase 1+ screens?
   - Recommended decision: stage the named Amber Dusk layer only. Do not flip the whole app default theme in Phase 0.
2. **Font packaging:** Are DM Sans and Fraunces bundled from Open Design assets, fetched through `google_fonts`, or represented through fallback stacks until licensing is proven?
   - Recommended decision: do not bundle Open Design font files until license/source is recorded. Use fallback-compatible token definitions and document the visual delta.
3. **Glass conflict:** Open Design contains blur-like surfaces, while `.impeccable.md` has a hard no-glass rule.
   - Recommended decision: solid surfaces only in Phase 0. Treat blur as a documented visual deviation requiring explicit approval before any future exception.
4. **Light mode parity:** Open Design is dark-first. Does Phase 0 define a full Amber Dusk light scheme or only a dark scheme?
   - Recommended decision: define a paired light token set for API parity and accessibility, but do not claim it is Open Design-authored unless evidence is added.

## B. Gate Status

| Gate | V1 Status | Corrected Status | Reason |
| --- | --- | --- | --- |
| Source-of-truth format | FAIL | PASS after rewrite | V1 was an execution plan, not the required PlanCritic A-I source-of-truth artifact. |
| UI evidence | PARTIAL | PASS after rewrite | V1 had evidence but did not require a refresh artifact with exact MCP project/file metadata before implementation. |
| Existing theme contract | FAIL | PASS after rewrite | V1 did not explicitly gate against duplicating current `AppMotion`, `AppStates`, status colors, component themes, or `AppColorScheme` fields. |
| Activation safety | FAIL | PASS after rewrite | V1 left global activation ambiguous. Corrected plan stages tokens and blocks default-theme flips unless separately approved. |
| Docs/session logging | PARTIAL | PASS after rewrite | Session log exists, but V1 did not require PlanCritic result logging and critique persistence. |
| Test and QA baseline | FAIL | PASS after rewrite | V1 had post-change checks but not a current baseline artifact or diff-only raw-token scan rule. |
| Backend/RLS | PASS | PASS | No backend work is needed. Corrected plan adds a hard stop if backend need appears. |
| Release risk | PARTIAL | PASS after rewrite | Corrected plan adds rollback boundaries, artifact checklist, and conditional full-suite escalation. |

## C. Critical Gaps

1. **Missing PlanCritic source-of-truth structure.**
   - The v1 plan was detailed, but it did not follow PlanCritic sections A-I and therefore could not serve as the requested source-of-truth gate.

2. **Current design-system reality was not a blocking gate.**
   - The repository already has `AppMotion`, `AppStates`, `AppDecorations.elevation`, component themes, and status color fields in `AppColorScheme`. V1 risked re-planning solved foundation work instead of building Amber Dusk as a constrained design layer.

3. **Global theme activation was ambiguous.**
   - Phase 0 should create a safe foundation. Flipping the app default theme would widen the blast radius to every screen and requires full-app visual QA. V1 did not make this a yes/no decision.

4. **Font licensing and source provenance were unresolved.**
   - Open Design lists `assets/fonts/fraunces-latin.woff2` and `assets/fonts/dm-sans-latin.woff2`, but the MCP search found no license text. V1 did not block bundling on license evidence.

5. **Open Design blur conflicts with the project no-glass rule.**
   - `.impeccable.md` forbids `BackdropFilter`, `GlassContainer`, `GlassCard`, and `GlassButton` in new code. V1 noted surfaces but did not force a decision for blur/transparent panels.

6. **Light mode parity was under-specified.**
   - SLine has light/dark theme infrastructure. Amber Dusk evidence is dark-first. V1 did not require a clear light-mode token strategy before any integration with existing theme APIs.

7. **Raw-token baseline was not exact enough.**
   - The repo already has legacy hardcoded `Colors.`, `Color(0x`, `fontSize:`, `Duration(`, `BoxShadow(`, and gradient usage outside theme files. V1 needed an explicit baseline artifact and diff-only acceptance rule.

8. **Test strategy lacked current baselines and escalation rules.**
   - V1 listed `flutter analyze` and targeted tests after implementation, but did not require baseline capture before edits or define when full `flutter test` becomes mandatory.

9. **Import/export contract was not strict enough.**
   - Without a barrel/import policy, new Phase 1 screens can import deep Amber Dusk implementation files inconsistently.

10. **Handoff to Mohammed was not tied to concrete artifacts.**
   - The web plan depends on phone Phase 0, but V1 did not make the handoff note an explicit release gate with exact contents.

## D. Invariants And Success Criteria

### Invariants

- No feature view imports Supabase or performs business/data fetching.
- No backend, migration, RLS, storage, edge function, or SQL file changes are allowed in Phase 0.
- New reusable design values live under `lib/core/theme/`, not feature folders.
- Existing theme APIs are adapted only after current fields and tests are scanned.
- New code uses existing design layers:
  - Layer 1: colors, typography, motion, elevation, theme.
  - Layer 2: layout, spacing, sizes, radii.
  - Layer 3: widgets consume tokens only.
- No new `BackdropFilter`, `GlassContainer`, `GlassCard`, or `GlassButton` use.
- No Open Design font files are bundled unless license/source evidence is recorded.
- Legacy raw-token debt is baselined; Phase 0 must not add new raw tokens outside approved token files.
- Theme activation remains staged unless the implementation owner records explicit approval to flip the app default.

### Success Criteria

- Corrected plan is persisted at `.TODO/Archive/OpenDesign_AmberDusk_Phase0_2026-05-11/PLAN_OpenDesign_AmberDusk_Phase0_PhoneFoundation_2026-05-11.md`.
- This critique is persisted at `.TODO/Archive/OpenDesign_AmberDusk_Phase0_2026-05-11/PLAN_CRITIQUE_2026-05-11_OpenDesign_AmberDusk_Phase0_PhoneFoundation.md`.
- Session log records the PlanCritic rewrite.
- Implementation plan requires these artifacts before code changes:
  - `.TODO/Archive/OpenDesign_AmberDusk_Phase0_2026-05-11/EVIDENCE_OpenDesign_AmberDusk_Phase0_2026-05-11.md`
  - `.TODO/Archive/OpenDesign_AmberDusk_Phase0_2026-05-11/BASELINE_OpenDesign_AmberDusk_Phase0_2026-05-11.md`
- Implementation plan requires these artifacts before handoff:
  - `.TODO/WebRedsign/HANDOFF_OpenDesign_AmberDusk_Phase0_ToWeb_2026-05-11.md`
  - `.TODO/Archive/OpenDesign_AmberDusk_Phase0_2026-05-11/DOCS_SYNC_2026-05-11_OpenDesign_AmberDusk_Phase0.md`
- Planned verification includes `dart format`, `flutter analyze`, targeted core theme/widget tests, raw-token diff scan, and no-backend-change scan.

## E. Risk Register

| Risk | Probability | Impact | Mitigation |
| --- | --- | --- | --- |
| Global theme flip causes app-wide visual regressions | Medium | High | Stage tokens in Phase 0; require separate approval and full-app QA for default activation. |
| Duplicating existing theme foundation creates API churn | Medium | High | Require current-code reality gate before any token/adaptor edits. |
| Bundled font files lack license evidence | Medium | High | Block font bundling until source/license is documented. |
| `.impeccable.md` no-glass policy conflicts with Open Design blur | High | Medium | Use solid surfaces and document deviation. |
| Light mode tokens are invented without evidence | Medium | Medium | Label light mapping as derived fallback and prevent default activation based on it. |
| Legacy raw-token debt hides new regressions | High | Medium | Capture baseline and enforce diff-only raw-token acceptance. |
| Web plan consumes incomplete phone handoff | Medium | Medium | Gate completion on explicit handoff file with token names, caveats, and unsupported items. |
| Tests are too broad and slow for Phase 0 | Medium | Low | Use targeted tests unless global theme activation occurs. |

## F. Pre-Mortem

Phase 0 fails if an implementer treats Amber Dusk as a full app reskin instead of a staged foundation. The most likely failure path is creating new token files, immediately wiring them into global `AppTheme`, and then chasing unrelated visual regressions across 100+ files. A second likely failure path is bundling font assets from Open Design without license provenance. A third is translating blur-heavy surfaces directly into `BackdropFilter`, violating `.impeccable.md`.

The corrected plan prevents these failures by making evidence, current-code inventory, and decisions explicit gates before edits. It stages Amber Dusk under a named design folder, requires adapter contracts, blocks backend work, baselines legacy raw-token debt, and makes the phone-to-web handoff a required artifact.

## G. Plan Fixes

1. Rewrite the plan into PlanCritic A-I format.
2. Add exact source-of-truth artifacts and file names.
3. Add Open Design MCP evidence refresh as a pre-edit gate.
4. Replace the current repository theme-contract scan with a comprehensive pre-edit codebase search for all related files, including theme contracts, shared widgets, screen groups, tests, docs, imports, and plan-missed files; require an implementer report listing every discovered/related file and any missed plan coverage, and require that report to be reviewed and accepted before any UI-phase code is written or edited.
5. Set staged named-token activation as the recommended Phase 0 path.
6. Add font provenance decision and license block.
7. Add no-glass conflict resolution.
8. Add light-mode parity strategy.
9. Add baseline scan artifact and diff-only raw-token rule.
10. Add targeted test plan plus escalation rule for full app tests.
11. Add import/export contract for Amber Dusk files.
12. Add concrete web handoff artifact.
13. Add rollback checkpoints and final gate.

## H. Corrected Plan

The corrected plan is now the source-of-truth execution plan:

`.TODO/Archive/OpenDesign_AmberDusk_Phase0_2026-05-11/PLAN_OpenDesign_AmberDusk_Phase0_PhoneFoundation_2026-05-11.md`

Implementation must follow that file, not the pre-critique v1 plan.

## I. Change Report

### What Changed

- Converted Phase 0 from a broad implementation plan into a gate-based PlanCritic source-of-truth plan.
- Added hard decisions for activation, fonts, blur/no-glass, and light mode.
- Added required evidence, baseline, docs-sync, and web-handoff artifacts.
- Added current-code reality gates for existing SLine theme infrastructure.
- Added targeted verification and full-test escalation criteria.

### Why It Changed

The v1 plan was useful but not safe enough as a source-of-truth gate. It had unresolved decisions and could allow broad app-wide theme activation or duplicate existing foundation code. The rewrite narrows Phase 0 to a controlled foundation that can be implemented, verified, and handed off without expanding scope.

### Downstream Impact

- Phone Phase 1 can consume stable Amber Dusk tokens after Phase 0 passes.
- Mohammed's web plan gets a concrete handoff file instead of inferring phone token decisions.
- Any app-wide default-theme activation is moved out of Phase 0 unless explicitly approved.
