# Emulator Test Checklist - Open Design Amber Dusk Phase 0

Date: 2026-05-11
Scope: Every uncommitted file touched in the Amber Dusk Phase 0 session, including local docs/tooling files.

## Purpose

Amber Dusk Phase 0 is a staged token layer only. The emulator pass should prove the current app still runs on the active Layer 1 `AppTheme` and that no Amber Dusk token changes leak into runtime UI before an explicit activation phase.

## Preflight

- [ ] Confirm `git status --short` and review every uncommitted path before launching the emulator.
- [ ] Run `flutter pub get` if dependencies are not current.
- [ ] Run `flutter analyze --no-fatal-infos`.
- [ ] Run `flutter test test/core/theme/`.
- [ ] Run `flutter test --coverage` and confirm total coverage is at least 40%.
- [ ] Run the CI `Architecture Guard / Check MVVM boundaries` command or verify the latest CI result is passing.
- [ ] Confirm `coverage/lcov.info` is not unintentionally staged after coverage generation.

## Emulator Matrix

- [ ] iOS or Android phone around the Open Design artboard size, for example 402 logical pixels wide if available.
- [ ] One smaller phone viewport.
- [ ] One taller/larger phone viewport.
- [ ] Light mode.
- [ ] Dark mode.
- [ ] Text scale 1.0.
- [ ] Text scale 1.3 or larger.

## Runtime Smoke Tests

- [ ] Launch the app from `lib/main.dart` with normal runtime configuration.
- [ ] Confirm the splash/startup path completes without errors.
- [ ] Confirm the app uses the existing active `AppTheme`, not Amber Dusk colors or typography.
- [ ] Navigate auth entry screens and confirm no layout, color, text, or overflow regression.
- [ ] Navigate the main bottom tabs: home, tasks, chat, profile, and any visible dashboard/work tab.
- [ ] Confirm bottom navigation remains above system insets and is not affected by Amber Dusk fixed phone tokens.
- [ ] Scroll representative list/card screens and confirm content is not hidden behind the bottom navigation or FAB.
- [ ] Toggle light/dark mode if available and confirm the existing active theme still controls runtime colors.
- [ ] Inspect one card, one button, one text field, one status badge, one signed image/avatar, and one bottom navigation item for visual parity with the pre-Amber baseline.
- [ ] Confirm no `BackdropFilter`, blur, glass card, glass button, or translucent frosted material appears due to Amber Dusk work.
- [ ] Capture screenshots for the baseline runtime screens if this checklist is used for merge approval.

## File Coverage Checklist

### Runtime Entry And Instructions

- [ ] `lib/main.dart`: app launches normally; no Amber Dusk import or activation is present.
- [ ] `AGENTS.md`: no emulator runtime effect; verify manual testing still follows MVVM and no-glass guidance.
- [ ] `.codex/config.toml`: no emulator runtime effect; confirm app launch does not depend on `SUPABASE_PROJECT_REF` from Codex MCP config.

### Active Docs And Project Context

- [ ] `.cursor/PROJECT_CONTEXT.md`: no emulator runtime effect; cross-check that active theme behavior on emulator still matches project context.
- [ ] `Sline_everything/DEVELOPER_GUIDE.md`: no emulator runtime effect; verify documented staged-layer behavior matches observed inactive Amber Dusk runtime.
- [ ] `Sline_everything/STRUCTURE.md`: no emulator runtime effect; verify documented `lib/core/theme/designs/amber_dusk/` path exists.

### Planning And Session Artifacts

- [ ] `.TODO/Archive/OpenDesign_AmberDusk_Phase0_2026-05-11/PLAN_OpenDesign_AmberDusk_Phase0_PhoneFoundation_2026-05-11.md`: no emulator runtime effect; verify checklist-required coverage and architecture guard evidence has been run.
- [ ] `.TODO/Archive/OpenDesign_AmberDusk_Phase0_2026-05-11/PLAN_CRITIQUE_2026-05-11_OpenDesign_AmberDusk_Phase0_PhoneFoundation.md`: no emulator runtime effect; verify pre-edit discovery/reporting requirements were satisfied.
- [ ] `.TODO/Archive/OpenDesign_AmberDusk_Phase0_2026-05-11/BASELINE_OpenDesign_AmberDusk_Phase0_2026-05-11.md`: no emulator runtime effect; verify baseline counts still match review evidence.
- [ ] `.TODO/Archive/OpenDesign_AmberDusk_Phase0_2026-05-11/EVIDENCE_OpenDesign_AmberDusk_Phase0_2026-05-11.md`: no emulator runtime effect; compare emulator screenshots only if a later preview activates Amber Dusk.
- [ ] `.TODO/Archive/OpenDesign_AmberDusk_Phase0_2026-05-11/DOCS_SYNC_2026-05-11_OpenDesign_AmberDusk_Phase0.md`: no emulator runtime effect; verify docs-sync notes match the staged inactive behavior.
- [ ] `.TODO/HANDOFF_OpenDesign_AmberDusk_Phase0_ToWeb_2026-05-11.md`: no emulator runtime effect; verify no web-specific assumptions are required for phone emulator smoke.
- [ ] `.TODO/Archive/OpenDesign_AmberDusk_Phase0_2026-05-11/MASTER_REPORT_2026-05-11_OpenDesign_AmberDusk_Phase0.md`: no emulator runtime effect; verify all BLOCKER/HIGH/MED findings are closed.
- [ ] `.TODO/EMULATOR_TEST_CHECKLIST_2026-05-11_OpenDesign_AmberDusk_Phase0.md`: no emulator runtime effect; use this file as the single manual-test source.
- [ ] `docs/LOG/SESSION_PLAN_OpenDesign_AmberDusk_Phase0_PhoneFoundation_2026-05-11.md`: no emulator runtime effect; verify logged validation matches the commands run for this checklist.

### Amber Dusk Token Layer

- [ ] `lib/core/theme/designs/amber_dusk/amber_dusk_tokens.dart`: importing the barrel in tests/previews exposes tokens only; emulator app remains unchanged until activation.
- [ ] `lib/core/theme/designs/amber_dusk/amber_dusk_colors.dart`: if a preview is activated later, hero chips must be borderless/transparent; normal emulator app should not show Amber Dusk colors.
- [ ] `lib/core/theme/designs/amber_dusk/amber_dusk_typography.dart`: normal emulator app should not switch to Amber Dusk typography; future preview should use the documented fallback stack without overflow.
- [ ] `lib/core/theme/designs/amber_dusk/amber_dusk_spacing.dart`: normal emulator app should not change spacing; future preview chips/capsules should render fully pill-shaped.
- [ ] `lib/core/theme/designs/amber_dusk/amber_dusk_surfaces.dart`: normal emulator app should not change surfaces; future preview surfaces should use gradients instead of `fill` when gradient stops are present.
- [ ] `lib/core/theme/designs/amber_dusk/amber_dusk_motion.dart`: normal emulator app should not change animations; future preview interactions should map to active `AppMotion` timing.
- [ ] `lib/core/theme/designs/amber_dusk/amber_dusk_components.dart`: normal emulator app should not change component styling; future preview recipes should resolve names from the canonical recipe list.
- [ ] `lib/core/theme/designs/amber_dusk/phone/amber_dusk_phone_layout.dart`: normal emulator app should not apply fixed 402 x 874 artboard metrics; future activation must verify safe-area behavior on all emulator sizes.

### Tests

- [ ] `test/core/theme/amber_dusk_tokens_test.dart`: pass locally; verify no-glass source guard and transparent hero chip border assertion are included.
- [ ] `test/core/theme/amber_dusk_phone_layout_test.dart`: pass locally; verify close-to floating assertions, relationship checks, and value equality coverage.

## Acceptance Criteria

- [ ] No runtime Amber Dusk activation is visible in the emulator.
- [ ] Existing active theme screens visually match the current app baseline.
- [ ] No MVVM boundary violation appears in app behavior or Architecture Guard output.
- [ ] No bottom navigation, FAB, or content overlap occurs on the tested emulator sizes.
- [ ] No glass/blur material appears from Amber Dusk work.
- [ ] Automated tests and coverage floor pass.
