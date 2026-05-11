# PLAN: OpenDesign Amber Dusk Phase 0 Phone Foundation

Date: 2026-05-11
Status: PLANCRITIC-CORRECTED SOURCE OF TRUTH
Planning agent: Athena
Critic: PlanCritic
Scope: Phase 0 only, phone-first design-system foundation

Related files:

- Parent phone plan: `.TODO/PLAN_OpenDesign_AmberDusk_Phone_2026-05-10.md`
- Web dependency plan: `.TODO/PLAN_OpenDesign_AmberDusk_Web_Mohammed_2026-05-10.md`
- Critique artifact: `.TODO/Archive/OpenDesign_AmberDusk_Phase0_2026-05-11/PLAN_CRITIQUE_2026-05-11_OpenDesign_AmberDusk_Phase0_PhoneFoundation.md`
- Session log: `docs/LOG/SESSION_PLAN_OpenDesign_AmberDusk_Phase0_PhoneFoundation_2026-05-11.md`
- Project design constraints: `.impeccable.md`
- Architecture references:
  - `Sline_everything/ARCHITECTURE_ANALYSIS.md`
  - `Sline_everything/DEVELOPER_GUIDE.md`
  - `Sline_everything/CODE_REVIEW.md`

## A. Assumptions And Decision Needed

### A.1 Assumptions

- This plan covers Phase 0 from the phone plan only: the reusable Amber Dusk phone design-system foundation.
- This plan does not implement phone screens, web screens, dashboard screens, backend data changes, or migration work.
- Open Design MCP evidence is the visual source of truth for Amber Dusk, but existing SLine architecture and `.impeccable.md` are hard constraints.
- Existing design-system files are already in place. Phase 0 must adapt or extend them carefully, not recreate the old foundation work.
- Phase 0 may create new token/layout/adaptor files under `lib/core/theme/designs/amber_dusk/`.
- Phase 0 may add focused tests under `test/core/theme/`.
- Phase 0 may add TODO/docs/log artifacts.
- Phase 0 must not modify feature ViewModels, services, repositories, Supabase config, migrations, SQL tests, edge functions, or storage policies.

### A.2 Decisions Required Before Code Edits

Implementation must record the chosen decision in the session log before editing Flutter files.

| Decision | Recommended Decision | Blocker If Different |
| --- | --- | --- |
| Theme activation | Stage Amber Dusk as a named design layer. Do not flip the app default theme in Phase 0. | If global activation is requested, add full-app visual QA and full `flutter test` to this phase. |
| Fonts | Do not bundle Open Design font files until license/source evidence is documented. Define font tokens with safe fallbacks. | If bundling fonts, document license/source and run asset/build verification. |
| Blur/glass | Use solid surfaces only. No `BackdropFilter`, `GlassContainer`, `GlassCard`, or `GlassButton`. | If blur is required, stop and get explicit approval because `.impeccable.md` forbids it. |
| Light mode | Provide API-parity light tokens as derived fallbacks, clearly labeled as not Open Design-authored. | If no light tokens are created, do not wire Amber Dusk into shared theme APIs used by light mode. |
| Web handoff | Produce a phone Phase 0 handoff artifact before Mohammed starts web theme work. | Web Phase 0 cannot safely proceed without this artifact. |

## B. Gate Status

| Gate | Status | Source-Of-Truth Requirement |
| --- | --- | --- |
| PlanCritic format | PASS | This plan follows sections A-I and supersedes the pre-critique v1 plan. |
| Open Design evidence | REQUIRED BEFORE EDIT | Implementation must refresh MCP metadata and write `.TODO/Archive/OpenDesign_AmberDusk_Phase0_2026-05-11/EVIDENCE_OpenDesign_AmberDusk_Phase0_2026-05-11.md`. |
| Existing theme contract | REQUIRED BEFORE EDIT | Implementation must scan current theme files and write baseline findings before editing. |
| Backend/RLS | PASS, HARD OUT OF SCOPE | Any backend or Supabase need stops Phase 0 and requires a separate plan. |
| UI architecture | PASS AFTER REQUIRED SCANS | New reusable values belong under `lib/core/theme/`, not feature views. |
| Testing | PASS AFTER BASELINE | Targeted core theme/widget tests are required; full suite is conditional on global activation. |
| Docs/handoff | REQUIRED BEFORE DONE | Session log, docs-sync note, and web handoff artifact are completion gates. |

## C. Critical Gaps Corrected

1. The pre-critique plan did not use PlanCritic A-I source-of-truth format.
2. It did not make current SLine theme infrastructure a blocking inventory gate.
3. It left Amber Dusk global activation ambiguous.
4. It did not block Open Design font bundling on source/license evidence.
5. It did not resolve the Open Design blur versus `.impeccable.md` no-glass conflict.
6. It did not define light-mode parity strongly enough.
7. It did not require exact raw-token and test baselines before implementation.
8. It did not define an import/export contract for the new Amber Dusk folder.
9. It did not tie Mohammed's web dependency to a concrete phone handoff artifact.

## D. Invariants And Success Criteria

### D.1 Hard Invariants

- No Supabase imports, calls, queries, auth checks, realtime channels, edge functions, migrations, RLS policies, SQL tests, or storage policy edits.
- No feature screen owns reusable Amber Dusk tokens.
- No new raw reusable colors, font sizes, spacing, radii, durations, curves, shadows, or gradients outside approved theme/token files.
- No new `BackdropFilter`, `GlassContainer`, `GlassCard`, or `GlassButton`.
- No direct business logic or data fetching in views.
- No global theme activation unless explicitly recorded as an approved decision.
- No font asset bundling unless license/source evidence is recorded.
- Do not delete or rewrite existing design-system foundations without a direct code-evidence reason.
- Do not create web-specific files in Phase 0 except the phone-to-web handoff artifact.

### D.2 Success Criteria

Phase 0 is complete only when all items below are true:

- Open Design evidence artifact exists and includes current MCP metadata, file list, token observations, and unresolved evidence gaps.
- Baseline artifact exists and includes current theme inventory, raw-token debt baseline, test/analyze baseline, and worktree status.
- New Amber Dusk files, if implemented, live under:
  - `lib/core/theme/designs/amber_dusk/`
  - `lib/core/theme/designs/amber_dusk/phone/`
- New tests cover token presence, color scheme parity, layout constants, and guardrails relevant to added files.
- `dart format` passes on changed Dart files.
- `flutter analyze` passes or failures are documented as pre-existing baseline failures with evidence.
- Targeted core theme/widget tests pass.
- Raw-token scan shows no new unapproved token debt outside approved files.
- No backend files changed.
- Session log records evidence, decisions, implementation summary, verification, and handoff.
- Handoff artifact exists for Mohammed's web work.

## E. Risk Register

| Risk | Probability | Impact | Mitigation |
| --- | --- | --- | --- |
| Amber Dusk gets globally activated too early | Medium | High | Stage tokens only; require explicit approval and full-app QA for activation. |
| Existing theme APIs are duplicated | Medium | High | Run current theme inventory before edits; adapt existing APIs. |
| Font assets create licensing risk | Medium | High | Block bundling without source/license evidence. |
| Blur violates `.impeccable.md` | High | Medium | Use solid surfaces; record visual deviation. |
| Light mode becomes incoherent | Medium | Medium | Define derived light tokens for parity, but do not claim Open Design evidence. |
| Legacy raw-token debt masks new debt | High | Medium | Capture baseline and compare diffs only. |
| Web work starts from incomplete phone tokens | Medium | Medium | Require handoff artifact with exact token names and caveats. |
| Tests become too broad for a foundation phase | Medium | Low | Use targeted tests unless global theme activation occurs. |

## F. Pre-Mortem

The most likely failure is scope expansion: implementing a full app reskin while only the design-system foundation was requested. That would create app-wide regressions, force broad screen QA, and blur the line between Phase 0 and later phone phases.

The second likely failure is treating Open Design export assets as directly shippable. The current MCP evidence shows font files but no license file, and `.impeccable.md` forbids glass even if the design export suggests blur. Directly copying these details would create compliance and architecture issues.

The third likely failure is duplicating foundation work already present in SLine. Current code already includes motion, states, elevation helpers, status colors, and component theme definitions. Phase 0 must create the Amber Dusk layer around those contracts rather than redoing them.

This plan avoids those outcomes by requiring evidence, baseline, decisions, scoped implementation, focused tests, and a web handoff before completion.

## G. Plan Fixes Applied

- Added A-I PlanCritic structure.
- Added required source-of-truth artifacts.
- Added Open Design MCP evidence refresh gate.
- Added current theme inventory gate.
- Added staged activation decision.
- Added font provenance and no-glass decisions.
- Added light-mode parity rule.
- Added baseline and diff-only raw-token scan.
- Added targeted verification and escalation rules.
- Added exact handoff requirement for Mohammed's web plan.
- Added rollback and stop conditions.

## H. Corrected Execution Plan

### H.0 Phase Summary

Primary outcome: a safe, reusable Amber Dusk phone foundation that later phone phases and Mohammed's web plan can consume.

Expected implementation folders:

```text
lib/core/theme/designs/amber_dusk/
  amber_dusk_tokens.dart
  amber_dusk_colors.dart
  amber_dusk_typography.dart
  amber_dusk_spacing.dart
  amber_dusk_surfaces.dart
  amber_dusk_motion.dart
  amber_dusk_components.dart
  phone/
    amber_dusk_phone_layout.dart
```

The exact file list can be adjusted during implementation if current code patterns support a smaller structure, but the import/export contract must remain explicit.

### H.1 Step 0: Planning Artifact Setup

Primary owner: Athena
Supporting agents: None
Skills: evidence-first-reading

Goal: ensure implementation starts from the corrected source-of-truth plan and has a session log.

Why: Phase 0 feeds later phone and web work. Planning artifacts must be stable before code changes.

How:

- Confirm this corrected plan exists.
- Confirm critique artifact exists.
- Confirm session log exists.
- Add a session log entry that PlanCritic rewrote the plan and that the v1 plan is superseded.

Result:

- Implementation owner knows which plan to follow.
- Audit trail shows this was a critique/rewrite pass.

Checklist:

- [ ] Confirm `.TODO/Archive/OpenDesign_AmberDusk_Phase0_2026-05-11/PLAN_CRITIQUE_2026-05-11_OpenDesign_AmberDusk_Phase0_PhoneFoundation.md`.
- [ ] Confirm `.TODO/Archive/OpenDesign_AmberDusk_Phase0_2026-05-11/PLAN_OpenDesign_AmberDusk_Phase0_PhoneFoundation_2026-05-11.md`.
- [ ] Update `docs/LOG/SESSION_PLAN_OpenDesign_AmberDusk_Phase0_PhoneFoundation_2026-05-11.md`.

### H.2 Step 1: Open Design Evidence Refresh

Primary owner: Athena
Supporting agents: None
Skills: evidence-first-reading, frontend-design

Goal: capture current Open Design MCP evidence before any implementation edit.

Why: Open Design metadata can drift. Phase 0 must be based on the current artifact, not cached notes.

How:

- Use Open Design MCP active project context.
- Record:
  - Project id and name.
  - Active entry file.
  - File manifest for `Sline V2 Amber Dusk.html`, `amber-dusk-design-system.html`, `sline-v2-amber-dusk-web.html`, screenshots, and font assets.
  - Current updated timestamps.
  - Color, typography, spacing, radius, surface, and phone layout observations.
  - Evidence gaps, especially font license and light mode.
- Write findings to `.TODO/Archive/OpenDesign_AmberDusk_Phase0_2026-05-11/EVIDENCE_OpenDesign_AmberDusk_Phase0_2026-05-11.md`.

Current evidence observed during planning:

- Project: `Sline V2 Amber Dusk.html`
- Project id: `1674a1db-7a74-4c80-8e2c-196a0385a8f7`
- Entry file: `Sline V2 Amber Dusk.html`
- Key files:
  - `Sline V2 Amber Dusk.html`
  - `amber-dusk-design-system.html`
  - `sline-v2-amber-dusk-web.html`
  - `assets/fonts/fraunces-latin.woff2`
  - `assets/fonts/dm-sans-latin.woff2`
- MCP search for `license` returned no matching file.

Result:

- Evidence file becomes the implementation baseline.

Checklist:

- [ ] Refresh Open Design MCP metadata.
- [ ] Record file sizes and updated timestamps.
- [ ] Record phone token observations.
- [ ] Record unresolved evidence gaps.
- [ ] Write `.TODO/Archive/OpenDesign_AmberDusk_Phase0_2026-05-11/EVIDENCE_OpenDesign_AmberDusk_Phase0_2026-05-11.md`.

### H.3 Step 2: Repository And Theme Reality Baseline

Primary owner: Athena
Supporting agents: None
Skills: evidence-first-reading, audit

Goal: capture the current repository contracts and debt before code edits.

Why: SLine already has a design-system foundation. Phase 0 must not duplicate or regress it.

How:

- Capture worktree status:
  - `git status --short`
- Inventory current theme files:
  - `lib/core/theme/app_colors.dart`
  - `lib/core/theme/app_theme.dart`
  - `lib/core/theme/app_typography.dart`
  - `lib/core/theme/app_motion.dart`
  - `lib/core/theme/app_states.dart`
  - `lib/core/theme/app_decorations.dart`
  - `lib/core/theme/app_layout.dart`
  - `lib/core/theme/app_dimens.dart`
- Confirm `AppColorScheme` fields and factories before adding anything:
  - `success`
  - `successMuted`
  - `warning`
  - `warningMuted`
  - `info`
  - `infoMuted`
  - `danger`
  - `dangerMuted`
- Confirm existing direct brand references that may need adapter work:
  - `AppColors.teal`
  - `AppColors.gold`
  - `ColorScheme.primary`
  - direct gradients in theme files.
- Capture raw-token debt baseline outside approved theme/token files:
  - `Color(0x`
  - `Colors.`
  - `fontSize:`
  - `Duration(`
  - `BoxShadow(`
  - `LinearGradient(`
  - `Curves.`
- Capture test/analyze baseline:
  - `flutter analyze --no-fatal-infos`
  - targeted existing tests under `test/core/theme/` and relevant `test/core/widgets/`.
- Write `.TODO/Archive/OpenDesign_AmberDusk_Phase0_2026-05-11/BASELINE_OpenDesign_AmberDusk_Phase0_2026-05-11.md`.

Result:

- Implementation can distinguish new Phase 0 changes from legacy debt.

Checklist:

- [ ] Record worktree status.
- [ ] Record current theme API inventory.
- [ ] Record direct brand references.
- [ ] Record raw-token baseline counts and representative files.
- [ ] Record current targeted test/analyze baseline.
- [ ] Write `.TODO/Archive/OpenDesign_AmberDusk_Phase0_2026-05-11/BASELINE_OpenDesign_AmberDusk_Phase0_2026-05-11.md`.

### H.4 Step 3: Pre-Edit Decision Gate

Primary owner: Athena
Supporting agents: None
Skills: evidence-first-reading

Goal: record Phase 0 implementation decisions before editing Dart files.

Why: activation, fonts, blur, and light mode affect blast radius and compliance.

How:

- In the session log, record:
  - Theme activation decision.
  - Font packaging decision.
  - Blur/no-glass decision.
  - Light mode strategy.
  - Web handoff requirements.

Default approved path:

- Stage Amber Dusk as a named token layer.
- No global default theme flip.
- No font bundling without license evidence.
- No blur/glass implementation.
- Derived light token parity only.

Result:

- Implementation scope is locked before code edits.

Checklist:

- [ ] Record activation decision.
- [ ] Record font decision.
- [ ] Record blur/no-glass decision.
- [ ] Record light mode decision.
- [ ] Record web handoff decision.

### H.5 Step 4: Amber Dusk File Contract

Primary owner: Athena
Supporting agents: None
Skills: frontend-design, normalize

Goal: create or update the Amber Dusk token folder with a predictable import contract.

Why: later phone screens and web work need stable names and a single source of truth.

How:

- Create `lib/core/theme/designs/amber_dusk/` only if it does not already exist.
- Create `lib/core/theme/designs/amber_dusk/phone/` only if it does not already exist.
- Prefer a barrel/root token file so screens do not import deep implementation details arbitrarily.
- Keep phone-specific measurements in `phone/amber_dusk_phone_layout.dart`.
- Keep global reusable tokens at the Amber Dusk root.
- Include top-level documentation comments explaining what each file provides and why it exists.

Expected contract:

```text
amber_dusk_tokens.dart       # public entry point for Amber Dusk tokens
amber_dusk_colors.dart       # palette and semantic color mapping
amber_dusk_typography.dart   # font families, weights, text roles
amber_dusk_spacing.dart      # spacing and radius aliases
amber_dusk_surfaces.dart     # elevations, fills, borders, surface recipes
amber_dusk_motion.dart       # motion aliases only when evidence supports them
amber_dusk_components.dart   # component-level recipes, no business UI
phone/amber_dusk_phone_layout.dart # phone frame, safe area, nav, card sizes
```

Result:

- A stable foundation can be consumed by later phases.

Checklist:

- [ ] Create root Amber Dusk folder if absent.
- [ ] Create phone subfolder if absent.
- [ ] Add a clear public import strategy.
- [ ] Keep phone-only sizes out of global tokens.

### H.6 Step 5: Token Mapping

Primary owner: Athena
Supporting agents: None
Skills: frontend-design, colorize, normalize, harden

Goal: translate Open Design evidence into SLine-compliant tokens.

Why: Phase 0 exists to prevent later screens from hardcoding design export values.

How:

#### H.6.1 Colors

Map Open Design colors into semantic names rather than export labels only.

Evidence palette observed during planning:

```text
#0E0B08  #1A1612  #241F1A  #2F2822  #3A312A
#F2E8D5  #E6D7BE  #1F1813  #8F8478  #7A6F63
#D4906A  #A36A48  #E6B87A  #C9695C  #7FA872  #E8B856
```

Required semantic groups:

- Backgrounds.
- Surfaces.
- Text primary/secondary/muted/inverse.
- Borders/dividers.
- Primary CTA/accent.
- Secondary accent.
- Danger/success/warning/info parity.
- Overlay/scrim values, solid only.

Do not:

- Add raw `Color(0x...)` outside Amber Dusk color/token files.
- Duplicate existing `AppColorScheme` fields.

#### H.6.2 Typography

Map evidence into roles, not one-off screen values.

Evidence:

- Interface/body/control family: DM Sans.
- Display/title/name/money family: Fraunces.
- Observed phone sizes include 30, 22, 36, and up to 44.

Rules:

- No bundled font files without license/source evidence.
- Provide fallback stack behavior if custom fonts are not activated.
- Do not hardcode `fontSize:` in feature code.
- Keep typography role names stable for later phone phases.

#### H.6.3 Layout, Spacing, And Radii

Evidence:

- Phone frame: 402 x 874.
- Content padding: 20.
- Header top: 64.
- Scroll bottom allowance: 138.
- Bottom nav margin: 16.
- Safe bottom padding: 22.
- Phone frame radius: 48.
- Hero card radius: 24.
- Task card radius: 22.
- Panel radius: 18.
- Compact controls radius: 15.
- Bottom nav radius: 26.
- Sheet radius: 30.
- FAB radius: 22.

Rules:

- Put reusable spacing/radius aliases in Amber Dusk spacing files.
- Put phone-specific layout dimensions in `phone/amber_dusk_phone_layout.dart`.
- Do not add raw `EdgeInsets`, `BorderRadius`, or numeric layout constants in future feature screens when a Phase 0 token exists.

#### H.6.4 Surfaces And Elevation

Rules:

- Use solid fills, borders, and `AppDecorations.elevation`-compatible recipes.
- Do not implement blur/glass.
- Preserve existing elevation architecture.
- Name surface recipes by role: base, raised, hero, nav, sheet, CTA.

#### H.6.5 Motion

Rules:

- Use existing `AppMotion` where possible.
- Add Amber Dusk motion aliases only if they express design intent or map evidence.
- Do not invent screen animation choreography in Phase 0.
- No raw `Duration(` or `Curves.` outside approved motion files.

#### H.6.6 Components

Rules:

- Component tokens can describe reusable recipes for CTA, nav, cards, sheets, chips, avatars, and status badges.
- Do not build final feature screens in Phase 0.
- Do not encode business data states in design-system tokens.

Result:

- Later implementation phases can consume named tokens without raw design-export constants.

Checklist:

- [ ] Map palette to semantic dark tokens.
- [ ] Create derived light tokens or explicitly block global activation.
- [ ] Map typography roles with fallback handling.
- [ ] Map spacing and radii.
- [ ] Map phone layout constants.
- [ ] Map solid surface recipes.
- [ ] Map motion aliases conservatively.
- [ ] Map component recipes without building feature screens.

### H.7 Step 6: Existing Theme Adapter Strategy

Primary owner: Athena
Supporting agents: None
Skills: normalize, harden

Goal: connect Amber Dusk to existing SLine theme contracts only where safe.

Why: SLine already has `AppTheme`, `AppColors`, `AppTypography`, `AppDimens`, `AppLayout`, `AppMotion`, `AppStates`, and `AppDecorations`.

How:

- Decide whether Amber Dusk stays fully separate for Phase 0 or adds adapters to existing theme classes.
- If adapters are added:
  - Preserve existing public APIs.
  - Do not duplicate `AppColorScheme` fields.
  - Ensure light/dark factories remain valid.
  - Update tests for any changed factory behavior.
  - Audit direct `AppColors.teal` and `AppColors.gold` references in `AppTheme`.
- If adapters are not added:
  - Document how later phases import Amber Dusk tokens.
  - Keep no-op impact on current app theme.

Preferred Phase 0 strategy:

- Add the Amber Dusk token layer and minimal adapters only when needed for tests or future screen consumption.
- Do not switch `ThemeData` globally to Amber Dusk.

Result:

- Existing app behavior remains stable while new tokens are available.

Checklist:

- [ ] Choose separate-only or minimal-adapter strategy.
- [ ] Preserve existing `AppColorScheme` contract.
- [ ] Audit direct teal/gold references.
- [ ] Add tests for any touched existing theme API.
- [ ] Document import guidance.

### H.8 Step 7: Font Handling Branch

Primary owner: Athena
Supporting agents: None
Skills: frontend-design, harden

Goal: handle DM Sans and Fraunces without creating licensing or asset failures.

Why: Typography is core to Amber Dusk, but font provenance is currently unresolved.

How:

Default branch:

- Do not add font files to `pubspec.yaml`.
- Define desired family names and fallback behavior in tokens.
- Record license gap in evidence and handoff docs.

Bundled-font branch, only if source/license is found:

- Record license/source in evidence artifact.
- Add assets using correct case-sensitive paths.
- Run `flutter pub get`.
- Run asset/build verification appropriate to the change.
- Add tests or docs confirming font family token names.

Result:

- Amber Dusk typography can be planned without unverified bundled assets.

Checklist:

- [ ] Use default no-bundle branch unless license evidence is found.
- [ ] Record font visual delta.
- [ ] If bundling, record license/source and run asset verification.

### H.9 Step 8: Verification Plan

Primary owner: Athena
Supporting agents: None
Skills: audit, harden

Goal: verify Phase 0 without overexpanding into full app QA unless activation scope demands it.

Why: Theme changes can be wide, but staged tokens should have focused verification.

Required verification:

```bash
dart format <changed dart files>
flutter analyze --no-fatal-infos
flutter test test/core/theme/
flutter test --coverage
```

Coverage floor check:

- Verify `coverage/lcov.info` reports overall coverage >= 40%.
- Fail or escalate if the coverage floor regresses below 40%.

Add relevant targeted widget tests only if existing shared widgets or `AppTheme` are changed:

```bash
flutter test test/core/widgets/
```

Raw-token diff checks:

```bash
rg -n "Color\(0x|Colors\.|fontSize:|Duration\(|BoxShadow\(|LinearGradient\(|Curves\." lib test
```

Backend no-change checks:

```bash
git diff --name-only -- supabase lib/core/services/supabase_config.dart
rg -n "Supabase|supabase|from\(|rpc\(|auth\.|channel\(" lib/core/theme test/core/theme
```

Conditional full-suite escalation:

- Run full `flutter test` if:
  - global `AppTheme` default behavior changes,
  - shared core widgets change,
  - app-wide colors or typography are activated,
  - implementation modifies more than theme/token/test/docs files.

Conditional build escalation:

- Run an asset/build check if:
  - font assets are added,
  - `pubspec.yaml` assets are changed,
  - dependency configuration changes.

Result:

- Verification matches actual blast radius.

Checklist:

- [ ] Run formatting.
- [ ] Run analyzer.
- [ ] Run targeted core theme tests.
- [ ] Run coverage and ensure overall test coverage >= 40%.
- [ ] Run targeted widget tests if shared widgets/theme changed.
- [ ] Run raw-token diff scan.
- [ ] Run no-backend-change scan.
- [ ] Escalate to full tests/build only if conditions are met.

### H.10 Step 9: Documentation And Handoff

Primary owner: Athena
Supporting agents: None
Skills: docs-sync, evidence-first-reading

Goal: leave implementation and downstream web work with exact context.

Why: Mohammed's web plan depends on Phase 0 token decisions and caveats.

How:

- Update the session log with:
  - Evidence artifact path.
  - Baseline artifact path.
  - Decisions made.
  - Files changed.
  - Verification commands and results.
  - Known gaps.
- Write `.TODO/Archive/OpenDesign_AmberDusk_Phase0_2026-05-11/DOCS_SYNC_2026-05-11_OpenDesign_AmberDusk_Phase0.md` with:
  - Whether docs were updated or why not.
  - Token/import contract summary.
  - Any docs needing future sync.
- Write `.TODO/HANDOFF_OpenDesign_AmberDusk_Phase0_ToWeb_2026-05-11.md` with:
  - Token files created.
  - Semantic color names.
  - Typography role names and font caveats.
  - Spacing/radius/layout names.
  - Surface/motion/component recipe names.
  - Light mode caveat.
  - No-glass deviation.
  - Verification summary.

Result:

- Phase 0 can be safely consumed by Phase 1 phone and by web work.

Checklist:

- [ ] Update session log.
- [ ] Write docs-sync note.
- [ ] Write web handoff note.
- [ ] Include known caveats and unresolved evidence gaps.

### H.11 Step 10: Final Gate

Primary owner: Athena
Supporting agents: None
Skills: audit

Goal: decide whether Phase 0 passes.

Why: The output must be reliable before later phases consume it.

Pass criteria:

- All required artifacts exist.
- Implementation follows staged activation unless explicit approval says otherwise.
- Analyzer and targeted tests pass or pre-existing failures are documented.
- No new unapproved raw-token debt.
- No backend changes.
- Handoff artifact exists.
- Worktree diff matches Phase 0 scope.

Fail criteria:

- Missing evidence or baseline artifacts.
- Global activation without expanded verification.
- Font assets bundled without license/source.
- New glass/blur implementation without approval.
- Backend or Supabase changes.
- New feature screen redesign work.
- Tests/analyzer fail from Phase 0 changes.

Rollback plan:

- Revert only Phase 0 changes made in this work.
- Preserve user/unrelated worktree changes.
- Keep critique and session log artifacts unless the user explicitly asks to remove them.

Checklist:

- [ ] Confirm artifacts.
- [ ] Confirm scope.
- [ ] Confirm verification.
- [ ] Confirm no backend changes.
- [ ] Confirm handoff.
- [ ] Record final pass/fail in session log.

## I. Change Report

### I.1 What This Rewrite Changed

- Converted the Phase 0 plan into PlanCritic A-I source-of-truth format.
- Added exact evidence, baseline, critique, docs-sync, session log, and handoff artifacts.
- Added blocking decisions for activation, fonts, blur/no-glass, and light mode.
- Added current-code inventory requirements to avoid duplicating existing theme foundation.
- Added targeted verification and conditional escalation rules.
- Added hard stop conditions for backend work and scope expansion.

### I.2 What This Rewrite Preserved

- Phase 0 remains the Amber Dusk phone design-system foundation.
- Open Design MCP remains the visual evidence source.
- The expected Amber Dusk folder remains under `lib/core/theme/designs/amber_dusk/`.
- Later phone screens remain out of scope.
- Mohammed's web plan still depends on phone Phase 0 handoff.

### I.3 Implementation Warning

The implementation owner must not treat this as permission to redesign screens. Phase 0 builds the reusable design foundation and its evidence trail only. Screen-level UI work belongs to later phone phases and the separate web plan.
