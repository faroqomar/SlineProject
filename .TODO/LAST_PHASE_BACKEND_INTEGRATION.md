# 🔮 Last Phase: Backend Integration & Future Features

**Objective:** Connect the new UI components (Wallet, Packages, Chat Offers) to real backend logic and databases, transitioning from "Mock Data" to "Live Data".
**Source of Truth:** `.TODO/Future_Plans/DESIGN_IMPLEMENTATION_PLAN.md`
**Gap Analysis Source:** `.TODO/Future_Plans/FUTURE_IMPLEMENTATION_TODO.md`

---

## 1. 💰 Wallet & Payments System

- [ ] **Database: Create Wallet Tables**
    - **Agent:** `@Supabase_Ops`
    - **Prompt:** "Create a migration for `wallets` (user_id, balance, currency) and `transactions` (wallet_id, amount, type, status, reference_id) tables. Ensure RLS allows users to read their own wallet/transactions."

- [ ] **Backend: Payment Gateway Integration (Stripe)**
    - **Agent:** `@Supabase_Ops` / `@Architect`
    - **Prompt:** "Plan the Edge Function for processing payments via Stripe. It should update the `wallets` table via a secure webhook."

- [ ] **Logic: Wallet Repository & ViewModel**
    - **Agent:** `@Architect`
    - **Prompt:** "Create `lib/features/wallet/data/wallet_repository.dart` to fetch balance/transactions from Supabase. Create `WalletViewModel` to expose this data to the UI, replacing the mock data in `WalletDashboardScreen`."

- [ ] **UI: Connect Wallet Dashboard**
    - **Agent:** `@Pixel`
    - **Prompt:** "Update `lib/features/wallet/view/wallet_dashboard_screen.dart` to use `Consumer<WalletViewModel>`. Display real balance and transaction history."

---

## 2. 📦 Service Packages (Fiverr-style)

- [ ] **Database: Add Packages to Tasks**
    - **Agent:** `@Supabase_Ops`
    - **Prompt:** "Create a migration to add a `packages` JSONB column to the `tasks` table (or a separate `task_packages` table). It should store Basic/Standard/Premium tier details (price, delivery, description)."

- [ ] **Logic: Update Task Model & Service**
    - **Agent:** `@Architect`
    - **Prompt:** "Update `lib/features/tasks/models/task_model.dart` to include the `packages` field. Update `TaskService` to handle parsing this data."

- [ ] **UI: Real Data in Task Details**
    - **Agent:** `@Pixel`
    - **Prompt:** "Update `lib/features/tasks/view/task_details_screen.dart` to display the actual packages from the `Task` model instead of the hardcoded mock data."

---

## 3. 🤝 Custom Chat Offers

- [ ] **Database: Create Offers Table**
    - **Agent:** `@Supabase_Ops`
    - **Prompt:** "Create a migration for `chat_offers` table (conversation_id, sender_id, price, title, description, status). Add RLS policies."

- [ ] **Logic: Offer Repository & ViewModel**
    - **Agent:** `@Architect`
    - **Prompt:** "Create `OfferRepository` to create/fetch offers. Update `ChatViewModel` to handle sending an offer (creating a DB entry + sending a message with metadata)."

- [ ] **UI: Wire Create Offer Modal**
    - **Agent:** `@Pixel`
    - **Prompt:** "Update `_showCreateOfferModal` in `ChatScreen` to call `ChatViewModel.sendOffer(...)` instead of sending a raw JSON string."

- [ ] **UI: Interactive Offer Bubble**
    - **Agent:** `@Pixel`
    - **Prompt:** "Update `_buildOfferBubble` in `ChatScreen` to be interactive. The 'Accept'/'Decline' buttons should call `ChatViewModel.respondToOffer(...)`."

---

## 4. 🔍 Advanced Filtering

- [ ] **Backend: Filter RPC**
    - **Agent:** `@Supabase_Ops`
    - **Prompt:** "Create a Supabase RPC function `search_tasks` that accepts advanced filters (budget range, delivery time, seller level) and returns filtered tasks."

- [ ] **Logic: Update TaskFilterViewModel**
    - **Agent:** `@Architect`
    - **Prompt:** "Update `TaskFilterViewModel` to call the new `search_tasks` RPC. Add state properties for budget range and other filters."

- [ ] **UI: Connect Filter Sheet**
    - **Agent:** `@Pixel`
    - **Prompt:** "Implement `lib/features/home/view/widgets/filters_bottom_sheet.dart` (or similar). Connect its inputs (sliders, checkboxes) to `TaskFilterViewModel`."

---

## 5. 🔔 Notification System

- [ ] **Database: Notifications Table**
    - **Agent:** `@Supabase_Ops`
    - **Prompt:** "Create `notifications` table (user_id, title, body, type, is_read, related_id). Enable RLS."

- [ ] **Logic: Notification Service**
    - **Agent:** `@Architect`
    - **Prompt:** "Create `NotificationService` to listen to real-time inserts on the `notifications` table. Create `NotificationViewModel` to manage the list."

- [ ] **UI: Notification Center**
    - **Agent:** `@Pixel`
    - **Prompt:** "Create `lib/features/notifications/view/notification_center_screen.dart` (or overlay). Use `GlassContainer`. Bind it to `NotificationViewModel`."

---

## 6. 📋 Orders Dashboard

- [ ] **Database: Orders Status Workflow**
    - **Agent:** `@Supabase_Ops`
    - **Prompt:** "Ensure `orders` table has all necessary columns for the workflow: `status` (active, revision, completed, cancelled), `due_date`, `amount`."

- [ ] **Logic: Orders ViewModel**
    - **Agent:** `@Architect`
    - **Prompt:** "Create `OrdersViewModel` to fetch orders grouped by status. Implement methods for `deliverWork` and `requestRevision`."

- [ ] **UI: Connect Orders Dashboard**
    - **Agent:** `@Pixel`
    - **Prompt:** "Update `lib/features/orders/view/orders_dashboard_screen.dart` to use `OrdersViewModel`. Make the tabs functional with real data."

---

