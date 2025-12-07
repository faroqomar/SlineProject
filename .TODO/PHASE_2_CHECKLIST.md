# 🚀 Phase 2: Feature Migration Checklist

**Objective:** Implement core UI screens with the new design system, integrating the shared widgets and theme components from Phase 1.
**Source of Truth:** `.TODO/Future_Plans/DESIGN_IMPLEMENTATION_PLAN.md`
**Design Reference:** `.TODO/New_Design_Code/Organized/`

---

## 🎨 Step 1: Authentication (`features/auth`)

- [ ] **Update Auth View Layout**
    - **Agent:** `@Pixel`
    - **Prompt:** "Refactor `lib/features/auth/view/login_screen.dart` and `lib/features/auth/view/signup_screen.dart` to use the new `GlassContainer` for main layouts and `AppTextField` for inputs. Incorporate `AppButton` for actions. Refer to `.TODO/New_Design_Code/Organized/Auth/AuthScreens.tsx`."

- [ ] **Implement Login/Signup Toggle Animation**
    - **Agent:** `@Pixel`
    - **Prompt:** "Add animation for the Login/Signup screen transitions as observed in `.TODO/New_Design_Code/Organized/Auth/AuthScreens.tsx`. This might involve using `AnimatedSwitcher` or `PageView`."

- [ ] **Bind AuthViewModel to New Inputs**
    - **Agent:** `@Architect`
    - **Prompt:** "Ensure `AuthViewModel` (if existing) or relevant state management connects correctly to the new `AppTextField` widgets in `login_screen.dart` and `signup_screen.dart`."

---

## 🧭 Step 2: Core Navigation & Home (`features/home`)

- [ ] **Build Main Wrapper Scaffold**
    - **Agent:** `@Pixel`
    - **Prompt:** "Create or refactor `lib/app/main_navigation_screen.dart` to implement the 'Main Wrapper' scaffold. This should include an animated gradient background and noise texture similar to the main phone mockup in `.TODO/New_Design_Code/App.tsx`."

- [ ] **Integrate CustomBottomNav**
    - **Agent:** `@Pixel`
    - **Prompt:** "Ensure the `CustomBottomNavBar` (from `lib/core/widgets/custom_bottom_nav_bar.dart`) is correctly integrated into the `main_navigation_screen.dart` as a floating element at the bottom."

- [ ] **Update HomeView Header & TaskCard**
    - **Agent:** `@Pixel`
    - **Prompt:** "Refactor `lib/features/home/view/home_screen.dart` to use the new Header design (Greeting + Search) and `TaskCard` widgets (if `TaskCard` is a shared widget, update its implementation). Refer to `.TODO/New_Design_Code/Organized/Home/HomeView.tsx`."

---

## 🎯 Step 3: Task Discovery (`features/tasks` & `features/booking`)

- [ ] **Refactor TaskTile/TaskCard**
    - **Agent:** `@Pixel`
    - **Prompt:** "Refactor `lib/features/tasks/view/widgets/task_card.dart` and `lib/features/booking/view/bookings_list_screen.dart` (or equivalent list items) to match the new design for task cards. This includes `Hot badge`, `gradient overlay`, and distinct visuals for Tender vs Booking. Refer to `.TODO/New_Design_Code/Organized/Tenders/TenderListView.tsx` and `Bookings/BookingListView.tsx`."

- [ ] **Implement Tender/Booking Visual Distinction**
    - **Agent:** `@Pixel`
    - **Prompt:** "Ensure the visual differences between Tender and Booking tasks are correctly applied in their respective list views, utilizing the semantic colors defined in `AppColors`."

---

## 📝 Step 4: Task Details & Proposals (`features/task_details`)

- [ ] **Create Task Details Route/Modal**
    - **Agent:** `@Pixel`
    - **Prompt:** "Refactor `lib/features/tasks/view/task_details_screen.dart` to implement the detailed task view based on `.TODO/New_Design_Code/Organized/TaskDetails/TaskDetailsOverlay.tsx`. Use `GlassContainer` and other shared widgets."

- [ ] **Implement Submit Proposal Modal**
    - **Agent:** `@Pixel`
    - **Prompt:** "Implement the 'Submit Proposal' modal (bottom sheet) within the task details flow, matching the design in `.TODO/New_Design_Code/Organized/TaskDetails/TaskDetailsOverlay.tsx`. Utilize `AppTextField` and `AppButton`."

- [ ] **Add Packages UI (Mock Data)**
    - **Agent:** `@Architect` (for data structure), `@Pixel` (for UI)
    - **Prompt:** "If 'Service Packages' (Basic/Standard/Premium) are not yet in the Flutter model, create mock data and build the corresponding UI in `task_details_screen.dart` using the design from `TaskDetailsOverlay.tsx`. Mark sections with `// TODO: Connect to Backend`."

---

## 💬 Step 5: Messaging (`features/chat`)

- [ ] **Update Chat List UI**
    - **Agent:** `@Pixel`
    - **Prompt:** "Refactor `lib/features/chat/view/chat_list_screen.dart` (or equivalent) to match the message list design in `.TODO/New_Design_Code/Organized/Messages/MessagesListView.tsx`."

- [ ] **Implement Create Offer Modal**
    - **Agent:** `@Pixel`
    - **Prompt:** "Implement the 'Create Offer' modal within the chat view, following `.TODO/New_Design_Code/Organized/Messages/ChatOverlay.tsx`. Utilize `AppTextField` and `AppButton`."

- [ ] **Render Custom Offer Bubbles**
    - **Agent:** `@Pixel`
    - **Prompt:** "Implement the rendering of 'Custom Offer' message bubbles within the chat stream, matching the design in `.TODO/New_Design_Code/Organized/Messages/ChatOverlay.tsx`."

---

## 💰 Step 6: Wallet & Orders (`features/wallet`, `features/orders`)

- [ ] **Create Wallet Feature Folder & UI (Mock Data)**
    - **Agent:** `@Pixel`
    - **Prompt:** "Create `lib/features/wallet/` and implement `lib/features/wallet/view/wallet_dashboard_screen.dart`. Design the 'Glass Credit Card' and transaction history using mock data based on `.TODO/New_Design_Code/Organized/Wallet/WalletDashboard.tsx`. Mark with `// TODO: Connect to Backend`."

- [ ] **Create Orders Feature Folder & UI (Mock Data)**
    - **Agent:** `@Pixel`
    - **Prompt:** "Create `lib/features/orders/` and implement `lib/features/orders/view/orders_dashboard_screen.dart`. Design the Orders tabs (Active, Revision, Completed) using mock data based on `.TODO/New_Design_Code/Organized/Orders/OrdersDashboard.tsx`. Mark with `// TODO: Connect to Backend`."

---

## 👤 Step 7: Profile (`features/profile`)

- [ ] **Update Profile Header**
    - **Agent:** `@Pixel`
    - **Prompt:** "Refactor `lib/features/profile/view/profile_screen.dart` to update the profile header (Avatar + Stats) based on `.TODO/New_Design_Code/Organized/Profile/ProfileView.tsx`."

- [ ] **Implement Dark Mode Toggle**
    - **Agent:** `@Pixel`
    - **Prompt:** "Integrate the 'Dark Mode' toggle switch into the profile settings, connecting it to the `ThemeModeProvider` to switch the application's theme. Refer to `.TODO/New_Design_Code/Organized/Profile/ProfileView.tsx`."