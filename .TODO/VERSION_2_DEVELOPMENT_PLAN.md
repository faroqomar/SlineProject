# SLine v2.0 Development Plan

**Created:** December 11, 2025
**Status:** Planning Phase
**Target:** Next Major Release

---

## 📊 Executive Summary

This document outlines all features, bug fixes, and improvements for SLine v2.0.
Tasks are organized in **dependency order** - complete each phase before moving to the next.

---

## ✅ PHASE 1: Critical Bug Fixes & Foundation — COMPLETE
*Completed December 14, 2025*

### 1.1 Task Card Image Display [BUG - HIGH PRIORITY] ✅ COMPLETE
- **Issue:** Task cards don't display images even when `image_paths` are provided
- **Location:** `lib/features/tasks/view/widgets/task_card.dart`
- **Current:** Header shows solid color only (lines 71-186)
- **Required:**
  - [x] Check if `task.imagePaths` exists and is not empty
  - [x] Use `SignedImage` widget to display first image in header
  - [x] Add fallback to colored header when no images
  - [x] Handle loading and error states for images
- **Files to modify:**
  - `lib/features/tasks/view/widgets/task_card.dart`
  - `lib/features/tasks/models/task_model.dart` (verify `imagePaths` parsing)
- **Reference:** New_Design shows image-based headers with gradient overlay

### 1.2 App Performance Optimization [BUG - HIGH PRIORITY] ✅ COMPLETE
- **Issue:** App is slow/laggy
- **Tasks:**
  - [x] Audit N+1 query patterns in services (JOINs vs loops)
  - [x] Implement lazy loading for lists (currently may load all at once)
  - [x] Add image caching with `CachedNetworkImage`
  - [x] Review ChangeNotifier rebuilds - use `Selector` where possible
  - [x] Profile with Flutter DevTools to find bottlenecks
  - [x] Implement pagination with cursors (not offsets) per project rules
  - [x] Review signed URL generation - may be regenerating too frequently
- **Files to audit:**
  - All ViewModels for unnecessary `notifyListeners()` calls
  - All Services for N+1 queries
  - Home screen load sequence

### 1.3 Supabase Connection Verification [AUDIT] ✅ COMPLETE
- **Issue:** Uncertain if all features properly connect to Supabase
- **Tasks:**
  - [x] Audit Create Task screen - verify all fields save to DB
  - [x] Audit Task Images upload - verify storage paths saved
  - [x] Verify RLS policies work correctly for all operations
  - [x] Check all error handling maps DB errors to user messages
  - [x] Test session expiry handling across features
- **Files to check:**
  - `lib/features/tasks/services/task_service.dart`
  - `lib/features/tasks/services/task_image_service.dart`
  - All service files for proper error handling

---

## 🟡 PHASE 2: Core Feature Fixes
*Fix existing features before adding new ones*

### 2.1 Differentiate Tender vs Booking Cards [UI/UX]
- **Issue:** Tender and Booking task cards look too similar
- **Current:** Both use same `TaskCard` widget with only badge difference
- **New Design Reference:**
  - `.TODO/New_Design/Tenders/TenderList.tsx` - Tender cards show author info, offers count
  - `.TODO/New_Design/Bookings/BookingList.tsx` - Booking cards show availability-focused info
- **Tasks:**
  - [ ] Create `TenderTaskCard` widget with:
    - Author avatar + name + verified badge
    - Time left (deadline countdown)
    - Red/coral color scheme
    - FileText icon badge
  - [ ] Create `BookingTaskCard` widget with:
    - Provider avatar + name
    - Availability slots indicator
    - Teal/green color scheme
    - Calendar icon badge
  - [ ] Update `TaskCard` to delegate to appropriate card type
  - [ ] Update Home/Tender/Booking screens to use correct cards

### 2.2 Orders Dashboard Overhaul [FEATURE FIX]
- **Issue:** Orders screen should work as dashboard for published tenders/bookings
- **Location:** `lib/features/orders/view/orders_dashboard_screen.dart`
- **Required functionality:**
  - [ ] View all my published tenders with status
  - [ ] View all my published bookings with status
  - [ ] See who made offers on my tenders
  - [ ] Edit published tasks (title, description, budget, etc.)
  - [ ] Delete/close published tasks
  - [ ] View offer details (freelancer info, bid amount, delivery time)
  - [ ] Accept/reject offers
  - [ ] Status tabs: Open, In Progress, Completed, Cancelled
- **UI Reference:** `.TODO/New_Design/Orders/OrdersScreen.tsx`
- **New files needed:**
  - `lib/features/orders/viewmodels/orders_view_model.dart`
  - `lib/features/orders/services/orders_service.dart`
  - `lib/features/orders/view/widgets/order_card.dart`
  - `lib/features/orders/view/widgets/offer_list_sheet.dart`

### 2.3 Chat System Overhaul [FEATURE FIX]
- **Issue:** Chat is messy and can't delete previous chats
- **Location:** `lib/features/chat/`
- **Current files:** 19 files in chat module
- **Tasks:**
  - [ ] Add delete conversation functionality
    - Service method to delete/archive conversation
    - UI swipe-to-delete or long-press menu
  - [ ] Fix message list ordering and realtime updates
  - [ ] Fix offer message display/accept/reject flow
  - [ ] Improve conversation list UI (per `MessagesList.tsx`)
  - [ ] Add unread message badges
  - [ ] Fix attachment sending/receiving
  - [ ] Add typing indicators (optional)
  - [ ] Clean up code structure - consolidate duplicates
- **Reference:** `.TODO/New_Design/Messages/` folder

### 2.4 Profile Screen Enhancement [FEATURE FIX]
- **Issue:** Profile doesn't show portfolio, edit profile not functional
- **Location:** `lib/features/profile/`
- **Tasks:**
  - [ ] Display portfolio grid on profile (link to Portfolio feature)
  - [ ] Make Edit Profile functional:
    - Edit full name
    - Edit bio
    - Change avatar
    - Change email
    - Update skills/tags
  - [ ] Add Settings section:
    - Dark mode toggle
    - Notification preferences
    - Language selection
    - Privacy settings
    - Account deletion
  - [ ] Display stats (jobs completed, rating, earnings)
  - [ ] Add badges display (Top Rated, Rising Talent, etc.)
- **Reference:** `.TODO/New_Design/Profile/ProfileView.tsx`

### 2.5 Saved Projects Feature [FEATURE FIX]
- **Issue:** Saved projects in profile doesn't work
- **Location:** `lib/features/saved/`
- **Tasks:**
  - [ ] Verify `SavedTasksService` properly saves/loads tasks
  - [ ] Connect Profile → Saved Tasks navigation
  - [ ] Add save/unsave toggle on task cards
  - [ ] Show saved count in profile
  - [ ] Test bookmark icon state persistence across screens
- **Already exists:** `lib/features/saved/` module is implemented but may not be wired

### 2.6 Forgot Password Flow [AUTH FIX]
- **Issue:** Forgot password doesn't work
- **Location:** `lib/features/auth/`
- **Tasks:**
  - [ ] Create `ForgotPasswordScreen` with email input
  - [ ] Implement `AuthService.resetPassword()` using Supabase
  - [ ] Add navigation from Login screen
  - [ ] Handle success/error states with user feedback
  - [ ] Add email sent confirmation screen
  - [ ] Handle deep link return from password reset email
- **Supabase method:** `supabase.auth.resetPasswordForEmail(email)`

---

## 🟢 PHASE 3: Design System Updates
*After features work, polish the design*

### 3.1 Liquid Glass Effect Implementation [UI OVERHAUL]
- **Note:** `liquid_glass.md` file needs to be created with design specs
- **Reference:** `.TODO/New_Design/Theme.ts` shows glassmorphism patterns
- **Tasks:**
  - [ ] Create liquid glass design specifications document
  - [ ] Update `AppDecorations` with glass effect presets
  - [ ] Apply glassmorphism consistently:
    - Cards (all task cards, chat cards, profile cards)
    - Modals and bottom sheets
    - Navigation elements
    - Headers
    - Input fields
  - [ ] Update `backdrop-blur` values across components
  - [ ] Add subtle animations for glass effects
  - [ ] Ensure dark/light mode consistency

### 3.2 New Design Alignment Audit [UI AUDIT]
- **Reference:** `.TODO/New_Design/` folder contains complete design reference
- **Missing/Different from current implementation:**
  - [ ] **Auth screens:** Gradient backgrounds, refined input styling
  - [ ] **Bottom Navigation:** May need design refresh
  - [ ] **Filters Modal:** Check alignment with `FiltersModal.tsx`
  - [ ] **Task Details:** Package selection UI
  - [ ] **Proposal Modals:** Submit/Details styling
  - [ ] **Public Profile:** Portfolio grid, reviews section
  - [ ] **Notifications:** Group by Today/Yesterday, icons per type
  - [ ] **Wallet:** Transaction history styling, card display
- **Per FEATURE_INVENTORY.md:** 
  - Proposal Submit Modal - needs verification
  - Bottom Navigation - needs verification
  - Design consistency review needed across all screens

### 3.3 Typography & Spacing Consistency
- [ ] Audit all screens for hardcoded fonts/sizes
- [ ] Use `AppTypography` everywhere
- [ ] Use `AppDimens` for all spacing
- [ ] Verify `AppColors` usage (no hardcoded hex values)

---

## 🔵 PHASE 4: New Features
*Add new functionality*

### 4.1 Notification System [NEW FEATURE]
- **Issue:** No notification system for status updates
- **Required notifications:**
  - [ ] New offer received on your task
  - [ ] Offer accepted/rejected
  - [ ] New message received
  - [ ] Task status changed (assigned, completed, cancelled)
  - [ ] Booking confirmed/cancelled
  - [ ] Payment received
  - [ ] Review received
- **Implementation:**
  - [ ] Create `notifications` table in Supabase
  - [ ] Create `NotificationService` for CRUD
  - [ ] Create `NotificationViewModel`
  - [ ] Implement push notifications (FCM)
  - [ ] Implement in-app notification center
  - [ ] Add unread badge to nav icon
  - [ ] Real-time subscription for new notifications
- **UI Reference:** `.TODO/New_Design/Notifications/NotificationsModal.tsx`

### 4.2 Complete Order Flow System [NEW FEATURE]
- **Issue:** No end-to-end order flow defined
- **Flows to implement:**

#### 4.2.1 Tender Order Flow
```
Client posts tender
    ↓
Freelancers submit offers
    ↓
Client reviews offers → Accept one
    ↓
Task status → 'assigned', Chat created
    ↓
Freelancer works → Delivers work
    ↓
Client reviews → Request revision OR Accept
    ↓
If revision → Freelancer resubmits
    ↓
Client accepts → Task 'completed'
    ↓
Payment released → Review exchange
```

#### 4.2.2 Booking Order Flow
```
Client views provider slots
    ↓
Client books slot → 'pending'
    ↓
Provider confirms → 'confirmed'
    ↓
Work happens at scheduled time
    ↓
Provider marks complete → 'completed'
    ↓
Payment released → Review exchange
```

#### 4.2.3 Payment Flow
```
Client has wallet balance
    ↓
Client accepts offer/books slot
    ↓
Funds held in escrow
    ↓
Work completed and accepted
    ↓
Escrow released to freelancer
    ↓
Platform fee deducted
```

#### 4.2.4 Cancellation Flow
```
Before work starts:
    - Client cancels → Full refund
    - Freelancer cancels → No penalty (first time)
    
During work:
    - Client cancels → Partial refund based on progress
    - Freelancer cancels → Penalty + client refund
    
Dispute:
    - Either party raises dispute
    - Admin reviews
    - Resolution applied
```

- **Database changes needed:**
  - [ ] Add `order_status` enum with more states
  - [ ] Create `escrow_transactions` table
  - [ ] Create `disputes` table
  - [ ] Add `cancelled_reason`, `cancelled_by` to tasks/bookings
  - [ ] Create `reviews` table if not exists


---

## 🟣 PHASE 5: Polish & Quality
*Final touches*

### 5.1 Error Handling Audit
- [ ] Verify all services map errors to user-friendly messages
- [ ] Add retry mechanisms for network failures
- [ ] Implement offline mode indicators
- [ ] Add proper loading states everywhere

### 5.2 Testing
- [ ] Add unit tests for critical services
- [ ] Add widget tests for main screens
- [ ] Integration tests for auth and order flows

### 5.3 Documentation
- [ ] Update DEVELOPER_GUIDE.md with new features
- [ ] Update SUPABASE_SETUP.md with new tables
- [ ] Create user guide/help section in app

---

## 📝 Additional Items Identified

### From Code Analysis:
1. **Service Card widget** exists but may not be used: `lib/features/home/view/widgets/service_card.dart`
2. **Favorite Card** exists: `lib/features/favorites/view/widgets/favorite_card.dart`
3. **Portfolio feature** exists but may not show on profile
4. **Categories feature** implemented but needs design polish

### From FEATURE_INVENTORY.md:
1. Theme Dashboard (`theme_dashboard.dart`) - TO BE CREATED for Phase 3
2. Proposal Submit Modal - needs implementation verification
3. Design consistency review needed

### Missing from New_Design that exists in Flutter:
1. Portfolio Management - not in design reference
2. Saved/Favorites - not in design reference  
3. Categories Management - not in design reference
4. Task Requests widgets - not in design reference

---

## 🎯 Priority Order Summary

| Priority | Phase | Task | Estimated Time |
|----------|-------|------|----------------|
| 1 | 1.1 | Task Card Images | 2-3 hours |
| 2 | 1.3 | Supabase Audit | 4-6 hours |
| 3 | 1.2 | Performance | 6-8 hours |
| 4 | 2.2 | Orders Dashboard | 8-12 hours |
| 5 | 2.3 | Chat Overhaul | 8-12 hours |
| 6 | 2.1 | Card Differentiation | 4-6 hours |
| 7 | 2.4 | Profile Enhancement | 6-8 hours |
| 8 | 2.5 | Saved Projects | 2-3 hours |
| 9 | 2.6 | Forgot Password | 2-3 hours |
| 10 | 3.x | Design Updates | 12-16 hours |
| 11 | 4.1 | Notifications | 8-12 hours |
| 12 | 4.2 | Order Flows | 16-24 hours |

**Total Estimated Time:** ~80-110 hours

---

## 🔧 Quick Reference - Files to Touch Most

```
lib/features/tasks/view/widgets/task_card.dart      # Phase 1.1, 2.1
lib/features/tasks/services/task_service.dart       # Phase 1.3
lib/features/orders/                                # Phase 2.2 (mostly new)
lib/features/chat/                                  # Phase 2.3
lib/features/profile/                               # Phase 2.4
lib/features/saved/                                 # Phase 2.5
lib/features/auth/                                  # Phase 2.6
lib/core/theme/                                     # Phase 3.x
lib/features/notifications/                         # Phase 4.1
```

---

## 📋 Daily Workflow

When you open this file each day:
1. Check which Phase you're on
2. Pick the next unchecked item `[ ]`
3. Mark as `[x]` when complete
4. Update "Last Updated" date below

---

## 📊 Progress Tracking

### Phase 1: Foundation ✅ COMPLETE
- [x] 1.1 Task Card Images
- [x] 1.2 Performance Optimization
- [x] 1.3 Supabase Verification

### Phase 2: Core Features
- [ ] 2.1 Tender/Booking Cards
- [ ] 2.2 Orders Dashboard
- [ ] 2.3 Chat System
- [ ] 2.4 Profile Enhancement
- [ ] 2.5 Saved Projects
- [ ] 2.6 Forgot Password

### Phase 3: Design
- [ ] 3.1 Liquid Glass Effect
- [ ] 3.2 Design Alignment
- [ ] 3.3 Typography/Spacing

### Phase 4: New Features
- [ ] 4.1 Notifications
- [ ] 4.2 Order Flows
- [ ] 4.3 Video Call (Optional)

### Phase 5: Polish
- [ ] 5.1 Error Handling
- [ ] 5.2 Testing
- [ ] 5.3 Documentation

---

**Last Updated:** December 14, 2025
**Next Review:** After Phase 2 completion
