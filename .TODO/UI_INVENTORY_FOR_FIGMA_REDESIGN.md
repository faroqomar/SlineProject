# 🎨 SLine App - Complete UI Inventory for Figma Redesign

**Project**: SLine - Freelance Marketplace
**Created**: 2025-11-01
**Purpose**: Comprehensive screen inventory for UI/UX redesign
**Total Screens**: 16 main screens + 10 modal sheets + 7 reusable components

---

## 📱 Navigation Structure

```
App Entry
├─ 1. Login Screen (unauthenticated)
├─ 2. Signup Screen (unauthenticated)
└─ Main Navigation (authenticated) ← Bottom Nav Bar (4 tabs)
    ├─ Tab 1: Home Screen
    ├─ Tab 2: Messages Screen
    ├─ Tab 3: Create Task Screen
    └─ Tab 4: Profile Screen
```

---

## 🎯 Screen Categories

### **Authentication Screens** (2)
### **Main Navigation Screens** (4)
### **Secondary Screens** (10)
### **Modal Sheets & Dialogs** (10)
### **Reusable Components** (7)

---

# 📋 DETAILED SCREEN INVENTORY

---

## 🔐 AUTHENTICATION FLOW

### 1. **Login Screen**
**File**: `lib/features/auth/view/login_screen.dart`

**When User Sees It:**
- App first launch (no session)
- After logout
- Session expired

**What It Displays:**
- App logo/branding at top
- Email text field (with validation)
- Password text field (obscured, with validation)
- "Login" button (disabled while loading)
- "Sign Up" navigation link at bottom
- Loading indicator when submitting

**User Actions:**
- Enter email and password
- Tap "Login" button → Navigate to Main Navigation Screen
- Tap "Sign Up" link → Navigate to Signup Screen
- Form validation on submit

**Important UI Notes:**
- Uses Material Design 3
- Primary color in AppBar
- White text on colored AppBar
- Centered form layout
- Button shows loading state

**Design Recommendations:**
- Add "Forgot Password?" link
- Add social login buttons (Google, Apple)
- Improve empty state messaging
- Add password visibility toggle
- Consider adding illustration/hero image
- Add smooth loading animations

---

### 2. **Signup Screen**
**File**: `lib/features/auth/view/signup_screen.dart`

**When User Sees It:**
- Tapping "Sign Up" from Login Screen
- New user registration flow

**What It Displays:**
- App logo/branding
- Full Name text field
- Email text field (with validation)
- Password text field (obscured, with validation)
- "Sign Up" button (disabled while loading)
- "Already have account? Login" link
- Loading indicator when submitting

**User Actions:**
- Enter registration details
- Tap "Sign Up" → Creates account + profile → Navigate to Main Navigation
- Tap "Login" link → Navigate to Login Screen
- Form validation on submit

**Important UI Notes:**
- Same styling as Login Screen for consistency
- Profile automatically created after auth signup
- Session immediately established

**Design Recommendations:**
- Add password strength indicator
- Add terms & privacy policy checkboxes
- Show password requirements
- Add profile picture upload in signup flow
- Consider multi-step signup (email → details → preferences)
- Add welcome animation after successful signup

---

## 🏠 MAIN NAVIGATION SCREENS (Bottom Nav Bar)

### 3. **Home Screen** (Tab 1)
**File**: `lib/features/home/view/home_screen.dart`

**When User Sees It:**
- Default landing screen after authentication
- Bottom nav "Home" tab selected
- App logo "SLine" in AppBar

**What It Displays:**
```
AppBar:
- Title: "SLine"
- Saved Tasks icon button (bookmark)
- Refresh icon button
- Add Task icon button (+)

Search Bar:
- Search text field with filter icon
- Category dropdown filter
- Clear filters button

Body (Scrollable List):
- Featured/Open tasks as cards (TaskCard component)
- Each card shows:
  * Task title
  * Category name
  * Budget (formatted price)
  * Task type badge (Tender/Booking)
  * Task images (if available)
  * User avatar + name
  * Saved/Bookmark icon (toggleable)

Empty State:
- "No tasks available" message
- Refresh button

Loading State:
- Circular progress indicator
```

**User Actions:**
- Pull-to-refresh → Reload tasks
- Tap search field → Filter tasks by text
- Tap category dropdown → Filter by category
- Tap "Clear" → Reset all filters
- Tap task card → Navigate to Task Details Screen
- Tap bookmark icon → Toggle save task
- Tap "Saved Tasks" button → Navigate to Saved Tasks Screen
- Tap "+" button → Navigate to Create Task Screen (pre-filled context)
- Tap "Refresh" button → Reload tasks

**Important UI Notes:**
- Uses TaskFilterViewModel for search/filter state
- Integrates with SavedTasksViewModel for bookmark state
- Cards use conditional styling (tender vs booking)
- Real-time sync with saved status
- Performance optimized with joins (fetches author + category in one query)

**Design Recommendations:**
- Add category chips/tabs for quick filtering
- Add sort options (newest, budget, deadline)
- Add infinite scroll/pagination UI
- Improve empty states with illustrations
- Add skeleton loaders instead of spinner
- Consider card/list view toggle
- Add trending/popular section
- Add quick action FAB for common tasks
- Improve search UX with recent searches
- Add filter chips showing active filters

---

### 4. **Messages Screen** (Tab 2)
**File**: `lib/features/chat/view/messages_screen.dart`

**When User Sees It:**
- Bottom nav "Messages" tab selected
- Conversations list view

**What It Displays:**
```
AppBar:
- Title: "Messages"

Body (Scrollable List):
- Conversations as ListTiles:
  * Other user avatar (circle)
  * Other user name (bold)
  * Task title (if task-linked, small gray text)
  * Last message preview (truncated)
  * Last message timestamp (formatted local time)
  * Unread indicator (optional future feature)

Empty State:
- "No conversations yet." message

Loading State:
- Circular progress indicator
```

**User Actions:**
- Tap conversation → Navigate to Chat Screen (1:1 messages)
- Pull-to-refresh → Reload conversations
- Real-time updates via Supabase Realtime

**Important UI Notes:**
- Realtime subscriptions active (updates without refresh)
- Shows both DM and task-linked conversations
- Uses formatted local timestamps
- WhatsApp-style conversation list

**Design Recommendations:**
- Add search conversations feature
- Add unread count badges
- Add swipe actions (archive, delete, pin)
- Add timestamp grouping (Today, Yesterday, This Week)
- Improve avatar handling with signed URLs
- Add online status indicators
- Add typing indicators preview
- Add conversation filtering (All, Unread, Task Chats, DMs)
- Consider adding message preview with attachments icons
- Add empty state illustration

---

### 5. **Create Task Screen** (Tab 3)
**File**: `lib/features/tasks/view/create_task_screen.dart`

**When User Sees It:**
- Bottom nav "Create Task" tab selected
- "+" button from Home Screen
- Edit mode: when editing existing task

**What It Displays:**
```
AppBar:
- Title: "Create Task" or "Edit Task"

Body (Scrollable Form):
- Task Type Selector:
  * Radio buttons: "Request (Tender)" | "Service (Booking)"

- Title text field (required)
- Description text field (multiline, required)
- Budget text field (numeric, required)
- Deadline picker (optional date selector)
- Category dropdown (from database categories)
- Image picker section:
  * Selected images preview
  * Add image button
  * Remove image buttons

- Create/Update button (disabled while loading)
- Cancel button

Loading State:
- Progress indicator on button
```

**User Actions:**
- Select task type (tender/booking)
- Fill form fields
- Pick deadline date → Date picker dialog
- Select category → Dropdown menu
- Tap "Add Image" → Image picker → Select multiple images
- Tap image "X" → Remove image
- Tap "Create Task" → Validate → Upload images → Create task → Navigate back with success
- Tap "Cancel" → Navigate back

**Important UI Notes:**
- Edit mode pre-fills all fields from existing task
- Image compression before upload
- Validation on submit
- Success SnackBar after creation
- Returns result to calling screen for refresh

**Design Recommendations:**
- Add drag-to-reorder for images
- Add image preview modal
- Add skills/tags input field
- Add draft save functionality
- Add step-by-step wizard for complex tasks
- Improve date picker UX
- Add price range suggestions
- Add character count for description
- Add rich text editor for description
- Add template selection for common task types
- Show image upload progress
- Add auto-save indicators

---

### 6. **Profile Screen** (Tab 4)
**File**: `lib/features/profile/view/profile_screen.dart`

**When User Sees It:**
- Bottom nav "Profile" tab selected
- User's own profile management

**What It Displays:**
```
AppBar:
- Title: "Profile"
- Favorites icon button (heart outline)
- Logout icon button

Tabs (3):
┌─────────────────────────────────────┐
│ Profile Info │ My Tasks │ Portfolio │
└─────────────────────────────────────┘

TAB 1: Profile Info
- Profile avatar (circular, editable)
- Full Name text field
- Email text field
- Phone text field (optional)
- Bio text area (optional)
- Role selector: "Client" | "Freelancer"
- Language selector dropdown
- Update Profile button

TAB 2: My Tasks
- User's created tasks list (TaskCard components)
- Each task shows:
  * Edit button → Navigate to Edit Task
  * Delete button → Confirm dialog → Delete
- Empty state: "No tasks yet"
- Create new task button

TAB 3: Portfolio
- Embedded PortfolioScreen
- Shows user's portfolio items
- Add/Edit/Delete portfolio items
```

**User Actions:**
- **Profile Info Tab:**
  * Tap avatar → Pick image → Upload → Update profile
  * Edit text fields → Tap "Update" → Save profile
  * Change role → Auto-save
  * Change language → Auto-save

- **My Tasks Tab:**
  * Tap task card → Navigate to Task Details
  * Tap "Edit" → Navigate to Edit Task Screen
  * Tap "Delete" → Confirm dialog → Delete task → Refresh list
  * Tap "Create Task" → Navigate to Create Task Screen

- **Portfolio Tab:**
  * See PortfolioScreen actions below

- **AppBar Actions:**
  * Tap "Favorites" → Navigate to Favorites Screen
  * Tap "Logout" → Confirm → Logout → Navigate to Login Screen

**Important UI Notes:**
- Uses TabBar with 3 tabs
- Profile avatar uses SignedAvatar widget for private storage
- Form validation on profile update
- Task list shows edit/delete only for owner's tasks
- Portfolio embedded as full screen

**Design Recommendations:**
- Add profile completion progress bar
- Add verification badge system
- Add statistics cards (tasks completed, ratings, etc.)
- Improve avatar upload with crop/filter options
- Add profile preview mode (how others see you)
- Add settings gear icon for app preferences
- Separate settings from profile
- Add profile cover photo
- Add social media links section
- Add skills/expertise section
- Add reviews/ratings section
- Add activity feed/history
- Improve empty states for all tabs

---

## 📄 SECONDARY SCREENS

### 7. **Task Details Screen**
**File**: `lib/features/tasks/view/task_details_screen.dart`

**When User Sees It:**
- Tapping any task card from Home, Profile, Saved Tasks
- Deep link to specific task

**What It Displays:**
```
AppBar:
- Title: Task title
- Back button

Body (Scrollable Card):
- Task badge (Tender/Booking with colored background)
- Task title (large, bold)
- Category name
- Budget (formatted)
- Task image (if available, with signed URL)
- Full description
- Deadline (if set)
- Skills/tags (if any)
- Created date

Action Buttons (context-dependent):
IF user is OWNER:
  - "View Offers" button (tender only) → Navigate to Requests List Screen
  - "View Bookings" button (booking only) → Navigate to Bookings List Screen
  - "View Availability" button (booking only) → Navigate to Availability Screen

IF user is NOT OWNER:
  - "Submit Offer" button (tender only) → Show Submit Request Sheet
  - "Book Appointment" button (booking only) → Navigate to Availability Screen
  - "Start Chat" button → Navigate to Chat Screen (task-linked conversation)
```

**User Actions:**
- **As Task Owner (Tender):**
  * Tap "View Offers" → Navigate to Requests List Screen
  * Review and accept/reject offers

- **As Task Owner (Booking):**
  * Tap "View Bookings" → Navigate to Bookings List Screen
  * Tap "View Availability" → Navigate to Availability Screen
  * Manage slots and bookings

- **As Freelancer (Tender):**
  * Tap "Submit Offer" → Show Submit Request Sheet modal
  * Fill offer details → Submit

- **As Client (Booking):**
  * Tap "Book Appointment" → Navigate to Availability Screen
  * View available slots → Book slot

- **Anyone:**
  * Tap "Start Chat" → Navigate to Chat Screen (1:1)
  * Scroll to view full details

**Important UI Notes:**
- Conditional rendering based on task type (tender/booking)
- Conditional rendering based on ownership
- Uses SignedImage for private task images
- Card styling differs by task type (color-coded)
- Non-owners cannot edit or delete

**Design Recommendations:**
- Add image gallery for multiple images
- Add share task functionality
- Add report/flag option
- Add related tasks section
- Add freelancer profile preview in offers
- Add breadcrumb navigation
- Add save/bookmark icon in header
- Improve action button hierarchy
- Add FAQ/questions section
- Add attachment downloads
- Show task status more prominently
- Add edit/delete buttons for owners

---

### 8. **Chat Screen** (1:1 Conversation)
**File**: `lib/features/chat/view/chat_screen.dart`

**When User Sees It:**
- Tapping a conversation from Messages Screen
- "Start Chat" from Task Details Screen
- "Start Chat" from user profile

**What It Displays:**
```
AppBar:
- Other user name
- Back button
- Task title (if task-linked, small subtitle)

Body (Message List - Scrollable):
- Message bubbles (MessageBubble component):
  * Sender messages (right-aligned, primary color)
  * Receiver messages (left-aligned, gray)
  * Message content text
  * Attachment preview (image/file)
  * Timestamp (formatted)
  * Message type indicator (offer, delivery, etc.)
  * Read receipts (future: delivered/seen ticks)

Message Composer (Bottom):
- Text input field
- Attachment button (camera/file picker)
- Send button
- Typing indicator (future)
```

**User Actions:**
- Type message → Tap send button → Send text message
- Tap attachment button → Pick image/file → Send with message
- Tap message bubble → View full image (if image)
- Scroll up → Load older messages
- Real-time receive messages via Supabase Realtime

**Important UI Notes:**
- Realtime subscriptions for instant messaging
- Attachments stored in private `chat-attachments` bucket (signed URLs)
- Message types support offer workflows (offer, offer_accepted, etc.)
- WhatsApp-style UI with bubbles
- Auto-scroll to bottom on new message

**Design Recommendations:**
- Add image/file preview before sending
- Add voice message support
- Add emoji picker
- Add reply/quote functionality
- Add message reactions
- Add message edit/delete (with time limit)
- Add copy message text
- Add file download progress
- Add typing indicators
- Add online/last seen status
- Add message search
- Improve attachment UI (multiple attachments, galleries)
- Add message status (sending, sent, delivered, read)
- Add link previews
- Add location sharing

---

### 9. **Requests List Screen** (Offers/Bids)
**File**: `lib/features/tasks/view/widgets/requests/requests_list_screen.dart`

**When User Sees It:**
- Task owner taps "View Offers" from Task Details (tender tasks only)
- Viewing all offers/bids on a specific task

**What It Displays:**
```
AppBar:
- Title: "Offers for [Task Title]"
- Back button

Body (Scrollable List):
- Request tiles (RequestTile component):
  * Bidder avatar + name
  * Offer price (formatted)
  * Delivery days
  * Note/message
  * Status badge (pending/accepted/rejected)
  * Created date
  * Action buttons:
    - "Accept" button (green)
    - "Reject" button (red)
    - "Chat" button → Navigate to Chat Screen

Empty State:
- "No offers yet" message
- Info about tender tasks

Guard State:
- If task is not tender type → Show info message
```

**User Actions:**
- **As Task Owner:**
  * Tap "Accept" → Confirm → Accept offer → Auto-assign freelancer → Update task status
  * Tap "Reject" → Confirm → Reject offer
  * Tap "Chat" → Navigate to Chat Screen with bidder

- **As Bidder:**
  * View own offer status
  * Edit pending offer (future feature)

**Important UI Notes:**
- Only task owner can see offers (RLS enforced)
- Accepting offer triggers auto-assignment (database trigger)
- One pending offer per bidder (enforced by unique constraint)
- Guards against viewing offers on booking tasks

**Design Recommendations:**
- Add sorting (price, days, date)
- Add filtering (pending, accepted, rejected)
- Add bidder rating/reviews
- Add offer comparison view (side-by-side)
- Add negotiation/counter-offer feature
- Add bidder portfolio preview
- Add offer analytics (average, lowest, highest)
- Improve action button styling
- Add bulk actions (select multiple)
- Add offer expiration dates
- Show offer rank/position
- Add recommendation badges (best value, fastest, etc.)

---

### 10. **Submit Request Sheet** (Make Offer Modal)
**File**: `lib/features/tasks/view/widgets/requests/submit_request_sheet.dart`

**When User Sees It:**
- Freelancer taps "Submit Offer" from Task Details Screen (tender tasks only)
- Modal bottom sheet slides up

**What It Displays:**
```
Sheet Header:
- Title: "Submit Offer"
- Close button (X)

Form Fields:
- Price input (required, numeric)
- Delivery days input (required, numeric)
- Note/message textarea (optional)
- Submit button
- Cancel button

Validation:
- Price must be positive
- Days must be positive
- Shows error messages
```

**User Actions:**
- Enter offer price
- Enter delivery timeframe (days)
- Add optional note explaining offer
- Tap "Submit" → Validate → Create offer → Close sheet → Show success message
- Tap "Cancel" or "X" → Close sheet without submitting

**Important UI Notes:**
- Modal bottom sheet (dismissible)
- Unique constraint prevents duplicate pending offers
- Validation enforced at database level (trigger)
- Only available for tender tasks
- Requires authenticated session

**Design Recommendations:**
- Add price suggestion based on task budget
- Add timeline calendar picker instead of days number
- Show similar offer prices for reference
- Add offer template messages
- Add milestone breakdown option
- Show your previous offers on similar tasks
- Add calculation helper (hourly rate × hours = price)
- Improve validation feedback
- Add character limit indicator for note
- Add draft save

---

### 11. **Saved Tasks Screen**
**File**: `lib/features/saved/view/saved_tasks_screen.dart`

**When User Sees It:**
- Tapping bookmark icon from Home Screen AppBar
- User's bookmarked/saved tasks collection

**What It Displays:**
```
AppBar:
- Title: "Saved Tasks"
- Back button

Body (Scrollable List):
- Saved task cards (SavedTaskTile component):
  * Task title
  * Category
  * Budget
  * Task type badge
  * Unsave button (bookmark filled icon)
  * Task details

Empty State:
- "No saved tasks" message
- "Browse tasks to save them" suggestion

Loading State:
- Circular progress indicator
```

**User Actions:**
- Tap task card → Navigate to Task Details Screen
- Tap unsave button → Remove from saved → Refresh list
- Pull-to-refresh → Reload saved tasks

**Important UI Notes:**
- Shows only current user's saved tasks (RLS enforced)
- Optimistic UI updates (immediate icon toggle)
- Unique constraint per (user, task) pair
- Duplicate save shows friendly error

**Design Recommendations:**
- Add search saved tasks
- Add category filtering
- Add sorting options
- Add bulk actions (select multiple to unsave)
- Add collections/folders for organization
- Add notes on saved tasks
- Add save date/timestamp display
- Improve empty state with illustration
- Add export saved tasks list
- Add share saved collection

---

### 12. **Favorites Screen**
**File**: `lib/features/favorites/view/favorites_screen.dart`

**When User Sees It:**
- Tapping heart icon from Profile Screen AppBar
- User's favorited freelancers list
- Enables DM creation with freelancers

**What It Displays:**
```
AppBar:
- Title: "Favorites"
- Back button

Body (Scrollable Grid/List):
- Favorite cards (FavoriteCard component):
  * Freelancer avatar
  * Freelancer name
  * Role badge
  * Remove from favorites button (heart filled)
  * Start chat button (message icon)

Empty State:
- "No favorites yet"
- "Add freelancers to favorites to start DMs"

Loading State:
- Circular progress indicator
```

**User Actions:**
- Tap card → Navigate to Freelancer Profile (future)
- Tap heart icon → Remove from favorites → Confirm → Refresh list
- Tap message icon → Start DM conversation → Navigate to Chat Screen
- Pull-to-refresh → Reload favorites

**Important UI Notes:**
- Client-only feature (clients favorite freelancers)
- Enables DM creation (enforced by conversation guard trigger)
- Unique constraint per (client, freelancer) pair
- RLS enforced (clients see only their favorites)

**Design Recommendations:**
- Add search favorites
- Add category/skill filtering
- Add notes on favorites
- Add rating/review display
- Add sort by (recent, name, rating)
- Add bulk actions (select multiple)
- Add favorite collections/tags
- Improve card layout with more info
- Add freelancer portfolio preview
- Add availability status
- Show recent work/tasks

---

### 13. **Availability Screen** (Provider Slots)
**File**: `lib/features/booking/view/availability_screen.dart`

**When User Sees It:**
- Task owner (provider) managing availability slots
- Client viewing provider availability to book
- Booking-type tasks only

**What It Displays:**
```
AppBar:
- Title: "Availability"
- Back button
- Add Slot button (+) (provider only)

Body:
- Calendar/grid view of slots
- Slot tiles showing:
  * Start time (local timezone)
  * End time (local timezone)
  * Status (open/blocked)
  * Book button (client view)
  * Delete button (provider view)

Empty State:
- "No available slots" (client view)
- "Add your first slot" (provider view)

Loading State:
- Progress indicator
```

**User Actions:**
- **As Provider:**
  * Tap "+" → Show Add Slot Sheet modal
  * Select date/time → Create slot
  * Tap delete icon → Confirm → Delete slot

- **As Client:**
  * View available slots
  * Tap "Book" → Show Booking Sheet modal
  * Fill booking details → Submit booking

**Important UI Notes:**
- UTC ↔ Local timezone conversion (CRITICAL)
- Overlap prevention enforced by trigger
- RLS: Provider creates/manages, clients view/book
- Only open (non-blocked) slots shown to clients

**Design Recommendations:**
- Add calendar view (monthly/weekly)
- Add recurring slot templates
- Add bulk slot creation
- Add slot duration quick selects (30min, 1hr, 2hr)
- Add timezone display/selection
- Improve empty state with instructions
- Add slot filtering (date range, duration)
- Add availability sync with external calendars
- Show booked slots differently
- Add drag-to-create slots
- Add copy slots to another date

---

### 14. **Bookings List Screen**
**File**: `lib/features/booking/view/bookings_list_screen.dart`

**When User Sees It:**
- Provider/client viewing their bookings
- Bookings management screen

**What It Displays:**
```
AppBar:
- Title: "Bookings"
- Back button

Tabs (Status Filter):
- All
- Pending
- Confirmed
- Completed
- Canceled

Body (Scrollable List):
- Booking cards showing:
  * Client name (provider view) / Provider name (client view)
  * Task title
  * Slot time (local timezone)
  * Booking status badge
  * Note
  * Action buttons:
    - Confirm (provider, if pending)
    - Complete (provider, if confirmed)
    - Cancel (both, if pending/confirmed)

Empty State:
- "No bookings" message per tab

Loading State:
- Progress indicator
```

**User Actions:**
- **As Provider:**
  * Tap "Confirm" → Confirm booking → Update status → Notify client
  * Tap "Complete" → Mark complete → Update status
  * Tap "Cancel" → Confirm → Cancel booking

- **As Client:**
  * View booking status
  * Tap "Cancel" → Confirm → Cancel booking

- **Both:**
  * Filter by status tabs
  * Pull-to-refresh

**Important UI Notes:**
- Status transitions enforced by trigger guard
- RLS: Provider and client see only their bookings
- One active booking per slot (unique constraint)
- Pagination with time-based cursors

**Design Recommendations:**
- Add calendar view integration
- Add upcoming bookings widget
- Add booking reminders/notifications
- Add reschedule functionality
- Add booking notes/instructions
- Add payment status (future)
- Add booking history timeline
- Improve status badges with colors/icons
- Add export bookings (PDF, calendar)
- Add rating/review after completion
- Add refund/dispute options
- Show duration in bookings

---

### 15. **Portfolio Screen**
**File**: `lib/features/portfolio/view/portfolio_screen.dart`

**When User Sees It:**
- Profile Screen → Portfolio Tab
- Viewing user's portfolio items
- Freelancer work gallery

**What It Displays:**
```
AppBar (when standalone):
- Title: "Portfolio"
- Add Item button (+)
- Back button

Body (Scrollable Grid):
- Portfolio tiles (PortfolioTile component):
  * Portfolio image
  * Title
  * Description (truncated)
  * Edit button (owner only)
  * Delete button (owner only)

Empty State:
- "No portfolio items yet"
- "Add your work" message

Loading State:
- Progress indicator
```

**User Actions:**
- **As Owner:**
  * Tap "+" → Show Add Portfolio Sheet
  * Upload image + enter details → Create item
  * Tap item → Show Portfolio Details Sheet (full view)
  * Tap "Edit" → Show Edit Portfolio Sheet
  * Tap "Delete" → Confirm → Delete item

- **As Viewer:**
  * View portfolio items
  * Tap item → View full details

**Important UI Notes:**
- RLS: Owner can CRUD, others can view
- Images stored in `portfolio` bucket
- Currently uses public storage (can switch to private + signed URLs)
- Grid layout (2 columns)

**Design Recommendations:**
- Add category/tag filtering
- Add sorting (recent, popular, likes)
- Add portfolio collections
- Add video support
- Add external link support (Behance, Dribbble, GitHub)
- Add portfolio statistics (views, likes)
- Add social sharing
- Improve image gallery with lightbox
- Add project details (client, date, tech stack)
- Add before/after showcase
- Add testimonials per project
- Make featured/highlight items

---

### 16. **Categories Screen**
**File**: `lib/features/categories/view/categories_screen.dart`

**When User Sees It:**
- Browse all service categories
- Category selection screens
- Admin category management (future)

**What It Displays:**
```
AppBar:
- Title: "Categories"
- Back button

Body (Scrollable List):
- Category tiles:
  * Category icon (if available)
  * Category name
  * Task count (optional)
  * Arrow/chevron icon

Loading State:
- Progress indicator
```

**User Actions:**
- Tap category → Filter tasks by category → Navigate to Home/Tasks Screen with filter
- Admin: Add/edit/delete categories (future, service role only)

**Important UI Notes:**
- Read-only for regular users (RLS enforced)
- Database-first approach (seeded categories)
- Case-insensitive unique names
- Cached for performance

**Design Recommendations:**
- Add category icons
- Add grid view option
- Add category descriptions
- Add popular/trending indicator
- Add category search
- Add subcategories
- Show task count per category
- Add category images/covers
- Improve empty state
- Add category sorting

---

## 📝 MODAL SHEETS & DIALOGS

### 17. **Add Slot Sheet**
**File**: `lib/features/booking/view/add_slot_sheet.dart`

**Type**: Modal Bottom Sheet
**Trigger**: Provider taps "+" on Availability Screen

**Contents:**
- Start date/time picker
- End date/time picker
- "Add Slot" button
- Cancel button

**Actions:**
- Select date/time range
- Submit → Create slot → Close sheet → Refresh availability

**Notes:**
- Local → UTC conversion before save
- Overlap validation by trigger
- Duration must be positive

---

### 18. **Booking Sheet**
**File**: `lib/features/booking/view/booking_sheet.dart`

**Type**: Modal Bottom Sheet
**Trigger**: Client taps "Book" on available slot

**Contents:**
- Slot details (date, time, duration)
- Task dropdown selector
- Note textarea
- "Book" button
- Cancel button

**Actions:**
- Select task for booking
- Add booking note
- Submit → Create booking → Close sheet → Navigate to Bookings List

**Notes:**
- One active booking per slot (enforced)
- Client-only action
- Status starts as "pending"

---

### 19. **Add Portfolio Sheet**
**File**: `lib/features/portfolio/view/sheets/add_portfolio_sheet.dart`

**Type**: Modal Bottom Sheet
**Trigger**: Tap "+" on Portfolio Screen

**Contents:**
- Image picker button
- Image preview
- Title text field
- Description textarea
- "Add" button
- Cancel button

**Actions:**
- Pick image from gallery/camera
- Enter title and description
- Submit → Upload image → Create portfolio item → Close sheet

---

### 20. **Edit Portfolio Sheet**
**File**: `lib/features/portfolio/view/sheets/edit_portfolio_sheet.dart`

**Type**: Modal Bottom Sheet
**Trigger**: Tap "Edit" on portfolio tile

**Contents:**
- Current image preview
- Change image button
- Title text field (pre-filled)
- Description textarea (pre-filled)
- "Update" button
- Cancel button

**Actions:**
- Optionally change image
- Edit title/description
- Submit → Update portfolio item → Close sheet

---

### 21. **Portfolio Details Sheet**
**File**: `lib/features/portfolio/view/sheets/portfolio_details_sheet.dart`

**Type**: Modal Bottom Sheet
**Trigger**: Tap portfolio item

**Contents:**
- Full-size image
- Title (large)
- Full description
- Created date
- Close button

**Actions:**
- View full details
- Swipe down to dismiss
- Tap outside to close

---

### 22. **Confirm Delete Dialog** (Multiple uses)
**Type**: Alert Dialog
**Trigger**: Deleting tasks, portfolio items, bookings, etc.

**Contents:**
- Warning title ("Delete [Item]?")
- Confirmation message
- "Cancel" button
- "Delete" button (red/danger)

**Actions:**
- Confirm → Perform delete action → Close dialog
- Cancel → Close dialog without action

---

### 23. **Success SnackBar** (Multiple uses)
**Type**: SnackBar
**Trigger**: After successful actions (create task, update profile, etc.)

**Contents:**
- Success message text
- Check icon
- Auto-dismiss after 3 seconds

---

### 24. **Error SnackBar** (Multiple uses)
**Type**: SnackBar
**Trigger**: After failed actions or validation errors

**Contents:**
- Error message text
- Error icon
- Dismiss button
- Auto-dismiss after 5 seconds

---

### 25. **Loading Dialog** (Optional)
**Type**: Alert Dialog
**Trigger**: During long operations (image upload, etc.)

**Contents:**
- Circular progress indicator
- Loading message
- Non-dismissible

---

### 26. **Image Picker Dialog**
**Type**: Bottom Sheet / Dialog
**Trigger**: Tap image upload buttons

**Contents:**
- "Take Photo" option (camera)
- "Choose from Gallery" option
- Cancel button

**Actions:**
- Select source → Open camera/gallery → Pick image → Return to form

---

## 🧩 REUSABLE UI COMPONENTS

### 27. **TaskCard**
**File**: `lib/features/tasks/view/widgets/task_card.dart`

**Used In**: Home Screen, Profile Screen (My Tasks), Saved Tasks Screen

**Displays:**
- Task title
- Category badge
- Budget (formatted price)
- Task type indicator (Tender/Booking with colored background)
- Task image thumbnail (if available)
- User avatar + name
- Created date
- Bookmark icon (toggleable)

**Variations:**
- Tender style (light purple background, purple border)
- Booking style (light blue background, blue border)

**Actions:**
- Tap card → Navigate to Task Details
- Tap bookmark → Toggle save status

**Design Recommendations:**
- Add task status badge (open/assigned/closed)
- Add hover effects (web)
- Add long-press actions
- Add swipe actions
- Show deadline countdown
- Add offer count indicator (tender tasks)
- Add booking slot availability (booking tasks)

---

### 28. **MessageBubble**
**File**: `lib/features/chat/view/widgets/message_bubble.dart`

**Used In**: Chat Screen

**Displays:**
- Message content text
- Attachment preview (image/file)
- Timestamp
- Message type indicator
- Read receipts (future)
- Sender alignment (right) vs receiver (left)

**Variations:**
- Text message
- Image attachment
- File attachment
- Offer message (special formatting)
- System message (centered, gray)

**Design Recommendations:**
- Add message reactions
- Add reply preview
- Add forwarded indicator
- Add edited indicator
- Add link previews
- Improve timestamp formatting

---

### 29. **SignedAvatar**
**File**: `lib/core/widgets/signed_avatar.dart`

**Used In**: Profile Screen, Messages Screen, Chat Screen, All user displays

**Displays:**
- Circular avatar image with signed URL
- Placeholder icon if no image
- Loading indicator while generating signed URL

**Props:**
- Path (storage path, not URL)
- Radius
- Placeholder widget

**Notes:**
- Auto-generates signed URLs for private `avatars` bucket
- 1-hour TTL on signed URLs
- Caches signed URLs temporarily

---

### 30. **SignedImage**
**File**: `lib/core/widgets/signed_image.dart`

**Used In**: Task Details, Task Cards, Portfolio, Chat attachments

**Displays:**
- Image with signed URL (for private buckets)
- Loading placeholder
- Error placeholder
- Configurable fit, border radius, dimensions

**Props:**
- Storage path or URL
- Width, height
- Border radius
- Fit mode

**Notes:**
- Auto-handles signed URL generation
- Works with both paths and public URLs
- Error fallback

---

### 31. **CustomBottomNavBar**
**File**: `lib/core/widgets/custom_bottom_nav_bar.dart`

**Used In**: Main Navigation Screen (always visible)

**Displays:**
- 4 navigation tabs:
  1. Home (home icon)
  2. Messages (chat bubble icon)
  3. Create Task (add icon)
  4. Profile (person icon)
- Selected tab highlight
- Tab labels

**Actions:**
- Tap tab → Switch screen (IndexedStack)

**Design Recommendations:**
- Add badge indicators (unread messages count)
- Improve selected state visual
- Add haptic feedback
- Add custom animations
- Consider floating action button for Create Task

---

### 32. **ServiceCard**
**File**: `lib/features/home/view/widgets/service_card.dart`

**Used In**: Home Screen (optional service category cards)

**Displays:**
- Service category icon
- Service category name
- Tap to filter by category

**Actions:**
- Tap → Filter tasks by this category

---

### 33. **RequestTile**
**File**: `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart`

**Used In**: Requests List Screen

**Displays:**
- Bidder avatar + name
- Offer price (formatted)
- Delivery days
- Note preview
- Status badge (pending/accepted/rejected)
- Action buttons (Accept/Reject/Chat)

**Actions:**
- Accept/Reject offer
- Start chat with bidder

---

## 🎨 DESIGN SYSTEM NOTES

### **Current Theme** (Material Design 3)
- Primary Color: Theme-based (appears to be purple/blue)
- AppBar: Primary color background, white text
- Cards: White background with subtle shadows
- Borders: Conditional colors (tender = purple, booking = blue)

### **Typography**
- Uses default Material Design 3 text theme
- TextFormField with OutlineInputBorder
- Bold for titles, normal for body text

### **Spacing**
- Standard padding: 16.0
- Card padding: 20.0
- Vertical spacing: 8, 12, 16, 24

### **Widgets Used**
- Scaffold, AppBar, BottomNavigationBar
- ListView, GridView
- Card, Container
- TextFormField, ElevatedButton
- CircularProgressIndicator
- SnackBar, AlertDialog
- BottomSheet, ModalBottomSheet
- TabBar, TabBarView
- Consumer (Provider pattern)

---

## 🚀 DESIGN RECOMMENDATIONS SUMMARY

### **High Priority:**
1. Add skeleton loaders (replace circular progress indicators)
2. Improve empty states with illustrations/animations
3. Add image galleries with swipe/zoom
4. Add pull-to-refresh consistently across all list screens
5. Standardize action button styles (primary/secondary/danger)
6. Add haptic feedback for interactions
7. Improve form validation UX with inline errors
8. Add success/error animations
9. Add loading states for buttons (spinner inside button)
10. Improve avatar/image loading states

### **Medium Priority:**
1. Add dark mode support
2. Add accessibility labels (screen readers)
3. Add onboarding/tutorial flows
4. Add app-wide search functionality
5. Add notification center
6. Add in-app help/tooltips
7. Add settings screen (separated from profile)
8. Add multi-language support UI
9. Add analytics event tracking
10. Add feature flags for gradual rollouts

### **Low Priority (Nice to Have):**
1. Add animations between screens
2. Add micro-interactions
3. Add custom illustrations
4. Add 3D touch/long press menus
5. Add widget home screen support
6. Add Apple Watch/Android Wear support
7. Add voice input
8. Add AR features (portfolio showcase)
9. Add AI assistant chat

---

## 📊 SCREEN STATISTICS

- **Total Main Screens**: 16
- **Total Modal Sheets**: 10
- **Total Reusable Components**: 7
- **Total Unique User Flows**: 12+
- **Total Interactive Elements**: 100+
- **Navigation Depth**: Maximum 3 levels

---

## 🎯 FIGMA REDESIGN WORKFLOW

### **Recommended Approach:**

1. **Phase 1: Foundation** (Week 1)
   - Set up design system (colors, typography, spacing)
   - Design reusable components (buttons, inputs, cards)
   - Create icon set
   - Design navigation patterns

2. **Phase 2: Core Screens** (Week 2-3)
   - Authentication flow (Login, Signup)
   - Main navigation (Home, Messages, Create Task, Profile)
   - Task Details screen

3. **Phase 3: Secondary Screens** (Week 3-4)
   - Chat screen
   - Profile tabs (Info, My Tasks, Portfolio)
   - Favorites, Saved Tasks
   - Requests List, Bookings

4. **Phase 4: Modals & Sheets** (Week 4)
   - All bottom sheets
   - Dialogs
   - Loading/error states

5. **Phase 5: Polish** (Week 5)
   - Animations
   - Micro-interactions
   - Empty states
   - Error states
   - Dark mode variants

### **Deliverables per Screen:**
- Desktop view (1920x1080)
- Mobile view (375x812 iPhone, 360x800 Android)
- Tablet view (768x1024)
- Component variants (default, hover, pressed, disabled)
- Loading states
- Error states
- Empty states
- Prototype with interactions

---

## 📝 NOTES FOR YOUR DESIGN AGENT

1. **Authentication is required** for all screens except Login/Signup
2. **Bottom navigation is persistent** across Home/Messages/CreateTask/Profile
3. **Real-time updates** happen on Messages and Chat screens (design for live updates)
4. **Image handling** is critical - private storage with signed URLs (design for loading states)
5. **Task types** (Tender vs Booking) have different UI flows - design variations
6. **Forms** are extensive - focus on excellent form UX with validation
7. **Empty states** are everywhere - make them engaging and helpful
8. **Mobile-first** but also consider tablet/desktop responsive layouts
9. **Accessibility** is important - ensure sufficient contrast, touch targets 44x44pt minimum
10. **Performance** - design for perceived performance (skeleton loaders, optimistic updates)

---

**End of UI Inventory**

**Next Steps:**
1. Review this inventory with your design team
2. Prioritize screens for redesign
3. Set up Figma project with this structure
4. Start with design system and reusable components
5. Iterate on user flows
6. Create prototypes for user testing

**Good luck with your redesign! 🎨✨**
