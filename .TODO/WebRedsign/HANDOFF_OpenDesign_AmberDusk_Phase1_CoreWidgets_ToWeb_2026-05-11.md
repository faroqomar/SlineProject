# HANDOFF: OpenDesign Amber Dusk Phase 1 Core Widgets To Web

Date: 2026-05-11
Status: CODE HANDOFF WITH VISUAL-EVIDENCE CAVEAT
Audience: Web redesign implementation agents

## Summary

Phase 1 activated Amber Dusk for selected shared phone widgets through a typed
adapter instead of a global app-theme flip. The reusable entry point is:

- `lib/core/theme/designs/amber_dusk/amber_dusk_tokens.dart`
- `AmberDuskTokens.widgetTheme`
- `lib/core/theme/designs/amber_dusk/amber_dusk_widget_theme.dart`

The adapter owns shared recipes for buttons, fields, icon buttons, cards, bottom
nav, tabs, status pills, skeletons, and signed-media placeholders.

## Source Artifacts

- Phase 1 plan: `.TODO/Archive/OpenDesign_AmberDusk_Phase1_2026-05-11/PLAN_OpenDesign_AmberDusk_Phase1_CorePhoneWidgets_2026-05-11.md`
- PlanCritic gate: `.TODO/Archive/OpenDesign_AmberDusk_Phase1_2026-05-11/PLAN_CRITIQUE_2026-05-11_OpenDesign_AmberDusk_Phase1_CorePhoneWidgets.md`
- Session log: `docs/LOG/SESSION_PLAN_OpenDesign_AmberDusk_Phase1_CorePhoneWidgets_2026-05-11.md`
- Docs sync: `.TODO/Archive/OpenDesign_AmberDusk_Phase1_2026-05-11/DOCS_SYNC_2026-05-11_OpenDesign_AmberDusk_Phase1_CoreWidgets.md`
- Phase 0 web handoff: `.TODO/WebRedsign/HANDOFF_OpenDesign_AmberDusk_Phase0_ToWeb_2026-05-11.md`

## Open Design Evidence

Open Design MCP was rechecked before implementation against project
`1674a1db-7a74-4c80-8e2c-196a0385a8f7`, active artifact
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

Step 5 caveat: this screenshot pack is provisional. Hash sanity found duplicate
route captures at 360px, 390px, and 402px, plus duplicate 430px
messages/profile captures. Treat the pack as Open Design width reference only,
not proof of route-specific Flutter runtime visual QA.

## Web-Relevant Adapter Values

Reusable design intent, subject to web breakpoint validation:

- Palette: page `#0E0B08`, surface stack `#1A1612`, `#241F1A`, `#2F2822`, text `#F2E8D5`, muted `#8F8478`, primary `#D4906A`, amber `#E6B87A`, rust `#C9695C`, forest `#7FA872`.
- Buttons: min height `46`, radius `15`, horizontal padding `18`, label weight `800`, borderless variants.
- Fields: radius `16`, dark fill, padding `13x12`, uppercase label style, borderless body.
- Cards: solid Amber surfaces, no blur, no glass.
- Status pills: uppercase `11/800`, pill radius, compact `10x5` padding.
- Skeletons: derive only from Amber surface steps; no standalone color family.

Phone-specific until a web phase defines and verifies breakpoints:

- Bottom nav geometry and four-destination phone shell.
- 360/390/402/430 width evidence matrix.
- Phone safe-area spacing and nav bottom offset.

Future web-specific tokens should live under
`lib/core/theme/designs/amber_dusk/web/` rather than overloading phone layout
tokens.

## Implementation Caveats

- `SignedImage` still contains pre-existing direct Supabase access. Phase 1 did
  not expand it and did not change signed URL/cache/bucket behavior.
- `SignedAvatar` keeps its existing signed URL generator contract.
- No global `MaterialApp` Amber Dusk flip occurred.
- No `BackdropFilter`, `ImageFilter.blur`, frosted glass, or deleted `glass_*`
  files were introduced.
- Font asset packaging remains unresolved because no license/source evidence was
  found in Phase 0/1 evidence.
- Runtime route screenshot verification is still owned by Step 6 and must not be
  inferred from the provisional screenshot pack above.

## Verification

- `flutter analyze --no-fatal-infos`: pass
- `flutter test test/core/theme/ test/core/widgets/`: pass
- Downstream smoke tests for app shell/cards/task and booking details: pass
- `flutter test --coverage`: pass
- Coverage after Step 5 remediation: 46.32% (`LH=11162`, `LF=24098`)
