# Evidence: OpenDesign Amber Dusk Phase 0

Date: 2026-05-11
Phase: OpenDesign Amber Dusk Phase 0 Phone Foundation
Source plan: `.TODO/Archive/OpenDesign_AmberDusk_Phase0_2026-05-11/PLAN_OpenDesign_AmberDusk_Phase0_PhoneFoundation_2026-05-11.md`

## Open Design MCP Project

- Project id: `1674a1db-7a74-4c80-8e2c-196a0385a8f7`
- Project name: `Sline V2 Amber Dusk.html`
- Kind: `prototype`
- Entry file: `Sline V2 Amber Dusk.html`
- Design system id: `null`
- Source import: `Sline V2 Amber Dusk.html.zip`
- Linked directory: `/Users/eros/Downloads/slineDesign`
- Created at: `1778174037101`
- Updated at: `1778418973981`

## Current File Manifest Highlights

- `Sline V2 Amber Dusk.html`
  - size: `86533`
  - mtime: `1778418921424.8796`
  - kind: `html`
- `amber-dusk-design-system.html`
  - size: `23667`
  - mtime: `1778418807550.6213`
  - kind: `html`
- `sline-v2-amber-dusk-web.html`
  - size: `92124`
  - mtime: `1778418782621.5164`
  - manifest updatedAt: `2026-05-11T12:43:23.995Z`
- `assets/fonts/fraunces-latin.woff2`
  - size: `36560`
  - mtime: `1778179400906.521`
- `assets/fonts/dm-sans-latin.woff2`
  - size: `36980`
  - mtime: `1778179400900.3164`

## Token Evidence From `amber-dusk-design-system.html`

### Fonts

Evidence lines 8-18 define two `@font-face` blocks:

- `DM Sans`
- `Fraunces`

The Open Design file references local font assets, but no license file was found by MCP search.

### Color Tokens

Evidence lines 21-38 define the core palette:

```text
--page: #0E0B08
--bg: #1A1612
--bg2: #241F1A
--bg3: #2F2822
--bg4: #3A312A
--cream: #F2E8D5
--cream-subtle: #E6D7BE
--text: #F2E8D5
--text-dark: #1F1813
--muted: #8F8478
--muted-dark: #7A6F63
--primary: #D4906A
--primary-deep: #A36A48
--amber: #E6B87A
--rust: #C9695C
--forest: #7FA872
--star: #E8B856
```

Evidence lines 39-42 define hero colors:

```text
--hero: #3E2418
--hero-top: #4A2D1F
--hero-deep: #2E1810
--hero-text: #F5E8D0
```

The app artifact also defines hero substates used by booking cards:

- `heroMuted`: `rgba(245,232,208,0.55)`
- `heroChip`: `rgba(255,255,255,0.05)`
- `heroChipBorder`: `rgba(245,232,208,0.15)`
- `heroDivider`: `rgba(245,232,208,0.1)`

The design-system artifact keeps generic `border`, `rim`, and `rim-strong`
transparent. Phase 0 follows that borderless rim contract for generic surfaces
and keeps hero-specific chip/rim/highlight values separate.

### Phone Layout Evidence

Evidence lines 104-112 define:

- phone width: `402px`
- phone height: `874px`
- phone radius: `48px`
- phone inner padding: `64px 20px 120px`
- scroll bottom allowance: `138px`
- safe bottom padding: `22px`
- dynamic island width: `126px`
- dynamic island height: `37px`

Additional observed phone component tokens:

- booking card radius: `24px`
- task card radius: `22px`
- module radius: `18px`
- bottom nav radius: `26px`
- bottom nav horizontal inset: `16px`
- bottom nav bottom: `24px`
- bottom nav height: `68px`
- FAB size: `56px`
- FAB radius: `22px`

### Typography Evidence

Evidence lines 246-251 state:

- Fraunces is for titles, names, and wallet/money values.
- DM Sans is for controls, labels, chips, and paragraphs.
- Screen titles use `30px`.
- Booking names use approximately `22-23px`.
- Wallet values can reach `44px`.

### System Rules Evidence

Evidence lines 284-318 state:

- Use a fixed `402 x 874` iPhone artboard for target matching.
- Keep page background near-black.
- Use Fraunces only for page titles, freelancer names, and major wallet values.
- Use DM Sans for controls, labels, chips, and paragraphs.
- BookingCard is the hero component with deep rust gradient, 24px radius, and layered hero shadow.
- TaskCard is quieter with bg2 surface, 22px radius, compact copy, and no decorative glow.
- Primary destinations are Home, Dashboard, Messages, and Profile.
- Status colors are semantic: muted, amber, forest, cream, and rust.
- Active state is amber primary on dark surfaces with only a small 8px glow.
- Neutral copy uses `#8F8478`.
- No blue or purple accents.

### Surface Material Evidence

- OD surface shadow roles include `shadow-surface`, `shadow-raised`,
  `shadow-hero`, `shadow-cta`, and `shadow-nav`.
- Hero booking materials use a directional rust gradient with a top highlight
  and subtle rim/bevel detail. Phase 0 stores these as passive recipe metadata
  only; it does not render blur or glass effects.

## Evidence Gaps

- MCP search for `license` returned no matches.
- No light-mode Amber Dusk source-of-truth evidence was found in the design-system file.
- Open Design font files should not be bundled in Flutter until source/license evidence is documented.
- Amber Dusk is dark-first; light tokens must be treated as derived parity tokens, not Open Design-authored tokens.

## Project Constraint Conflict

`.impeccable.md` requires solid surfaces and forbids glass, frosted blur, `BackdropFilter`, `GlassContainer`, `GlassCard`, and `GlassButton`.

Phase 0 decision: implement Amber Dusk with solid color, border, shadow, and gradient recipes only. Do not implement blur or glass.
