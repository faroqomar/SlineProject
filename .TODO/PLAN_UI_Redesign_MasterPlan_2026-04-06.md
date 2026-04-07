# SLINE UI REDESIGN — MASTER PLAN
> From basic to best-in-class. Every screen, every widget, every animation.
> Generated: 2026-04-06

---

## THE PROBLEM

The current UI is **functional but basic**. It looks like a 2022 Flutter template, not a 2026 premium marketplace.

**Specific issues found in code audit:**
- **Zero animations** on 90% of screens (login, signup, profile, chat, tasks — all static)
- **Cards are flat and lifeless** — task_card, booking_card, tender_task_card all use simple InkWell with no press feedback, no elevation change, no state transitions
- **Dashboard counters** are just text in boxes — no animated count-up, no icons that breathe
- **Message bubbles** are WhatsApp-circa-2018 — hard corners, no grouping, no reactions, no swipe-to-reply
- **Login/Signup** has zero motion — form appears instantly, no logo animation, no field stagger
- **Profile screen** uses hardcoded placeholder stats ("47 projects", "$12.5k")
- **Bottom nav** has animation but the rest of the app feels dead by comparison
- **No loading shimmer** on most screens — just a centered CircularProgressIndicator
- **No empty state designs** — just icon + plain text
- **Colors are flat** — no gradients with purpose, no depth, no layering
- **Shadows are inconsistent** — some cards have blurRadius=20 (heavy), others have 0 (flat)
- **No haptic feedback** anywhere
- **No accessibility** — zero Semantics widgets, no focus rings, no screen reader support
- **Typography has flat line-height** (1.2 everywhere) making body text cramped and hard to read

---

## THE VISION

A **premium, fluid, responsive** marketplace app that feels like it was designed by a top-tier studio:
- **Intentional motion** on every interaction (not decorative — purposeful)
- **Layered depth** using subtle shadows, blur, and elevation
- **Content-first hierarchy** — important info jumps out, secondary fades back
- **Micro-interactions** that reward engagement (haptics, scale, color shifts)
- **Graceful states** — loading shimmers, meaningful empty states, smooth error recovery
- **Accessibility-first** — every element has a semantic label, focus ring, 4.5:1 contrast

---

## HOW TO USE THIS PLAN

1. **Work phase by phase, top to bottom.** Phase 0 (theme) must be done first.
2. **For each item**: read the BEFORE (what exists), the AFTER (what we want), the FILES to change, and the SKILLS to run.
3. **Use Cursor agents**: `@Pixel` for UI, `@Architect` for logic, `@Sentinel` for QA.
4. **Run `teach-impeccable` first** to populate `.impeccable.md` design context.
5. **Verify after each section**: `flutter analyze` clean + visual check on device.

---

# PHASE 0: DESIGN SYSTEM OVERHAUL

> Everything depends on this. Do it first. Every screen inherits these changes.

---

## 0.1 Motion Tokens (NEW FILE)

**BEFORE:** No animation constants exist. Every widget picks random durations (100ms, 200ms, 300ms, 450ms, 1000ms, 1500ms) and random curves (easeInOut, easeOutBack, easeOutCubic, easeInOutSine).

**AFTER:** Create `lib/core/theme/app_motion.dart`:

```
class AppMotion {
  // Durations (100/300/500 rule from motion-design.md)
  static const micro    = Duration(milliseconds: 100);  // toggles, badges, ripples
  static const standard = Duration(milliseconds: 300);  // cards, sheets, tabs
  static const emphasis = Duration(milliseconds: 500);  // page transitions, hero

  // Curves (ease-out family — never bounce/elastic)
  static const curveStandard = Curves.easeOutCubic;     // most interactions
  static const curveDecel    = Curves.easeOutQuart;      // entering elements
  static const curveAccel    = Curves.easeInCubic;       // exiting elements
  static const curveSpring   = Cubic(0.175, 0.885, 0.32, 1.1); // subtle overshoot

  // Scale amounts
  static const pressScale   = 0.96;  // button press-down
  static const hoverScale   = 1.02;  // card hover
  static const badgeScale   = 1.15;  // notification badge entrance
}
```

**FILES:** Create `lib/core/theme/app_motion.dart`
**SKILL:** `animate` to define, `normalize` to replace all hardcoded values across codebase

---

## 0.2 Interaction States (NEW FILE)

**BEFORE:** Buttons have 2 states: default and loading. No hover, focus, disabled, error, or success states. AppButton just swaps text for a spinner.

**AFTER:** Create `lib/core/theme/app_states.dart`:

```
// Every interactive element supports these states:
// default → hover → focus → active/pressed → disabled → loading → success → error
//
// State visual treatments:
// - hover:    elevation +1, opacity 0.95, scale 1.02
// - focus:    2px outline (teal, 2px offset), no fill change
// - pressed:  scale 0.96, darker tint, haptic lightImpact
// - disabled: opacity 0.4, no pointer events
// - loading:  subtle pulse, replace icon/text with spinner
// - success:  flash green tint (300ms), check icon, haptic success
// - error:    flash red tint (300ms), shake animation (3 cycles, 4px amplitude)
```

**FILES:** Create `lib/core/theme/app_states.dart`, then update `app_button.dart`, `app_text_field.dart`, `glass_button.dart`, `circle_icon_button.dart`, `scale_button.dart`
**SKILL:** `harden` (all states), `animate` (transitions)

---

## 0.3 Shadow & Elevation Scale

**BEFORE:** Random shadows: blurRadius=20/offset=8 on TaskCard, blurRadius=12/offset=4 on TenderCard, blurRadius=10/offset=4 on BookingCard, blurRadius=8/offset=2 on DashboardOfferCard. No consistency.

**AFTER:** Add to `app_decorations.dart`:

```
// 4-level elevation system:
// Level 0 (flat):      no shadow (cards at rest in list)
// Level 1 (resting):   blur=4,  offset=(0,1), alpha=0.06   — default cards
// Level 2 (raised):    blur=8,  offset=(0,2), alpha=0.08   — hovered/focused cards
// Level 3 (floating):  blur=16, offset=(0,4), alpha=0.12   — modals, FAB, dragged items
// Level 4 (dramatic):  blur=24, offset=(0,8), alpha=0.16   — popovers, dropdowns
```

**FILES:** `lib/core/theme/app_decorations.dart`, then update every card widget
**SKILL:** `normalize` (consolidate all shadows), `polish` (verify visual hierarchy)

---

## 0.4 Typography Line Heights

**BEFORE:** All styles have `height: 1.2` globally. Body text at 14px/1.2 = 16.8px line height — way too tight for reading.

**AFTER:** Update `lib/core/theme/app_typography.dart`:

```
// Headings: 1.1 - 1.2 (tight, impactful)
// h1: height 1.1, h2: 1.15, h3: 1.2, h4-h6: 1.2

// Body: 1.4 - 1.6 (comfortable reading)
// bodyLarge: height 1.5, bodyMedium: height 1.5, bodySmall: height 1.4

// Captions: 1.3 (compact but readable)
// caption: height 1.3, captionBold: height 1.3, overline: height 1.3, micro: height 1.2

// Letter spacing:
// overline: letterSpacing 1.5 (ALL CAPS readability)
// caption: letterSpacing 0.2 (subtle)
// h1-h3: letterSpacing -0.5 (tighten large text)
```

**FILES:** `lib/core/theme/app_typography.dart`
**SKILL:** `typeset`

---

## 0.5 Color System Semantic Expansion

**BEFORE:** Basic palette works but no semantic tokens for success/warning/info. Status colors hardcoded in each widget's switch statement (11 cases in booking_card alone).

**AFTER:** Add to `AppColorScheme`:

```
// Semantic status colors (light + dark mode):
Color get success      // green — completed, approved, online
Color get successMuted // green at 10% — success backgrounds
Color get warning      // amber — pending, expiring, attention
Color get warningMuted // amber at 10%
Color get info         // blue — informational, neutral status
Color get infoMuted    // blue at 10%
Color get danger       // red — errors, declined, urgent
Color get dangerMuted  // red at 10%

// Interactive state colors:
Color get hoverOverlay    // primary at 5%
Color get pressedOverlay  // primary at 10%
Color get focusRing       // primary at full opacity, 2px
Color get disabledBg      // grey at 10%
Color get disabledText    // grey at 40%
```

**FILES:** `lib/core/theme/app_colors.dart`
**SKILL:** `colorize`, `audit` (contrast check every combo)

---

## 0.6 Theme Component Themes

**BEFORE:** Only ElevatedButton, InputDecoration, and AppBar themed. Cards, dialogs, chips, bottom sheets all use defaults.

**AFTER:** Add to `app_theme.dart`:

```
// Add these ThemeData properties:
// - CardTheme(elevation: 0, shape: RoundedRectangleBorder(r16), color: cardBackground)
// - DialogTheme(shape: RoundedRectangleBorder(r24), backgroundColor: cardBackground)
// - BottomSheetThemeData(shape: RoundedRectangleBorder(topLeft/Right r24))
// - ChipThemeData(shape: StadiumBorder(), backgroundColor: transparent, side: 1px outline)
// - DividerThemeData(color: outline, thickness: 0.5, space: 0)
// - SnackBarThemeData(shape: RoundedRectangleBorder(r12), behavior: floating)
// - TabBarThemeData(indicator: UnderlineTabIndicator(width: 3, radius: 2))
```

**FILES:** `lib/core/theme/app_theme.dart`
**SKILL:** `normalize`

---

# PHASE 1: CORE WIDGET REDESIGN

> 14 widgets used everywhere. Upgrading these transforms the entire app.

---

## 1.1 AppButton — From Dead to Alive

**BEFORE:** Static Material+InkWell. Two states: default and loading (swaps text for spinner). No scale, no haptics, no disabled styling, no success feedback. ~30 lines.

**AFTER:**
- Wrap in ScaleButton with `AppMotion.pressScale` (0.96) on press-down
- Add `HapticFeedback.lightImpact()` on tap
- Loading state: shrink text out (opacity 0→1), scale spinner in
- Success state: flash `success` color for 300ms, show check icon, then revert
- Disabled: opacity 0.4, ignore pointer
- Focus: 2px teal outline with 2px offset
- Add Semantics(button: true, label: text)
- Icon variant: icon left of text with 8px gap, both animate together

**FILES:** `lib/core/widgets/app_button.dart`
**SKILLS:** `animate` (press + success), `harden` (all 8 states), `delight` (haptics + success flash)
**DEPENDS ON:** 0.1 (AppMotion), 0.2 (AppStates)

---

## 1.2 AppTextField — From Static to Interactive

**BEFORE:** Bare TextFormField wrapper. No animations. No error animation. No character count. No clear button.

**AFTER:**
- Focus transition: border color animates from outline → teal (200ms easeOutCubic)
- Error state: field shakes horizontally (3 cycles, 4px, 300ms) + border turns danger red
- Label floats above on focus (standard Material behavior but verify it works with our decoration)
- Add optional `maxLength` with live counter (right-aligned below field, caption style)
- Add optional clear button (X) that appears when field has value (fade in 100ms)
- Add optional `obscureText` toggle button (eye icon) for password fields
- Add Semantics with label and error announcement
- Suffix icon animates rotation on state change (e.g., dropdown arrow rotates 180 on open)

**FILES:** `lib/core/widgets/app_text_field.dart`
**SKILLS:** `animate` (shake, focus), `clarify` (labels), `harden` (all edge cases)

---

## 1.3 GlassContainer → Solid Surface Migration (NO GLASS)

**BEFORE:** BackdropFilter with blur=20 everywhere. Performance-heavy. Used for every card and container. Glassmorphism is dated in 2026.

**AFTER — NO GLASS POLICY (see .impeccable.md):**
- **Remove ALL BackdropFilter** from GlassContainer. Replace with solid surface.
- Background: solid `colorScheme.cardBackground`
- Border: `colorScheme.cardBorder` (1px, subtle)
- Depth: `AppDecorations.elevation(level)` parameter for shadow
- Web and mobile render identically (no platform branching needed)
- Keep widget name `GlassContainer` for backward compat but internal implementation is solid
- **Every screen using GlassContainer (21 files) gets cleaner, faster, more readable surfaces**

**FILES:** `lib/core/widgets/glass_container.dart`
**SKILLS:** `distill` (remove glass complexity), `normalize` (solid surfaces everywhere)

---

## 1.4 ScaleButton — Spring Physics

**BEFORE:** Linear scale from 1.0 → 0.95 with easeInOut curve, 100ms. Fixed 50ms callback delay.

**AFTER:**
- Replace with `AppMotion.curveSpring` for a subtle bounce-back feel
- Duration: `AppMotion.micro` (100ms) down, spring-back on release (200ms)
- Add `HapticFeedback.selectionClick()` on press-down
- Remove hardcoded 50ms delay — fire callback on tap-up immediately
- Add `disabled` parameter that prevents scale + greys out child
- Respect `MediaQuery.disableAnimations` — skip scale if true

**FILES:** `lib/core/widgets/scale_button.dart`
**SKILLS:** `animate` (spring), `harden` (reduced motion, disabled)

---

## 1.5 CustomBottomNavBar — Polish the Best Widget

**BEFORE:** Already the most polished widget (liquid glass, animated pill, 300ms transitions). But: no labels under icons, no badge animation, no haptic feedback, hardcoded nav items.

**AFTER:**
- Add tiny labels below each icon (micro text, fades in on active, fades out on inactive)
- Badge entrance: scale from 0 → 1 with `AppMotion.curveSpring` when count changes
- Badge shows count (max "99+"), not just a dot
- Add `HapticFeedback.selectionClick()` on each tap
- Add long-press tooltip showing full label
- Extract nav item data to a config list (not hardcoded in build)
- Double-tap active tab = scroll-to-top in that tab's content

**FILES:** `lib/core/widgets/custom_bottom_nav_bar.dart`
**SKILLS:** `delight` (badge animation, haptics), `clarify` (labels), `adapt` (all device sizes)

---

## 1.6 SignedAvatar — From Spinner to Shimmer

**BEFORE:** Shows `CircularProgressIndicator` while loading. Error shows generic person icon. No animation on load.

**AFTER:**
- Loading: shimmer placeholder (SkeletonLoader circle) instead of spinner
- Loaded: fade-in with `AppMotion.standard` (300ms, easeOutCubic)
- Error: show colored circle with user initials (first letter of name, gold background)
- Add optional online indicator dot (12px green circle with 2px white border, positioned bottom-right)
- Add optional `hero` tag for shared element transitions to profile screens

**FILES:** `lib/core/widgets/signed_avatar.dart`
**SKILLS:** `delight` (shimmer + fade-in), `harden` (error fallback)

---

## 1.7 SkeletonCard — Complete Coverage

**BEFORE:** 6 skeleton variants exist (TaskCard, BookingCard, OfferCard, MessageBubble, ConversationTile, DetailsScreen). Missing: wallet, proposal, work item, notification, service, favorite, search result, profile.

**AFTER:** Add skeleton variants for every card type in the app:
- `SkeletonWalletHeroCard` — gradient placeholder with shimmer amount
- `SkeletonProposalTile` — avatar + lines + price line
- `SkeletonWorkItemCard` — header bar + body lines + button area
- `SkeletonNotificationTile` — icon circle + 2 lines + time
- `SkeletonServiceCard` — image rect + title + price
- `SkeletonFavoriteCard` — avatar + name + stats
- `SkeletonSearchResultCard` — avatar + lines + tags
- `SkeletonProfileCard` — large avatar + 3 lines + stats row

**FILES:** `lib/core/widgets/skeleton_card.dart`
**SKILLS:** `extract` (match real card layouts), `delight` (staggered entrance)

---

## 1.8 StatusBadge — Semantic + Animated

**BEFORE:** Static colored container with text. Color mapped via 11-case switch statement hardcoded in widget. No icon, no animation.

**AFTER:**
- Add icon to each status (check for completed, clock for pending, x for cancelled, etc.)
- Use semantic colors from AppColorScheme (success, warning, danger, info) instead of hardcoded values
- Pulse animation on "pending" and "urgent" statuses (subtle opacity pulse, 2s, repeat)
- Pill shape (StadiumBorder) for consistent look
- Add Semantics label announcing status
- Status transitions: animate color change when status updates (300ms crossfade)

**FILES:** `lib/core/widgets/status_badge.dart`
**SKILLS:** `colorize` (semantic colors), `animate` (pulse + transition), `harden` (colorblind: icon always present)

---

# PHASE 2: APP SHELL & NAVIGATION

---

## 2.1 MainNavigationScreen — Fluid Transitions

**BEFORE:** `AnimatedSwitcher` with default fade between 7 tabs. FAB positioned 100px above bottom. Runtime banner just appears.

**AFTER:**
- Replace fade with shared-axis transition (horizontal slide + fade, 300ms)
- Re-tap active tab = scroll content to top (pass callback to child screens)
- FAB: add `ScaleTransition` entrance on first render (scale 0→1, 500ms, curveSpring)
- FAB: hide on scroll-down, show on scroll-up (with slide animation, like Material 3 extended FAB)
- Runtime banner: slide down from top with 300ms animation, dismiss by swipe-up
- Background: simplify the 3-layer system (gradient overlay + phone bg + content is overkill — single themed background)

**FILES:** `lib/app/main_navigation_screen.dart`
**SKILLS:** `animate` (transitions), `arrange` (FAB behavior), `distill` (simplify background)

---

## 2.2 Page Transitions

**BEFORE:** Default `MaterialPageRoute` slide transition everywhere. No hero animations. No container transforms.

**AFTER:**
- Card → Detail screens: use `OpenContainer` (container transform) — card expands into detail page
- Peer navigation (tabs): shared-axis horizontal
- Forward navigation (push): shared-axis vertical (slide up + fade)
- Backward navigation (pop): reverse of forward
- Modal sheets: slide up from bottom with spring physics
- Define a `SlinePageRoute` helper that applies the correct transition based on navigation type

**FILES:** `lib/core/utils/transitions.dart` (expand existing), `lib/main.dart` (routes)
**SKILLS:** `animate` (all transitions), `normalize` (consistent everywhere)

---

# PHASE 3: AUTHENTICATION — First Impression

---

## 3.1 LoginScreen — Make It Premium

**BEFORE:** Static gradient background. "S" letter in an 80x80 box as logo. Form fields appear instantly. No animation. SnackBar for errors. Basic "Sign In" / "Sign Up" text links.

**AFTER:**
- **Background:** Subtle animated gradient (slow hue shift over 10s, barely perceptible — gives life without distraction)
- **Logo:** Animated entrance — scale from 0.8→1.0 + fade in (500ms, curveDecel). Consider a proper SVG logo instead of "S" in a box.
- **Form fields:** Staggered entrance — each field slides up + fades in with 100ms delay between them (field 1 at 300ms, field 2 at 400ms, button at 500ms)
- **Error handling:** Inline error below field (not SnackBar). Error text slides in + field border turns red. Shake animation on invalid submit (whole form shakes 3 cycles, 4px, 300ms).
- **Password field:** Eye icon to toggle visibility. Animated transition between obscured/visible.
- **Sign In button:** Full-width, 56px height, teal background. Press-down scale. Loading state with animated dots ("Signing in..."). Success state: flash green + navigate.
- **Keyboard handling:** `SingleChildScrollView` with `keyboardDismissBehavior: onDrag`. Fields scroll into view on focus.
- **"Sign Up" link:** Distinct styling — not hidden at bottom. Consider side-by-side tabs (Login | Sign Up) at top.

**FILES:** `lib/features/auth/view/login_screen.dart`
**SKILLS:** `animate` (stagger + logo), `onboard` (first impression), `clarify` (error messages), `harden` (keyboard, validation)

---

## 3.2 SignupScreen — Guided Flow

**BEFORE:** Copy of login with 4 fields. Same static gradient. Same "S" logo. Same SnackBar errors. "Signups disabled" message is a basic bordered container.

**AFTER:**
- Match LoginScreen redesign (same background, logo, stagger)
- Add **password strength indicator** — colored bar below password field (red→orange→yellow→green, animated width + color transition)
- Add **real-time validation** — green check icon appears inline as each field validates
- Confirm password: show match/mismatch indicator (check/x icon with color)
- If signups disabled: show a styled card with illustration, not plain text
- Consider combining Login + Signup into one screen with tab toggle at top

**FILES:** `lib/features/auth/view/signup_screen.dart`
**SKILLS:** `delight` (strength indicator), `clarify` (validation), `onboard` (flow)

---

## 3.3 ForgotPassword & ResetPassword

**BEFORE:** Basic form screens with no visual feedback beyond SnackBar.

**AFTER:**
- ForgotPassword: success state shows email illustration + "Check your inbox" message with animated mail icon
- ResetPassword: password requirements checklist (each requirement turns green with check animation as met)
- Auto-redirect to login after successful reset with countdown ("Redirecting in 3...")

**FILES:** `lib/features/auth/view/forgot_password_screen.dart`, `reset_password_update_screen.dart`
**SKILLS:** `clarify` (messaging), `delight` (success states), `onboard` (flow)

---

## 3.4 Maintenance, UpdateRequired, AccountRestricted

**BEFORE:** Basic text screens with no illustration. Maintenance is a dead-end.

**AFTER:**
- Each gets a distinct illustration (can be simple icon composition, not full illustration)
- Maintenance: animated "fixing" icon (wrench rotating slowly). "We'll be back soon" with estimated time if available. Auto-retry button.
- UpdateRequired: animated "update" icon. Direct link to app store.
- AccountRestricted: clear reason display. "Contact Support" button. Empathetic tone.

**FILES:** `lib/features/auth/view/maintenance_screen.dart`, `update_required_screen.dart`, `account_restricted_screen.dart`
**SKILLS:** `clarify` (messaging), `onboard` (helpful dead-end states)

---

# PHASE 4: HOME & DISCOVERY — The Main Stage

---

## 4.1 HomeScreen — Content-First Redesign

**BEFORE:** Basic greeting + avatar row. Static search field + filter button. Hardcoded category label mapping. AnimatedContainer on chips (200ms) is the only animation. Content is just DiscoveryTaskSliver (list of task cards).

**AFTER:**
- **Greeting:** Time-aware greeting with user's first name. Subtle fade-in on load.
- **Search bar:** Prominent, full-width. Tap expands to search screen (hero animation on search icon). Add voice search icon placeholder.
- **Category chips:** Horizontal scroll with snap behavior. Active chip: filled teal background. Inactive: outlined. Transition between states is animated (300ms, background color + text color crossfade). Remove hardcoded label mapping — pull from data.
- **Task feed:** Cards enter with staggered animation (each card slides up + fades, 50ms delay between cards). Pull-to-refresh with custom indicator (branded, not default Material).
- **Scroll behavior:** Search bar collapses/shrinks on scroll down, expands on scroll up (SliverAppBar-like behavior).
- **Empty state:** Illustrated "No projects found" with CTA to change filters or create a task.

**FILES:** `lib/features/home/view/home_screen.dart`, `widgets/filters_modal.dart`
**SKILLS:** `arrange` (layout hierarchy), `animate` (stagger + scroll), `onboard` (empty state), `delight` (pull-to-refresh)

---

## 4.2 FiltersModal — Smart Filtering

**BEFORE:** Basic bottom sheet with unknown content.

**AFTER:**
- DraggableScrollableSheet with snap points (50%, 85%)
- Category multi-select: grid of tappable pills with check animation
- Price range: dual-thumb slider with live value labels
- Sort options: segmented control (Newest, Price Low→High, Price High→Low, Most Popular)
- "Apply" button: filled teal, shows count of active filters ("Apply 3 filters")
- "Reset" button: text button, resets all with fade animation
- Active filters: show as removable chips below search bar on HomeScreen

**FILES:** `lib/features/home/view/widgets/filters_modal.dart`
**SKILLS:** `arrange` (filter layout), `clarify` (labels), `animate` (sheet + selections)

---

# PHASE 5: CARDS — The Most Visible Elements

> Cards appear on almost every screen. Getting these right transforms the entire app.

---

## 5.1 TaskCard — Complete Redesign

**BEFORE:** 120px colored header with gradient overlay + badges. Content section with title, description, footer. InkWell only. blurRadius=20 shadow. No press animation.

**AFTER:**
- **Remove 120px header** — it wastes space and looks template-y. Instead: compact card with image thumbnail (if exists) as small rectangle on left side (60x60, r12).
- **Layout:** Horizontal — thumbnail left, content middle, price right (like a modern list tile but richer)
- **Or for grid view:** Vertical — small thumbnail bar at top (80px), content below. Image fills with soft rounded corners (r16 top only).
- **Title:** bodyLarge, bold, maxLines 2, ellipsis overflow
- **Meta row:** category pill + deadline + bid count, all in captionBold, spaced with dots
- **Price:** h5, teal color, right-aligned. "IQD" prefix in caption size.
- **Status badge:** top-right corner, using redesigned StatusBadge
- **Press state:** ScaleButton wrapping entire card (0.96 scale). Card elevation moves from Level 1 → Level 2 on press.
- **Tap:** Container transform (OpenContainer) to TaskDetailsScreen
- **Bookmark button:** Heart icon with animated fill (scale bounce on tap)
- **Shadow:** Level 1 at rest (blur=4, offset=1)
- **Skeleton:** SkeletonTaskCard matches this exact layout

**FILES:** `lib/features/tasks/view/widgets/task_card.dart`
**SKILLS:** `arrange` (new layout), `animate` (press + bookmark), `normalize` (shadow level), `distill` (remove header bloat)

---

## 5.2 TenderTaskCard — Differentiated Identity

**BEFORE:** Left red accent bar (width=4). Content with tags, title, desc, footer. Hardcoded fontSize=10,11,13,16 scattered. Bookmark button positioned awkwardly. No animations.

**AFTER:**
- **Remove accent bar** — it adds noise without meaning. Use a subtle `info` colored left border only if needed for list differentiation.
- **Layout:** Match TaskCard base layout for consistency, but add: bid count chip (prominent, "12 bids"), deadline countdown (orange/red if < 24h remaining).
- **Tags:** Top of card, horizontal scroll if more than 2. Styled as small pills with category color tint.
- **Bookmark:** Positioned consistently (top-right of content area, not overlapping). Animated heart with haptic.
- **Price:** In `warning` color (gold) for tenders to differentiate from booking's teal.
- **Press state:** Same ScaleButton + elevation pattern as TaskCard.
- **Typography:** All from AppTypography — zero hardcoded fontSize values.

**FILES:** `lib/features/tasks/view/widgets/tender_task_card.dart`
**SKILLS:** `normalize` (consistent with task card), `colorize` (differentiation), `polish` (typography)

---

## 5.3 BookingTaskCard — Service Card Feel

**BEFORE:** 90px gradient header (teal→lightTeal). Avatar overlaps with Transform.translate(-24). Hardcoded "4.9" rating. "Book Now" button with shadow. Multiple hardcoded colors and sizes.

**AFTER:**
- **Remove Transform.translate hack** — use Stack with proper Positioned for avatar overlay if needed, or move avatar into content area entirely.
- **Layout:** Image/gradient banner (60px, subtle), then content: avatar (40x40) + name + rating inline. Title below. Tags. Price + "Book" CTA.
- **Rating:** Real data (not hardcoded 4.9). Star icon + number. Gold color.
- **"Book Now" button:** Small filled pill button (teal), 36px height. Animated scale on press.
- **Provider info:** Tap avatar → navigate to public profile (hero animation on avatar)
- **Featured badge:** Small "Featured" pill at top-left, animated entrance (fade+slide, 200ms)

**FILES:** `lib/features/tasks/view/widgets/booking_task_card.dart`
**SKILLS:** `distill` (remove Transform hack), `normalize` (consistent layout), `animate` (CTA + badge)

---

## 5.4 DashboardOfferCard — Status-Driven Design

**BEFORE:** Colored status header + avatar + info chips + conditional buttons (10+ conditions). Pulse animation on critical deadline but stops/starts abruptly. Buttons cramped in row.

**AFTER:**
- **Status header:** Thinner (40px), icon + label left, status badge right. Color from semantic tokens (not hardcoded).
- **Deadline countdown:** Smooth gradient from `success` → `warning` → `danger` as time decreases. Pulse only at critical level (< 2h), with proper ease-in-out curve.
- **Avatar:** 44px (consistent across all cards). Online indicator if available.
- **Info chips:** Redesign as inline tags with subtle background. Price chip gets teal tint, days chip gets neutral.
- **Action buttons:** Max 2 visible. Primary button full-width below card, secondary as text link. If more than 2 actions, use overflow menu (3-dot icon).
- **Loading state on buttons:** Spinner replaces text when action in progress. Button disabled during load.

**FILES:** `lib/features/tasks/view/widgets/dashboard_offer_card.dart`
**SKILLS:** `arrange` (button layout), `animate` (deadline gradient), `harden` (all status combos), `distill` (simplify conditionals)

---

## 5.5 BookingCard — Modern List Tile

**BEFORE:** Horizontal: 70x70 thumbnail + info column + price + chevron. Status badge too small (micro text). Hardcoded "$" formatting. No press feedback.

**AFTER:**
- **Thumbnail:** 64x64, r12. Shimmer placeholder on load. If no image: branded gradient background with category icon.
- **Info hierarchy:** Status badge first (prominent), title bold below, single meta line (date + provider name).
- **Price:** Right-aligned, bodyLarge, teal. No hardcoded "$" — use PriceFormatter.
- **Chevron → Arrow:** Replace boring chevron with a subtle animated arrow (slides right 4px on press, returns on release).
- **Press feedback:** ScaleButton + elevation shift. Entire card is tappable.
- **Status colors:** From semantic system. Consistent across all booking cards.

**FILES:** `lib/features/booking/view/widgets/booking_card.dart`
**SKILLS:** `arrange` (hierarchy), `normalize` (price formatting, status colors), `animate` (arrow)

---

## 5.6 DashboardBookingCard — Consistent with BookingCard

**BEFORE:** GlassCard with title + status + note + conditional buttons. TextButton for message has TODO onPressed.

**AFTER:**
- **Match BookingCard visual language** but optimized for dashboard context (more actions visible).
- **Note section:** Styled as a subtle info callout (left border accent, info color tint background). Not italic quotes — too subtle.
- **Buttons:** Primary action full-width (teal filled). Secondary actions as icon buttons in a row. Loading state on all buttons.
- **Implement Message button** (currently TODO) — opens chat with booking provider.

**FILES:** `lib/features/booking/view/widgets/dashboard_booking_card.dart`
**SKILLS:** `normalize` (match booking card), `harden` (implement TODO), `clarify` (button labels)

---

## 5.7 WorkItemCard — Unified Dashboard Card

**BEFORE:** GlassCard with colored header showing type (TASK/BOOKING/CUSTOM OFFER) + status. Avatar radius=12 (tiny). "Needs Review" badge with lightRed. No animations.

**AFTER:**
- **Type indicator:** Small icon + colored dot (not full-width header). Saves vertical space.
- **Avatar:** 36px (not 12px radius = 24px diameter — too small). With online dot.
- **"Needs Review" indicator:** Animated pulse badge (like notification) to draw attention. Uses `danger` semantic color.
- **Primary action button:** Contextual label, full-width, animated. Shows current required action clearly.
- **Progress indicator:** If work has stages (pending → in progress → delivered → completed), show a mini progress bar or step dots.
- **Due date:** Show as relative time ("Due in 2 days", "Overdue by 1 day"). Color-code: green if plenty of time, orange if soon, red if overdue.

**FILES:** `lib/features/dashboard/view/widgets/work_item_card.dart`
**SKILLS:** `arrange` (layout), `animate` (pulse + progress), `colorize` (time urgency), `clarify` (action labels)

---

## 5.8 DashboardCountersGrid — Animated + Interactive

**BEFORE:** 2-column grid, 4 GlassCards. Icon + large number (h3) + label. No animation. No empty/loading state. Static.

**AFTER:**
- **Animated count-up:** Numbers animate from 0 → actual value on first load (500ms, curveDecel). Using a custom `AnimatedCount` widget.
- **Icons:** Larger (32px), with subtle background circle (icon color at 10%). Icons should be meaningful and distinct per counter.
- **Tap interaction:** Scale feedback + navigate to relevant tab. Show a brief ripple.
- **Loading state:** Shimmer skeleton for each counter card.
- **Zero state:** Show "0" with muted color + different empty icon
- **Layout:** Keep 2-column grid. Add subtle divider or spacing that feels intentional. Consider making the top-priority counter span full width (optional).
- **Responsive:** On tablets, 4-column single row.

**FILES:** `lib/features/dashboard/view/widgets/dashboard_counters_grid.dart`
**SKILLS:** `animate` (count-up), `delight` (tap feedback), `adapt` (tablet), `onboard` (zero state)

---

# PHASE 6: CHAT & MESSAGING — Real-time Feel

---

## 6.1 MessagesScreen — Modern Inbox

**BEFORE:** Basic list with 6 skeleton tiles on load. Empty state: icon + text. Dismissible with red background. AlertDialog for delete confirm.

**AFTER:**
- **Search bar at top** — filter conversations by name/keyword
- **Unread conversations** — bold name + dark background tint + unread count badge (animated entrance)
- **Conversation tiles:** Staggered entrance animation on first load (each tile slides in from right, 30ms delay)
- **Swipe actions:** Left swipe = delete (red). Right swipe = archive (blue). Show action icon during swipe.
- **Delete confirmation:** Bottom sheet (not AlertDialog — more modern, less intrusive)
- **Empty state:** Illustrated "No conversations yet" with "Find Freelancers" CTA button
- **Pull-to-refresh:** Branded indicator
- **Online status:** Green dot on avatars of online users

**FILES:** `lib/features/chat/view/messages_screen.dart`
**SKILLS:** `arrange` (list layout), `animate` (stagger + swipe), `onboard` (empty state), `delight` (unread animation)

---

## 6.2 ConversationListTile — Rich Preview

**BEFORE:** AnimatedContainer (200ms) for unread state. Avatar 48x48 with tiny online dot (14x14). Basic text layout. Unread badge is 12x12 circle (too small).

**AFTER:**
- **Avatar:** 52x52 with proper online indicator (12px green circle with 2px white border)
- **Content:** Name (bold if unread) + last message preview (2 lines) + typing indicator ("typing..." with animated dots)
- **Time:** Right-aligned, caption style. "Just now", "2m", "1h", "Yesterday" — relative time
- **Unread badge:** Pill with count number (not just dot). Animated entrance (scale spring).
- **Pressed state:** Subtle background tint + scale. Navigate to ChatScreen.
- **Task context:** Small pill showing linked task/booking name (optional)

**FILES:** `lib/features/chat/view/widgets/conversation_list_tile.dart`
**SKILLS:** `polish` (alignment), `animate` (typing dots, badge), `clarify` (time formatting)

---

## 6.3 ChatScreen — Messaging Excellence

**BEFORE:** Basic message list. No date separators. No scroll-to-bottom. No swipe-to-reply. Basic input bar.

**AFTER:**
- **Message grouping:** Messages from same sender within 2 minutes grouped (remove avatar/name for consecutive, reduce spacing)
- **Date separators:** "Today", "Yesterday", "March 15" chips between day groups
- **Scroll-to-bottom FAB:** Appears when scrolled up > 2 screens. Shows unread count. Animated entrance (slide up + fade).
- **Input bar:** Redesigned — rounded container with: text field (expanding), attach button (left), send button (right, teal circle, animated scale on press). Send button morphs from grey→teal as text is typed.
- **Message sending:** Optimistic UI — message appears immediately with "sending" status, then transitions to "sent" → "delivered" → "read" with animated checkmarks.
- **Long-press message:** Context menu (copy, reply, delete) — use a nice popover, not AlertDialog.
- **Swipe-to-reply:** Swipe right on a message to reply, shows quoted message above input.

**FILES:** `lib/features/chat/view/chat_screen.dart`
**SKILLS:** `arrange` (grouping + input bar), `animate` (FAB + send + status), `delight` (swipe-to-reply), `harden` (long messages, emoji-only, links)

---

## 6.4 MessageBubble — From Basic to Beautiful

**BEFORE:** Align left/right. ConstrainedBox 75% width. r18/r4 asymmetric corners. 14px/10px padding. Hardcoded blue for read status. No grouping awareness.

**AFTER:**
- **Shape:** Slightly asymmetric corners (16px on 3 corners, 4px on sender-side corner). Subtle tail/pointer on first message in group.
- **Colors:** Sent = teal bubble with white text. Received = cardBackground with text color. NOT gradient text.
- **Grouped messages:** First in group: full bubble with tail + avatar. Middle: no avatar, reduced spacing (2px). Last: no avatar, normal spacing.
- **Status icons:** Animated transitions: sending (clock) → sent (single check) → delivered (double check) → read (double check, teal). Each transition fades in.
- **Time:** Inside bubble, bottom-right, micro text, slightly transparent.
- **Link detection:** URLs become tappable links with teal color + underline.
- **Emoji-only messages:** If message is 1-3 emoji only, display at 2x size without bubble background.
- **Image messages:** Rounded image within bubble, tap to full-screen.
- **Accessibility:** Semantics with sender name + message content + time + status.

**FILES:** `lib/features/chat/view/widgets/message_bubble.dart`
**SKILLS:** `polish` (shape + colors), `animate` (status transitions), `harden` (emoji, links, images, RTL, long text)

---

## 6.5 OfferMessageBubble — In-Chat Commerce

**BEFORE:** Unknown exact state but likely basic card within chat.

**AFTER:**
- **Distinct design:** Elevated card (Level 2 shadow) within chat, not a regular bubble. Gold/teal accent border.
- **Content:** Price large + bold. Description. Expiry timer. Sender info.
- **CTA buttons:** Accept (teal filled) + Decline (outlined). Counter-offer (text button).
- **Status:** Pending = gold border. Accepted = success/green. Declined = red, muted.
- **Animation:** Status change animates border color + shows check/x icon.

**FILES:** `lib/features/chat/view/widgets/offer_message_bubble.dart`
**SKILLS:** `colorize` (status), `animate` (status change), `clarify` (CTAs)

---

# PHASE 7: DASHBOARD — Command Center

---

## 7.1 DashboardScreen & OverviewTab

**BEFORE:** Basic TabBar with 5 tabs. AlertDialog for settings. Overview is greeting + wallet snapshot + counters + next actions + activity. No animations.

**AFTER:**
- **Tab bar:** Custom styled (not default Material). Pill-style indicator instead of underline. Horizontal scroll if tabs overflow.
- **Settings:** Bottom sheet (not AlertDialog). Role switcher as segmented control with animated slider.
- **Overview tab:**
  - Wallet snapshot card → redesigned hero card with animated balance (see Phase 12)
  - Counters → animated count-up grid (see 5.8)
  - Next actions → priority-sorted cards with urgency color coding + tap to navigate
  - Activity feed → timeline with vertical line + dots + staggered entrance
- **Tab transitions:** Fade + slide between tabs (not default TabBarView swipe)
- **Pull-to-refresh:** Per tab, with branded indicator

**FILES:** `lib/features/dashboard/view/dashboard_screen.dart`, `tabs/overview_tab.dart`
**SKILLS:** `arrange` (layout), `animate` (tab transitions, counter, timeline), `delight` (pull-to-refresh)

---

## 7.2 NextActionsList — Priority-Driven

**BEFORE:** Basic list with unknown content.

**AFTER:**
- **Priority indicators:** Left colored bar (danger=red, warning=orange, info=blue) based on urgency
- **Action clarity:** Each item has a clear CTA button ("Review Delivery", "Send Payment", "Respond to Offer")
- **Tap:** Navigate to relevant detail screen
- **Empty state:** "All caught up!" with check illustration + confetti-like dots
- **Staggered entrance:** Cards slide in from bottom, 50ms delay each

**FILES:** `lib/features/dashboard/view/widgets/next_actions_list.dart`
**SKILLS:** `colorize` (priority), `clarify` (CTAs), `onboard` (empty state), `animate` (stagger)

---

## 7.3 ActivityFeedPreview — Timeline Design

**BEFORE:** Basic expandable list. setState toggle for show more/less.

**AFTER:**
- **Timeline visual:** Vertical line connecting dots. Each dot colored by activity type.
- **Time grouping:** "Today", "Yesterday", "This Week" headers
- **Activity cards:** Icon + description + relative time + tap target
- **Expand/collapse:** Animated height change (not instant toggle)
- **Max items:** Show 3 by default, "View All" button expands with animation to show remaining

**FILES:** `lib/features/dashboard/view/widgets/activity_feed_preview.dart`
**SKILLS:** `arrange` (timeline), `animate` (expand/collapse), `polish` (grouping)

---

# PHASE 8: BOOKING & PAYMENTS

---

## 8.1 BookingsDiscoveryScreen & TendersScreen — Not Copy-Paste

**BEFORE:** Both are nearly identical screens — title + DiscoveryTaskSliver with different filter. No differentiation.

**AFTER:**
- **BookingsDiscovery:** Horizontal category filter. Grid layout (2 columns) using BookingTaskCard. Search bar. Sort options.
- **TendersScreen:** List layout using TenderTaskCard. Filter pills at top (Budget range, Category, Deadline). Sort by newest/most bids/highest budget.
- **Both:** Skeleton loading, empty states with distinct messaging, pull-to-refresh, staggered card entrance.
- **Visual distinction:** Bookings screen has a warmer feel (teal accents), Tenders has a more business feel (neutral with gold accents for prices).

**FILES:** `lib/features/booking/view/bookings_discovery_screen.dart`, `lib/features/tasks/view/tenders_screen.dart`
**SKILLS:** `arrange` (distinct layouts), `onboard` (empty states), `animate` (entrance)

---

## 8.2 BookingDetailsScreen & TaskDetailsScreen

**BEFORE:** Unknown exact layout but likely basic scrollable detail view.

**AFTER:**
- **Hero image/header:** If task has images, collapsing header with image (SliverAppBar + FlexibleSpaceBar). If not, gradient header with category icon.
- **Status progress:** Horizontal step indicator (dots connected by line) showing: Created → Confirmed → In Progress → Delivered → Completed
- **Info sections:** Glass cards for each section (Details, Provider/Client, Payment, Timeline)
- **Sticky bottom bar:** Action buttons (contextual) in glass container — "Contact", "Pay", "Cancel", etc.
- **Scroll behavior:** Sections lazy-load as scrolled into view (fade-in animation)
- **Back button:** Circular glass button overlaying header image

**FILES:** `lib/features/booking/view/booking_details_screen.dart`, `lib/features/tasks/view/task_details_screen.dart`
**SKILLS:** `arrange` (info architecture), `animate` (header collapse + section entrance), `polish` (consistent sections)

---

## 8.3 Payment Flow Screens

**BEFORE:** Basic checkout form. WebView for payment. Return screen with unknown design.

**AFTER:**
- **Checkout:** Order summary card (clear line items + total). Security badges. Payment method selector with saved cards.
- **WebView:** Loading progress bar at top. Error page with retry button if fails.
- **Payment Return:** Success = animated check + confetti. Failure = clear error + retry CTA. Pending = animated processing indicator.
- **All screens:** No back-navigation during processing (disable back button). Clear step indicator (Step 1 of 3).

**FILES:** `lib/features/booking/view/payment_*.dart`
**SKILLS:** `onboard` (flow clarity), `harden` (all error states), `animate` (success/failure), `clarify` (security messaging)

---

# PHASE 9: PROFILE — Personal Space

---

## 9.1 ProfileScreen — Not Just a Menu

**BEFORE:** ScrollView with avatar + name + hardcoded stats ("47", "4.9", "$12.5k"). Portfolio horizontal scroll. Menu items list. Dark mode toggle. Logout button with p100 bottom padding.

**AFTER:**
- **Header section:** Large avatar (80px) centered. Name + title below. Verified badge animated on load.
- **Stats row:** Real data from API. Animated count-up on first load. Tap each stat for detail.
- **Profile completion:** Progress ring around avatar showing % complete. Tappable to see missing items.
- **Quick actions:** "Edit Profile", "View Public Profile" as glass buttons side by side.
- **Portfolio preview:** Horizontal scroll with parallax-like depth effect. "See All" button.
- **Menu sections:** Grouped with section headers (Account, Work, App). Each tile has icon in colored circle + title + subtitle + trailing. Animated press state.
- **Dark mode:** Better toggle — segmented control (Light | Dark | System) instead of binary switch.
- **Logout:** Move inside Settings (not on main profile page). Dangerous action should be harder to reach.
- **Remove p100 bottom padding** — use proper safe-area bottom padding only.

**FILES:** `lib/features/profile/view/profile_screen.dart`
**SKILLS:** `arrange` (layout restructure), `animate` (stats count-up, completion ring), `distill` (move logout, reduce clutter), `delight` (parallax portfolio)

---

## 9.2 PublicProfileScreen — Showcase Profile

**BEFORE:** NestedScrollView with header + 4 tabs. Static layout. Bottom bar with Message + "Hire Now" (not implemented). Skills are plain containers.

**AFTER:**
- **Header:** Parallax effect on scroll (image/gradient moves slower than content). Avatar scales down into nav bar on scroll.
- **Stats:** Animated count-up (percentage, numbers). Progress-ring style for Job Success %.
- **Tab content:** Each tab lazy-loads with skeleton → content fade-in.
- **Skills:** Styled as interactive pills. Tap a skill → filter/search by that skill.
- **Portfolio tab:** Masonry grid with tap-to-lightbox. Smooth hero animation on image tap.
- **Reviews tab:** Rating distribution bar chart at top. Review cards with star rating, date, reviewer avatar.
- **Bottom bar:** Glass container. "Message" button always visible. "Hire Now" opens a booking sheet. Both animated.
- **Hire Now button:** Actually implement it. Opens a bottom sheet with service selection + date picker + price confirmation.

**FILES:** `lib/features/profile/view/public_profile_screen.dart`, `widgets/public_profile/*.dart`
**SKILLS:** `animate` (parallax, count-up, lightbox), `arrange` (reviews layout), `harden` (implement Hire Now)

---

## 9.3 EditProfileScreen — Smooth Editing

**BEFORE:** Form with GlassContainers. Skill chips with delete. "Add+" chip opens AlertDialog. Save button is basic FilledButton.

**AFTER:**
- **Inline validation:** Green check appears next to valid fields. Red error below invalid fields.
- **Skill input:** Replace AlertDialog with inline autocomplete field (type → suggestions appear → select). Chips animate entrance (scale spring).
- **Avatar editing:** Tap avatar → bottom sheet (Take Photo | Choose from Gallery | Remove). Upload shows progress ring around avatar.
- **Unsaved changes:** Back button shows confirmation sheet if changes exist.
- **Save animation:** Button shows success state (flash green + check) then pops screen.

**FILES:** `lib/features/profile/view/edit_profile_screen.dart`
**SKILLS:** `clarify` (validation), `animate` (chip entrance, save), `harden` (unsaved changes, upload errors)

---

## 9.4 SettingsScreen — Organized Preferences

**BEFORE:** Flat list of GlassContainer tiles. ALL CAPS section headers. Same visual for every item.

**AFTER:**
- **Section grouping:** Visual separators between groups (Preferences, Account, Support, About).
- **Section headers:** Overline style (uppercase, letterSpacing, muted color) — but smaller than current.
- **Tile variants:** Toggle tiles (switch), navigation tiles (arrow), action tiles (different colors).
- **Dangerous actions:** "Delete Account" and "Logout" in red, at bottom, with extra spacing.
- **Version info:** At very bottom, micro text, center-aligned. Build number on tap.
- **Toggles:** Custom styled switches (teal active track, not default Material).

**FILES:** `lib/features/profile/view/settings_screen.dart`
**SKILLS:** `arrange` (grouping), `normalize` (tile variants), `clarify` (labels), `harden` (dangerous actions)

---

# PHASE 10: PORTFOLIO

**BEFORE:** Basic masonry grid. Add/edit via bottom sheets. Image placeholder is static grey.

**AFTER:**
- **Grid:** Staggered masonry with varied heights based on image aspect ratio. Shimmer placeholders while loading.
- **Tile interaction:** Tap opens lightbox (hero animation). Title overlay fades in on press-down.
- **Add flow:** Sheet with drag-drop image upload area. Multi-image support. Title + description form. Category tag selector.
- **Edit:** Inline editing in detail sheet (not separate screen).
- **Reorder:** Long-press to drag and reorder portfolio items.
- **Image placeholder:** Shimmer animation (not static grey) + camera icon.

**FILES:** `lib/features/portfolio/view/*.dart`
**SKILLS:** `delight` (drag-drop, lightbox), `animate` (hero, shimmer), `arrange` (masonry)

---

# PHASE 11: PROPOSALS & DIRECT OFFERS

**BEFORE:** Unknown exact state. Likely basic list + detail views.

**AFTER:**
- **ProposalsListScreen:** Filter tabs (Sent, Received, All). Each tile shows status + price + time. Skeleton loading.
- **ProposalTile:** Avatar + name + price + status badge + time. Clear visual hierarchy.
- **SubmitProposalSheet:** Cover letter with character counter. Price input with formatting. Timeline selector (calendar). Attach portfolio items.
- **DirectOfferDetailsScreen:** Card with all offer details. Accept/Decline/Counter as distinct styled buttons. Status timeline showing offer lifecycle.

**FILES:** `lib/features/proposals/view/*.dart`, `lib/features/direct_offers/view/*.dart`
**SKILLS:** `arrange` (list + detail), `clarify` (form labels), `animate` (status transitions), `harden` (all states)

---

# PHASE 12: WALLET — Premium Feel

---

## 12.1 WalletHeroCard — Animated + Premium

**BEFORE:** Gradient (darkTeal→teal→lightTeal) with decorative orbs (static circles). AnimatedPositioned for balance bar (450ms). Balance text at 34px/w900.

**AFTER:**
- **Background:** Keep gradient but add subtle animated glow orbs (slow float animation, 8s cycle, gentle movement)
- **Balance:** Animated count-up on first load (from 0 → actual, 800ms, curveDecel). On balance change, animate from old→new value.
- **Balance composition bar:** Smooth animated segments. Tap a segment → show breakdown tooltip.
- **Chips:** Tap to filter transactions by type. Active chip gets filled style.
- **Card entrance:** Slide up + fade in on screen load (500ms, staggered after greeting).

**FILES:** `lib/features/wallet/view/widgets/wallet_hero_card.dart`
**SKILLS:** `animate` (orbs, count-up, entrance), `delight` (tooltip, chip interaction), `polish` (premium feel)

---

## 12.2 WalletTimelineCard — Transaction History

**BEFORE:** Unknown exact state.

**AFTER:**
- **Transaction entries:** Icon (type-specific), description, amount (+green / -red), date.
- **Grouping:** By date (Today, Yesterday, March 2026, etc.)
- **Amount animation:** Count-up for each visible transaction on scroll-into-view.
- **Pull-to-refresh + infinite scroll** for pagination.
- **Filter bar:** By type (All, Incoming, Outgoing, Escrow).

**FILES:** `lib/features/wallet/view/widgets/wallet_timeline_card.dart`
**SKILLS:** `arrange` (transaction layout), `colorize` (income/expense), `animate` (scroll-triggered count-up)

---

# PHASE 13: WORK MANAGEMENT

**BEFORE:** WorkItemDetailsScreen with basic layout. Modals for submit/review delivery and request extension. No animations.

**AFTER:**
- **Detail screen:** Status progress stepper at top (animated step progression). Sections: task details, booking details, delivery area, timeline.
- **Submit delivery modal:** File upload area with drag indicator. Description. Preview before submit. Animated submit button.
- **Review delivery modal:** Star rating with animated fill (tap + drag). Feedback text area. Approve/request changes buttons.
- **Extension request modal:** Reason picker + new date selector + message field. Clear approval/denial flow.
- **Status transitions:** When status changes, animate progress stepper and show success state briefly.

**FILES:** `lib/features/work/view/*.dart`, `lib/features/management/view/*.dart`
**SKILLS:** `animate` (stepper, rating), `clarify` (form labels), `harden` (all status combos)

---

# PHASE 14: NOTIFICATIONS — Attention-Worthy

---

## 14.1 NotificationsModal — Grouped + Animated

**BEFORE:** DraggableScrollableSheet with basic list. "Mark all as read" TextButton. Dividers between items. No entrance animation.

**AFTER:**
- **Snap points:** 50%, 75%, 95% with spring physics.
- **Grouping:** "New" and "Earlier" sections with headers.
- **Notification tiles:** Icon (type-colored circle) + title + description + relative time + unread dot.
- **Unread → Read transition:** Animated background color change (fade, 200ms).
- **Mark all as read:** Animated — all unread dots disappear in a stagger (50ms between each).
- **Swipe to dismiss:** Individual notifications can be swiped away.
- **Empty state:** "All caught up!" with check icon.
- **Entrance:** Tiles stagger in from bottom on modal open.

**FILES:** `lib/features/notifications/view/notifications_modal.dart`, `widgets/notification_tile.dart`
**SKILLS:** `animate` (stagger, read transition, swipe), `arrange` (grouping), `onboard` (empty state)

---

## 14.2 NotificationBadgeButton — Attention Getter

**BEFORE:** Static 10x10 red dot.

**AFTER:**
- **Badge:** Shows count (max "99+"). Red pill with white text.
- **Entrance:** Scale spring animation when count changes from 0→N.
- **Increment:** Brief scale pulse (1.0→1.2→1.0) when count increases.
- **Bell icon:** Subtle rotation animation (like a bell ringing) when new notification arrives.

**FILES:** `lib/features/notifications/view/widgets/notification_badge_button.dart`
**SKILLS:** `animate` (all badge states), `delight` (bell ring)

---

# PHASE 15: SECONDARY SCREENS

---

## 15.1 Saved & Favorites

**AFTER:** Empty states with illustration + CTA. Remove animation (item fades + slides out). Consistent card styling. Pull-to-refresh.

## 15.2 Categories

**AFTER:** Grid of category cards with icon + name + item count. Colored icon backgrounds (each category gets a subtle tint). Tap animation. Search at top.

## 15.3 Search

**AFTER:** Prominent search bar (auto-focus on entry). Recent searches. Live suggestions as typing. Result cards: profile card with avatar + name + rating + skills + price. Loading shimmer. No results state with suggestions.

## 15.4 Services

**AFTER:** ServiceCard redesign: image, title, provider, price, rating. Grid/list toggle. Filter by category.

**FILES:** All files in `saved/`, `favorites/`, `categories/`, `search/`, `services/`
**SKILLS:** `onboard` (empty states), `animate` (remove animation, search), `arrange` (grids), `normalize` (card consistency)

---

# PHASE 16: CROSS-CUTTING QUALITY

---

## 16.1 Empty States — Every Screen

Audit every list/grid/feed screen. Each gets:
- Relevant icon or mini-illustration (not just generic folder_open)
- Descriptive text explaining WHY it's empty + WHAT to do
- CTA button if there's an action they can take
- Consistent layout: icon (48px) + title (bodyLarge) + description (bodySmall, secondary) + button
- Screens: Home, Tenders, Bookings, Messages, Notifications, Favorites, Saved, Proposals, Wallet, Dashboard tabs, Search (no results), Portfolio, Services

**SKILL:** `onboard`

---

## 16.2 Loading States — Shimmer Everything

Replace every `Center(CircularProgressIndicator())` with content-matched shimmer skeletons.
- Every list screen: show 3-5 skeleton cards matching the real card layout
- Every detail screen: show skeleton header + skeleton body sections
- Every form: skeleton fields (rare, but good for slow data pre-fill)
- Stagger shimmer timing: slight delay between cards for wave effect

**SKILL:** `delight` + `extract`

---

## 16.3 Error States — Helpful Recovery

Replace every generic "Something went wrong" with:
- Contextual message: "Couldn't load your bookings" (not "Error occurred")
- Reason hint: "Check your internet connection" or "Please try again later"
- Retry button: "Try Again" (not "OK")
- Network error: offline illustration + auto-retry when connection restores
- Auth expired: "Session expired" + "Sign In Again" button (navigates to login)

**SKILL:** `clarify` + `harden`

---

## 16.4 Dark Mode — Full Audit

Toggle dark mode, test every screen:
- Glass effects visible but not overwhelming
- Text contrast minimum 4.5:1 (body) and 3:1 (large text)
- Images don't look washed out
- Status colors remain distinguishable
- Shadows adapt (lighter shadows on dark, using white alpha not black alpha)
- Borders visible but subtle

**SKILL:** `audit` + `colorize`

---

## 16.5 Accessibility — From Zero to Compliant

Add to every interactive element:
- `Semantics` widget with appropriate labels
- Minimum 48px touch targets (audit all CircleIconButtons, chips, small buttons)
- Focus rings on all tappable elements (for keyboard/switch access)
- Screen reader announcements for state changes (loading, error, success)
- Contrast ratio verification on all text/background combos

**SKILL:** `harden` + `audit`

---

## 16.6 Haptic Feedback — Physical Feel

Add `HapticFeedback` calls to:
- `lightImpact()`: button taps, card taps, nav bar taps
- `selectionClick()`: toggle switches, tab changes, filter selections
- `mediumImpact()`: successful actions (payment complete, message sent)
- `heavyImpact()`: destructive actions (delete confirmation)
- Respect `MediaQuery.disableAnimations` — skip haptics if reduced motion enabled

**SKILL:** `delight`

---

# MASTER FILE INDEX (134 files)

| Priority | File | Phase | Key Change |
|----------|------|-------|------------|
| **P0** | `lib/core/theme/app_motion.dart` | 0.1 | NEW — animation tokens |
| **P0** | `lib/core/theme/app_states.dart` | 0.2 | NEW — interaction states |
| **P0** | `lib/core/theme/app_decorations.dart` | 0.3 | Shadow scale system |
| **P0** | `lib/core/theme/app_typography.dart` | 0.4 | Line heights + letter spacing |
| **P0** | `lib/core/theme/app_colors.dart` | 0.5 | Semantic color tokens |
| **P0** | `lib/core/theme/app_theme.dart` | 0.6 | Component themes |
| **P0** | `lib/core/widgets/app_button.dart` | 1.1 | 8 states + haptics |
| **P0** | `lib/core/widgets/app_text_field.dart` | 1.2 | Error shake + clear + toggle |
| **P0** | `lib/core/widgets/glass_container.dart` | 1.7 | Performance + intensity levels |
| **P0** | `lib/core/widgets/custom_bottom_nav_bar.dart` | 1.5 | Labels + badge count animation |
| **P0** | `lib/core/widgets/signed_avatar.dart` | 1.6 | Shimmer + fade-in + initials fallback |
| **P0** | `lib/core/widgets/scale_button.dart` | 1.4 | Spring physics + haptics |
| **P0** | `lib/app/main_navigation_screen.dart` | 2.1 | Shared-axis transitions |
| **P0** | `lib/features/auth/view/login_screen.dart` | 3.1 | Staggered entrance + inline errors |
| **P0** | `lib/features/auth/view/signup_screen.dart` | 3.2 | Password strength + real-time validation |
| **P0** | `lib/features/home/view/home_screen.dart` | 4.1 | Content-first + staggered cards |
| **P0** | `lib/features/tasks/view/widgets/task_card.dart` | 5.1 | Complete card redesign |
| **P0** | `lib/features/tasks/view/tenders_screen.dart` | 8.1 | Distinct from bookings |
| **P0** | `lib/features/tasks/view/task_details_screen.dart` | 8.2 | Collapsing header + status progress |
| **P0** | `lib/features/chat/view/messages_screen.dart` | 6.1 | Modern inbox |
| **P0** | `lib/features/chat/view/chat_screen.dart` | 6.3 | Grouping + scroll FAB + input redesign |
| **P0** | `lib/features/chat/view/widgets/message_bubble.dart` | 6.4 | Grouped + status animations |
| **P0** | `lib/features/dashboard/view/dashboard_screen.dart` | 7.1 | Custom tabs + animated overview |
| **P0** | `lib/features/dashboard/view/tabs/overview_tab.dart` | 7.1 | Animated sections |
| **P0** | `lib/features/dashboard/view/widgets/dashboard_counters_grid.dart` | 5.8 | Animated count-up |
| **P0** | `lib/features/booking/view/booking_details_screen.dart` | 8.2 | Status progress + sections |
| **P0** | `lib/features/booking/view/bookings_discovery_screen.dart` | 8.1 | Grid layout + filters |
| **P0** | `lib/features/profile/view/profile_screen.dart` | 9.1 | Completion ring + real stats |
| **P0** | `lib/features/profile/view/public_profile_screen.dart` | 9.2 | Parallax + implement Hire Now |
| **P0** | `lib/features/notifications/view/notifications_modal.dart` | 14.1 | Grouped + staggered |
| **P0** | `lib/features/notifications/view/widgets/notification_badge_button.dart` | 14.2 | Count + bell ring |
| **P0** | `lib/features/work/view/work_item_details_screen.dart` | 13 | Status stepper |
| **P1** | `lib/core/widgets/glass_button.dart` | 1.5 | Contrast + states |
| **P1** | `lib/core/widgets/glass_card.dart` | 1.6 | Elevation variants |
| **P1** | `lib/core/widgets/circle_icon_button.dart` | 1.3 | Tooltip + 48px target |
| **P1** | `lib/core/widgets/skeleton_card.dart` | 1.7 | 8 new skeleton variants |
| **P1** | `lib/core/widgets/status_badge.dart` | 1.8 | Icons + semantic colors + pulse |
| **P1** | `lib/core/widgets/skeleton_loader.dart` | 1.7 | Intensity + dark mode |
| **P1** | `lib/core/widgets/sliver_tab_bar_delegate.dart` | 1.8 | Blur when pinned |
| **P1** | `lib/core/utils/transitions.dart` | 2.2 | Container transform + shared axis |
| **P1** | `lib/features/tasks/view/widgets/tender_task_card.dart` | 5.2 | Match system + differentiate |
| **P1** | `lib/features/tasks/view/widgets/booking_task_card.dart` | 5.3 | Remove transform hack |
| **P1** | `lib/features/tasks/view/widgets/dashboard_offer_card.dart` | 5.4 | Simplified actions |
| **P1** | `lib/features/tasks/view/create_task_screen.dart` | 5.7 | Step wizard + image upload |
| **P1** | `lib/features/booking/view/widgets/booking_card.dart` | 5.5 | Modern list tile |
| **P1** | `lib/features/booking/view/widgets/dashboard_booking_card.dart` | 5.6 | Implement Message button |
| **P1** | `lib/features/booking/view/payment_checkout_screen.dart` | 8.3 | Clear checkout flow |
| **P1** | `lib/features/chat/view/widgets/conversation_list_tile.dart` | 6.2 | Rich preview |
| **P1** | `lib/features/chat/view/widgets/offer_message_bubble.dart` | 6.5 | In-chat commerce card |
| **P1** | `lib/features/chat/view/widgets/create_offer_sheet.dart` | 6.6 | Price formatting |
| **P1** | `lib/features/dashboard/view/widgets/next_actions_list.dart` | 7.2 | Priority-driven |
| **P1** | `lib/features/dashboard/view/widgets/activity_feed_preview.dart` | 7.3 | Timeline design |
| **P1** | `lib/features/dashboard/view/widgets/work_item_card.dart` | 5.7 | Progress indicator |
| **P1** | `lib/features/dashboard/view/tabs/bookings_tab.dart` | 7.4 | Empty + skeleton + refresh |
| **P1** | `lib/features/dashboard/view/tabs/inbox_tab.dart` | 7.4 | Empty + skeleton + refresh |
| **P1** | `lib/features/dashboard/view/tabs/wallet_tab.dart` | 7.4 | Empty + skeleton + refresh |
| **P1** | `lib/features/dashboard/view/tabs/work_tab.dart` | 7.4 | Empty + skeleton + refresh |
| **P1** | `lib/features/profile/view/edit_profile_screen.dart` | 9.3 | Inline validation |
| **P1** | `lib/features/profile/view/settings_screen.dart` | 9.4 | Grouped + themed |
| **P1** | `lib/features/profile/view/manage_portfolio_screen.dart` | 9.5 | Drag-reorder |
| **P1** | `lib/features/profile/view/widgets/profile_avatar_widget.dart` | 9.3 | Upload progress ring |
| **P1** | `lib/features/wallet/view/wallet_dashboard_screen.dart` | 12.1 | Premium feel |
| **P1** | `lib/features/wallet/view/widgets/wallet_hero_card.dart` | 12.1 | Animated orbs + count-up |
| **P1** | `lib/features/wallet/view/widgets/wallet_timeline_card.dart` | 12.2 | Transaction history |
| **P1** | `lib/features/proposals/view/proposals_list_screen.dart` | 11 | Filter tabs |
| **P1** | `lib/features/proposals/view/widgets/proposal_tile.dart` | 11 | Visual hierarchy |
| **P1** | `lib/features/proposals/view/widgets/submit_proposal_sheet.dart` | 11 | Rich form |
| **P1** | `lib/features/direct_offers/view/direct_offer_details_screen.dart` | 11 | Status timeline |
| **P1** | `lib/features/work/view/widgets/submit_delivery_modal.dart` | 13 | File upload + preview |
| **P1** | `lib/features/work/view/widgets/review_delivery_modal.dart` | 13 | Animated star rating |
| **P1** | `lib/features/search/view/search_screen.dart` | 15.3 | Live suggestions |
| **P1** | `lib/features/search/view/widgets/search_result_profile_card.dart` | 15.3 | Rich result card |
| **P1** | `lib/features/categories/view/categories_screen.dart` | 15.2 | Icon grid |
| **P1** | `lib/features/notifications/view/widgets/notification_tile.dart` | 14.1 | Type icon + read animation |
| **P2** | `lib/features/auth/view/forgot_password_screen.dart` | 3.3 | Success illustration |
| **P2** | `lib/features/auth/view/reset_password_update_screen.dart` | 3.4 | Requirements checklist |
| **P2** | `lib/features/auth/view/maintenance_screen.dart` | 3.5 | Animated icon |
| **P2** | `lib/features/auth/view/update_required_screen.dart` | 3.5 | Store link CTA |
| **P2** | `lib/features/auth/view/account_restricted_screen.dart` | 3.6 | Support CTA |
| **P2** | `lib/features/home/view/widgets/filters_modal.dart` | 4.2 | Smart filters |
| **P2** | `lib/features/tasks/view/widgets/requests/*.dart` (4 files) | 5.8 | Consistent tiles |
| **P2** | `lib/features/tasks/view/widgets/expiration_countdown.dart` | 5.9 | Color progression |
| **P2** | `lib/features/tasks/view/widgets/payment_status_badge.dart` | 5.9 | Use StatusBadge |
| **P2** | `lib/features/tasks/view/tender_payment_screen.dart` | 5.10 | Match payment flow |
| **P2** | `lib/features/chat/view/widgets/chat_context_widget.dart` | 6.7 | Task/booking link |
| **P2** | `lib/features/chat/attachments/widgets/attachment_message_tile.dart` | 6.7 | File type handling |
| **P2** | `lib/features/booking/view/bookings_list_screen.dart` | 8.2 | Status tabs |
| **P2** | `lib/features/booking/view/payment_method_screen.dart` | 8.3 | Saved cards |
| **P2** | `lib/features/booking/view/payment_return_screen.dart` | 8.3 | Success/failure states |
| **P2** | `lib/features/booking/view/payment_webview_screen.dart` | 8.3 | Progress bar |
| **P2** | `lib/features/booking/view/widgets/payment_order_summary_card.dart` | 8.3 | Line items |
| **P2** | `lib/features/profile/view/my_services_screen.dart` | 9.5 | Empty state |
| **P2** | `lib/features/profile/view/widgets/profile_preview_modal.dart` | 9.5 | Smooth physics |
| **P2** | `lib/features/profile/view/widgets/public_profile/*.dart` (4 files) | 9.2 | Polish each |
| **P2** | `lib/features/portfolio/view/*.dart` (6 files) | 10 | Masonry + lightbox |
| **P2** | `lib/features/proposals/view/proposal_details_modal.dart` | 11 | Full detail |
| **P2** | `lib/features/proposals/view/proposal_payment_screen.dart` | 11 | Match payment flow |
| **P2** | `lib/features/wallet/view/wallet_screen.dart` | 12.2 | Full history |
| **P2** | `lib/features/wallet/view/widgets/wallet_shared_body.dart` | 12.2 | Shared layout |
| **P2** | `lib/features/wallet/view/widgets/wallet_snapshot_card.dart` | 12.2 | Sparkline chart |
| **P2** | `lib/features/work/view/widgets/request_extension_modal.dart` | 13 | Date + reason |
| **P2** | `lib/features/work/view/widgets/work_item_booking_details.dart` | 13 | Consistent card |
| **P2** | `lib/features/work/view/widgets/work_item_bottom_actions.dart` | 13 | Context-aware |
| **P2** | `lib/features/work/view/widgets/work_item_guard_widgets.dart` | 13 | Clear messaging |
| **P2** | `lib/features/management/view/*.dart` (3 files) | 13.4 | Admin layout |
| **P2** | `lib/features/saved/view/*.dart` (2 files) | 15.1 | Empty + remove anim |
| **P2** | `lib/features/favorites/view/*.dart` (2 files) | 15.2 | Empty + unfavorite anim |
| **P2** | `lib/features/services/view/widgets/service_card.dart` | 15.4 | Marketplace card |
| **P3** | `lib/core/theme/theme_dashboard.dart` | 0.5 | Update reference doc |
| **P3** | `lib/features/tasks/view/widgets/booking_logistics_section.dart` | 5.9 | Polish |
| **P3** | `lib/features/tasks/view/widgets/discovery_task_sliver.dart` | 5.9 | Skeleton loading |
| **P3** | `lib/features/tasks/view/widgets/task_concept_section.dart` | 5.9 | Polish |

---

# EXECUTION ORDER

```
Step 1:  Phase 0 (theme foundation)           — 2 new files + 4 updated files
Step 2:  Phase 1 (core widgets)               — 14 files
Step 3:  Phase 2 (navigation shell)           — 3 files
Step 4:  Phase 3 (auth screens)               — 7 files
Step 5:  Phase 5 (cards)                      — 8 card files (impacts all screens)
Step 6:  Phase 4 (home + discovery)           — 2 files
Step 7:  Phase 6 (chat)                       — 7 files
Step 8:  Phase 7 (dashboard)                  — 10 files
Step 9:  Phase 8 (booking + payments)         — 10 files
Step 10: Phase 9 (profile)                    — 12 files
Step 11: Phase 10-15 (remaining features)     — ~30 files
Step 12: Phase 16 (cross-cutting quality)     — audit pass on all 134 files
Step 13: flutter analyze + flutter test       — must pass clean
```

---

# ANTI-PATTERNS TO NEVER USE

1. **NO** bounce/elastic easing — use ease-out curves only
2. **NO** glassmorphism / frosted glass / BackdropFilter blur — ANYWHERE. Use solid surfaces (`cardBackground` + `cardBorder` + `elevation()` shadow). See `.impeccable.md` NO GLASS POLICY.
3. **NO** gradient text — ever
4. **NO** purple-to-blue gradients — stick to teal brand
5. **NO** hardcoded Color(0xFF...) — use AppColors.* or context.colorScheme.*
6. **NO** hardcoded TextStyle() — use AppTypography.*
7. **NO** hardcoded spacing values — use AppDimens.*
8. **NO** hardcoded animation durations — use AppMotion.*
9. **NO** print() — use AppLogger.*
10. **NO** CircularProgressIndicator for list loading — use shimmer skeletons
11. **NO** AlertDialog for confirmations — use bottom sheets (more modern, less intrusive)
12. **NO** SnackBar for form errors — use inline error messages below fields

---

**Total scope: 134 files | 16 phases | 20+ skills available**
**Priority: 32 P0 files → 38 P1 files → 50 P2 files → 14 P3 files**
