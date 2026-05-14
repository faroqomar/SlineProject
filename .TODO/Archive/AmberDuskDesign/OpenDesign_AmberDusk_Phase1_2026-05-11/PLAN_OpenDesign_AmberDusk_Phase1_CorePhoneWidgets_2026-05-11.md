# PLANCRITIC-CORRECTED PLAN: OpenDesign Amber Dusk Phase 1 Core Phone Widgets

Date: 2026-05-11
Status: PLANCRITIC-CORRECTED SOURCE OF TRUTH
Planning agent: Athena
Critic: PlanCritic
Scope: Phase 1 only, phone shared-widget runtime activation for Amber Dusk

Related artifacts:

- Parent phone plan: `.TODO/PLAN_OpenDesign_AmberDusk_Phone_2026-05-10.md`
- Prior Phase 1 draft superseded by this file: `.TODO/Archive/OpenDesign_AmberDusk_Phase1_2026-05-11/PLAN_OpenDesign_AmberDusk_Phase1_CorePhoneWidgets_2026-05-11.md`
- Critique artifact: `.TODO/Archive/OpenDesign_AmberDusk_Phase1_2026-05-11/PLAN_CRITIQUE_2026-05-11_OpenDesign_AmberDusk_Phase1_CorePhoneWidgets.md`
- Phase 1 session log: `docs/LOG/SESSION_PLAN_OpenDesign_AmberDusk_Phase1_CorePhoneWidgets_2026-05-11.md`
- Phase 0 source plan: `.TODO/Archive/OpenDesign_AmberDusk_Phase0_2026-05-11/PLAN_OpenDesign_AmberDusk_Phase0_PhoneFoundation_2026-05-11.md`
- Phase 0 critique: `.TODO/Archive/OpenDesign_AmberDusk_Phase0_2026-05-11/PLAN_CRITIQUE_2026-05-11_OpenDesign_AmberDusk_Phase0_PhoneFoundation.md`
- Phase 0 evidence: `.TODO/Archive/OpenDesign_AmberDusk_Phase0_2026-05-11/EVIDENCE_OpenDesign_AmberDusk_Phase0_2026-05-11.md`
- Phase 0 baseline: `.TODO/Archive/OpenDesign_AmberDusk_Phase0_2026-05-11/BASELINE_OpenDesign_AmberDusk_Phase0_2026-05-11.md`
- Phase 0 report: `.TODO/Archive/OpenDesign_AmberDusk_Phase0_2026-05-11/MASTER_REPORT_2026-05-11_OpenDesign_AmberDusk_Phase0.md`
- Phase 0 to web handoff: `.TODO/WebRedsign/HANDOFF_OpenDesign_AmberDusk_Phase0_ToWeb_2026-05-11.md`
- Phase 0 emulator checklist: `.TODO/Archive/EMULATOR_TEST_CHECKLIST_2026-05-11_OpenDesign_AmberDusk_Phase0.md`

## A) Assumptions And Decisions Needed

### A.1 Assumptions

- This pass is planning and critique only. It does not implement Flutter source changes.
- Phase 1 activates Amber Dusk visually only for listed shared phone widgets and the tab theme surface needed by those widgets.
- Phase 1 is not a global `MaterialApp` theme flip and does not replace `AppTheme.light()` or `AppTheme.dark()` wholesale.
- Phase 1 has broad runtime impact because shared widgets are used by many screens. Treat it as a high-blast-radius UI phase even though it is visual-only.
- Open Design MCP project `1674a1db-7a74-4c80-8e2c-196a0385a8f7`, Phase 0 evidence, and current repo scans are the visual and code evidence base.
- Phase 0 Amber Dusk tokens are staged and passive. Phase 1 must add a deliberate adapter/activation path before widgets depend on them.
- Backend, Supabase schema, RLS, RPCs, Edge Functions, storage policies, ViewModels, services, repositories, provider registration, and business flows are out of scope.
- `SignedImage` has pre-existing direct Supabase usage inside a core widget. Phase 1 must not expand that debt. Any architectural migration of signed media URL resolution requires a separate plan.

### A.2 Decisions Needed Before Code Edits

1. Shared-widget activation strategy
   - Missing decision: whether Phase 1 changes shared widgets globally, uses opt-in preview wrappers, or flips the entire app theme.
   - Options:
     - Activate Amber Dusk only inside the listed shared widgets through a typed adapter.
     - Keep widgets unchanged and build opt-in preview wrappers only.
     - Globally remap `AppTheme.light()` and `AppTheme.dark()` to Amber Dusk.
   - Recommended: activate only the listed shared widgets through `lib/core/theme/designs/amber_dusk/amber_dusk_widget_theme.dart`.
   - Why: this satisfies Phase 1's purpose while avoiding a full-app theme flip.
   - Plan impact: widget tests and manual QA must cover all touched shared families and representative downstream screens.

2. Signed media placeholder scope
   - Missing decision: whether `signed_avatar.dart` and `signed_image.dart` are included in core widgets.
   - Options:
     - Include narrow visual placeholder/error/initials styling only.
     - Defer them and document teal/gold leakage as an accepted Phase 1 exception.
   - Recommended: include narrow visual styling only.
   - Why: `signed_avatar.dart` currently uses `AppColors.teal`, `AppColors.gold`, and raw text sizing; these are visible shared-widget leaks.
   - Plan impact: tests must verify visuals without changing signed URL, cache, bucket, or Supabase fallback behavior.

3. Bottom navigation height
   - Missing decision: whether to change global `AppLayout.bottomNavHeight` from 70 to the Open Design 68 value.
   - Options:
     - Use `AmberDuskTokens.phoneLayout.bottomNavHeight` through the Phase 1 adapter.
     - Change global `AppLayout.bottomNavHeight`.
   - Recommended: use the adapter/phone-layout value for `CustomBottomNavBar` only.
   - Why: changing global layout tokens has broader impact than Phase 1 needs.
   - Plan impact: nav tests assert 68px Amber Dusk nav geometry without requiring a global layout-token migration.

4. Font packaging
   - Missing decision: whether to bundle Open Design font assets.
   - Options:
     - Bundle local WOFF2 files.
     - Use existing runtime font fallback/Google Fonts paths only.
   - Recommended: do not bundle Open Design font files in Phase 1.
   - Why: Phase 0 found no license/source evidence.
   - Plan impact: widget adapter typography maps roles and weights, but no `pubspec.yaml` font asset changes are allowed.

5. Pre-existing `SignedImage` Supabase debt
   - Missing decision: whether to fix the architecture debt while touching signed media visuals.
   - Options:
     - Visual-only changes, no URL-resolution refactor.
     - Move URL resolution out of `SignedImage`.
   - Recommended: visual-only changes.
   - Why: moving Supabase access out of a shared widget is valuable but outside this UI phase and would require architecture/test planning.
   - Plan impact: scans use baseline-diff acceptance: no new Supabase references, no changed signed URL behavior.

## B) Gate Status

| Gate | Status | Reason | Required fix to pass |
| --- | --- | --- | --- |
| Data / Contracts Gate | PASS AFTER CORRECTION | Public widget constructors, navigation keys, signed media storage contracts, and ViewModel contracts are preserved. | Add constructor/API preservation checks for every touched widget. |
| Security / RLS Gate | PASS WITH BASELINE EXCEPTION | No RLS or policy work is planned. `SignedImage` has pre-existing direct Supabase access and must not expand. | Record before/after `Supabase.instance` scan and do not change signed URL resolution semantics. |
| Backend / Supabase Gate | PASS | No tables, policies, RPCs, functions, buckets, migrations, SQL tests, or backend docs are changed by Phase 1. | Any backend need stops this plan and requires `Skill: supabase-migration`. |
| UI / Integration Gate | PASS AFTER CORRECTION | The draft had UI phases but not a strict adapter contract, missed signed media placeholders, and left activation scope ambiguous. | Add adapter-first phase, exact target list, owner/skill tags, and manual visual QA gates. |
| Release / QA Gate | PASS AFTER CORRECTION | The draft made `flutter test --coverage` conditional even though shared-widget blast radius is broad. | Make full coverage mandatory, add downstream smoke tests, and require artifact sanity checks. |

## C) Critical Gaps Corrected

### Gap 1: The prior Phase 1 draft was not in PlanCritic A-I source-of-truth format.

- Why it will break: executors would not have explicit decisions, gate status, risk register, and change report in the plan file.
- Fix: rewrite this plan into PlanCritic sections A-I and persist a critique artifact.
- Owner: @PlanCritic
- Acceptance check: this file and `.TODO/Archive/OpenDesign_AmberDusk_Phase1_2026-05-11/PLAN_CRITIQUE_2026-05-11_OpenDesign_AmberDusk_Phase1_CorePhoneWidgets.md` both exist.

### Gap 2: Runtime activation was ambiguous.

- Why it will break: importing passive Amber Dusk tokens by itself changes nothing, but a global `AppTheme` flip changes too much.
- Fix: add one typed shared-widget adapter and route listed widgets through it.
- Owner: @Architect
- Acceptance check: `amber_dusk_widget_theme.dart` exists, is exported through `amber_dusk_tokens.dart`, and tests prove widgets use it.

### Gap 3: The adapter contract was underspecified.

- Why it will break: implementers would scatter colors, radii, text styles, shadow recipes, and status maps into widgets.
- Fix: define typed roles for buttons, inputs, icon buttons, cards, nav, tabs, badges, skeletons, and signed media placeholders before widget edits.
- Owner: @Architect + @Pixel
- Acceptance check: adapter tests cover each role and no target widget introduces raw Amber values.

### Gap 4: Related signed media widgets were missed.

- Why it will break: `SignedAvatar` still renders teal/gold defaults and raw initial sizing even after "core widgets" are supposedly done.
- Fix: add a narrow media-placeholder subphase for `signed_avatar.dart` and `signed_image.dart`.
- Owner: @Pixel
- Acceptance check: no new `AppColors.teal`, `AppColors.gold`, `AppColors.lightRed`, or raw reusable visual defaults remain in signed media placeholders, except documented pre-existing non-target exceptions.

### Gap 5: Pre-existing `SignedImage` Supabase usage made the boundary scan unrealistic.

- Why it will break: a naive "no Supabase in widgets" scan already fails before Phase 1 starts.
- Fix: use baseline-diff scanning for `SignedImage` and block any new or expanded Supabase access.
- Owner: @Architect + @Sentinel
- Acceptance check: before/after scan shows no additional Supabase references and tests do not assert changed storage behavior.

### Gap 6: Full-suite coverage was conditional.

- Why it will break: shared widgets can affect many screens, and CI enforces a 40% coverage floor.
- Fix: make `flutter test --coverage` mandatory after focused widget tests.
- Owner: @Sentinel
- Acceptance check: coverage result is recorded in the session log and remains above 40%.

### Gap 7: Phase 0 documentation paths are inconsistent.

- Why it will break: existing docs/checklists still reference root `.TODO/HANDOFF...` and `.TODO/EMULATOR...` paths that are currently missing; the live handoff/checklist are under `.TODO/WebRedsign/` and `.TODO/Archive/`.
- Fix: Phase 1 docs sync must either correct those references or explicitly avoid relying on missing root files.
- Owner: @DocsKeeper
- Acceptance check: Phase 1 docs/handoff reference existing files only.

### Gap 8: Skeleton and animation test hazards were not strict enough.

- Why it will break: repeating shimmer and pulse animations hang under `pumpAndSettle()`.
- Fix: add `pump(Duration)` test rule for skeletons and pulses.
- Owner: @Sentinel
- Acceptance check: new/updated skeleton tests do not use `pumpAndSettle()` on repeating animations.

## D) Invariants And Success Criteria

### D.1 Non-Negotiable Invariants

- No feature view imports or calls Supabase directly.
- No new Supabase, storage, payment, RLS, SQL, Edge Function, migration, RPC, or bucket behavior is introduced.
- `SignedImage` pre-existing Supabase access is not expanded and its URL/cache/bucket behavior is unchanged.
- No ViewModel, service, repository, provider-registration, auth, navigation-contract, payment, booking, tender, wallet, chat, or role-switch business logic changes.
- Public constructors remain compatible for every touched shared widget unless the change is documented and tested before code edits continue.
- No `BackdropFilter`, `ImageFilter.blur`, `GlassContainer`, `GlassCard`, `GlassButton`, frosted glass, or blur substitute is introduced.
- Reusable colors, font sizes, radii, spacing, durations, shadows, gradients, and state maps live in theme/token/adapter files, not feature views or ad hoc widget constants.
- Stale `glass_button.dart`, `glass_card.dart`, and `glass_container.dart` targets are not recreated; they map to `AppStyledButton`, `AppCard`, and `AppCardContainer`.
- Bottom navigation keeps four visible destinations: Home, Dashboard, Messages, Profile.
- Existing `CustomBottomNavBar` static keys and `MainNavDestinations` contract remain valid.
- Storage paths remain paths; Phase 1 does not store or persist signed URLs.
- `AppLogger` discipline remains intact; no `print()` or `debugPrint()` is added.
- Fonts are not bundled without license/source evidence.

### D.2 Success Criteria

Phase 1 is complete only when all items below are true:

- Session log records PlanCritic rewrite, worktree status, Open Design evidence refresh, implementation decisions, verification, and final summary.
- `lib/core/theme/designs/amber_dusk/amber_dusk_widget_theme.dart` exists with top-level/public documentation comments.
- `amber_dusk_tokens.dart` exports the widget adapter.
- All planned widgets either consume the adapter/theme tokens or have a documented no-op reason:
  - `app_button.dart`
  - `app_styled_button.dart`
  - `scale_button.dart`
  - `app_text_field.dart`
  - `circle_icon_button.dart`
  - `app_card.dart`
  - `app_card_container.dart`
  - `custom_bottom_nav_bar.dart`
  - `sliver_tab_bar_delegate.dart`
  - `status_badge.dart`
  - `skeleton_loader.dart`
  - `skeleton_card.dart`
  - `skeleton_card_extended.dart`
  - `signed_avatar.dart`
  - `signed_image.dart` visual placeholder/error styling only
- `AppTheme.tabBarTheme` no longer uses teal-era active tab colors unless explicitly documented as an accepted exception.
- Focused tests are added or updated for adapter, buttons, fields, icon buttons, cards, nav, tabs, badges, skeletons, and signed media placeholders.
- `dart format --set-exit-if-changed` passes on changed Dart files.
- `flutter analyze --no-fatal-infos` passes.
- `flutter test test/core/theme/ test/core/widgets/` passes.
- Representative downstream widget smoke tests pass.
- `flutter test --coverage` passes and coverage remains at or above 40%.
- Baseline-diff scans show no new no-glass, Supabase, raw token, or legacy color debt.
- Manual phone QA at 360, 390, 402, and 430 widths is recorded.
- Docs sync and Phase 1 web handoff artifact use existing file paths.

## E) Risk Register

| Risk | Where | Probability | Impact | Blast radius | Early signal | Prevention | Fallback |
| --- | --- | ---: | ---: | --- | --- | --- | --- |
| Adapter changes become a hidden full-app theme flip | `AppTheme`, `MaterialApp`, shared widgets | Medium | High | Entire app | Many unrelated screens change at once | Keep activation inside listed widgets and tab theme only | Revert adapter wiring and keep tokens passive |
| Signed media visual changes alter storage behavior | `signed_avatar.dart`, `signed_image.dart` | Medium | High | Avatars/task images | tests fail, URL cache changes, Supabase errors | Do not touch `_resolve`, cache, bucket, TTL, generator logic | Revert signed media changes first |
| Pre-existing Supabase widget debt causes false gate failures | scans | High | Medium | QA gate | `rg Supabase.instance lib/core/widgets` fails before edits | Use before/after baseline diff | Open separate architecture plan |
| Old teal colors remain in shared widgets | nav, skeleton, signed media, tab theme | High | Medium | Visual system | `AppColors.teal/gold/lightRed` hits remain | Targeted legacy color scans per file | Document accepted exception or fix before close |
| Skeleton tests hang | skeleton/pulse tests | Medium | Medium | Test suite | `pumpAndSettle` timeout | Use `pump(Duration)` | Rewrite tests around bounded time advances |
| Public widget API breaks downstream call sites | shared widgets | Medium | High | Many screens | compile errors or changed constructor defaults | Preserve constructors and run call-site grep | Add compatibility shim |
| Fixed 402px artboard values break small phones | nav, skeleton, cards | Medium | High | Phone UX | overflow at 360px or text scale 1.3 | width matrix and safe-area QA | Use responsive constraints in adapter |
| Missing golden infra hides pixel drift | visual QA | Medium | Medium | Design quality | no pixel evidence | manual screenshots and focused geometry assertions | Add golden infra in a later dedicated plan |
| Docs point to missing Phase 0 files | handoff/checklist docs | Medium | Low | future agents | broken file references | docs sync path validation | patch docs references |

## F) Pre-Mortem

- This fails when the executor imports Amber Dusk tokens into widgets without a typed adapter, scattering values across 15 files.
- This fails when Phase 1 quietly becomes a global `AppTheme` rewrite and every screen becomes part of the QA scope.
- This fails when `signed_avatar.dart` keeps teal/gold defaults while the plan claims shared widgets are done.
- This fails when `signed_image.dart` storage resolution is refactored casually as part of visual cleanup.
- This fails when `pumpAndSettle()` is used on skeleton shimmer or badge pulse tests.
- This fails when bottom nav moves to 68px by editing a global layout token used elsewhere without downstream checks.
- This fails when `AppTheme.tabBarTheme` remains teal and tabs drift from the new shared surface system.
- This fails when Phase 1 docs link to missing root TODO handoff/checklist files.
- This fails when `flutter test --coverage` is skipped and the CI 40% floor regresses.

## G) Plan Fixes Applied

1. Goal: Make Phase 1 an explicit shared-widget activation, not a vague theme import.
   - Why: Phase 0 tokens are passive.
   - How: Add adapter-first phase with exact path and tests.
   - Output artifact: `amber_dusk_widget_theme.dart` and adapter test.
   - Stop condition: no widget edits before adapter contract passes.

2. Goal: Close stale target drift from the parent plan.
   - Why: `glass_*` files no longer exist.
   - How: map them to live solid-surface widgets and ban recreation.
   - Output artifact: plan target list and no-glass scan.
   - Stop condition: any new glass target blocks Phase 1.

3. Goal: Add discovered signed media placeholder work.
   - Why: live repo scan found visible teal/gold defaults in shared media widgets.
   - How: add a narrow visual-only subphase.
   - Output artifact: signed media tests and baseline-diff scan.
   - Stop condition: any storage/URL behavior change requires a separate plan.

4. Goal: Make release verification proportional to blast radius.
   - Why: shared widgets affect many screens.
   - How: make full coverage mandatory and add downstream smoke tests.
   - Output artifact: session log verification block.
   - Stop condition: analyze/tests/coverage failures block closure.

5. Goal: Fix docs traceability.
   - Why: some Phase 0 references point to missing root TODO files.
   - How: Phase 1 docs sync validates references before publishing handoff.
   - Output artifact: docs sync note and web handoff addendum.
   - Stop condition: broken artifact paths remain.

## H) Corrected Execution Plan

### H.0 Source-Of-Truth Setup

Primary Agent(s): @Sentinel, @PlanCritic

Goal: ensure execution starts from this corrected plan and critique artifact.
Why: the previous Phase 1 draft is superseded and had source-of-truth gaps.
How: record plan status, critique status, and worktree status before any code edit.
Result: executor has a clear audit trail and stop conditions.

#### H.0.1 Planning Artifact Resumption

Primary Agent(s): @Sentinel

- [ ] Owner: @Sentinel. Confirm this plan has `Status: PLANCRITIC-CORRECTED SOURCE OF TRUTH`.
- [ ] Owner: @Sentinel. Confirm `.TODO/Archive/OpenDesign_AmberDusk_Phase1_2026-05-11/PLAN_CRITIQUE_2026-05-11_OpenDesign_AmberDusk_Phase1_CorePhoneWidgets.md` exists.
- [ ] Owner: @Sentinel. Resume `docs/LOG/SESSION_PLAN_OpenDesign_AmberDusk_Phase1_CorePhoneWidgets_2026-05-11.md`.
- [ ] Owner: @Sentinel. Record `git status --short` before source edits.
- [ ] Owner: @Sentinel. Record that this plan supersedes the Phase 1 section in `.TODO/PLAN_OpenDesign_AmberDusk_Phone_2026-05-10.md` where it references deleted `glass_*` files.

GATE CHECK:

- PASS only if session log and critique artifact exist and this source plan is named in the log.

### H.1 Evidence And Baseline Gate

Primary Agent(s): @Planner, @Pixel, @Architect, @Sentinel, @Supabase_Ops

Goal: lock current design evidence, repo reality, and backend no-op status.
Why: Phase 1 touches high-use shared widgets and inherited stale targets.
How: refresh Open Design evidence, rescan live file paths, and capture before/after scan baselines.
Result: implementation starts from current evidence and known debt.

#### H.1.1 Open Design Evidence Refresh

Primary Agent(s): @Planner, @Pixel, @Sentinel

- [ ] Owner: @Planner | Skill: anthropic-skills:extract. Call Open Design MCP `get_project` for project `1674a1db-7a74-4c80-8e2c-196a0385a8f7`.
- [ ] Owner: @Planner | Skill: anthropic-skills:extract. Call Open Design MCP `list_files` and record `Sline V2 Amber Dusk.html`, `amber-dusk-design-system.html`, screenshots, and font asset metadata.
- [ ] Owner: @Planner | Skill: anthropic-skills:extract. Read `amber-dusk-design-system.html`.
- [ ] Owner: @Planner | Skill: anthropic-skills:extract. Read `Sline V2 Amber Dusk.html` for buttons, fields, cards, nav, tabs, statuses, and loading-state inference.
- [ ] Owner: @Pixel | Skill: anthropic-skills:critique. Record evidence gaps: no skeleton-specific spec, no font license, screenshots not text-readable, and no explicit signed media placeholder spec.
- [ ] Owner: @Sentinel | Skill: anthropic-skills:audit. If MCP is unavailable, stop and ask the user before using cached Phase 0 evidence.

GATE CHECK:

- PASS only if current Open Design evidence or explicit user-approved cached evidence is logged.

#### H.1.2 Repository Target And Related-File Inventory

Primary Agent(s): @Architect, @Sentinel

- [ ] Owner: @Architect. Validate all live target files with `rg --files`.
- [ ] Owner: @Architect. Record missing stale files: `glass_button.dart`, `glass_card.dart`, `glass_container.dart`.
- [ ] Owner: @Architect. Record replacement targets: `app_styled_button.dart`, `app_card.dart`, `app_card_container.dart`.
- [ ] Owner: @Architect. Include discovered related core widgets: `signed_avatar.dart` and `signed_image.dart`.
- [ ] Owner: @Architect. Explicitly exclude `fullscreen_image_viewer.dart` from Phase 1 unless a later scan proves it participates in the targeted shared-widget state changes.
- [ ] Owner: @Sentinel. Record current focused tests under `test/core/theme/` and `test/core/widgets/`, including missing `skeleton_loader_test.dart` and missing base `skeleton_card_test.dart`.

GATE CHECK:

- PASS only if every planned file exists or is explicitly a new file and every missing stale target is documented.

#### H.1.3 Backend And Boundary Baseline

Primary Agent(s): @Supabase_Ops, @Architect, @Sentinel

- [ ] Owner: @Supabase_Ops | Skill: supabase-migration. Confirm no Phase 1 work touches `supabase/migrations/`, `supabase/functions/`, `supabase/tests/`, storage policy docs, RLS docs, or RPC definitions.
- [ ] Owner: @Architect. Run before-edit scan for `Supabase.instance`, `.from(`, and `.rpc(` in planned target files.
- [ ] Owner: @Architect. Record `signed_image.dart` as pre-existing signed media debt if it appears in the scan.
- [ ] Owner: @Sentinel. Run before-edit scan for `print(` and `debugPrint(` in planned target files.
- [ ] Owner: @Sentinel. Run before-edit scan for `BackdropFilter`, `ImageFilter.blur`, `GlassContainer`, `GlassCard`, and `GlassButton`.
- [ ] Owner: @Sentinel. Run before-edit scan for `AppColors.(teal|lightTeal|lightRed|gold)`, `Color(0x`, `fontSize:`, `Duration(`, `BoxShadow(`, and `LinearGradient(` in planned target files.

GATE CHECK:

- PASS only if baseline debt is recorded and execution accepts no new Supabase/backend/no-glass debt.

### H.2 Amber Dusk Shared Widget Adapter

Primary Agent(s): @Architect, @Pixel, @Sentinel

Goal: create the single styling bridge from Phase 0 tokens to shared widgets.
Why: direct token use inside widgets would scatter design decisions.
How: add a typed adapter and tests before widget rewrites.
Result: widget implementation has a stable public contract.

#### H.2.1 Adapter Contract

Primary Agent(s): @Architect, @Pixel

- [ ] Owner: @Architect | Skill: anthropic-skills:extract. Create `lib/core/theme/designs/amber_dusk/amber_dusk_widget_theme.dart`.
- [ ] Owner: @Architect | Skill: anthropic-skills:extract. Add a top-level `///` file doc comment explaining what the adapter provides and why it exists.
- [ ] Owner: @Architect | Skill: anthropic-skills:extract. Export the adapter from `lib/core/theme/designs/amber_dusk/amber_dusk_tokens.dart`.
- [ ] Owner: @Pixel | Skill: anthropic-skills:normalize. Define typed button roles for primary, secondary/ghost, disabled, loading, success, error, focus, icon, and long-label states.
- [ ] Owner: @Pixel | Skill: anthropic-skills:normalize. Define typed field roles for fill, label, text, hint, prefix/suffix icon, focus, error, disabled, counter, clear, and password toggle states.
- [ ] Owner: @Pixel | Skill: anthropic-skills:normalize. Define typed icon-button, card, container, tab, nav, status badge, skeleton, signed avatar, and signed image placeholder roles.
- [ ] Owner: @Pixel | Skill: anthropic-skills:arrange. Use `AmberDuskTokens.phoneLayout.bottomNavHeight` for nav geometry without changing global `AppLayout.bottomNavHeight`.
- [ ] Owner: @Sentinel | Skill: anthropic-skills:audit. Verify adapter code contains no no-glass violations and no raw duplicated Open Design values outside token references.

GATE CHECK:

- PASS only if widgets can consume one central adapter API.

#### H.2.2 Adapter Tests

Primary Agent(s): @Sentinel, @Architect, @Pixel

- [ ] Owner: @Sentinel | Skill: anthropic-skills:audit. Add `test/core/theme/amber_dusk_widget_theme_test.dart`.
- [ ] Owner: @Sentinel | Skill: anthropic-skills:audit. Assert button min-height/radius/label roles match Phase 0/Open Design evidence.
- [ ] Owner: @Sentinel | Skill: anthropic-skills:audit. Assert field radius/fill/label/text roles match evidence.
- [ ] Owner: @Sentinel | Skill: anthropic-skills:audit. Assert nav height/radius/icon capsule and label roles match evidence.
- [ ] Owner: @Sentinel | Skill: anthropic-skills:audit. Assert skeleton colors are neutral Amber surfaces, not teal/gold/lightRed.
- [ ] Owner: @Sentinel | Skill: anthropic-skills:audit. Assert signed media placeholder colors and initials text style come from adapter roles.
- [ ] Owner: @Architect. Confirm tests import the public `amber_dusk_tokens.dart` entry point unless a private helper requires direct file access.

GATE CHECK:

- PASS only if adapter tests pass before widget code consumes the adapter.

### H.3 Primitive Controls

Primary Agent(s): @Pixel, @Architect, @Sentinel

Goal: align the shared button, icon button, scale, and text-field controls to Amber Dusk.
Why: these controls appear across auth, create, dashboard, payment, work, chat, and profile flows.
How: preserve constructors and behavior while routing default visuals through the adapter.
Result: primary controls stop using teal-era defaults.

#### H.3.1 `ScaleButton`

Primary Agent(s): @Pixel, @Architect, @Sentinel

- [ ] Owner: @Pixel | Skill: anthropic-skills:animate. Review `scaleAmount`, `duration`, `callbackDelay`, disabled behavior, and haptic path against `AmberDuskTokens.motion`.
- [ ] Owner: @Architect. Preserve the constructor and callback-delay semantics.
- [ ] Owner: @Pixel | Skill: anthropic-skills:animate. Keep any intentional non-token timing documented if it is interaction-specific rather than visual styling.
- [ ] Owner: @Sentinel | Skill: anthropic-skills:audit. Update `scale_button_test.dart` only if behavior or defaults intentionally change.

GATE CHECK:

- PASS only if press feedback behavior and tests remain deterministic.

#### H.3.2 `AppButton` And `AppStyledButton`

Primary Agent(s): @Pixel, @Architect, @Sentinel

- [ ] Owner: @Pixel | Skill: anthropic-skills:colorize. Replace teal-era default surfaces with adapter primary, ghost, disabled, success, error, focus, and foreground roles.
- [ ] Owner: @Pixel | Skill: anthropic-skills:arrange. Use stable min-height and radius so loading, icon, and long-label states do not resize the button unexpectedly.
- [ ] Owner: @Pixel | Skill: anthropic-skills:harden. Verify long labels fit at 360px width and text scale 1.3.
- [ ] Owner: @Architect. Preserve `AppButton` public constructor parameters, custom overrides, loading, success, error, disabled, and icon behavior.
- [ ] Owner: @Architect. Preserve `AppStyledButton` public constructor parameters and `ScaleButton` wrapping.
- [ ] Owner: @Sentinel | Skill: anthropic-skills:audit. Update `app_button_test.dart` for default, pressed, disabled, loading, success, error, focus, icon, custom override, and long-label cases.
- [ ] Owner: @Sentinel | Skill: anthropic-skills:audit. Update `app_styled_button_test.dart` for primary/secondary Amber differences and no-glass guardrails.

GATE CHECK:

- PASS only if behavior stays compatible and button state coverage exists.

#### H.3.3 `AppTextField`

Primary Agent(s): @Pixel, @Architect, @Sentinel

- [ ] Owner: @Pixel | Skill: anthropic-skills:normalize. Route field fill, radius, label, text, hint, border, focus, disabled, error, icon, and counter styling through adapter roles.
- [ ] Owner: @Pixel | Skill: anthropic-skills:harden. Preserve suffix priority: explicit `suffixIcon` beats password toggle and clear button.
- [ ] Owner: @Architect. Preserve controller ownership, validation behavior, `enabled`, `maxLines`, `maxLength`, clear button, and password toggle behavior.
- [ ] Owner: @Sentinel | Skill: anthropic-skills:audit. Update `app_text_field_test.dart` for focus, error, disabled, counter, password toggle, clear button, suffix priority, and long text.

GATE CHECK:

- PASS only if form behavior is unchanged and visual defaults come from the adapter.

#### H.3.4 `CircleIconButton`

Primary Agent(s): @Pixel, @Architect, @Sentinel

- [ ] Owner: @Pixel | Skill: anthropic-skills:normalize. Map default circle background, border, icon, hover/focus, and pressed states to adapter roles.
- [ ] Owner: @Pixel | Skill: anthropic-skills:harden. Preserve the 48dp minimum touch target and tooltip/semantics behavior.
- [ ] Owner: @Architect. Preserve custom `iconColor`, `backgroundColor`, `borderColor`, `size`, `iconSize`, and `tooltip` overrides.
- [ ] Owner: @Sentinel | Skill: anthropic-skills:audit. Update `circle_icon_button_test.dart` for Amber defaults, custom overrides, min touch target, tooltip, and semantics.

GATE CHECK:

- PASS only if icon-only controls remain accessible.

### H.4 Solid Surfaces And Tabs

Primary Agent(s): @Pixel, @Architect, @Sentinel

Goal: align reusable solid surfaces and tab defaults.
Why: later screen phases depend on stable cards, containers, and tabs.
How: replace glass-era/teal-era assumptions with adapter roles while preserving public APIs.
Result: shared surfaces are Amber Dusk compatible without blur.

#### H.4.1 `AppCardContainer` And `AppCard`

Primary Agent(s): @Pixel, @Architect, @Sentinel

- [ ] Owner: @Pixel | Skill: anthropic-skills:normalize. Route default fill, radius, padding, border/rim, and elevation roles through the adapter or active theme tokens.
- [ ] Owner: @Pixel | Skill: anthropic-skills:distill. Keep deprecated `blurRadius` ignored and do not resurrect blur behavior.
- [ ] Owner: @Architect. Preserve `AppCardContainer({child, padding, margin, borderRadius, elevation, blurRadius})`.
- [ ] Owner: @Architect. Preserve `AppCard({child, onTap, padding, margin, width, height, borderRadius, elevation, disabled})`.
- [ ] Owner: @Sentinel | Skill: anthropic-skills:audit. Update `app_card_container_test.dart` and `app_card_test.dart` for Amber defaults, custom overrides, tap behavior, disabled behavior, and no `BackdropFilter`.

GATE CHECK:

- PASS only if no glass/blur exists and public APIs are unchanged.

#### H.4.2 `SliverTabBarDelegate` And `AppTheme.tabBarTheme`

Primary Agent(s): @Pixel, @Architect, @Sentinel

- [ ] Owner: @Pixel | Skill: anthropic-skills:colorize. Replace teal tab label/indicator values in `lib/core/theme/app_theme.dart` with adapter-compatible Amber roles.
- [ ] Owner: @Pixel | Skill: anthropic-skills:normalize. Keep `SliverTabBarDelegate` background solid and aligned with card/nav surfaces.
- [ ] Owner: @Architect. Preserve `SliverTabBarDelegate(TabBar tabBar, {Color? backgroundColor})`, `maxExtent`, `minExtent`, and `shouldRebuild` behavior.
- [ ] Owner: @Sentinel | Skill: anthropic-skills:audit. Update `sliver_tab_bar_delegate_test.dart`.
- [ ] Owner: @Sentinel | Skill: anthropic-skills:audit. Add or update theme tests for `AppTheme.tabBarTheme` Amber active values.

GATE CHECK:

- PASS only if no teal active tab path remains unless documented as an accepted exception.

### H.5 Bottom Navigation

Primary Agent(s): @Pixel, @Architect, @Sentinel

Goal: align the shared bottom navigation to Amber Dusk phone evidence.
Why: bottom nav is the primary app-shell visual anchor.
How: preserve provider/index/key contracts while replacing visual roles.
Result: nav uses compact dark surface, amber active capsule, safe insets, and semantic badges.

#### H.5.1 Contract Preservation

Primary Agent(s): @Architect, @Sentinel

- [ ] Owner: @Architect. Preserve `CustomBottomNavBar()` and static keys `homeNavKey`, `dashboardNavKey`, deprecated `ordersNavKey`, `messagesNavKey`, and `profileNavKey`.
- [ ] Owner: @Architect. Preserve four visible destinations from `MainNavDestinations`: Home, Dashboard, Messages, Profile.
- [ ] Owner: @Architect. Preserve `NavigationProvider.setCurrentIndex` usage.
- [ ] Owner: @Architect. Preserve stale-index `AppLogger.w` instrumentation.
- [ ] Owner: @Sentinel | Skill: anthropic-skills:audit. Keep tests for four items, tap behavior, semantics, and Android bottom inset behavior.

GATE CHECK:

- PASS only if navigation indexes, keys, provider behavior, and logging remain unchanged.

#### H.5.2 Amber Dusk Nav Visuals

Primary Agent(s): @Pixel, @Architect, @Sentinel

- [ ] Owner: @Pixel | Skill: anthropic-skills:arrange. Use adapter nav height, inset, radius, active icon capsule, label sizing, and spacing.
- [ ] Owner: @Pixel | Skill: anthropic-skills:colorize. Replace `AppColors.teal` and `AppColors.lightRed` nav defaults with Amber primary and semantic roles.
- [ ] Owner: @Pixel | Skill: anthropic-skills:harden. Verify labels ellipsize at 360px and text scale 1.3 without overlap.
- [ ] Owner: @Sentinel | Skill: anthropic-skills:audit. Update `custom_bottom_nav_bar_test.dart` for active capsule, badge styling, no teal references, safe-area inset, semantics, and four-destination contract.

GATE CHECK:

- PASS only if `rg "AppColors\\.(teal|lightTeal|lightRed|gold)" lib/core/widgets/custom_bottom_nav_bar.dart` returns no unapproved hits.

### H.6 Status, Skeletons, And Signed Media Placeholders

Primary Agent(s): @Pixel, @Architect, @Sentinel

Goal: align non-command shared state surfaces.
Why: badges, skeletons, and signed media placeholders appear across many feature screens.
How: use adapter semantic roles while preserving behavior and storage contracts.
Result: loading, status, avatar, and image fallbacks no longer leak old brand styling.

#### H.6.1 `StatusBadge`

Primary Agent(s): @Pixel, @Architect, @Sentinel

- [ ] Owner: @Pixel | Skill: anthropic-skills:colorize. Map setup/timeout to muted, waiting/review to amber, active/won to forest, completed/closed/refunded to cream, and failure/cancellation to rust.
- [ ] Owner: @Pixel | Skill: anthropic-skills:harden. Preserve icon/text indicators so color is not the only status signal.
- [ ] Owner: @Architect. Preserve `StatusBadge({required text, color, isSmall})`, `fromWorkItem`, and `fromStatus`.
- [ ] Owner: @Sentinel | Skill: anthropic-skills:audit. Update `status_badge_test.dart` for semantic map, custom override, pill shape, semantics, and pulse timing.

GATE CHECK:

- PASS only if status behavior and accessibility remain intact.

#### H.6.2 `SkeletonLoader`

Primary Agent(s): @Pixel, @Architect, @Sentinel

- [ ] Owner: @Pixel | Skill: anthropic-skills:normalize. Replace teal-era shimmer base/highlight values with Amber neutral surface roles.
- [ ] Owner: @Pixel | Skill: anthropic-skills:animate. Preserve repeating shimmer duration/curve through `AppMotion` or Amber motion roles.
- [ ] Owner: @Architect. Preserve `SkeletonLoader({width, height, borderRadius, isCircle})`, `SkeletonText`, and `SkeletonAvatar`.
- [ ] Owner: @Sentinel | Skill: anthropic-skills:audit. Add `test/core/widgets/skeleton_loader_test.dart`.
- [ ] Owner: @Sentinel | Skill: anthropic-skills:audit. Use `pump(Duration)` and do not use `pumpAndSettle()` for repeating shimmer tests.

GATE CHECK:

- PASS only if skeleton loader no longer depends on teal-era colors and tests cannot hang.

#### H.6.3 `SkeletonCard` And `SkeletonCardExtended`

Primary Agent(s): @Pixel, @Architect, @Sentinel

- [ ] Owner: @Pixel | Skill: anthropic-skills:arrange. Update base variants: task, booking, offer, message bubble, conversation tile, search result, category tile, favorite card, details screen.
- [ ] Owner: @Pixel | Skill: anthropic-skills:arrange. Update extended variants: wallet hero, proposal tile, work item card, notification tile, service card, favorite card, search result, profile card.
- [ ] Owner: @Pixel | Skill: anthropic-skills:normalize. Replace raw shadows, gradients, radii, and legacy colors with adapter/theme tokens where those values are reusable.
- [ ] Owner: @Pixel | Skill: anthropic-skills:harden. Verify skeleton geometry remains stable at 360, 390, 402, and 430 widths.
- [ ] Owner: @Sentinel | Skill: anthropic-skills:audit. Add `test/core/widgets/skeleton_card_test.dart` for base variants.
- [ ] Owner: @Sentinel | Skill: anthropic-skills:audit. Update `skeleton_card_extended_test.dart` with no-legacy-color/no-glass and representative geometry assertions.

GATE CHECK:

- PASS only if skeleton-to-final layout-shift risk is tested or captured in manual QA.

#### H.6.4 `SignedAvatar` And `SignedImage` Visual Placeholders

Primary Agent(s): @Pixel, @Architect, @Sentinel

- [ ] Owner: @Pixel | Skill: anthropic-skills:colorize. Replace `SignedAvatar` default placeholder, initials, icon, border, and online-indicator surface roles with adapter/theme roles.
- [ ] Owner: @Pixel | Skill: anthropic-skills:normalize. Replace `SignedImage` error/empty placeholder visuals with adapter/image-placeholder roles.
- [ ] Owner: @Architect. Do not change `_resolve`, `SignedUrlCache`, `DefaultSignedUrlGenerator`, bucket names, TTL handling, public URL fallback, or Supabase fallback behavior.
- [ ] Owner: @Architect. Preserve `SignedAvatar` and `SignedImage` constructors.
- [ ] Owner: @Sentinel | Skill: anthropic-skills:audit. Update `signed_avatar_test.dart` for placeholder, initials, custom background override, rounded rectangle, online indicator, and semantics.
- [ ] Owner: @Sentinel | Skill: anthropic-skills:audit. Update `signed_image_test.dart` for empty/error placeholder styling, skeleton use, retry semantics, and no spinner regression.
- [ ] Owner: @Sentinel. Compare before/after `Supabase.instance` scan and record no added signed media backend debt.

GATE CHECK:

- PASS only if signed media visuals change without changing signed URL/storage behavior.

### H.7 Automated Verification

Primary Agent(s): @Sentinel, @CodeGuard, @Architect

Goal: prove Phase 1 compiles, tests, and respects architecture/design guardrails.
Why: shared-widget changes are high blast radius.
How: run focused tests first, then full coverage and scan gates.
Result: Phase 1 has CI-quality evidence before manual QA.

#### H.7.1 Format, Analyze, And Tests

Primary Agent(s): @Sentinel

- [ ] Owner: @Sentinel. Run `dart format --set-exit-if-changed lib/core/widgets lib/core/theme test/core/widgets test/core/theme`.
- [ ] Owner: @Sentinel. Run `flutter analyze --no-fatal-infos`.
- [ ] Owner: @Sentinel. Run `flutter test test/core/theme/ test/core/widgets/`.
- [ ] Owner: @Sentinel. Run downstream smoke tests for app navigation and representative cards/details screens:
  - `flutter test test/widget/app/main_navigation_screen_test.dart`
  - `flutter test test/widget/cards/task_card_test.dart`
  - `flutter test test/widget/cards/booking_task_card_test.dart`
  - `flutter test test/widget/tasks/task_details_screen_test.dart`
  - `flutter test test/widget/booking/booking_details_screen_test.dart`
- [ ] Owner: @Sentinel. Run `flutter test --coverage` and record total coverage.
- [ ] Owner: @Sentinel. Verify coverage remains at or above the CI 40% floor.

GATE CHECK:

- PASS only if analyze and required tests pass, or documented failures block closure.

#### H.7.2 Boundary, Legacy, And Dead-Code Scans

Primary Agent(s): @CodeGuard, @Architect, @Sentinel

- [ ] Owner: @Architect. Run before/after diff scan for `Supabase.instance|\\.from\\(|\\.rpc\\(` in planned target files.
- [ ] Owner: @CodeGuard. Run `rg -n "print\\(|debugPrint\\(" lib/core/widgets lib/core/theme/designs/amber_dusk`.
- [ ] Owner: @CodeGuard. Run `rg -n "BackdropFilter|ImageFilter\\.blur|GlassContainer|GlassCard|GlassButton" lib/core/widgets lib/core/theme/designs/amber_dusk test/core/widgets test/core/theme`.
- [ ] Owner: @CodeGuard. Run `rg -n "AppColors\\.(teal|lightTeal|lightRed|gold)" lib/core/widgets lib/core/theme/app_theme.dart`.
- [ ] Owner: @CodeGuard. Run `rg -n "Color\\(0x|#[0-9A-Fa-f]{6}|fontSize:|Duration\\(|BoxShadow\\(|LinearGradient\\(" lib/core/widgets lib/core/theme/designs/amber_dusk`.
- [ ] Owner: @CodeGuard. Run duplicate test id scan: `grep -rn 'T[0-9]\\{3\\}' test/ | sed 's/:.*//' | sort | uniq -d`.
- [ ] Owner: @Sentinel. Classify every remaining hit as fixed, pre-existing, or intentional with file/line notes in the session log.

GATE CHECK:

- PASS only if no new unapproved raw token, no-glass, logging, Supabase, or duplicate test-id debt remains.

### H.8 Manual Phone Visual QA

Primary Agent(s): @Pixel, @Sentinel

Goal: verify visual outcomes that tests cannot prove.
Why: there is no golden-test infrastructure for this phase.
How: capture screenshots or concise manual evidence notes across representative widths and states.
Result: later feature phases can trust the shared widget layer.

#### H.8.1 Width, Text Scale, And State Matrix

Primary Agent(s): @Pixel, @Sentinel

- [ ] Owner: @Pixel | Skill: anthropic-skills:audit. Verify representative controls at 360, 390, 402, and 430 logical-pixel widths.
- [ ] Owner: @Pixel | Skill: anthropic-skills:harden. Verify text scale 1.3 for button labels, nav labels, field text, badge text, initials, image retry text, and skeleton placeholders.
- [ ] Owner: @Pixel | Skill: anthropic-skills:audit. Verify dark mode and derived-light mode where adapter supports both.
- [ ] Owner: @Pixel | Skill: anthropic-skills:audit. Verify bottom nav remains above Android/iOS safe-area insets.
- [ ] Owner: @Pixel | Skill: anthropic-skills:audit. Verify one representative screen or harness per widget family: buttons, fields, cards, nav, tabs, badges, skeletons, signed media.
- [ ] Owner: @Sentinel. Record screenshot paths or manual evidence notes in the session log.

GATE CHECK:

- PASS only if no overlap, clipped text, stale teal active states, or skeleton-to-content layout jumps are accepted.

### H.9 Docs Sync And Handoff

Primary Agent(s): @DocsKeeper, @Sentinel, @Pixel

Goal: keep docs and web handoff aligned with the implemented shared-widget contract.
Why: later phone phases and Mohammed's web phase depend on this shared layer.
How: update docs only after code and verification evidence exist.
Result: downstream plans use real files and correct caveats.

#### H.9.1 Docs Sync

Primary Agent(s): @DocsKeeper, @Sentinel

- [ ] Owner: @DocsKeeper. Update `Sline_everything/DEVELOPER_GUIDE.md` if Phase 1 changes active shared-widget runtime behavior or adapter guidance.
- [ ] Owner: @DocsKeeper. Update `Sline_everything/STRUCTURE.md` if `amber_dusk_widget_theme.dart` is added.
- [ ] Owner: @DocsKeeper. Update `Sline_everything/CODE_REVIEW.md` if new review rules emerge for Amber shared widgets or signed media placeholders.
- [ ] Owner: @DocsKeeper. Write `.TODO/Archive/OpenDesign_AmberDusk_Phase1_2026-05-11/DOCS_SYNC_2026-05-11_OpenDesign_AmberDusk_Phase1_CoreWidgets.md`.
- [ ] Owner: @DocsKeeper. Correct or avoid stale root-level Phase 0 handoff/checklist references, because current live files are under `.TODO/WebRedsign/` and `.TODO/Archive/`.
- [ ] Owner: @Sentinel. Confirm docs do not claim a global Amber Dusk theme flip unless implementation actually did one.

GATE CHECK:

- PASS only if docs describe the actual activation scope and all artifact links exist.

#### H.9.2 Phone-To-Web Handoff Addendum

Primary Agent(s): @DocsKeeper, @Pixel, @Sentinel

- [ ] Owner: @DocsKeeper. Add `.TODO/WebRedsign/HANDOFF_OpenDesign_AmberDusk_Phase1_CoreWidgets_ToWeb_2026-05-11.md`.
- [ ] Owner: @Pixel | Skill: anthropic-skills:adapt. Record which adapter values are phone-only and which are reusable for web.
- [ ] Owner: @Pixel | Skill: anthropic-skills:adapt. Record that web-specific breakpoints still belong under `lib/core/theme/designs/amber_dusk/web/`.
- [ ] Owner: @Sentinel. Confirm the handoff references this plan, the critique artifact, session log, and verification evidence.

GATE CHECK:

- PASS only if Mohammed can consume Phase 1 without guessing target files, adapter APIs, or caveats.

## I) Change Report

### I.1 Original Issues Summary

- The Phase 1 draft was detailed but not formatted as a PlanCritic source-of-truth gate.
- The draft did not persist a PlanCritic critique artifact.
- Runtime activation was ambiguous between passive tokens, shared-widget activation, and global theme activation.
- The adapter was described as optional "for example" instead of an exact required file/API.
- The target list missed `signed_avatar.dart` and `signed_image.dart` even though live scans found shared visual debt.
- The boundary scan did not account for pre-existing `SignedImage` Supabase access.
- Full coverage was conditional despite shared-widget blast radius.
- Docs sync did not call out stale Phase 0 root TODO paths.

### I.2 Added Steps

- Added H.0 source-of-truth setup.
- Added exact adapter contract and adapter tests.
- Added signed media placeholder subphase.
- Added baseline-diff scan for `SignedImage` Supabase debt.
- Added mandatory full coverage.
- Added stale docs path validation.
- Added explicit web handoff addendum for Phase 1.

### I.3 Removed Steps

- Removed any implication that deleted `glass_*` files should be recreated.
- Removed conditional full-coverage wording.
- Removed vague adapter wording.

### I.4 Reordered Steps

- Adapter now precedes all widget edits.
- Baseline scans now precede implementation.
- Focused tests now precede downstream smoke tests and full coverage.
- Docs/handoff happen after verification, not before.

### I.5 Expanded Steps

- Button, text-field, nav, skeleton, tab, status, and signed media work now name exact owners, skills, behavior preservation points, tests, and gate checks.
- QA now includes width matrix, text scale, safe-area, and state coverage.
- Scans now distinguish baseline debt from new regressions.

### I.6 Why

Phase 1 is the first runtime Amber Dusk activation. Shared widgets have app-wide reach, and the prior draft left too much for the executor to infer. This rewrite narrows the activation mechanism, broadens verification, and adds discovered related files before implementation begins.

### I.7 Residual Risks

- Pixel accuracy remains limited without golden-test infrastructure.
- `SignedImage` still has pre-existing widget-level Supabase access after Phase 1 unless a separate architecture plan addresses it.
- The adapter may reveal missing ergonomic token fields during implementation; add them centrally instead of hardcoding.
- Manual QA remains required for phone safe-area and text-scale behavior.

## J) Phase 1 Visual Notes Appended During Execution

Date: 2026-05-11
Executor: Codex @Executor
Status: Open Design reference evidence recorded before implementation

Open Design MCP was rechecked before writing Phase 1 widget changes against
project `1674a1db-7a74-4c80-8e2c-196a0385a8f7`, active artifact
`Sline V2 Amber Dusk.html`.

Reference screenshot pack:

- `.TODO/Archive/OpenDesign_AmberDusk_Phase1_2026-05-11/OpenDesign_AmberDusk_Phase1_OpenDesignScreenshots_2026-05-11/opendesign-360-home.png`
- `.TODO/Archive/OpenDesign_AmberDusk_Phase1_2026-05-11/OpenDesign_AmberDusk_Phase1_OpenDesignScreenshots_2026-05-11/opendesign-360-dashboard.png`
- `.TODO/Archive/OpenDesign_AmberDusk_Phase1_2026-05-11/OpenDesign_AmberDusk_Phase1_OpenDesignScreenshots_2026-05-11/opendesign-360-messages.png`
- `.TODO/Archive/OpenDesign_AmberDusk_Phase1_2026-05-11/OpenDesign_AmberDusk_Phase1_OpenDesignScreenshots_2026-05-11/opendesign-360-profile.png`
- `.TODO/Archive/OpenDesign_AmberDusk_Phase1_2026-05-11/OpenDesign_AmberDusk_Phase1_OpenDesignScreenshots_2026-05-11/opendesign-390-home.png`
- `.TODO/Archive/OpenDesign_AmberDusk_Phase1_2026-05-11/OpenDesign_AmberDusk_Phase1_OpenDesignScreenshots_2026-05-11/opendesign-390-dashboard.png`
- `.TODO/Archive/OpenDesign_AmberDusk_Phase1_2026-05-11/OpenDesign_AmberDusk_Phase1_OpenDesignScreenshots_2026-05-11/opendesign-390-messages.png`
- `.TODO/Archive/OpenDesign_AmberDusk_Phase1_2026-05-11/OpenDesign_AmberDusk_Phase1_OpenDesignScreenshots_2026-05-11/opendesign-390-profile.png`
- `.TODO/Archive/OpenDesign_AmberDusk_Phase1_2026-05-11/OpenDesign_AmberDusk_Phase1_OpenDesignScreenshots_2026-05-11/opendesign-402-home.png`
- `.TODO/Archive/OpenDesign_AmberDusk_Phase1_2026-05-11/OpenDesign_AmberDusk_Phase1_OpenDesignScreenshots_2026-05-11/opendesign-402-dashboard.png`
- `.TODO/Archive/OpenDesign_AmberDusk_Phase1_2026-05-11/OpenDesign_AmberDusk_Phase1_OpenDesignScreenshots_2026-05-11/opendesign-402-messages.png`
- `.TODO/Archive/OpenDesign_AmberDusk_Phase1_2026-05-11/OpenDesign_AmberDusk_Phase1_OpenDesignScreenshots_2026-05-11/opendesign-402-profile.png`
- `.TODO/Archive/OpenDesign_AmberDusk_Phase1_2026-05-11/OpenDesign_AmberDusk_Phase1_OpenDesignScreenshots_2026-05-11/opendesign-430-home.png`
- `.TODO/Archive/OpenDesign_AmberDusk_Phase1_2026-05-11/OpenDesign_AmberDusk_Phase1_OpenDesignScreenshots_2026-05-11/opendesign-430-dashboard.png`
- `.TODO/Archive/OpenDesign_AmberDusk_Phase1_2026-05-11/OpenDesign_AmberDusk_Phase1_OpenDesignScreenshots_2026-05-11/opendesign-430-messages.png`
- `.TODO/Archive/OpenDesign_AmberDusk_Phase1_2026-05-11/OpenDesign_AmberDusk_Phase1_OpenDesignScreenshots_2026-05-11/opendesign-430-profile.png`

Step 5 gap-scan note:

- The screenshot pack is a provisional Open Design width reference, not
  route-specific runtime visual QA evidence.
- Hash sanity found identical route captures for all 360px, 390px, and 402px
  images, plus identical 430px messages/profile captures.
- A local downloaded `Sline V2 Amber Dusk.html` file was checked during the
  gap scan, but it did not match the current Open Design MCP artifact and was
  not used as replacement evidence.
- Step 6 must recapture or verify runtime visual evidence before any final test
  checklist treats route screenshots as complete.

Visual notes from the Open Design evidence:

- Buttons use a borderless 46px control height, 15px radius, 18px horizontal
  padding, and 13px/800 labels.
- Text fields use a solid dark fill, 16px radius, 13px horizontal and 12px
  vertical padding, uppercase 11.5px/800 labels, and no visible border.
- Bottom navigation is a compact four-destination phone shell with a solid
  `bg2` surface, 26px radius, and a small amber active icon capsule.
- Cards and panels use solid Amber Dusk surfaces; no glass or blur treatment is
  part of the Phase 1 source design.
- Status pills are uppercase, compact, pill-radius capsules using primary,
  rust, and forest semantic overlays.
- Avatar and media fallback colors are warm/cool Amber-adjacent placeholders;
  signed URL behavior is not part of the visual note scope.
- Skeletons have no dedicated Open Design spec, so Phase 1 derives them from
  final component geometry and Amber Dusk surface steps only.

Runtime app screenshots were not added here. Flutter runtime confidence for
Step 5 is limited to focused geometry/widget tests, downstream widget smoke
tests, analyze, and guardrail scans. Golden screenshot infrastructure and a
clean route screenshot pass remain Step 6/later-phase evidence gaps.
