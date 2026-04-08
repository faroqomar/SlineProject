# Phase 0 — Emulator Test Checklist
> Test every design system change visually on a real device/emulator.
> Run the app: `/Users/eros/Dev/flutter/bin/flutter run`

---

## SETUP

- [ ] Start emulator or connect device
- [ ] Run `flutter run` (app launches without crash)
- [ ] App defaults to **dark mode** (ThemeModeProvider default)

---

## 1. TYPOGRAPHY — Line Height Changes

The biggest visual change. Body text is now taller (1.2 → 1.5 line height = 25% more vertical space).

### Login Screen
- [ ] Open login screen
- [ ] Verify "Sign in to continue to SLine" subtitle text is readable and not cramped
- [ ] Verify email/password field hint text has comfortable spacing
- [ ] Verify no text is clipped or overflowing

### Home Screen
- [ ] Navigate to Home tab
- [ ] Verify greeting text ("Good morning, [Name]") has good spacing
- [ ] Verify search bar hint text looks normal
- [ ] Verify category chip labels are readable (not too tall for pill shape)
- [ ] Scroll through task cards — verify card titles and descriptions have comfortable line spacing
- [ ] Verify no card content overflows its container

### Chat / Messages
- [ ] Navigate to Messages tab
- [ ] Verify conversation list tile text (name + last message) has good spacing
- [ ] Open a conversation — verify message bubble text is readable
- [ ] Verify timestamp text in bubbles is compact but readable
- [ ] Verify the message input field hint text looks normal

### Dashboard
- [ ] Navigate to Dashboard tab
- [ ] Verify tab labels (Overview, Bookings, Work, Wallet, Inbox) look normal
- [ ] Verify counter grid numbers and labels have good spacing
- [ ] Verify "Next Actions" and "Recent Activity" section text

### Profile
- [ ] Navigate to Profile tab
- [ ] Verify name, bio, and stat labels have comfortable spacing
- [ ] Verify menu item titles and subtitles
- [ ] Open Settings — verify all setting tile text

### Task/Booking Detail
- [ ] Open any task or booking detail screen
- [ ] Verify description text is comfortable to read (not cramped)
- [ ] Verify section headers (h5) look properly spaced
- [ ] Verify price and status text

---

## 2. COMPONENT THEMES — Visual Defaults

These affect Material widgets globally. Check that nothing looks broken.

### Dialogs
- [ ] Trigger any dialog (e.g., logout confirmation in Settings, or "Add Skill" in Edit Profile)
- [ ] Verify dialog has **rounded corners (r24)** — not sharp default Material corners
- [ ] Verify dialog background matches card background color
- [ ] Verify dialog has **no shadow/elevation** (flat against overlay)

### Bottom Sheets
- [ ] Trigger any bottom sheet (e.g., filters on Home, or notification modal)
- [ ] Verify sheet has **rounded top corners (r24)**
- [ ] Verify sheet has a **drag handle** (small grey bar at top, 32x4 pixels)
- [ ] Verify sheet background matches card background color
- [ ] Verify sheet slides up smoothly

### Chips
- [ ] Look at any screen with chips (category chips on Home, skill chips on Profile/Edit Profile)
- [ ] Verify chips have **pill shape** (stadium border, not sharp rectangle)
- [ ] Verify chips have **thin border** (0.5px, subtle)
- [ ] Verify chip text uses captionBold style
- [ ] Verify chip background is transparent (border-only style)

### Snackbars
- [ ] Trigger a snackbar (e.g., save profile with missing name, or any error action)
- [ ] Verify snackbar is **floating** (not attached to bottom)
- [ ] Verify snackbar has **rounded corners (r12)**
- [ ] Verify snackbar has **inverted colors** (dark background in light mode, light in dark mode)

### Dividers
- [ ] Look for dividers on any list screen (Settings, Messages, Notifications)
- [ ] Verify dividers are **very thin** (0.5px) — subtle, not heavy

### Tab Bars
- [ ] Check Dashboard tab bar and Public Profile tab bar
- [ ] Verify active tab has **teal underline indicator** (3px width)
- [ ] Verify active tab label is **bold** (captionBold)
- [ ] Verify inactive tab labels are **regular weight** and secondary color
- [ ] Verify indicator size is **label width** (not full tab width)

---

## 3. DARK MODE vs LIGHT MODE

Toggle theme in Settings → Dark Mode switch.

### In Dark Mode (default)
- [ ] Verify background is dark (#0c0c0c)
- [ ] Verify text is light (off-white)
- [ ] Verify cards have subtle glass effect visible against dark background
- [ ] Verify bottom navigation bar glass effect works
- [ ] Verify tab bar labels are readable

### Switch to Light Mode
- [ ] Toggle to light mode in Settings
- [ ] Verify background is light (#f4f3f1)
- [ ] Verify text is dark
- [ ] Verify cards have visible borders and subtle styling
- [ ] Verify bottom navigation bar adapts
- [ ] Verify all text is readable (no white-on-white or dark-on-dark issues)

### Switch Back to Dark Mode
- [ ] Verify the transition is smooth (theme lerp should interpolate colors)
- [ ] Verify no flash of wrong colors during transition

---

## 4. BOTTOM NAVIGATION BAR

The nav bar was NOT changed in Phase 0, but verify it still works after theme changes.

- [ ] Verify all 6 tabs are tappable and navigate correctly (Home, Tenders, Bookings, Dashboard, Messages, Profile)
- [ ] Verify animated pill indicator moves smoothly on tab switch
- [ ] Verify notification badge on Messages tab (if unread messages exist)
- [ ] Verify the FAB (Create Task button) appears and is tappable
- [ ] Verify the FAB rotation animation works on tap (AnimatedRotationButton — migrated to AppMotion)

---

## 5. FAB ANIMATION (SpringButton + AnimatedRotationButton)

These widgets were migrated from AppAnimations to AppMotion tokens. Verify they still animate.

- [ ] Tap the Create Task FAB
- [ ] Verify the FAB **scales down on press** (SpringButton with AppMotion.pressScale = 0.96)
- [ ] Verify the FAB **rotates on tap** (AnimatedRotationButton, 90 degrees)
- [ ] Verify the FAB **bounces back** smoothly after press release
- [ ] Verify no jank or stutter in the animation

---

## 6. GENERAL REGRESSION CHECK

Quick smoke test on main flows.

- [ ] **Login:** Can sign in (if test credentials available)
- [ ] **Home:** Task cards load and display correctly
- [ ] **Tenders:** Screen loads, cards display
- [ ] **Bookings:** Screen loads, cards display
- [ ] **Dashboard:** All 5 tabs load (Overview, Bookings, Work, Wallet, Inbox)
- [ ] **Messages:** Conversation list loads
- [ ] **Chat:** Can open a conversation, messages display
- [ ] **Profile:** Profile screen loads, all sections visible
- [ ] **Edit Profile:** Can open, form fields work, skills chips display
- [ ] **Settings:** All tiles visible, dark mode toggle works
- [ ] **Notifications:** Modal opens from bell icon, notifications display (if any)
- [ ] **Create Task:** FAB opens create task screen

---

## 7. WHAT TO LOOK FOR (Known Risk Areas)

### Typography Overflow
The line height increase may cause text to take more vertical space than before:
- **Watch for:** Text clipping at bottom of fixed-height containers
- **Watch for:** Cards that look "too tall" compared to before
- **Watch for:** Overlapping text in tight layouts (task cards, booking cards, chat bubbles)
- **If found:** Note the screen name and widget — these are Phase 1 fixes, not Phase 0 bugs

### Component Theme Conflicts
New global themes may affect widgets that relied on Material defaults:
- **Watch for:** Double drag handles on bottom sheets (one from theme + one custom)
- **Watch for:** Invisible chips (transparent background where old default was filled)
- **Watch for:** Dialogs with unexpected styling
- **If found:** Note the screen name — these may need per-widget overrides in Phase 1

---

## RESULTS

**Date tested:** _______________
**Device/Emulator:** _______________
**Mode tested:** ☐ Dark  ☐ Light  ☐ Both

### Issues Found:
| # | Screen | Issue | Severity | Screenshot? |
|---|--------|-------|----------|-------------|
| 1 | | | | |
| 2 | | | | |
| 3 | | | | |

### Overall Verdict:
☐ **CLEAN** — No issues found. Ready to commit.
☐ **MINOR** — Cosmetic issues only. Can commit and fix in Phase 1.
☐ **BLOCKING** — Functional issues found. Must fix before commit.
