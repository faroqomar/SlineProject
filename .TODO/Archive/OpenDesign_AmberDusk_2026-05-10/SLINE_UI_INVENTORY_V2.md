# SLINE COMPLETE UI INVENTORY V2
> Exhaustive Figma-Ready UI Specification — Every Screen, Component, Widget & Theme Token
> Auto-Generated from 115+ Source Files

**Document Generated:** 2026-04-05
**Comprehensive Source Coverage:** 
- Original V1 Inventory (30 files)
- Profile Documentation (11 files)
- Public Profile Screens (6 widgets)
- Batch Extraction (50+ additional screens/components)
- Complete Theme System & Design Tokens

---

## TABLE OF CONTENTS

1. PART 1: DESIGN SYSTEM FOUNDATION
2. PART 2: CORE REUSABLE COMPONENTS
3. PART 3: APP SHELL & NAVIGATION
4. PART 4: AUTHENTICATION SCREENS
5. PART 5: HOME & DISCOVERY
6. PART 6: TASKS & TENDERS
7. PART 7: CHAT & MESSAGING
8. PART 8: DASHBOARD
9. PART 9: BOOKING & PAYMENTS
10. PART 10: PROFILE
11. PART 11: PORTFOLIO
12. PART 12: PROPOSALS & DIRECT OFFERS
13. PART 13: WALLET
14. PART 14: WORK MANAGEMENT
15. PART 15: NOTIFICATIONS
16. PART 16: SAVED, FAVORITES, CATEGORIES, SERVICES
17. PART 17: MASTER SUMMARY & FILE INDEX

---

# PART 1: DESIGN SYSTEM FOUNDATION

## 1.1 Color Palette (AppColors)

Complete color constants used throughout the SLine app:

### Primary Colors
- **teal** - `#146068` - Primary brand color, buttons, active states, primary actions
- **darkTeal** - `#0c3b40` - Darker variant for secondary uses
- **lightTeal** - `#93ccce` - Secondary brand color, badges, hover states, accents
- **gold** - `#f3bb19` - Accents, avatar backgrounds, star ratings, highlights
- **lightRed** - `#f49d9d` - Danger/delete actions, warning states, alerts
- **mediumGreyBlue** - `#9dbabb` - Subtle secondary text, disabled states
- **white** - `#ffffff` - Text on dark backgrounds, borders, primary light color

### Context ColorScheme Colors
Dynamically applied via `context.colorScheme`:
- **phoneBackground** - Main scaffold background color
- **cardBackground** - Container and card backgrounds
- **text** / **textSecondary** / **textTertiary** - Text hierarchy levels
- **primary** - Primary action color (usually teal)
- **surface** / **onSurface** - Dialog and surface backgrounds
- **error** - Error states and validation failures
- **outline** - Border and divider colors

### Color Usage Guidelines
- Buttons: Use `AppColors.teal` (#146068) for primary, `AppColors.lightTeal` (#93ccce) for secondary
- Text: Use context.colorScheme.text for primary, textSecondary for labels
- Alerts: Use `AppColors.lightRed` (#f49d9d) for errors and dangerous actions
- Backgrounds: Use context.colorScheme.phoneBackground and cardBackground
- Dark mode support: All colors respect app theme via colorScheme

---

## 1.2 Typography System (AppTypography)

Standard text styles applied across all screens:

### Heading Styles
- **h3** - Screen titles (Edit Profile, Settings, Manage Portfolio, etc.)
  - Size: 24px font size
  - Weight: Bold
  - Use: Main screen headers
  
- **h5** - Section headers (Basic Info, Skills, Portfolio, Reviews, etc.)
  - Size: 18px font size
  - Weight: SemiBold
  - Use: Section dividers within screens
  
- **h6** - Stat values and emphasis (92%, 15, $45/hr, etc.)
  - Size: 16px font size
  - Weight: SemiBold
  - Use: Highlighted numbers and stats

### Body Text Styles
- **bodyLarge** - Primary buttons and prominent CTAs
  - Size: 16px font size
  - Weight: Medium
  - Use: Button text, main action labels
  
- **bodyMedium** - Regular text, labels, tile titles
  - Size: 14px font size
  - Weight: Regular
  - Use: Standard paragraph text, list items
  
- **bodySmall** - Secondary text, descriptions, chip labels
  - Size: 12px font size
  - Weight: Regular
  - Use: Secondary information, hints

### Caption Styles
- **caption / captionBold** - Tertiary text, badges, section labels
  - Size: 11px font size
  - Weight: Regular / Bold
  - Use: Very small labels, badge text
  
- **micro** - Very small text, dates, locations, category info
  - Size: 10px font size
  - Weight: Regular
  - Use: Timestamps, minor metadata

---

## 1.3 Spacing & Dimensions (AppDimens)

Standard spacing values for consistent layouts:

### Padding Values
- **p4** - 4px (very small padding, micro spacing)
- **p8** - 8px (small padding, list separators, tight spacing)
- **p12** - 12px (small spacing, gaps between elements)
- **p16** - 16px (standard spacing, vertical sections)
- **p24** - 24px (major spacing, horizontal margins, section breaks)
- **p32** - 32px (large spacing, between major sections)
- **p48** - 48px (bottom padding to avoid overlap with nav bar)

### Border Radius Values
- **r8** - 8px (text fields, small containers, back buttons)
- **r12** - 12px (back buttons, small containers, icon backgrounds)
- **r16** - 16px (cards, portfolio items, medium containers)
- **r20** - 20px (large cards, avatars, circular effects)
- **r24** - 24px (modal corners, dialog boxes, large rounded containers)

### Responsive Layout
- **Horizontal Padding:** 24px margins on all sides (maintains readability on small screens)
- **Avatar Radius:** Configurable per parameter (typically 40-60px)
- **Grid Columns:** 2 columns (masonry layouts fit phones/tablets)
- **List Height:** Full-width minus margins

---

## 1.4 Decorations & Glass Effects (AppDecorations)

Custom visual treatments applied throughout:

### GlassContainer Decoration
```
BoxDecoration(
  color: Color(0x80FFFFFF) or context.colorScheme.cardBackground.withOpacity(0.5),
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: Colors.white10),
  boxShadow: [BoxShadow(
    color: Colors.black12,
    blurRadius: 12,
    offset: Offset(0, 2)
  )]
)
```
Used for: Card containers, glass morphism effects, subtle backgrounds

### Standard Card Decoration
```
BoxDecoration(
  color: context.colorScheme.cardBackground,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: Colors.white.withOpacity(0.1))
)
```
Used for: Regular cards, list items, content containers

### Gradient Headers (PublicProfileHeader)
```
BoxDecoration(
  gradient: LinearGradient(
    colors: [#146068, #0c3b40],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight
  )
)
```
Used for: Profile headers, hero sections, prominent backgrounds

---

## 1.5 Theme Configuration (AppTheme)

Primary theme configuration:

### Theme Structure
```dart
ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.teal,
    brightness: isDarkMode ? Brightness.dark : Brightness.light
  ),
  scaffoldBackgroundColor: isDarkMode ? #0a0e11 : #f5f5f5,
  appBarTheme: AppBarTheme(
    backgroundColor: transparent,
    elevation: 0,
    centerTitle: false
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    filled: true,
    fillColor: context.colorScheme.cardBackground
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: context.colorScheme.surface,
    selectedItemColor: AppColors.teal,
    unselectedItemColor: AppColors.mediumGreyBlue
  )
)
```

### Dark Mode Support
All colors automatically adapt via `context.colorScheme`
- Light backgrounds become dark
- Light text becomes light
- Icons and buttons adapt accordingly
- Theme toggle via `ThemeModeProvider`

---

## 1.6 Dashboard Theme (ThemeDashboard)

**Path:** `lib/core/theme/theme_dashboard.dart`
**Class:** `ThemeDashboard` (private constructor — documentation-only reference class)
**Type:** Theme Reference / Design Token Documentation

This file is a **comprehensive design token reference** that documents all theme values in one place. It does NOT provide runtime values — use `AppColors`, `AppTypography`, `AppDimens`, `AppDecorations` directly.

### Color System Reference

**Primary Colors:**
| Token | Hex | Usage |
|-------|-----|-------|
| `AppColors.teal` | #146068 | Primary brand, buttons, active states, focus borders |
| `AppColors.lightTeal` | #93ccce | Secondary teal |
| `AppColors.gold` | #f3bb19 | Hot badges, highlights, special indicators |
| `AppColors.lightRed` | #f49d9d | Errors, hot badges, warnings |

**Neutral Colors:**
| Token | Hex | Usage |
|-------|-----|-------|
| `AppColors.almostBlack` | #0c0c0c | Dark text, dark backgrounds |
| `AppColors.offWhite` | #f4f3f1 | Light backgrounds |
| `AppColors.white` | #ffffff | Pure white |
| `AppColors.mediumGreyBlue` | #9dbabb | Secondary text (dark mode) |
| `AppColors.mediumGrey` | #a9a8a7 | Secondary text (light mode) |
| `AppColors.darkerGrey` | #6b6b6b | Tertiary text (light mode) |

### Typography Scale Reference

**Font Family:** Plus Jakarta Sans (via Google Fonts)

| Style | Size | Weight | Usage |
|-------|------|--------|-------|
| `logo` | 36px | w900 | Logo text |
| `h1` | 32px | w900 | Main headings |
| `h2` | 28px | w900 | Section headings |
| `h3` | 22px | w800 | Subsection headings |
| `h4` | 20px | w800 | Card titles |
| `h5` | 18px | w700 | Modal titles |
| `subtitle` | 17px | w700 | Modal subtitles |
| `h6` | 16px | w800 | Small headings |
| `bodyLarge` | 15px | w500 | Body text (large) |
| `bodyMedium` | 14px | normal | Body text (standard) |
| `bodySmall` | 13px | w500 | Body text (small) |
| `caption` | 12px | normal | Captions |
| `captionBold` | 12px | w700 | Bold captions |
| `overline` | 11px | w600 | Overlines |
| `micro` | 10px | w500 | Micro text |

### Spacing / Padding Scale Reference

| Token | Value | Usage |
|-------|-------|-------|
| `p0` | 0.0 | No spacing |
| `p2` | 2.0 | Minimal |
| `p4` | 4.0 | Tight |
| `p6` | 6.0 | |
| `p8` | 8.0 | Small |
| `p10` | 10.0 | |
| `p12` | 12.0 | Medium-small |
| `p14` | 14.0 | |
| `p16` | 16.0 | Standard |
| `p18` | 18.0 | |
| `p20` | 20.0 | Medium |
| `p22` | 22.0 | Icon size |
| `p24` | 24.0 | Large |
| `p28` | 28.0 | |
| `p32` | 32.0 | XL |
| `p40` | 40.0 | |
| `p48` | 48.0 | |
| `p50` | 50.0 | |
| `p52` | 52.0 | Avatar size |
| `p54` | 54.0 | |
| `p60` | 60.0 | |
| `p70` | 70.0 | |
| `p80` | 80.0 | |
| `p100` | 100.0 | Bottom nav offset |

### Border Radius Scale Reference

| Token | Value | Usage |
|-------|-------|-------|
| `r4` | 4.0 | |
| `r8` | 8.0 | Small |
| `r10` | 10.0 | Small buttons |
| `r12` | 12.0 | Chips, small buttons |
| `r14` | 14.0 | Inputs, buttons |
| `r16` | 16.0 | Inputs, cards |
| `r18` | 18.0 | Avatars, buttons |
| `r20` | 20.0 | Cards |
| `r24` | 24.0 | Large cards |
| `r30` | 30.0 | Modals |
| `r50` | 50.0 | Phone mockup |

### Icon Sizes Reference
- `iconSizeSmall` = 16.0
- `iconSizeMedium` = 24.0
- `iconSizeLarge` = 32.0

### Common Component Size Reference

**Inputs:** Standard=46px, Auth=52px, Search=48px
**Buttons:** Standard=50px, Auth=54px, Small=36px
**Avatars:** Standard=52x52px, Large=80x80px
**Icon Buttons:** Standard=46x46px, Small=38x38px, Large=56x56px

### Light Mode Color Scheme
| Property | Value | Hex |
|----------|-------|-----|
| background | offWhite | #f4f3f1 |
| text | almostBlack | #0c0c0c |
| textSecondary | mediumGrey | #a9a8a7 |
| textTertiary | darkerGrey | #6b6b6b |
| cardBackground | white | #ffffff |
| inputBackground | white | #ffffff |
| primary | teal | #146068 |
| accent | gold | #f3bb19 |

### Dark Mode Color Scheme
| Property | Value | Hex |
|----------|-------|-----|
| background | almostBlack | #0c0c0c |
| text | offWhite | #f4f3f1 |
| textSecondary | mediumGreyBlue | #9dbabb |
| textTertiary | mediumGrey | #a9a8a7 |
| cardBackground | offWhite@8% | rgba(244,243,241,0.08) |
| inputBackground | offWhite@10% | rgba(244,243,241,0.10) |
| primary | teal | #146068 |
| accent | gold | #f3bb19 |

### Design Token → Flutter Mapping
| Design Token | Flutter Theme |
|---|---|
| `phoneBg` | `colorScheme.phoneBackground` |
| `text` | `colorScheme.text` |
| `textSecondary` | `colorScheme.textSecondary` |
| `textTertiary` | `colorScheme.textTertiary` |
| `cardBg` | `colorScheme.cardBackground` |
| `cardBorder` | `colorScheme.cardBorder` |
| `inputBg` | `colorScheme.inputBackground` |
| `inputBorder` | `colorScheme.inputBorder` |
| `headerBg` | `colorScheme.headerBackground` |
| `headerBorder` | `colorScheme.headerBorder` |
| `bottomNavBg` | `colorScheme.bottomNavBackground` |
| `bottomNavBorder` | `colorScheme.bottomNavBorder` |
| `bottomNavInactive` | `colorScheme.bottomNavInactive` |
| `hotBadgeBg` | `colorScheme.hotBadgeBackground` |
| `hotBadgeBorder` | `colorScheme.hotBadgeBorder` |

### Figma Notes
ThemeDashboard is the master reference file that maps all design tokens to Flutter theme classes. A Figma designer should use this as the single lookup table for every color hex, typography size/weight, spacing value, border radius, and component dimension in the SLine design system. It covers both light and dark mode schemes with exact rgba values for transparent variants.

---


# PART 2: CORE REUSABLE COMPONENTS

## 2.1 AppButton

**Path:** `lib/core/widgets/app_button.dart`

### Widget Tree
```
GestureDetector
  ├── onTap: onPressed callback
  ├── child: Container
  │   ├── decoration: BoxDecoration
  │   │   ├── color: AppColors.teal (#146068) or custom
  │   │   └── borderRadius: 8px
  │   ├── padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24)
  │   └── child: Text(buttonLabel)
```

### Properties
- **Label:** String (button text)
- **onPressed:** VoidCallback
- **backgroundColor:** Color (default: AppColors.teal)
- **textColor:** Color (default: white)
- **borderRadius:** double (default: 8)
- **isLoading:** bool (shows spinner when true)
- **width:** double (optional, default full width)

### States
- **Normal:** AppColors.teal background, white text
- **Pressed:** Opacity 0.8
- **Loading:** CircularProgressIndicator replaces text, disabled state
- **Disabled:** Gray background, reduced opacity

### Usage Example
```dart
AppButton(
  label: 'Save Changes',
  onPressed: () => vm.saveProfile(),
  backgroundColor: AppColors.teal,
)
```

---

## 2.2 AppTextField

**Path:** `lib/core/widgets/app_text_field.dart`

### Widget Tree
```
Column
  ├── label: Text(labelText)
  ├── SizedBox(height: 8)
  ├── TextField
  │   ├── decoration: InputDecoration
  │   │   ├── hintText: hintText
  │   │   ├── border: OutlineInputBorder
  │   │   ├── fillColor: cardBackground.withOpacity(0.5)
  │   │   └── filled: true
  │   ├── onChanged: onChanged callback
  │   └── maxLines: 1 or custom
  └── errorText: String (if validation fails)
```

### Properties
- **labelText:** String (field label)
- **hintText:** String (placeholder text)
- **onChanged:** (String) -> void
- **validator:** (String) -> String? (validation function)
- **maxLines:** int (default: 1)
- **maxLength:** int (optional, shows character counter)
- **keyboardType:** TextInputType
- **obscureText:** bool (for passwords)
- **prefixIcon:** IconData (optional)
- **suffixIcon:** IconData (optional)

### States
- **Empty:** Gray border, light background, hint text visible
- **Focused:** Teal border highlight, light background
- **Filled:** Dark text on light background, border subtle
- **Error:** Red/pink border, error text below field
- **Disabled:** Gray background, unresponsive

---

## 2.3 GlassContainer

**Path:** `lib/core/widgets/glass_container.dart`

### Properties
- **child:** Widget
- **padding:** EdgeInsets (default: all 16)
- **borderRadius:** double (default: 16)
- **backgroundColor:** Color (default: white 0.5)
- **border:** Border (optional)
- **boxShadow:** List<BoxShadow> (default: subtle)
- **onTap:** VoidCallback (optional, makes tappable)

### Visual Effect
- Semi-transparent white/colored background (0.5 opacity)
- 12px blur radius shadow effect
- 10px white border with 0.1 opacity
- Smooth border radius (default 16px)

### Usage Example
```dart
GlassContainer(
  padding: EdgeInsets.all(16),
  child: Column(
    children: [
      Text('Glass Effect Content'),
    ],
  ),
)
```

---

## 2.4 GlassCard

**Path:** `lib/core/widgets/glass_card.dart`

### Widget Tree
```
Container
  ├── decoration: BoxDecoration
  │   ├── color: Color(0x80FFFFFF)
  │   ├── borderRadius: 16
  │   ├── border: white 0.1 opacity
  │   └── boxShadow: [subtle shadow]
  └── child: Padding(all: 16, child: content)
```

### Properties
- **child:** Widget
- **onTap:** VoidCallback (optional)
- **padding:** EdgeInsets (default: 16)
- **borderRadius:** double (default: 16)
- **elevation:** double (default: 0, shadow strength)

### Usage
Cards for list items, tile content, sections with frosted glass appearance

---

## 2.5 GlassButton

**Path:** `lib/core/widgets/glass_button.dart`

### Widget Tree
```
Container
  ├── decoration: BoxDecoration (glass effect)
  │   ├── color: white.withOpacity(0.1)
  │   ├── borderRadius: 8
  │   └── border: white 0.2
  ├── child: InkWell
  │   └── onTap: callback
  │   └── child: Padding(8, Text(label))
```

### Properties
- **label:** String
- **onPressed:** VoidCallback
- **icon:** IconData (optional)
- **isPrimary:** bool (false = glass, true = teal)

### States
- **Normal:** Semi-transparent white with light border
- **Pressed:** Opacity increases to 0.2
- **Primary Mode:** Uses AppColors.teal background

---

## 2.6 ScaleButton

**Path:** `lib/core/widgets/scale_button.dart`

### Widget Tree
```
GestureDetector
  ├── onTap: onPressed
  ├── child: AnimatedScale
  │   ├── duration: 100ms
  │   ├── scale: isPressed ? 0.95 : 1.0
  │   └── child: child widget
```

### Properties
- **onPressed:** VoidCallback
- **child:** Widget
- **scale:** double (default: 0.95 on press)

### Behavior
- Scales down to 95% on tap
- Animates back to 100% on release
- Provides tactile feedback without changing appearance

---

## 2.7 CircleIconButton

**Path:** `lib/core/widgets/circle_icon_button.dart`

### Widget Tree
```
Container
  ├── decoration: BoxDecoration
  │   ├── color: backgroundColor
  │   ├── shape: circle
  │   └── borderRadius: circular(radius)
  └── child: IconButton
      ├── icon: Icon(iconData)
      ├── onPressed: callback
      └── iconSize: 24
```

### Properties
- **icon:** IconData
- **onPressed:** VoidCallback
- **backgroundColor:** Color
- **iconColor:** Color (default: white)
- **radius:** double (default: 24)
- **tooltip:** String (optional)

### Usage
Circular buttons for share, favorite, delete, report actions in cards

---

## 2.8 SignedAvatar

**Path:** `lib/core/widgets/signed_avatar.dart`

### Widget Tree
```
CircleAvatar
  ├── backgroundImage: NetworkImage (signed URL)
  ├── radius: 40 (default)
  └── child: placeholder (if no image)
```

### Properties
- **imageUrl:** String (path in Supabase storage)
- **radius:** double (default: 40)
- **placeholder:** Widget (default: Icon)
- **storageBucket:** String (e.g., 'avatars')

### Behavior
- Generates signed URL from Supabase storage
- 2-hour TTL on signed URLs (avatars bucket)
- Falls back to placeholder if image unavailable
- Respects image caching

---

## 2.9 SignedImage

**Path:** `lib/core/widgets/signed_image.dart`

### Widget Tree
```
Container
  ├── child: Image.network(signedUrl)
  │   ├── fit: BoxFit.cover
  │   ├── errorBuilder: placeholder
  │   └── loadingBuilder: skeleton loader
  └── decoration: optional border/shadow
```

### Properties
- **imagePath:** String (storage path)
- **width:** double
- **height:** double
- **fit:** BoxFit (default: cover)
- **storageBucket:** String
- **borderRadius:** BorderRadius (optional)

### Behavior
- Automatically generates signed URLs
- Shows SkeletonLoader while loading
- Error placeholder on failed load
- Respects bucket-specific TTL

---

## 2.10 SkeletonCard & SkeletonLoader

**Path:** `lib/core/widgets/skeleton_*.dart`

### SkeletonLoader
```
Column
  ├── shimmer effect (gray wave animation)
  └── placeholder shapes
      ├── Circle (avatar placeholder)
      ├── Rectangle (text placeholder)
      └── custom layouts
```

### SkeletonCard
```
Container
  ├── height: 120
  ├── decoration: gray background
  ├── shimmer overlay
  └── child: Column of placeholder lines
```

### Usage
- Loading states in lists
- Image placeholder during fetch
- Entire card placeholders while data loads

---

## 2.11 StatusBadge

**Path:** `lib/core/widgets/status_badge.dart`

### Widget Tree
```
Container
  ├── decoration: BoxDecoration
  │   ├── color: statusColor (teal/red/gold/gray)
  │   ├── borderRadius: 12
  │   └── border: optional
  ├── padding: 4,8
  └── child: Text(statusLabel, style: caption)
```

### Properties
- **status:** String ('pending', 'completed', 'cancelled', etc.)
- **size:** BadgeSize (small, medium, large)
- **customColor:** Color (optional override)

### Status Mapping
- `pending` → Yellow/Gold (#f3bb19)
- `completed` → Teal (#146068)
- `cancelled` → Red (#f49d9d)
- `in_progress` → Light Teal (#93ccce)

---

## 2.12 SliverTabBarDelegate

**Path:** `lib/core/widgets/sliver_tab_bar_delegate.dart`

### Purpose
Custom SliverPersistentHeaderDelegate for pinned tab bars in nested scroll views

### Properties
- **tabBar:** TabBar widget
- **height:** double (default: 48)
- **backgroundColor:** Color (default: cardBackground)

### Behavior
- Stays pinned at top during scroll
- Slides down when scrolled past
- Maintains proper alignment and sizing

---

## 2.13 CustomBottomNavBar

**Path:** `lib/core/widgets/custom_bottom_nav_bar.dart`

### Widget Tree
```
BottomNavigationBar
  ├── items: List<BottomNavigationBarItem>
  │   ├── icon: IconData
  │   ├── label: String
  │   └── backgroundColor: colorScheme.surface
  ├── currentIndex: activeTabIndex
  ├── onTap: setIndex callback
  ├── type: BottomNavigationBarType.fixed
  └── elevation: 8
```

### Navigation Items
| Item | Index | Icon | Label |
|------|-------|------|-------|
| Home | 0 | home_outlined | Home |
| Tasks | 1 | assignment_outlined | Tasks |
| Bookings | 2 | calendar_today_outlined | Bookings |
| Dashboard | 3 | dashboard_outlined | Dashboard |
| Messages | 4 | mail_outlined | Messages |
| Profile | 5 | person_outlined | Profile |

### Styling
- **Selected Item Color:** AppColors.teal (#146068)
- **Unselected Item Color:** AppColors.mediumGreyBlue (#9dbabb)
- **Background:** context.colorScheme.surface
- **Elevation:** 8px shadow
- **Font:** BottomNavigationBarLabelBehavior.alwaysShow


---

# PART 3: APP SHELL & NAVIGATION

## 3.1 MainNavigationScreen

**Path:** `lib/app/main_navigation_screen.dart`

**Type:** Navigation Container (Root Widget)

**Provider:** NavigationProvider

### Widget Tree Structure
```
Scaffold
  ├── backgroundColor: colorScheme.phoneBackground
  ├── body: AnimatedSwitcher
  │   ├── duration: 200ms
  │   └── [Current Tab Widget]
  ├── bottomNavigationBar: CustomBottomNavBar
  │   ├── currentIndex: NavigationProvider.currentIndex
  │   ├── onTap: NavigationProvider.setIndex
  │   └── items: [6 nav items]
  └── floatingActionButton: Conditional FAB (Create Task)
```

### UI Elements
- **Scaffold Background:** `colorScheme.phoneBackground`
- **Body Container:** Full-screen area with AnimatedSwitcher for smooth page transitions
- **Bottom Navigation:** CustomBottomNavBar (6 tabs with icons and labels)
- **FAB:** Create Task button with Icon.add_rounded and label, visible on most tabs
- **Transitions:** 200ms animation between tab screens

### Navigation Structure
| Tab | Index | Screen | Icon |
|-----|-------|--------|------|
| Home | 0 | HomeScreen | home_outlined |
| Tasks | 1 | TasksScreen | assignment_outlined |
| Bookings | 2 | BookingsDiscoveryScreen | calendar_today_outlined |
| Dashboard | 3 | DashboardScreen | dashboard_outlined |
| Messages | 4 | MessagesScreen | mail_outlined |
| Profile | 5 | ProfileScreen | person_outlined |

### FAB Actions
- **Tap:** Opens CreateTaskScreen as modal route
- **Label:** "Create Task"
- **Icon:** Icon.add_rounded (white)
- **Color:** `colorScheme.primary` (teal)
- **Visibility:** Hidden on ProfileScreen tab

---

# PART 4: AUTHENTICATION SCREENS

## 4.1 LoginScreen

**Path:** `lib/features/auth/view/login_screen.dart`

### Widget Tree
```
Scaffold
  ├── backgroundColor: colorScheme.phoneBackground
  └── body: SingleChildScrollView
      └── Padding(24)
          └── Column
              ├── SizedBox(24)
              ├── Text("Welcome Back", h3)
              ├── Text("Login to your account", bodyMedium)
              ├── SizedBox(32)
              ├── AppTextField(label: "Email", hint: "Enter email")
              ├── SizedBox(12)
              ├── AppTextField(label: "Password", obscure: true)
              ├── SizedBox(8)
              ├── Align(TextButton("Forgot Password?"))
              ├── SizedBox(24)
              ├── AppButton(label: "Login", onPressed: login)
              ├── SizedBox(16)
              ├── Row(Divider, "OR", Divider)
              ├── SizedBox(16)
              ├── GlassButton(label: "Continue with Google")
              ├── SizedBox(32)
              └── Row(Text("New user?"), TextButton("Sign Up"))
```

### Form Fields
- **Email TextField**
  - Label: "Email"
  - Hint: "example@mail.com"
  - Validator: Email format check
  - KeyboardType: TextInputType.emailAddress
  
- **Password TextField**
  - Label: "Password"
  - Obscure: true (shows dots)
  - Validator: Non-empty check

### Buttons
- **Login Button** - AppButton (AppColors.teal background, full width, 14px vertical padding)
- **Forgot Password Link** - TextButton (teal text)
- **Google Login** - GlassButton (semi-transparent glass effect)
- **Sign Up Link** - TextButton in footer row

### Colors
- Heading: colorScheme.text
- Subtext: colorScheme.textSecondary
- Input background: cardBackground.withOpacity(0.5)
- Button background: AppColors.teal (#146068)

---

## 4.2 SignupScreen

**Path:** `lib/features/auth/view/signup_screen.dart`

### Widget Tree
```
Scaffold
  ├── backgroundColor: colorScheme.phoneBackground
  └── body: SingleChildScrollView
      └── Padding(24)
          └── Column
              ├── SizedBox(24)
              ├── Text("Create Account", h3)
              ├── Text("Join SLine marketplace", bodyMedium)
              ├── SizedBox(32)
              ├── AppTextField(label: "Full Name")
              ├── SizedBox(12)
              ├── AppTextField(label: "Email")
              ├── SizedBox(12)
              ├── AppTextField(label: "Password", obscure: true)
              ├── SizedBox(12)
              ├── AppTextField(label: "Confirm Password", obscure: true)
              ├── SizedBox(8)
              ├── Row(Checkbox, Text("I agree to Terms"))
              ├── SizedBox(24)
              ├── AppButton(label: "Create Account")
              ├── SizedBox(16)
              ├── GlassButton(label: "Continue with Google")
              ├── SizedBox(32)
              └── Row(Text("Already have account?"), TextButton("Login"))
```

### Form Fields (4 total)
- **Full Name** - AppTextField (required validator)
- **Email** - AppTextField (email format validator)
- **Password** - AppTextField (min 8 chars validator)
- **Confirm Password** - AppTextField (must match password)
- **Terms Checkbox** - CheckboxListTile (required before signup)

### Validation
- Name: Non-empty
- Email: Valid format
- Password: Minimum 8 characters, contains uppercase/number
- Confirm: Must match password field
- Terms: Must be checked (checkbox)

### Error Display
- Inline validation messages below each field
- SnackBar for server errors
- Loading spinner on button during submission

---

## 4.3 ForgotPasswordScreen

**Path:** `lib/features/auth/view/forgot_password_screen.dart`

### Widget Tree
```
Scaffold
  ├── appBar: AppBar(back button)
  ├── backgroundColor: colorScheme.phoneBackground
  └── body: Padding(24)
      └── Column
          ├── SizedBox(24)
          ├── Text("Reset Password", h3)
          ├── Text("Enter your email to receive reset link", bodyMedium)
          ├── SizedBox(32)
          ├── AppTextField(label: "Email")
          ├── SizedBox(24)
          ├── AppButton(label: "Send Reset Link")
          ├── SizedBox(24)
          └── Text("Check your email for password reset instructions")
```

### Elements
- **Email Input** - AppTextField (required, email format)
- **Send Button** - AppButton (disabled until valid email entered)
- **Success Message** - Text after submission, with resend option
- **Back Button** - Standard app bar back navigation

---

## 4.4 ResetPasswordUpdateScreen

**Path:** `lib/features/auth/view/reset_password_update_screen.dart`

### Widget Tree
```
Scaffold
  ├── appBar: AppBar(back button)
  └── body: Padding(24)
      └── Column
          ├── Text("Set New Password", h3)
          ├── Text("Enter a strong new password", bodyMedium)
          ├── SizedBox(32)
          ├── AppTextField(label: "New Password", obscure: true)
          ├── SizedBox(12)
          ├── AppTextField(label: "Confirm Password", obscure: true)
          ├── SizedBox(8)
          ├── Text("Password requirements", caption)
          ├── Row(Icon, Text("At least 8 characters"))
          ├── Row(Icon, Text("Uppercase letter"))
          ├── Row(Icon, Text("Number"))
          ├── SizedBox(24)
          └── AppButton(label: "Update Password")
```

### Validation
- Min 8 characters
- Uppercase letter required
- Number required
- Passwords must match

### Password Requirements Display
- Visual checkmarks for met requirements
- Green color (#93ccce) for completed
- Gray for pending
- Real-time validation as user types

---

## 4.5 AccountRestrictedScreen

**Path:** `lib/features/auth/view/account_restricted_screen.dart`

### Widget Tree
```
Scaffold
  ├── backgroundColor: colorScheme.phoneBackground
  └── body: SafeArea
      └── Center
          └── Padding(24)
              └── Column(mainAxisSize: min)
                  ├── Icon(Icons.block, 64px, #f49d9d)
                  ├── SizedBox(16)
                  ├── Text("Account Banned" or "Suspended", h3)
                  ├── SizedBox(12)
                  ├── Text(reason or default message, bodyMedium)
                  ├── SizedBox(24)
                  └── FilledButton("Log Out")
```

### Display Logic
- **Icon:** Red block icon (64px, #f49d9d)
- **Title:** "Account Banned" (if status == 'banned') OR "Account Suspended"
- **Message:** Reason from backend OR default "Your account is currently restricted..."
- **Button:** "Log Out" → logout() → navigate to '/login'

### Colors
- Icon: #f49d9d (AppColors.lightRed)
- Title: colorScheme.text
- Message: colorScheme.textSecondary
- Button: AppColors.teal

---

## 4.6 MaintenanceScreen

**Path:** `lib/features/auth/view/maintenance_screen.dart`

### Widget Tree
```
Scaffold
  ├── backgroundColor: colorScheme.phoneBackground
  └── body: SafeArea
      └── Center
          └── Column(mainAxisSize: min)
              ├── Icon(Icons.construction, 64px)
              ├── SizedBox(16)
              ├── Text("Under Maintenance", h3)
              ├── SizedBox(12)
              ├── Text("We'll be back shortly...")
              ├── SizedBox(24)
              ├── CircularProgressIndicator()
              └── SizedBox(16)
              └── Text("Estimated time: 30 minutes")
```

### Purpose
- Full-screen notification during server maintenance
- Shows timestamp of when service will return
- Loading indicator for visual feedback

---

## 4.7 UpdateRequiredScreen

**Path:** `lib/features/auth/view/update_required_screen.dart`

### Widget Tree
```
Scaffold
  ├── backgroundColor: colorScheme.phoneBackground
  └── body: SafeArea
      └── Center
          └── Column(mainAxisSize: min)
              ├── Icon(Icons.system_update, 64px)
              ├── SizedBox(16)
              ├── Text("App Update Required", h3)
              ├── SizedBox(12)
              ├── Text("Please update to the latest version", bodyMedium)
              ├── SizedBox(24)
              ├── AppButton(label: "Update Now")
              └── SizedBox(16)
              └── TextButton(label: "Later")
```

### Actions
- **Update Now** - Opens Play Store / App Store
- **Later** - Allows dismissal (reminder shown later)

---

# PART 5: HOME & DISCOVERY

## 5.1 HomeScreen

**Path:** `lib/features/home/view/home_screen.dart`

### Widget Tree
```
Scaffold
  ├── backgroundColor: colorScheme.phoneBackground
  ├── appBar: AppBar
  │   ├── title: "SLine"
  │   ├── actions: [NotificationBadgeButton]
  │   └── elevation: 0
  └── body: CustomScrollView
      ├── slivers:
      │   ├── SliverToBoxAdapter(GreetingSection)
      │   ├── SliverToBoxAdapter(FiltersRow)
      │   ├── DiscoveryTaskSliver (lazy-load tasks)
      │   └── SliverToBoxAdapter(LoadMoreButton)
      └── onEndReached: loadMore()
```

### Home Sections
1. **Greeting Section** (Top)
   - Text: "Hi, [UserName]!"
   - Subtitle: "Discover tasks and opportunities"
   - Size: 24px top padding
   
2. **Filters Row**
   - Category filter button (with icon and text)
   - Filter modal button (Icon.tune)
   - Search icon (opens SearchScreen)
   - Pill-shaped buttons with teal text
   
3. **Tasks List (DiscoveryTaskSliver)**
   - Lazy-loaded task cards (20 at a time)
   - Cursor-based pagination
   - Pull-to-refresh gesture
   - Empty state: "No tasks found" message

### Colors
- Title text: colorScheme.text
- Subtitle: colorScheme.textSecondary
- Filter button text: AppColors.teal
- Background: colorScheme.phoneBackground

---

## 5.2 FiltersModal

**Path:** `lib/features/home/view/filters_modal.dart`

### Widget Tree
```
BottomSheet
  └── DraggableScrollableSheet
      ├── expand: false
      ├── initialChildSize: 0.7
      ├── minChildSize: 0.5
      ├── maxChildSize: 0.95
      └── builder: Column
          ├── DragHandle (top bar)
          ├── Padding(16)
          └── Column
              ├── Text("Filters", h5)
              ├── SizedBox(16)
              ├── FilterSection("Budget Range")
              │   └── RangeSlider (min: 0, max: 10000)
              ├── SizedBox(12)
              ├── FilterSection("Category")
              │   └── ListView.separated(CategoryChip)
              ├── SizedBox(12)
              ├── FilterSection("Complexity")
              │   └── Row(RadioButton options)
              ├── SizedBox(12)
              ├── FilterSection("Duration")
              │   └── SegmentedButton (1-week, 1-month, 3-month)
              ├── SizedBox(24)
              └── Row
                  ├── TextButton("Clear All")
                  └── AppButton("Apply Filters")
```

### Filter Options
- **Budget Range:** Slider from $0-$10,000 with display
- **Categories:** Multi-select chips (freelancing, design, writing, etc.)
- **Complexity:** Radio buttons (beginner, intermediate, advanced)
- **Duration:** Segmented buttons (< 1 week, 1-4 weeks, > 1 month)
- **Sorting:** Dropdown (newest, highest pay, closing soon)

### Actions
- **Apply Filters** - Updates HomeScreen task list, closes modal
- **Clear All** - Resets all filters to defaults

---

## 5.3 SearchScreen

**Path:** `lib/features/search/view/search_screen.dart`

### Widget Tree
```
Scaffold
  ├── appBar: AppBar
  │   ├── title: SearchTextField
  │   │   ├── autofocus: true
  │   │   ├── hintText: "Search tasks..."
  │   │   └── onChanged: filterResults()
  │   └── actions: [ClearButton]
  └── body: Consumer<SearchViewModel>
      └── _buildBody(ViewState)
          ├── loading: CircularProgressIndicator
          ├── loaded: ListView(SearchResultProfileCard)
          └── error: ErrorWidget
```

### Search Elements
- **Search TextField** - In AppBar, auto-focuses, real-time filtering
- **Results List** - SearchResultProfileCard items
- **Sort Options** - Dropdown (relevance, newest, trending)
- **Empty State** - "No results found for '[query]'"
- **Recent Searches** - List of previous searches with clear button

### Result Card Structure
```
Container
  ├── TaskCard or ProfileCard
  ├── Highlight: matching text in bold
  ├── Metadata: category, location, budget
  └── Tap: opens details screen
```

---

## 5.4 SearchResultProfileCard

**Path:** `lib/features/search/view/search_result_profile_card.dart`

### Widget Tree
```
GestureDetector
  ├── onTap: navigate to PublicProfileScreen
  └── child: Card
      └── Padding(12)
          └── Row
              ├── SignedAvatar(radius: 40)
              ├── SizedBox(12)
              ├── Expanded Column
              │   ├── Text(fullName, bodyLarge)
              │   ├── Text(title or role, bodySmall)
              │   ├── SizedBox(4)
              │   ├── Row(Star icon, rating, reviews count)
              │   ├── SizedBox(4)
              │   └── Text(hourlyRate or category, micro)
              └── Icon(Icons.arrow_forward)
```

### Display Elements
- **Avatar** - 40px circle, from storage
- **Name** - bodyLarge, teal color if highlighted
- **Title/Role** - bodySmall, textSecondary
- **Rating** - Star icon (#f3bb19) + numeric rating + count
- **Hourly Rate** - micro text, "$45/hr" format
- **Arrow Icon** - Indicates tappable

### Interaction
- Tap anywhere: Opens PublicProfileScreen
- No direct messaging from here (go to profile first)


---

# PART 6: TASKS & TENDERS

## 6.1 CreateTaskScreen

**Path:** `lib/features/tasks/view/create_task_screen.dart`

### Widget Tree
```
Scaffold
  ├── appBar: AppBar(back button, "Create Task")
  ├── backgroundColor: colorScheme.phoneBackground
  └── body: CustomScrollView
      ├── slivers:
      │   ├── SliverToBoxAdapter(FormSection)
      │   ├── SliverToBoxAdapter(DescriptionField)
      │   ├── SliverToBoxAdapter(BudgetSection)
      │   ├── SliverToBoxAdapter(DurationSection)
      │   ├── SliverToBoxAdapter(CategorySection)
      │   └── SliverToBoxAdapter(ButtonSection)
      └── bottomPadding: 48px
```

### Form Sections
1. **Task Title & Category**
   - TextField: "Task Title" (required, 100 char max)
   - Dropdown: Category selection (design, development, writing, etc.)
   
2. **Description**
   - TextFormField (multiline, 500 char max)
   - Placeholder: "Describe your task in detail..."
   
3. **Budget & Payment**
   - TextField: Budget amount
   - Dropdown: Currency (USD, AUD, etc.)
   - Checkbox: "Fixed price" vs "Hourly"
   
4. **Duration**
   - Dropdown: Expected duration (urgent, 1 week, 1 month, flexible)
   - DatePicker: Optional deadline
   
5. **Attachments**
   - Button: "Add Files" (image_picker)
   - Max 5 files
   - Shows preview grid

6. **Action Buttons**
   - AppButton: "Post Task" (creates task on Supabase)
   - TextButton: "Save as Draft"

### Validation
- Title: Required, 1-100 chars
- Description: Required, 10-500 chars
- Budget: Required, numeric, > 0
- Category: Required
- Duration: Required

### Colors & Spacing
- Field padding: 16px
- Section gap: 16px
- Title text: h5 (18px)
- Label text: bodyMedium
- Border radius: 8px on inputs

---

## 6.2 TaskDetailsScreen

**Path:** `lib/features/tasks/view/task_details_screen.dart`

### Widget Tree
```
Scaffold
  ├── appBar: AppBar(back, "Task Details")
  ├── body: Consumer<TaskViewModel>
  │   └── _buildBody(ViewState)
  │       ├── loading: Skeleton
  │       ├── loaded: CustomScrollView
  │       └── error: ErrorWidget
  └── bottomNavigationBar: ActionBar
      ├── Button: "Submit Proposal" or "Message Freelancer"
      └── Button: "Save Task"
```

### Content Sections (CustomScrollView)
1. **Header Section**
   - Task title (h3)
   - Budget display (h6, teal)
   - Status badge
   - Posted date (micro text)
   
2. **Task Info Row**
   - Category badge
   - Complexity level
   - Duration estimate
   - Location (if applicable)
   
3. **Description Section**
   - Full task description text
   - Formatted with proper spacing
   
4. **Requirements/Skills**
   - List of required skills (Chip widgets)
   - Teal background (#93ccce)
   
5. **Attachments Section**
   - SignedImage previews (if any)
   - Grid layout (2 columns)
   
6. **Client Profile Section**
   - Client avatar (SignedAvatar, 48px)
   - Client name (bodyMedium)
   - Client rating (star + count)
   - Tap: Opens PublicProfileScreen
   
7. **Similar Tasks Section**
   - Horizontal scroll view of TaskCard items
   - "See All" button

### Action Buttons
- **Submit Proposal** - Opens SubmitProposalSheet
- **Message Freelancer** - Opens ChatScreen with client
- **Save Task** - Adds to saved_tasks table
- **Share** - System share intent

---

## 6.3 TendersScreen

**Path:** `lib/features/tasks/view/tenders_screen.dart`

### Widget Tree
```
Scaffold
  ├── appBar: AppBar("My Tenders")
  ├── body: Consumer<TendersViewModel>
  │   └── CustomScrollView
  │       ├── slivers:
  │       │   ├── SliverAppBar(filters)
  │       │   ├── SliverList(TenderTaskCard)
  │       │   └── SliverToBoxAdapter(LoadMore)
  │       └── onEndReached: pagination
  └── floatingActionButton: CreateTaskFAB
```

### Tender List
- **TenderTaskCard items** - Each tender with:
  - Task title (bodyLarge)
  - Budget range (h6, teal)
  - Tender count badge
  - Status (open, closing soon, closed)
  - Posted date
  
- **Status Badges**
  - "Open" → Green/teal
  - "Closing Soon" → Yellow (#f3bb19)
  - "Closed" → Gray
  - Countdown timer (if < 24h)

### Filters
- Status: All, Open Only, Closing Soon
- Sort: Newest, Highest Budget, Closing Soon
- Category filter

### Empty State
- Icon + "No tenders yet"
- "Create your first tender" button

---

## 6.4 TenderPaymentScreen

**Path:** `lib/features/tasks/view/tender_payment_screen.dart`

### Widget Tree
```
Scaffold
  ├── appBar: AppBar("Confirm Tender")
  └── body: Column
      ├── TaskConceptSection (read-only task display)
      ├── SizedBox(16)
      ├── PaymentSummarySection
      │   ├── Text: "Budget: $500"
      │   ├── Text: "Platform fee: $10"
      │   ├── Divider
      │   └── Text: "Total: $510"
      ├── SizedBox(16)
      ├── PaymentMethodSection
      │   └── SelectPaymentMethod()
      ├── SizedBox(24)
      └── AppButton("Confirm & Pay")
```

### Payment Summary
- Budget from task (h6)
- Platform/tender fee (micro)
- Calculated total (h5, teal)
- Breakdown of costs

### Payment Method Selection
- Saved credit cards (masked)
- "Add New Card" option
- Apple Pay / Google Pay (if available)
- PayPal integration

### Confirmation
- Tap "Confirm & Pay"
- Redirect to payment gateway (QiCard or demo)
- Return with receipt
- Show success screen

---

## 6.5 TaskCard

**Path:** `lib/features/tasks/view/task_card.dart`

### Widget Tree
```
GestureDetector
  ├── onTap: navigate to TaskDetailsScreen
  └── child: GlassContainer
      ├── padding: 12
      ├── borderRadius: 16
      └── Column
          ├── Row
          │   ├── Expanded Column (title, category, budget)
          │   ├── SizedBox(8)
          │   └── Icon(Icons.bookmark_outline)
          ├── SizedBox(8)
          ├── Row (metadata)
          │   ├── Icon + "15 proposals"
          │   ├── Icon + "2 days left"
          │   └── Icon + "Freelancer needed"
          └── SizedBox(4)
          └── Text(posted date, micro)
```

### Display Elements
- **Title** - bodyLarge (task name, 1-2 lines max, truncated)
- **Category** - micro text, teal color
- **Budget** - h6, AppColors.gold or teal
- **Status Badge** - Right side (open, closing, closed)
- **Proposals Count** - Icon + count (bodySmall)
- **Time Left** - Icon + countdown (bodySmall)
- **Save Icon** - Outline or filled (if in saved list)
- **Posted Date** - micro text, gray

### Interactions
- Tap card: Open TaskDetailsScreen
- Tap bookmark icon: Save/unsave task
- Long press: Context menu (share, report)

### Colors
- Background: Glass effect
- Title: colorScheme.text
- Category: AppColors.teal
- Budget: AppColors.gold (#f3bb19)
- Border: white 0.1
- Time left text: AppColors.lightRed (if urgent)

---

## 6.6 TenderTaskCard

**Path:** `lib/features/tasks/view/tender_task_card.dart`

### Widget Tree
```
GestureDetector
  └── child: GlassContainer
      └── Column
          ├── Row
          │   ├── Expanded Column
          │   │   ├── Text(title, bodyLarge)
          │   │   ├── Text(budget, h6, teal)
          │   │   └── Row(category, complexity)
          │   └── Column
          │       ├── StatusBadge
          │       └── Text("X bids")
          ├── SizedBox(8)
          └── Row(duration, posted date)
```

### Specific Elements
- **Tender Count Badge** - "12 bids" or "1 bid" (micro, teal background)
- **Status Display** - "Open" / "Closing in 2h" / "Closed"
- **Bid Count** - Right side, teal text
- **Category Chip** - Small badge
- **Duration** - "1 week" format (micro)

---

## 6.7 BookingTaskCard

**Path:** `lib/features/booking/view/booking_task_card.dart`

### Widget Tree
```
GestureDetector
  └── child: Container
      └── Padding(12)
          └── Column
              ├── Row (title, status, price)
              ├── SizedBox(8)
              ├── Row (client name, rating, avatar)
              ├── SizedBox(8)
              └── Text(description, 2 lines)
```

### Display
- **Task Title** - bodyLarge
- **Status Badge** - Right aligned (accepted, pending, completed)
- **Budget** - h6, right aligned
- **Client Section** - Name + avatar + rating
- **Description Preview** - 2-line truncate, bodySmall
- **Date** - micro text, gray

---

## 6.8 TaskConceptSection

**Path:** `lib/features/tasks/view/task_concept_section.dart`

### Widget Tree
```
Container
  ├── padding: 16
  ├── decoration: CardDecoration
  └── Column
      ├── Text("Task Concept", h5)
      ├── SizedBox(12)
      ├── Row
      │   ├── Icon(category_icon)
      │   ├── SizedBox(8)
      │   └── Column
      │       ├── Text(task title, bodyMedium)
      │       ├── Text(category, bodySmall)
      │       └── Text(budget, h6)
      └── SizedBox(8)
      └── Text(description excerpt, bodyMedium, 3 lines)
```

### Purpose
Display quick task overview (title, category, budget, description preview)

### Colors
- Background: cardBackground
- Title: colorScheme.text
- Category: textSecondary
- Budget: AppColors.gold or teal

---

## 6.9 BookingLogisticsSection

**Path:** `lib/features/booking/view/booking_logistics_section.dart`

### Widget Tree
```
Container
  ├── padding: 16
  └── Column
      ├── Text("Logistics", h5)
      ├── SizedBox(12)
      ├── LogisticsRow("Duration", "2 weeks")
      ├── LogisticsRow("Complexity", "Intermediate")
      ├── LogisticsRow("Location", "Remote")
      └── LogisticsRow("Budget", "$500 USD")
```

### LogisticsRow Pattern
```
Row
  ├── Icon(icon_name)
  ├── SizedBox(8)
  ├── Expanded Text(label, bodySmall)
  └── Text(value, bodyMedium)
```

---

## 6.10 DiscoveryTaskSliver

**Path:** `lib/features/home/view/discovery_task_sliver.dart`

### Widget Tree
```
SliverList(
  delegate: SliverChildBuilderDelegate(
    (context, index) => Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TaskCard(task: tasks[index])
    ),
    childCount: tasks.length,
  )
)
```

### Behavior
- Lazy-loads tasks 20 at a time
- Cursor-based pagination (timestamp-based)
- Connected to HomeViewModel
- Pull-to-refresh from parent CustomScrollView

---

## 6.11 ExpirationCountdown

**Path:** `lib/features/tasks/view/expiration_countdown.dart`

### Widget Tree
```
Container
  ├── padding: 4,8
  ├── decoration: BoxDecoration(color: #f3bb19, borderRadius: 4)
  ├── child: Row
  │   ├── Icon(Icons.timer, 12px)
  │   └── Text("2 days 3h left", bodySmall)
```

### Display Logic
- Calculates remaining time from expires_at timestamp
- Updates every minute (using Stream or Timer)
- Color: Gold (#f3bb19) normally, Red (#f49d9d) if < 24h
- Format: "Xd Yh left" or "Xh Ym left" or "Expires today"

---

## 6.12 PaymentStatusBadge

**Path:** `lib/features/tasks/view/payment_status_badge.dart`

### Widget Tree
```
Container
  ├── padding: 6,12
  ├── decoration: BoxDecoration(color: statusColor, radius: 8)
  └── Text(statusText, caption)
```

### Status Mapping
- `pending` → Yellow background (#f3bb19), "Pending"
- `completed` → Green/Teal (#146068), "Completed"
- `refunded` → Gray (#9dbabb), "Refunded"
- `failed` → Red (#f49d9d), "Failed"

---

## 6.13 DashboardOfferCard

**Path:** `lib/features/dashboard/view/dashboard_offer_card.dart`

### Widget Tree
```
GlassContainer
  ├── padding: 12
  └── Column
      ├── Row
      │   ├── Column
      │   │   ├── Text(task title, bodyMedium)
      │   │   ├── Text(offer amount, h6, teal)
      │   │   └── Text(freelancer, bodySmall)
      │   └── StatusBadge (right)
      ├── SizedBox(8)
      └── Row (date, actions)
          ├── Text(posted date, micro)
          └── Row(AcceptButton, DeclineButton)
```

### Display Elements
- Task title (2 lines max)
- Offer amount (bold, teal, larger)
- Freelancer name
- Offer status badge
- Posted date
- Action buttons (Accept, Decline)

---

## 6.14 RequestsListScreen

**Path:** `lib/features/tasks/view/requests_list_screen.dart`

### Widget Tree
```
Scaffold
  ├── appBar: AppBar("Task Requests")
  └── body: Consumer<RequestsViewModel>
      └── ListView.separated(
          separatorBuilder: SizedBox(12),
          itemBuilder: RequestTile(request)
      )
```

### Content
- List of RequestTile widgets
- Cursor-based pagination
- Pull-to-refresh
- Empty state: "No requests yet"

---

## 6.15 SubmitRequestSheet

**Path:** `lib/features/tasks/view/submit_request_sheet.dart`

### Widget Tree
```
BottomSheet
  └── DraggableScrollableSheet
      └── Column
          ├── Text("Propose to Task", h5)
          ├── SizedBox(12)
          ├── TextField("Your proposal")
          ├── SizedBox(8)
          ├── TextField("Proposed amount", keyboardType: number)
          ├── SizedBox(8)
          ├── TextField("Duration", dropdown)
          ├── SizedBox(8)
          ├── CheckBox("I agree to terms")
          ├── SizedBox(16)
          └── Row(CancelButton, SubmitButton)
```

### Form Fields
- **Proposal Text** - TextFormField (required, 500 chars max)
- **Proposed Amount** - TextFormField (currency, required)
- **Duration** - Dropdown (1 week, 2 weeks, 1 month, flexible)
- **Terms Checkbox** - Required before submit

### Actions
- **Submit** - Creates proposal in Supabase
- **Cancel** - Closes sheet

---

## 6.16 RequestTile

**Path:** `lib/features/tasks/view/request_tile.dart`

### Widget Tree
```
GestureDetector
  ├── onTap: openRequestDetails
  └── child: Container
      └── Column
          ├── Row
          │   ├── Column(name, role)
          │   ├── Spacer
          │   └── Text(amount, h6)
          ├── SizedBox(8)
          ├── Text(proposal excerpt, bodySmall, 2 lines)
          ├── SizedBox(8)
          └── Row(timestamp, actionButtons)
```

### Display
- **Freelancer Name** - bodyMedium
- **Freelancer Title** - bodySmall, gray
- **Proposed Amount** - h6, teal
- **Proposal Preview** - 2-line text excerpt
- **Posted Time** - micro, gray
- **Action Buttons** - Accept / Decline / Message

---

## 6.17 RequestAwardDialog

**Path:** `lib/features/tasks/view/request_award_dialog.dart`

### Widget Tree
```
AlertDialog
  ├── title: Text("Award Task")
  ├── content: Column
  │   ├── Text("Confirm awarding task to [freelancer]?")
  │   ├── SizedBox(12)
  │   ├── Container(ProposalDetails)
  │   ├── SizedBox(12)
  │   ├── CheckBox("I've discussed terms")
  │   └── CheckBox("I understand the escrow")
  └── actions: [CancelButton, ConfirmButton]
```

### Confirmation Items
- Freelancer name and avatar
- Proposed amount (bold)
- Duration
- Description excerpt
- Two checkboxes for confirmation
- Cancel/Confirm buttons


---

# PART 7: CHAT & MESSAGING

## 7.1 MessagesScreen

**Path:** `lib/features/chat/view/messages_screen.dart`

### Widget Tree
```
Scaffold
  ├── appBar: AppBar("Messages")
  ├── body: Consumer<ChatViewModel>
  │   └── CustomScrollView
  │       ├── slivers:
  │       │   ├── SliverToBoxAdapter(SearchBar)
  │       │   ├── SliverList(ConversationListTile)
  │       │   └── SliverToBoxAdapter(LoadMore)
  │       └── onEndReached: pagination
  └── floatingActionButton: ComposeButton
```

### Content Sections
1. **Search Bar** - Text field to filter conversations
2. **Conversation List** - ConversationListTile items sorted by last message date
3. **Empty State** - "No conversations" with "Start a conversation" button

### Features
- Lazy-load conversations (20 at a time)
- Pull-to-refresh
- Swipe-to-archive (optional)
- Badge on unread count

---

## 7.2 ChatScreen

**Path:** `lib/features/chat/view/chat_screen.dart`

### Widget Tree
```
Scaffold
  ├── appBar: AppBar
  │   ├── title: OtherUserName
  │   ├── subtitle: onlineStatus
  │   └── actions: [InfoButton, MoreButton]
  ├── body: Column
  │   ├── Expanded ListView(MessageBubble)
  │   └── ChatInputBar
  └── resizeToAvoidBottomInset: true
```

### Message Display
- **MessageBubble** - For text messages (aligned by sender)
- **OfferMessageBubble** - For offer proposals (highlighted)
- **AttachmentMessageTile** - For file/image attachments
- Messages grouped by date
- Timestamps shown on hover/long-press

### Chat Input Bar
```
Row
  ├── IconButton(attachment)
  ├── Expanded TextField(message)
  │   └── hintText: "Type your message..."
  ├── IconButton(emoji) [optional]
  └── IconButton(send)
      └── onTap: sendMessage()
```

### Features
- Text input with auto-grow
- Attachment button (camera, gallery, files)
- Emoji picker (optional)
- Send button (enabled when text non-empty)
- Typing indicator
- Read receipts (checkmarks)
- Auto-scroll to latest message

### Colors
- Own messages: teal background (#146068), white text
- Other messages: cardBackground, dark text
- Timestamps: micro text, gray
- Online indicator: green dot

---

## 7.3 MessageBubble

**Path:** `lib/features/chat/view/message_bubble.dart`

### Widget Tree
```
Align
  ├── alignment: isOwn ? right : left
  └── child: Container
      ├── padding: 12,16 (8,12 if own)
      ├── decoration: BoxDecoration
      │   ├── color: isOwn ? teal : cardBackground
      │   ├── borderRadius: 12 (with higher corner on own side)
      │   └── border: subtle
      ├── constraints: maxWidth 70% of screen
      └── child: Column
          ├── Text(message, bodyMedium, color: isOwn ? white : text)
          └── Row
              ├── SizedBox(4)
              ├── Text(timestamp, micro)
              └── isOwn ? ReadReceipt : SizedBox()
```

### Display Elements
- **Message Text** - bodyMedium, wrapped
- **Timestamp** - micro text, gray (own) or lighter (other)
- **Read Receipt** - Double checkmark if delivered/read
- **Alignment** - Right for own messages, left for others
- **Color Scheme**
  - Own: AppColors.teal background, white text
  - Other: cardBackground, dark text

### Interactions
- Long press: Copy text, delete (own only)
- Tap: Show details (optional)

---

## 7.4 OfferMessageBubble

**Path:** `lib/features/chat/view/offer_message_bubble.dart`

### Widget Tree
```
Align
  ├── alignment: isOwn ? right : left
  └── child: Container
      ├── padding: 12
      ├── decoration: BoxDecoration
      │   ├── color: Color(0xFFFFF8DC) [light gold]
      │   ├── borderRadius: 12
      │   ├── border: Border(color: #f3bb19)
      │   └── boxShadow: [subtle]
      └── child: Column
          ├── Text("Offer Proposal", caption)
          ├── SizedBox(8)
          ├── Container(OfferDetails)
          │   ├── Row(offerAmount, duration)
          │   ├── Text(description)
          │   └── Row(AcceptButton, DeclineButton)
          └── SizedBox(4)
          └── Text(timestamp, micro)
```

### Offer Details
- **Amount** - h6, teal color
- **Duration** - bodySmall
- **Description** - bodyMedium (2-3 lines)
- **Accept/Decline Buttons** - Below description
- **Timestamp** - micro text

### Colors
- Background: Light gold (#FFF8DC)
- Border: AppColors.gold (#f3bb19)
- Amount: AppColors.teal
- Buttons: Accept (teal), Decline (red/pink)

---

## 7.5 AttachmentMessageTile

**Path:** `lib/features/chat/view/attachment_message_tile.dart`

### Widget Tree
```
Align
  └── child: Container
      ├── padding: 8
      ├── decoration: glass effect
      └── Column
          ├── SignedImage or document preview
          ├── SizedBox(8)
          ├── Text(filename, bodySmall)
          ├── Text(filesize, micro)
          └── Row
              ├── IconButton(download)
              └── IconButton(delete) [own only]
```

### File Types Support
- **Images** - Display thumbnail preview
- **Documents** - Show document icon + filename
- **Audio** - Show audio player widget
- **Video** - Show video thumbnail + duration

### Interactions
- Tap image: Full-screen viewer
- Tap document: Download or open in app
- Tap audio/video: Play in player
- Long press: Copy link, delete (own only)

---

## 7.6 ConversationListTile

**Path:** `lib/features/chat/view/conversation_list_tile.dart`

### Widget Tree
```
GestureDetector
  ├── onTap: openChatScreen
  └── child: Container
      ├── padding: 12
      ├── decoration: subtle border bottom
      └── Row
          ├── SignedAvatar(radius: 48)
          ├── SizedBox(12)
          ├── Expanded Column
          │   ├── Row
          │   │   ├── Text(userName, bodyMedium)
          │   │   ├── Spacer
          │   │   └── Text(timestamp, micro)
          │   ├── SizedBox(4)
          │   ├── Text(lastMessage preview, bodySmall)
          │   └── SizedBox(4) [unread indicator]
          └── SizedBox(8)
          └── unreadCount ? Badge(count) : SizedBox()
```

### Display Elements
- **Avatar** - 48px circle, from storage
- **User Name** - bodyMedium, teal if unread
- **Last Message Preview** - 1-line truncated, gray if read
- **Timestamp** - micro, right aligned
- **Unread Badge** - Red circle with white count (right side)
- **Online Status** - Green dot (if online)

### Interactions
- Tap: Open ChatScreen
- Swipe left: Archive (optional)
- Long press: Delete, mute notifications (optional)

---

## 7.7 ChatContextWidget

**Path:** `lib/features/chat/view/chat_context_widget.dart`

### Widget Tree
```
Container
  ├── padding: 12
  ├── backgroundColor: cardBackground.withOpacity(0.5)
  ├── borderRadius: 8
  └── Row
      ├── SignedImage(task image, 40x40) [optional]
      ├── SizedBox(8)
      ├── Expanded Column
      │   ├── Text("Task: [title]", bodySmall)
      │   ├── Text("Budget: $500", micro)
      │   └── Text("Status: [status]", micro)
      └── Icon(Icons.info)
```

### Purpose
Display context for chat (task details, offer details, booking details)

### Display
- Context type (Task, Offer, Booking)
- Title and amount
- Current status
- Tap to view full context

---

## 7.8 CreateOfferSheet

**Path:** `lib/features/chat/view/create_offer_sheet.dart`

### Widget Tree
```
BottomSheet
  └── DraggableScrollableSheet
      └── Column
          ├── Text("Create Offer", h5)
          ├── SizedBox(12)
          ├── TextField("Offer description")
          ├── SizedBox(12)
          ├── Row
          │   ├── TextField("Amount")
          │   ├── Dropdown("Currency")
          ├── SizedBox(12)
          ├── TextField("Duration", dropdown)
          ├── SizedBox(16)
          └── Row(CancelButton, SendOfferButton)
```

### Form Fields
- **Description** - TextFormField (required, 500 chars)
- **Amount** - TextFormField (required, numeric)
- **Currency** - Dropdown (USD, AUD, etc.)
- **Duration** - Dropdown (1 week, 2 weeks, 1 month, etc.)

### Actions
- **Send Offer** - Creates OfferMessageBubble, sends to Supabase
- **Cancel** - Closes sheet

---

# PART 8: DASHBOARD

## 8.1 DashboardScreen

**Path:** `lib/features/dashboard/view/dashboard_screen.dart`

### Widget Tree
```
Scaffold
  ├── appBar: AppBar("Dashboard")
  ├── body: TabBarView
  │   ├── Tab 1: OverviewTab
  │   ├── Tab 2: BookingsTab
  │   ├── Tab 3: WorkTab
  │   ├── Tab 4: WalletTab
  │   └── Tab 5: InboxTab
  └── bottomNavigationBar: TabBar
      ├── Tab 1: "Overview"
      ├── Tab 2: "Bookings"
      ├── Tab 3: "Work"
      ├── Tab 4: "Wallet"
      └── Tab 5: "Inbox"
```

### Tab Navigation
- Swipe to change tabs
- Tab bar at bottom (dark background, teal indicators)
- Each tab loads independently with Consumer<ViewModel>

---

## 8.2 OverviewTab

**Path:** `lib/features/dashboard/view/overview_tab.dart`

### Widget Tree
```
CustomScrollView
  └── slivers:
      ├── SliverToBoxAdapter(HeroCard)
      │   ├── Balance display
      │   ├── Quick action buttons
      │   └── Gradient background
      ├── SliverToBoxAdapter(DashboardCountersGrid)
      │   ├── Active tasks
      │   ├── Proposals
      │   ├── Ongoing bookings
      │   └── Messages waiting
      ├── SliverToBoxAdapter(NextActionsList)
      │   ├── "Pending proposals"
      │   └── List of action items
      └── SliverToBoxAdapter(ActivityFeedPreview)
          ├── Recent activity items
          └── "View all" link
```

### Sections
1. **Hero Card** - Balance, quick actions (view wallet, create task)
2. **Counters Grid** - 4 metrics in 2x2 grid
3. **Next Actions List** - Top 3 pending items
4. **Activity Feed** - Last 5 activities with timestamps

---

## 8.3 BookingsTab

**Path:** `lib/features/dashboard/view/bookings_tab.dart`

### Widget Tree
```
Consumer<DashboardViewModel>
  └── CustomScrollView
      ├── SliverToBoxAdapter(FilterChips)
      │   ├── All, Active, Completed, Cancelled
      │   └── onChanged: filterBookings()
      └── SliverList(DashboardBookingCard)
          └── separated by 12px SizedBox
```

### Booking Filters
- **All** - Show all bookings
- **Active** - Ongoing, not completed
- **Completed** - Finished and paid
- **Cancelled** - Cancelled or refunded

### Display
- DashboardBookingCard items for each booking
- Status badges (in progress, completed, etc.)
- Action buttons (message, view details)

---

## 8.4 WorkTab

**Path:** `lib/features/dashboard/view/work_tab.dart`

### Widget Tree
```
Consumer<DashboardViewModel>
  └── CustomScrollView
      ├── SliverToBoxAdapter(FilterChips)
      │   └── All, In Progress, Completed, Delivered
      ├── SliverList(WorkItemCard)
      │   └── item: work_item[index]
      └── SliverToBoxAdapter(EmptyState)
          └── "No work items" or LoadMoreButton
```

### Work Filters
- **All** - All work items
- **In Progress** - Currently active
- **Delivered** - Awaiting review
- **Completed** - Closed and paid

### Display
- WorkItemCard for each active work item
- Shows task info, status, deadline, client
- Action button: "View Details" → WorkItemDetailsScreen

---

## 8.5 WalletTab

**Path:** `lib/features/dashboard/view/wallet_tab.dart`

### Widget Tree
```
Consumer<WalletViewModel>
  └── CustomScrollView
      ├── SliverToBoxAdapter(WalletHeroCard)
      │   ├── Balance display
      │   ├── Available/Pending
      │   └── Withdraw button
      ├── SliverToBoxAdapter(FilterChips)
      │   └── All, Income, Expense, Pending
      └── SliverList(WalletTimelineCard)
          └── transaction_item[index]
```

### Wallet Display
- Hero card with total balance and pending
- Transaction history with filtering
- Income/expense indicators
- Withdraw funds button

---

## 8.6 InboxTab

**Path:** `lib/features/dashboard/view/inbox_tab.dart`

### Widget Tree
```
Consumer<DashboardViewModel>
  └── CustomScrollView
      ├── SliverToBoxAdapter(NotificationBadge)
      │   └── unread count
      ├── SliverToBoxAdapter(FilterChips)
      │   └── All, Proposals, Messages, Updates
      └── SliverList(NotificationTile)
          └── notification_item[index]
```

### Notification Filters
- **All** - All notifications
- **Proposals** - New proposals
- **Messages** - Unread messages
- **Updates** - System updates

### Display
- NotificationTile for each notification
- Badge showing unread count
- Mark as read on tap

---

## 8.7 DashboardCountersGrid

**Path:** `lib/features/dashboard/view/dashboard_counters_grid.dart`

### Widget Tree
```
Container
  ├── padding: 16
  └── GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        CounterCard("Active Tasks"),
        CounterCard("Proposals"),
        CounterCard("In Progress"),
        CounterCard("Messages")
      ]
    )
```

### CounterCard Pattern
```
Container
  ├── padding: 16
  ├── decoration: glass effect
  ├── borderRadius: 12
  └── Column
      ├── Icon(icon_data, 32px)
      ├── SizedBox(8)
      ├── Text(count, h5, teal)
      ├── SizedBox(4)
      └── Text(label, bodySmall)
```

### Metrics Displayed
- **Active Tasks** - Count of open tasks posted by user
- **Proposals** - Count of pending proposals waiting response
- **In Progress** - Count of active bookings
- **Messages** - Count of unread messages

### Colors
- Icon: AppColors.teal
- Count: h5, AppColors.teal
- Label: bodySmall, textSecondary
- Background: Glass effect

---

## 8.8 NextActionsList

**Path:** `lib/features/dashboard/view/next_actions_list.dart`

### Widget Tree
```
Container
  ├── padding: 16
  └── Column
      ├── Row
      │   ├── Text("Next Actions", h5)
      │   └── TextButton("View All")
      ├── SizedBox(12)
      └── ListView.separated(
          separatorBuilder: SizedBox(8),
          itemCount: min(actions.length, 3),
          itemBuilder: NextActionTile
        )
```

### Next Action Types
- **Pending Proposal Review** - "Review: Task Name | $XXX"
- **Expiring Tender** - "Closing in Xh | Task Name"
- **Payment Pending** - "Confirm payment | $XXX"
- **Delivery Awaiting Review** - "Review delivery | Task Name"
- **Message Awaiting Response** - "Reply to [User] | Message preview"

### Tile Pattern
```
Container
  └── Row
      ├── Icon(action_type_icon, 24px)
      ├── SizedBox(12)
      ├── Expanded Column
      │   ├── Text(action_title, bodyMedium)
      │   ├── Text(action_detail, bodySmall)
      │   └── Text(timestamp, micro)
      └── Icon(Icons.arrow_forward)
```

---

## 8.9 ActivityFeedPreview

**Path:** `lib/features/dashboard/view/activity_feed_preview.dart`

### Widget Tree
```
Container
  ├── padding: 16
  └── Column
      ├── Row
      │   ├── Text("Recent Activity", h5)
      │   └── TextButton("View All")
      ├── SizedBox(12)
      └── ListView.separated(
          separatorBuilder: Divider(),
          itemCount: min(activities.length, 5),
          itemBuilder: ActivityRow
        )
```

### Activity Types
- "You posted: Task Name" (24 mins ago)
- "[User] submitted proposal for Task Name" (2h ago)
- "Payment received: $500" (1 day ago)
- "Task completed: Task Name" (1 day ago)
- "Booking started: Task Name" (2 days ago)

### Activity Row Pattern
```
Row
  ├── Icon(activity_type_icon, 24px)
  ├── SizedBox(12)
  ├── Expanded Column
  │   ├── Text(activity_description, bodySmall)
  │   └── Text(timestamp, micro)
  └── Icon(Icons.arrow_forward)
```

---

## 8.10 WorkItemCard

**Path:** `lib/features/dashboard/view/work_item_card.dart`

### Widget Tree
```
GestureDetector
  ├── onTap: navigate to WorkItemDetailsScreen
  └── child: GlassContainer
      ├── padding: 12
      └── Column
          ├── Row
          │   ├── Column
          │   │   ├── Text(task_title, bodyMedium)
          │   │   ├── Text(client_name, bodySmall)
          │   │   └── Text(budget, h6, teal)
          │   └── StatusBadge (right)
          ├── SizedBox(8)
          ├── ProgressBar
          │   └── value: deliveryProgress
          ├── SizedBox(8)
          └── Row
              ├── Icon(Icons.schedule)
              ├── Text(dueDate, bodySmall)
              ├── Spacer
              └── Text(daysLeft, micro)
```

### Display Elements
- **Task Title** - bodyMedium
- **Client Name** - bodySmall, gray
- **Budget** - h6, teal
- **Status Badge** - "In Progress", "Delivered", "Completed"
- **Progress Bar** - LinearProgressIndicator (0-100%)
- **Due Date** - Icon + formatted date
- **Days Left** - Countdown or "Overdue"

### Interactions
- Tap: Open WorkItemDetailsScreen


---

# PART 9: BOOKING & PAYMENTS

## 9.1 BookingsDiscoveryScreen

**Path:** `lib/features/booking/view/bookings_discovery_screen.dart`

### Widget Tree
```
Scaffold
  ├── appBar: AppBar("Bookings")
  ├── body: Consumer<BookingViewModel>
  │   └── CustomScrollView
  │       ├── slivers:
  │       │   ├── SliverToBoxAdapter(FilterChips)
  │       │   ├── SliverList(BookingTaskCard)
  │       │   └── SliverToBoxAdapter(LoadMore)
  │       └── onEndReached: pagination
  └── floatingActionButton: CreateBookingFAB
```

### Content
- Filter chips (All, Available, Booked, Completed)
- List of BookingTaskCard items
- Cursor-based pagination (20 items per page)
- Empty state message

---

## 9.2 BookingsListScreen

**Path:** `lib/features/booking/view/bookings_list_screen.dart`

### Widget Tree
```
Scaffold
  ├── appBar: AppBar("My Bookings")
  ├── body: Consumer<BookingViewModel>
  │   └── CustomScrollView
  │       ├── slivers:
  │       │   ├── SliverToBoxAdapter(StatusFilter)
  │       │   └── SliverList(BookingCard)
  └── floatingActionButton: FAB
```

### Status Filters
- **All** - Show all bookings
- **Pending** - Awaiting acceptance
- **Active** - Ongoing work
- **Completed** - Finished and paid
- **Cancelled** - Cancelled or refunded

### Display
- BookingCard for each booking
- Sorted by status, then by creation date
- Pull-to-refresh
- Pagination

---

## 9.3 BookingDetailsScreen

**Path:** `lib/features/booking/view/booking_details_screen.dart`

### Widget Tree
```
Scaffold
  ├── appBar: AppBar(back, "Booking Details")
  ├── body: Consumer<BookingViewModel>
  │   └── _buildBody(ViewState)
  │       ├── loading: Skeleton
  │       ├── loaded: CustomScrollView
  │       └── error: ErrorWidget
  └── bottomNavigationBar: ActionBar
      └── [Status-specific action buttons]
```

### Content Sections
1. **Status Header**
   - Large status badge (pending, active, completed, cancelled)
   - Color-coded

2. **Booking Summary**
   - Task title and concept (TaskConceptSection)
   - Budget/payment amount
   - Duration and deadline

3. **Logistics**
   - Duration estimate
   - Location
   - Complexity
   - Category

4. **Client/Freelancer Profile**
   - Avatar, name, rating
   - Tap to view profile

5. **Timeline**
   - Created date
   - Accepted date (if applicable)
   - Delivery date (if applicable)
   - Completion date (if applicable)

6. **Messages**
   - Quick link to ChatScreen
   - Unread count badge

7. **Payment Details**
   - Amount breakdown
   - Platform fee
   - Payment method
   - Receipt (if paid)

8. **Actions Section**
   - Status-dependent buttons (Accept, Decline, Deliver, Review, Complete, Cancel)

---

## 9.4 PaymentCheckoutScreen

**Path:** `lib/features/booking/view/payment_checkout_screen.dart`

### Widget Tree
```
Scaffold
  ├── appBar: AppBar(back, "Confirm Payment")
  ├── body: Column
  │   ├── TaskConceptSection
  │   ├── SizedBox(16)
  │   ├── PaymentOrderSummaryCard
  │   ├── SizedBox(16)
  │   ├── PaymentMethodSection
  │   ├── SizedBox(16)
  │   ├── CheckBox("I agree to terms")
  │   └── SizedBox(24)
  └── BottomActionBar
      └── AppButton("Confirm Payment")
```

### Sections
1. **Task Concept** - TaskConceptSection (task details)
2. **Order Summary** - PaymentOrderSummaryCard (amount, fees, total)
3. **Payment Method** - Select from saved cards or add new
4. **Terms Checkbox** - Must be checked before payment
5. **Confirm Button** - Initiates payment flow

### Payment Process
- Tap "Confirm Payment"
- Redirect to QiCard/payment gateway
- Return with success/failure
- Show receipt screen

---

## 9.5 PaymentMethodScreen

**Path:** `lib/features/booking/view/payment_method_screen.dart`

### Widget Tree
```
Scaffold
  ├── appBar: AppBar("Payment Method")
  ├── body: Column
  │   ├── ListView
  │   │   ├── SavedCard tiles (radio selected)
  │   │   ├── Divider
  │   │   └── AddNewCard button
  │   └── SizedBox(24)
  └── BottomActionBar
      └── AppButton("Continue")
```

### Saved Cards Display
```
Container
  ├── padding: 12
  ├── decoration: glass effect
  └── Row
      ├── Radio(selected: card.id == selectedCardId)
      ├── SizedBox(12)
      ├── Expanded Column
      │   ├── Text("**** **** **** " + lastFour, bodyMedium)
      │   ├── Text(cardholderName, bodySmall)
      │   └── Text(expiryDate, micro)
      └── IconButton(delete) [if > 1 card]
```

### Add New Card
- Button opens CardFormModal
- Collects card number, expiry, CVV, cardholder name
- Validation on each field
- Save option (for future payments)

### Actions
- **Continue** - Proceeds to payment confirmation
- **Delete Card** - Long press or swipe (with confirmation)

---

## 9.6 PaymentReturnScreen

**Path:** `lib/features/booking/view/payment_return_screen.dart`

### Widget Tree
```
Scaffold
  └── body: Column (centered)
      ├── Icon(success/failure icon, 64px)
      ├── SizedBox(16)
      ├── Text(status title, h3)
      ├── SizedBox(12)
      ├── Text(status message, bodyMedium, center)
      ├── SizedBox(32)
      ├── (if success) ReceiptSection
      ├── SizedBox(24)
      └── AppButton("Return to Dashboard") or ("Retry")
```

### Success Display
- Green checkmark icon
- "Payment Successful" title
- Receipt details
- Order number
- Amount paid
- Date and time

### Failure Display
- Red X icon
- "Payment Failed" title
- Error reason
- "Retry" or "Use Different Card" button
- Support link

---

## 9.7 PaymentWebviewScreen

**Path:** `lib/features/booking/view/payment_webview_screen.dart`

### Widget Tree
```
Scaffold
  ├── appBar: AppBar("Payment", back: false)
  │   └── actions: [CancelButton]
  └── body: WebViewWidget
      ├── url: payment_gateway_url
      ├── onPageFinished: handleReturn
      └── javascriptMode: unrestricted
```

### Purpose
- Display payment gateway (QiCard) in WebView
- Handle payment form submission
- Intercept return URL to confirm payment

### Behavior
- WebView loads payment gateway URL
- User enters payment details
- On success, intercepts return URL
- Returns to PaymentReturnScreen with success
- Back/cancel button available (with confirmation)

---

## 9.8 BookingCard

**Path:** `lib/features/booking/view/booking_card.dart`

### Widget Tree
```
GestureDetector
  ├── onTap: navigate to BookingDetailsScreen
  └── child: GlassContainer
      ├── padding: 12
      └── Column
          ├── Row
          │   ├── Column
          │   │   ├── Text(task_title, bodyMedium)
          │   │   ├── Text(client_name, bodySmall)
          │   │   └── Text(budget, h6, teal)
          │   └── StatusBadge (right)
          ├── SizedBox(8)
          ├── Divider()
          ├── SizedBox(8)
          └── Row
              ├── Icon(Icons.schedule)
              ├── Text(dueDate, micro)
              ├── SizedBox(16)
              ├── Icon(Icons.person)
              └── Text(clientName, micro)
```

### Display Elements
- **Task Title** - bodyMedium
- **Client Name** - bodySmall, gray
- **Budget** - h6, teal
- **Status Badge** - Colored (pending, active, completed, cancelled)
- **Due Date** - Icon + formatted date
- **Client Name** - Icon + name

---

## 9.9 DashboardBookingCard

**Path:** `lib/features/dashboard/view/dashboard_booking_card.dart`

### Widget Tree
```
GestureDetector
  └── child: GlassContainer
      └── Column
          ├── Row
          │   ├── SignedAvatar(radius: 32)
          │   ├── SizedBox(12)
          │   ├── Expanded Column
          │   │   ├── Text(task_title, bodyMedium)
          │   │   ├── Text(client_name, bodySmall)
          │   │   └── Text(budget, h6, teal)
          │   └── StatusBadge
          ├── SizedBox(8)
          └── Row(actionButtons)
              ├── TextButton("View")
              └── TextButton("Message")
```

### Display
- Client avatar (32px)
- Task title
- Client name
- Budget (teal, larger)
- Status badge
- Action buttons

---

## 9.10 PaymentOrderSummaryCard

**Path:** `lib/features/booking/view/payment_order_summary_card.dart`

### Widget Tree
```
Container
  ├── padding: 16
  ├── decoration: glass effect
  ├── borderRadius: 12
  └── Column
      ├── Text("Order Summary", h5)
      ├── SizedBox(12)
      ├── SummaryRow("Task Price", "$500.00")
      ├── SummaryRow("Platform Fee", "$10.00")
      ├── Divider()
      ├── SummaryRow("Total", "$510.00", bold: true)
      └── SizedBox(8)
      └── Text("Tax included", caption)
```

### SummaryRow Pattern
```
Row
  ├── Text(label, bodyMedium)
  ├── Spacer
  └── Text(amount, bodyMedium or h6 if total)
```

### Display
- Line items (price, fees)
- Divider before total
- Total in bold/larger
- Tax note at bottom

---

# PART 10: PROFILE

## 10.1 ProfileScreen

**Path:** `lib/features/profile/view/profile_screen.dart`

### Widget Tree
```
Scaffold
  ├── backgroundColor: colorScheme.phoneBackground
  └── body: Consumer<ProfileViewModel>
      └── _buildBody(ViewState)
          ├── loading: CircularProgressIndicator
          ├── loaded: CustomScrollView
          └── error: ErrorWidget
```

### Content Sections (CustomScrollView)
1. **Profile Header Sliver**
   - Avatar (ProfileAvatarWidget, 80px)
   - User name (h3)
   - User title/role (bodySmall)
   - Verified badge (if applicable)
   - Online status indicator

2. **Action Buttons Row**
   - Edit Profile button
   - Share Profile button
   - Settings button

3. **Stats Section**
   - Job Success Rate (%)
   - Total Jobs (count)
   - Hourly Rate ($X/hr)

4. **Bio Section**
   - User bio/about text
   - "Edit" button overlay

5. **Services Section**
   - List of ServiceCard items
   - "Add Service" button

6. **Portfolio Section**
   - Grid of PortfolioTile items (masonry)
   - "Add Portfolio Item" button
   - "Manage Portfolio" link

7. **Reviews Section**
   - Average rating + star count
   - List of review cards (3 most recent)
   - "View All" link

### Colors & Typography
- Background: colorScheme.phoneBackground
- Avatar background: AppColors.gold
- Name: h3, colorScheme.text
- Title: bodySmall, textSecondary
- Verified badge: teal background, white text
- Stats: h6 for numbers, bodySmall for labels

---

## 10.2 EditProfileScreen

**Path:** `lib/features/profile/view/edit_profile_screen.dart`

### Widget Tree
```
Scaffold
  ├── appBar: AppBar(back, "Edit Profile")
  └── body: Consumer<ProfileViewModel>
      └── CustomScrollView
          ├── slivers:
          │   ├── SliverToBoxAdapter(ProfileAvatarSection)
          │   ├── SliverToBoxAdapter(FormFieldsSection)
          │   ├── SliverToBoxAdapter(SkillsSection)
          │   ├── SliverToBoxAdapter(BioSection)
          │   └── SliverToBoxAdapter(ButtonSection)
          └── bottomPadding: 48
```

### Form Sections
1. **Avatar Upload**
   - ProfileAvatarWidget (with edit button)
   - Upload progress indicator
   - Circular avatar, 80px

2. **Basic Info Fields**
   - Full Name (required, TextField)
   - Title/Role (optional, TextField)
   - Location (optional, TextField)
   - Hourly Rate (optional, TextField with currency)

3. **Skills Section**
   - ListView of Chip widgets
   - "Add Skill" button (opens dialog)
   - Delete button on each chip

4. **Bio Section**
   - TextFormField (multiline, 500 chars max)
   - Character counter

5. **Account Settings**
   - "Manage Portfolio" link
   - "Change Password" button
   - "Settings" link

6. **Action Buttons**
   - AppButton("Save Changes")
   - TextButton("Cancel")

### Validation
- Full Name: Required (trim whitespace)
- Title: Optional
- Location: Optional
- Hourly Rate: Optional, numeric if provided

### Loading State
- CircularProgressIndicator on avatar during upload
- Disabled button with spinner during save
- SnackBar for error messages

---

## 10.3 PublicProfileScreen

**Path:** `lib/features/profile/view/public_profile_screen.dart`

### Widget Tree
```
Scaffold
  ├── appBar: AppBar(back, actions: [ShareButton, MoreButton])
  ├── body: Consumer<PublicProfileViewModel>
  │   └── _buildBody(ViewState)
  └── bottomNavigationBar: ActionBar
      ├── MessageButton (text button)
      └── FavoriteButton (toggle button)
```

### Content (NestedScrollView with TabBarView)
1. **PublicProfileHeader**
   - Gradient background (teal → darkTeal)
   - Circular avatar (80px)
   - Online badge (if online)
   - Name and verified badge
   - Title/role

2. **PublicProfileStats**
   - 3-column layout
   - Job Success Rate (%) | Total Jobs | Hourly Rate
   - All in white text on teal background

3. **TabBarView** (4 tabs)
   - **About Tab** (PublicProfileAbout)
     - Bio text
     - Skills list (Chips)
     - Hourly rate
     
   - **Portfolio Tab** (PublicProfilePortfolio)
     - Masonry grid (2 columns)
     - PortfolioTile items
     
   - **Reviews Tab** (PublicProfileReviews)
     - Average rating (stars)
     - List of review cards
     
   - **More Tab** (PublicProfileMore)
     - Report button
     - Block button
     - Support link

### Action Buttons (Bottom)
- **Message Button** - Opens ChatScreen
- **Favorite Button** - Toggle icon (heart_outline / heart_filled)
- **Share Button** - System share intent

### Colors
- Header: Linear gradient (#146068 to #0c3b40)
- Avatar: white border, 80px radius
- Tab bar: white text on transparent, teal indicator
- Online badge: green circle

---

## 10.4 MyServicesScreen

**Path:** `lib/features/profile/view/my_services_screen.dart`

### Widget Tree
```
Scaffold
  ├── appBar: AppBar(back, "My Services")
  ├── body: Consumer<MyServicesViewModel>
  │   └── CustomScrollView
  │       ├── slivers:
  │       │   ├── SliverToBoxAdapter(ComingSoonBadge)
  │       │   ├── SliverList(ServiceCard)
  │       │   └── SliverToBoxAdapter(AddServiceButton)
  │       └── onEndReached: pagination
  └── floatingActionButton: AddServiceFAB
```

### Content
- "Coming Soon" badge at top (if feature not released)
- List of ServiceCard items (from user's created services)
- Grid layout (2 columns)
- Empty state: "No services yet"
- "Add Service" button/FAB

---

## 10.5 ManagePortfolioScreen

**Path:** `lib/features/profile/view/manage_portfolio_screen.dart`

### Widget Tree
```
Scaffold
  ├── appBar: AppBar(back, "Manage Portfolio")
  ├── body: Consumer<ProfileViewModel>
  │   └── CustomScrollView
  │       ├── slivers:
  │       │   ├── SliverList(PortfolioTile with swipe)
  │       │   └── SliverToBoxAdapter(AddButton)
  │       └── onEndReached: pagination
  └── floatingActionButton: AddPortfolioFAB
```

### Portfolio List
- **Swipe-to-Delete** - Slide left to delete (with confirm)
- **Edit** - Tap to open EditPortfolioSheet
- **Reorder** - Long press to drag and reorder
- **PortfolioTile** - Shows thumbnail, title, date

### Actions
- Add Portfolio Item (FAB or button at bottom)
- Edit Portfolio Item (PortfolioDetailsSheet)
- Delete Portfolio Item (swipe or context menu)
- Reorder Items (drag)

### Empty State
- Icon + "No portfolio items yet"
- "Add your first portfolio" button

---

## 10.6 SettingsScreen

**Path:** `lib/features/profile/view/settings_screen.dart`

### Widget Tree
```
Scaffold
  ├── appBar: AppBar(back, "Settings")
  └── body: Consumer<ThemeModeProvider>
      └── ListView
          ├── SettingsTile("Theme")
          │   └── Switch(ThemeModeProvider.isDarkMode)
          ├── SettingsTile("Notifications")
          │   └── Switch(notificationsEnabled)
          ├── SettingsTile("Privacy")
          │   └── Icon(arrow_forward)
          ├── SettingsTile("About")
          │   └── Text(version)
          ├── SettingsTile("Help & Support")
          │   └── Icon(arrow_forward)
          ├── Divider()
          ├── SettingsTile("Change Password")
          │   └── Icon(arrow_forward)
          ├── SettingsTile("Delete Account")
          │   └── Icon(arrow_forward, red)
          ├── Divider()
          └── SettingsTile("Log Out")
              └── onTap: logout()
```

### Settings Tiles
- **Theme** - Toggle dark/light mode
- **Notifications** - Enable/disable all notifications
- **Privacy** - Opens privacy policy/settings
- **About** - App version, legal links
- **Help & Support** - Contact support, FAQs
- **Change Password** - Opens password change flow
- **Delete Account** - Dangerous action (confirmation required)
- **Log Out** - Logs out user (confirmation required)

### SettingsTile Pattern
```
GlassContainer
  ├── padding: 16
  ├── borderRadius: 12
  └── Row
      ├── Icon(icon, 24px)
      ├── SizedBox(12)
      ├── Expanded Text(label, bodyMedium)
      └── (Switch or Icon)
```

### Colors
- Background: Glass effect
- Title: bodyMedium, text color
- Icons: teal for normal, red for delete
- Switches: teal when on, gray when off

---

## 10.7 ProfileAvatarWidget

**Path:** `lib/features/profile/view/profile_avatar_widget.dart`

### Widget Tree
```
Stack
  ├── child: CircleAvatar
  │   ├── radius: 40 (default, customizable)
  │   ├── backgroundImage: NetworkImage(signedUrl)
  │   ├── backgroundColor: AppColors.gold
  │   └── child: Icon (if no image)
  ├── Positioned (bottom-right)
  │   └── (enableEdit)
  │       ? Container
  │           ├── decoration: circle
  │           ├── backgroundColor: AppColors.teal
  │           └── child: IconButton(Icons.camera)
  │       : SizedBox()
  └── (isLoading)
      ? Positioned (overlay)
          └── CircularProgressIndicator
      : SizedBox()
```

### Properties
- **imageUrl** - String (path in Supabase storage)
- **radius** - double (default: 40)
- **enableEdit** - bool (shows edit button if true)
- **onEditPressed** - VoidCallback
- **isLoading** - bool (shows spinner overlay)

### Behavior
- Displays user avatar from storage
- Edit button (camera icon) if enableEdit=true
- Loading spinner during upload
- Tap edit → Image picker (camera or gallery)

### Colors
- Circle background: AppColors.gold (#f3bb19)
- Edit button: AppColors.teal (#146068)
- Spinner: AppColors.teal

---

## 10.8 ProfilePreviewModal

**Path:** `lib/features/profile/view/profile_preview_modal.dart`

### Widget Tree
```
DraggableScrollableSheet
  ├── expand: false
  ├── initialChildSize: 0.9
  ├── minChildSize: 0.5
  ├── maxChildSize: 0.95
  └── builder: Column
      ├── DragHandle (top bar)
      └── PublicProfileScreen (full content)
```

### Purpose
Bottom sheet modal wrapper for viewing public profiles from search results, chats, proposals, etc.

### Behavior
- Drag to dismiss
- Scroll PublicProfileScreen content inside
- Action buttons (Message, Favorite) work normally
- Close button: Drag down or tap outside

---

## 10.9 PublicProfileHeader

**Path:** `lib/features/profile/view/public_profile_header.dart`

### Widget Tree
```
Container
  ├── height: 200
  ├── decoration: LinearGradient
  │   ├── colors: [#146068, #0c3b40]
  │   ├── begin: topLeft
  │   └── end: bottomRight
  └── child: Stack
      ├── Column (centered, MainAxisAlignment.center)
      │   ├── CircleAvatar
      │   │   ├── radius: 80
      │   │   ├── backgroundImage: SignedImage
      │   │   └── border: white 2px
      │   ├── SizedBox(12)
      │   ├── Text(fullName, h3, white)
      │   ├── SizedBox(4)
      │   └── Row(verifiedBadge, onlineBadge)
      └── (online)
          ? Positioned (top-right)
              └── GreenOnlineBadge
          : SizedBox()
```

### Display Elements
- **Gradient Background** - Teal to dark teal, diagonal
- **Avatar** - 80px white-bordered circle
- **Name** - h3 typography, white text
- **Badges** - Verified (checkmark + "Verified"), Online (green dot)
- **Height** - 200px total

### Colors
- Gradient: #146068 to #0c3b40
- Avatar border: white
- Text: white (#ffffff)
- Online badge: green (#4CAF50)
- Verified badge: gold (#f3bb19)

---

## 10.10 PublicProfileStats

**Path:** `lib/features/profile/view/public_profile_stats.dart`

### Widget Tree
```
Container
  ├── height: 100
  ├── decoration: BoxDecoration
  │   ├── color: AppColors.teal
  │   └── borderRadius: BottomRounded(8)
  └── child: Row
      ├── StatColumn("92%", "Job Success")
      ├── VerticalDivider(white)
      ├── StatColumn("15", "Total Jobs")
      ├── VerticalDivider(white)
      └── StatColumn("$45/hr", "Hourly Rate")
```

### StatColumn Pattern
```
Expanded
  ├── mainAxisAlignment: center
  └── child: Column
      ├── Text(value, h6, white)
      ├── SizedBox(4)
      └── Text(label, bodySmall, white)
```

### Display
- **3-Column Layout** - Equal width columns
- **Values** - h6 typography, bold, white
- **Labels** - bodySmall, white
- **Dividers** - Vertical white lines between columns
- **Height** - 100px total

### Colors
- Background: AppColors.teal (#146068)
- Text: white (#ffffff)
- Dividers: white with opacity

---

## 10.11 PublicProfilePortfolio

**Path:** `lib/features/profile/view/public_profile_portfolio.dart`

### Widget Tree
```
Consumer<PublicProfileViewModel>
  └── (portfolio.isEmpty)
      ? Center(Text("No portfolio items"))
      : CustomScrollView
          ├── slivers:
          │   └── SliverGrid(
          │       gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          │         crossAxisCount: 2,
          │         mainAxisSpacing: 12,
          │         crossAxisSpacing: 12,
          │         childAspectRatio: 0.75
          │       ),
          │       delegate: SliverChildBuilderDelegate(
          │         (context, index) => PortfolioTile(portfolio[index])
          │       )
          │     )
```

### Portfolio Grid
- **2-Column Masonry Layout** - Responsive to screen width
- **Aspect Ratio** - 0.75 (portrait orientation)
- **Spacing** - 12px between items
- **PortfolioTile** - Image thumbnail with title overlay
- **Empty State** - "No portfolio items" centered text

---

## 10.12 PublicProfileReviews

**Path:** `lib/features/profile/view/public_profile_reviews.dart`

### Widget Tree
```
Consumer<PublicProfileViewModel>
  └── (reviews.isEmpty)
      ? Center(Text("No reviews yet"))
      : Column
          ├── Row
          │   ├── Row(5 stars, rating, count)
          │   │   ├── Row(Icon x5, filled/empty)
          │   │   ├── Text(4.8, h6)
          │   │   └── Text("(142 reviews)", bodySmall)
          │   └── Spacer
          │   └── TextButton("View All")
          ├── SizedBox(16)
          └── ListView.separated(
              separatorBuilder: Divider(),
              itemCount: min(reviews.length, 5),
              itemBuilder: ReviewCard
            )
```

### Review Card Pattern
```
Container
  ├── padding: 12
  ├── decoration: glass effect
  └── Column
      ├── Row
      │   ├── CircleAvatar(reviewer.avatar, 32px)
      │   ├── SizedBox(12)
      │   ├── Expanded Column
      │   │   ├── Text(reviewerName, bodyMedium)
      │   │   ├── Row(stars, rating, date)
      │   │   └── SizedBox(4)
      │   └── (own review)
      │       ? IconButton(delete)
      │       : SizedBox()
      ├── SizedBox(8)
      └── Text(reviewText, bodySmall, 3 lines)
```

### Display Elements
- **Average Rating** - 5 stars (filled/half/empty) + numeric score + count
- **Review Cards**
  - Reviewer avatar (32px)
  - Reviewer name (bodyMedium)
  - Star rating
  - Posted date (micro)
  - Review text (3-line preview)
- **View All** - Link to full reviews list

### Colors
- Stars: AppColors.gold (#f3bb19)
- Rating text: h6, teal
- Review background: Glass effect
- Date: micro, gray


---

# PART 11: PORTFOLIO

## 11.1 PortfolioScreen

**Path:** `lib/features/portfolio/view/portfolio_screen.dart`

### Widget Tree
```
Scaffold
  ├── appBar: AppBar("Portfolio")
  ├── body: Consumer<PortfolioViewModel>
  │   └── CustomScrollView
  │       ├── slivers:
  │       │   ├── SliverGrid (2-column masonry)
  │       │   │   └── PortfolioTile(item)
  │       │   │       ├── onTap: showDetailsSheet
  │       │   │       └── onLongPress: editMenu
  │       │   └── SliverToBoxAdapter(EmptyState)
  │       └── onEndReached: pagination
  └── floatingActionButton: AddPortfolioFAB
```

### Portfolio Grid Display
- **2-Column Grid** - Masonry layout with different heights
- **Aspect Ratio** - 0.75 per item (portrait)
- **Spacing** - 12px between items
- **PortfolioTile** - Image with overlay title, date
- **Empty State** - "No portfolio items yet" with "Add" button
- **Pagination** - Cursor-based, 20 items per page

### Interactions
- **Tap** - Opens PortfolioDetailsSheet (view/edit)
- **Long Press** - Context menu (edit, delete, move)
- **FAB** - Opens AddPortfolioSheet (new item)

---

## 11.2 AddPortfolioSheet

**Path:** `lib/features/portfolio/view/add_portfolio_sheet.dart`

### Widget Tree
```
BottomSheet
  └── DraggableScrollableSheet
      ├── expand: false
      ├── initialChildSize: 0.8
      └── builder: Column
          ├── DragHandle
          ├── Padding(16)
          └── Column
              ├── Text("Add Portfolio Item", h5)
              ├── SizedBox(12)
              ├── ImagePickerSection
              │   └── "Upload Image" button
              ├── SizedBox(12)
              ├── TextField("Title")
              ├── SizedBox(12)
              ├── TextField("Description", multiline)
              ├── SizedBox(12)
              ├── ChipsInput("Tags")
              ├── SizedBox(24)
              └── Row(CancelButton, SaveButton)
```

### Form Fields
- **Image** - Picker (camera/gallery), preview thumbnail
- **Title** - TextFormField (required, 50 chars max)
- **Description** - TextFormField (optional, 500 chars max)
- **Tags** - ChipsInput (optional, up to 5 tags)

### Validation
- Title: Required, non-empty
- Image: At least one image required

### Actions
- **Save** - Creates portfolio item, adds to grid, closes sheet
- **Cancel** - Closes sheet without saving

---

## 11.3 EditPortfolioSheet

**Path:** `lib/features/portfolio/view/edit_portfolio_sheet.dart`

### Widget Tree
```
BottomSheet
  └── DraggableScrollableSheet
      └── Column
          ├── DragHandle
          ├── Padding(16)
          └── Column
              ├── Text("Edit Portfolio Item", h5)
              ├── SizedBox(12)
              ├── SignedImage(currentImage, 120x120)
              ├── SizedBox(12)
              ├── TextButton("Change Image")
              ├── SizedBox(16)
              ├── TextField("Title")
              ├── SizedBox(12)
              ├── TextField("Description", multiline)
              ├── SizedBox(12)
              ├── ChipsInput("Tags")
              ├── SizedBox(24)
              └── Row
                  ├── TextButton("Delete")
                  ├── Spacer
                  ├── TextButton("Cancel")
                  └── FilledButton("Save")
```

### Form Fields
- Same as AddPortfolioSheet
- Pre-filled with current data

### Actions
- **Save** - Updates item, closes sheet
- **Delete** - Shows confirmation dialog, removes from grid
- **Cancel** - Closes sheet without saving

---

## 11.4 PortfolioDetailsSheet

**Path:** `lib/features/portfolio/view/portfolio_details_sheet.dart`

### Widget Tree
```
BottomSheet
  └── DraggableScrollableSheet
      ├── expand: false
      ├── initialChildSize: 0.9
      └── builder: Column
          ├── DragHandle + CloseButton
          ├── Padding(16)
          └── Column
              ├── SignedImage(fullImage, 300x300)
              ├── SizedBox(16)
              ├── Text(title, h5)
              ├── SizedBox(4)
              ├── Text(date, micro)
              ├── SizedBox(16)
              ├── Text(description, bodyMedium)
              ├── SizedBox(12)
              ├── Row(tags as Chips)
              ├── SizedBox(24)
              └── Row
                  ├── TextButton("Edit")
                  └── TextButton("Delete")
```

### Display
- **Image** - Full-width, scrollable
- **Title** - h5 typography
- **Date** - micro text, gray
- **Description** - Full text, bodyMedium
- **Tags** - Chips row (read-only)
- **Edit/Delete** - Action buttons at bottom

### Interactions
- Drag to close
- Tap Edit → Opens EditPortfolioSheet
- Tap Delete → Confirmation dialog, removes item
- Swipe image left/right → Previous/next item (if in grid context)

---

## 11.5 PortfolioTile

**Path:** `lib/features/portfolio/view/portfolio_tile.dart`

### Widget Tree
```
GestureDetector
  ├── onTap: onTap callback
  ├── child: Container
  │   ├── decoration: BoxDecoration(borderRadius: 12)
  │   ├── clipBehavior: hardEdge
  │   └── child: Stack
  │       ├── SignedImage(image, fit: cover)
  │       ├── Positioned(
  │           bottom: 0,
  │           left: 0,
  │           right: 0,
  │           child: Container(
  │             decoration: LinearGradient(black.withOpacity(0) → 0.6),
  │             padding: 12,
  │             child: Column(
  │               crossAxisAlignment: start,
  │               children: [
  │                 Text(title, bodyMedium, white),
  │                 SizedBox(4),
  │                 Text(date, micro, white)
  │               ]
  │             )
  │           )
  │         )
```

### Display Elements
- **Image** - Full coverage, object fit
- **Title Overlay** - Bottom left, white text on gradient
- **Date Overlay** - Below title, micro text, white
- **Gradient Overlay** - Black gradient from bottom (0 → 0.6 opacity)
- **Border Radius** - 12px rounded corners

### Interactions
- Tap: onTap callback (usually opens PortfolioDetailsSheet)
- Long press: Edit menu (optional)

### Colors
- Text overlay: white (#ffffff)
- Gradient: Black with variable opacity
- Border: None (seamless image)

---

## 11.6 ImagePlaceholder

**Path:** `lib/features/portfolio/view/image_placeholder.dart`

### Widget Tree
```
Container
  ├── color: Colors.grey[300]
  ├── child: Center
  │   └── Column
  │       ├── Icon(Icons.image, size: 48)
  │       ├── SizedBox(8)
  │       └── Text("No Image", bodySmall)
```

### Purpose
Placeholder shown when portfolio item image fails to load

### Display
- Gray background
- Large image icon (48px)
- "No Image" text below

---

# PART 12: PROPOSALS & DIRECT OFFERS

## 12.1 ProposalsListScreen

**Path:** `lib/features/proposals/view/proposals_list_screen.dart`

### Widget Tree
```
Scaffold
  ├── appBar: AppBar("My Proposals")
  ├── body: Consumer<ProposalsViewModel>
  │   └── CustomScrollView
  │       ├── slivers:
  │       │   ├── SliverToBoxAdapter(FilterChips)
  │       │   ├── SliverList(ProposalTile)
  │       │   └── SliverToBoxAdapter(LoadMore)
  │       └── onEndReached: pagination
  └── floatingActionButton: CreateProposalFAB [optional]
```

### Proposal Filters
- **All** - Show all proposals
- **Pending** - Awaiting client response
- **Accepted** - Client accepted proposal
- **Declined** - Client declined proposal
- **Expired** - Proposal expired (task no longer open)

### Display
- **ProposalTile** - Each proposal with status
- **Status Badges** - Pending (yellow), Accepted (green), Declined (red)
- **Pagination** - Cursor-based, 20 per page
- **Empty State** - "No proposals yet"

---

## 12.2 ProposalDetailsModal

**Path:** `lib/features/proposals/view/proposal_details_modal.dart`

### Widget Tree
```
Dialog
  ├── title: Text("Proposal Details")
  └── content: Column
      ├── TaskConceptSection (task info)
      ├── SizedBox(12)
      ├── PaymentOrderSummaryCard
      ├── SizedBox(12)
      ├── Container(ProposalText)
      │   ├── padding: 12
      │   ├── decoration: glass effect
      │   ├── borderRadius: 8
      │   └── Text(proposalText, bodyMedium)
      ├── SizedBox(12)
      ├── Container(ClientMessage)
      │   └── Text(clientResponse, bodySmall)
      ├── SizedBox(12)
      └── Row
          ├── TextButton("Close")
          ├── FilledButton("Withdraw") [if pending]
          └── FilledButton("Message Client")
```

### Display Sections
1. **Task Concept** - Task details (title, category, description)
2. **Payment Summary** - Proposed amount, platform fee, total
3. **Proposal Text** - Full proposal message (glass background)
4. **Client Response** - If client declined, reason shown here
5. **Action Buttons** - Close, Withdraw (if pending), Message

### Colors
- Background: Dialog white/dark
- Proposal box: Glass effect
- Client message: Gray background
- Amount: h6, teal
- Status badge: Colored per status

---

## 12.3 ProposalPaymentScreen

**Path:** `lib/features/proposals/view/proposal_payment_screen.dart`

### Widget Tree
```
Scaffold
  ├── appBar: AppBar(back, "Confirm Proposal")
  ├── body: Column
  │   ├── TaskConceptSection
  │   ├── SizedBox(16)
  │   ├── ProposalDetailsCard
  │   ├── SizedBox(16)
  │   ├── PaymentOrderSummaryCard
  │   ├── SizedBox(16)
  │   ├── PaymentMethodSection
  │   ├── SizedBox(16)
  │   ├── CheckBox("I agree to terms")
  │   └── SizedBox(24)
  └── BottomActionBar
      └── AppButton("Confirm & Pay")
```

### Content Sections
- Task details
- Proposal summary (amount, duration)
- Payment breakdown (amount, fees, total)
- Payment method selection
- Terms checkbox
- Confirm button

---

## 12.4 SubmitProposalSheet

**Path:** `lib/features/proposals/view/submit_proposal_sheet.dart`

### Widget Tree
```
BottomSheet
  └── DraggableScrollableSheet
      └── Column
          ├── Text("Submit Proposal", h5)
          ├── SizedBox(12)
          ├── TextField("Your Proposal")
          ├── SizedBox(12)
          ├── TextField("Proposed Amount")
          ├── SizedBox(12)
          ├── TextField("Duration", dropdown)
          ├── SizedBox(8)
          ├── CheckBox("I agree to terms")
          ├── SizedBox(16)
          └── Row(CancelButton, SubmitButton)
```

### Form Fields
- **Proposal Text** - TextFormField (required, 500 chars)
- **Amount** - TextFormField (required, numeric)
- **Duration** - Dropdown (1 week, 2 weeks, 1 month, flexible)
- **Terms Checkbox** - Required

### Actions
- **Submit** - Creates proposal, shows success, closes sheet
- **Cancel** - Closes sheet

---

## 12.5 ProposalTile

**Path:** `lib/features/proposals/view/proposal_tile.dart`

### Widget Tree
```
GestureDetector
  ├── onTap: navigate to ProposalDetailsModal
  └── child: GlassContainer
      ├── padding: 12
      └── Column
          ├── Row
          │   ├── Column
          │   │   ├── Text(taskTitle, bodyMedium)
          │   │   ├── Text(amount, h6, teal)
          │   │   └── Text(clientName, bodySmall)
          │   └── StatusBadge
          ├── SizedBox(8)
          └── Row(duration, proposedDate)
              ├── Icon(duration)
              ├── Text(duration, bodySmall)
              ├── SizedBox(16)
              └── Text(proposedDate, micro)
```

### Display Elements
- **Task Title** - bodyMedium
- **Proposed Amount** - h6, teal
- **Client Name** - bodySmall, gray
- **Status Badge** - Pending (yellow), Accepted (green), Declined (red)
- **Duration** - Icon + text
- **Proposed Date** - micro text, gray

---

## 12.6 DirectOfferDetailsScreen

**Path:** `lib/features/direct_offers/view/direct_offer_details_screen.dart`

### Widget Tree
```
Scaffold
  ├── appBar: AppBar(back, "Direct Offer")
  ├── body: Consumer<DirectOfferViewModel>
  │   └── _buildBody(ViewState)
  │       ├── loading: Skeleton
  │       ├── loaded: CustomScrollView
  │       └── error: ErrorWidget
  └── bottomNavigationBar: ActionBar
      ├── (if pending) AcceptButton, DeclineButton
      ├── (if accepted) MessageButton
      └── CancelButton
```

### Content Sections
1. **Client Profile**
   - Avatar (48px)
   - Name and rating
   - Tap to view full profile

2. **Offer Details**
   - "Direct Offer from [Client]"
   - Proposed amount (h6, teal)
   - Duration estimate
   - Posted date

3. **Offer Message**
   - Client's message/description
   - Formatted text

4. **Payment Summary**
   - PaymentOrderSummaryCard
   - Amount breakdown
   - Total (with platform fee)

5. **Terms & Conditions**
   - "I agree to offer terms" checkbox
   - Links to terms

6. **Action Buttons**
   - **Accept** - Accepts offer, starts booking
   - **Decline** - Declines offer (with optional reason)
   - **Message** - Opens ChatScreen with client

### Colors
- Amount: AppColors.teal (#146068)
- Accept button: Green/teal
- Decline button: Red (#f49d9d)
- Background: Glass effect cards

---

# PART 13: WALLET

## 13.1 WalletDashboardScreen

**Path:** `lib/features/wallet/view/wallet_dashboard_screen.dart`

### Widget Tree
```
Scaffold
  ├── appBar: AppBar("Wallet")
  ├── body: Consumer<WalletViewModel>
  │   └── CustomScrollView
  │       ├── slivers:
  │       │   ├── SliverToBoxAdapter(WalletHeroCard)
  │       │   ├── SliverToBoxAdapter(QuickActionButtons)
  │       │   ├── SliverToBoxAdapter(SectionHeader)
  │       │   └── SliverList(WalletTimelineCard)
  │       └── onEndReached: pagination
```

### Content Sections
1. **Hero Card** - Balance, pending, actions
2. **Quick Actions** - Withdraw, Add Payment Method
3. **Transaction History** - Filtered and paginated
4. **Filters** - All, Income, Expense, Pending

---

## 13.2 WalletScreen

**Path:** `lib/features/wallet/view/wallet_screen.dart`

### Widget Tree
```
Scaffold
  ├── appBar: AppBar(back, "Wallet")
  └── body: WalletSharedBody()
      └── [Same content as WalletDashboardScreen]
```

### Purpose
Full wallet screen (shown in navigation tab or as route)

---

## 13.3 WalletHeroCard

**Path:** `lib/features/wallet/view/wallet_hero_card.dart`

### Widget Tree
```
Container
  ├── decoration: LinearGradient(teal → darkTeal)
  ├── padding: 24
  ├── borderRadius: 16
  └── Column
      ├── Row
      │   ├── Column
      │   │   ├── Text("Available Balance", bodySmall, white)
      │   │   ├── SizedBox(4)
      │   │   ├── Text("$1,234.56", h3, white)
      │   │   └── SizedBox(12)
      │   │   └── Row(Icon + "$432.10 Pending")
      │   └── Spacer
      │   └── Icon(Icons.credit_card, 48px, white)
      ├── SizedBox(24)
      └── Row
          ├── AppButton("Withdraw", onPressed: showWithdrawModal)
          ├── SizedBox(12)
          └── GlassButton("Add Funds")
```

### Display Elements
- **Title** - "Available Balance" (bodySmall, white)
- **Balance** - Large amount (h3, white)
- **Pending** - Icon + amount (bodySmall, white)
- **Action Buttons** - Withdraw, Add Funds
- **Gradient Background** - Teal to dark teal

### Colors
- Background: Linear gradient (#146068 → #0c3b40)
- Text: white (#ffffff)
- Icons: white
- Buttons: AppButton (teal), GlassButton (semi-transparent)

---

## 13.4 WalletSharedBody

**Path:** `lib/features/wallet/view/wallet_shared_body.dart`

### Widget Tree
```
CustomScrollView
  └── slivers:
      ├── SliverToBoxAdapter(WalletHeroCard)
      ├── SliverToBoxAdapter(FilterChips)
      │   └── All, Income, Expense, Pending
      ├── SliverList(WalletSnapshotCard or WalletTimelineCard)
      └── SliverToBoxAdapter(LoadMore)
```

### Purpose
Shared wallet content used in both WalletDashboardScreen and WalletScreen

### Display Modes
- **Snapshot View** - Monthly/weekly summaries
- **Timeline View** - Individual transactions

---

## 13.5 WalletSnapshotCard

**Path:** `lib/features/wallet/view/wallet_snapshot_card.dart`

### Widget Tree
```
GlassContainer
  ├── padding: 16
  └── Column
      ├── Row
      │   ├── Column
      │   │   ├── Text("March 2026", bodyMedium)
      │   │   ├── Text("Income", bodySmall)
      │   │   └── Text("+$1,250", h6, green)
      │   └── Spacer
      │   └── Icon(Icons.expand_more)
      ├── SizedBox(8)
      ├── Divider()
      ├── SizedBox(8)
      ├── Row
      │   ├── Column
      │   │   ├── Text("Expenses", bodySmall)
      │   │   └── Text("-$450", h6, red)
      │   └── Spacer
      │   └── Column
      │       ├── Text("Net", bodySmall)
      │       └── Text("+$800", h6, teal)
      └── SizedBox(8)
      └── LinearProgressIndicator (income/expense ratio)
```

### Display
- Month/period header
- Income (green, positive)
- Expenses (red, negative)
- Net (teal, highlighted)
- Progress bar showing ratio
- Tap to expand and see transactions

---

## 13.6 WalletTimelineCard

**Path:** `lib/features/wallet/view/wallet_timeline_card.dart`

### Widget Tree
```
Container
  ├── padding: 12
  ├── decoration: subtle border bottom
  └── Row
      ├── Icon(transactionType_icon, 32px)
      ├── SizedBox(12)
      ├── Expanded Column
      │   ├── Text(transactionDescription, bodyMedium)
      │   ├── Text(transactionType, bodySmall)
      │   └── Text(date, micro)
      └── Column
          ├── Text(amount, h6, colorByType)
          └── StatusBadge(status)
```

### Transaction Types
- **Income** - Green text, Icon: arrow_downward
  - "Completed booking"
  - "Task payment received"
  - "Proposal accepted - $500"
  
- **Expense** - Red text, Icon: arrow_upward
  - "Platform fee"
  - "Tender listing fee"
  - "Refund issued"
  
- **Pending** - Yellow text, Icon: hourglass
  - "Payment pending"
  - "Withdrawal processing"

### Display Elements
- **Icon** - Transaction type (income/expense/pending)
- **Description** - Full transaction detail
- **Type** - Secondary label
- **Date** - micro text, timestamp
- **Amount** - h6, color per type
- **Status** - Badge (pending, completed, failed)

### Colors
- Income: Green (#4CAF50)
- Expense: Red (#f49d9d)
- Pending: Yellow (#f3bb19)
- Background: White/transparent


---

# PART 14: WORK MANAGEMENT

## 14.1 WorkItemDetailsScreen

**Path:** `lib/features/work/view/work_item_details_screen.dart`

### Widget Tree
```
Scaffold
  ├── appBar: AppBar(back, "Work Details")
  ├── body: Consumer<WorkViewModel>
  │   └── _buildBody(ViewState)
  │       ├── loading: Skeleton
  │       ├── loaded: CustomScrollView
  │       └── error: ErrorWidget
  └── bottomNavigationBar: WorkItemBottomActions
```

### Content Sections
1. **Status Header** - Large status badge (in progress, delivered, completed)
2. **Task Overview** - TaskConceptSection (task details)
3. **Booking Details** - WorkItemBookingDetails
4. **Client Profile** - Avatar, name, rating
5. **Order Management** - OrderManagementPanel (if applicable)
6. **Messages** - Link to ChatScreen
7. **Timeline** - Activity log (created, accepted, delivered, completed)
8. **Deliverables** - List of submitted work items
9. **Payment Summary** - Amount, status, receipt

### Conditional Sections
- **In Progress** - "Submit Delivery" button, deadline info, progress
- **Delivered** - "Awaiting Review" message, client actions
- **Completed** - Receipt and download link

---

## 14.2 OrderManagementPanel

**Path:** `lib/features/work/view/order_management_panel.dart`

### Widget Tree
```
Container
  ├── padding: 16
  ├── decoration: glass effect
  ├── borderRadius: 12
  └── Column
      ├── Text("Order Management", h5)
      ├── SizedBox(12)
      ├── OrderManagementSection
      │   └── [status-specific actions]
      ├── SizedBox(16)
      ├── Divider()
      ├── SizedBox(16)
      └── Row(actionButtons)
          ├── FilledButton("Request Extension") [if in progress]
          ├── FilledButton("Submit Delivery") [if in progress]
          ├── FilledButton("Review Delivery") [if delivered]
          └── TextButton("Cancel Order")
```

### Sections
- Current status display
- Timeline of state changes
- Action buttons (contextual)
- Messaging link to client

---

## 14.3 OrderManagementSection

**Path:** `lib/features/work/view/order_management_section.dart`

### Widget Tree
```
Column
  ├── OrderStatusRow("Order Started", startedDate, icon, color)
  ├── OrderStatusRow("Work In Progress", progressDate, icon, color)
  ├── OrderStatusRow("Delivery Submitted", deliveryDate, icon, color)
  └── OrderStatusRow("Order Completed", completedDate, icon, color)
```

### OrderStatusRow Pattern
```
Row
  ├── Column(icon, vertical line)
  ├── SizedBox(12)
  ├── Expanded Column
  │   ├── Text(status, bodyMedium)
  │   ├── Text(timestamp, micro)
  │   └── (if active) CircularProgressIndicator
  └── Text(daysAgo, micro)
```

### Display
- Status line (vertical timeline)
- Completed items: Green checkmark
- Active item: Yellow hourglass + spinner
- Pending items: Gray X
- Timestamps on each

---

## 14.4 WorkLogTile

**Path:** `lib/features/work/view/work_log_tile.dart`

### Widget Tree
```
Container
  ├── padding: 12
  ├── decoration: subtle border
  └── Row
      ├── Icon(activityType_icon)
      ├── SizedBox(12)
      ├── Expanded Column
      │   ├── Text(activityDescription, bodyMedium)
      │   ├── Text(activityType, bodySmall)
      │   └── Text(timestamp, micro)
      └── Icon(Icons.arrow_forward)
```

### Activity Types
- "Work started"
- "Milestone completed"
- "Delivery submitted"
- "Revision requested"
- "Order completed"
- "Payment released"

---

## 14.5 SubmitDeliveryModal

**Path:** `lib/features/work/view/submit_delivery_modal.dart`

### Widget Tree
```
Dialog
  ├── title: Text("Submit Delivery")
  └── content: Column
      ├── Text("Add deliverables", h5)
      ├── SizedBox(12)
      ├── FilePickerSection
      │   ├── "Upload Files" button
      │   └── Preview list
      ├── SizedBox(12)
      ├── TextField("Delivery Notes")
      ├── SizedBox(12)
      ├── CheckBox("I confirm delivery is complete")
      ├── SizedBox(24)
      └── Row
          ├── TextButton("Cancel")
          └── FilledButton("Submit Delivery")
```

### Form Fields
- **Files** - Multiple file picker (images, documents, etc.)
- **Notes** - TextFormField (optional, 500 chars)
- **Confirmation Checkbox** - Required
- **Submit Button** - Disabled until checkbox checked

### Actions
- **Submit** - Creates delivery record, notifies client
- **Cancel** - Closes dialog

---

## 14.6 ReviewDeliveryModal

**Path:** `lib/features/work/view/review_delivery_modal.dart`

### Widget Tree
```
Dialog
  ├── title: Text("Review Delivery")
  └── content: Column
      ├── Text("Review freelancer's work", h5)
      ├── SizedBox(12)
      ├── FilePreviewGallery
      │   └── [submitted deliverables]
      ├── SizedBox(12)
      ├── Text(freelancerNotes, bodySmall)
      ├── SizedBox(16)
      ├── RadioGroup("How satisfied are you?")
      │   ├── Radio("Approve - Work is complete")
      │   ├── Radio("Request revisions")
      │   └── Radio("Not satisfied - Request cancellation")
      ├── SizedBox(12)
      ├── TextField("Comments/Feedback")
      ├── SizedBox(24)
      └── Row
          ├── TextButton("Cancel")
          └── FilledButton("Submit Review")
```

### Review Options
- **Approve** - Work accepted, payment released to freelancer
- **Request Revisions** - Work goes back to freelancer, deadline extended
- **Cancel Order** - Requests refund (requires both parties' agreement)

### Submission
- Tap "Submit Review"
- Shows confirmation
- Creates review record in database

---

## 14.7 RequestExtensionModal

**Path:** `lib/features/work/view/request_extension_modal.dart`

### Widget Tree
```
Dialog
  ├── title: Text("Request Time Extension")
  └── content: Column
      ├── Text("How many additional days do you need?", bodyMedium)
      ├── SizedBox(12)
      ├── Row
      │   ├── IconButton(-) 
      │   ├── Text(extensionDays, h5, center)
      │   └── IconButton(+)
      ├── SizedBox(8)
      ├── Text("New deadline: [date]", micro, gray)
      ├── SizedBox(16)
      ├── TextField("Reason for extension")
      ├── SizedBox(24)
      └── Row
          ├── TextButton("Cancel")
          └── FilledButton("Request Extension")
```

### Fields
- **Days Selector** - +/- buttons (1-7 days, default: 3)
- **New Deadline** - Automatically calculated and displayed
- **Reason** - TextFormField (optional, 200 chars)

### Submission
- Tap "Request Extension"
- Sends notification to client
- Awaits client approval
- If approved, deadline is updated

---

## 14.8 WorkItemBookingDetails

**Path:** `lib/features/work/view/work_item_booking_details.dart`

### Widget Tree
```
Container
  ├── padding: 16
  ├── decoration: glass effect
  ├── borderRadius: 12
  └── Column
      ├── Text("Booking Details", h5)
      ├── SizedBox(12)
      ├── DetailRow("Budget", "$500.00")
      ├── DetailRow("Duration", "2 weeks")
      ├── DetailRow("Started", "March 1, 2026")
      ├── DetailRow("Deadline", "March 15, 2026")
      ├── DetailRow("Days Left", "3 days")
      ├── SizedBox(12)
      ├── Divider()
      ├── SizedBox(12)
      └── DetailRow("Status", StatusBadge)
```

### DetailRow Pattern
```
Row
  ├── Text(label, bodySmall)
  ├── Spacer
  └── Text(value, bodyMedium or h6)
```

### Display
- Budget (bold, teal)
- Duration estimate
- Start and end dates
- Days remaining (red if overdue)
- Current status badge

---

## 14.9 WorkItemBottomActions

**Path:** `lib/features/work/view/work_item_bottom_actions.dart`

### Widget Tree
```
BottomAppBar
  └── Row
      ├── (status: in_progress)
      │   ├── TextButton("Contact Support")
      │   ├── Spacer
      │   └── FilledButton("Submit Delivery")
      ├── (status: delivered)
      │   ├── Spacer
      │   └── FilledButton("Review Delivery")
      ├── (status: completed)
      │   ├── TextButton("Download Receipt")
      │   ├── Spacer
      │   └── TextButton("Message Freelancer")
      └── (status: cancelled)
          └── Center(Text("Order Cancelled"))
```

### Button Actions
- **Submit Delivery** - Opens SubmitDeliveryModal
- **Review Delivery** - Opens ReviewDeliveryModal
- **Contact Support** - Opens support chat
- **Download Receipt** - Downloads invoice PDF
- **Message** - Opens ChatScreen

---

## 14.10 WorkItemGuardWidgets

**Path:** `lib/features/work/view/work_item_guard_widgets.dart`

### Purpose
Conditional widgets based on user role (freelancer vs client)

### Display Logic
- **Freelancer View** - Submit delivery, request extension buttons
- **Client View** - Review delivery, approve/revise buttons
- **Both** - Message freelancer, view timeline, contact support

### Implementations
- `FreelancerWorkItemView` - Freelancer-specific UI
- `ClientWorkItemView` - Client-specific UI
- `SharedWorkItemView` - Common UI for both

---

# PART 15: NOTIFICATIONS

## 15.1 NotificationsModal

**Path:** `lib/features/notifications/view/notifications_modal.dart`

### Widget Tree
```
BottomSheet
  └── DraggableScrollableSheet
      ├── expand: false
      ├── initialChildSize: 0.8
      └── builder: Column
          ├── DragHandle
          ├── Row
          │   ├── Text("Notifications", h5)
          │   ├── Spacer
          │   └── TextButton("Clear All")
          ├── SizedBox(12)
          ├── FilterChips("All", "Unread", "Proposals", "Messages")
          ├── SizedBox(12)
          └── ListView.separated(
              separatorBuilder: Divider(),
              itemBuilder: NotificationTile
            )
```

### Filters
- **All** - All notifications
- **Unread** - Only unread
- **Proposals** - Proposal notifications
- **Messages** - Message notifications
- **System** - System updates

### Display
- NotificationTile items
- Sorted by date (newest first)
- Pull-to-refresh
- Pagination

### Actions
- Tap notification: Navigate to relevant screen
- Swipe to dismiss: Hides notification
- "Clear All": Marks all as read

---

## 15.2 NotificationBadgeButton

**Path:** `lib/features/notifications/view/notification_badge_button.dart`

### Widget Tree
```
Stack
  ├── child: IconButton(Icons.notifications_none)
  │   ├── onPressed: showNotificationsModal()
  │   └── icon color: teal
  └── (unreadCount > 0)
      ? Positioned(
          top: 0,
          right: 0,
          child: Badge(
            backgroundColor: #f49d9d,
            label: Text(unreadCount)
          )
        )
      : SizedBox()
```

### Display
- Notification bell icon (teal)
- Red badge with unread count (top-right)
- Badge only shows if unreadCount > 0

### Interaction
- Tap: Opens NotificationsModal

---

## 15.3 NotificationTile

**Path:** `lib/features/notifications/view/notification_tile.dart`

### Widget Tree
```
GestureDetector
  ├── onTap: navigate to relevant screen
  └── child: Container
      ├── color: isRead ? transparent : Colors.blue.withOpacity(0.1)
      ├── padding: 12
      └── Row
          ├── (isUnread)
          │   ? Container(
          │       width: 8,
          │       height: 8,
          │       decoration: circle,
          │       color: teal
          │     )
          │   : SizedBox(width: 8)
          ├── SizedBox(12)
          ├── Expanded Column
          │   ├── Text(notificationTitle, bodyMedium)
          │   ├── Text(notificationMessage, bodySmall)
          │   └── Text(timestamp, micro)
          └── Icon(Icons.arrow_forward)
```

### Display Elements
- **Unread Indicator** - Small teal circle (left side)
- **Title** - Notification type/action
- **Message** - Full notification text
- **Timestamp** - Relative time (2h ago, yesterday, etc.)
- **Read State** - Background color indicates read/unread

### Notification Types
- "New proposal received"
- "Proposal accepted"
- "Task completed"
- "Payment received"
- "Message from [user]"
- "Booking started"
- "Delivery submitted"
- "System announcement"

---

# PART 16: SAVED, FAVORITES, CATEGORIES, SERVICES

## 16.1 SavedTasksScreen

**Path:** `lib/features/saved/view/saved_tasks_screen.dart`

### Widget Tree
```
Scaffold
  ├── appBar: AppBar("Saved Tasks")
  ├── body: Consumer<SavedViewModel>
  │   └── CustomScrollView
  │       ├── slivers:
  │       │   ├── SliverList(SavedTaskTile)
  │       │   └── SliverToBoxAdapter(LoadMore)
  │       └── onEndReached: pagination
  └── (empty) EmptyStateWidget
```

### Content
- List of SavedTaskTile items
- Cursor-based pagination (20 per page)
- Pull-to-refresh
- Empty state: "No saved tasks"

---

## 16.2 SavedTaskTile

**Path:** `lib/features/saved/view/saved_task_tile.dart`

### Widget Tree
```
GestureDetector
  ├── onTap: navigate to TaskDetailsScreen
  └── child: Container
      ├── padding: 12
      ├── decoration: subtle border
      └── Row
          ├── Column
          │   ├── Text(taskTitle, bodyMedium)
          │   ├── Text(category, bodySmall)
          │   └── Text(budget, h6)
          ├── Spacer
          ├── Column
          │   ├── Text(savedDate, micro)
          │   ├── SizedBox(8)
          │   └── IconButton(
          │       icon: Icons.bookmark_filled,
          │       color: teal,
          │       onPressed: removeSave()
          │     )
```

### Display
- Task title (2 lines max)
- Category (small, gray)
- Budget (bold, teal)
- Saved date (micro, right)
- Bookmark button (filled, indicates saved)

### Interaction
- Tap: Opens TaskDetailsScreen
- Tap bookmark: Removes from saved (with SnackBar confirmation)

---

## 16.3 FavoritesScreen

**Path:** `lib/features/favorites/view/favorites_screen.dart`

### Widget Tree
```
Scaffold
  ├── appBar: AppBar("Favorites")
  ├── body: Consumer<FavoritesViewModel>
  │   └── CustomScrollView
  │       ├── slivers:
  │       │   ├── SliverGrid(2-column grid)
  │       │   │   └── FavoriteCard(profile)
  │       │   └── SliverToBoxAdapter(LoadMore)
  │       └── onEndReached: pagination
  └── (empty) EmptyStateWidget
```

### Grid Display
- 2-column grid layout
- FavoriteCard items
- Responsive to screen width
- Empty state: "No favorite freelancers"

---

## 16.4 FavoriteCard

**Path:** `lib/features/favorites/view/favorite_card.dart`

### Widget Tree
```
GestureDetector
  ├── onTap: navigate to PublicProfileScreen
  └── child: Stack
      ├── Container
      │   ├── decoration: glass effect
      │   ├── borderRadius: 12
      │   ├── padding: 12
      │   └── Column
      │       ├── SignedAvatar(radius: 48)
      │       ├── SizedBox(8)
      │       ├── Text(name, bodyMedium, center)
      │       ├── Text(title, bodySmall, center)
      │       ├── SizedBox(4)
      │       ├── Row(starRating, center)
      │       ├── SizedBox(8)
      │       └── AppButton("View Profile")
      └── Positioned(top-right)
          └── IconButton(
              icon: Icons.favorite_filled,
              color: #f49d9d,
              onPressed: removeFavorite()
            )
```

### Display Elements
- **Avatar** - 48px circle
- **Name** - bodyMedium, centered
- **Title/Role** - bodySmall, centered
- **Rating** - Stars + count
- **View Profile Button** - Full width, teal
- **Remove Button** - Heart icon, top-right

### Interaction
- Tap card: Opens PublicProfileScreen
- Tap heart icon: Removes from favorites (with SnackBar confirmation)

---

## 16.5 CategoriesScreen

**Path:** `lib/features/categories/view/categories_screen.dart`

### Widget Tree
```
Scaffold
  ├── appBar: AppBar("Categories")
  ├── body: GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      padding: 16,
      children: [
        CategoryCard("Design"),
        CategoryCard("Development"),
        CategoryCard("Writing"),
        CategoryCard("Marketing"),
        // ... more categories
      ]
    )
```

### Grid Display
- 2-column grid
- 16px spacing
- CategoryCard items
- Responsive to screen width

### Categories
- Design (UI/UX, Graphic Design, Logo Design)
- Development (Web, Mobile, Backend, Full Stack)
- Writing (Content, Technical, Creative)
- Marketing (Social Media, SEO, Email)
- Business (Virtual Assistant, Consulting)
- Other (All other categories)

---

## 16.6 ServiceCard

**Path:** `lib/features/services/view/service_card.dart`

### Widget Tree
```
GestureDetector
  ├── onTap: navigate to ServiceDetailsScreen [if applicable]
  └── child: GlassContainer
      ├── padding: 12
      └── Column
          ├── Row
          │   ├── Icon(serviceType_icon, 32px)
          │   ├── SizedBox(12)
          │   ├── Expanded Column
          │   │   ├── Text(serviceName, bodyMedium)
          │   │   ├── Text(serviceCategory, bodySmall)
          │   │   └── Text(startingPrice, h6)
          │   └── Icon(Icons.arrow_forward)
          ├── SizedBox(8)
          └── Text(serviceDescription, bodySmall, 2 lines)
```

### Display Elements
- **Icon** - Service type icon (32px)
- **Name** - bodyMedium (service name)
- **Category** - bodySmall (gray)
- **Starting Price** - h6, teal
- **Description** - 2-line preview, bodySmall
- **Arrow Icon** - Indicates tappable

### Interaction
- Tap: Opens ServiceDetailsScreen (if applicable) or shows details modal
- Long press: Edit/delete menu (if own service)

---

# PART 17: MASTER SUMMARY & FILE INDEX

## Complete Design System Summary

### Color Reference Table

| Color Name | Hex Code | Usage | Component |
|------------|----------|-------|-----------|
| Teal | #146068 | Primary buttons, active states, headings | AppColors.teal |
| Dark Teal | #0c3b40 | Darker variant, gradients | AppColors.darkTeal |
| Light Teal | #93ccce | Secondary actions, badges, hover | AppColors.lightTeal |
| Gold | #f3bb19 | Accents, avatars, star ratings | AppColors.gold |
| Light Red | #f49d9d | Danger actions, alerts, delete | AppColors.lightRed |
| Medium Grey Blue | #9dbabb | Secondary text, disabled states | AppColors.mediumGreyBlue |
| White | #ffffff | Light backgrounds, text on dark | AppColors.white |

### Typography Reference Table

| Style | Size | Weight | Usage |
|-------|------|--------|-------|
| h3 | 24px | Bold | Screen titles |
| h5 | 18px | SemiBold | Section headers |
| h6 | 16px | SemiBold | Stat values, emphasis |
| bodyLarge | 16px | Medium | Button text, CTAs |
| bodyMedium | 14px | Regular | Standard text, labels |
| bodySmall | 12px | Regular | Secondary text |
| caption/captionBold | 11px | Regular/Bold | Badges, labels |
| micro | 10px | Regular | Timestamps, metadata |

### Spacing Reference Table

| Token | Size | Usage |
|-------|------|-------|
| p4 | 4px | Micro spacing |
| p8 | 8px | Small padding, separators |
| p12 | 12px | Small spacing, gaps |
| p16 | 16px | Standard padding, sections |
| p24 | 24px | Major spacing, margins |
| p32 | 32px | Large spacing, breaks |
| p48 | 48px | Bottom padding, nav clearance |

### Border Radius Reference Table

| Token | Size | Usage |
|-------|------|-------|
| r8 | 8px | Text fields, small containers |
| r12 | 12px | Back buttons, icons |
| r16 | 16px | Cards, standard containers |
| r20 | 20px | Large cards, avatars |
| r24 | 24px | Modals, dialogs |

---

## Provider Dependencies Summary

### Core Providers (lib/main.dart)

**Authentication & User Management**
- `AuthSessionViewModel` - Login/logout state
- `ProfileViewModel` - User profile data
- `PublicProfileViewModel` - Public profile viewing

**Navigation & Theme**
- `NavigationProvider` - Tab navigation state
- `ThemeModeProvider` - Dark/light mode toggle

**Feature-Specific Providers**
- `HomeViewModel` - Home screen tasks/filters
- `TasksViewModel` - Tasks list and management
- `ChatViewModel` - Chat list and messaging
- `BookingViewModel` - Bookings and direct offers
- `DashboardViewModel` - Dashboard data
- `WalletViewModel` - Wallet and transactions
- `NotificationsViewModel` - Notifications
- `ProposalsViewModel` - Proposals management
- `WorkViewModel` - Work items and deliverables
- `SavedViewModel` - Saved tasks
- `FavoritesViewModel` - Favorite freelancers
- `SearchViewModel` - Search results

**Utility Providers**
- `DeepLinkService` - Deep link routing
- `PaymentService` - Payment handling
- `AccountGuardService` - Account restriction checks
- `SupabaseConfig` - Backend configuration

---

## Complete File Index (115+ Files)

### App Shell (2 files)
- lib/app/main_navigation_screen.dart - Root navigator
- lib/app/main.dart - App initialization, provider setup

### Core System (25 files)
**Widgets (13)**
- lib/core/widgets/app_button.dart
- lib/core/widgets/app_text_field.dart
- lib/core/widgets/glass_container.dart
- lib/core/widgets/glass_card.dart
- lib/core/widgets/glass_button.dart
- lib/core/widgets/scale_button.dart
- lib/core/widgets/circle_icon_button.dart
- lib/core/widgets/signed_avatar.dart
- lib/core/widgets/signed_image.dart
- lib/core/widgets/skeleton_card.dart
- lib/core/widgets/skeleton_loader.dart
- lib/core/widgets/status_badge.dart
- lib/core/widgets/custom_bottom_nav_bar.dart
- lib/core/widgets/sliver_tab_bar_delegate.dart

**Design System (5)**
- lib/core/theme/app_colors.dart
- lib/core/theme/app_typography.dart
- lib/core/theme/app_dimens.dart
- lib/core/theme/app_decorations.dart
- lib/core/theme/app_theme.dart

**Services (5)**
- lib/core/services/supabase_config.dart
- lib/core/services/logger_service.dart
- lib/core/services/payment_service.dart
- lib/core/services/deep_link_service.dart
- lib/core/services/account_guard_service.dart

**Utilities (2)**
- lib/core/utils/format_date.dart
- lib/core/utils/error_mapper.dart

### Features (88 files)

**Auth (7 files)**
- lib/features/auth/view/login_screen.dart
- lib/features/auth/view/signup_screen.dart
- lib/features/auth/view/forgot_password_screen.dart
- lib/features/auth/view/reset_password_update_screen.dart
- lib/features/auth/view/account_restricted_screen.dart
- lib/features/auth/view/maintenance_screen.dart
- lib/features/auth/view/update_required_screen.dart

**Home & Discovery (4 files)**
- lib/features/home/view/home_screen.dart
- lib/features/home/view/filters_modal.dart
- lib/features/search/view/search_screen.dart
- lib/features/search/view/search_result_profile_card.dart

**Tasks & Tenders (13 files)**
- lib/features/tasks/view/create_task_screen.dart
- lib/features/tasks/view/task_details_screen.dart
- lib/features/tasks/view/tenders_screen.dart
- lib/features/tasks/view/tender_payment_screen.dart
- lib/features/tasks/view/task_card.dart
- lib/features/tasks/view/tender_task_card.dart
- lib/features/tasks/view/task_concept_section.dart
- lib/features/tasks/view/booking_logistics_section.dart
- lib/features/tasks/view/discovery_task_sliver.dart
- lib/features/tasks/view/expiration_countdown.dart
- lib/features/tasks/view/payment_status_badge.dart
- lib/features/tasks/view/requests_list_screen.dart
- lib/features/tasks/view/request_tile.dart
- lib/features/tasks/view/request_award_dialog.dart
- lib/features/tasks/view/submit_request_sheet.dart

**Chat (8 files)**
- lib/features/chat/view/messages_screen.dart
- lib/features/chat/view/chat_screen.dart
- lib/features/chat/view/message_bubble.dart
- lib/features/chat/view/offer_message_bubble.dart
- lib/features/chat/view/attachment_message_tile.dart
- lib/features/chat/view/conversation_list_tile.dart
- lib/features/chat/view/chat_context_widget.dart
- lib/features/chat/view/create_offer_sheet.dart

**Dashboard (10 files)**
- lib/features/dashboard/view/dashboard_screen.dart
- lib/features/dashboard/view/overview_tab.dart
- lib/features/dashboard/view/bookings_tab.dart
- lib/features/dashboard/view/work_tab.dart
- lib/features/dashboard/view/wallet_tab.dart
- lib/features/dashboard/view/inbox_tab.dart
- lib/features/dashboard/view/dashboard_counters_grid.dart
- lib/features/dashboard/view/next_actions_list.dart
- lib/features/dashboard/view/activity_feed_preview.dart
- lib/features/dashboard/view/work_item_card.dart
- lib/features/dashboard/view/dashboard_offer_card.dart
- lib/features/dashboard/view/dashboard_booking_card.dart

**Booking & Payments (10 files)**
- lib/features/booking/view/bookings_discovery_screen.dart
- lib/features/booking/view/bookings_list_screen.dart
- lib/features/booking/view/booking_details_screen.dart
- lib/features/booking/view/payment_checkout_screen.dart
- lib/features/booking/view/payment_method_screen.dart
- lib/features/booking/view/payment_return_screen.dart
- lib/features/booking/view/payment_webview_screen.dart
- lib/features/booking/view/booking_card.dart
- lib/features/booking/view/booking_task_card.dart
- lib/features/booking/view/payment_order_summary_card.dart

**Profile (11 files)**
- lib/features/profile/view/profile_screen.dart
- lib/features/profile/view/edit_profile_screen.dart
- lib/features/profile/view/public_profile_screen.dart
- lib/features/profile/view/my_services_screen.dart
- lib/features/profile/view/manage_portfolio_screen.dart
- lib/features/profile/view/settings_screen.dart
- lib/features/profile/view/profile_avatar_widget.dart
- lib/features/profile/view/profile_preview_modal.dart
- lib/features/profile/view/public_profile_header.dart
- lib/features/profile/view/public_profile_stats.dart
- lib/features/profile/view/public_profile_portfolio.dart
- lib/features/profile/view/public_profile_reviews.dart

**Portfolio (6 files)**
- lib/features/portfolio/view/portfolio_screen.dart
- lib/features/portfolio/view/add_portfolio_sheet.dart
- lib/features/portfolio/view/edit_portfolio_sheet.dart
- lib/features/portfolio/view/portfolio_details_sheet.dart
- lib/features/portfolio/view/portfolio_tile.dart
- lib/features/portfolio/view/image_placeholder.dart

**Proposals & Direct Offers (6 files)**
- lib/features/proposals/view/proposals_list_screen.dart
- lib/features/proposals/view/proposal_details_modal.dart
- lib/features/proposals/view/proposal_payment_screen.dart
- lib/features/proposals/view/submit_proposal_sheet.dart
- lib/features/proposals/view/proposal_tile.dart
- lib/features/direct_offers/view/direct_offer_details_screen.dart

**Wallet (6 files)**
- lib/features/wallet/view/wallet_dashboard_screen.dart
- lib/features/wallet/view/wallet_screen.dart
- lib/features/wallet/view/wallet_hero_card.dart
- lib/features/wallet/view/wallet_shared_body.dart
- lib/features/wallet/view/wallet_snapshot_card.dart
- lib/features/wallet/view/wallet_timeline_card.dart

**Work Management (10 files)**
- lib/features/work/view/work_item_details_screen.dart
- lib/features/work/view/order_management_panel.dart
- lib/features/work/view/order_management_section.dart
- lib/features/work/view/work_log_tile.dart
- lib/features/work/view/submit_delivery_modal.dart
- lib/features/work/view/review_delivery_modal.dart
- lib/features/work/view/request_extension_modal.dart
- lib/features/work/view/work_item_booking_details.dart
- lib/features/work/view/work_item_bottom_actions.dart
- lib/features/work/view/work_item_guard_widgets.dart

**Notifications (3 files)**
- lib/features/notifications/view/notifications_modal.dart
- lib/features/notifications/view/notification_badge_button.dart
- lib/features/notifications/view/notification_tile.dart

**Saved, Favorites, Categories, Services (7 files)**
- lib/features/saved/view/saved_tasks_screen.dart
- lib/features/saved/view/saved_task_tile.dart
- lib/features/favorites/view/favorites_screen.dart
- lib/features/favorites/view/favorite_card.dart
- lib/features/categories/view/categories_screen.dart
- lib/features/services/view/service_card.dart

---

## Complete Navigation Map

### Tab-Based Navigation (MainNavigationScreen)
```
┌─────────────────────────────────────────┐
│  Tab 0: HomeScreen                      │
│  ├── FiltersModal                       │
│  ├── SearchScreen                       │
│  │   └── PublicProfileScreen (modal)    │
│  ├── TaskDetailsScreen                  │
│  └── SubmitProposalSheet                │
├─────────────────────────────────────────┤
│  Tab 1: TasksScreen                     │
│  ├── CreateTaskScreen                   │
│  ├── TendersScreen                      │
│  ├── TaskDetailsScreen                  │
│  ├── TenderPaymentScreen                │
│  ├── RequestsListScreen                 │
│  └── SubmitRequestSheet                 │
├─────────────────────────────────────────┤
│  Tab 2: BookingsDiscoveryScreen         │
│  ├── BookingsListScreen                 │
│  ├── BookingDetailsScreen               │
│  ├── PaymentCheckoutScreen              │
│  ├── PaymentWebviewScreen               │
│  └── PaymentReturnScreen                │
├─────────────────────────────────────────┤
│  Tab 3: DashboardScreen                 │
│  ├── OverviewTab                        │
│  ├── BookingsTab                        │
│  ├── WorkTab                            │
│  │   └── WorkItemDetailsScreen          │
│  ├── WalletTab                          │
│  └── InboxTab                           │
├─────────────────────────────────────────┤
│  Tab 4: MessagesScreen                  │
│  └── ChatScreen                         │
│      └── CreateOfferSheet               │
└─────────────────────────────────────────┘
│  Tab 5: ProfileScreen                   │
│  ├── EditProfileScreen                  │
│  ├── ManagePortfolioScreen              │
│  ├── SettingsScreen                     │
│  ├── PortfolioScreen                    │
│  └── PublicProfileScreen                │
```

### Modal Flows

**Profile Navigation**
```
PublicProfileScreen
├── Header (PublicProfileHeader)
├── Stats (PublicProfileStats)
├── Tabs
│   ├── About
│   ├── Portfolio (PublicProfilePortfolio)
│   ├── Reviews (PublicProfileReviews)
│   └── More
└── Actions: Message, Favorite, Share
```

**Payment Flow**
```
TaskDetails / BookingDetails
├── PaymentCheckoutScreen
├── PaymentMethodScreen (select/add card)
├── PaymentWebviewScreen (QiCard gateway)
└── PaymentReturnScreen (success/failure)
```

**Work Management Flow**
```
WorkItemDetailsScreen
├── OrderManagementPanel
├── SubmitDeliveryModal → ReviewDeliveryModal
├── RequestExtensionModal
└── WorkItemBottomActions
```

---

## Responsive Design Principles

### Breakpoints
- **Mobile** - < 600px width (phone)
- **Tablet** - 600-900px width
- **Desktop** - > 900px width (web)

### Layout Adjustments
- **Padding** - Consistent 24px horizontal on mobile
- **Grid Columns** - 2 columns on mobile, 3+ on tablet/desktop
- **Font Sizes** - Scale based on AppTypography
- **Button Heights** - 48px minimum touch target
- **Avatar Sizes** - Flexible via radius parameter

### Safe Area Handling
- Top padding: `MediaQuery.of(context).padding.top`
- Bottom padding: 48px (avoid nav bar)
- Side margins: 24px minimum

---

## Dark Mode Support

### Theme Implementation
All colors use `context.colorScheme` for automatic dark mode adaptation:
- `colorScheme.phoneBackground` - Scaffold background
- `colorScheme.cardBackground` - Card/container backgrounds
- `colorScheme.text` / `.textSecondary` / `.textTertiary` - Text colors
- `colorScheme.surface` / `.onSurface` - Dialog backgrounds
- `colorScheme.primary` - Primary action color

### Dark Mode Toggle
- `ThemeModeProvider` manages dark/light state
- Toggle in SettingsScreen
- Preference saved to `SharedPreferences`
- App rebuilds with new colorScheme

---

## Testing & QA Checklist

### Visual Testing
- [ ] All colors match AppColors constants
- [ ] Typography follows AppTypography styles
- [ ] Spacing uses AppDimens values
- [ ] Border radius consistent (8, 12, 16, 20, 24px)
- [ ] Dark mode colors adapt correctly

### Interaction Testing
- [ ] All buttons responsive (48px+ touch targets)
- [ ] Form validation shows errors inline
- [ ] Loading states show spinners
- [ ] Empty states display appropriate messaging
- [ ] Scroll performance smooth (no jank)

### Navigation Testing
- [ ] Tab switching transitions smooth (200ms)
- [ ] Back buttons work on all screens
- [ ] Deep links resolve to correct screens
- [ ] Modal dismissal works (back gesture + button)
- [ ] FAB visible/hidden appropriately

### Accessibility Testing
- [ ] Text contrast > 4.5:1 for WCAG AA
- [ ] Icons have tooltips/semantic labels
- [ ] Form fields labeled properly
- [ ] Loading indicators announced
- [ ] Tab order logical

---

## Document Metadata

**Document Version:** 2.0
**Generated:** 2026-04-05
**Total Sections:** 17 Parts
**Total Files Documented:** 115+ screens and components
**Color Palette:** 7 primary colors + dynamic colorScheme
**Typography Styles:** 8 standard styles
**Spacing Tokens:** 7 padding values + 5 border radius values
**Design System:** Complete MVVM-based Flutter UI specification

---

**End of SLINE Complete UI Inventory V2**

This document serves as the single source of truth for all UI specifications, component properties, and interaction patterns in the SLine Flutter application. All future feature development, UI updates, and design system modifications should reference and conform to these specifications.

