# Docs Sync: OpenDesign Amber Dusk Phase 0

Date: 2026-05-11
Plan: `.TODO/Archive/OpenDesign_AmberDusk_Phase0_2026-05-11/PLAN_OpenDesign_AmberDusk_Phase0_PhoneFoundation_2026-05-11.md`

## Code Change Summary

Phase 0 added a staged Amber Dusk design token layer under:

```text
lib/core/theme/designs/amber_dusk/
```

The new public import is:

```dart
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
```

The layer is passive and staged. It does not activate the global app theme, change `AppTheme`, modify shared widgets, or bundle font assets.

## Docs Updated

- `Sline_everything/DEVELOPER_GUIDE.md`
  - Added the Amber Dusk staged token folder to the core theme file table.
  - Added staged design layers to the three-layer design-system architecture notes.
- `Sline_everything/STRUCTURE.md`
  - Added `designs/amber_dusk/` under `lib/core/theme/`.
- `.cursor/PROJECT_CONTEXT.md`
  - Added the Amber Dusk staged design token import to the theme-system quick reference.

## Docs Not Updated

- `Sline_everything/SUPABASE_SETUP.md`
  - No database, storage, policy, RPC, trigger, or edge function changes were made.
- `Sline_everything/MVP_ROADMAP.md`
  - No user-facing feature status changed; this is an internal foundation layer.
- `lib/core/theme/theme_dashboard.dart`
  - Deferred. This file is a broad app-theme reference and should be updated
    when Amber Dusk is activated or when a dedicated design-dashboard sync phase
    is planned.

## Token Contract Summary

- `AmberDuskTokens.colors`
  - Authored dark semantic palette and derived light parity palette.
- `AmberDuskTokens.typography`
  - DM Sans and Fraunces role names with fallback family lists only.
- `AmberDuskTokens.spacing`
  - Reusable spacing, radii, and border widths.
- `AmberDuskTokens.surfaces`
  - Borderless solid surface recipes with OD shadow names, hero gradient
    metadata, and no glass or blur.
- `AmberDuskTokens.motion`
  - Role aliases backed by existing `AppMotion`.
- `AmberDuskTokens.components`
  - Component recipe names for later UI phases, including broad status badges.
- `AmberDuskTokens.phoneLayout`
  - Fixed 402 x 874 phone artboard and nav/FAB layout constants.

## Verification

- `dart format lib/core/theme/designs/amber_dusk test/core/theme/amber_dusk_tokens_test.dart test/core/theme/amber_dusk_phone_layout_test.dart`
- `flutter analyze --no-fatal-infos`
- `flutter test test/core/theme/`
- Raw-token debt outside approved Amber Dusk files and focused Amber Dusk tests
  stayed at baseline counts.
- No Supabase/backend references were added to the Amber Dusk token files or tests.
