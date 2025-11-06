# 🎨 SLine - Screens Quick Reference

**Total Screens**: 33 (16 main + 10 modals + 7 components)

---

## 📱 MAIN SCREENS (16)

| # | Screen Name | File | Category |
|---|------------|------|----------|
| 1 | Login Screen | `lib/features/auth/view/login_screen.dart` | Auth |
| 2 | Signup Screen | `lib/features/auth/view/signup_screen.dart` | Auth |
| 3 | Home Screen | `lib/features/home/view/home_screen.dart` | Main Nav (Tab 1) |
| 4 | Messages Screen | `lib/features/chat/view/messages_screen.dart` | Main Nav (Tab 2) |
| 5 | Create Task Screen | `lib/features/tasks/view/create_task_screen.dart` | Main Nav (Tab 3) |
| 6 | Profile Screen | `lib/features/profile/view/profile_screen.dart` | Main Nav (Tab 4) |
| 7 | Task Details Screen | `lib/features/tasks/view/task_details_screen.dart` | Secondary |
| 8 | Chat Screen | `lib/features/chat/view/chat_screen.dart` | Secondary |
| 9 | Requests List Screen | `lib/features/tasks/view/widgets/requests/requests_list_screen.dart` | Secondary |
| 10 | Saved Tasks Screen | `lib/features/saved/view/saved_tasks_screen.dart` | Secondary |
| 11 | Favorites Screen | `lib/features/favorites/view/favorites_screen.dart` | Secondary |
| 12 | Availability Screen | `lib/features/booking/view/availability_screen.dart` | Secondary |
| 13 | Bookings List Screen | `lib/features/booking/view/bookings_list_screen.dart` | Secondary |
| 14 | Portfolio Screen | `lib/features/portfolio/view/portfolio_screen.dart` | Secondary |
| 15 | Categories Screen | `lib/features/categories/view/categories_screen.dart` | Secondary |
| 16 | Main Navigation | `lib/app/main_navigation_screen.dart` | Container |

---

## 📝 MODAL SHEETS (10)

| # | Sheet Name | File | Trigger |
|---|-----------|------|---------|
| 17 | Submit Request Sheet | `lib/features/tasks/view/widgets/requests/submit_request_sheet.dart` | "Submit Offer" button |
| 18 | Add Slot Sheet | `lib/features/booking/view/add_slot_sheet.dart` | "+" on Availability |
| 19 | Booking Sheet | `lib/features/booking/view/booking_sheet.dart` | "Book" on slot |
| 20 | Add Portfolio Sheet | `lib/features/portfolio/view/sheets/add_portfolio_sheet.dart` | "+" on Portfolio |
| 21 | Edit Portfolio Sheet | `lib/features/portfolio/view/sheets/edit_portfolio_sheet.dart` | "Edit" on portfolio item |
| 22 | Portfolio Details Sheet | `lib/features/portfolio/view/sheets/portfolio_details_sheet.dart` | Tap portfolio item |
| 23 | Confirm Delete Dialog | (Multiple files) | Delete actions |
| 24 | Success SnackBar | (Multiple files) | Successful operations |
| 25 | Error SnackBar | (Multiple files) | Failed operations |
| 26 | Image Picker Dialog | (Multiple files) | Image upload triggers |

---

## 🧩 REUSABLE COMPONENTS (7)

| # | Component Name | File | Used In |
|---|---------------|------|---------|
| 27 | TaskCard | `lib/features/tasks/view/widgets/task_card.dart` | Home, Profile, Saved Tasks |
| 28 | MessageBubble | `lib/features/chat/view/widgets/message_bubble.dart` | Chat Screen |
| 29 | SignedAvatar | `lib/core/widgets/signed_avatar.dart` | All user displays |
| 30 | SignedImage | `lib/core/widgets/signed_image.dart` | Task images, Portfolio |
| 31 | CustomBottomNavBar | `lib/core/widgets/custom_bottom_nav_bar.dart` | Main Navigation |
| 32 | ServiceCard | `lib/features/home/view/widgets/service_card.dart` | Home Screen |
| 33 | RequestTile | `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart` | Requests List |

---

## 🗺️ USER FLOWS

### **Authentication Flow**
```
Login Screen → Main Navigation (4 tabs)
            ↑
            └─ Signup Screen
```

### **Main Navigation Flow** (4 tabs always visible)
```
Main Navigation
├─ Tab 1: Home Screen
├─ Tab 2: Messages Screen
├─ Tab 3: Create Task Screen
└─ Tab 4: Profile Screen (3 internal tabs)
```

### **Task Creation Flow**
```
Home/Profile → Create Task → (Upload Images) → Submit → Task Details
```

### **Offer/Request Flow** (Tender Tasks)
```
Task Details → Submit Offer Sheet → Requests List (owner) → Accept → Task Assigned
```

### **Booking Flow** (Booking Tasks)
```
Task Details → Availability Screen → Book Slot → Booking Sheet → Bookings List
```

### **Chat Flow**
```
Messages Screen → Chat Screen (1:1)
               ↑
Task Details ──┘ (Start task-linked chat)
               ↑
Favorites ─────┘ (Start DM)
```

### **Profile Management Flow**
```
Profile Screen
├─ Tab 1: Edit Profile Info
├─ Tab 2: My Tasks (Edit/Delete)
└─ Tab 3: Portfolio (Add/Edit/Delete)
```

---

## 🎨 DESIGN PRIORITY

### **Phase 1: Authentication & Navigation** (Week 1)
- Login Screen
- Signup Screen
- Main Navigation (Bottom Nav Bar)
- CustomBottomNavBar component

### **Phase 2: Core Task Flow** (Week 2)
- Home Screen
- Task Details Screen
- Create Task Screen
- TaskCard component

### **Phase 3: Communication** (Week 3)
- Messages Screen
- Chat Screen
- MessageBubble component

### **Phase 4: Profile & Portfolio** (Week 3)
- Profile Screen (3 tabs)
- Portfolio Screen
- Favorites Screen
- Saved Tasks Screen

### **Phase 5: Booking System** (Week 4)
- Availability Screen
- Bookings List Screen
- Add Slot Sheet
- Booking Sheet

### **Phase 6: Offers System** (Week 4)
- Requests List Screen
- Submit Request Sheet
- RequestTile component

### **Phase 7: Supporting Screens** (Week 5)
- Categories Screen
- All remaining modal sheets
- Empty states
- Loading states
- Error states

---

## 📊 COMPLEXITY RATING

| Screen | Complexity | Estimated Design Time |
|--------|-----------|----------------------|
| Login/Signup | Low | 2-4 hours |
| Home Screen | High | 8-12 hours |
| Messages Screen | Medium | 4-6 hours |
| Chat Screen | High | 10-14 hours |
| Create Task | High | 8-10 hours |
| Task Details | High | 8-10 hours |
| Profile Screen | High | 10-12 hours |
| Portfolio Screen | Medium | 6-8 hours |
| Availability Screen | High | 8-10 hours |
| Bookings List | Medium | 6-8 hours |
| Requests List | Medium | 4-6 hours |
| Others | Low-Medium | 2-6 hours each |

**Total Estimated Time**: 80-120 hours of design work

---

## 🎯 KEY DESIGN CONSIDERATIONS

### **Critical Features to Highlight:**
1. **Dual Task Types** (Tender vs Booking) - Need visual differentiation
2. **Real-time Chat** - Design for instant message updates
3. **Image Handling** - Private storage with signed URLs (loading states critical)
4. **Form-Heavy** - Many input screens need excellent UX
5. **Empty States** - Every list/screen needs engaging empty states

### **Accessibility Requirements:**
- Minimum touch target: 44x44pt
- Color contrast ratio: WCAG AA minimum (4.5:1)
- Screen reader support (semantic labels)
- Keyboard navigation (web/desktop)

### **Responsive Design:**
- Mobile-first (375x812 iPhone base)
- Tablet support (768x1024 iPad)
- Desktop support (1920x1080 web)

### **Performance:**
- Skeleton loaders for all lists
- Optimistic UI updates where possible
- Progressive image loading
- Lazy loading for long lists

---

## 📝 QUICK NOTES

- **Bottom navigation is always visible** on main 4 screens
- **All screens require authentication** except Login/Signup
- **Material Design 3** is current framework
- **Provider pattern** used for state management
- **Supabase backend** handles all data
- **Private storage** buckets use signed URLs (1-hour TTL)
- **UTC timestamps** converted to local for display
- **RLS enforced** at database level (session-based access)

---

For full details on each screen, see: **UI_INVENTORY_FOR_FIGMA_REDESIGN.md**


 ---
  🎯 SLine - Freelance Marketplace App Description

  What is SLine?

  SLine is a cross-platform freelance marketplace mobile application that connects clients (people who need services) with freelancers (service providers). Think of it as a combination of Fiverr + Upwork + Task Rabbit with built-in real-time chat and appointment booking.

  ---
  🎭 Two User Types

  1. Clients (Buyers)

  People who need work done:
  - Post tasks/jobs they need completed
  - Browse freelancer services
  - Receive and review offers from freelancers
  - Book appointments with service providers
  - Save favorite freelancers
  - Chat with freelancers about projects

  2. Freelancers (Service Providers)

  People who offer services:
  - Browse available tasks/jobs
  - Submit offers/bids on projects
  - Showcase their work in a portfolio
  - Set availability for bookings
  - Chat with potential clients
  - Build their reputation

  Note: Users can switch roles anytime via their profile settings!

  ---
  🎯 Core Value Proposition

  For Clients:
  "Find skilled freelancers, get offers, chat directly, and book services - all in one app"

  For Freelancers:
  "Discover opportunities, showcase your work, submit offers, and manage bookings easily"

  ---
  🔑 Two Types of Tasks (This is CRITICAL!)

  Type 1: TENDER Tasks (Bidding/Offer-based) 🎨

  Example: "Design a logo for my company - Budget: $500"

  How it works:
  1. Client posts a task with description and budget
  2. Multiple freelancers submit offers (price + delivery time)
  3. Client reviews all offers
  4. Client accepts one offer
  5. Freelancer gets assigned to the task
  6. They communicate via chat
  7. Work gets delivered

  Think: Traditional bidding like Upwork/Freelancer

  Visual Identifier: Purple/violet color scheme

  ---
  Type 2: BOOKING Tasks (Appointment-based) 📅

  Example: "I offer house cleaning services - $50/hour"

  How it works:
  1. Freelancer posts their service with pricing
  2. Freelancer sets availability slots (date + time)
  3. Clients browse available slots
  4. Client books a specific time slot
  5. Booking goes to provider for confirmation
  6. Service happens at scheduled time

  Think: Appointment booking like CalendlyTaskRabbit

  Visual Identifier: Blue color scheme

  ---
  💬 Chat System (WhatsApp-style)

  Two Types of Conversations:

  1. Task-Linked Chats (Project discussions)
  - Tied to a specific task
  - Between task owner and interested freelancer
  - Can be started by clicking "Start Chat" on task details
  - Shows task title in chat header

  2. Direct Messages (DMs) (General conversations)
  - One-on-one private chat
  - Requires the freelancer to be in client's "Favorites" list
  - For general inquiries, networking, or repeat business

  Chat Features:

  - Real-time messaging (instant delivery)
  - Image and file attachments
  - Message timestamps
  - Read receipts (delivered/seen) - coming soon
  - Special message types for offers, delivery confirmations, etc.

  ---
  🏗️ App Structure

  Main Navigation (4 tabs always visible at bottom)

  ┌─────────────────────────────────────┐
  │        📱 SLine App                 │
  ├─────────────────────────────────────┤
  │                                     │
  │         [CURRENT SCREEN]            │
  │                                     │
  │                                     │
  ├─────────────────────────────────────┤
  │  🏠 Home │ 💬 Chat │ ➕ Post │ 👤 Me │
  └─────────────────────────────────────┘

  Tab 1 - 🏠 Home:
  - Browse all available tasks (tender and booking)
  - Search and filter by category
  - See task cards with images, budget, and type
  - Save tasks to favorites
  - Quick access to create new task

  Tab 2 - 💬 Messages:
  - List of all conversations
  - Both task-linked chats and DMs
  - Shows last message and timestamp
  - Real-time updates (new messages appear instantly)

  Tab 3 - ➕ Create Task:
  - Quick access to post a new task
  - Form to enter title, description, budget, deadline
  - Upload task images
  - Select category
  - Choose task type (Tender or Booking)

  Tab 4 - 👤 Profile:
  - 3 sub-tabs:
    a. Profile Info: Edit personal details, avatar, role, bio
    b. My Tasks: View/edit/delete your posted tasks
    c. Portfolio: Showcase your work (for freelancers)
  - Access to favorites list
  - Logout option

  ---
  🎨 Key Features in Detail

  1. Task Posting & Discovery

  - Rich task cards with images
  - Category-based filtering
  - Search functionality
  - Budget display
  - Task type indicators (color-coded)
  - User avatars and names
  - Save/bookmark tasks

  2. Offer System (Tender Tasks Only)

  - Freelancers submit offers with:
    - Proposed price
    - Delivery time (days)
    - Optional note/message
  - Clients see all offers in one list
  - One-click accept/reject
  - Auto-assignment when offer accepted
  - Chat button for each offer

  3. Booking System (Booking Tasks Only)

  - Providers set availability slots:
    - Date and time ranges
    - Duration
    - Prevents overlapping slots
  - Clients view calendar of available slots
  - One-click booking with optional note
  - Booking confirmation flow
  - Status tracking (pending → confirmed → completed)

  4. Portfolio System

  - Freelancers upload work samples:
    - Images
    - Title
    - Description
  - Grid gallery layout
  - Tap to view full details
  - Edit/delete for owners
  - Public viewing for everyone

  5. Favorites & Saved

  - Favorites: Save freelancers you like (enables DMs)
  - Saved Tasks: Bookmark interesting tasks to review later
  - Quick access from home screen
  - Toggle on/off with heart/bookmark icons

  6. Smart Image Handling

  - All images stored in private cloud storage
  - Secure signed URLs (temporary access)
  - Auto-compression before upload
  - Loading states while generating access
  - Support for multiple images per task

  ---
  🎯 User Journeys

  Journey 1: Client Posts Task & Receives Offers

  1. Client opens app → Home screen
  2. Taps "+" → Create Task screen
  3. Selects "Tender" type
  4. Fills in: Title, Description, Budget, Category
  5. Uploads reference images
  6. Taps "Create Task"
  7. Task appears on Home feed
  8. Freelancers discover task
  9. Multiple freelancers submit offers
  10. Client receives notifications
  11. Client goes to Task Details → "View Offers"
  12. Reviews all offers (price, time, freelancer profile)
  13. Taps "Accept" on best offer
  14. Freelancer gets auto-assigned
  15. Chat becomes available
  16. They discuss via chat
  17. Work gets delivered

  Journey 2: Client Books Appointment

  1. Client browses Home feed
  2. Sees Booking task: "House Cleaning - $50/hour"
  3. Taps task card → Task Details
  4. Taps "Book Appointment"
  5. Views provider's availability calendar
  6. Selects available slot (e.g., "Tomorrow 2:00 PM - 4:00 PM")
  7. Adds optional note
  8. Taps "Book"
  9. Booking created with "Pending" status
  10. Provider receives notification
  11. Provider confirms booking
  12. Booking status → "Confirmed"
  13. Service happens at scheduled time
  14. Provider marks as "Completed"

  Journey 3: Direct Message a Favorite Freelancer

  1. Client discovers talented freelancer from a task
  2. Taps heart icon → Adds to Favorites
  3. Goes to Profile tab → Taps heart icon → Favorites screen
  4. Sees list of favorite freelancers
  5. Taps message icon on freelancer card
  6. Opens chat screen
  7. Sends message: "Hi! Do you also do web design?"
  8. Real-time conversation begins
  9. Can lead to new task collaboration

  ---
  🎨 Visual Design Language

  Current Style:

  - Framework: Material Design 3 (Google's design system)
  - Colors:
    - Primary: Purple/Blue theme
    - Tender tasks: Purple accents
    - Booking tasks: Blue accents
    - Success: Green
    - Error: Red
  - Typography: Material Design 3 default (Roboto)
  - Cards: Rounded corners, subtle shadows
  - Spacing: 8pt grid system (8, 16, 24px spacing)

  What to KEEP in redesign:

  - Bottom navigation (4 tabs)
  - Card-based layout for tasks
  - Color differentiation for task types (Tender vs Booking)
  - Real-time chat bubbles (WhatsApp style)
  - Material Design principles (accessibility, clarity)

  What to IMPROVE:

  - More modern, polished look
  - Better empty states with illustrations
  - Skeleton loaders instead of spinners
  - More engaging animations
  - Better form UX with inline validation
  - Improved image galleries
  - Dark mode support
  - Custom icons instead of Material defaults

  ---
  🌟 Key Differentiators (vs competitors)

  1. Dual Task Types: Unique combination of bidding AND appointment booking
  2. Built-in Chat: No need for external communication
  3. Favorites System: Easy to maintain relationships with trusted freelancers
  4. Real-time Everything: Instant chat, instant updates
  5. Mobile-First: Designed for on-the-go usage
  6. Simple Flow: From discovery to completion in one app

  ---
  👥 Target Audience

  Clients:

  - Small business owners
  - Startups needing quick services
  - Individuals needing one-off tasks
  - People seeking appointment-based services
  - Age: 25-55
  - Tech-savvy, mobile-first users

  Freelancers:

  - Designers, developers, writers
  - Service providers (cleaners, tutors, consultants)
  - Side hustlers
  - Independent contractors
  - Age: 20-45
  - Portfolio-focused professionals

  ---
  📱 Technical Context (Important for Design)

  Platform:

  - Flutter framework (iOS, Android, Web, Desktop)
  - Cross-platform consistency required
  - Mobile-first design priority

  Backend:

  - Supabase (cloud database + auth + storage)
  - Real-time capabilities (live chat updates)
  - Secure private storage (images need loading states)

  Performance Considerations:

  - Images load from cloud (design loading placeholders)
  - Real-time updates (design for instant changes)
  - Forms submit to server (design loading/success/error states)
  - List scrolling (design for infinite scroll/pagination)

  ---
  🎯 Design Goals for Figma

  Must Have:

  1. Clean, modern, professional look
  2. Clear visual distinction between Tender (purple) and Booking (blue) tasks
  3. Excellent form UX (lots of input screens)
  4. Engaging empty states (every list needs one)
  5. Loading states for everything (images, lists, buttons)
  6. Mobile-first responsive design
  7. Accessibility compliance (contrast, touch targets)

  Nice to Have:

  1. Dark mode variants
  2. Custom illustrations
  3. Micro-animations
  4. Skeleton loaders
  5. Advanced interactions (swipe, drag, etc.)
  6. Tablet/desktop layouts
  7. Onboarding flow designs

  ---
  🚀 Design Deliverables Needed

  For each of the 33 screens:
  - Mobile view (375x812 iPhone base)
  - Tablet view (768x1024 iPad) - optional
  - Desktop view (1920x1080) - optional
  - Component variants (default, hover, pressed, disabled, loading, error)
  - Empty states
  - Loading states
  - Error states
  - Interactive prototype with navigation flows

  ---
  💡 Use Cases to Visualize

  Example 1: Graphic Designer needs a logo
  - Posts tender task: "Design modern logo - $300 budget"
  - Gets 5 offers ranging $150-$400
  - Reviews portfolios, selects best offer
  - Chats with designer about brand guidelines
  - Receives drafts via chat
  - Approves final version

  Example 2: Student needs tutoring
  - Finds booking task: "Math Tutoring - $40/hour"
  - Checks tutor's availability
  - Books Tuesday 4pm-6pm slot
  - Receives confirmation
  - Gets reminder before session
  - Meets for tutoring at scheduled time

  Example 3: Freelance writer discovers client
  - Browses Home feed
  - Sees "Blog Post Writing" task
  - Submits competitive offer
  - Gets accepted
  - Discusses requirements via chat
  - Delivers article through chat attachment
  - Builds relationship, gets added to favorites
  - Receives repeat work via DMs

  ---
  📊 App in Numbers

  - 16 main screens to design
  - 10 modal sheets (bottom sheets, dialogs)
  - 7 reusable components (cards, buttons, etc.)
  - 4 persistent tabs (bottom navigation)
  - 2 task types (different flows each)
  - 2 chat types (task-linked + DM)
  - 3 user states (loading, empty, error)
  - ∞ possibilities for making it beautiful! 🎨

  ---
  🎬 Final Context

  This is a real production app used by actual clients and freelancers. The redesign should:
  - Feel professional and trustworthy (money changes hands)
  - Be intuitive (minimal learning curve)
  - Look modern and fresh (compete with established apps)
  - Work flawlessly on mobile (primary platform)
  - Handle real-world complexity (chat, bookings, offers, images)
  - Support quick actions (post task, send message, book slot in < 1 min)

  Think: "Upwork meets Calendly meets WhatsApp" with a beautiful, cohesive design! 🚀✨