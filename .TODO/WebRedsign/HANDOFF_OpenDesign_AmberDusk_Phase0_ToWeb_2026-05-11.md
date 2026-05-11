# Handoff: OpenDesign Amber Dusk Phase 0 To Web

Date: 2026-05-11
Source plan: `.TODO/Archive/OpenDesign_AmberDusk_Phase0_2026-05-11/PLAN_OpenDesign_AmberDusk_Phase0_PhoneFoundation_2026-05-11.md`
Web dependency plan: `.TODO/PLAN_OpenDesign_AmberDusk_Web_Mohammed_2026-05-10.md`

## Status

Phase 0 phone design-system foundation is implemented as a staged token layer. It is available for phone Phase 1+ and Mohammed's web plan, but it is not globally activated.

## Public Import

```dart
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
```

Use the root `AmberDuskTokens` entry point. Avoid importing deep token files from screens unless a later plan explicitly needs it.

## Files Created

```text
lib/core/theme/designs/amber_dusk/amber_dusk_tokens.dart
lib/core/theme/designs/amber_dusk/amber_dusk_colors.dart
lib/core/theme/designs/amber_dusk/amber_dusk_typography.dart
lib/core/theme/designs/amber_dusk/amber_dusk_spacing.dart
lib/core/theme/designs/amber_dusk/amber_dusk_surfaces.dart
lib/core/theme/designs/amber_dusk/amber_dusk_motion.dart
lib/core/theme/designs/amber_dusk/amber_dusk_components.dart
lib/core/theme/designs/amber_dusk/phone/amber_dusk_phone_layout.dart
```

## Token Names

### Colors

- Dark palette: `AmberDuskTokens.colors.dark`
- Derived light palette: `AmberDuskTokens.colors.light`
- Key dark values:
  - `primary`: `#D4906A`
  - `page`: `#0E0B08`
  - `background`: `#1A1612`
  - `surface`: `#241F1A`
  - `surfaceRaised`: `#2F2822`
  - `surfaceHighest`: `#3A312A`
  - `text`: `#F2E8D5`
  - `muted`: `#8F8478`
  - `heroTop`: `#4A2D1F`
  - `hero`: `#3E2418`
  - `heroDeep`: `#2E1810`
  - `heroMuted`: `rgba(245,232,208,0.55)`
  - `heroChip`: `rgba(255,255,255,0.05)`
  - `heroChipBorder`: `rgba(245,232,208,0.15)`
  - `heroDivider`: `rgba(245,232,208,0.1)`
  - `success` / `forest`: `#7FA872`
  - `warning` / `star`: `#E8B856`
  - `danger` / `rust`: `#C9695C`
  - generic `border` / `divider`: transparent in the staged OD-aligned layer
  - `activeGlow`: `rgba(212,144,106,0.2)` with an 8px glow blur token

### Typography

- Interface/control/label/chip/paragraph family: `DM Sans`
- Display/title/name/money family: `Fraunces`
- Font assets were not bundled. The token layer exposes family names and fallback lists only.

### Layout

- `AmberDuskTokens.phoneLayout.frameWidth`: `402`
- `frameHeight`: `874`
- `frameRadius`: `48`
- `horizontalPadding`: `20`
- `topPadding`: `64`
- `contentBottomPadding`: `120`
- `bottomScrollPadding`: `138`
- `safeBottomPadding`: `22`
- `bottomNavInset`: `16`
- `bottomNavBottom`: `24`
- `bottomNavHeight`: `68`
- `bottomNavRadius`: `26`
- `fabSize`: `56`
- `fabRadius`: `22`
- `dynamicIslandWidth`: `126`
- `dynamicIslandHeight`: `37`

### Surfaces

- Recipes: `base`, `raised`, `hero`, `nav`, `sheet`, `cta`
- Generic recipe borders are transparent to preserve OD's borderless rim rule.
- Shadow metadata names: `shadow-surface`, `shadow-raised`, `shadow-hero`,
  `shadow-nav`, and `shadow-cta`.
- Hero recipe includes gradient stops, `172` degree direction metadata, a
  non-blur top highlight, and a subtle rim token.
- All recipes are solid/gradient/shadow recipes only.
- No blur, glass, `BackdropFilter`, `GlassContainer`, `GlassCard`, or `GlassButton` was added.

### Motion

- Motion roles alias existing `AppMotion`.
- No screen choreography was added in Phase 0.

### Components

- Recipes: `bookingCard`, `taskCard`, `bottomNav`, `floatingActionButton`, `bottomSheet`, `chip`, `statusBadge`
- These are recipe contracts, not widgets.
- `chip`, `statusBadge`, and CTA capsule radii use `AmberDuskTokens.spacing.pillRadius`.

## Caveats For Web Phase

- Amber Dusk light mode is derived for API parity. It is not Open Design-authored visual evidence.
- Do not use Open Design font files unless license/source evidence is added in a later phase.
- Do not use blue or purple accents for Amber Dusk.
- Do not reintroduce glass effects. `.impeccable.md` still controls the no-glass policy.
- Business-specific web status maps remain out of Phase 0. Use the semantic
  status colors/washes and add screen/business-state mapping in the owning web
  or phone phase.
- No web token namespace was created in phone Phase 0. Web-specific tokens such
  as rail width and responsive grid sizes should live under
  `lib/core/theme/designs/amber_dusk/web/` in the web plan, not inside the phone
  folder.

## Verification Summary

- `flutter analyze --no-fatal-infos`: passed.
- `flutter test test/core/theme/`: passed.
- Raw-token debt outside approved Amber Dusk files and focused Amber Dusk tests remained unchanged from baseline.
- No backend/Supabase files were changed.
