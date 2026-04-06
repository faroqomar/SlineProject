# SLine Profile Feature - UI Documentation Summary

## Overview

Complete visual documentation for 11 files in the profile feature module. All specifications include exact color hex codes, dimensions in pixels, typography styles, interaction handlers, and Figma reconstruction notes.

## Files Documented

### Main Screens (4 files)
1. **EditProfileScreen** - User profile editing with avatar, basic info, and skills
2. **ManagePortfolioScreen** - Portfolio item CRUD with swipe-to-delete
3. **MyServicesScreen** - List view of user's services (coming soon features)
4. **SettingsScreen** - App preferences, account settings, logout
5. **PublicProfileScreen** - View-only freelancer profile with 4 tabs

### Widgets (6 files)
6. **ProfileAvatarWidget** - Circular avatar with edit button and upload loading state
7. **ProfilePreviewModal** - Bottom sheet modal wrapper for public profile
8. **PublicProfileHeader** - Gradient header with avatar and online badge
9. **PublicProfileStats** - 3-column stats display (Job Success, Total Jobs, Hourly Rate)
10. **PublicProfilePortfolio** - Masonry 2-column grid of portfolio items
11. **PublicProfileReviews** - List of review cards with star ratings

## Key Colors Used

All colors reference `AppColors` constants:
- **teal** (#146068) - Primary brand color, buttons, active states
- **darkTeal** (#0c3b40) - Darker variant (not used in profile)
- **lightTeal** (#93ccce) - Secondary brand color, badges, hover states
- **gold** (#f3bb19) - Accents, avatar backgrounds, star ratings
- **lightRed** (#f49d9d) - Danger/delete actions, warning states
- **mediumGreyBlue** (#9dbabb) - Subtle secondary text
- **white** (#ffffff) - Text on dark backgrounds, borders

Color scheme variants (from context.colorScheme):
- `phoneBackground` - Main scaffold background
- `cardBackground` - Container backgrounds
- `text` / `textSecondary` / `textTertiary` - Text hierarchy
- `primary` - Primary action color
- `surface` / `onSurface` - Dialog backgrounds
- `error` - Error states

## Typography Standards

All text uses `AppTypography` constants:
- **h3** - Screen titles (Edit Profile, Settings, Manage Portfolio)
- **h5** - Section headers (Basic Info, Skills, Portfolio, Reviews)
- **h6** - Stat values (92%, 15, $45/hr)
- **bodyLarge** - Primary buttons, prominent CTAs
- **bodyMedium** - Regular text, labels, tile titles
- **bodySmall** - Secondary text, descriptions, chip labels
- **caption/captionBold** - Tertiary text, badges, section labels
- **micro** - Very small text, dates, locations, category info

## Spacing Standards (AppDimens)

Key spacing values:
- **p4** - 4px (very small padding)
- **p8** - 8px (micro spacing, list separators)
- **p12** - 12px (small spacing, gaps)
- **p16** - 16px (standard spacing, vertical sections)
- **p24** - 24px (major spacing, horizontal margins, section breaks)
- **p32** - 32px (large spacing, between major sections)
- **p48** - 48px (bottom padding to avoid overlap)

Border radius values:
- **r8** - 8px (text fields, containers)
- **r12** - 12px (back buttons, small containers)
- **r16** - 16px (cards, portfolio items)
- **r20** - 20px (large cards, avatars)
- **r24** - 24px (modal corners)

## Common Layout Patterns

### Header Pattern (EditProfileScreen, ManagePortfolioScreen, SettingsScreen)
```
SliverToBoxAdapter
├── Padding (24px horiz, topPadding+24px top)
└── Row
    ├── Back Button (8px padding, 12px br, cardBackground)
    ├── SizedBox(16)
    └── Title (h3 typography)
```

### Settings Tile Pattern (SettingsScreen, ManagePortfolioScreen items)
```
GlassContainer (16px padding, 16px br)
└── Row
    ├── Icon Container (10px padding, 12px br, background)
    ├── SizedBox(16)
    ├── Expanded Column (title, subtitle)
    └── Trailing Widget (icon or switch)
```

### Card Pattern (ManagePortfolioScreen, PublicProfileReviews)
```
GlassContainer/Container (16px padding, 16px br, border)
└── Row/Column
    ├── Thumbnail/Avatar (32-80px)
    ├── SizedBox(spacing)
    └── Text Content (title, description)
```

### List Separator Pattern
```
ListView.separated(
├── padding: 16px all
├── separatorBuilder: SizedBox(height: 12-16px)
└── itemBuilder: [Card Widget]
)
```

## State Management

All screens use **Provider** for state:
- **EditProfileScreen**: `Consumer<ProfileViewModel>` for form state
- **ManagePortfolioScreen**: `Consumer<ProfileViewModel>` for portfolio list
- **MyServicesScreen**: `context.watch<MyServicesViewModel>` for services
- **SettingsScreen**: `Consumer<ThemeModeProvider>` for theme toggle
- **PublicProfileScreen**:
  - `Consumer<PublicProfileViewModel>` for profile data
  - `Consumer<FavoritesViewModel>` for favorite toggle
  - `context.read<ChatViewModel>` for messaging
  - `context.read<SafetyViewModel>` for reporting

## Interactive Elements

### Common Button Types
- **FilledButton** (Material): Save Changes (blue bg), Add (in dialogs)
- **TextButton** / **TextButton.icon**: Cancel, navigation
- **IconButton**: Edit, delete, share, report
- **FloatingActionButton / FloatingActionButton.extended**: Add/create actions
- **CircleIconButton**: Custom icon buttons in rows (share, favorite, report)
- **GestureDetector**: Custom tap targets (tiles, logout)
- **Switch**: Theme toggle

### Common Dialogs
- **AlertDialog**: Skill entry, item add/edit, report reason, support info
- **SnackBar**: Error messages, "coming soon" messages, confirmation
- **DraggableScrollableSheet**: Profile preview modal

### Common Overlays
- **CircularProgressIndicator**: Loading states
- **LoadingUtils**: Overlay loading during message creation
- **Semi-transparent Container**: Loading overlay on avatar during upload

## Navigation

**Explicit Navigation:**
- EditProfileScreen → ManagePortfolioScreen (from Settings)
- SettingsScreen → ManagePortfolioScreen (Manage Portfolio tile)
- PublicProfileScreen → ChatScreen (Message button)
- Back button: `Navigator.pop(context)`
- Logout: `Navigator.pushNamedAndRemoveUntil(context, '/login', remove all)`

**Modal Navigation:**
- showProfilePreview() → PublicProfileScreen in DraggableScrollableSheet

## Validation & Error Handling

**Form Validation:**
- EditProfileScreen: Name field required (TextFormField validator)
- ManagePortfolioScreen: Title required before save
- Dialog forms: Trim input before submission

**Error Messages:**
- Save profile failure: SnackBar "Failed to save profile. Please try again."
- Avatar upload: SnackBar with vm.avatarUploadError message
- Chat creation: SnackBar "Error starting chat: {error}"
- Messaging validation: SnackBar "You must be logged in to message." / "You cannot message yourself."

**Loading States:**
- Save button: CircularProgressIndicator (24×24, white) when isLoadingUpdate=true
- Image upload: Loading spinner on avatar or in dialog
- Profile loading: Center CircularProgressIndicator
- Conversation creation: LoadingUtils overlay

## Conditional Rendering

**Empty States:**
- No portfolio items: Icon + "No items yet" text
- No services: Icon + "No services found." text
- No history: Text "No completed work yet."
- No reviews: SizedBox.shrink() (hidden)

**Loading States:**
- Profile: CircularProgressIndicator centered
- Portfolio: SliverFillRemaining with spinner
- Services: CircularProgressIndicator centered

**Visibility Conditions:**
- Verified badge: Shows if profile.verified=true
- Online badge: Shows if profile.online=true
- Edit button: Shows if enableEdit=true on ProfileAvatarWidget
- Coming soon badge: Shows on Request Withdrawal tile

## Animations & Transitions

- **Tab switching**: Cross-fade (TabBarView implicit)
- **NestedScrollView header**: Parallax collapse as content scrolls
- **Dismissible items**: Slide animation on swipe
- **Snackbar**: Slide-up from bottom
- **Dialog**: Fade-in
- **Switch**: Toggle animation

## Safe Area & Notch Handling

- All main screens read `MediaQuery.of(context).padding.top`
- Header slivers add topPadding to padding calculations
- Profile header includes CircleAvatar positioned for notch clearance
- Bottom modals respect bottom padding for home indicator
- FloatingActionButton positioned with 24px margins (safe from corners)

## Component Dependencies

**Core Widgets Used:**
- `GlassContainer` - Custom frosted glass effect (from core/widgets)
- `SignedAvatar` / `SignedImage` - Authenticated storage URLs
- `CircleIconButton` - Custom circular icon button
- `AppButton` - Custom primary button
- `SliverTabBarDelegate` - Custom pinned tab bar

**Material Widgets:**
- Scaffold, AppBar, CustomScrollView, SliverList, SliverToBoxAdapter
- TabBar, TabBarView, NestedScrollView
- TextField, TextFormField, Chip, ActionChip
- Container, Row, Column, Stack, Positioned
- FloatingActionButton, FilledButton, TextButton, IconButton
- AlertDialog, SnackBar, Switch
- CircleAvatar, Icon, CircularProgressIndicator
- ListView, Dismissible, DraggableScrollableSheet

**External Components:**
- `ServiceCard` (from services feature)
- `TaskCard` (from tasks feature)
- `PublicProfileScreen` (embedded in modal)

## Testing Considerations

**Key Touch Targets:**
- Back buttons: 8px padding = ~40px effective touch area
- Icon buttons: Implicit 48px Material minimum
- Circular buttons: 48px+ diameter
- Tiles: 48px+ minimum height

**Responsive Behavior:**
- Horizontal padding: 24px (maintains readability on small screens)
- Avatar radius: Configurable via parameter
- Portfolio grid: 2 columns (masonry) fits phones/tablets
- Lists: Full-width minus margins

**States to Test:**
- Loading, loaded, empty, error states
- Favorite toggle (filled/unfilled icon transition)
- Dark mode (AppColors used, colorScheme handles theming)
- Scrolling behavior with fixed headers
- Dialog interactions (add, edit, delete)
- Upload progress and error states
- Navigation and back button behavior

## Documentation Files

- **UI_DOCS_PROFILE_SCREENS.md** - EditProfile, ManagePortfolio, MyServices, Settings screens
- **UI_DOCS_PUBLIC_PROFILE.md** - PublicProfile screen and all 6 widgets
- **UI_DOCS_PROFILE_SUMMARY.md** - This file (overview and standards)

All documentation includes:
- Complete widget trees (4+ levels deep)
- All UI elements with exact specs (colors hex, sizes px, padding, border radius)
- ASCII layout wireframes
- State diagrams
- Interaction maps with exact navigation targets
- Overlay/dialog specifications
- Figma reconstruction measurements
- Color reference tables
