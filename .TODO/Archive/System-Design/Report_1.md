
SLine Complete Redesign Research Report
Executive verdict and diagnosis
1. Redesign Executive Verdict
SLine should be rebuilt around a trust-first, calm, content-led design system that uses Material 3 as the behavior foundation but not the default “Material look.” The new direction should prioritize: (a) high readability, (b) predictable hierarchy and spacing, (c) restraint in color, and (d) a semantic token architecture that cleanly maps to Flutter theming and scales to Arabic RTL. This is not “polish”—your current system is structurally noisy, token-light, and overly dependent on ad-hoc styling patterns that will not scale across marketplace complexity like escrow, booking states, and chat. 

To be implementation-realistic in Flutter, the redesign should standardize around ThemeData + ColorScheme + TextTheme as the single source of truth, because Flutter’s Material components increasingly derive appearance from ColorScheme and TextTheme, and Material 3 is the default styling baseline in modern Flutter. 

2. Why the Current Direction Should Be Replaced
Your legacy UI direction looks like it was built by assembling “UI patterns” rather than a coherent system: it relies heavily on near-black surfaces, frequent borders, and a single high-chroma teal accent, producing a visually dense and game-like feel that can undermine marketplace trust—especially in the escrow/wallet domain where calm clarity is a feature. 

More critically, the legacy system shows too many inconsistent radii, heights, and spacing micro-scales (e.g., multiple pill, card, input, sheet radii ranges; lots of bespoke component heights), which is exactly how a marketplace UI becomes inconsistent over time and harder to maintain. 

A redesign is justified because Flutter Material 3 theming now expects you to commit to a coherent ColorScheme and TextTheme approach—trying to keep a largely custom “legacy dark UI” while also benefiting from M3 defaults is the worst of both worlds. 

New philosophy and visual direction
3. New Design Philosophy for SLine
The redesign should follow a single principle: “Reduce anxiety, increase confidence.” In a freelance marketplace, users are constantly evaluating risk (quality, scams, payment uncertainty, time). Your UI must behave like a calm contract: clear, legible, predictable, not flashy.

Practical philosophy pillars:

Content-first hierarchy: jobs, people, delivery timelines, payment terms, and reputation signals come before decoration.
Restraint as premium: premium ≠ trendy gradients; premium = spacing discipline, typography discipline, and conservative color usage.
State clarity over aesthetics: booking states, escrow status, and message states must be unambiguous.
Semantic tokens over “pretty constants”: every color/spacing value must have a meaning and a defined usage boundary. This aligns with modern token practices aimed at cross-tool interoperability. 
4. Best Overall Visual Direction
“Quiet Luxury Marketplace”: porcelain-like surfaces in light mode, ink-like surfaces in dark mode, one signature accent that feels trustworthy and calm (a refined jade/teal is appropriate), and typography tuned for mobile scanning.

Why this is the best fit for your constraints:

Material 3 provides accessible structure and component behavior while still allowing brand differentiation through your ColorScheme and typography. 
A restrained accent approach avoids “Fiverr clone” energy (loud, high-chroma, salesy) without drifting into enterprise heaviness.
It scales cleanly to Arabic RTL because the visual system relies on spacing rhythm and typographic hierarchy rather than directional ornamentation. Flutter’s localization and Directionality model supports correct RTL mirroring when you build with directional primitives. 
5. Recommended Brand Feeling
Target emotional profile: Calm, assured, discreetly premium, human, precise.
Avoid: “hustle marketplace,” “neon fintech,” “enterprise dashboard,” “social feed.”

Concrete brand-feel decisions:

Surfaces do the work, not borders. Use containers to create structure; borders only where interaction boundaries must be explicit. (This also supports non-text contrast requirements for interactive boundaries.) 
Accent is earned. Use brand accent primarily for: primary actions, selected states, confirmation moments, and “SLine signature” micro-highlights—not everywhere.
Trust cues are designed, not shouted. Verification, escrow protection, ratings: present them as calm signals, not bright badges.
Color and typography system
6. Full Color Strategy
A marketplace with escrow and bookings needs a two-layer color system:

Layer A: Brand + foundation (stable)

A neutral surface system that feels premium and readable.
One signature accent (primary).
A supporting accent (tertiary) used rarely.
Layer B: Semantic state system (functional)

Success, warning, error, info.
Status colors for booking lifecycle and escrow lifecycle.
Material 3’s color approach strongly supports role-based colors via ColorScheme, and Flutter recommends theming through ColorScheme because Material widgets increasingly derive from it. 

Also, because marketplace UI is interaction-heavy, you must treat contrast as a requirement, not preference: WCAG guidance for text contrast (4.5:1 normal text, 3:1 large text) and non-text contrast for UI component boundaries (3:1) should be your baseline acceptance criteria. 

7. Light Mode Palette
Direction: Porcelain surfaces + ink text + refined jade accent.

Recommended brand seed (for generation and harmonization):

brand.seed: #0F6E6D (deep jade-teal)
Recommended key functional colors (explicit, not generated):

ref.neutral.0 (pure white): #FFFFFF
ref.neutral.10 (porcelain background): #FBFBFC
ref.neutral.20 (surface low): #F6F7F9
ref.neutral.30 (surface): #F0F2F5
ref.ink.100 (primary text): #0F1115
ref.ink.70 (secondary text): #3F454D
ref.ink.55 (muted text): #5C646E
Interactive boundary requirement (non-text contrast):

ref.stroke.interactive: #7F8892 (chosen to hit ≥3:1 against porcelain backgrounds in typical UI use) aligned with non-text contrast guidance. 
Status colors (calm, not neon):

ref.success: #157A4C
ref.warning: #A15C00
ref.error: #B42318
ref.info: #2457A6
8. Dark Mode Palette
Direction: Ink surfaces + light text + softened jade accent.

Key colors:

ref.neutral.95 (dark background): #0E0F11
ref.neutral.90 (surface): #15181B
ref.neutral.85 (surface high): #1B1F23
ref.neutral.80 (surface highest): #23282D
ref.paper.100 (primary text): #F1F2F4
ref.paper.80 (secondary text): #C2C8D0
ref.stroke.interactive: #5C646E (meets 3:1+ boundary contrast on dark surfaces)
Brand accent mapping (dark):

brand.primary: #5BD1CE
brand.onPrimary: #042423
brand.primaryContainer: #0A3F3D
brand.onPrimaryContainer: #B9F1EF
Why these choices are rational in a Material 3 world:
Flutter’s ColorScheme generation and variants are built to create harmonious role-based tones from a seed color, with variants designed to avoid overly colorful output in many cases. 

For production: you should generate and export exact role maps using the official Material Theme Builder workflow. 

9. Semantic Token System
This redesign must not repeat the “constants.ts = theme” trap. Your tokens should follow a layered architecture aligned with modern token specs and proven design-system practice:

Reference tokens: raw values (palette, scale units).
System/semantic tokens: meaning-based roles (surface, text, border, action).
Component tokens: per-component decisions (button height, chip radius, field padding).
This matches the direction of cross-tool token interoperability standards. 

Suggested semantic structure (example names):

color.bg.canvas (app background)
color.surface.default / low / high
color.text.primary / secondary / muted / inverse
color.stroke.interactive / subtle
color.action.primary / primaryHover / primaryPressed
color.state.success / warning / error / info
Critical rule:

stroke.subtle can be “pretty.”
stroke.interactive must satisfy non-text contrast requirements for boundaries and state indicators where needed. 
10. Typography System
A premium marketplace lives or dies by typography. Your current system leans into many heavy weights and small sizes, which often reads “over-designed” and reduces scanning comfort in dense lists. 

Target typography characteristics:

High x-height sans for long reading.
Moderate weight usage (avoid 800–900 except rare brand moments).
Tabular numerals for wallet and pricing consistency.
Arabic readiness without reflow surprises (line-height discipline).
Practical font recommendation (bilingual stability):

Primary family: Noto-family strategy (Latin + Arabic pairing) because Noto was created to reduce mismatched font aesthetics across scripts and languages—exactly your RTL/LTR future need. 
Implement as:
Latin: “Noto Sans”
Arabic: “Noto Sans Arabic”
Flutter supports custom fonts via pubspec and applying them at theme level. 
Type scale (Material 3 compatible, tuned for mobile):

Display: reserved; rarely used.
Headline: screen titles and section headers.
Title: card titles.
Body: the product.
Label: buttons, chips, metadata.
Use Material 3’s role-based TextTheme approach; it is designed as a system, not an ad-hoc set of sizes. 

Recommended weight policy:

Default: 400 (body), 500–600 (titles), 600 (primary buttons), 700 only for rare “hero metric” moments.
Do not use 800/900 as routine emphasis.
Layout metrics, components, motion and accessibility
11. Spacing / Radius / Elevation System
Your legacy system shows many radii and spacing values that vary by feature area rather than system intent. 

Replace with a strict, small set:

Spacing scale (dp):
0, 2, 4, 8, 12, 16, 20, 24, 32, 40, 48, 64

Rules:

Screen horizontal padding: 16 (phones), 20 (large phones), 24 (tablets)
Vertical rhythm: content sections separated by 24–32
List items: 12–16 vertical, 12 horizontal
Radius scale:

radius.xs = 8 (chips, small controls)
radius.sm = 12 (fields, small cards)
radius.md = 16 (cards, sheets)
radius.lg = 24 (large sheets, hero containers)
radius.full = 999
Elevation:

Use tonal elevation and subtle, consistent shadows. Flutter’s Material stack uses surface tint blending in Material 3 and exposes elevation behavior in its framework utilities. 
Standard levels: 0, 1, 2, 3, 6, 12
Only modal surfaces (dialogs/sheets) should exceed 6.
12. Core Component Redesign Recommendations
This is where SLine stops feeling like a generic marketplace.

Buttons:

Prefer FilledButton for the primary action, FilledButton.tonal for secondary, TextButton for tertiary actions. Material 3’s component ecosystem is explicitly designed around ColorScheme roles. 
Height: 48dp minimum, 52dp for primary CTA on key screens (post task, pay, accept).
Corner radius: radius.md (16) so it feels premium and soft—not pill-everywhere.
Inputs:

Use one field style globally (do not mix outline + fill patterns per screen).
Default: filled surface container + explicit focus ring.
“Focus ring” must be visible and meet non-text contrast as a state indicator. 
Cards:

Replace border-heavy cards with surface containers + spacing.
Use borders only for interactive boundaries or when the container color difference is insufficient.
Chips / pills:

Use chips for filtering and status, not for decoration.
One chip height (32 or 36), one padding rule.
Navigation:

Use Material 3 NavigationBar: icons + short labels.
Do not use “marketplace multi-row sticky headers + endless chips” patterns. Keep discovery calm: a search bar, a few curated entry points, then content.
Chat:

Message bubbles should be neutral-first; use accent for “sent” only and keep it toned.
Treat attachments, payments, and offer cards inside chat as “mini sheets” with consistent container styling.
Wallet / escrow:

Use a ledger layout with tabular numerals.
Show escrow state as calm, step-based UI (e.g., Funded → In progress → Released) rather than bright badges.
13. Screen-by-Screen Redesign Strategy
Replace each area’s layout logic with a shared “screen blueprint.”

Auth:

One column, one story: brand promise + secure sign-in.
Minimal fields, unmistakable primary button.
Remove decorative noise.
Onboarding:

Progressive disclosure: collect only what is needed to personalize discovery and trust (role, location, skill categories).
Use a step indicator only if multi-step is unavoidable.
Home / discovery:

Top: search + one “primary filter” affordance.
Middle: curated bands (recommended tasks, near you, urgent).
Bottom: the feed.
Avoid heavy category grids.
Task posting:

A stepper that behaves like a contract: scope, budget, timing, requirements, escrow preference.
Sticky bottom action button.
Inline validation, not surprise dialogs.
Tenders / bidding:

Separate “offers list” from “offer detail.”
Offer cards must show: price, timeline, key proof, risk indicators.
One clear “accept offer” action.
Bookings:

A single booking detail page that becomes the source of truth: timeline, milestones, chat entry, escrow status, dispute entry.
Chat:

Thread is primary; actions are contextual and appear as bottom sheets (send offer, request files, propose milestone).
Don’t overload the chat header.
Wallet / escrow:

Default view: balance + “protected funds” + recent activity.
Escrow detail: step-based status, transaction detail, and receipts.
Saved items:

Simple list. Provide grouping via filters (saved tasks / saved providers).
Notifications:

Group by type (bookings, chat, payments).
Provide “mark as read” and batch behaviors.
Profile / portfolio:

Profile is a trust document: verification, work, ratings, response time, policies.
Portfolio entries should be scannable cards with consistent media masks.
Settings:

Use standard M3 list patterns; no custom visual experiments.
Search / filtering:

Filters: modal bottom sheet with clear sections and reset/apply.
Results: stable card layout with strong typography hierarchy.
14. Motion System
Motion must be informative, not decorative. This is especially important for trust-heavy flows like payments and escrow.

Principles:

Use motion to clarify transitions (list → detail, sheet open/close) and confirmation states.
Avoid long animations; users see them constantly. Material guidance emphasizes responsive, short transitions. 
Make motion optional and respect platform requests to reduce/disable animations. Flutter exposes this via MediaQueryData.disableAnimations and AccessibilityFeatures flags. 
Tokenized motion set:

motion.duration.xs = 80ms (icon toggles)
motion.duration.sm = 140ms (button press, state)
motion.duration.md = 220ms (sheet open, card expand)
motion.duration.lg = 320ms (page transition)
Curves: standard for most; emphasized only for major transitions.
Navigation transitions:

Use container/element continuity where meaningful (task card → task detail).
Otherwise, favor simple fades.
15. Accessibility and Usability Standards
Your new system should meet these minimums:

Contrast:

Text: 4.5:1 minimum for normal text, 3:1 for large text. 
UI component boundaries/state indicators: 3:1 minimum. 
Touch targets:

Aim for 48x48dp minimum for interactive elements; Flutter documents this in MaterialTapTargetSize and its accessibility checklist. 
Platform alignment: iOS commonly expects 44x44pt and meaningful spacing between controls. 
Typography accessibility:

Support large text scaling; don’t hard-lock critical layouts. Flutter’s accessibility guidance calls out scale-factor usability and contrast. 
Reduce motion:

Honor disableAnimations / reduceMotion signals. 
RTL readiness:

Use Directionality-aware primitives (EdgeInsetsDirectional, AlignmentDirectional) and Flutter localization delegates so the UI mirrors correctly. 
16. What Must Be Deleted from the Old System
Delete these categories completely, not “refine” them:

The border-everywhere look: it increases noise and harms premium calm. Use containers + spacing instead. 
Inconsistent radii and component heights: replace with a strict scale. Your legacy system lists many per-component height choices and radius ranges—this is exactly what causes long-term UI drift. 
Single-accent-overuse (teal everywhere): keep a signature accent, but dramatically reduce where it appears. 
Any ad-hoc token naming that isn’t semantic or mapped to behavior/component needs.
17. What Is Safe to Preserve
Only preserve what is objectively strong:

The idea of a calm teal/jade signature is defensible for trust and distinctiveness—but change its usage discipline and tonal mapping. 
A dark mode-first mentality can be preserved, but only after rebuilding it with proper tonal surface hierarchy and contrast rules instead of “many near-blacks + borders.” 
Design directions, tokens, and implementation strategy
18. Three New Redesign Directions

Most balanced: Porcelain + Ink + Jade (Recommended)

Calm, premium, widely appealing, low risk.
Accent: deep jade-teal.
Works best with Material 3 tonal system and code export workflows. 
Most premium: Ivory + Ink + Subtle Brass

Warmer surfaces, more editorial typographic voice.
Accent: muted brass for highlights; jade limited to trust states.
Risk: brass can look “fintechy” if overused; requires strong restraint.
Most memorable: Mist + Ink + Blue-Teal “Line Motif”

Uses a distinctive “line” motif as a structural brand element (thin vertical rule, section dividers, progress lines).
Accent: slightly cooler teal-blue.
Risk: motif must remain structural, not decorative.
19. Final Recommended Direction
Choose Most balanced: Porcelain + Ink + Jade because it best satisfies your constraints: premium, calm, modern, readable, and distinct without being trend-driven. It also scales best to RTL and to complex product states like escrow and bookings where clarity beats style. 

20. Full Design Token Proposal
Token format: align your storage with the modern token ecosystem so you can generate Dart, keep Figma parity, and maintain light/dark themes cleanly. The W3C Design Tokens Community Group formats and resolver concepts are the current interoperability baseline. 

Proposed token organization:

ref/ (reference palettes & scales)
sys/ (semantic roles, light/dark)
comp/ (component-level overrides)
motion/ (durations/easings)
typography/ (role styles)
Example token skeleton (DTCG-style concept, simplified for clarity):

json
Copy
{
  "ref": {
    "color": {
      "brandSeed": { "$type": "color", "$value": "#0F6E6D" },
      "neutral": {
        "0": { "$type": "color", "$value": "#FFFFFF" },
        "10": { "$type": "color", "$value": "#FBFBFC" },
        "95": { "$type": "color", "$value": "#0E0F11" }
      },
      "strokeInteractiveLight": { "$type": "color", "$value": "#7F8892" },
      "strokeInteractiveDark": { "$type": "color", "$value": "#5C646E" }
    },
    "space": {
      "0": { "$type": "dimension", "$value": 0 },
      "1": { "$type": "dimension", "$value": 4 },
      "2": { "$type": "dimension", "$value": 8 },
      "3": { "$type": "dimension", "$value": 12 },
      "4": { "$type": "dimension", "$value": 16 }
    },
    "radius": {
      "xs": { "$type": "dimension", "$value": 8 },
      "sm": { "$type": "dimension", "$value": 12 },
      "md": { "$type": "dimension", "$value": 16 },
      "lg": { "$type": "dimension", "$value": 24 },
      "full": { "$type": "dimension", "$value": 999 }
    }
  },
  "sys": {
    "light": {
      "color": {
        "bgCanvas": { "$type": "color", "$value": "{ref.color.neutral.10}" },
        "textPrimary": { "$type": "color", "$value": "#0F1115" }
      }
    },
    "dark": {
      "color": {
        "bgCanvas": { "$type": "color", "$value": "{ref.color.neutral.95}" },
        "textPrimary": { "$type": "color", "$value": "#F1F2F4" }
      }
    }
  }
}

21. Flutter / Material 3 Implementation Strategy
Implementation must be unapologetically Material-3-native in code, while brand-distinct in values:

Core theming approach:

Build ColorScheme for light/dark with either:

ColorScheme.fromSeed using your brand seed and a restrained variant, then override key roles, or
fully explicit ColorScheme exported from Material Theme Builder.
Flutter documents fromSeed, its variants, and contrast behavior. 
Construct ThemeData using ThemeData.from(colorScheme: ..., textTheme: ...) because it’s the recommended theming path and keeps Material widgets consistent. 

Keep useMaterial3: true (default) and embrace it; don’t fight it with widget-level overrides everywhere. 

Dynamic color (optional, Android 12+):

If you want “native personalization,” use dynamic color as an optional layer with a fallback to your brand schemes. Material 3 supports dynamic color conceptual workflows, and Flutter has ecosystem support via the dynamic_color package. 
Surface tint / elevation behavior:

In Material 3, surfaces can be tinted based on elevation; Flutter exposes this behavior in ElevationOverlay utilities. This matters for your card/sheet colors and why “random dialog colors” appear if you ignore tint. 
RTL readiness:

Ensure your UI uses Directionality-aware layout primitives and localization delegates; Flutter’s internationalization docs explicitly call out RTL behavior when properly configured. 
Accessibility enforcement:

Set ThemeData.materialTapTargetSize = MaterialTapTargetSize.padded and don’t shrink-wrap interactive areas; Flutter documents padded as the 48x48 recommended size. 
Build component states so boundaries and focus indicators satisfy non-text contrast guidance. 
22. Step-by-Step Migration Plan
This plan assumes you are rebuilding “from zero” while shipping incrementally.

Step 1: Freeze legacy UI scope

No new components in the old style. Only bug fixes.
Step 2: Define the new token source of truth

Create the token repo/file structure and enforce semantic naming. Use DTCG-style structure even if you don’t fully adopt the JSON spec on day one. 
Step 3: Generate the new ColorScheme and export

Use Material Theme Builder (web + Figma plugin) to generate light/dark schemes from the chosen seed, then export Flutter-ready values. 
Decide whether to support dynamic color via dynamic_color with fallback. 
Step 4: Implement ThemeData + ThemeExtensions

ThemeData: ColorScheme + TextTheme + component themes. 
ThemeExtensions: spacing, radii, custom semantic colors not covered by ColorScheme.
Step 5: Build the new component library first
Implement wrappers so screens don’t invent UI:

Buttons (primary/secondary/tertiary)
Input field + validation + focus ring
Card container
List row
Chip
Sheet + dialog
Avatar + rating row
Status badge (semantic state colors only)
Step 6: Redesign screens in this order (risk-first)

Wallet/escrow
Booking + tender flows
Chat
Discovery + search
Profile/portfolio
Auth/onboarding
This order reduces trust and conversion risk earliest.
Step 7: Replace navigation and global patterns last
Once core screens are migrated, unify navigation bars, app bars, and global sheets.

Step 8: Accessibility validation gates

Contrast checks per screen type and component type. 
Touch target tests (48x48). 
VoiceOver/TalkBack pass. Flutter calls out explicit screen reader testing. 
23. Final Creative Direction Statement
SLine’s redesign is a quietly premium marketplace where every screen feels like a clear agreement: minimal distraction, controlled color, and typography that makes complex decisions feel simple. The interface communicates trust through restraint—structured surfaces, meaningful states, and consistent motion—so users can confidently post, bid, book, chat, and pay without visual noise.

This direction uses Material 3 as the behavioral substrate, but the brand expression is defined by your tokenized surfaces, disciplined hierarchy, and calm jade signature—not Material defaults.

24. Figma / AI UI Generation Prompt for the New Design
Prompt (copy/paste into Figma AI or an AI UI generator):

Create a mobile-first freelance marketplace app UI redesign called “SLine” with a calm, premium, minimal visual system (NOT like Fiverr or Upwork). Use Material 3 foundation, but make it brand-distinct through restrained color and typography.

Design language:

Quiet luxury, editorial clarity, high readability, low visual noise.
Light mode: porcelain backgrounds (#FBFBFC), ink text (#0F1115), signature jade accent (#0F6E6D).
Dark mode: ink backgrounds (#0E0F11), soft light text (#F1F2F4), softened jade accent (#5BD1CE).
Use two border styles: subtle separators can be light; interactive boundaries must be clearly visible with strong contrast (design for accessibility).
Typography:

Use Noto Sans for Latin and Noto Sans Arabic for Arabic readiness.
Strong hierarchy: clear page titles, scannable cards, calm metadata.
Layout rules:

4dp grid system; primary horizontal padding 16dp; section spacing 24–32dp.
Radius: 8/12/16/24 with consistent usage (chips/fields/cards/sheets).
Components: Filled primary button, tonal secondary button, clean fields with clear focus ring, soft cards using surface containers (not heavy borders).
Motion: subtle, fast, informative transitions; do not use flashy animations.
Screens to design: Auth, onboarding, home/discovery, task posting, tenders/bidding, bookings, chat, wallet/escrow, saved items, notifications, profile, portfolio, settings, search/filter sheet.

Make the UI feel trustworthy: escrow and booking states must be clear, calm, and unambiguous.