# SLine Profile Feature - UI Documentation

## 1. EditProfileScreen

**File:** `/lib/features/profile/view/edit_profile_screen.dart`
**Class:** `EditProfileScreen` (StatefulWidget)
**State Class:** `_EditProfileScreenState`
**Provider:** `ProfileViewModel`

### WIDGET TREE

```
Scaffold
├── backgroundColor: colorScheme.phoneBackground
└── body: Consumer<ProfileViewModel>
    └── CustomScrollView
        ├── SliverToBoxAdapter (Header)
        │   └── Padding (24px horiz, topPadding+24px top, 24px horiz, 16px bottom)
        │       └── Row
        │           ├── GestureDetector (Back Button)
        │           │   └── Container
        │           │       ├── padding: 8px all
        │           │       ├── decoration: cardBackground, br=12
        │           │       └── Icon(arrow_back, colorScheme.text)
        │           ├── SizedBox(width: 16)
        │           └── Text("Edit Profile", h3, colorScheme.text)
        │
        ├── SliverToBoxAdapter (Form)
        │   └── Padding (24px horizontal)
        │       └── Form
        │           └── Column
        │               ├── ProfileAvatarWidget (radius=50, enableEdit=true)
        │               ├── SizedBox(height: 24)
        │               ├── GlassContainer (Basic Info)
        │               │   ├── padding: 16 all
        │               │   ├── br: 20
        │               │   └── Column
        │               │       ├── Text("Basic Info", h5)
        │               │       ├── SizedBox(16)
        │               │       ├── TextField (Full Name)
        │               │       ├── SizedBox(16)
        │               │       ├── TextField (Bio, maxLines=3)
        │               │       ├── SizedBox(16)
        │               │       └── TextField (Email, readOnly)
        │               │
        │               ├── SizedBox(height: 24)
        │               ├── GlassContainer (Skills)
        │               │   ├── padding: 16 all
        │               │   ├── br: 20
        │               │   └── Column
        │               │       ├── Text("Skills", h5)
        │               │       ├── SizedBox(16)
        │               │       └── Wrap (spacing=8, runSpacing=8)
        │               │           ├── ...Chips (skill items)
        │               │           │   ├── label: skill text
        │               │           │   ├── backgroundColor: teal.withAlpha(0.1)
        │               │           │   ├── deleteIcon: close, size=14
        │               │           │   ├── onDeleted: removeSkill()
        │               │           │   ├── br: 20
        │               │           │   └── no border
        │               │           └── ActionChip (Add +)
        │               │               ├── backgroundColor: cardBackground
        │               │               ├── border: textSecondary.alpha(0.3)
        │               │               └── onPressed: _showAddSkillDialog()
        │               │
        │               ├── SizedBox(height: 32)
        │               ├── FilledButton (Save Changes)
        │               │   ├── width: double.infinity
        │               │   ├── height: 56
        │               │   ├── backgroundColor: teal
        │               │   ├── br: 16
        │               │   ├── onPressed: validate & updateProfile()
        │               │   └── child: Text/CircularProgressIndicator
        │               │
        │               └── SizedBox(height: 48)
```

### UI ELEMENTS

**Header Section (SliverToBoxAdapter)**
- Back button: 8px padding, 12px border radius, cardBackground color, arrow_back icon
- Title: "Edit Profile", h3 typography, colorScheme.text
- Combined padding: top (MediaQuery.padding.top + 24px), left/right 24px, bottom 16px

**Avatar Section (ProfileAvatarWidget)**
- Centered, radius=50 (diameter 100px)
- enableEdit=true (shows camera edit button)
- Handles image upload internally

**Basic Info Container (GlassContainer)**
- 16px padding all, 20px border radius
- Title: "Basic Info", h5 style
- Field 1: Full Name (icon=person_outline, validator required)
- Field 2: Bio (icon=info_outline, maxLines=3, optional)
- Field 3: Email (icon=email_outlined, readOnly=true)
- All TextFields use:
  - fillColor: colorScheme.background
  - borderRadius: 12px
  - focusedBorder: teal color
  - labelStyle: bodySmall, colorScheme.textSecondary
  - prefixIcon size: 20, colorScheme.textSecondary

**Skills Container (GlassContainer)**
- 16px padding all, 20px border radius
- Title: "Skills", h5 style
- Wrap layout with 8px spacing, 8px runSpacing
- Skill Chips:
  - Label text
  - backgroundColor: teal.withValues(alpha: 0.1) hex #146068 at 10%
  - labelStyle: bodySmall, teal color
  - deleteIcon: close, size 14
  - borderRadius: 20px
  - no border side
  - onDeleted triggers vm.removeSkill()
- "Add +" ActionChip:
  - backgroundColor: cardBackground
  - border: 1px textSecondary.withValues(alpha: 0.3)
  - labelStyle: bodySmall, colorScheme.textSecondary
  - onPressed triggers dialog

**Save Button**
- Full width (double.infinity), height 56px
- backgroundColor: AppColors.teal (#146068)
- borderRadius: 16px
- Text: "Save Changes", bodyLarge, bold, white
- When loading: CircularProgressIndicator (24x24, strokeWidth 2, white)
- Disabled when vm.isLoadingUpdate=true
- onPressed: validates form, calls updateProfile(), pops on success

**Bottom Spacing:** 48px

### COLORS USED
- **teal (#146068)**: Save button background, chip background at 10%, focused text field borders
- **cardBackground**: Back button background, "Add +" chip background
- **phoneBackground**: Scaffold background
- **text/textSecondary**: Title, labels, icons
- **white**: Text on save button, progress indicator

### LAYOUT WIREFRAME

```
┌─────────────────────────────────┐
│ ↶  Edit Profile                 │ topPadding + 24px
├─────────────────────────────────┤ 16px bottom
│                                 │
│            [Avatar]             │ 24px top margin
│                                 │
├─────────────────────────────────┤ 24px margin
│ Basic Info                      │
│ ┌─────────────────────────────┐ │
│ │ 🔤 Full Name                │ │
│ ├─────────────────────────────┤ │ 16px spacing
│ │ ℹ️ Bio (3 lines)            │ │
│ ├─────────────────────────────┤ │ 16px spacing
│ │ ✉️ Email (readOnly)         │ │
│ └─────────────────────────────┘ │
├─────────────────────────────────┤ 24px margin
│ Skills                          │
│ ┌────────────┐ ┌────────────┐  │
│ │ Skill1 ✕   │ │ Skill2 ✕   │  │ 8px spacing
│ └────────────┘ └────────────┘  │
│ ┌────────────┐                  │
│ │ Add +      │                  │ 8px runSpacing
│ └────────────┘                  │
├─────────────────────────────────┤ 32px margin
│  [Save Changes Button (56px)]   │
├─────────────────────────────────┤ 48px bottom
```

### STATES

1. **Initial Load**: Form fields populated from vm.loadedName/Email/Bio in didChangeDependencies
2. **Editing**: User modifies name, bio, skills
3. **Adding Skill**: Dialog modal appears with text input
4. **Saving**: vm.isLoadingUpdate=true, button shows CircularProgressIndicator
5. **Success**: Navigator.pop() returns to previous screen
6. **Error**: SnackBar shows "Failed to save profile. Please try again."

### INTERACTIONS

**Back Button (GestureDetector)**
- onTap: Navigator.pop(context)

**Avatar (ProfileAvatarWidget)**
- enableEdit=true, shows edit button that calls vm.pickAndUploadAvatar()

**Add Skill Button (ActionChip)**
- onPressed: _showAddSkillDialog(context, vm)

**Skill Delete (Chip)**
- onDeleted: vm.removeSkill(skill)

**Save Changes Button (FilledButton)**
- onPressed:
  - Validates form (_formKey.currentState?.validate())
  - Calls vm.updateProfile(name, bio)
  - On exception: shows SnackBar
  - On mounted: Navigator.pop(context)

### OVERLAYS

**Add Skill Dialog (_showAddSkillDialog)**
- AlertDialog:
  - backgroundColor: cardBackground
  - Title: "Add Skill" (h5, colorScheme.text)
  - Content: TextField with autofocus, hintText: "e.g. Flutter"
  - Actions:
    - Cancel button: pops dialog
    - Add button: calls vm.addSkill(), pops dialog
  - Text color: colorScheme.text

**Save Error SnackBar**
- Content: "Failed to save profile. Please try again."
- No behavior specified (shows inline)

### COMPONENTS USED

- **GlassContainer**: Custom widget from core/widgets, with padding and borderRadius
- **ProfileAvatarWidget**: Custom widget (see separate docs), handles avatar display and upload
- **TextFormField**: Material widget with custom decoration
- **Chip/ActionChip**: Material widgets
- **FilledButton**: Material widget

### FIGMA NOTES

Reconstructed screen dimensions:
- Safe area padding: top (system status bar varies), left 0, right 0, bottom 0
- Content area: 24px margins horizontal (max width ~328px on 375px screen)
- Stack layout: header sliver (flexible), form sliver (flexible scrollable)
- Avatar: 100x100px, centered, displayed above form content
- Container shadows: GlassContainer uses theme defaults (likely frosted glass appearance)
- Spacing pattern: 24px major (between sections), 16px minor (within sections), 8px micro (chip spacing)
- Button height: 56px (Material standard touch target minimum)
- Icon sizes: 20px (text field prefix), 14px (chip delete)
- Typography baseline: h5 for section titles, bodySmall for labels
- Animations: None specified, but updateProfile likely triggers loading state transition
- Safe area: respects MediaQuery.padding.top for notch/status bar

---

## 2. ManagePortfolioScreen

**File:** `/lib/features/profile/view/manage_portfolio_screen.dart`
**Class:** `ManagePortfolioScreen` (StatefulWidget)
**State Class:** `_ManagePortfolioScreenState`
**Provider:** `ProfileViewModel`

### WIDGET TREE

```
Scaffold
├── backgroundColor: colorScheme.phoneBackground
├── body: Consumer<ProfileViewModel>
│   └── CustomScrollView
│       ├── SliverToBoxAdapter (Header)
│       │   └── Padding (24px horiz, topPadding+24px top, 24px horiz, 16px bottom)
│       │       └── Row
│       │           ├── GestureDetector (Back)
│       │           │   └── Container (8px padding, 12px br, cardBackground)
│       │           │       └── Icon(arrow_back)
│       │           ├── SizedBox(16)
│       │           └── Text("Manage Portfolio", h3)
│       │
│       ├── [Conditional Content]
│       │   ├── if isLoadingPortfolio:
│       │   │   └── SliverFillRemaining
│       │   │       └── Center(CircularProgressIndicator)
│       │   │
│       │   ├── else if portfolioItems.isEmpty:
│       │   │   └── SliverFillRemaining
│       │   │       └── Center(Column)
│       │   │           ├── Icon(folder_open, size=64, textSecondary)
│       │   │           ├── SizedBox(16)
│       │   │           └── Text("No items yet", bodyMedium, textSecondary)
│       │   │
│       │   └── else:
│       │       └── SliverList
│       │           └── itemBuilder for each item:
│       │               └── Padding (24px horiz, 8px vert)
│       │                   └── Dismissible
│       │                       ├── key: item['id']
│       │                       ├── direction: endToStart (swipe left)
│       │                       ├── background: Container (lightRed #f49d9d, br=20)
│       │                       │   └── Icon(delete, white, right aligned)
│       │                       ├── confirmDismiss: _confirmDelete()
│       │                       └── child: GlassContainer
│       │                           ├── padding: 12 all
│       │                           ├── br: 20
│       │                           └── Row
│       │                               ├── ClipRRect (12px br)
│       │                               │   └── Container (80x80)
│       │                               │       ├── color: background
│       │                               │       └── child: SignedImage/Icon
│       │                               ├── SizedBox(16)
│       │                               ├── Expanded(Column)
│       │                               │   ├── Text(title, h5)
│       │                               │   └── Text(description, bodySmall, 2 lines max)
│       │                               └── IconButton(edit, primary color)
│       │
└── floatingActionButton: FloatingActionButton.extended
    ├── backgroundColor: teal
    ├── label: Text("Add Item", white)
    ├── icon: Icon(add, white)
    └── onPressed: _showAddEditDialog(context, vm)
```

### UI ELEMENTS

**Header Section**
- Back button: 8px padding, 12px br, cardBackground
- Title: "Manage Portfolio", h3 typography
- Padding: topPadding+24px top, 24px horizontal

**Loading State**
- Full screen center: CircularProgressIndicator

**Empty State**
- Icon: folder_open, size 64px, textSecondary color
- Text: "No items yet", bodyMedium, textSecondary color
- Vertical spacing: 16px between icon and text

**Portfolio Item Card (GlassContainer)**
- Padding: 12px all
- Border radius: 20px
- Row layout with:
  - Image thumbnail: 80x80px, 12px border radius, background color
  - SignedImage (portfolio bucket) or Icon(image, textSecondary)
  - SizedBox: 16px spacing
  - Column (expanded):
    - Title: h5 style
    - Description: bodySmall, textSecondary, maxLines=2, ellipsis
  - Edit IconButton: primary color, Icons.edit

**Dismissible Background (Swipe Left)**
- Container: lightRed (#f49d9d) background
- Border radius: 20px
- Alignment: right, 20px padding
- Icon: delete, white, centered

**FAB (FloatingActionButton.extended)**
- backgroundColor: teal
- Label: "Add Item", white text
- Icon: add, white, 24px
- onPressed: opens add dialog

### COLORS USED
- **teal (#146068)**: FAB background
- **lightRed (#f49d9d)**: Dismiss background
- **cardBackground**: Back button background
- **phoneBackground**: Scaffold background
- **textSecondary**: Empty state icon/text, description text
- **primary**: Edit button color
- **white**: FAB text/icon, dismiss icon

### LAYOUT WIREFRAME

```
┌─────────────────────────────────┐
│ ↶  Manage Portfolio             │ topPadding + 24px
├─────────────────────────────────┤ 16px bottom
│                                 │
│   📁 No items yet               │ [if empty]
│                                 │
├─────────────────────────────────┤ 24px horiz margin
│ ┌─────────────────────────────┐ │
│ │ [80x80]   Title         [✎] │ │ 8px vert margin
│ │           Description…      │ │ 12px container padding
│ └─────────────────────────────┘ │ 20px br
│ ┌─────────────────────────────┐ │
│ │ [80x80]   Title2        [✎] │ │ 8px vert margin
│ │           Desc2…            │ │
│ └─────────────────────────────┘ │
│                                 │
│                      [Add Item] │ FAB bottom-right
│                           ➕    │
```

### STATES

1. **Loading**: isLoadingPortfolio=true, shows spinner
2. **Empty**: portfolioItems.isEmpty, shows empty state icon/text
3. **Loaded**: Shows SliverList with items
4. **Swiping**: Dismissible shows red delete background
5. **Deleting**: Dialog confirmation before delete
6. **Adding/Editing**: Dialog modal appears

### INTERACTIONS

**Back Button**
- onTap: Navigator.pop(context)

**Item Edit Button (IconButton)**
- onPressed: _showAddEditDialog(context, vm, item)
- Opens dialog in edit mode with pre-filled data

**Item Swipe (Dismissible)**
- direction: endToStart (swipe left)
- confirmDismiss: triggers _confirmDelete()
- Returns false (dialog handles deletion)

**Delete Confirmation Dialog**
- Title: "Delete Item?"
- Content: "This action cannot be undone."
- Cancel button: pops dialog
- Delete button (red #f49d9d): calls vm.deletePortfolioItem(itemId), pops dialog

**FAB (Add Item)**
- onPressed: _showAddEditDialog(context, vm) with no item (add mode)

### OVERLAYS

**Add/Edit Portfolio Dialog (_showAddEditDialog)**
- StatefulBuilder for local image state
- AlertDialog:
  - backgroundColor: colorScheme.surface
  - Title: isEditing ? "Edit Item" : "Add Item" (h4)
  - barrierDismissible: false
  - Content (SingleChildScrollView):
    - Image upload container (150h, full width):
      - GestureDetector with tap to upload
      - isUploading shows spinner
      - Success shows checkmark + "Image uploaded!" + "Tap to change"
      - Empty shows icon + "Add Image"
      - borderRadius: 12px
      - border: 0.2 alpha outline
    - SizedBox(16)
    - TextField (Title, required)
    - SizedBox(16)
    - TextField (Description, maxLines=3)
  - Actions:
    - Cancel button: pops dialog
    - Save/Add button: validates, calls updatePortfolioItem() or addPortfolioItem()

**Delete Confirmation Dialog (_confirmDelete)**
- AlertDialog:
  - Title: "Delete Item?"
  - Content: "This action cannot be undone."
  - Actions: Cancel, Delete (red text)

### COMPONENTS USED

- **GlassContainer**: Custom frosted glass effect widget
- **SignedImage**: Custom widget for signed storage URLs
- **Dismissible**: Material widget for swipe actions
- **FloatingActionButton.extended**: Material widget
- **StatefulBuilder**: For dialog local state management
- **AlertDialog**: Material dialog

### FIGMA NOTES

Screen dimensions:
- Header sliver: 56px + status bar safe area
- FAB: 56px height (extended variant), positioned bottom-right with 24px margins
- Item cards: full width - 48px horizontal (24px margins), 80x80px thumbnail
- Image container: 150px height, 12px br, with upload state transitions
- Dismissible background: full card width with 20px br
- Dialog width: Standard Material (typically 90% of screen width, max 560px)
- Animations: Dismissible slide animation on swipe, dialog appearance
- Safe area: respects top padding + 24px margin
- Touch targets: 44px minimum (FAB 56px, IconButton implicit 48px)

---

## 3. MyServicesScreen

**File:** `/lib/features/profile/view/my_services_screen.dart`
**Class:** `MyServicesScreen` (StatefulWidget)
**Provider:** `MyServicesViewModel`

### WIDGET TREE

```
Scaffold
├── backgroundColor: colorScheme.background
├── appBar: AppBar
│   ├── title: Text("My Services", h3)
│   ├── centerTitle: true
│   ├── backgroundColor: transparent
│   ├── elevation: 0
│   └── leading: IconButton(arrow_back)
│
├── body: [Conditional]
│   ├── if isLoading && services.isEmpty:
│   │   └── Center(CircularProgressIndicator)
│   │
│   ├── else if error != null && services.isEmpty:
│   │   └── Center(Padding)
│   │       └── Text(error, bodyMedium, red)
│   │
│   ├── else if services.isEmpty:
│   │   └── Center(Column)
│   │       ├── Icon(design_services_outlined, 64, textSecondary)
│   │       ├── SizedBox(16)
│   │       └── Text("No services found.", bodyMedium, textSecondary)
│   │
│   └── else:
│       └── ListView.separated
│           ├── padding: 16 all
│           ├── separatorBuilder: SizedBox(16)
│           └── itemBuilder: ServiceCard(service)
│
└── floatingActionButton: FloatingActionButton
    ├── backgroundColor: colorScheme.primary
    ├── icon: Icon(add, white)
    └── onPressed: shows snackbar "Create service coming soon"
```

### UI ELEMENTS

**AppBar**
- Title: "My Services", h3 typography, centered
- Background: transparent
- Elevation: 0
- Leading: back IconButton with colorScheme.text icon
- No actions

**Loading State**
- Full screen center: CircularProgressIndicator

**Error State**
- Center with padding (16px all)
- Text: vm.error, bodyMedium, error color (red)
- textAlign: center

**Empty State**
- Center column:
  - Icon: design_services_outlined, size 64, textSecondary color
  - SizedBox: 16px vertical spacing
  - Text: "No services found.", bodyMedium, textSecondary color

**Services List (ListView.separated)**
- Padding: 16px all
- Item separator: SizedBox 16px height
- Each item: ServiceCard widget (external component)
- Services displayed as cards with unknown structure (from services feature)

**FAB (FloatingActionButton)**
- backgroundColor: colorScheme.primary
- Icon: add, white, 24px
- onPressed: shows snackbar "Create service coming soon" (floating behavior)

### COLORS USED
- **background (colorScheme.background)**: Scaffold background
- **primary (colorScheme.primary)**: FAB background
- **textSecondary (colorScheme.textSecondary)**: Empty/loading icon, empty text
- **error (colorScheme.error)**: Error message text
- **text (colorScheme.text)**: AppBar back button icon, title
- **white**: FAB icon

### LAYOUT WIREFRAME

```
┌─────────────────────────────────┐
│       My Services               │ AppBar (transparent)
├─────────────────────────────────┤
│                                 │
│  🎨 No services found.          │ [if empty]
│                                 │
├─────────────────────────────────┤ 16px padding
│ ┌─────────────────────────────┐ │
│ │      [Service Card]         │ │
│ └─────────────────────────────┘ │
│                                 │ 16px separator
│ ┌─────────────────────────────┐ │
│ │      [Service Card]         │ │
│ └─────────────────────────────┘ │
│                                 │
│                          [➕]   │ FAB
```

### STATES

1. **Loading**: isLoading=true && services.isEmpty → shows spinner
2. **Error**: error!=null && services.isEmpty → shows error message
3. **Empty**: services.isEmpty → shows empty state icon/text
4. **Loaded**: displays ListView of ServiceCard items
5. **FAB Tap**: shows floating snackbar "Create service coming soon"

### INTERACTIONS

**Back Button (AppBar leading)**
- onPressed: Navigator.pop(context)

**Service Card (ListView item)**
- onTap: shows snackbar "Edit service coming soon" (floating)

**FAB (FloatingActionButton)**
- onPressed: shows snackbar "Create service coming soon" (floating behavior)

### OVERLAYS

**SnackBar (Service Card tap)**
- Content: "Edit service coming soon"
- Behavior: floating
- Duration: default (4 seconds)

**SnackBar (FAB tap)**
- Content: "Create service coming soon"
- Behavior: floating
- Duration: default (4 seconds)

### COMPONENTS USED

- **AppBar**: Material widget with transparent styling
- **ListView.separated**: Material widget with item separator
- **ServiceCard**: External widget from services feature
- **FloatingActionButton**: Material widget
- **SnackBar**: Material overlay widget
- **ScaffoldMessenger**: Material service for showing snackbars

### FIGMA NOTES

Screen dimensions:
- AppBar height: 56px (standard Material)
- AppBar transparent background, no shadow
- Content padding: 16px all sides
- List item separator: 16px vertical spacing
- ServiceCard width: full width - 32px (16px padding each side)
- FAB: 56px diameter, positioned bottom-right
- Empty state icon: 64px size
- Safe area: no explicit top padding handling (AppBar handles it)
- Animations: SnackBar slide-up animation from bottom
- Loading indicator: centered, indeterminate
- Error text: multiline if needed (center aligned)

---

## 4. SettingsScreen

**File:** `/lib/features/profile/view/settings_screen.dart`
**Class:** `SettingsScreen` (StatelessWidget)
**Provider:** `ThemeModeProvider`, `AuthSessionViewModel`

### WIDGET TREE

```
Scaffold
├── backgroundColor: colorScheme.phoneBackground
└── body: CustomScrollView
    ├── SliverToBoxAdapter (Header)
    │   └── Padding (24px horiz, topPadding+24px top, 24px horiz, 16px bottom)
    │       └── Row
    │           ├── GestureDetector (Back)
    │           │   └── Container (8px padding, 12px br, cardBackground)
    │           │       └── Icon(arrow_back)
    │           ├── SizedBox(16)
    │           └── Text("Settings", h3)
    │
    ├── SliverPadding (24px all)
    │   └── SliverList
    │       └── SliverChildListDelegate([
    │           // PREFERENCES SECTION
    │           Text("PREFERENCES", captionBold, textSecondary, 1.2 letter spacing)
    │           SizedBox(12)
    │
    │           Consumer<ThemeModeProvider>
    │           └── _buildSettingsTile (Dark Mode)
    │               ├── icon: isDark ? dark_mode : light_mode
    │               ├── title: "Dark Mode"
    │               ├── subtitle: isDark ? "On" : "Off"
    │               └── trailing: Switch
    │                   ├── activeThumbColor: teal
    │                   └── onChanged: toggleThemeMode()
    │
    │           SizedBox(24)
    │
    │           // ACCOUNT SECTION
    │           Text("ACCOUNT", captionBold, textSecondary, 1.2 letter spacing)
    │           SizedBox(12)
    │
    │           _buildSettingsTile (Manage Portfolio)
    │               ├── icon: folder_special
    │               ├── title: "Manage Portfolio"
    │               ├── subtitle: "Add or edit your work"
    │               ├── trailing: Icon(arrow_forward_ios, 14)
    │               └── onTap: Navigator.push(ManagePortfolioScreen)
    │
    │           SizedBox(12)
    │           _buildSettingsTile (Notifications)
    │               ├── icon: notifications_none
    │               ├── title: "Notifications"
    │               ├── subtitle: "Manage alerts"
    │               ├── trailing: Icon(arrow_forward_ios, 14)
    │               └── onTap: TODO
    │
    │           SizedBox(12)
    │           _buildSettingsTile (Support & Safety)
    │               ├── icon: gpp_good_outlined
    │               ├── title: "Support & Safety"
    │               ├── subtitle: "Reporting and account safety"
    │               ├── trailing: Icon(arrow_forward_ios, 14)
    │               └── onTap: shows AlertDialog with info
    │
    │           SizedBox(12)
    │           _buildSettingsTile (Language)
    │               ├── icon: language
    │               ├── title: "Language"
    │               ├── subtitle: "English"
    │               ├── trailing: Icon(arrow_forward_ios, 14)
    │               └── onTap: TODO
    │
    │           SizedBox(24)
    │
    │           // WALLET SECTION
    │           Text("WALLET", captionBold, textSecondary, 1.2 letter spacing)
    │           SizedBox(12)
    │
    │           _buildComingSoonTile (Request Withdrawal)
    │               ├── icon: account_balance_wallet
    │               ├── title: "Request Withdrawal"
    │               ├── subtitle: "Withdraw funds to your bank"
    │               ├── trailing: "Coming soon" badge
    │               └── onTap: shows snackbar "Request withdrawal — coming soon"
    │
    │           SizedBox(32)
    │
    │           // LOGOUT
    │           GestureDetector
    │           └── Container (Logout)
    │               ├── padding: 16 all
    │               ├── decoration: lightRed.alpha(0.1), br=16, border lightRed.alpha(0.3)
    │               └── Row
    │                   ├── Icon(logout, lightRed)
    │                   ├── SizedBox(8)
    │                   └── Text("Log Out", bodyMedium, bold, lightRed)
    │       ])
```

### UI ELEMENTS

**Header Section**
- Back button: 8px padding, 12px br, cardBackground
- Title: "Settings", h3 typography
- Padding: topPadding+24px top, 24px horizontal

**Section Headers (_buildSectionHeader)**
- Text uppercase: "PREFERENCES", "ACCOUNT", "WALLET"
- Typography: captionBold, textSecondary color
- Letter spacing: 1.2
- Spacing between sections: 24px

**Settings Tiles (_buildSettingsTile)**
- GlassContainer:
  - padding: 16px all
  - borderRadius: 16px
- Row layout:
  - Icon container (10px padding, 12px br, background color)
    - Icon size 20px
  - SizedBox: 16px spacing
  - Expanded column:
    - Title: bodyMedium, bold, colorScheme.text
    - Subtitle: micro, colorScheme.textSecondary
  - Trailing widget (arrow or switch)

**Dark Mode Tile (Consumer<ThemeModeProvider>)**
- Icon: dark_mode or light_mode (20px)
- Title: "Dark Mode"
- Subtitle: "On" or "Off"
- Trailing: Switch with activeThumbColor=teal

**Coming Soon Tile (_buildComingSoonTile)**
- Icon container: teal.withValues(alpha: 0.15) background
- Title/Subtitle: same as regular tile
- Trailing: "Coming soon" badge
  - Container: teal.withValues(alpha: 0.2) background, 20px br, teal border alpha 0.5
  - Text: "Coming soon", micro, teal color, fontWeight w600
  - Padding: 10px horiz, 4px vert

**Logout Button (GestureDetector)**
- Container:
  - padding: 16px all
  - decoration: lightRed.withValues(alpha: 0.1), br=16, border lightRed alpha 0.3
  - Row:
    - Icon(logout, lightRed)
    - SizedBox: 8px
    - Text("Log Out", bodyMedium, bold, lightRed)
  - Center aligned

### COLORS USED
- **teal (#146068)**: Switch active thumb, "Coming soon" badge
- **lightRed (#f49d9d)**: Logout button text/icon/border
- **cardBackground**: Back button
- **phoneBackground**: Scaffold background
- **textSecondary**: Section header text, subtitle text
- **text**: Settings tile titles
- **background**: Icon container background in tiles
- **white**: Various widget defaults

### LAYOUT WIREFRAME

```
┌─────────────────────────────────┐
│ ↶  Settings                     │ topPadding + 24px
├─────────────────────────────────┤ 16px bottom
│ PREFERENCES                     │ 24px padding horiz
├─────────────────────────────────┤ 12px spacing
│ ┌─────────────────────────────┐ │
│ │ 🌙 Dark Mode     On    [◯|] │ │ 16px padding
│ └─────────────────────────────┘ │ 16px br
│                                 │ 24px spacing
│ ACCOUNT                         │
├─────────────────────────────────┤ 12px spacing
│ ┌─────────────────────────────┐ │
│ │ 📁 Manage Portfolio    ⟶    │ │ 16px padding
│ │    Add or edit your work    │ │ 16px br
│ └─────────────────────────────┘ │
│ ┌─────────────────────────────┐ │
│ │ 🔔 Notifications       ⟶    │ │ 12px spacing
│ │    Manage alerts            │ │
│ └─────────────────────────────┘ │
│ ┌─────────────────────────────┐ │
│ │ 🔒 Support & Safety    ⟶    │ │ 12px spacing
│ │    Reporting and safety     │ │
│ └─────────────────────────────┘ │
│ ┌─────────────────────────────┐ │
│ │ 🌐 Language       English ⟶ │ │ 12px spacing
│ └─────────────────────────────┘ │
│                                 │ 24px spacing
│ WALLET                          │
├─────────────────────────────────┤ 12px spacing
│ ┌─────────────────────────────┐ │
│ │ 💰 Request Withdrawal  Soon │ │ 16px padding
│ │    Withdraw to bank    Soon │ │ Coming soon badge
│ └─────────────────────────────┘ │
│                                 │ 32px spacing
│ ┌─────────────────────────────┐ │
│ │  🚪 Log Out                 │ │ lightRed bg
│ └─────────────────────────────┘ │ 16px padding
│                                 │
```

### STATES

1. **Dark Mode Off**: Shows light_mode icon, subtitle "Off"
2. **Dark Mode On**: Shows dark_mode icon, subtitle "On"
3. **Default**: All tiles displayed, logout at bottom
4. **Coming Soon Tile**: Disabled (tap shows snackbar)
5. **Support & Safety Tap**: Dialog with info text appears

### INTERACTIONS

**Back Button (GestureDetector)**
- onTap: Navigator.pop(context)

**Dark Mode Switch (Switch)**
- onChanged: themeProvider.toggleThemeMode()

**Manage Portfolio Tile (GestureDetector)**
- onTap: Navigator.push(context, MaterialPageRoute to ManagePortfolioScreen)

**Notifications Tile (GestureDetector)**
- onTap: TODO (not yet implemented)

**Support & Safety Tile (GestureDetector)**
- onTap: shows AlertDialog with info:
  - Title: "Support & Safety"
  - Content: "You can report abusive content from task details, chat conversations, and public profiles. For booking issues, open a booking and tap 'Report Issue'."
  - Actions: Close button

**Language Tile (GestureDetector)**
- onTap: TODO (not yet implemented)

**Coming Soon Tile (GestureDetector)**
- onTap: shows SnackBar "Request withdrawal — coming soon" (floating)

**Logout Button (GestureDetector)**
- onTap:
  1. Calls authVM.logout()
  2. Navigator.pushNamedAndRemoveUntil(context, '/login', remove all routes)

### OVERLAYS

**Support & Safety Dialog**
- AlertDialog:
  - Title: "Support & Safety"
  - Content: "You can report abusive content from task details, chat conversations, and public profiles. For booking issues, open a booking and tap 'Report Issue'."
  - Actions: Close button (TextButton)

**Coming Soon SnackBar**
- Content: "Request withdrawal — coming soon"
- Behavior: floating
- No action button

### COMPONENTS USED

- **GlassContainer**: Custom frosted glass effect widget
- **Consumer<ThemeModeProvider>**: Provider state management
- **Switch**: Material widget
- **AlertDialog**: Material dialog
- **SnackBar**: Material overlay
- **ScaffoldMessenger**: Material service

### FIGMA NOTES

Screen dimensions:
- Header sliver: 56px + status bar safe area
- Content sliver: CustomScrollView with padding 24px all
- Settings tiles: full width content area (width - 48px for 24px margins)
- Icon containers: 40x40px (10px padding + 20px icon)
- Tiles: 16px padding, 16px br
- Section headers: 12px after header, 24px before next section
- Coming soon badge: ~56px width × 24px height
- Logout button: full width content, 16px padding, 16px br
- Bottom padding: 24px (implicit from sliver padding)
- Touch targets: 44px minimum (tiles ~48px effective)
- Animations: Switch toggle animation, AlertDialog fade-in
- Safe area: respects MediaQuery.padding.top
- Typography: captionBold 12px (section headers), bodyMedium 14px (tiles)
