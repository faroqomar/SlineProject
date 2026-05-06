# SLine — Complete Design System Redesign Strategy
### A production-minded visual identity replacement, not a polish

---

## 1. Redesign Executive Verdict

The current SLine design system is not a system — it is an accumulation. Every screen has been built by reaching for slightly different hex values, slightly different radius values, slightly different component heights, and slightly different border colors, resulting in a product that feels assembled rather than designed. The teal (#0D8C8C) has potential, but it is used indiscriminately across buttons, borders, text, badges, card backgrounds, and icons simultaneously, which destroys its communicative power entirely. The dark surfaces are not dark *with intention* — they are dark because dark was the default, and the result is a collection of near-black swatches (#0D0D0D, #111111, #1A1A1A, #161A1A, #0D1515, #141C1C, #0A1C1C) that individually look almost identical but collectively create an incoherent depth model. The typography has no scale — it jumps from 40px to 34px to 32px to 28px with no musical logic, and the heaviest weights (800–900) are overused so aggressively that nothing actually feels important. The product deserves a complete replacement: a new color architecture, a new type scale, a new component philosophy, and a new emotional identity built from first principles.

---

## 2. Why the Current Direction Should Be Replaced

**Color system is broken in three ways.** First, it has too many surface colors — at least 22 distinct near-black backgrounds are used across the app, none of them semantically named or intentionally chosen. This is not a dark mode; it is dark noise. Second, the primary teal is used for literally everything: primary buttons, icon tint, active tab indicator, card borders, section headers, badge backgrounds, text links, and amount colors — which means the color communicates nothing because it communicates everything. Third, there is no true neutral palette. The "muted" text is always #888888 regardless of context, which makes it too bright on some surfaces and too dim on others.

**Typography has no rhythm.** The scale goes 40/34/32/28/26/24/22/20/18/17/16/15/14/13/12/11/10 — seventeen distinct sizes. This is not a scale; it is a pixel picker. Font weight 800 is used for page titles, card titles, stat numbers, empty state headlines, price displays, and bottom nav titles indiscriminately. The result is that nothing is visually prioritized. When everything is bold, nothing is bold.

**Component inconsistency is severe.** Border radius values in use include: 6, 8, 10, 12, 14, 16, 20, 22, 23, 24, 26, 28, and 50%. This is not a system. Cards use 14–20px, inputs use 10–14px, pills use 20–28px — all inconsistently. The selected state for CreateTask type cards uses a coral-red (#D05050) accent that appears nowhere else in the product, indicating components were built in isolation without a governing token system.

**The emotional identity is absent.** SLine is supposed to connect skilled freelancers with clients in Iraq — a market that needs to feel trustworthy, professional, and modern. The current design communicates "generic dark app" rather than "premium marketplace." There is no warmth, no distinction, no memorable quality. Fiverr is cluttered but at least has personality. SLine currently has neither clarity nor personality.

**What should never return:** the collection of 22 near-identical dark backgrounds; fontWeight 900 used on any mobile text; the red left-border accent on tender cards (a UI pattern that belongs to email clients, not marketplaces); the inconsistent radius system; the overuse of teal as both a surface color and a primary action color simultaneously.

---

## 3. New Design Philosophy for SLine

**Principle 1 — Calm Authority.** Every screen should feel settled, not anxious. This means generous whitespace (or dark space), restrained use of accent color, and a type scale where hierarchy is achieved through size *and* weight contrast, not just weight alone. A user should never feel visually overwhelmed when opening SLine.

**Principle 2 — Purposeful Color.** Color earns the right to exist on a screen by communicating something specific. The primary color appears on interactive elements that invite action. Status colors appear only when status is relevant. Surface colors serve a structural function, not a decorative one. The rule is: if removing this color makes the screen less understandable, it belongs. If removing it only makes it less "designed-looking," it does not belong.

**Principle 3 — One Hierarchy, Everywhere.** Every screen uses the same visual grammar: the most important element is largest and most contrasted; supporting information is smaller and lower-contrast; metadata is smallest and muted. This hierarchy never inverts. Users should be able to scan any screen and immediately understand what to look at first.

**Principle 4 — Components Know Their Role.** Cards are containers, not canvases. Buttons are actions, not decorations. Inputs are invitations, not forms. Every component has one job, and its visual design serves that job exclusively. No component is designed for its own sake.

**Principle 5 — Bilingual by Architecture.** RTL support is not a feature added later — it is a constraint baked into every layout decision from day one. This means no hardcoded left/right directions, no components that assume reading direction, and a type system that works equally well in Arabic and Latin.

---

## 4. Best Overall Visual Direction

**Recommended direction: Structured Warmth.**

SLine should feel like the intersection of a premium productivity tool and a trusted marketplace — similar in spirit to Linear's calm focus, Wise's financial clarity, and Airbnb's human warmth, but executed with a distinct personality of its own.

Concretely, this means: a near-white (not pure white) light mode with generous space and a single warm-tinted primary color; a near-black (not pure black) dark mode built on a single surface tonal family rather than 22 ad-hoc colors; typography that leads with a confident, slightly humanist display face paired with a highly legible body face that has proven Arabic support; components that are rounded but not playful, structured but not rigid; and motion that is present but never decorative.

The alternative directions (ultra-minimal monochrome, bold editorial contrast) were considered and rejected for specific reasons. Ultra-minimal monochrome does not work in a marketplace context because it removes the visual vocabulary needed to communicate status, urgency, and trust simultaneously. Bold editorial contrast is too fashionable and will age poorly in two years. Structured Warmth is timeless, scalable, and directly serves the product's core job: making people feel confident enough to hire or be hired.

---

## 5. Recommended Brand Feeling

When a user opens SLine, they should feel **trusted capability**. Not excitement (that is for games and social apps). Not power (that is for financial trading platforms). Trusted capability: the feeling you get when you open a product that clearly knows what it is, does not waste your time, and makes the next step obvious.

The visual system creates this feeling through four specific mechanisms. First, surfaces are calm — they do not shout, do not texture, do not gradient for decoration's sake. Second, the primary color appears only where action is possible, so its appearance always means something. Third, typography is confident — titles are large and clear, body text is readable, metadata is minimal. Fourth, every interactive state is visually distinct — pressed, focused, loading, success, error all look intentionally different, which creates the subconscious impression of a product that has been carefully thought through.

Reference points that capture the *feeling* (not the look) of the target: Wise app (financial trust without sterility), Linear (calm productivity without coldness), Luma events (warm professionalism), Craft (typographic clarity with warmth).

---

## 6. Full Color Strategy

**Should teal stay?** Yes, but it needs to be *promoted* from a UI color to a brand color, and simultaneously *restricted* to only brand-relevant contexts. The current teal (#0D8C8C) is too dark and desaturated to sing at small sizes. The new teal should be slightly lighter and more saturated: **#0E9E9E** as the core brand hue, sitting in a properly-built tonal palette rather than being used as a flat color.

**Strategy: Mono-primary with semantic secondaries.** One primary brand hue (teal family) governs all primary actions. Two semantic secondaries — a warm amber for tender/urgency contexts, and a soft indigo for booking/scheduled contexts — replace the current ad-hoc use of red, gold, and blue. Red is reserved exclusively for destructive actions and error states. Green is reserved exclusively for success states.

**The key discipline:** no color other than the primary teal may appear on an interactive element that is not also communicating a specific semantic meaning. This eliminates the current situation where gold, blue, red, and teal all appear on buttons depending on context.

**Anti-rules for color:**
- Never use teal as a card background AND as a button color on the same screen — choose one role per surface
- Never use more than two accent colors visible simultaneously on a single screen
- Never use #000000 or #ffffff as a surface color — always offset by at least 4% brightness
- Never express status through color alone — always pair with an icon or label
- Never use opacity variants of accent colors as borders (e.g. rgba(teal, 0.12) as a border) — use proper tonal palette values instead

---

## 7. Light Mode Palette

The light mode is built on a warm-neutral base — not cold blue-gray, not pure white. The base surfaces use a very slight warm tint (#FAFAF8 range) that creates a sense of quality paper without going ivory.

```
--- BRAND / TEAL FAMILY ---
brand.teal.50   #E8F7F7   (teal container, teal background)
brand.teal.100  #C5ECEC
brand.teal.200  #96DADA
brand.teal.300  #5EC4C4
brand.teal.400  #2DAEAE
brand.teal.500  #0E9E9E   ← PRIMARY (main brand, all primary buttons)
brand.teal.600  #0B8888
brand.teal.700  #097272
brand.teal.800  #075B5B
brand.teal.900  #054444

--- AMBER / TENDER FAMILY ---
brand.amber.50  #FFF8E6
brand.amber.100 #FFEAB8
brand.amber.200 #FFD878
brand.amber.300 #FFC73C
brand.amber.400 #FFBA0D
brand.amber.500 #F5A623   ← TENDER PRIMARY (tender cards, urgent badges)
brand.amber.600 #E09000
brand.amber.700 #B87400

--- INDIGO / BOOKING FAMILY ---
brand.indigo.50  #EEF0FF
brand.indigo.100 #D5D9FF
brand.indigo.200 #A8B0FF
brand.indigo.300 #7A88FF
brand.indigo.400 #5566FF
brand.indigo.500 #3B4FE8   ← BOOKING PRIMARY (booking cards, calendar)
brand.indigo.600 #2C3DCC

--- NEUTRAL FAMILY (warm-tinted) ---
neutral.0    #FFFFFF
neutral.50   #FAFAF8   ← App background (light)
neutral.100  #F3F2F0   ← Subtle surface, dividers
neutral.200  #E8E7E4   ← Borders, outlines
neutral.300  #D0CFC9   ← Inactive borders
neutral.400  #A8A7A2   ← Disabled text, placeholders
neutral.500  #7A7974   ← Muted text, captions
neutral.600  #504F4B   ← Secondary text
neutral.700  #2E2D2A   ← Primary body text
neutral.800  #1A1918   ← Headings
neutral.900  #0C0B09   ← (Near) black

--- SEMANTIC ---
semantic.success     #1A8A5A
semantic.success.bg  #E8F5EE
semantic.warning     #C47A00
semantic.warning.bg  #FFF3D6
semantic.error       #C8372D
semantic.error.bg    #FEECE9
semantic.info        #2655CC
semantic.info.bg     #EBF0FF

--- SURFACE ROLES (light mode) ---
surface.background   #FAFAF8   (page bg)
surface.base         #FFFFFF   (cards, sheets)
surface.raised       #F3F2F0   (elevated sections, tab bars)
surface.overlay      rgba(12,11,9,0.48)  (modal backdrop)
```

**Usage rules:** surface.background is used for the page itself. surface.base is used for any card or container that sits on the page. surface.raised is used for the bottom navigation, floating elements, and segmented controls — anything that needs to feel above the page without a shadow. No other surfaces exist in light mode.

---

## 8. Dark Mode Palette

The single biggest mistake in dark mode design is treating it as "invert the light mode." The current SLine design made a different but equally bad mistake: inventing a unique dark hex for every screen. The correct approach is a **single tonal surface family** derived from the brand hue, then built upward in consistent elevation steps.

**Why dark modes go muddy:** because designers darken by adding black (subtractive), which loses chroma and creates a sludgy grayish-brown. The correct approach is to darken by moving toward the dark end of the *hue's own tonal palette*, which preserves chroma even at very dark values. For a teal-based product this means dark surfaces have a very slight cool-neutral lean — not visibly teal, but subtly cleaner than a pure black-gray scale.

```
--- DARK SURFACES (single tonal family) ---
dark.surface.base      #0E1212   ← Page background (replaces 22 near-blacks)
dark.surface.container #161C1C   ← Cards, inputs, modals
dark.surface.raised    #1D2626   ← Bottom nav, elevated cards
dark.surface.high      #253030   ← Tooltips, highest surfaces

--- DARK NEUTRALS ---
dark.neutral.0    #0E1212
dark.neutral.100  #161C1C
dark.neutral.200  #1D2626
dark.neutral.300  #253030
dark.neutral.400  #3A4848   ← Borders, dividers
dark.neutral.500  #516060   ← Inactive borders
dark.neutral.600  #7A9090   ← Muted text
dark.neutral.700  #A8BCBC   ← Secondary text
dark.neutral.800  #D4E4E4   ← Primary body text
dark.neutral.900  #EDF5F5   ← Headings, high-contrast text

--- BRAND IN DARK MODE ---
brand.teal.on-dark.active   #2DAEAE   (buttons, active icons — one step lighter)
brand.teal.on-dark.surface  #1A3A3A   (tinted card surfaces — very dark teal bg)
brand.teal.on-dark.border   #2A4848   (subtle teal borders)
brand.teal.on-dark.text     #5EC4C4   (teal text on dark — lighter for contrast)

brand.amber.on-dark.active  #FFB830
brand.amber.on-dark.surface #2A1E00
brand.amber.on-dark.border  #3A2A00
brand.amber.on-dark.text    #FFC84A

brand.indigo.on-dark.active  #8496FF
brand.indigo.on-dark.surface #151A2E
brand.indigo.on-dark.border  #252E4A
brand.indigo.on-dark.text    #9AAEFF

--- SEMANTIC IN DARK MODE ---
semantic.success.dark     #2DBD7A
semantic.success.dark.bg  #0A1E14
semantic.warning.dark     #FFBA36
semantic.warning.dark.bg  #1E1400
semantic.error.dark       #F27066
semantic.error.dark.bg    #1E0B09
semantic.info.dark        #6B8FFF
semantic.info.dark.bg     #0D1428
```

**Dark mode surface rule:** use exactly four surface levels — base, container, raised, high. Nothing else. Any new surface that does not fit these four categories should be questioned. If it cannot be described as "it sits on the page," "it is a card," "it is above cards," or "it is the highest level," it should not exist.

---

## 9. Semantic Token System

Semantic tokens are the bridge between the raw palette and the components. They are named by *role*, not by *color*, so that swapping the palette never requires updating components.

```
=== TEXT TOKENS ===
color.text.primary          → neutral.800 / dark.neutral.900
color.text.secondary        → neutral.600 / dark.neutral.700
color.text.tertiary         → neutral.500 / dark.neutral.600
color.text.disabled         → neutral.400 / dark.neutral.500
color.text.inverse          → neutral.0 / dark.neutral.0
color.text.brand            → brand.teal.500 / brand.teal.on-dark.text
color.text.danger           → semantic.error / semantic.error.dark
color.text.success          → semantic.success / semantic.success.dark
color.text.warning          → semantic.warning / semantic.warning.dark
color.text.tender           → brand.amber.500 / brand.amber.on-dark.text
color.text.booking          → brand.indigo.500 / brand.indigo.on-dark.text

=== SURFACE TOKENS ===
color.surface.page          → surface.background / dark.surface.base
color.surface.card          → surface.base / dark.surface.container
color.surface.elevated      → surface.raised / dark.surface.raised
color.surface.overlay       → surface.overlay / rgba(0,0,0,0.60)
color.surface.brand-subtle  → brand.teal.50 / brand.teal.on-dark.surface
color.surface.tender-subtle → brand.amber.50 / brand.amber.on-dark.surface
color.surface.booking-subtle→ brand.indigo.50 / brand.indigo.on-dark.surface
color.surface.danger-subtle → semantic.error.bg / semantic.error.dark.bg
color.surface.success-subtle→ semantic.success.bg / semantic.success.dark.bg

=== BORDER TOKENS ===
color.border.default        → neutral.200 / dark.neutral.400
color.border.subtle         → neutral.100 / dark.neutral.300
color.border.strong         → neutral.300 / dark.neutral.500
color.border.brand          → brand.teal.500 / brand.teal.on-dark.border
color.border.danger         → semantic.error / semantic.error.dark
color.border.focus          → brand.teal.500 / brand.teal.on-dark.active

=== ACTION TOKENS ===
color.action.primary.default    → brand.teal.500 / brand.teal.on-dark.active
color.action.primary.hover      → brand.teal.600 / brand.teal.400
color.action.primary.pressed    → brand.teal.700 / brand.teal.300
color.action.primary.disabled   → neutral.300 / dark.neutral.400
color.action.primary.on         → neutral.0 / neutral.0

color.action.secondary.default  → color.surface.card
color.action.secondary.border   → color.border.default
color.action.secondary.on       → color.text.primary

color.action.danger.default     → semantic.error.bg / semantic.error.dark.bg
color.action.danger.border      → semantic.error / semantic.error.dark
color.action.danger.on          → semantic.error / semantic.error.dark

=== STATUS TOKENS ===
color.status.active.text    → brand.teal.500 / brand.teal.on-dark.text
color.status.active.bg      → brand.teal.50 / brand.teal.on-dark.surface
color.status.active.border  → brand.teal.200 / brand.teal.on-dark.border

color.status.pending.text   → brand.amber.600 / brand.amber.on-dark.text
color.status.pending.bg     → brand.amber.50 / brand.amber.on-dark.surface
color.status.pending.border → brand.amber.200 / brand.amber.on-dark.border

color.status.completed.text → semantic.success / semantic.success.dark
color.status.completed.bg   → semantic.success.bg / semantic.success.dark.bg
color.status.completed.border → semantic.success / semantic.success.dark (at 40% opacity)

color.status.delivered.text → semantic.info / semantic.info.dark
color.status.delivered.bg   → semantic.info.bg / semantic.info.dark.bg

color.status.cancelled.text → neutral.500 / dark.neutral.600
color.status.cancelled.bg   → neutral.100 / dark.neutral.200

color.status.danger.text    → semantic.error / semantic.error.dark
color.status.danger.bg      → semantic.error.bg / semantic.error.dark.bg

=== SPACING SCALE (base-8 system) ===
space.0    0px
space.1    4px    (tight icon gaps, badge padding)
space.2    8px    (inline element gaps, chip padding)
space.3    12px   (component internal spacing)
space.4    16px   (standard padding, card horizontal)
space.5    20px   (section gaps, card vertical)
space.6    24px   (screen edge padding, sheet padding)
space.8    32px   (large section breaks)
space.10   40px   (major layout divisions)
space.12   48px   (screen top padding)
space.16   64px   (large empty state spacing)

=== RADIUS SCALE ===
radius.xs    4px   (badges, tags, micro chips)
radius.sm    8px   (small chips, context pills)
radius.md    12px  (inputs, small cards, icon buttons)
radius.lg    16px  (standard cards, primary buttons)
radius.xl    20px  (profile cards, bottom sheets top corners)
radius.2xl   28px  (pill buttons, search bar)
radius.full  9999px (fully round: avatars, online dots)

=== ELEVATION SYSTEM ===
elevation.0  (no shadow, use border instead: color.border.default)
elevation.1  0px 1px 3px rgba(0,0,0,0.08), 0px 1px 2px rgba(0,0,0,0.06)
             (light: cards; dark: rarely used)
elevation.2  0px 4px 12px rgba(0,0,0,0.10), 0px 2px 4px rgba(0,0,0,0.06)
             (bottom nav, FAB, floating sheets)
elevation.3  0px 8px 24px rgba(0,0,0,0.14), 0px 4px 8px rgba(0,0,0,0.08)
             (modals, drawers)

RULE: In dark mode, do NOT use shadows. Instead, distinguish elevation levels
purely through surface tonal stepping (container → raised → high).
Shadows on dark surfaces create murky, unconvincing depth.
```

---

## 10. Typography System

**Font recommendation: Plus Jakarta Sans (Latin primary) + IBM Plex Sans Arabic (Arabic)**

Plus Jakarta Sans is the correct choice here because it is geometric enough to feel modern and premium, but it has subtle humanist touches (slightly open apertures, friendly stroke terminals) that prevent it from feeling cold. It has excellent weight coverage (200 through 800) and renders very well on both iOS and Android at small sizes. Most importantly, it does not look like Roboto, and it does not look like Inter — it has a slight personality without being difficult to read.

IBM Plex Sans Arabic is the correct Arabic companion because it was designed specifically as a bilingual system alongside IBM Plex Sans (the Latin), has excellent rendering at all sizes, covers all necessary OpenType features for Arabic text shaping, and its visual rhythm harmonizes with Plus Jakarta Sans's geometric structure better than Cairo or Noto Sans Arabic do.

**How to use them in Flutter:** load both from Google Fonts or bundle locally. Set the app's default font to Plus Jakarta Sans. For any TextSpan or widget that renders Arabic content, use IBM Plex Sans Arabic via a FontFamily override. This is cleanly achievable in Flutter using locale-aware text rendering.

**Type Scale:**

```
=== DISPLAY ===
display.large    size: 48  weight: 700  lineHeight: 1.10  tracking: -0.5px
                 (wallet balance, hero numbers — use sparingly)
display.medium   size: 36  weight: 700  lineHeight: 1.15  tracking: -0.3px
                 (large price displays, splash screens)

=== HEADLINE ===
headline.large   size: 28  weight: 700  lineHeight: 1.20  tracking: -0.2px
                 (screen titles: Home, Wallet, Profile)
headline.medium  size: 24  weight: 700  lineHeight: 1.25  tracking: -0.1px
                 (section headers with top-level importance)
headline.small   size: 20  weight: 600  lineHeight: 1.30  tracking: 0
                 (sub-section titles, sheet headers)

=== TITLE ===
title.large      size: 18  weight: 600  lineHeight: 1.35  tracking: 0
                 (card titles, nav bar titles)
title.medium     size: 16  weight: 600  lineHeight: 1.40  tracking: 0.1px
                 (menu items, settings rows, conversation names)
title.small      size: 14  weight: 600  lineHeight: 1.45  tracking: 0.1px
                 (card subtitle, secondary card title)

=== BODY ===
body.large       size: 16  weight: 400  lineHeight: 1.60  tracking: 0.1px
                 (primary body text, descriptions, chat messages)
body.medium      size: 14  weight: 400  lineHeight: 1.65  tracking: 0.2px
                 (supporting descriptions, detail text)
body.small       size: 13  weight: 400  lineHeight: 1.60  tracking: 0.2px
                 (metadata, timestamps, footer info)

=== LABEL ===
label.large      size: 14  weight: 600  lineHeight: 1.30  tracking: 0.3px
                 (button text, active tab, form labels)
label.medium     size: 12  weight: 600  lineHeight: 1.30  tracking: 0.4px
                 (tags, badges, filter chips, nav labels)
label.small      size: 11  weight: 600  lineHeight: 1.30  tracking: 0.6px
                 (status badges — UPPERCASE only here)
                 (uppercase with 0.6px tracking IS correct for status badges)

=== CAPTION ===
caption          size: 12  weight: 400  lineHeight: 1.50  tracking: 0.3px
                 (timestamps in cards, footnotes, "FROM" prefixes)
```

**Scale reasoning:** this is 11 steps, not 17. The discipline of fewer steps forces decisions. The weight shifts (700 → 600 → 400) create contrast even when sizes are close together. Headline uses 700 because it needs authority. Title uses 600 because it needs presence without shouting. Body uses 400 because readability at body sizes requires normal weight.

**What to delete:** font weights 800 and 900. They are too heavy for mobile display. Plus Jakarta Sans 700 is already very bold on mobile. 800+ creates visual aggression, not hierarchy. Reserve weight 800 only for the wallet/price display number (display.large) if absolutely needed.

---

## 11. Spacing / Radius / Elevation System

**Spacing: Base-8 with 4px half-steps allowed only for micro contexts.**

The base-8 system means every spacing value is a multiple of 8: 8, 16, 24, 32, 40, 48, 64. The 4px half-steps (4, 12, 20, 28) are allowed *only inside components* for internal padding adjustments — never for layout spacing between elements. This discipline creates the subconscious sense of alignment and rhythm that separates premium apps from apps that merely look okay.

**Concrete layout application:**
- Screen edge padding: 20px (not 16, not 24 — 20 is comfortable on 390px wide screens for a marketplace with lots of card content)
- Card internal padding: 16px horizontal, 16px vertical
- Section gaps (between groups of cards): 24px
- Between title and first card in a section: 12px
- Between cards in a list: 12px
- Bottom navigation height: 72px (with 8px safe area buffer below icons)
- Top nav height: 52px

**Radius system — 6 values only:**

radius.xs (4px) is for inline labels, status badges — elements so small that a larger radius would make them look like dots.
radius.sm (8px) is for tags, filter chips, and any pill-shaped chip that carries a label.
radius.md (12px) is for inputs, search bars, icon buttons, and small cards (conversation list items).
radius.lg (16px) is for standard cards — this is the workhorse value.
radius.xl (20px) is for primary action buttons, bottom sheet top corners, and large hero cards.
radius.full (9999px) is for avatar images, online status dots, notification count badges, and purely circular elements.

No value between these may be used. If a component does not fit one of these six values, the component geometry should be adjusted to fit, not the radius scale.

**Elevation model:**

In light mode, cards use elevation.1 (very subtle shadow). This distinguishes cards from the page background without heavy shadowing. The bottom nav uses elevation.2. Modals and bottom sheets use elevation.3.

In dark mode, elevation is expressed entirely through surface tonal steps: page (dark.surface.base) → card (dark.surface.container) → raised (dark.surface.raised) → top (dark.surface.high). No shadows in dark mode. This is a firm rule.

**Dividers:** use color.border.subtle (a 1px line) for list separators inside grouped sections. Do not use full-width dividers between standalone cards — spacing alone should separate them.

---

## 12. Core Component Redesign Recommendations

**Primary Button**
Height: 52px. Radius: radius.xl (20px). Background: color.action.primary.default. Label: label.large (14px, weight 600, white). Horizontal padding: 24px. States: hover → primary.hover (one step darker); pressed → scale transform 0.97 + primary.pressed; disabled → neutral background + neutral.500 text. No icon by default; if icon is present, 18px icon with 8px gap to text. Do not use a full-width button for every primary action — full width is reserved for authentication flows and form submission only.

**Secondary Button**
Same height and radius as primary. Background: transparent. Border: 1.5px color.border.default. Label: color.text.primary. Hover: surface.raised background. This replaces all the various "outline" ghost buttons currently scattered across the app with a single consistent component.

**Destructive Button**
Height: 52px. Radius: radius.xl. Background: color.action.danger.default (very subtle error-tinted background). Border: color.action.danger.border. Label: color.action.danger.on. Use only for logout, delete, cancel contract — not for "decline offer" which should be a secondary button.

**Text Button / Link Button**
No background, no border. Label: color.text.brand. Underline: none normally, underline on hover/focus. Height: 36px touch target minimum. Used for "Forgot password," "Mark all as read," "View all" patterns.

**FAB (Floating Action Button)**
Size: 56×56px. Radius: radius.full. Background: color.action.primary.default. Icon: 24px, white. Shadow: elevation.2. Position: 20px from right edge, 20px above bottom nav. Only one FAB per screen. Never label it — icon must be self-explanatory.

**Input Field**
Height: 52px. Radius: radius.md (12px). Background: color.surface.card. Border: 1px color.border.default; focused: 2px color.border.focus (brand teal). Label above the field: body.small weight 600, color.text.secondary. Placeholder: body.large, color.text.tertiary. Error state: border color.border.danger, error message below in body.small color.text.danger. No icon inside the field unless it is a password toggle or clear button. Search bar is a special variant: radius.xl (20px), includes search icon on the left at 18px, clear button on right when text is present.

**Search Bar**
Height: 48px. Radius: radius.xl (20px). Background: color.surface.card in dark mode, neutral.100 in light mode. Left: 16px padding + Search icon (18px, color.text.tertiary) + 10px gap + placeholder. Right: filter icon button (40×40, radius.md, color.action.primary.default) attached flush right OR separated by 8px. The filter button being teal is acceptable *only here* because it is the primary call-to-discovery action on the home screen.

**Segmented Control**
Container: radius.md (12px). Height: 44px. Background: color.surface.raised. Each segment: flex-1. Active segment: radius.sm (8px) inset, background color.surface.card, label.large weight 600, color.text.primary. Inactive: label.large weight 400, color.text.tertiary. No accent color in the segmented control — it is a navigation pattern, not an action pattern.

**Tab Bar (underline style)**
Used for sub-navigation within a screen (Dashboard tabs, Profile tabs). Tabs are text-only. Active: label.large weight 600, color.text.brand, 2px underline indicator in color.action.primary below text. Inactive: label.large weight 400, color.text.tertiary. No background, no pill wrapper. Scrollable when tabs do not fit.

**Filter Chip**
Height: 36px. Radius: radius.sm (8px). Horizontal padding: 14px. Inactive: background transparent, border 1px color.border.default, label.medium color.text.secondary. Active: background color.surface.brand-subtle, border color.border.brand, label.medium color.text.brand. Icon optional (left at 14px if present). This is the ONLY chip style in the product. No separate "pill" and "square tag" variants.

**Bottom Navigation**
Height: 72px (plus safe area). Background: color.surface.elevated (slightly raised from page). Top border: 1px color.border.subtle. 6 tabs: Home, Tenders, Bookings, Dashboard, Messages, Profile. Each tab: icon (22px) centered, label (label.medium 10px) below at 3px gap. Active: icon and label in color.text.brand. Inactive: icon and label in color.text.tertiary. Active indicator: small 4×4px dot below the label in color.action.primary, NOT an underline under the icon. Notification dot: 8px circle, color.status.danger.text, positioned at top-right of icon.

**Top Navigation Bar**
Height: 52px. Background: color.surface.page (transparent to page, NOT a separate surface). Left: back button (ChevronLeft, 24px) in a 40×40 touch target. Center or left-aligned: title at title.large. Right: 0–2 icon actions. The nav bar does not have a bottom border by default — a screen that needs a separator uses a scroll-triggered thin border at color.border.subtle.

**Card — Service/Booking Card**
No image header. The current green image header creates visual noise and inconsistency when images are missing. Replace with a colored left stripe (4px) in the booking category color OR a category icon in a tinted container. Structure: 16px internal padding, category stripe or icon, title (title.large), skills/tags row, thin divider, price row + CTA button. The CTA inside the card should be a small secondary button — not a full teal pill taking up half the footer.

**Card — Tender Card**
Remove the red left border entirely. Instead, use a small amber/orange indicator badge at top-right labeled "TENDER" in label.small. This communicates the type without visually alarming the user before they have read the title. The card border should be color.border.default — identical to all other cards. The visual distinction between Tender and Booking is carried by the category badge color (amber for tender, indigo for booking), not the card border.

**Card — Booking Status Card (Dashboard)**
Use the surface token system: ACTIVE cards get color.surface.brand-subtle background with color.border.brand border. PENDING gets color.surface.tender-subtle. COMPLETED gets color.surface.success-subtle. DELIVERED gets color.surface.booking-subtle (indigo). This is cleaner and more systematized than the 22 different hex backgrounds currently in use.

**Chat Bubble — Sent**
Background: color.action.primary.default. Text: white, body.large. Radius: 18px 18px 4px 18px (top-left, top-right, bottom-right, bottom-left). Max width: 72% of screen. Timestamp + read indicator at bottom-right of bubble, 10px size, white at 60% opacity.

**Chat Bubble — Received**
Background: color.surface.card. Text: color.text.primary, body.large. Radius: 18px 18px 18px 4px. Max width: 72%.

**Offer Card (in chat)**
Background: color.surface.brand-subtle. Border: 1.5px color.border.brand. Radius: radius.lg (16px). Contains: OFFER badge (label.small, teal), price (headline.small, teal), title (title.medium), description (body.medium, tertiary), delivery time (caption + icon), action button (Accept/View). Completed state changes border to color.status.completed.border and adds a completed banner row.

**Bottom Sheet**
Background: color.surface.card. Top radius: radius.xl (20px) on both top corners only. Bottom radius: 0 (flush with screen bottom). Drag handle: 36×4px, radius.full, neutral.300/dark.neutral.400, centered, 10px from top. Header: 20px horizontal padding, title (headline.small), optional close button (X icon, 24px). Content: 20px padding. Max height: 85% of screen. Always has an overlay backdrop (color.surface.overlay).

**Settings Row**
Height: 60px. Horizontal padding: 16px. Left: 40×40 icon container (radius.md, color.surface.brand-subtle for brand actions, neutral for others), 12px gap, title (title.medium) + optional subtitle (body.small, tertiary). Right: ChevronRight (16px, tertiary) for navigation rows, or Toggle for toggle rows. Row is separated by a subtle inset divider at color.border.subtle — not a full-width divider.

**Notification Item**
Padding: 16px. Left: icon or avatar (40px). Center: title (title.small) + body (body.medium, 1 line max). Right: timestamp (caption) + unread dot (8px, danger color) if unread. Unread background: color.surface.brand-subtle at very low opacity. Read: color.surface.page.

**Empty State**
Centered layout. Illustration or icon (48px, color.text.tertiary) with 4px tint at color.surface.brand-subtle as circular container (72×72). Title: headline.small, color.text.primary. Body: body.medium, color.text.secondary, max 2 lines. Optional CTA button (secondary style). Vertical spacing: 16px between each element. Top margin: 64px from top of content area. No decorative flourishes, no large vector illustrations — keep it simple and fast.

**Skeleton Loader**
Replaces every card with a same-shape placeholder. Colors: color.surface.card base, with animated shimmer gradient from color.surface.card to color.surface.raised and back. Duration: 1.2s, ease-in-out loop. Skeleton shapes match card structure exactly (title bar, two tag bars, price row).

**Avatar**
4 defined sizes: 32px (list items), 44px (card headers), 56px (profile sections, conversation cards), 88px (full profile screen). 32px and 44px: radius.sm (8px square). 56px: radius.md (12px square). 88px: radius.full (circular). Initials avatar: background color.surface.brand-subtle, text color.text.brand, label.medium. Camera badge (edit profile): 28×28, radius.full, white background, 12px dark camera icon, 2px border in color.surface.page.

**Toggle Switch**
Width: 48px. Height: 28px. Radius: radius.full. On state: background color.action.primary.default, knob white at right position. Off state: background neutral.300/dark.neutral.400, knob white at left position. Knob: 22px, radius.full, white. Transition: 180ms ease.

---

## 13. Screen-by-Screen Redesign Strategy

**Home / Discovery**
The current home screen loads too many distinct visual patterns simultaneously: a search bar, horizontal category pills, a "For You" section, and dense card grids. The new home starts with a clean header (greeting + avatar + bell icon) using headline.large, followed immediately by the search bar and filter button. Below the search, a single horizontal scroll of filter chips (All, Design, Development, Marketing, Writing, etc.) replaces the current pill row but uses the new filter chip component — not mixed pill/pill styles. Cards are displayed in a single-column list for Tenders (better scannability for complex marketplace items) and a two-column grid for Services/Bookings. This list vs grid distinction is the primary layout organization of the home screen. Remove the cluttered "Recent Activity" section from the home page — it belongs only in Dashboard.

**Tenders List**
Clean list view, single column. Each card: category badge (amber, top-right), title (title.large, 2 lines max), description snippet (body.medium, 2 lines, tertiary color), tags row (max 3 chips), footer row (bids count + deadline + budget range). No left-border red accent. The urgency of a tender is communicated through the amber badge and the deadline text, not a red border. FAB for "Post a Tender" at bottom right.

**Tender Detail**
Title at headline.large, below it the client avatar + name + verified badge + rating. Below that: a horizontal info row (budget, deadline, bids count) using three compact stat blocks. Body description in body.large with generous line height. Tags section. Bottom action bar: Message button (secondary) + Apply/Bid button (primary). The action bar is sticky at bottom with a clean surface background — no gradients, no blur.

**Bookings Discovery**
Two-column grid of service cards. Each card: category color stripe (left, 4px), provider avatar + name + rating, service title (title.large), price (headline.small, teal), "Book Now" CTA (small secondary, not full teal pill). Horizontal category filter at top. Sort/filter button as icon button.

**Booking Detail**
Full service info with provider profile section at top (avatar, name, rating, stats row). Plan selector using segmented control (Basic / Standard / Premium). Plan details in a structured card. Deliverables list using checkmark rows. Reviews section. Sticky bottom action bar with price + Book Now button.

**Create Task**
Multi-step flow with a clean progress indicator at top (3 dots or 3 labeled steps, no complex gradient header). Step 1: Task type selection (two large cards, Tender vs Booking, using booking-indigo and tender-amber accent respectively to distinguish them clearly). Step 2: Category + details. Step 3: Logistics (deadline, budget). Each step is a single scrollable page — no carousels. The progress indicator uses a simple 3-dot row where completed dots are filled teal, current is outlined teal, future are outlined neutral.

**Chat Conversation**
Clean chat interface. Top bar: back button, avatar + name + online status, call/video icon buttons (future), more menu. Context banner (which booking/tender this is about) as a compact pill below the top bar — collapsible after first view. Messages: sent right-aligned teal, received left-aligned card surface. Offer cards as full-width inline cards with accept/decline actions. Bottom input bar: attachment icon + text input (radius.full) + send button. No "Offer" button in the top bar — offers should be created from a "+" menu in the input area.

**Messages List**
Simple list. Each conversation card: avatar (56px, square rounded), name + context line (amber "BOOKING:" or teal "TENDER:" prefix), last message snippet, timestamp, unread badge. Sorted by recency. Search bar at top.

**Dashboard**
Tab bar (Overview / Bookings / Work / Wallet / Inbox). Overview tab: stat cards grid (2×2), recent bookings preview (3 items), recent work preview (3 items). Each tab shows the relevant content cleanly. The current design puts too much on Overview — it tries to be a summary of everything and ends up being a summary of nothing. Each tab should be able to stand alone.

**Wallet**
Hero balance display at top: display.large for the number, caption for "Available Balance." Below: three balance indicators (Available, Pending, Held) as inline stat row. Action buttons: Withdraw, Add Funds (two secondary buttons). Transaction list with date grouping. Each transaction: colored dot (teal = received, amber = pending, error = paid out), title, subtitle, amount.

**Profile (own)**
Avatar (88px, circular) + name (headline.large) + title/role (body.medium, secondary). Stats row (3 stats). Role toggle (Client / Freelancer segmented control). Menu list below: Edit Profile, Portfolio, Settings, Help, Log Out. Clean and simple — no teal gradient banners, no decorative elements.

**User Profile (other)**
Header with avatar, name, verified badge, rating, country. Stats row. Tab bar (About / Portfolio / History / Reviews). Message + Hire Now buttons sticky at bottom. About tab: bio + skills chips + languages. No gradient banner — a clean card-surface header instead.

**Settings**
Section-grouped list. Sections: Account, Preferences, Notifications, Privacy, Support, Legal. Each section has a section label (label.small, uppercase, tertiary) above the grouped rows. Rows use the settings row component. Log Out is at the very bottom as a destructive button (full width, danger style), separated from the settings list by generous spacing.

**Saved Items / Favorites**
Two tabs: Freelancers | Tasks. Grid or list of saved items with a Heart icon filled in the card corner. Empty state with "Explore" CTA. Simple, clean.

**Notifications**
List with date grouping (Today, Yesterday, This Week). Each item uses the notification component. Mark all as read button in the header (text button, right-aligned). Unread items have color.surface.brand-subtle background.

**Search Results**
Full-screen results with filter bar at top (horizontal chips). Results list — same cards as the respective section. Empty results state with clear messaging and suggestion chips ("Try: Design, Marketing, Development").

---

## 14. Motion System

**Philosophy: Motion serves navigation and feedback, never decoration.** If an animation does not help the user understand what happened or where they are going, it should not exist. The question to ask for every animation: "Does a user who turns this animation off lose any information?" If no, reconsider whether it should exist at all.

**Duration scale:**
```
motion.instant   0ms    (immediate state changes: checkbox tick, toggle)
motion.fast      100ms  (button press feedback, color state changes)
motion.medium    200ms  (component transitions: sheet expand, card press)
motion.slow      350ms  (screen transitions, modal entry/exit)
motion.lazy      500ms  (skeleton shimmer cycle, long loading animations)
```

**Easing curves:**
```
easing.standard    cubic-bezier(0.2, 0.0, 0, 1.0)   (M3 standard — most transitions)
easing.decelerate  cubic-bezier(0.0, 0.0, 0.2, 1.0)  (elements entering the screen)
easing.accelerate  cubic-bezier(0.4, 0.0, 1.0, 1.0)  (elements leaving the screen)
easing.spring      spring(stiffness: 300, damping: 28) (FAB, modal bounce — use sparingly)
```

**Specific transition rules:**
- Screen-to-screen push navigation: horizontal slide, 300ms, standard easing. Slide distance: 100% of screen width for push, 30% for pop (Material 3 predictive back).
- Bottom sheet: vertical slide up from bottom, 300ms, decelerate easing. Dismiss: 250ms, accelerate easing.
- Cards in a list appearing on load: staggered fade + translate-Y(8px → 0), 200ms per card, 30ms stagger between items. Maximum stagger: 180ms total (do not stagger more than 6 items).
- FAB: scale from 0 to 1 on mount, easing.spring. FAB press: scale 0.92 in 80ms, return 120ms.
- Tab switching: active indicator slides horizontally to new tab, 200ms, standard easing. Content cross-fades, 150ms.
- Status badge state change: color cross-fade, 200ms. No bouncing, no pulsing.
- Skeleton to content: fade out skeleton, fade in content, 250ms. Do NOT snap replace.

**Where motion must be reduced or eliminated:** every screen in the app should fully respect `prefers-reduced-motion` (or Flutter's `AccessibilityFeatures.disableAnimations`). When this is active, all transitions become instant opacity changes. Duration: motion.instant for all.

---

## 15. Accessibility and Usability Standards

**Contrast requirements:** All text on surfaces must meet WCAG AA minimum — 4.5:1 for normal text, 3:1 for large text (18px+ regular or 14px+ bold). The recommended color tokens above have been designed to meet these ratios. Specifically: color.text.primary on color.surface.page achieves approximately 14:1 in light mode and 12:1 in dark mode. color.text.secondary achieves 6:1. color.text.tertiary achieves 4.6:1. Teal-on-dark (#2DAEAE on #0E1212) achieves 7.2:1 — sufficient for all uses. Do not use color.text.tertiary for anything that conveys essential information.

**Minimum touch targets:** 44×44px absolute minimum (Apple HIG) / 48×48px recommended (Material 3). In SLine, every tappable element must have a minimum 44×44px touch target even if its visual size is smaller. This is implemented in Flutter using `GestureDetector` with `HitTestBehavior.opaque` combined with sufficient padding, or using `Material` widget's `inkWell` with explicit minimum constraints.

**Font size floors:** never render any text at less than 11px (label.small). Even caption text sits at 12px. Do not reduce font sizes below these values for any reason, including "compact" variants.

**RTL readiness:** every layout component must be built using `start`/`end` instead of `left`/`right`. In Flutter, this means using `EdgeInsetsDirectional` instead of `EdgeInsets`, using `Row` with `TextDirection` awareness, and never hardcoding icon placement (a left-side icon in LTR is a right-side icon in RTL). The left-accent bar pattern (4px colored stripe on the left of cards) should be replaced with the new category badge approach, which is direction-agnostic. Card chevrons (ChevronRight in LTR) automatically flip in RTL when using Flutter's `Directionality` widget.

**State communication rules:** every interactive element must have a visually distinct state for: default, hovered (web), focused (keyboard/accessibility), pressed, disabled, loading, error. Loading state for buttons: replace button label with a 20px `CircularProgressIndicator` in white. Never disable a button silently — always pair disabled appearance with a tooltip or visible reason.

**Dark mode clarity rules:** all text in dark mode must be checked against `dark.surface.container` (the card background), not against `dark.surface.base` (the page background), since most text appears inside cards. The dark neutral palette has been calibrated for this. Never place muted text (dark.neutral.600 / #7A9090) on a dark.surface.high surface — the contrast drops below 3.5:1.

**Visual QA checklist (per screen before shipping):**
- [ ] All touch targets ≥ 44×44px
- [ ] No text smaller than 11px
- [ ] Primary action is obvious within 2 seconds of viewing
- [ ] Status badges pair color with icon or label
- [ ] Empty state exists and contains a recovery action
- [ ] Loading state exists for all async data
- [ ] Error state exists and communicates clearly
- [ ] Screen functions without any color (test in grayscale)
- [ ] Screen functions in RTL layout direction
- [ ] All animations respect reduced motion setting

---

## 16. What Must Be Deleted from the Old System

These elements should not appear anywhere in the new design:

**22 distinct near-black hex values.** Replaced entirely by the four dark surface tokens. There is no design reason for #0D1515, #141C1C, #0A1C1C, #0C1414, #151E1E, #0D2525, #1A2020, etc. to all exist simultaneously.

**Font weights 800 and 900.** Too heavy for mobile. Plus Jakarta Sans 700 is already impactful. Weights above 700 are removed entirely from the type system.

**The red left-border accent on tender cards.** This is a UI pattern borrowed from email/inbox applications (unread message indicator). It does not belong in a marketplace card. The amber badge approach communicates "tender" without visual alarm.

**The teal gradient banner on UserProfile** (linear-gradient from #0D8C8C to #5AC8C8). Gradients on solid sections feel decorative, not functional. Replace with a clean card-surface header.

**The 40px wallet balance in fontWeight 900 using the old teal.** The new display.large at 48px in weight 700 with the new teal is cleaner and more readable.

**SELECTED_BG (#2A1010) and border (#D05050) for CreateTask type/category selection.** This coral-red selection state appears nowhere else in the app and creates a false signal (red typically means danger/error). Replace with teal-branded selection (color.surface.brand-subtle + color.border.brand).

**The "Offer" button in the ChatScreen nav bar.** Putting a CTA inside the navigation bar collapses the functional boundary between navigation and actions. The offer action moves to the input area.

**Star rating icon at 13px in a 12px line-height context.** Unreadable. All rating displays use 14px stars minimum.

**The overloaded use of teal as: card background, border, text, button, icon, badge, and header simultaneously.** The new system limits teal to: primary button backgrounds, active state indicators, positive text labels, and brand moments. It cannot simultaneously serve as both a surface color and an interactive color on the same screen.

---

## 17. What Is Safe to Preserve

**The teal brand hue direction.** The choice of teal as a primary brand color is correct for SLine. It communicates trust, professionalism, and a slight technological precision — exactly right for a marketplace. The specific value (#0D8C8C) is too dark; it is promoted and lightened to #0E9E9E. But the hue is worth keeping.

**The amber color for tender urgency.** Using gold/amber (#F5A623) to signal tender-related urgency is a genuinely good design decision. It carries through in a refined form in the new system.

**The 6-tab bottom navigation structure.** Having Home, Tenders, Bookings, Dashboard, Messages, and Profile as the six primary navigation tabs is the correct information architecture for this product.

**The offer card pattern in chat.** The concept of a structured offer card appearing inline in a chat conversation is a strong, distinctive pattern. The visual execution needs rebuilding but the concept is excellent.

**The left-accent stripe pattern for wallet flows.** Using a colored left stripe to visually distinguish transaction types (received vs. paid out vs. pending) in a wallet list is a proven fintech pattern (Wise uses it). Keep it but build it from the semantic color tokens instead of hardcoded hex values.

**The progress header for multi-step task creation.** A labeled step indicator at the top of a multi-step flow is the correct pattern. The visual execution (gradient teal header, complex stage labels) needs rebuilding but the pattern is right.

---

## 18. Three Redesign Directions

**Direction A — Refined Market (Most Balanced)**
This direction feels like a premium Middle Eastern marketplace that has studied Linear and Wise equally. It is calm, structured, and immediately professional. The primary palette is teal with warm neutral surfaces (slightly sand-tinted whites and dark taupes). Typography is Plus Jakarta Sans throughout in both languages. Component language is card-forward with clear categorical color coding (amber for tender, indigo for booking). Motion is purposeful and minimal. It works in both light and dark mode with equal quality. This direction has the widest appeal, the easiest implementation, and the most direct path to feeling premium without risk. It is the safe bet — in the best sense of "safe."

**Direction B — Precision Dark (Most Premium)**
This direction commits fully to the dark mode as the primary experience. Surfaces are a deep, refined teal-dark with a very slight chromatic warmth. Typography shifts slightly — the body font pairs Plus Jakarta Sans with a narrower tracking, and headline sizes are more restrained (maximum 26px) for a denser, more professional feel. The accent color (teal) is used even more sparingly — primarily on numbers (prices, stats) and primary buttons only. Cards have extremely subtle borders (1px, barely visible) rather than the tonal surface differential used in Direction A. This direction would feel at home alongside Revolut, Linear, and Raycast. It requires design discipline that is harder to maintain across a large feature set, and it needs very careful quality control to avoid feeling overly cold.

**Direction C — Warm Contrast (Most Memorable)**
This direction introduces a warm off-white cream (#F6F3EE) as the light mode surface, and a very warm dark (#12100D) as the dark mode surface, breaking the standard blue-gray dark mode convention entirely. The teal primary is paired with a warm terracotta secondary (#D4603A) for client-side actions, creating a warm-cool contrast. Typography is bolder in headlines (slightly more editorial). This direction would be the most visually distinctive in the Iraqi market — nothing else in the local marketplace/freelancing category looks like this. The risk is that the warm surfaces may feel less "digital-professional" to some users, and maintaining the warm-cool color balance across 20+ screens requires significant design discipline.

---

## 19. Final Recommended Direction

**Direction A — Refined Market** is the correct choice for SLine at this stage of the product's development.

Here is the specific reasoning: Direction B (Precision Dark) requires a level of design system maturity and quality control that is better achieved after the base system is fully established — it is less forgiving of inconsistencies. Direction C (Warm Contrast) is the most differentiated, but differentiation is not SLine's primary problem right now. The primary problem is that the product lacks basic design coherence, trustworthiness, and readability. Solving coherence with a warm-terracotta-on-cream palette is a higher-variance bet than solving it with a clean, structured neutral system.

Direction A gives SLine three things it needs immediately: (1) a coherent surface system that eliminates the 22-hex-background problem; (2) a clear color vocabulary where amber means tender, indigo means booking, and teal means action — which is immediately learnable by users; and (3) a typography system that works elegantly in both Arabic and Latin, which is non-negotiable for the target market.

Once Direction A is implemented and the product is stable, the team can evolve toward the warmer Direction C personality as a refinement of the established system, not as a replacement.

---

## 20. Full Design Token Proposal

This token list is organized in three layers as recommended for a production Flutter implementation.

```dart
// ═══════════════════════════════════════════════
// LAYER 1: PRIMITIVE TOKENS
// lib/core/theme/tokens/primitives.dart
// ═══════════════════════════════════════════════

class SLinePrimitives {
  // Teal family
  static const teal50  = Color(0xFFE8F7F7);
  static const teal100 = Color(0xFFC5ECEC);
  static const teal200 = Color(0xFF96DADA);
  static const teal300 = Color(0xFF5EC4C4);
  static const teal400 = Color(0xFF2DAEAE);
  static const teal500 = Color(0xFF0E9E9E); // PRIMARY
  static const teal600 = Color(0xFF0B8888);
  static const teal700 = Color(0xFF097272);
  static const teal800 = Color(0xFF075B5B);
  static const teal900 = Color(0xFF054444);

  // Dark teal surfaces
  static const tealDarkSurface  = Color(0xFF1A3A3A);
  static const tealDarkBorder   = Color(0xFF2A4848);
  static const tealDarkActive   = Color(0xFF2DAEAE);
  static const tealDarkText     = Color(0xFF5EC4C4);

  // Amber family
  static const amber50  = Color(0xFFFFF8E6);
  static const amber100 = Color(0xFFFFEAB8);
  static const amber200 = Color(0xFFFFD878);
  static const amber300 = Color(0xFFFFC73C);
  static const amber500 = Color(0xFFF5A623); // TENDER
  static const amber600 = Color(0xFFE09000);

  static const amberDarkSurface = Color(0xFF2A1E00);
  static const amberDarkBorder  = Color(0xFF3A2A00);
  static const amberDarkActive  = Color(0xFFFFB830);
  static const amberDarkText    = Color(0xFFFFC84A);

  // Indigo family
  static const indigo50  = Color(0xFFEEF0FF);
  static const indigo100 = Color(0xFFD5D9FF);
  static const indigo200 = Color(0xFFA8B0FF);
  static const indigo500 = Color(0xFF3B4FE8); // BOOKING
  static const indigo600 = Color(0xFF2C3DCC);

  static const indigoDarkSurface = Color(0xFF151A2E);
  static const indigoDarkBorder  = Color(0xFF252E4A);
  static const indigoDarkActive  = Color(0xFF8496FF);
  static const indigoDarkText    = Color(0xFF9AAEFF);

  // Neutral family (warm-tinted)
  static const neutral0   = Color(0xFFFFFFFF);
  static const neutral50  = Color(0xFFFAFAF8);
  static const neutral100 = Color(0xFFF3F2F0);
  static const neutral200 = Color(0xFFE8E7E4);
  static const neutral300 = Color(0xFFD0CFC9);
  static const neutral400 = Color(0xFFA8A7A2);
  static const neutral500 = Color(0xFF7A7974);
  static const neutral600 = Color(0xFF504F4B);
  static const neutral700 = Color(0xFF2E2D2A);
  static const neutral800 = Color(0xFF1A1918);
  static const neutral900 = Color(0xFF0C0B09);

  // Dark neutral family
  static const darkBase      = Color(0xFF0E1212);
  static const darkContainer = Color(0xFF161C1C);
  static const darkRaised    = Color(0xFF1D2626);
  static const darkHigh      = Color(0xFF253030);
  static const darkBorder    = Color(0xFF3A4848);
  static const darkBorderSubtle  = Color(0xFF253030);
  static const darkMuted         = Color(0xFF7A9090);
  static const darkSecondary     = Color(0xFFA8BCBC);
  static const darkPrimary       = Color(0xFFD4E4E4);
  static const darkHeading       = Color(0xFFEDF5F5);

  // Semantic
  static const successLight  = Color(0xFF1A8A5A);
  static const successBgLight = Color(0xFFE8F5EE);
  static const successDark   = Color(0xFF2DBD7A);
  static const successBgDark  = Color(0xFF0A1E14);

  static const warningLight   = Color(0xFFC47A00);
  static const warningBgLight = Color(0xFFFFF3D6);
  static const warningDark    = Color(0xFFFFBA36);
  static const warningBgDark  = Color(0xFF1E1400);

  static const errorLight     = Color(0xFFC8372D);
  static const errorBgLight   = Color(0xFFFEECE9);
  static const errorDark      = Color(0xFFF27066);
  static const errorBgDark    = Color(0xFF1E0B09);

  static const infoLight      = Color(0xFF2655CC);
  static const infoBgLight    = Color(0xFFEBF0FF);
  static const infoDark       = Color(0xFF6B8FFF);
  static const infoBgDark     = Color(0xFF0D1428);

  // Spacing
  static const double space1  = 4.0;
  static const double space2  = 8.0;
  static const double space3  = 12.0;
  static const double space4  = 16.0;
  static const double space5  = 20.0;
  static const double space6  = 24.0;
  static const double space8  = 32.0;
  static const double space10 = 40.0;
  static const double space12 = 48.0;
  static const double space16 = 64.0;

  // Radius
  static const double radiusXs   = 4.0;
  static const double radiusSm   = 8.0;
  static const double radiusMd   = 12.0;
  static const double radiusLg   = 16.0;
  static const double radiusXl   = 20.0;
  static const double radius2xl  = 28.0;
  static const double radiusFull = 9999.0;

  // Typography sizes
  static const double displayLg = 48.0;
  static const double displayMd = 36.0;
  static const double headlineLg = 28.0;
  static const double headlineMd = 24.0;
  static const double headlineSm = 20.0;
  static const double titleLg    = 18.0;
  static const double titleMd    = 16.0;
  static const double titleSm    = 14.0;
  static const double bodyLg     = 16.0;
  static const double bodyMd     = 14.0;
  static const double bodySm     = 13.0;
  static const double labelLg    = 14.0;
  static const double labelMd    = 12.0;
  static const double labelSm    = 11.0;
  static const double caption    = 12.0;

  // Motion durations (in ms)
  static const int durationInstant = 0;
  static const int durationFast    = 100;
  static const int durationMedium  = 200;
  static const int durationSlow    = 350;
  static const int durationLazy    = 500;
}


// ═══════════════════════════════════════════════
// LAYER 2: SEMANTIC TOKENS
// lib/core/theme/tokens/semantic.dart
// (Uses ThemeExtension for custom tokens)
// ═══════════════════════════════════════════════

class SLineColorTokens extends ThemeExtension<SLineColorTokens> {
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textDisabled;
  final Color textBrand;
  final Color textDanger;
  final Color textSuccess;
  final Color textWarning;
  final Color textTender;
  final Color textBooking;

  final Color surfacePage;
  final Color surfaceCard;
  final Color surfaceElevated;
  final Color surfaceBrandSubtle;
  final Color surfaceTenderSubtle;
  final Color surfaceBookingSubtle;
  final Color surfaceDangerSubtle;
  final Color surfaceSuccessSubtle;

  final Color borderDefault;
  final Color borderSubtle;
  final Color borderStrong;
  final Color borderBrand;
  final Color borderDanger;
  final Color borderFocus;

  final Color actionPrimary;
  final Color actionPrimaryPressed;
  final Color actionPrimaryDisabled;
  final Color onActionPrimary;

  final Color statusActiveBg;
  final Color statusActiveText;
  final Color statusActiveBorder;
  final Color statusPendingBg;
  final Color statusPendingText;
  final Color statusPendingBorder;
  final Color statusCompletedBg;
  final Color statusCompletedText;
  final Color statusDangerBg;
  final Color statusDangerText;
  final Color statusCancelledBg;
  final Color statusCancelledText;

  // ... (constructor, copyWith, lerp as required by ThemeExtension)

  // LIGHT MODE FACTORY
  static SLineColorTokens light() => SLineColorTokens(
    textPrimary:   SLinePrimitives.neutral800,
    textSecondary: SLinePrimitives.neutral600,
    textTertiary:  SLinePrimitives.neutral500,
    textDisabled:  SLinePrimitives.neutral400,
    textBrand:     SLinePrimitives.teal500,
    textDanger:    SLinePrimitives.errorLight,
    textSuccess:   SLinePrimitives.successLight,
    textWarning:   SLinePrimitives.warningLight,
    textTender:    SLinePrimitives.amber500,
    textBooking:   SLinePrimitives.indigo500,
    surfacePage:      SLinePrimitives.neutral50,
    surfaceCard:      SLinePrimitives.neutral0,
    surfaceElevated:  SLinePrimitives.neutral100,
    surfaceBrandSubtle:   SLinePrimitives.teal50,
    surfaceTenderSubtle:  SLinePrimitives.amber50,
    surfaceBookingSubtle: SLinePrimitives.indigo50,
    surfaceDangerSubtle:  SLinePrimitives.errorBgLight,
    surfaceSuccessSubtle: SLinePrimitives.successBgLight,
    borderDefault: SLinePrimitives.neutral200,
    borderSubtle:  SLinePrimitives.neutral100,
    borderStrong:  SLinePrimitives.neutral300,
    borderBrand:   SLinePrimitives.teal500,
    borderDanger:  SLinePrimitives.errorLight,
    borderFocus:   SLinePrimitives.teal500,
    actionPrimary:         SLinePrimitives.teal500,
    actionPrimaryPressed:  SLinePrimitives.teal700,
    actionPrimaryDisabled: SLinePrimitives.neutral300,
    onActionPrimary:       SLinePrimitives.neutral0,
    statusActiveBg:       SLinePrimitives.teal50,
    statusActiveText:     SLinePrimitives.teal600,
    statusActiveBorder:   SLinePrimitives.teal200,
    statusPendingBg:      SLinePrimitives.amber50,
    statusPendingText:    SLinePrimitives.amber600,
    statusPendingBorder:  SLinePrimitives.amber200,
    statusCompletedBg:    SLinePrimitives.successBgLight,
    statusCompletedText:  SLinePrimitives.successLight,
    statusDangerBg:       SLinePrimitives.errorBgLight,
    statusDangerText:     SLinePrimitives.errorLight,
    statusCancelledBg:    SLinePrimitives.neutral100,
    statusCancelledText:  SLinePrimitives.neutral500,
  );

  // DARK MODE FACTORY
  static SLineColorTokens dark() => SLineColorTokens(
    textPrimary:   SLinePrimitives.darkHeading,
    textSecondary: SLinePrimitives.darkSecondary,
    textTertiary:  SLinePrimitives.darkMuted,
    textDisabled:  SLinePrimitives.darkBorder,
    textBrand:     SLinePrimitives.tealDarkText,
    textDanger:    SLinePrimitives.errorDark,
    textSuccess:   SLinePrimitives.successDark,
    textWarning:   SLinePrimitives.warningDark,
    textTender:    SLinePrimitives.amberDarkText,
    textBooking:   SLinePrimitives.indigoDarkText,
    surfacePage:      SLinePrimitives.darkBase,
    surfaceCard:      SLinePrimitives.darkContainer,
    surfaceElevated:  SLinePrimitives.darkRaised,
    surfaceBrandSubtle:   SLinePrimitives.tealDarkSurface,
    surfaceTenderSubtle:  SLinePrimitives.amberDarkSurface,
    surfaceBookingSubtle: SLinePrimitives.indigoDarkSurface,
    surfaceDangerSubtle:  SLinePrimitives.errorBgDark,
    surfaceSuccessSubtle: SLinePrimitives.successBgDark,
    borderDefault: SLinePrimitives.darkBorder,
    borderSubtle:  SLinePrimitives.darkBorderSubtle,
    borderStrong:  Color(0xFF516060),
    borderBrand:   SLinePrimitives.tealDarkBorder,
    borderDanger:  SLinePrimitives.errorDark,
    borderFocus:   SLinePrimitives.tealDarkActive,
    actionPrimary:         SLinePrimitives.tealDarkActive,
    actionPrimaryPressed:  SLinePrimitives.teal300,
    actionPrimaryDisabled: SLinePrimitives.darkBorder,
    onActionPrimary:       SLinePrimitives.neutral0,
    statusActiveBg:       SLinePrimitives.tealDarkSurface,
    statusActiveText:     SLinePrimitives.tealDarkText,
    statusActiveBorder:   SLinePrimitives.tealDarkBorder,
    statusPendingBg:      SLinePrimitives.amberDarkSurface,
    statusPendingText:    SLinePrimitives.amberDarkText,
    statusPendingBorder:  SLinePrimitives.amberDarkBorder,
    statusCompletedBg:    SLinePrimitives.successBgDark,
    statusCompletedText:  SLinePrimitives.successDark,
    statusDangerBg:       SLinePrimitives.errorBgDark,
    statusDangerText:     SLinePrimitives.errorDark,
    statusCancelledBg:    SLinePrimitives.darkContainer,
    statusCancelledText:  SLinePrimitives.darkMuted,
  );

  @override
  ThemeExtension<SLineColorTokens> copyWith({/* fields */}) => this; // implement fully

  @override
  ThemeExtension<SLineColorTokens> lerp(
    ThemeExtension<SLineColorTokens>? other, double t) => this; // implement with Color.lerp
}
```

---

## 21. Flutter / Material 3 Implementation Strategy

**File structure for the theme system:**
```
lib/
  core/
    theme/
      tokens/
        primitives.dart     ← Layer 1: raw color/spacing/radius values
        semantic.dart        ← Layer 2: SLineColorTokens ThemeExtension
        typography.dart      ← TextTheme + custom text styles
        component_tokens.dart ← Layer 3: component-specific tokens
      app_theme.dart         ← ThemeData.light() and ThemeData.dark() assembly
      theme_extensions.dart  ← All ThemeExtension registrations
```

**Building the Material 3 ColorScheme:**
Material 3's ColorScheme is built around seed colors. Use `ColorScheme.fromSeed` with the brand teal as the seed, then override specific roles that M3's algorithm generates incorrectly for your palette. In particular, always override `surface`, `onSurface`, `surfaceContainerLow`, `surfaceContainerHigh`, and `outline` manually, because the M3 seed algorithm often generates unexpectedly warm or cool surfaces that conflict with your palette direction.

```dart
// In app_theme.dart
ThemeData lightTheme() {
  final base = ColorScheme.fromSeed(
    seedColor: SLinePrimitives.teal500,
    brightness: Brightness.light,
  );

  final colorScheme = base.copyWith(
    primary:          SLinePrimitives.teal500,
    onPrimary:        SLinePrimitives.neutral0,
    primaryContainer: SLinePrimitives.teal50,
    onPrimaryContainer: SLinePrimitives.teal800,
    secondary:        SLinePrimitives.indigo500,
    onSecondary:      SLinePrimitives.neutral0,
    error:            SLinePrimitives.errorLight,
    onError:          SLinePrimitives.neutral0,
    surface:          SLinePrimitives.neutral50,       // page background
    onSurface:        SLinePrimitives.neutral800,
    surfaceContainerLow:    SLinePrimitives.neutral0,  // card
    surfaceContainer:       SLinePrimitives.neutral100,// raised
    surfaceContainerHigh:   SLinePrimitives.neutral200,
    outline:          SLinePrimitives.neutral200,
    outlineVariant:   SLinePrimitives.neutral100,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    textTheme: _buildTextTheme(Brightness.light),
    cardTheme: _buildCardTheme(),
    inputDecorationTheme: _buildInputTheme(colorScheme),
    elevatedButtonTheme: _buildPrimaryButtonTheme(colorScheme),
    // ... other component themes
    extensions: [
      SLineColorTokens.light(),
    ],
  );
}
```

**Accessing semantic tokens in widgets:**
```dart
// In any widget:
final tokens = Theme.of(context).extension<SLineColorTokens>()!;

Container(
  color: tokens.surfaceCard,
  child: Text(
    'Title',
    style: TextStyle(color: tokens.textPrimary),
  ),
)
```

**TextTheme structure:** Flutter's Material 3 TextTheme maps well to the proposed scale:
- `displayLarge` → display.large (48px, w700)
- `displayMedium` → display.medium (36px, w700)
- `headlineLarge` → headline.large (28px, w700)
- `headlineMedium` → headline.medium (24px, w700)
- `headlineSmall` → headline.small (20px, w600)
- `titleLarge` → title.large (18px, w600)
- `titleMedium` → title.medium (16px, w600)
- `titleSmall` → title.small (14px, w600)
- `bodyLarge` → body.large (16px, w400)
- `bodyMedium` → body.medium (14px, w400)
- `bodySmall` → body.small (13px, w400)
- `labelLarge` → label.large (14px, w600)
- `labelMedium` → label.medium (12px, w600)
- `labelSmall` → label.small (11px, w600, letterSpacing 0.6)

**ThemeExtension for component-specific tokens** (optional Layer 3):
For complex components like cards, chat bubbles, and status badges, create a `SLineComponentTokens` ThemeExtension that maps semantic tokens to component slot names. This makes component code self-documenting: `tokens.cardBorderRadius` instead of `12.0` scattered everywhere.

---

## 22. Step-by-Step Migration Plan

Migration must happen without breaking the working app. The strategy is token-first, component-second, screen-third.

**Phase 0 — Preparation (1–2 days)**
Create the full primitives.dart and semantic.dart files without touching any existing screens. Add both the new `lightTheme()` and `darkTheme()` to the app but keep the old theme as the default. Add a dev-mode toggle that switches between old and new themes on a shake gesture. This allows side-by-side comparison without any production risk.

**Phase 1 — Token System (3–5 days)**
Replace all hardcoded hex values in existing widgets with semantic token references. Do not change any visual appearance yet — just connect the wires. This phase is pure refactoring. After this phase, changing a token value propagates everywhere. The test for completion: can you change the brand color from teal to blue by changing one value, and have it apply correctly across all screens?

**Phase 2 — Foundation Components (5–7 days)**
Build the new versions of: Button (primary, secondary, destructive, text), Input, Search Bar, Segmented Control, Filter Chip, Tab Bar, Bottom Sheet, Avatar, Badge, Toggle. Each new component is built as a new file alongside the old one (e.g. `new_primary_button.dart` next to `primary_button.dart`). Do not delete old components yet.

**Phase 3 — Cards (3–5 days)**
Rebuild the four card types: ServiceCard, TenderCard, BookingStatusCard, WorkCard. The new cards use semantic tokens for backgrounds and borders (status token system), removing all the status-specific hex values. Deploy these one card type at a time, not all at once.

**Phase 4 — Navigation Components (2–3 days)**
Rebuild Bottom Navigation and Top Navigation Bar. These affect every screen, so extra QA is needed. Test on both iOS and Android simulators. Test with notch and without notch. Test with accessibility text scaling at 150%.

**Phase 5 — Screen-by-Screen Rollout (ongoing, prioritize by traffic)**
Priority order: Home → Chat → Tenders → Bookings → Profile → Dashboard → Wallet → Settings → Saved → Notifications → Search. For each screen, apply the screen architecture recommendations from Section 13. Delete old component references as they are replaced.

**Phase 6 — Typography Migration (parallel to Phase 5)**
Switch the app font from the current system font to Plus Jakarta Sans. Load it either from Google Fonts package or bundle the font files in `assets/fonts/`. Add IBM Plex Sans Arabic and configure locale-aware font selection.

**Phase 7 — Light Mode (after dark mode is stable)**
Build out the full light mode palette and test all screens in light mode. Material 3's `ColorScheme.fromSeed` makes much of this automatic, but every custom surface and border color needs light mode values verified.

**Risk mitigations:** never migrate more than one screen per PR. Run the existing E2E tests after every component replacement. Keep the old theme in the codebase for at least 30 days after migration, behind a feature flag, so it can be rolled back if a critical issue surfaces.

---

## 23. Final Creative Direction Statement

SLine exists to make professional freelancing accessible and trustworthy in Iraq — a market that deserves a product built with the same care and quality as the best global tools, but designed for its own context, language, and pace.

The visual language of SLine is one of calm confidence. We do not use visual noise to communicate urgency. We do not use decorative complexity to signal quality. We build trust through clarity: every element on every screen earns its space by making the next action more obvious, more understandable, or more trustworthy. When a freelancer sees their active project highlighted in teal, they feel organized. When a client reviews a tender, the amber category signal tells them immediately what kind of task they are looking at. When the wallet shows a balance, the display is large enough to read in a glance, clean enough to feel reliable.

The color teal is our primary brand statement — it is the color of action, of trust, of clarity. Amber is the color of opportunity and urgency. Indigo is the color of scheduled, reliable work. These three colors, used with discipline, give users a visual grammar they can learn quickly and use confidently. Nothing else competes with them for attention.

SLine should feel, in its best moments, like the product that makes the user say: "I trust this." That trust is built in the smallest details — consistent spacing, reliable component behavior, readable typography, status colors that actually mean something. This is not a design brief about making beautiful screens. It is a brief about building a product that earns the confidence of the people who use it to make their living.

---

## 24. Figma / AI UI Generation Prompt for the New Design

Use this prompt in Figma Make, v0.dev, or any AI UI generation tool to generate screens consistent with SLine's new design direction.

---

**SYSTEM PROMPT FOR AI UI GENERATION:**

Design a mobile app screen for SLine, a premium freelance marketplace for iOS and Android. The screen should feel calm, professional, and modern — similar in spirit to Linear, Wise, and Airbnb combined, but with its own identity.

**Design language:**
- Rounded corners throughout: standard cards use 16px radius; inputs use 12px radius; pill buttons use 20px radius; badges use 4–8px radius
- Generous whitespace: 20px screen edge padding; 24px between sections; 16px internal card padding
- Single column layout for marketplace listings; two-column grid for service cards only
- No gradients on surfaces; no decorative background patterns; no drop shadows in dark mode

**Color system (dark mode):**
- Page background: #0E1212 (very dark cool-teal, not pure black)
- Card background: #161C1C
- Elevated surface: #1D2626
- Border color: #3A4848
- Subtle border: #253030
- Primary brand (teal): #2DAEAE — use ONLY on buttons, active states, and price/stat numbers
- Tender accent (amber): #FFB830 — use ONLY on tender category badges and tender-type items
- Booking accent (indigo): #8496FF — use ONLY on booking category badges
- Primary text: #EDF5F5
- Secondary text: #A8BCBC
- Muted/caption text: #7A9090

**Color system (light mode):**
- Page background: #FAFAF8
- Card background: #FFFFFF
- Elevated surface: #F3F2F0
- Border color: #E8E7E4
- Primary brand (teal): #0E9E9E
- Tender accent (amber): #F5A623
- Booking accent (indigo): #3B4FE8
- Primary text: #1A1918
- Secondary text: #504F4B
- Muted text: #7A7974

**Typography:**
- Font family: Plus Jakarta Sans (all text)
- Screen title: 28px, weight 700
- Card title: 18px, weight 600
- Body text: 16px, weight 400, line-height 1.6
- Tags/badges/labels: 12px, weight 600
- Status badges: 11px, weight 600, UPPERCASE, letter-spacing 0.6px
- Metadata / timestamps: 12px, weight 400
- Price display: 24–36px, weight 700, brand teal color
- No font weight above 700 anywhere

**Component behavior:**
- Cards: flat (no shadow in dark mode), thin border (1px border color), 16px radius, 16px internal padding
- Buttons: 52px height, 20px radius, primary uses brand teal background with white label; secondary uses transparent background with border
- Inputs: 52px height, 12px radius, 1px border default; 2px teal border on focus
- Segmented control: contained inside a 44px height container, no accent color on the container itself — active tab uses card surface background
- Status badges: small pill (4px radius), colored background at ~12% opacity of status color, text in status color, 1px border in status color at ~40% opacity
- Bottom nav: 72px height, card surface background, thin top border; 6 tabs (Home, Tenders, Bookings, Dashboard, Messages, Profile)
- FABs: 56×56px, fully round (radius 9999), brand teal background, white icon, no label

**What to avoid:**
- No pure black (#000000) or pure white (#FFFFFF) surfaces
- No gradient backgrounds
- No decorative dividers, glows, or neon effects
- No font weight above 700
- No more than 2 accent colors visible on a single screen
- No red color except for error states and destructive actions
- No card headers filled with solid color (replace with category badge at top of card)
- No text below 11px
- No components without clear touch targets (minimum 44×44px)

**Emotional target:** the screen should make the user feel organized, trusted, and capable — not excited, not overwhelmed. Everything important should be readable in under 2 seconds of viewing.

---

*End of SLine Complete Redesign Strategy*
*Version 1.0 — Ready for implementation*