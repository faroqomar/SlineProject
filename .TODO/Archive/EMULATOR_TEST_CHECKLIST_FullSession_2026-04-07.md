# Emulator Test Checklist — Full Session (Phase 0 + Phase 1)
> Covers ALL work from this session: 6 theme files + 14 widgets + 32 feature files + 3 architecture fixes
> Run: `/Users/eros/Dev/flutter/bin/flutter run` on iPhone simulator
> Date: 2026-04-07

---

## PRE-FLIGHT

- [ ] `flutter analyze` — must show "No issues found"
- [ ] `flutter test` — 1282 passed, 30 skipped, 1 pre-existing failure
- [ ] App launches on iPhone simulator without crash
- [ ] App defaults to **dark mode**

---

## SECTION 1: TYPOGRAPHY (Phase 0 — Line Height Changes)

Body text line heights changed from 1.2 → 1.5 (25% taller). Check every screen for overflow.

### Auth Screens
- [ ] **Login screen** — email/password field hints readable, no text clipping
- [ ] **Login screen** — "Sign in to continue" subtitle spacing comfortable
- [ ] **Signup screen** — all 4 field labels readable, no overflow

### Home Screen
- [ ] **Greeting text** ("Good morning, Name") — proper spacing
- [ ] **Search bar hint** — text not clipped
- [ ] **Category chips** — label text fits inside pill shape
- [ ] **Task cards** — title and description have comfortable line spacing, no overflow

### Chat / Messages
- [ ] **Conversation list** — name + last message text spaced well, not cramped
- [ ] **Message bubbles** — text readable, no text clipping at bubble edges
- [ ] **Message input** — hint text normal height

### Dashboard
- [ ] **Tab labels** (Overview, Bookings, Work, Wallet, Inbox) — all fit, not truncated
- [ ] **Counter grid** — numbers and labels spaced well
- [ ] **Next Actions / Activity** — section text readable

### Profile
- [ ] **Profile name + bio** — comfortable spacing
- [ ] **Menu tile** titles and subtitles — no cramping
- [ ] **Settings screen** — all tile text readable
- [ ] **Edit Profile** — form field labels + values spaced well

### Task/Booking Details
- [ ] **Description text** — body text comfortable to read (not cramped like before)
- [ ] **Section headers** (h5) — properly spaced from content below
- [ ] **Price and status** text — readable

---

## SECTION 2: NO GLASS — Solid Surfaces (Phase 1 — Most Critical Visual Change)

Glass/blur effects (BackdropFilter) were completely removed. Every screen that used GlassContainer, GlassCard, or GlassButton now shows solid backgrounds.

### Bottom Navigation Bar (HIGHEST VISIBILITY)
- [ ] **Bottom nav bar** is visible with **solid background** (NOT frosted/blurry)
- [ ] **Bottom nav bar** has a subtle border and shadow (elevation 3)
- [ ] **Bottom nav bar** does NOT have blur behind it — content behind should NOT be blurred
- [ ] **Nav bar icons** visible and correctly colored (teal when active, grey when inactive)
- [ ] **Nav bar labels** appear below each icon (tiny text, bolder when active)
- [ ] **Tapping a nav item** produces haptic feedback (physical click sensation)
- [ ] **Active pill indicator** animates smoothly on tab switch
- [ ] **Messages badge** shows (if unread messages exist)

### Cards Across the App
Every screen with cards should show **solid colored cards** (NOT semi-transparent glass):

- [ ] **Home** — task cards have solid `cardBackground`, subtle border, light shadow
- [ ] **Dashboard counters** — 4 counter cards are solid, not glass
- [ ] **Dashboard work items** — work item cards are solid
- [ ] **Dashboard booking cards** — solid background
- [ ] **Wallet** — wallet hero card visible (still has gradient, that's OK — it's not glass)
- [ ] **Wallet** — timeline cards, snapshot cards are solid
- [ ] **Search** — search result cards are solid
- [ ] **Profile** — all menu tiles and info sections are solid containers
- [ ] **Settings** — all settings tiles are solid containers
- [ ] **Edit Profile** — form containers (Basic Info, Skills) are solid
- [ ] **Public Profile** — info sections, bottom action bar are solid
- [ ] **Chat** — chat context widget is solid
- [ ] **Task Details** — all info sections are solid
- [ ] **Booking Details** — all info sections are solid
- [ ] **Direct Offer Details** — all sections are solid
- [ ] **Work Item Details** — all sections are solid
- [ ] **Notifications modal** — modal container is solid
- [ ] **Proposals modal** — container is solid
- [ ] **Portfolio manage** — items are solid
- [ ] **Order management** — panel sections are solid
- [ ] **Service cards** — solid background

### Dark Mode Specific
- [ ] **Toggle to dark mode** in Settings (if not already default)
- [ ] **Cards** — solid dark background visible against dark scaffold (not invisible)
- [ ] **Card borders** — subtle but visible in dark mode
- [ ] **Card shadows** — reduced intensity in dark mode (intentional, not invisible)
- [ ] **Text on cards** — readable (light text on dark card)

### Light Mode Specific
- [ ] **Toggle to light mode** in Settings
- [ ] **Cards** — solid white/off-white background
- [ ] **Card borders** — subtle teal tint visible
- [ ] **Card shadows** — slightly more visible than dark mode
- [ ] **Text on cards** — dark text readable

---

## SECTION 3: BUTTON INTERACTIONS (Phase 1 — AppButton + ScaleButton)

### Scale/Press Feedback
- [ ] **Any button tap** — button scales down slightly (0.96) on press, bounces back on release
- [ ] **Any button tap** — produces haptic feedback (light click sensation)
- [ ] **Card taps** (where tappable) — same scale effect
- [ ] **Nav bar taps** — same haptic click
- [ ] **No bounce/elastic** — the animation should feel smooth, not bouncy

### AppButton States
- [ ] **Normal button** — solid teal background, white text, subtle shadow
- [ ] **Loading button** — when an action is in progress, button shows spinner (small white circle), same size as before
- [ ] **Disabled button** — reduced opacity (~38%), not tappable
- [ ] **Button with icon** — icon appears next to text

### Test Button Locations
- [ ] **Login "Sign In"** button — tappable, shows loading during auth
- [ ] **Signup "Sign Up"** button — same
- [ ] **Create Task** FAB — press produces rotation animation + haptic
- [ ] **Task Details action buttons** — tappable with feedback
- [ ] **Booking Details action buttons** — tappable with feedback
- [ ] **Chat "Send" area** — functional
- [ ] **Edit Profile "Save Changes"** — shows loading, then navigates back

---

## SECTION 4: TEXT FIELD FEATURES (Phase 1 — AppTextField)

### Password Toggle
- [ ] **Login password field** — if `showPasswordToggle` is enabled, eye icon visible
- [ ] **Tap eye icon** — password text becomes visible/hidden
- [ ] **Eye icon toggles** between visibility_off and visibility icons

### Clear Button (if enabled on any screen)
- [ ] When text is entered, X icon appears in the suffix area
- [ ] Tapping X clears the field
- [ ] X disappears when field is empty

### General Field Behavior
- [ ] Fields accept text input normally
- [ ] Validation errors show below fields (not just SnackBar)
- [ ] Cursor color is teal

---

## SECTION 5: AVATAR & IMAGE LOADING (Phase 1 — SignedAvatar + SignedImage)

### SignedAvatar
- [ ] **Profile avatar** — shows shimmer animation while loading (NOT spinner)
- [ ] **Avatar loaded** — fades in smoothly
- [ ] **Missing avatar** — shows person icon (or initials if configured)
- [ ] **Other user avatars** (in chat list, cards) — same shimmer → fade-in pattern
- [ ] **No CircularProgressIndicator** on any avatar (should be shimmer instead)

### SignedImage
- [ ] **Task images** — show shimmer rectangle while loading (NOT spinner)
- [ ] **Image loaded** — fades in smoothly
- [ ] **Image load failure** — shows "Tap to retry" with icon
- [ ] **Tapping retry** — re-attempts image load
- [ ] **No CircularProgressIndicator** on any image (should be shimmer instead)

---

## SECTION 6: STATUS BADGES (Phase 1 — StatusBadge)

### Visual Changes
- [ ] **Status badges** are now **pill-shaped** (rounded stadium, NOT rectangular)
- [ ] **Each badge has an icon** next to the text:
  - Completed/Delivered → check_circle icon (green)
  - Pending/Draft → schedule icon (amber/gold)
  - Canceled/Declined → cancel icon (red)
  - Active/In Progress → play_circle icon (blue)
  - Confirmed → verified icon (blue)
- [ ] **Colors are semantic** — green for success, red for danger, amber for warning, blue for info
- [ ] **Pending badges** — subtle pulse animation (3 times then stops)

### Where to Check
- [ ] **Dashboard work items** — each card has a status badge
- [ ] **Task Details** — status badge at top
- [ ] **Booking Details** — status badge
- [ ] **Booking list** — each booking card has badge
- [ ] **Work Item Details** — status progression

---

## SECTION 7: COMPONENT THEMES (Phase 0 — Global Defaults)

### Dialogs
- [ ] **Any dialog** (e.g., logout confirm in Settings, Add Skill in Edit Profile)
- [ ] Dialog has **rounded corners (r24)** — not sharp Material default
- [ ] Dialog background matches card color
- [ ] Dialog has no visible elevation/shadow drop

### Bottom Sheets
- [ ] **Any bottom sheet** (e.g., filters, notifications)
- [ ] Sheet has **rounded top corners (r24)**
- [ ] Sheet has a **drag handle** at top (small grey bar, ~32px wide)
- [ ] Sheet background is solid card color

### Chips
- [ ] **Category chips** on Home screen — pill shape (StadiumBorder)
- [ ] **Skill chips** on Profile/Edit Profile — pill shape with thin border
- [ ] Chips have transparent background with subtle outline

### SnackBars
- [ ] **Trigger an error** (e.g., save profile with empty name)
- [ ] SnackBar is **floating** (not attached to bottom edge)
- [ ] SnackBar has **rounded corners (r12)**
- [ ] SnackBar has **inverted colors** (dark bg with light text in light mode, or vice versa)

### Tab Bars
- [ ] **Dashboard tabs** — active tab has teal underline (3px thick)
- [ ] **Active tab label** is bold, inactive is regular weight
- [ ] **Public Profile tabs** (About, Portfolio, History, Reviews) — same styling
- [ ] Tab indicator width = label width (not full tab width)

### Dividers
- [ ] **Settings screen** — dividers between sections are very thin (0.5px)
- [ ] **Any list with dividers** — subtle, not heavy

---

## SECTION 8: SKELETON LOADING (Phase 1 — Shimmer)

### Shimmer Animation
- [ ] **Any loading list** — shows shimmer rectangles (not spinners)
- [ ] Shimmer has a smooth left-to-right sweep animation
- [ ] Shimmer adapts to dark/light mode (visible but subtle in both)

### Specific Screens
- [ ] **Home** — if tasks loading, shows shimmer task card skeletons
- [ ] **Messages** — if loading, shows shimmer conversation tiles
- [ ] **Dashboard** — counters show shimmer while loading
- [ ] **Booking list** — shimmer booking card skeletons

---

## SECTION 9: NAVIGATION & GENERAL REGRESSION

### All Tabs Functional
- [ ] **Home** tab loads, shows content
- [ ] **Tenders** tab loads, shows tender cards
- [ ] **Bookings** tab loads, shows booking cards
- [ ] **Dashboard** tab loads, shows 5 sub-tabs (Overview, Bookings, Work, Wallet, Inbox)
- [ ] **Messages** tab loads, shows conversation list
- [ ] **Profile** tab loads, shows profile info + menu

### Key Flows
- [ ] **Login** — can sign in with test credentials
- [ ] **Create Task** — FAB button opens create screen, form works
- [ ] **Open a task** — task details screen loads
- [ ] **Open a booking** — booking details screen loads
- [ ] **Open chat** — conversation loads, messages display
- [ ] **Edit Profile** — form loads, fields editable, save works
- [ ] **Settings** — dark mode toggle works, all tiles tappable
- [ ] **Notifications** — bell icon opens modal, notifications display
- [ ] **Public Profile** — tap user avatar → public profile loads with tabs

### Theme Switching
- [ ] **Dark → Light** — toggle in Settings, app transitions smoothly
- [ ] **Light → Dark** — toggle back, no flash of wrong colors
- [ ] **Both modes** — all text readable, all cards visible, all badges colored correctly

---

## SECTION 10: KNOWN RISK AREAS (Watch Closely)

### Typography Overflow (Body Height 1.2 → 1.5)
- [ ] **WATCH:** Cards with fixed heights may now clip text
- [ ] **WATCH:** Tight layouts (task card footer, booking card info) may overflow
- [ ] **WATCH:** Chat bubbles may be slightly taller than before
- [ ] **If found:** Note screen name + widget — these are fixable per-screen

### Glass → Solid Visual Difference
- [ ] **WATCH:** Some screens may look "flat" or "boring" without the glass effect — this is intentional per the NO GLASS POLICY. Solid surfaces are faster, cleaner, more accessible.
- [ ] **WATCH:** Dark mode cards may blend into dark background if border is too subtle
- [ ] **If found:** Note screen name — may need border color adjustment

### Haptic Feedback
- [ ] **VERIFY:** Haptics work on a physical device (simulator may not vibrate)
- [ ] If testing on simulator: skip haptic checks, verify only visual feedback (scale animation)

---

## RESULTS

**Date tested:** _______________
**Device/Simulator:** _______________
**iOS version:** _______________
**Mode tested:** [ ] Dark  [ ] Light  [ ] Both

### Issues Found:
| # | Section | Screen | Issue Description | Severity (Blocker/Major/Minor/Cosmetic) | Screenshot? |
|---|---------|--------|-------------------|----------------------------------------|-------------|
| 1 | | | | | |
| 2 | | | | | |
| 3 | | | | | |
| 4 | | | | | |
| 5 | | | | | |

### Sections Passed:
- [ ] Section 1: Typography
- [ ] Section 2: No Glass / Solid Surfaces
- [ ] Section 3: Button Interactions
- [ ] Section 4: Text Field Features
- [ ] Section 5: Avatar & Image Loading
- [ ] Section 6: Status Badges
- [ ] Section 7: Component Themes
- [ ] Section 8: Skeleton Loading
- [ ] Section 9: Navigation & Regression
- [ ] Section 10: Risk Areas Checked

### Overall Verdict:
[ ] **CLEAN** — No issues. Ready to commit and push.
[ ] **MINOR** — Cosmetic issues only. Safe to commit, fix in next phase.
[ ] **MAJOR** — Functional issues found. Must fix before commit.
[ ] **BLOCKER** — App crashes or critical flow broken. Must fix immediately.
