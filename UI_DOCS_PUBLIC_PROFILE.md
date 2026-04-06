# SLine Profile Feature - Public Profile & Widgets

## 5. PublicProfileScreen

**File:** `/lib/features/profile/view/public_profile_screen.dart`
**Class:** `PublicProfileScreen` (StatefulWidget)
**Constructor Parameters:** userId (required), initialTabIndex (default 0)
**Providers:** `PublicProfileViewModel`, `FavoritesViewModel`, `ChatViewModel`, `SafetyViewModel`
**State Class:** `_PublicProfileScreenState` with `SingleTickerProviderStateMixin`

### WIDGET TREE

```
ChangeNotifierProvider<PublicProfileViewModel>
└── Scaffold
    ├── backgroundColor: colorScheme.phoneBackground
    ├── body: Consumer<PublicProfileViewModel>
    │   └── [Conditional]
    │       ├── if isLoading:
    │       │   └── Center(CircularProgressIndicator)
    │       │
    │       ├── else if profile == null:
    │       │   └── Center(Text("User not found"))
    │       │
    │       └── else:
    │           └── Stack
    │               ├── NestedScrollView
    │               │   ├── headerSliverBuilder:
    │               │   │   ├── PublicProfileHeader (profile)
    │               │   │   │   └── SliverToBoxAdapter (gradient + avatar header)
    │               │   │   │
    │               │   │   ├── SliverToBoxAdapter (Profile Info Section)
    │               │   │   │   └── Padding (24px horiz, 24px bottom)
    │               │   │   │       └── Column (crossAxisAlignment: start)
    │               │   │   │           ├── SizedBox(60) [spacing from header]
    │               │   │   │           ├── Row (name + verification + actions)
    │               │   │   │           │   ├── Row (name + verified icon)
    │               │   │   │           │   │   ├── Text(profile.name, h3)
    │               │   │   │           │   │   └── [if verified] Icon(check_circle, lightTeal, 20)
    │               │   │   │           │   │
    │               │   │   │           │   └── Row (action buttons)
    │               │   │   │           │       ├── CircleIconButton(share)
    │               │   │   │           │       ├── SizedBox(8)
    │               │   │   │           │       ├── Consumer<FavoritesViewModel>
    │               │   │   │           │       │   └── CircleIconButton(favorite)
    │               │   │   │           │       ├── SizedBox(8)
    │               │   │   │           │       └── CircleIconButton(flag, lightRed)
    │               │   │   │           │
    │               │   │   │           ├── Text(profile.title, bodyMedium, secondary)
    │               │   │   │           ├── SizedBox(4)
    │               │   │   │           ├── Row (location)
    │               │   │   │           │   ├── Icon(location_on, 14, secondary)
    │               │   │   │           │   ├── SizedBox(4)
    │               │   │   │           │   └── Text(profile.location, micro, secondary)
    │               │   │   │           ├── SizedBox(24)
    │               │   │   │           └── PublicProfileStats(profile)
    │               │   │   │
    │               │   │   └── SliverPersistentHeader (pinned TabBar)
    │               │   │       └── TabBar
    │               │   │           ├── controller: _tabController
    │               │   │           ├── labelColor: teal
    │               │   │           ├── unselectedLabelColor: textSecondary
    │               │   │           ├── indicatorColor: teal
    │               │   │           ├── indicatorSize: label
    │               │   │           └── tabs: [About, Portfolio, History, Reviews]
    │               │   │
    │               │   └── body: TabBarView
    │               │       ├── Tab 0 - About
    │               │       │   └── SingleChildScrollView
    │               │       │       └── Column
    │               │       │           ├── Text("Bio", h5)
    │               │       │           ├── SizedBox(8)
    │               │       │           ├── Text(profile.bio, bodySmall, secondary)
    │               │       │           ├── SizedBox(24)
    │               │       │           ├── Text("Skills", h5)
    │               │       │           ├── SizedBox(8)
    │               │       │           ├── Wrap (skills containers)
    │               │       │           │   └── skill: Container(padding 12h×6v, br=8)
    │               │       │           │       └── Text(skill, captionBold)
    │               │       │           └── SizedBox(100) [bottom padding]
    │               │       │
    │               │       ├── Tab 1 - Portfolio
    │               │       │   └── SingleChildScrollView
    │               │       │       └── Column
    │               │       │           ├── PublicProfilePortfolio(portfolio)
    │               │       │           └── SizedBox(100)
    │               │       │
    │               │       ├── Tab 2 - History
    │               │       │   ├── if profile.history.isEmpty:
    │               │       │   │   └── Center(Text("No completed work yet."))
    │               │       │   │
    │               │       │   └── else:
    │               │       │       └── ListView.separated
    │               │       │           ├── controller: _historyScrollController
    │               │       │           ├── padding: 24 all, bottom 100
    │               │       │           ├── itemCount: history.length
    │               │       │           ├── separator: SizedBox(12)
    │               │       │           └── item: TaskCard(task)
    │               │       │
    │               │       └── Tab 3 - Reviews
    │               │           └── SingleChildScrollView
    │               │               └── Column
    │               │                   ├── PublicProfileReviews(reviews)
    │               │                   └── SizedBox(100)
    │               │
    │               └── Positioned (Sticky Bottom Bar)
    │                   ├── bottom: 24, left: 24, right: 24
    │                   └── GlassContainer
    │                       ├── padding: 8 horiz, 8 vert
    │                       └── Row
    │                           ├── Expanded
    │                           │   └── TextButton.icon
    │                           │       ├── icon: Icon(message)
    │                           │       ├── label: Text("Message")
    │                           │       └── onPressed: _handleMessageAction()
    │                           │
    │                           ├── Container (divider, 1w×24h, grey alpha 0.3)
    │                           │
    │                           └── Expanded
    │                               └── Padding (8 horiz)
    │                                   └── AppButton
    │                                       ├── text: "Hire Now"
    │                                       ├── height: 46
    │                                       └── onPressed: {}
```

### UI ELEMENTS

**Header (PublicProfileHeader)**
- Gradient background: teal to lightTeal, 120px height
- Avatar: 80x80, positioned at top: 80, left: 20, rounded corners 20px
- Avatar border: 4px white/phoneBackground
- Online badge: 16x16 green circle, positioned at top: 140, left: 80
- Back button: CircleAvatar (black26), top-left positioned

**Profile Info Section**
- Name row:
  - Text: h3 typography
  - Verified icon: check_circle, lightTeal (#93ccce), 20px (if profile.verified=true)
- Action buttons (right side):
  - Share button: CircleIconButton
  - Favorite button: Heart icon (filled=red, unfilled=textSecondary)
  - Report button: Flag icon, lightRed
  - All: 8px spacing between
- Title: bodyMedium, textSecondary, bold
- Location: row with location_on icon (14px), micro text, textSecondary
- Stats container: PublicProfileStats component

**TabBar (SliverPersistentHeader, pinned)**
- Tabs: About, Portfolio, History, Reviews
- Label color: teal
- Unselected: textSecondary
- Indicator: teal underline, label size
- Label style: bodySmall, bold
- Background: phoneBackground

**About Tab**
- Bio section:
  - Title: "Bio", h5
  - Text: bodySmall, textSecondary, height=1.5
- Skills section:
  - Title: "Skills", h5
  - Wrap layout (8px spacing, 8px runSpacing)
  - Skill items: Container with padding (12px horiz, 6px vert), 8px br, cardBackground border
  - Text: captionBold, colorScheme.text

**Portfolio Tab**
- PublicProfilePortfolio component (masonry 2-column grid)

**History Tab**
- Empty state: Text "No completed work yet." (center)
- Loaded: ListView with TaskCard items, 12px separator

**Reviews Tab**
- PublicProfileReviews component (list of review cards)

**Bottom Action Bar (Positioned Overlay)**
- GlassContainer: padding 8px horiz×8px vert
- Row layout:
  - Message button (left): TextButton.icon, icon + label
  - Divider: 1px×24px grey line
  - Hire Now button (right): AppButton, 46px height
  - All centered vertically

### COLORS USED
- **teal (#146068)**: Name verification icon, TabBar label/indicator
- **lightTeal (#93ccce)**: Online badge, favorite filled icon
- **lightRed (#f49d9d)**: Report/flag button
- **cardBackground**: Skill containers
- **phoneBackground**: Scaffold background, TabBar background
- **textSecondary**: Title, location, description, unselected tab label
- **text**: Skill text, message button
- **white**: Avatar border, divider background

### LAYOUT WIREFRAME

```
┌─────────────────────────────────┐
│ [Gradient Header - 120px]       │ teal→lightTeal
│   [↶] [80x80 Avatar] [🟢]       │
├─────────────────────────────────┤
│ John Doe ✓          [🔗❤️🚩]  │ 60px spacing from header
│ UI Designer          24px horiz margin
│ 📍 San Francisco                │
│                                 │
│ ┌─────────────────────────────┐ │
│ │ 92% │ 15 │ $45/hr          │ │ Stats
│ └─────────────────────────────┘ │
│                                 │
│ About │ Portfolio │ History │ Reviews  [pinned]
├─────────────────────────────────┤
│ Bio                             │ Content scrolls
│ Lorem ipsum...                  │
│                                 │
│ Skills                          │
│ [Flutter] [Dart] [Design]       │
│                                 │
├─────────────────────────────────┤ [Sticky Bottom - 24px margin]
│ [💬 Message] │ [Hire Now 46px] │
└─────────────────────────────────┘
```

### STATES

1. **Loading**: Shows CircularProgressIndicator
2. **User Not Found**: Shows "User not found" text
3. **Profile Loaded**: Displays all content
4. **Tab Active**: Current tab content visible (About=default, initialTabIndex param)
5. **Favorite Toggle**: Heart icon filled/unfilled based on FavoritesViewModel
6. **Message Loading**: LoadingUtils overlay appears during conversation creation

### INTERACTIONS

**Back Button (PublicProfileHeader)**
- onTap: Not explicitly defined in header, but CircleAvatar/BackButton handles standard pop behavior

**Share Button (CircleIconButton)**
- onTap: TODO (not yet implemented)

**Favorite Button (Consumer<FavoritesViewModel>)**
- onTap:
  - If isFavorited: calls favoritesVm.remove(profile.id)
  - Else: calls favoritesVm.add(profile.id)
  - Icon updates in real-time

**Report Button (CircleIconButton)**
- onTap: _reportUserProfileAction(context, profile.id)
- Opens AlertDialog for report submission

**Message Button (TextButton.icon)**
- onPressed: _handleMessageAction(context, profile.id)
- Shows LoadingUtils overlay
- Creates/gets conversation via chatVm.createOrGetConversation()
- Navigates to ChatScreen on success

**Hire Now Button (AppButton)**
- onPressed: {} (not yet implemented)

**Tab Selection (TabBar)**
- onTap: Updates TabController, shows corresponding TabBarView content

### OVERLAYS

**Report User Dialog (_reportUserProfileAction)**
- AlertDialog:
  - Title: "Report User"
  - Content: TextField (maxLines=4, hintText: "Describe the issue")
  - Actions:
    - Cancel button: pops dialog
    - Submit button: calls vm.submitReport(entityType='user', entityId, reason)
      - Shows SnackBar: "Report submitted." or error message
  - Dynamic reason text collection

**Message Loading Overlay (LoadingUtils)**
- Semi-transparent overlay with loading indicator
- Auto-dismissed on conversation creation or error
- Error SnackBar: "Error starting chat: {error}"

**Message Validation SnackBar**
- Not logged in: "You must be logged in to message."
- Self-message: "You cannot message yourself."

### COMPONENTS USED

- **NestedScrollView**: For complex scrolling with persistent header
- **PublicProfileHeader**: Custom sliver widget
- **PublicProfileStats**: Custom stats display widget
- **PublicProfilePortfolio**: Custom masonry grid widget
- **PublicProfileReviews**: Custom review list widget
- **TaskCard**: External widget from tasks feature
- **CircleIconButton**: Custom icon button widget
- **GlassContainer**: Custom frosted glass widget
- **AppButton**: Custom button widget
- **LoadingUtils**: Custom loading overlay service

### FIGMA NOTES

Screen dimensions:
- Header gradient: full width × 120px height
- Avatar: 80×80px, positioned absolutely at top: 80, left: 20
- Name section: 60px spacing from header top to account for avatar overlap
- Content padding: 24px horizontal, 24px bottom for action bar clearance
- Stats container: full width - 48px (24px margins)
- TabBar: pinned, full width background=phoneBackground
- Tab content: varies by tab (scrollable columns or lists)
- Action bar: positioned fixed at bottom, 24px margins all sides, 8px internal padding
- Action buttons: 46px height (Message button), Divider 24px height
- Safe area: respects top padding in header sliver
- Touch targets: 44px minimum (circular buttons 48px effective)
- Animations:
  - NestedScrollView parallax header collapse
  - TabBar switch with cross-fade
  - SnackBar slide-up
  - LoadingUtils fade-in/out
- ScrollControllers: 4 separate controllers (about, portfolio, history, reviews) to prevent "attached to multiple" errors

---

## 6. PublicProfileHeader

**File:** `/lib/features/profile/view/widgets/public_profile/public_profile_header.dart`
**Class:** `PublicProfileHeader` (StatelessWidget, SliverToBoxAdapter)
**Input:** `FreelancerProfile profile`

### WIDGET TREE

```
SliverToBoxAdapter
└── Stack (clipBehavior: none)
    ├── Container (Gradient Background)
    │   ├── height: 120
    │   └── decoration: LinearGradient
    │       ├── colors: [teal, lightTeal]
    │       ├── begin: centerLeft, end: centerRight
    │
    ├── Positioned (Back Button)
    │   ├── top: 40, left: 16
    │   └── CircleAvatar (black26 bg)
    │       └── BackButton (white icon)
    │
    ├── Positioned (Avatar)
    │   ├── top: 80, left: 20
    │   └── Container
    │       ├── width: 80, height: 80
    │       ├── decoration:
    │       │   ├── color: gold
    │       │   ├── br: 20
    │       │   └── border: 4px white/phoneBackground
    │       └── ClipRRect (br: 20-4=16)
    │           └── SignedAvatar
    │               ├── storagePathOrUrl: profile.avatarUrl
    │               ├── size: 80
    │               ├── borderRadius: 16
    │               └── placeholder: initials text
    │
    └── Positioned (Online Badge)
        ├── [if profile.online]
        ├── top: 140, left: 80
        └── Container
            ├── width: 16, height: 16
            ├── decoration:
            │   ├── color: lightTeal
            │   ├── shape: circle
            │   └── border: 2px white/phoneBackground
```

### UI ELEMENTS

**Gradient Background**
- Height: 120px
- LinearGradient: teal (#146068) to lightTeal (#93ccce)
- Direction: centerLeft to centerRight

**Back Button**
- Position: top 40px, left 16px
- CircleAvatar background: black26 (semi-transparent black)
- Icon: BackButton, white color
- Implicit touch area: ~48px diameter

**Avatar Container**
- Position: top 80px, left 20px (overlaps gradient by 40px)
- Size: 80×80px
- Background color: gold (#f3bb19)
- Border radius: 20px
- Border: 4px solid white/phoneBackground
- Inner ClipRRect: 16px border radius (20-4)
- Content: SignedAvatar with placeholder showing initials

**Online Badge**
- Position: top 140px, left 80px (right edge of avatar)
- Size: 16×16px
- Background color: lightTeal (#93ccce) - indicates online
- Shape: perfect circle
- Border: 2px white/phoneBackground
- Visibility: conditional on profile.online=true

### COLORS USED
- **teal (#146068)**: Gradient start color
- **lightTeal (#93ccce)**: Gradient end color, online badge
- **gold (#f3bb19)**: Avatar container background
- **phoneBackground**: Avatar and badge borders
- **black26**: Back button background
- **white**: Back button icon and borders

### LAYOUT WIREFRAME

```
┌─────────────────────────────────┐ top: 0
│ [↶] (black26)                   │ 40px from top, 16px from left
│ Gradient: teal → lightTeal       │
│ Height: 120px                   │
│                                 │
│   [Avatar 80×80] [🟢Online]      │ Avatar: top 80, left 20
│   Gold bg, br=20                │ Badge: top 140, left 80
│                                 │
└─────────────────────────────────┘
```

### STATES

1. **Online=true**: Shows lightTeal badge at right edge of avatar
2. **Online=false**: Badge hidden (conditional rendering)
3. **Avatar Loaded**: SignedAvatar displays user image
4. **Avatar Missing**: Shows placeholder with initials text

### INTERACTIONS

**Back Button (BackButton)**
- onPressed: Implicit (standard Material BackButton behavior)
- Pops current route from navigator

### COLORS & GRADIENTS

**LinearGradient**
- Direction: Alignment.centerLeft to Alignment.centerRight
- Colors: [AppColors.teal, AppColors.lightTeal]
- Creates left-to-right gradient from teal to light teal

### COMPONENTS USED

- **SignedAvatar**: Custom widget for authenticated storage URLs
- **BackButton**: Material widget
- **CircleAvatar**: Material widget
- **ClipRRect**: Material widget

### FIGMA NOTES

Header dimensions:
- Full width × 120px height
- Avatar positioned absolutely: 80px from top, 20px from left
- Avatar size: 80×80px with 20px border radius
- Avatar border width: 4px
- Avatar content border radius: 16px (20 - 4 border width)
- Back button: positioned at top 40px, left 16px, ~48px diameter (CircleAvatar implicit size)
- Online badge: 16×16px positioned at top 140px, left 80px
- Badge border: 2px
- Gradient colors: exact hex codes [#146068, #93ccce]
- Gradient direction: horizontal (left to right)
- Stack clip behavior: none (allows badge to overflow if needed)
- Safe area: no explicit top padding (parent handles it)

---

## 7. PublicProfileStats

**File:** `/lib/features/profile/view/widgets/public_profile/public_profile_stats.dart`
**Class:** `PublicProfileStats` (StatelessWidget)
**Input:** `FreelancerProfile profile`

### WIDGET TREE

```
Container
├── padding: 12px all
├── decoration: BoxDecoration
│   ├── color: teal.withValues(alpha: 0.05)
│   ├── br: 16px
│   └── border: 1px teal.withValues(alpha: 0.1)
│
└── Row
    ├── _buildStatItem("Job Success", profile.jobSuccess)
    ├── _buildDivider()
    ├── _buildStatItem("Total Jobs", profile.jobsCompleted.toString())
    ├── _buildDivider()
    └── _buildStatItem("Hourly", profile.hourlyRate)

_buildStatItem(label, value):
    └── Expanded
        └── Column
            ├── Text(value, h6)
            │   ├── color: teal if label=="Job Success" else text
            │   └── fontWeight: bold
            │
            └── Text(label.toUpperCase(), micro)
                ├── color: textSecondary
                └── fontWeight: bold

_buildDivider():
    └── Container
        ├── width: 1px
        ├── height: 30px
        └── color: grey.withValues(alpha: 0.1)
```

### UI ELEMENTS

**Container Wrapper**
- Padding: 12px all sides
- Background: teal.withValues(alpha: 0.05) - very subtle teal tint
- Border radius: 16px
- Border: 1px solid teal.withValues(alpha: 0.1)

**Stat Items (3 columns)**
- Layout: Row with 3 expanded columns separated by dividers
- Column 1: "Job Success" - value shown in teal
- Column 2: "Total Jobs" - value shown in text color
- Column 3: "Hourly" - value shown in text color

**Stat Item Structure (_buildStatItem)**
- Expanded: equal width for 3 items (minus divider space)
- Column (centered):
  - Value: h6 typography, bold
  - Label: micro typography, uppercase, bold, textSecondary color

**Dividers (_buildDivider)**
- Vertical line: 1px width × 30px height
- Color: grey.withValues(alpha: 0.1)
- Between each stat item

### COLORS USED
- **teal (#146068)**: Background tint (5% alpha), "Job Success" value text
- **text (colorScheme.text)**: "Total Jobs" and "Hourly" value text
- **textSecondary (colorScheme.textSecondary)**: Label text
- **grey (Colors.grey)**: Divider at 10% alpha

### LAYOUT WIREFRAME

```
┌─────────────────────────────────┐ 12px padding
│ 92%      │ 15      │ $45/hr    │
│ JOB      │ TOTAL   │ HOURLY    │
│ SUCCESS  │ JOBS    │           │
└─────────────────────────────────┘ 16px br, teal border
│ = 1px divider (grey alpha 0.1)  │ 30px height each
```

### STATES

Static component - no state changes

### INTERACTIONS

None - display-only component

### COMPONENTS USED

- **Container**: Material widget
- **Row/Column**: Layout widgets
- **Text**: Display widgets

### FIGMA NOTES

Stats container dimensions:
- Padding: 12px all sides
- Border radius: 16px
- Border width: 1px
- Background: teal at 5% opacity
- Border color: teal at 10% opacity
- Content area: 3-column layout with equal flex expansion
- Divider: 1px width × 30px height, grey at 10% opacity
- Text alignment: center in each column
- Value font: h6 (18px), bold
- Label font: micro (10px), uppercase, bold
- Column spacing: implicit (dividers separate them)
- Safe area: none needed

---

## 8. PublicProfilePortfolio

**File:** `/lib/features/profile/view/widgets/public_profile/public_profile_portfolio.dart`
**Class:** `PublicProfilePortfolio` (StatelessWidget)
**Input:** `List<PortfolioItem> portfolio`

### WIDGET TREE

```
Column
├── crossAxisAlignment: start
└── [if portfolio.isEmpty] SizedBox.shrink()
    else:
    ├── Row (Header)
    │   ├── mainAxisAlignment: spaceBetween
    │   ├── Text("Portfolio", h5)
    │   └── Text("View All", caption, teal, w600)
    │
    ├── SizedBox(12)
    │
    └── Row (Masonry Grid - 2 columns)
        ├── Expanded (Left Column - even indices)
        │   └── Column
        │       └── for each item at even index:
        │           └── _PortfolioCard(item, aspectRatio)
        │               ├── aspectRatio=0.8 for index 0
        │               ├── aspectRatio=1.0 for others
        │
        ├── SizedBox(12) [column spacing]
        │
        └── Expanded (Right Column - odd indices)
            └── Column
                └── for each item at odd index:
                    └── _PortfolioCard(item, aspectRatio)
                        ├── aspectRatio=1.2 for index 1
                        ├── aspectRatio=0.9 for others

_PortfolioCard(item, aspectRatio):
    └── Container
        ├── margin: 12px bottom
        └── AspectRatio (aspectRatio)
            └── Container
                ├── decoration: BoxDecoration
                │   ├── color: displayColor (fallback)
                │   ├── br: 16px
                │   └── boxShadow: [shadow with displayColor.alpha(0.3)]
                │
                └── ClipRRect (br: 16px)
                    └── Stack
                        ├── Positioned.fill (Image)
                        │   └── [if imageRef != null]
                        │       └── SignedImage (portfolio bucket)
                        │           └── fit: cover
                        │       else: Container(displayColor)
                        │
                        ├── Positioned.fill (Gradient Overlay)
                        │   └── Container
                        │       ├── gradient: LinearGradient
                        │       │   ├── transparent → black.alpha(0.8)
                        │       │   ├── stops: [0.3, 1.0]
                        │       │   └── direction: topCenter → bottomCenter
                        │       │
                        │       └── br: 16px
                        │
                        └── Positioned (Content)
                            ├── bottom: 12, left: 12, right: 12
                            └── Column (mainAxisSize: min, crossAxisAlignment: start)
                                ├── Text(item.title, bodySmall, white, bold, 1 line ellipsis)
                                ├── SizedBox(2)
                                └── Text(item.displayCategory, micro, white.alpha(0.7))
```

### UI ELEMENTS

**Header Row**
- Title: "Portfolio", h5 typography
- "View All" link: caption, teal color, fontWeight w600
- Spacing: MainAxisAlignment.spaceBetween

**Masonry Grid Layout**
- 2-column layout using Row with Expanded children
- Column spacing: 12px (SizedBox)
- Left column: even indices (0, 2, 4...)
- Right column: odd indices (1, 3, 5...)
- Staggered aspect ratios for visual interest:
  - Index 0: 0.8 (taller)
  - Index 1: 1.2 (shorter, wider)
  - Index 2+: 1.0 / 0.9 (alternating)

**Portfolio Card (_PortfolioCard)**
- Container with 12px bottom margin
- AspectRatio wrapper for dynamic sizing
- Border radius: 16px
- Box shadow: displayColor at 30% opacity, blur 12, offset (0, 4)

**Card Background**
- SignedImage (if available) with cover fit
- Fallback color: displayColor (from item.displayColor property)
- Gradient overlay: transparent at top, black at 80% at bottom (stops: 0.3, 1.0)

**Card Content (Positioned)**
- Position: bottom 12, left 12, right 12
- Column layout:
  - Title: bodySmall, white, bold, maxLines=1, ellipsis
  - Category: micro, white at 70% opacity

### COLORS USED
- **teal (#146068)**: "View All" text
- **displayColor**: Card background (from PortfolioItem, varies per item)
- **white**: Content text
- **black**: Gradient overlay (black at 80% alpha)
- **text/cardBorder**: Not used in this component

### LAYOUT WIREFRAME

```
┌─────────────────────────────────┐
│ Portfolio              View All  │ Header
├─────────────────────────────────┤ 12px spacing
│ ┌──────────────┐ ┌──────────────┐
│ │              │ │              │
│ │   [0.8]      │ │   [1.2]      │ Left column: 0, 2...
│ │  Image       │ │  Image       │ Right column: 1, 3...
│ │  ▓▓▓ Title   │ │  ▓▓ Title    │ 12px between columns
│ │  Category    │ │  Category    │
│ └──────────────┘ └──────────────┘
│     12px down        12px down
│ ┌──────────────┐ ┌──────────────┐
│ │              │ │              │
│ │   [1.0]      │ │   [0.9]      │
│ │  Image       │ │  Image       │
│ │  ▓▓ Title    │ │  ▓▓▓ Title   │
│ │  Category    │ │  Category    │
│ └──────────────┘ └──────────────┘
```

### STATES

- **Empty portfolio**: Returns SizedBox.shrink()
- **Loaded**: Displays masonry grid

### INTERACTIONS

**Card Tap**: Not implemented in this component (likely navigates to detail in parent)

### COMPONENTS USED

- **SignedImage**: Custom widget for authenticated storage URLs
- **AspectRatio**: Material widget for maintaining proportions

### FIGMA NOTES

Portfolio grid dimensions:
- Card border radius: 16px
- Card margin bottom: 12px
- Column spacing: 12px (SizedBox)
- Box shadow: blur 12px, offset (0, 4), color depends on background
- Gradient overlay: black at 80% opacity from 30% to 100% height
- Content padding: 12px all sides (from Positioned)
- Aspect ratios: 0.8 (index 0), 1.2 (index 1), 1.0/0.9 (subsequent)
- Title font: bodySmall (14px), bold, white
- Category font: micro (10px), white at 70% opacity
- Category line height: not specified (single line assumed)
- Content alignment: bottom-left
- Images: fit: cover (fills container while maintaining aspect)
- Placeholder color: item.displayColor (varies)
- Safe area: inherits parent padding

---

## 9. PublicProfileReviews

**File:** `/lib/features/profile/view/widgets/public_profile/public_profile_reviews.dart`
**Class:** `PublicProfileReviews` (StatelessWidget)
**Input:** `List<ReviewItem> reviews`

### WIDGET TREE

```
Column
├── crossAxisAlignment: start
└── [if reviews.isEmpty] SizedBox.shrink()
    else:
    ├── Row (Header)
    │   ├── mainAxisAlignment: spaceBetween
    │   ├── Text("Reviews", h5)
    │   └── Text("Recent", caption, textSecondary)
    │
    ├── SizedBox(12)
    │
    └── ...reviews.map((review) => _ReviewCard(review))

_ReviewCard(review):
    └── Container
        ├── margin: 12px bottom
        ├── padding: 16px all
        ├── decoration: BoxDecoration
        │   ├── color: cardBackground
        │   ├── br: 16px
        │   └── border: 1px cardBorder
        │
        └── Column (crossAxisAlignment: start)
            ├── Row (Header Row)
            │   ├── mainAxisAlignment: spaceBetween
            │   ├── crossAxisAlignment: start
            │   │
            │   ├── Row (Client Info)
            │   │   ├── Container (Avatar)
            │   │   │   ├── width: 32, height: 32
            │   │   │   ├── color: lightTeal
            │   │   │   ├── shape: circle
            │   │   │   └── child: Text(initials, micro, black, w800)
            │   │   │
            │   │   ├── SizedBox(8)
            │   │   │
            │   │   └── Column
            │   │       ├── Text(review.client, bodySmall, text, bold)
            │   │       ├── SizedBox(2)
            │   │       └── Row (Star Rating)
            │   │           └── for i in 0..4:
            │   │               └── Padding(right: 2)
            │   │                   └── Icon(star, 12)
            │   │                       ├── color: gold if i<rating else textTertiary
            │   │
            │   └── Text(review.date, micro, textSecondary)
            │
            ├── SizedBox(12)
            │
            └── Text('"${review.comment}"', bodySmall, textSecondary, italic)
                └── height: 1.4
```

### UI ELEMENTS

**Review Section Header**
- Title: "Reviews", h5 typography
- Subtitle: "Recent", caption, textSecondary
- Layout: spaceBetween (title left, subtitle right)

**Review Card (_ReviewCard)**
- Padding: 16px all
- Background: cardBackground
- Border: 1px cardBorder
- Border radius: 16px
- Margin bottom: 12px

**Card Header Row (Client Info + Date)**
- Left side: Client avatar, name, star rating
  - Avatar: 32×32px circle, lightTeal background
  - Initials: micro, black, bold (w800)
  - Name: bodySmall, text, bold
  - Stars: 5 × Icon(star, 12px)
    - Filled: gold color
    - Empty: textTertiary color
  - Spacing: 8px between avatar and name column
- Right side: Date text (micro, textSecondary)

**Comment Section**
- Quoted text: `"${review.comment}"`
- Typography: bodySmall, textSecondary, italic
- Line height: 1.4

### COLORS USED
- **cardBackground**: Card background
- **cardBorder**: Card border
- **lightTeal (#93ccce)**: Avatar background
- **gold (#f3bb19)**: Filled star icons
- **textTertiary**: Empty star icons
- **text (colorScheme.text)**: Client name
- **textSecondary (colorScheme.textSecondary)**: Date, comment text
- **black**: Avatar initials

### LAYOUT WIREFRAME

```
┌─────────────────────────────────┐
│ Reviews                  Recent  │ Header
├─────────────────────────────────┤ 12px spacing
│ ┌─────────────────────────────┐ │
│ │ [🟢] John Smith    2 days ago │ 16px padding
│ │    ⭐⭐⭐⭐⭐                  │ 12px spacing
│ │                              │
│ │ "Great work, highly          │
│ │  recommend this person!"     │
│ └─────────────────────────────┘ │ 16px br, border
│ ┌─────────────────────────────┐ │ 12px margin bottom
│ │ [🟢] Jane Doe      1 week ago │
│ │    ⭐⭐⭐⭐☆                  │ 12px margin bottom
│ │                              │
│ │ "Good designer but slow       │
│ │  delivery."                  │
│ └─────────────────────────────┘ │
```

### STATES

- **Empty reviews**: Returns SizedBox.shrink()
- **With reviews**: Displays list of review cards

### INTERACTIONS

**Review Card**: Display only, no tap action

### COMPONENTS USED

- **Icon**: Material widget for stars
- **Container**: Layout widget

### FIGMA NOTES

Review card dimensions:
- Padding: 16px all
- Border radius: 16px
- Border width: 1px
- Margin bottom: 12px between cards
- Avatar size: 32×32px (circle)
- Avatar background: lightTeal (#93ccce)
- Initials font: micro (10px), black, w800
- Name font: bodySmall (12px), bold
- Star icon size: 12px
- Star spacing: 2px right
- Date font: micro (10px), textSecondary
- Comment font: bodySmall (12px), italic, textSecondary
- Comment line height: 1.4
- Quotation marks: included in text
- Safe area: inherits parent padding

---

## 10. ProfileAvatarWidget

**File:** `/lib/features/profile/view/widgets/profile_avatar_widget.dart`
**Class:** `ProfileAvatarWidget` (StatelessWidget)
**Constructor Parameters:**
- `radius` (default 60)
- `enableEdit` (default true)
**Provider:** `ProfileViewModel`

### WIDGET TREE

```
Consumer<ProfileViewModel>
└── Center
    └── Stack
        ├── alignment: center
        │
        ├── Container (Avatar)
        │   ├── width: diameter (radius * 2)
        │   ├── height: diameter
        │   ├── decoration: BoxDecoration
        │   │   ├── shape: circle
        │   │   ├── color: Colors.grey.shade200
        │   │   ├── border: 3px primary color
        │   │   └── image: [if hasImage]
        │   │       ├── image: NetworkImage(avatarSignedUrl)
        │   │       └── fit: cover
        │   │
        │   └── [if not hasImage]
        │       └── Icon(person, radius size, grey)
        │
        ├── [if enableEdit]
        │   └── Positioned (Edit Button)
        │       ├── bottom: 0, right: 0
        │       └── Container
        │           ├── decoration: BoxDecoration
        │           │   ├── color: primary
        │           │   ├── shape: circle
        │           │   └── border: 2px white
        │           │
        │           └── IconButton
        │               ├── icon: camera_alt (20, white)
        │               └── onPressed: pickAndUploadAvatar()
        │
        └── [if avatarUploading]
            └── Container (Loading Overlay)
                ├── width: 124 (radius*2 + buffer)
                ├── height: 124
                ├── decoration: BoxDecoration
                │   ├── color: black.alpha(0.25)
                │   └── shape: circle
                │
                └── Center
                    └── SizedBox(24x24)
                        └── CircularProgressIndicator(strokeWidth: 2)
```

### UI ELEMENTS

**Avatar Container**
- Shape: Circle (BoxShape.circle)
- Size: diameter = radius × 2 (default 120px at radius=60)
- Background: Colors.grey.shade200
- Border: 3px solid primary color
- Content:
  - If hasImage: NetworkImage from avatarSignedUrl
  - If no image: Icon(person, size=radius)

**Edit Button (Bottom-Right)**
- Position: Positioned(bottom: 0, right: 0)
- Container:
  - Background: Theme.of(context).primaryColor (teal)
  - Shape: circle
  - Border: 2px white
  - Implicit size ~56px (IconButton 48px + padding)
- Icon: camera_alt, 20px, white
- onPressed: calls vm.pickAndUploadAvatar()

**Loading Overlay**
- Position: Center of avatar (via Stack alignment)
- Size: 124×124px (approximately)
- Background: black.withValues(alpha: 0.25) - semi-transparent overlay
- Shape: circle
- Content: CircularProgressIndicator(24×24, strokeWidth: 2)

### COLORS USED
- **primary (colorScheme.primary / teal)**: Avatar border, edit button background
- **white**: Edit button border, camera icon
- **grey.shade200**: Avatar background (placeholder)
- **black**: Loading overlay (25% alpha)
- **grey (standard)**: Placeholder person icon

### LAYOUT WIREFRAME

```
         [Camera Button]
            (Primary)
         ↓ (bottom-right)
    ┌──────────────────┐
    │    [Avatar]      │
    │   ┌─────────────┐│
    │   │   Image     ││ 3px border
    │   │   or Icon   ││ (primary)
    │   │   person    ││
    │   └─────────────┘│
    │        [📷]      │
    └──────────────────┘
        [Loading Spinner]
        (if uploading)
```

### STATES

1. **No Image**: Shows person icon, grey background
2. **Image Loaded**: Shows NetworkImage (from avatarSignedUrl)
3. **Edit Button Disabled**: When enableEdit=false (not shown)
4. **Uploading**: Shows semi-transparent overlay with spinner on top of avatar

### INTERACTIONS

**Edit Button (IconButton)**
- onPressed:
  - Calls vm.pickAndUploadAvatar()
  - On error: shows SnackBar with vm.avatarUploadError message
  - Sets vm.avatarUploading flag during upload

**Image Upload Flow**
- Sets vm.avatarUploading = true (shows loading overlay)
- Picks image and uploads via vm.pickAndUploadAvatar()
- Sets vm.avatarUploading = false (hides loading overlay)
- Updates vm.avatarSignedUrl (triggers avatar refresh)

### OVERLAYS

**Upload Error SnackBar**
- Content: Text from vm.avatarUploadError
- Shown when pick succeeds but upload fails or returns error

### COMPONENTS USED

- **NetworkImage**: Flutter widget for loading images from URLs
- **CircularProgressIndicator**: Material widget

### FIGMA NOTES

Avatar widget dimensions:
- Radius parameter: default 60px (120px diameter)
- Avatar container: 120×120px (at default radius)
- Avatar border width: 3px
- Border color: primary (#146068 - teal)
- Person icon size: equal to radius parameter
- Edit button position: absolute bottom-right corner
- Edit button size: ~48px (IconButton implicit)
- Edit button border: 2px white
- Edit button icon: 20px camera_alt
- Loading overlay: ~124×124px circle (diameter + buffer)
- Loading spinner: 24×24px with strokeWidth 2
- Loading overlay background: black at 25% opacity
- Safe area: inherits parent padding/positioning

---

## 11. ProfilePreviewModal

**File:** `/lib/features/profile/view/widgets/profile_preview_modal.dart`
**Function:** `showProfilePreview(BuildContext context, String userId)`

### WIDGET TREE

```
showModalBottomSheet(
├── context: context
├── isScrollControlled: true
├── backgroundColor: transparent
│
└── builder: DraggableScrollableSheet
    ├── initialChildSize: 0.9 (90% screen height)
    ├── minChildSize: 0.5 (50% screen height)
    ├── maxChildSize: 0.95 (95% screen height)
    │
    └── builder: (_, controller)
        └── Container
            ├── decoration: BoxDecoration
            │   └── borderRadius: vertical top 24px
            │
            ├── clipBehavior: antiAlias
            │
            └── child: PublicProfileScreen(userId: userId)
```

### UI ELEMENTS

**Bottom Sheet Container**
- Border radius: 24px (top corners only)
- Background: Transparent (uses DraggableScrollableSheet default)
- Clip behavior: antiAlias (smooth corners)

**DraggableScrollableSheet**
- Initial height: 90% of screen
- Min drag height: 50% of screen
- Max drag height: 95% of screen
- Allows user to drag sheet up/down to resize

**Content**
- PublicProfileScreen embedded inside sheet
- Inherits userId parameter from function argument

### COLORS USED
- **transparent**: Bottom sheet background (allows card shadow)
- **white/surface**: Sheet content background (from PublicProfileScreen)

### LAYOUT WIREFRAME

```
[Existing Content Behind]
├────────────────────────────┐
│                            │ 90% initial height
│  PublicProfileScreen       │ 50-95% draggable range
│  (Name, Avatar, Tabs)      │ 24px rounded top corners
│  [scrollable content]       │
│                            │
└────────────────────────────┘
```

### STATES

1. **Closed**: Modal dismissed (backgroundColor transparent allows see-through)
2. **Open (90%)**: Initial state when showProfilePreview called
3. **Expanded (95%)**: User drags sheet up
4. **Collapsed (50%)**: User drags sheet down

### INTERACTIONS

**Drag Gestures**
- User drags sheet up: expands to 95%
- User drags sheet down: collapses to 50%
- Drag below 50%: sheet dismisses

**Scroll in Content**
- Content (PublicProfileScreen) can scroll when at 90%+
- Drag handle appears at top for sheet manipulation

### COMPONENTS USED

- **showModalBottomSheet**: Material function
- **DraggableScrollableSheet**: Material widget
- **PublicProfileScreen**: Custom screen widget

### FIGMA NOTES

Modal dimensions:
- Border radius: 24px (top-left and top-right, vertical only)
- Initial height: 90% of screen
- Minimum height: 50% of screen
- Maximum height: 95% of screen
- Background: transparent (sheet appears to float)
- Sheet background: white/surface (from child widget)
- Clip behavior: antiAlias (smooth rendering)
- Safe area: respects bottom padding for notch/home indicator
- Animation: Smooth height transitions on drag
- Scroll behavior: Content scrolls independently when content exceeds available height
