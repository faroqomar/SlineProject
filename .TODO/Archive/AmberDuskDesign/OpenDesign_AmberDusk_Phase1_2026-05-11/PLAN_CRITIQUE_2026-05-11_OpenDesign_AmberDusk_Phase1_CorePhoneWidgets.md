# PLAN CRITIQUE: OpenDesign Amber Dusk Phase 1 Core Phone Widgets

Date: 2026-05-11
Critic: PlanCritic
Input plan: `.TODO/Archive/OpenDesign_AmberDusk_Phase1_2026-05-11/PLAN_OpenDesign_AmberDusk_Phase1_CorePhoneWidgets_2026-05-11.md`
Corrected plan: `.TODO/Archive/OpenDesign_AmberDusk_Phase1_2026-05-11/PLAN_OpenDesign_AmberDusk_Phase1_CorePhoneWidgets_2026-05-11.md`
Parent plan: `.TODO/PLAN_OpenDesign_AmberDusk_Phone_2026-05-10.md`
Session log: `docs/LOG/SESSION_PLAN_OpenDesign_AmberDusk_Phase1_CorePhoneWidgets_2026-05-11.md`

## A) Assumptions And Decisions Needed

### Assumptions

- This critique pass is planning-only and does not implement Flutter source changes.
- Phase 1 is visual shared-widget runtime activation for Amber Dusk, not backend work.
- Phase 0 Amber Dusk tokens are passive until a deliberate adapter or activation path consumes them.
- Shared widget work has broad blast radius because feature screens reuse these widgets.
- `SignedImage` has pre-existing direct Supabase usage; this critique treats it as baseline debt, not a reason to expand storage behavior in a UI phase.

### Decisions Needed Before Implementation

1. Activate Amber Dusk through one shared-widget adapter, not by globally flipping `AppTheme`.
2. Include `signed_avatar.dart` and `signed_image.dart` visual placeholders in Phase 1, with no storage/URL behavior changes.
3. Use Amber phone-layout nav height through the adapter instead of globally changing `AppLayout.bottomNavHeight`.
4. Do not bundle Open Design font files without license/source evidence.
5. Treat `SignedImage` Supabase access as baseline debt and block only new or expanded access.

## B) Gate Status Table

| Gate | Draft Status | Corrected Status | Notes |
| --- | --- | --- | --- |
| Data / Contracts Gate | PARTIAL | PASS AFTER CORRECTION | Added explicit public constructor, nav key, signed media, and storage-contract preservation checks. |
| Security / RLS Gate | PARTIAL | PASS WITH BASELINE EXCEPTION | No backend/RLS work. Existing `SignedImage` Supabase access must be baseline-diffed and not expanded. |
| Backend / Supabase Gate | PASS | PASS | Any schema/RLS/RPC/storage need requires a separate `Skill: supabase-migration` plan. |
| UI / Integration Gate | FAIL | PASS AFTER CORRECTION | Added exact adapter path, target list, signed media pass, owner/skill tags, and gate checks. |
| Release / QA Gate | FAIL | PASS AFTER CORRECTION | Made full coverage mandatory and added downstream smoke, scan, and manual width matrix gates. |

## C) Critical Gaps Found

### Gap 1: Draft was not a persisted PlanCritic source-of-truth gate.

- Why it will break: executors would not get decisions, gates, risks, and change report in one authoritative artifact.
- Fix: rewrite the plan into sections A-I and persist this critique file.
- Owner: @PlanCritic
- Acceptance check: corrected plan and critique artifact both exist.

### Gap 2: Runtime activation path was ambiguous.

- Why it will break: passive tokens do nothing; a global theme flip changes too much.
- Fix: require `lib/core/theme/designs/amber_dusk/amber_dusk_widget_theme.dart` before widget edits.
- Owner: @Architect
- Acceptance check: adapter file is exported from the token barrel and covered by tests.

### Gap 3: Adapter API was too vague.

- Why it will break: implementers would scatter Amber values across widgets.
- Fix: define typed roles for buttons, fields, icon buttons, cards, nav, tabs, badges, skeletons, and signed media placeholders.
- Owner: @Architect + @Pixel
- Acceptance check: adapter test asserts every role family.

### Gap 4: Signed media placeholders were missed.

- Why it will break: `signed_avatar.dart` still uses teal/gold defaults and raw initial text sizing.
- Fix: add visual-only signed media subphase.
- Owner: @Pixel
- Acceptance check: signed media tests cover placeholders without changing URL/cache/bucket behavior.

### Gap 5: Boundary scan ignored pre-existing `SignedImage` Supabase access.

- Why it will break: a naive no-Supabase scan already fails before implementation.
- Fix: baseline-diff `SignedImage` and block only new or expanded access in this phase.
- Owner: @Architect + @Sentinel
- Acceptance check: before/after scan is recorded in the session log.

### Gap 6: Full coverage was conditional.

- Why it will break: shared-widget changes can break downstream screens and CI enforces a 40% coverage floor.
- Fix: make `flutter test --coverage` mandatory.
- Owner: @Sentinel
- Acceptance check: coverage result is logged and remains at or above 40%.

### Gap 7: Existing TODO references include missing root files.

- Why it will break: future agents may follow broken Phase 0 handoff/checklist paths.
- Fix: docs sync validates that referenced artifacts exist and uses `.TODO/WebRedsign/` and `.TODO/Archive/` paths.
- Owner: @DocsKeeper
- Acceptance check: Phase 1 docs and handoff contain no broken artifact paths.

## D) Invariants And Success Criteria

- No new backend, Supabase schema, RLS, RPC, storage policy, Edge Function, SQL test, ViewModel, service, repository, provider, payment, booking, tender, wallet, or role-switch behavior.
- No new `BackdropFilter`, `ImageFilter.blur`, `GlassContainer`, `GlassCard`, or `GlassButton`.
- No recreation of deleted `glass_*` files.
- Shared reusable visual values are in tokens/theme/adapter files.
- Public constructors and navigation contracts stay compatible.
- `SignedImage` storage and URL resolution behavior stays unchanged.
- Full verification includes analyze, focused tests, downstream smoke tests, coverage, scans, and manual phone QA.

## E) Risk Register

| Risk | Where | Probability | Impact | Blast radius | Early signal | Prevention | Fallback |
| --- | --- | ---: | ---: | --- | --- | --- | --- |
| Shared-widget activation becomes global theme flip | `AppTheme`, widgets | Medium | High | Entire app | unrelated screens change | adapter-only activation | revert adapter wiring |
| Signed media visual pass changes storage behavior | `signed_image.dart`, `signed_avatar.dart` | Medium | High | images/avatars | URL/cache test failures | visual-only scope | revert signed media changes |
| Existing Supabase widget debt causes false failure | scans | High | Medium | QA | pre-edit scan fails | baseline-diff rule | separate architecture plan |
| Old teal/gold remains visible | nav, tabs, skeletons, signed media | High | Medium | shared UI | legacy color scan hits | exact target scans | fix or document exception |
| Skeleton tests hang | skeleton tests | Medium | Medium | test suite | `pumpAndSettle` timeout | use `pump(Duration)` | rewrite tests |
| Public API break | shared widgets | Medium | High | many screens | compile errors | preserve constructors | compatibility shim |
| Small-phone overflow | nav/buttons/badges | Medium | High | phone UX | 360px/text-scale issue | width matrix QA | adjust responsive constraints |
| Broken docs links | TODO/docs | Medium | Low | future work | missing file paths | path validation | patch docs references |

## F) Pre-Mortem

- This fails when widget edits start before the adapter contract exists.
- This fails when `glass_*` names from the parent plan are treated as live files.
- This fails when `SignedAvatar` keeps teal/gold defaults after Phase 1.
- This fails when `SignedImage` gets a casual Supabase refactor hidden in visual work.
- This fails when `pumpAndSettle()` is used on repeating skeleton animation tests.
- This fails when `flutter test --coverage` is skipped.
- This fails when Phase 1 docs link to missing root TODO artifacts.

## G) Plan Fixes

1. Rewrote Phase 1 plan into PlanCritic A-I format.
2. Persisted this critique at the required `.TODO/Archive/OpenDesign_AmberDusk_Phase1_2026-05-11/PLAN_CRITIQUE_2026-05-11_OpenDesign_AmberDusk_Phase1_CorePhoneWidgets.md` path.
3. Added exact adapter path and barrel export requirement.
4. Added signed media placeholder subphase.
5. Added baseline-diff rule for pre-existing `SignedImage` Supabase access.
6. Made full coverage mandatory.
7. Added stale TODO path validation.
8. Added explicit web handoff addendum requirement.

## H) Corrected Plan Reference

The corrected source-of-truth execution plan is:

`.TODO/Archive/OpenDesign_AmberDusk_Phase1_2026-05-11/PLAN_OpenDesign_AmberDusk_Phase1_CorePhoneWidgets_2026-05-11.md`

Implementation must follow that file, not the pre-critique draft or the Phase 1 section of the parent phone plan.

## I) Change Report Summary

### Original Issues Summary

- Draft was detailed but not a source-of-truth PlanCritic artifact.
- Activation strategy was ambiguous.
- Adapter API was too loose.
- Signed media related files were omitted.
- Pre-existing `SignedImage` Supabase debt was not accounted for.
- Full coverage was conditional.
- Stale Phase 0 artifact paths were not called out.

### Added Steps

- Source-of-truth setup gate.
- Evidence and baseline gate.
- Adapter contract and adapter tests.
- Signed media placeholder subphase.
- Mandatory coverage and downstream smoke tests.
- Boundary/legacy/dead-code scans.
- Manual width/text-scale QA.
- Docs and web handoff path validation.

### Removed Steps

- Any implication that `glass_button.dart`, `glass_card.dart`, or `glass_container.dart` should be recreated.
- Conditional coverage wording.
- Optional adapter wording.

### Reordered Steps

- Adapter before widget edits.
- Baseline scans before implementation.
- Verification before docs/handoff.

### Expanded Steps

- Every UI family now has owner, skill tag, behavior constraints, tests, and gate checks.
- Scans distinguish baseline debt from new debt.
- Manual QA includes width and text-scale matrices.

### Why

Phase 1 is the first runtime Amber Dusk activation path. The plan must be stricter than a normal widget styling task because shared widgets affect most screens and because Phase 0 tokens are passive until deliberately consumed.

### Residual Risks

- No golden-test infrastructure exists.
- `SignedImage` widget-level Supabase access remains as pre-existing architecture debt.
- Adapter implementation may reveal missing ergonomic token fields that must be added centrally.

