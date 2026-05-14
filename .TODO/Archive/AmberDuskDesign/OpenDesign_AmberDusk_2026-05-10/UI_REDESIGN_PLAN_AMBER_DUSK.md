# SLine UI Redesign — Amber Dusk (V2)
## Full Implementation Plan — Step by Step, Screen by Screen

**Source:** `Sline V2 Amber Dusk.html` (design handoff bundle, extracted to `/tmp/design_extracted/sline-v1/project/`)
**Target:** `lib/` (Flutter, MVVM, Provider)
**Branch:** `RedsignTheUi` (current)
**Scope:** View layer only — no Supabase/repo/VM changes unless noted as a gap.

---

## 1. Design Intent (from README + chat transcript)

- User mocked 6 variants; **chose V2 Amber Dusk** and archived the rest.
- **Theme direction:** Dark, warm, editorial. Rust-brown hero, amber highlights, cream CTAs, Fraunces serif for headings/numerals.
- **Localization:** Iraqi — IQD prices (e.g. `850,000`), Baghdad/Erbil/Basra, Arabic greeting (`صباح الخير`) in Home header.
- **Motion:** "Subtle for navigation, crisp for taps, playful for peak moments" — 150ms press-scale on cards, 500ms staggered FadeIn on feed items, spring pop on success states.
- **Navigation:** 5-tab bottom nav (Home · Tenders · Book · Chat · Me), floating pill with 14px side margin on bg-gradient fade. Matches Flutter `CustomBottomNavBar` shape (24px top radius → 28px pill in new design).
- **Principle (project CLAUDE.md):** Redesign happens via **Layer 1 (theme tokens) + Layer 2 (layout tokens)** — components never hardcode colors/sizes. Editing 6 token files cascades across every view.

---

## 2. Design Tokens — Exact Values

### 2.1 Color palette (Amber Dusk)
```
bg          #1A1612   phoneBackground / scaffold
bg2         #241F1A   cardBackground / surface
bg3         #2F2822   input fill / elevated card
bg4         #3A312A   hover / pressed

cream       #F2E8D5   CTA button fill, primary text on hero
creamSubtle #E6D7BE   secondary cream for gradients
text        #F2E8D5   body text
textDark    #1F1813   text on cream CTAs
muted       #8F8478   textSecondary, captions
mutedDark   #7A6F63   disabled / tertiary

primary     #D4906A   primary action, filter pill active, active nav
primaryDeep #A36A48   primary pressed / gradient deep

amber       #E6B87A   accents, clock icon, pending warnings
rust        #C9695C   urgent, heart fill, negative amount
forest      #7FA872   success, online badge, accepted status
star        #E8B856   rating star

hero        #3E2418   profile hero gradient mid
heroTop     #4A2D1F   profile hero gradient top
heroDeep    #2E1810   profile hero gradient bottom
heroText    #F5E8D0   text on hero
heroMuted   rgba(245,232,208,0.55)
heroChip    rgba(255,255,255,0.05)
heroChipBorder rgba(245,232,208,0.15)
heroDivider rgba(245,232,208,0.1)

border      rgba(242,232,213,0.06)   all card/chip outlines
```

### 2.2 Typography
- **Sans:** `DM Sans` (body, labels, buttons, captions) — already in `pubspec.yaml`/GoogleFonts
- **Serif:** `Fraunces` (hero numerals, screen titles, names, price displays) — needs adding to `pubspec.yaml`
- **Sizes used in design:** 9.5 · 10 · 11 · 11.5 · 12 · 12.5 · 13 · 13.5 · 14 · 14.5 · 15 · 16 · 18 · 20 · 21 · 22 · 23 · 26 · 28 · 30 · 34 · 38
- **Letter spacing:** labels `0.3–0.4` uppercase, display `−0.3 to −1.2`, body `0`
- **Tabular numerals:** `fontVariantNumeric: tabular-nums` wherever a price, balance, progress %, or stat appears

### 2.3 Spacing + radius
- Radius scale: `md=12, lg=16, xl=24, full=999`
- Padding scale: `4, 6, 8, 10, 11, 12, 14, 16, 18, 20, 22, 24, 30`
- Card padding: `14px 16px` (TaskCard) or `18px 20px 20px` (BookingCard)
- Screen horiz padding: **20px** (not 24px like current)

### 2.4 Motion
- Press scale: `0.985` (BookingCard), `0.99` (TaskCard), transition `150ms cubic-bezier(.2,.7,.3,1)`
- List FadeIn: `500ms` with `60ms` stagger, `8px` dy translate
- Modal slide-up: `320ms cubic-bezier(.2,.7,.3,1)` + `200ms` backdrop fade
- Success pop: `400ms` scale `0 → 1.15 → 1`
- Typing dots: 3 dots, `1.2s` loop, `150ms` stagger, `−4px` bounce
- Progress fill: `800ms cubic-bezier(.2,.7,.3,1)` on width

### 2.5 Shadows
- Card rest: `0 1px 0 rgba(255,255,255,0.06) inset, 0 −1px 0 rgba(0,0,0,0.2) inset, 0 12px 32px rgba(0,0,0,0.5), 0 4px 8px rgba(0,0,0,0.3)` (BookingCard)
- TaskCard rest: `0 1px 0 rgba(239,232,220,0.04) inset, 0 6px 20px rgba(0,0,0,0.3)`
- Pressed: `0 2px 10px rgba(0,0,0,0.4)`
- Cream button: `0 4px 14px rgba(0,0,0,0.35), 0 1px 0 rgba(255,255,255,0.4) inset`
- Primary button: `0 4px 14px ${primary}40, 0 1px 0 rgba(255,255,255,0.15) inset`
- Bottom nav: `0 −4px 24px rgba(0,0,0,0.3), 0 1px 0 rgba(255,255,255,0.03) inset`

### 2.6 Signature patterns
- **HeaderGlow:** two soft radial gradients at top of every main screen (primary@10% top-right, amber@8% mid-left), 240px tall, `overflow:hidden` container.
- **Avatar ring:** gradient border `linear-gradient(135deg, primary, amber)` wrapping 62–72px avatar with 3px padding — used on Profile self-view and BookingDetail hero.
- **Left accent stripe:** TaskCard has a `3px` left border, `rust` if urgent else `primary`.
- **Inset highlight line:** every elevated surface has a 1px white-@4–6% inset top border to mimic glass specular.
- **Pill filter tabs:** Active uses `primary` fill + `cream` label + shadow `0 2px 14px ${primary}30`; inactive is transparent with 1px `border` stroke.

---

## 3. Gap Analysis — Existing Flutter vs Design

| Concern | Current (lib/) | Design (Amber Dusk) | Action |
|---|---|---|---|
| Dark scaffold | teal-based (`#146068`), cool | warm rust/brown (`#1A1612`) | Rewrite `AppColors` + `AppColorScheme.dark` |
| Primary accent | teal | terracotta `#D4906A` | Token swap |
| Typography heading font | DM Sans only | Fraunces serif for display | Add Fraunces via `google_fonts` |
| Bottom nav | 6 tabs, 24px top radius, full-width | 5 tabs, 28px pill, 14px side margin, floating over bg gradient fade | Rewrite `CustomBottomNavBar` |
| Screen horiz padding | 24px standard | 20px | Adjust `AppLayout` |
| BookingCard visual | flat card, grey bg | dark hero gradient, 52px avatar, online badge, cream CTA, chip row | Rewrite `booking_card.dart` (or feed widget equivalents) |
| TaskCard visual | basic card | left-accent stripe, urgent chip, offer-avatars stack, deadline amber chip | Rewrite |
| Home greeting | "Welcome Back" | Arabic + English (`صباح الخير · Good morning`) + Omar | New widget |
| Price unit | `$45/hr` shown sometimes | always `IQD`, comma grouping | Update `format_price` + VM strings |
| Avatar illustration | `SignedAvatar` + initials placeholder | Hand-drawn SVG (Yara/Hassan/Zaynab/Omar/Layla/Karim) | Create Flutter SVG assets (6 files in `assets/avatars/`) |
| Dashboard subtabs | separate screens | pill scroll bar Overview · Bookings · Work · Wallet · Inbox | Consolidate |
| Chat detail | existing | needs `Offer` button in header + bottom composer bar + OfferComposer bottom sheet | Extend |
| OfferComposer | exists (`direct_offers` feature) | must match slide-up sheet + success pop | Restyle |

---

## 4. Execution Order (16 Phases)

> **Each phase has:** (A) files to touch · (B) evidence from design · (C) verification. All work is on branch `RedsignTheUi`.

### PHASE 0 — Discovery + scaffolding (NO visual changes)
**Goal:** confirm every file the plan will touch; zero regressions.

- [ ] Run full codebase scan: `grep -rln "AppColors.teal\|AppColors.lightTeal\|AppColors.gold\|colorScheme.primary" lib/` — record count. Expect 200+ references; token rewrite will cascade.
- [ ] Record `flutter analyze` clean baseline.
- [ ] Confirm `lib/core/theme/theme_dashboard.dart` exists (the dev-only theme explorer page) and plan to regenerate it after tokens change.
- [ ] Verify current home feed card widgets (`lib/features/home/view/widgets/`) — list actual filenames before editing.
- [ ] Add `Fraunces` to `pubspec.yaml` GoogleFonts OR add `.ttf` to `assets/fonts/`.

**Verification:** no code changes yet; just a TODO list + a pinned list of `file_path:line` references for hot spots.

---

### PHASE 1 — Layer 1 tokens: Colors
**Files:**
- `lib/core/theme/app_colors.dart` — add `AmberDusk` block (keep legacy names as deprecated aliases for one phase to avoid compile break).
- `lib/core/theme/app_theme.dart` — rebuild `AppColorScheme.dark` from the 21 tokens in §2.1.
- Delete/deprecate unused: `darkTeal`, legacy `tealTransparent*`, `goldTransparent20` once references are cleaned.

**Evidence:** `themes.jsx:22–36` (the `amber` block).

**Verification:** boot app, every screen should now render in the warm palette (even if layout is old). Screenshot compare vs design.

**Commit:** `feat(theme): swap color palette to Amber Dusk (Layer 1)`

---

### PHASE 2 — Layer 1 tokens: Typography
**Files:**
- `pubspec.yaml` — add Fraunces (via `google_fonts` — no asset download needed if online, or bundle .ttf).
- `lib/core/theme/app_typography.dart`:
  - Add `displaySerif` family helper → `GoogleFonts.fraunces(...)`.
  - Rebuild scale — `displayLarge (34/−1.2/600 serif)`, `displayMedium (30/−0.5/600 serif)`, `displaySmall (26/−0.5/600 serif)`, `titleLarge (23/−0.5/600 serif)`, `titleMedium (22/−0.4/600 serif)`, `headlineLarge (21/−0.3/600 serif)`, keep body in DM Sans.
  - Add `tabularNums` TextStyle mixin for price/number displays.
- Scan `fontSize:` in `lib/features/**` — every raw literal becomes a mistake; route everything through `AppTypography`.

**Evidence:** `cards.jsx:28` (`fontFamily: t.serif || t.font`), `details.jsx:18,97,158`.

**Verification:** `flutter analyze` + render the theme dashboard page (`theme_dashboard.dart`) to compare all 16 styles visually.

**Commit:** `feat(theme): add Fraunces serif + tabular-nums scale`

---

### PHASE 3 — Layer 2 tokens: Layout + motion + decorations
**Files:**
- `lib/core/theme/app_layout.dart`:
  - `screenPaddingH = 20` (was 24).
  - `cardRadiusLg = 16`, `cardRadiusXl = 24`, `pillRadius = 999` (likely exists).
  - `bookingCardPadding = EdgeInsets.fromLTRB(20, 18, 20, 20)`.
  - `taskCardPadding = EdgeInsets.fromLTRB(16, 14, 16, 14)`.
  - `bottomNavMargin = 14`, `bottomNavPadding = EdgeInsets.fromLTRB(6, 8, 6, 8)`, `bottomNavHeight = 72 + safeArea`.
- `lib/core/theme/app_motion.dart`:
  - `pressScaleDuration = 150ms`, `curveGentle = Cubic(.2,.7,.3,1)`.
  - `fadeInDuration = 500ms`, `fadeInStagger = 60ms`, `fadeInOffset = 8px`.
  - `sheetDuration = 320ms`, `backdropFade = 200ms`.
  - `popDuration = 400ms`, `popCurve = overshoot 1.15`.
- `lib/core/theme/app_decorations.dart`:
  - `elevationCard(1|2|3)`, `elevationCream()`, `elevationPrimary(primary)`, `elevationBottomNav()` — exact shadow stacks from §2.5.
  - `insetHighlight(color, alpha: 0.04–0.06)` helper for the glass specular line.

**Verification:** build a `test/widget/theme_tokens_test.dart` golden that prints every token — guarantees no regression in Phase 5+.

**Commit:** `feat(theme): Layer 2 layout/motion/decoration tokens for Amber Dusk`

---

### PHASE 4 — Core atoms (Layer 3, shared widgets)
**Files in `lib/core/widgets/`:**
- `app_button.dart` — two variants (`primary` with `elevationPrimary`, `cream` with cream fill + `textDark` label); radius 999; height 44 sm / 52 md.
- `app_text_field.dart` — height 46, bg `bg2`, 1px `border`, radius `lg=16`, icon 18px muted, focused border `primary`.
- `app_chip.dart` (new or rename) — two flavours: `filterPill` (active primary, inactive transparent+border) and `tagChip` (bg2 fill, 12px radius, optional leading icon).
- `glass_container.dart` — keep, but swap defaults to new tokens.
- New: `header_glow.dart` — stateless widget with two `RadialGradient` blobs per §2.6.
- New: `fade_in.dart` — `AnimatedOpacity + Transform.translate` wrapping widget with `delay` + `dy` props (see `browse.jsx:8–12`).
- New: `typing_dots.dart` — 3 animated dots per `messages.jsx:49–56`.
- New: `avatar_ring.dart` — gradient ring wrapper using `primary→amber` (see `details.jsx:16`, `details.jsx:155`).
- New: `action_circle_button.dart` — 36px circular button with heroChip bg (see `cards.jsx:3–5`).
- New: `press_scale.dart` — `GestureDetector` + `AnimatedScale`, default `0.985`, for card presses.

**Evidence:** `cards.jsx:3–49` (ActionBtn + BookingCard), `browse.jsx:3–12` (HeaderGlow, FadeIn), `messages.jsx:49–56` (TypingDots).

**Verification:** widget tests for each atom; hit them in a storybook-style screen.

**Commit:** `feat(core/widgets): add Amber Dusk atom widgets (HeaderGlow, FadeIn, PressScale, etc.)`

---

### PHASE 5 — Avatar system
**Problem:** design uses 6 hand-drawn SVG personas; SLine uses real user photos via `SignedAvatar`. Do NOT replace real photos.

**Decision:** keep `SignedAvatar` for authenticated user images. Change the **placeholder** (when URL null/error) from initials-on-gold to one of the 6 SVG illustrations, **deterministically** chosen from the user id hash.

**Files:**
- `assets/avatars/ya.svg`, `ha.svg`, `za.svg`, `om.svg`, `la.svg`, `ka.svg` — port from `avatars.jsx:6–98`.
- `pubspec.yaml` — declare assets directory.
- `lib/core/widgets/signed_avatar.dart` — in the placeholder branch, `hashCode % 6` picks an SVG; fill with matching `bg` color from `AV` array in `avatars.jsx:104–111`.
- `lib/core/widgets/online_badge.dart` — 14px forest dot with 2.5px hero/bg border, positioned bottom-right.

**Verification:** write a widget test that forces null URL for 12 different user ids — expect 6 distinct SVGs rotating.

**Commit:** `feat(avatar): add Amber Dusk illustrated placeholders + online badge`

---

### PHASE 6 — Bottom navigation
**File:** `lib/core/widgets/custom_bottom_nav_bar.dart`
- Collapse from 6 tabs → **5** (Home · Tenders · Bookings/Book · Messages/Chat · Dashboard/Me). Dashboard absorbs Profile as a subtab (design does this — see `App shell:2437` where `dashboard` highlights for both `dashboard` and `profile`).
- Floating pill style:
  - Wrap nav in `Positioned(bottom: 0)` with outer gradient fade (`transparent → bg@e8 → bg`).
  - Inner container: `margin: 14 horiz`, `bg: bg2`, `radius: 28`, `padding: (6h, 8v)`, `elevationBottomNav()`.
- Each item: 42×32 tappable zone with `12px` radius chip; icon `22px` stroke `1.8`, label `9.5px` letter-spacing `0.2`.
- Active chip bg: `primary@18% alpha`, active icon + label in `primary`, font-weight 600. Inactive: muted.
- Transitions: `200ms` color tween.
- **Update:** `lib/core/providers/navigation_provider.dart` tab count & route mapping; `lib/app/main_navigation_screen.dart` to wire new 5-tab list (move Bookings tab index 2, drop dedicated Profile tab).

**Evidence:** `Sline V2 Amber Dusk.html:2425–2450`.

**Verification:** interactive smoke — tap each tab, verify Profile now routes via `Me` → Dashboard → sub-link.

**Commit:** `feat(nav): floating 5-tab pill bottom nav (Amber Dusk)`

---

### PHASE 7 — Feed cards (Booking + Task)
Files (locate exact paths in Phase 0):
- `lib/features/home/view/widgets/booking_card.dart` (rewrite)
- `lib/features/home/view/widgets/task_card.dart` (rewrite)
- OR the equivalent cards used on the feed.

**BookingCard** (`cards.jsx:7–50`):
- Gradient bg `linear-gradient(180deg, heroTop 0%, hero 60%, heroDeep 100%)`, radius 24, padding `18/20/20`.
- Top row: 52px avatar with 14px forest badge (2.5px hero border), plus right-aligned row of two `ActionCircleButton`s (heart, message).
- Middle: name (23/600 serif, leading 1.1, letter-spacing −0.5), subtitle (`{seniority} · {role}` uppercase 11.5/500 letter-spacing 0.6).
- Chip row (wrap, gap 6): rating `IcStar + rating` on heroChip bg; tags (location, experience) same treatment.
- Divider: 1px heroDivider, 14px vertical margin.
- Footer row: price `28/700 −0.8 tabular-nums` + `IQD` suffix `13` muted + `per {period}` caption uppercase; right side cream pill button `See details →` with cream shadow.
- Press scale 0.985, 150ms.

**TaskCard** (`cards.jsx:52–92`):
- Bg2 fill, radius 24, `borderLeft: 3px (rust if urgent else primary)`.
- Header: 32px avatar + name/time, right badge `● Urgent` (rust @15%) or `TASK` (primary @15%).
- Title row: title (15/600 leading 1.25) + price chip `bg3` rounded 10 (price tabular bold primary + IQD 10/500).
- Description: 12.5/muted, 1-line ellipsis.
- Tag row: location/schedule chips + deadline chip `amber@12%` with clock icon.
- Footer: offer avatars stack (up to 3, −6px overlap, 2px bg2 border) + `{offers} offers` text, right `Make offer` pill `primary@15%` with 1px `primary@40%` border.
- Press scale 0.99.

**Evidence:** `cards.jsx` full file.

**Verification:** rebuild home feed with 6 fake items matching `data.jsx:3–10`; screenshot-compare side-by-side.

**Commit:** `feat(feed): redesign Booking + Task cards (Amber Dusk)`

---

### PHASE 8 — HomeScreen
**File:** `lib/features/home/view/home_screen.dart`

**Evidence:** `browse.jsx:14–87`.

**Structure** (top to bottom):
1. Stack containing `HeaderGlow` behind content.
2. 48px top spacer (status bar handled by phone frame; safe area in app).
3. Greeting row: 46px avatar (self — Omar), stacked `صباح الخير · Good morning` (12 muted) + `Omar` (21/600 serif −0.3). Right: 42px circular bell button (`bg2`, border) with 8px primary dot badge top-right.
4. Search bar: 46px height, `bg2`, radius 16, border, icons left (search muted) + right (filter muted), placeholder `Search freelancers, tasks…`.
5. **Stat row:** 3 horizontal stat tiles — Active/Messages/Done — each with a 28px rounded icon square at accent color @12%, big number (15/600) + label (10 muted letter-spacing 0.2).
6. **Filter pills:** `All · Bookings · Tasks` — pill radius 999, active primary+cream, shadow `primary@30%`.
7. Section header `Feed` + `{n} posts` right.
8. Feed column `gap: 14`, each item wrapped in `FadeIn(delay: i*60)`.
9. 30px bottom spacer (nav clearance handled by Scaffold bottom inset).

**ViewModel gaps to document (don't patch here):**
- Greeting needs `first name` + locale-aware morning/evening.
- Stat tile values — where does `12 Active` come from? Mark TODO to add `HomeStatsViewModel.activeCount`, `.unreadMessages`, `.doneCount`.
- Bell badge unread count — from `NotificationsViewModel`.

**Commit:** `feat(home): redesign HomeScreen to Amber Dusk`

---

### PHASE 9 — TendersScreen + BookingsBrowseScreen
**Files:**
- `lib/features/tasks/view/...` (locate tenders list screen in Phase 0)
- `lib/features/search/view/...` OR bookings browse screen

**Evidence:** `browse.jsx:89–143`.

**Shared layout:**
- HeaderGlow + 48px spacer.
- Overline `BROWSE` (11 muted letter-spacing 0.4 uppercase) + huge title `Tenders` / `Bookings` (30/600 serif −0.5) — matches existing `h3` use in inventory but promoted to serif.
- Search bar row (46 bg2).
- Column feed with `FadeIn(delay: i*50/60)`, using `TaskCard` or `BookingCard` respectively.

**Commit:** `feat(browse): redesign Tenders + BookingsBrowse to Amber Dusk`

---

### PHASE 10 — MessagesScreen
**File:** `lib/features/chat/view/messages_screen.dart` (locate in Phase 0)

**Evidence:** `messages.jsx:3–47`.

- HeaderGlow + overline `INBOX` + title `Messages` (30/600 serif).
- Segmented toggle `Responses | Requests` — pill group in bg2 capsule with 3px inner padding, active = primary fill + cream label + shadow.
- **Online now row:** horizontal 48px avatars, name first-name below. Only for chats with `online: true`.
- Thin 1px divider.
- Thread list: each row is a bg2 rounded-24 card with 46px avatar (+ online dot), name + timestamp row, last message or `TypingDots` (`typing: true`), unread count as primary pill right-aligned.
- Press scale 0.99 on tap.
- Wrap each row in `FadeIn(delay: i*40)`.

**Commit:** `feat(chat): redesign MessagesScreen (Amber Dusk)`

---

### PHASE 11 — ChatDetail
**File:** `lib/features/chat/view/chat_screen.dart` (locate)

**Evidence:** `messages.jsx:58–115`.

- Sticky top bar (52px top pad for status bar): back button 36px circle, 36px avatar, name + online status (`● Online` forest or `Offline` muted), right-aligned `[IcSend] Offer` outlined pill (primary@15% fill, primary@40% border).
- Message list: scrollable column, auto-scroll to bottom on new message. Each bubble:
  - `me`: right-aligned, primary fill (full), cream text, radius `18/18/4/18`, shadow `primary@25%`.
  - `them`: left-aligned, bg2 fill, 1px border, radius `18/18/18/4`.
  - Max width 78%, padding 10/14, 13.5 font, 1.45 leading. Timestamp 10/0.6-alpha under text.
- Composer bar (sticky bottom, blurred `${bg}f5` + 14px blur, 1px top border):
  - 36px attach circle (`IcAttach` muted) left.
  - Input: flex, bg2, 1px border, radius 999, padding 10/16, 13.5 font.
  - 40px send button — primary fill + cream icon when draft non-empty, bg2 + muted when empty. Transition `200ms all`.
- Offer button in header opens `OfferComposer` bottom sheet (Phase 13).

**VM gaps:** confirm `ChatViewModel` exposes message streaming, typing indicator, and can post offers.

**Commit:** `feat(chat): redesign ChatDetail (Amber Dusk)`

---

### PHASE 12 — Dashboard + sub-tabs
**File:** `lib/features/dashboard/view/dashboard_screen.dart`

**Evidence:** `dashboard.jsx:3–253`.

- HeaderGlow + overline = **current subtab label** (uppercased) + title `Dashboard` (30/600 serif).
- **Subtab pill bar** (horizontal scroll): `Overview · Bookings · Work · Wallet · Inbox`. Active pill = primary+cream+shadow; inactive = transparent+1px-border. 8px gap.
- **Overview:**
  - Wallet gradient card (bg2→bg3 155deg, radius 24, padding 22, radial primary glow top-right). Header `[IcWallet] Wallet`. Balance `4,250,000` (34/600 serif tabular) + `IQD` (18 muted). USD subtitle. Pending row at bottom (bg@80%, 14 radius, border) with Withdraw pill (primary bg).
  - 2×2 stat grid (bg2, 16 radius, border): Pending · Active · Messages · New offers, each with colored icon chip.
  - `Next actions` list: bg2 rows with icon (primary/forest tint), title, subtitle, relative time, chevron right.
- **Bookings sub:** `Upcoming` + `Past` lists. Each bookings card has 40px avatar, name + role/time, price right, Accept/Decline buttons. Accept morphs to `[IcCheck] Accepted — see you {when}` (forest@15% pill). Declined fades to 0.5 opacity.
- **Work sub:** Segmented `Active (n) | Done (n) | Cancelled (n)` in bg2 capsule. Each row: 34px avatar, title (1 line ellipsis), client + due, amount right. Progress bar (5px, bg3 track, primary/forest/rust fill per status), animated 800ms.
- **Wallet sub:** Large dark gradient card (hero→heroDeep), radial amber glow. Balance 38/700 serif. Two buttons: `Withdraw` cream, `Top up` glass. Pending row below. Transaction list: each row has in/out/fee icon (forest/rust/muted), label + sub, amount + date right.
- **Inbox sub:** `Received | Sent` segmented. Each offer card: 36px avatar, name + title, colored status pill (pending amber / accepted forest / declined muted), border-top divider, time left + amount right.

**VM gaps (document, don't patch):**
- `DashboardOverviewViewModel` needs `pendingCount`, `activeCount`, `messagesCount`, `newOffersCount`, `nextActions[]` (ad-hoc list).
- `WorkViewModel` needs `progress: double` on each WorkItem.
- `DashboardInboxViewModel` unified offers list with sent/received flag.

**Commit:** `feat(dashboard): redesign Dashboard + 5 sub-tabs (Amber Dusk)`

---

### PHASE 13 — BookingDetail + TaskDetail + OfferComposer
**Files:**
- `lib/features/profile/view/public_profile_screen.dart` (the booking-detail) + subwidgets from `UI_DOCS_PUBLIC_PROFILE.md`.
- `lib/features/tasks/view/task_detail_screen.dart` (locate).
- `lib/features/direct_offers/view/...` (locate OfferComposer).

**BookingDetail** (`details.jsx:3–75`):
- Sticky translucent back bar (`${bg}dd` + 20px blur, 1px bottom border). Centered title `Profile`. Right-aligned heart toggle.
- Hero block (linear-gradient hero→heroDeep, padding 20/20/24): gradient-ring-wrapped 72px avatar + name (22/600 serif), subtitle uppercase `{seniority} · {role}`, chip row (rating + location + experience). Divider. Bottom row: `Rate` overline + price (24/700 tabular) + `IQD / {period}`, and cream `Book now →` pill.
- Tabs `About · Portfolio · Reviews` (underline-style, 2px primary).
- **About:** bio paragraph + `SKILLS` overline + skill pills (first 2 highlighted primary) + `LANGUAGES` + Arabic/English pills.
- **Portfolio:** 2-column grid, `aspect-ratio: 1`, 16 radius placeholder cards (bg2→bg3 gradient).
- **Reviews:** bg2 cards with avatar + name + stars + body.

**TaskDetail** (`details.jsx:77–133`):
- Sticky back bar `Task`.
- Poster row (42px avatar + name + `Posted {time}`), right urgent badge if urgent.
- Title 26/600 serif −0.5.
- 2 side-by-side stat cards `Budget` (primary 20/700) + `Deadline` (amber 20/700) + caption.
- `DESCRIPTION` overline + body (14/1.6/muted).
- `REQUIREMENTS` overline + pill chips.
- Offers pill: avatar stack + `{n} freelancers have made an offer` + chevron.
- Sticky bottom bar: `[IcMsg] Chat` outlined (flex 0.5) + `[IcSend] Make offer` primary (flex 1.5).

**OfferComposer** (`messages.jsx:117–169`):
- Bottom-anchored modal, `bg: rgba(0,0,0,0.6) + 10px blur`, sheet `bg2` with 28px top radius.
- 40×4 drag handle.
- Overline `SEND DIRECT OFFER TO` + 34px avatar + recipient name (18/600 serif).
- Title input (bg3, 1px border, radius 12, padding 11/14, 14 font).
- Row: Amount (flex 1.3, primary 16/700 tabular) | Delivery days (flex 1, 16/600). Each field has overline label.
- Actions: `Cancel` (outlined flex 1) + `[IcSend] Send offer` (primary flex 1.3, shadow).
- Success state: green forest@20% circle with pop animation + check, heading `Offer sent` (20/600 serif) + subtitle `{name} will be notified.` then auto-dismiss (1000ms).

**Commit:** `feat(details): redesign BookingDetail/TaskDetail/OfferComposer (Amber Dusk)`

---

### PHASE 14 — ProfileScreen (self-view, "Me")
**File:** `lib/features/profile/view/profile_screen.dart` (locate) — this is the user's *own* profile, distinct from the public profile.

**Evidence:** `details.jsx:135–195`.

- HeaderGlow + overline `ACCOUNT` + title `Profile` (30/600 serif). Right: 40px settings icon (cog SVG) in bg2 circle.
- **Cream identity card** (full width, 24 radius, cream→creamSubtle 180deg gradient, shadow `0 12px 32px + 0 4px 8px rgba(0,0,0)`):
  - 60px top strip with `primary@25% + amber@20%` 135deg wash.
  - Gradient-ring 62px avatar overlapping by −30px.
  - Name `Omar Khalil` 22/600 serif on textDark + `Verified` forest@20% pill.
  - Subtitle `UI/UX Designer · Baghdad` (mutedDark).
  - Bio paragraph textDark mutedDark.
- 3-up stat cards: `Rating 5.0★` (star color) · `Deals 12` (primary) · `Earned 4.1M` (forest).
- `SKILLS` overline + pills (first 2 highlighted primary).
- `PORTFOLIO` overline + `See all` primary link + horizontal scroll of 130×90 gradient thumbnails.
- Bottom: logout button (lightRed box) — not shown in design but preserve from current SettingsScreen pattern.

**VM gaps:** map `ProfileViewModel` — verify `.stats.rating`, `.stats.deals`, `.stats.earned`. Currently public profile has these but self-view may not.

**Commit:** `feat(profile): redesign self ProfileScreen (Amber Dusk)`

---

### PHASE 15 — Settings, Auth, Create-Task, Booking-payment, Empty states
**Pass #2 — absorb the rest of the inventory under the new tokens.**

Because Layers 1–3 are already correct, most remaining screens rebuild automatically. Still need explicit visual passes on:
- **Auth screens** (`lib/features/auth/view/*`): login/signup — adopt big serif title `Sline` or similar, DM Sans body, primary button, cream "or continue with" divider. Add a HeaderGlow in background.
- **Settings** (`lib/features/profile/view/settings_screen.dart`): rows of GlassContainer tiles with icon chip + title + subtitle + chevron; section overlines. Switch active-thumb = primary.
- **EditProfile, ManagePortfolio, MyServices, Notifications, Wallet transactions** (all in `UI_DOCS_PROFILE_SCREENS.md`) — follow the new token system; typography shifts to serif only on the **screen title**.
- **Empty states** (no chats, no work, no reviews): center icon 64 muted @30% opacity + 13/muted text. Design shows `design_services_outlined`, `folder_open` etc. — keep but restyle.
- **Error/loading**: CircularProgressIndicator uses `primary` (now terracotta). Retry buttons: primary pill.

**Verification:** full manual sweep — boot app, visit every entry point in `main_navigation_screen.dart`, screenshot compare against `SLINE_UI_INVENTORY_V2.md`.

**Commit:** `feat(misc): sweep auxiliary screens to Amber Dusk tokens`

---

### PHASE 16 — Localization, RTL, polish
- **Iraqi copy:** replace demo user names/locations in sample/fixture data ONLY if any test fixtures use non-Iraqi names (real user data stays intact via Supabase).
- **IQD format:** audit `lib/core/utils/format_price.dart` — every price renders `850,000 IQD` not `$45/hr`. Add helper `formatIqd(int amount)` with `,` thousands separator.
- **Arabic greeting:** add `lib/l10n/*.arb` entries for `greetingMorning`, `greetingAfternoon`, `greetingEvening` with both Arabic and English variants (design shows them concatenated by ` · `).
- **RTL:** Iraqi = Arabic. Design is LTR but chat says `copy_locale: yes`. Verify `Directionality` works with new token layouts — the bottom nav pill and card chip rows already use `Row` with logical flex, should mirror cleanly.
- **Accessibility:** ensure contrast on `cream` on `textDark` meets AA (7.8:1 — passes). Verify `muted` (#8F8478) on `bg` (#1A1612) is ≥ 4.5:1 — measure; if not, bump to `#A0988C` for labels only.
- **Analyze + tests:** `flutter analyze` clean, architecture-guard passes (no new Supabase imports in views), coverage floor holds (40%).
- **Regenerate** `theme_dashboard.dart` to display final palette.

**Commit:** `feat(polish): Iraqi copy + IQD format + RTL audit + contrast check`

---

## 5. Risks & Mitigations

| Risk | Mitigation |
|---|---|
| Color token rename breaks 200+ files | Phase 1 keeps legacy names as deprecated aliases; remove in Phase 15 sweep. |
| `AppColors.teal` references scattered in features/ | Treat all `teal` → `primary` (semantic), `lightTeal` → `amber` (accent), `gold` → `star`. Do it with `Edit` replace_all file by file so review is easy. |
| Fraunces bundle size | Use `GoogleFonts.fraunces` (runtime fetch) first; bundle `.ttf` only if offline rendering required. |
| Public profile tab order (`UI_DOCS_PUBLIC_PROFILE.md` has 4 tabs: About/Portfolio/History/Reviews) vs design (3 tabs: About/Portfolio/Reviews) | Keep 4; map design's `Reviews` tab to `Reviews`; preserve `History` tab as Flutter-only. |
| Dashboard subsumes Profile tab | Keep old `/profile` route for deep links; bottom nav just no longer surfaces it directly. |
| Architecture guard (CLAUDE.md) — Supabase in views | Every new widget stays in `lib/core/widgets/` or `lib/features/*/view/widgets/`; no repo imports. VM gaps flagged in-place, never patched inline. |
| Screen-by-screen drift | Every phase ends with a before/after screenshot in the commit body; reviewers can spot divergence. |
| Token coverage gap (something hardcodes `Colors.teal` or `fontSize: 16`) | Phase 15 grep sweep: `grep -rn "Color(0x\|fontSize:" lib/features/` — zero tolerance for raw values after Phase 14. |

---

## 6. Definition of Done

- [ ] All 5 bottom-nav tabs render the new palette and layout.
- [ ] All 9 hero screens from the design (Home, Tenders, BookingsBrowse, Messages, ChatDetail, Dashboard×5 sub, BookingDetail, TaskDetail, Profile) visually match the HTML prototype side-by-side.
- [ ] Fraunces loads and displays on all `serif` identifiers in design source.
- [ ] Motion tokens in use everywhere: card press scale, feed FadeIn stagger, modal slide-up, success pop, typing dots, progress bar fill.
- [ ] No raw color hex or font size literals in `lib/features/**`.
- [ ] `flutter analyze` clean, architecture-guard passes, tests ≥ 40% coverage.
- [ ] `theme_dashboard.dart` regenerated to reflect the Amber Dusk palette.
- [ ] `pubspec.yaml` declares Fraunces + 6 avatar SVGs.
- [ ] Merge `RedsignTheUi` → `main` in one PR (or 3 PRs: tokens / nav+cards / screens).

---

## 7. Quick-Reference: Source File → Target Feature

| Design source (JSX) | Target Flutter |
|---|---|
| `shared/themes.jsx:22–36` | `lib/core/theme/app_colors.dart` + `app_theme.dart` |
| `shared/cards.jsx` (BookingCard) | `lib/features/home/view/widgets/booking_card.dart` (or feed card widget) |
| `shared/cards.jsx` (TaskCard) | `lib/features/home/view/widgets/task_card.dart` |
| `shared/avatars.jsx` | `assets/avatars/*.svg` + `lib/core/widgets/signed_avatar.dart` (placeholder branch) |
| `shared/icons.jsx` | Replace with Material/Cupertino icons or bespoke `SvgPicture` if style diverges |
| `screens/browse.jsx` HomeScreen | `lib/features/home/view/home_screen.dart` |
| `screens/browse.jsx` TendersScreen | `lib/features/tasks/view/tenders_screen.dart` |
| `screens/browse.jsx` BookingsBrowseScreen | `lib/features/search/view/bookings_browse_screen.dart` |
| `screens/messages.jsx` MessagesScreen | `lib/features/chat/view/messages_screen.dart` |
| `screens/messages.jsx` ChatDetail | `lib/features/chat/view/chat_screen.dart` |
| `screens/messages.jsx` OfferComposer | `lib/features/direct_offers/view/offer_composer_sheet.dart` |
| `screens/dashboard.jsx` DashboardScreen | `lib/features/dashboard/view/dashboard_screen.dart` |
| `screens/details.jsx` BookingDetail | `lib/features/profile/view/public_profile_screen.dart` |
| `screens/details.jsx` TaskDetail | `lib/features/tasks/view/task_detail_screen.dart` |
| `screens/details.jsx` ProfileScreen | `lib/features/profile/view/profile_screen.dart` |
| `Sline V2 Amber Dusk.html:2425` BottomNav | `lib/core/widgets/custom_bottom_nav_bar.dart` |

---

## 8. What to do RIGHT NOW (next session)

1. **Kickoff Phase 0:** run the discovery greps in §4 Phase 0, return the actual paths of `booking_card`, `task_card`, `tenders_screen`, `messages_screen`, `chat_screen`, `task_detail_screen`, `dashboard_screen` — save them into this file under §7.
2. **Ship Phase 1 + 2 in one PR** (tokens only — palette + serif). Smallest safe change; visually hints at the new direction without rewriting widgets.
3. Review against design — confirm `primary` terracotta reads correctly and Fraunces renders.
4. Then proceed Phases 3 → 16 in order, one PR each.

*Plan ends here. No code changes yet.*
