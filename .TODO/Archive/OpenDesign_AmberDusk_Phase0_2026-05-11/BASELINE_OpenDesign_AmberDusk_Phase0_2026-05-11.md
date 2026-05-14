# Baseline: OpenDesign Amber Dusk Phase 0

Date: 2026-05-11
Phase: OpenDesign Amber Dusk Phase 0 Phone Foundation
Source plan: `.TODO/Archive/OpenDesign_AmberDusk_Phase0_2026-05-11/PLAN_OpenDesign_AmberDusk_Phase0_PhoneFoundation_2026-05-11.md`

## Worktree Baseline Before Dart Source Edits

`git status --short` before Phase 0 implementation source edits:

```text
?? .TODO/Archive/OpenDesign_AmberDusk_Phase0_2026-05-11/PLAN_CRITIQUE_2026-05-11_OpenDesign_AmberDusk_Phase0_PhoneFoundation.md
?? .TODO/Archive/OpenDesign_AmberDusk_Phase0_2026-05-11/PLAN_OpenDesign_AmberDusk_Phase0_PhoneFoundation_2026-05-11.md
?? .TODO/Archive/OpenDesign_AmberDusk_Phase0_2026-05-11/EVIDENCE_OpenDesign_AmberDusk_Phase0_2026-05-11.md
?? .codex/
?? AGENTS.md
?? docs/LOG/SESSION_PLAN_OpenDesign_AmberDusk_Phase0_PhoneFoundation_2026-05-11.md
```

Notes:

- `.codex/` and `AGENTS.md` are unrelated pre-existing untracked items and are not part of Phase 0.
- The Phase 0 plan, critique, evidence, baseline, handoff, docs-sync, and session log artifacts are expected planning outputs.

## Current Theme Directory Baseline

Existing `lib/core/theme/` files:

- `app_colors.dart`
- `app_decorations.dart`
- `app_dimens.dart`
- `app_layout.dart`
- `app_motion.dart`
- `app_states.dart`
- `app_theme.dart`
- `app_typography.dart`
- `theme_dashboard.dart`

Missing before implementation:

- `lib/core/theme/designs/`
- `lib/core/theme/designs/amber_dusk/`
- `lib/core/theme/designs/amber_dusk/phone/`

## Current Theme API Inventory

Confirmed current design-system foundations:

- `AppColorScheme` exists in `lib/core/theme/app_colors.dart`.
- `AppColorScheme.light()` exists.
- `AppColorScheme.dark()` exists.
- `AppColorScheme.lerp(...)` exists.
- Required status fields already exist:
  - `success`
  - `successMuted`
  - `warning`
  - `warningMuted`
  - `info`
  - `infoMuted`
  - `danger`
  - `dangerMuted`
- `AppTypography` exists and has current fallback families.
- `AppMotion` exists and owns duration/curve tokens.
- `AppInteractionStates` exists in `app_states.dart`.
- `AppDecorations.elevation(...)` exists.
- `AppDimens` and `AppLayout` exist.
- `AppTheme` builds current light/dark `ThemeData`.

## Current Direct Brand References

Known current brand references before Phase 0:

- `lib/core/theme/app_theme.dart` uses `AppColors.teal` directly in `TabBarThemeData`.
- `lib/core/theme/app_colors.dart` current factories use `AppColors.teal` and `AppColors.gold`.
- `lib/core/widgets/signed_avatar.dart` uses `AppColors.teal` and `AppColors.gold`.
- `lib/core/widgets/custom_bottom_nav_bar.dart` uses `AppColors.teal`, `AppColors.lightRed`, and raw `fontSize`.

Phase 0 decision: do not rewrite existing app-wide brand usage unless it is required for the staged Amber Dusk token layer. Default app theme remains unchanged.

## Current Asset And Font Baseline

`pubspec.yaml`:

- `google_fonts: ^8.0.2` is already present.
- `flutter.assets` declares `assets/images/logo.png`.
- No active `fonts:` block exists.

Filesystem:

- Found `assets/images/Logo.png`.
- Did not find local Flutter font assets for DM Sans or Fraunces.

Open Design:

- Found `assets/fonts/dm-sans-latin.woff2`.
- Found `assets/fonts/fraunces-latin.woff2`.
- No license evidence found.

Phase 0 decision: do not add Open Design font assets to Flutter in this phase.

## Raw Token Debt Baseline

Raw token scan over `lib` and `test` before Phase 0 Dart source edits:

```text
Color(0x       47
Colors.      644
fontSize:      66
Duration(     275
BoxShadow(     13
LinearGradient( 13
Curves.        14
```

Acceptance rule:

- Existing debt is baseline only.
- Phase 0 must not add new unapproved raw-token usage outside `lib/core/theme/designs/amber_dusk/**` and focused tests.

## Baseline Verification Commands

```bash
flutter analyze --no-fatal-infos
```

Result:

```text
No issues found! (ran in 12.7s)
```

```bash
flutter test test/core/theme/
```

Result:

```text
All tests passed.
```

```bash
flutter test test/core/widgets/
```

Result:

```text
All tests passed.
```

Notes:

- `test/core/widgets/` emitted pre-existing tap hit-test warnings in disabled interaction tests, but the suite passed.

## Backend And MVVM Baseline

Phase 0 is theme-only.

Backend scan:

- `supabase/migrations/` exists.
- `supabase/functions/` exists.
- `supabase/scripts/` exists.
- `supabase/tests/` exists.

No Supabase objects are referenced for creation or modification by this plan.

MVVM impact:

- Views: no direct screen changes planned.
- ViewModels: no changes planned.
- Services/repositories: no changes planned.
- Backend/Supabase: no changes planned.
- Theme layer: new staged Amber Dusk token files planned.
