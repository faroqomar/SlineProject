# 📌 Plan: Fix Navigation TODOs & Complete Chat Routing

## 1) Goal

- Goal: Fix all pending TODOs in the UI related to navigation, specifically ensuring users can navigate to the correct Chat thread using the task/booking context, and wiring up Dashboard next-actions.
- Why: Users currently hit "stubbed" snackbars or dead buttons. We must unblock communication while adhering to strict MVVM rules and ensuring production stability.
- Result: Fully functional, idempotent chat routing (PR 1), and properly wired-up Next Actions like Dispute, Review, Payment (PR 2).

## 2) Scope

### In-Scope

**PR 1: Chat Routing & Idempotency**

- `OrdersDashboardScreen.dart`: Wire up `onChatTap`.
- `WorkItemDetailsScreen.dart`: Wire up `Navigate to chat` TODO.
- `ChatViewModel.dart`: Add a helper to cleanly fetch/create a task-linked conversation. Ensure it only returns state/intent, NOT performing `Navigator.push`.
- UI layers: Perform `Navigator.push` in the View based on ViewModel state.
- Add error/offline state handling for chat creation.

**PR 2: Dashboard Next-Actions**

- `NextActionsList.dart` & `DashboardViewModel.dart`: Wire up Review, Payment, and Dispute navigation stubs.
- `BookingDetailsScreen.dart`: Wire up `Dispute Flow` TODO.

### Out-of-Scope

- Building the actual Dispute/Review/Payment screens (if they don't exist, we will route to a placeholder screen or a functional stub that doesn't break).
- Modifying the underlying `MessageService` (it already has `createOrGetConversation` and `start_task_conversation_v1` RPC).

## 3) Evidence & Findings (From Scan)

### Existing

- `MessageService.createOrGetConversation(taskId, user1Id, user2Id)` exists and calls `start_task_conversation_v1`.
- `ChatScreen` takes a `Conversation` object as a parameter.
- `Task` model has `userId` (client) and `assignedFreelancerId` (freelancer).
- `NextActionsList` has TODOs for review/payment/dispute flows.

### Missing

- Safe View-ViewModel bridge: The UI currently has no safe way to request conversation creation without blocking/crashing or violating MVVM.
- Error pathways: No UI states for offline/RPC failure during chat creation.

### Conflicts / Risks

- **MVVM Violation Risk:** Navigation logic placed inside the ViewModel instead of the View.
- **Duplicate Threads Risk:** Not enforcing conversation idempotency.
- **Crash Risk:** Attempting to start chat when `assignedFreelancerId` is null.
- **Scope Creep:** Doing chat routing and dashboard actions in one massive PR increases regressions.

## 4) System Impact Map

- UI: Replaces SnackBar stubs with loading indicators and `Navigator.push`. Handles offline SnackBars.
- MVVM/App Logic: Adds `fetchTaskConversation` logic in ViewModels to handle the async creation of a conversation, exposing `isLoading` and `error` states to the View.
- Database: No schema changes. Relies on existing `start_task_conversation_v1` RPC.
- Safety: Enforces conversation idempotency (same taskId + participants = exactly one thread).

---

# ✅ Execution Phases (Checklist)

## Phase 0: Preconditions & Gates

> Primary: @Sentinel

### 0.1 Spec Lock

- [ ] (@Sentinel) Acceptance + non-regression list (all chat buttons open the correct thread, no crashes on null freelancers).
- [ ] (@Architect) Confirm MVVM approach: View observes `ViewModel.isLoading`, calls `ViewModel.getTaskConversation()`, awaits result, and View manually calls `Navigator.push(ChatScreen)`. Error handling is in View (SnackBar).

---

## Phase 1: Database & Security (If applicable)

> Primary: @Supabase_Ops

### 1.0 Live Supabase Confirmation (MANDATORY)

- [ ] (@Supabase_Ops) Confirm `start_task_conversation_v1` RPC works, enforces idempotency, and doesn't require schema changes.

---

## Phase 2: App Layer (MVVM)

> Primary: @Architect

### 2.1 ViewModels (PR 1 - Chat Routing)

- [ ] (@Architect) Update `ChatViewModel` (or create a mixin/helper) to include `Future<Conversation?> getTaskConversation(Task task)`.
  - Logic: Identify `client_id` (`task.userId`) and `freelancer_id` (`task.assignedFreelancerId` or `task.freelancerId`).
  - Idempotency: Rely on `MessageService` to return the exact same thread if one exists for the task.
  - Return state/error to View. DO NOT use `BuildContext` in ViewModel.

### 2.2 ViewModels (PR 2 - Next-Actions)

- [ ] (@Architect) Update `DashboardViewModel`: Add proper intent-getters for Payment, Review, and Dispute Next Actions.
- [ ] (@Architect) Update `BookingViewModel` / `WorkViewModel`: Expose navigation intent helpers.

---

## Phase 3: UI (After logic)

> Primary: @Pixel

### 3.1 Wiring (PR 1 - Chat Routing)

- [ ] (@Pixel) In `OrdersDashboardScreen` (Line 172): Call ViewModel cleanly. Show async load mask. On success `Navigator.push` to `ChatScreen`. On error (timeout/offline/RPC), show SnackBar.
- [ ] (@Pixel) In `WorkItemDetailsScreen` (Line 461): Replicate the clean ViewModel -> `Navigator.push` pattern.

### 3.2 Wiring (PR 2 - Next-Actions)

- [ ] (@Pixel) In `DashboardViewModel` & `NextActionsList`: Replace logical TODOs with actual View-level routing based on intent.
- [ ] (@Pixel) In `BookingDetailsScreen`: Wire the Dispute transition to navigate to the Dispute Form (or placeholder).

---

## Phase 4: QA + Security (MANDATORY)

> Primary: @Sentinel

### 4.1 Functional QA & Test Matrix (Before Merge)

- [ ] (@Sentinel) **Test Matrix**:
  - `Client Profile`: Taps "Chat" on assigned task -> Opens thread. Repeat -> Opens _same_ thread.
  - `Freelancer Profile`: Taps "Chat" on active work -> Opens thread. Repeat -> Opens _same_ thread.
  - `Offline/Timeout`: Taps "Chat" -> Fails gracefully with SnackBar, no crash, loading spinner dismisses.
  - `Null Freelancer`: Button is hidden or disabled, no crash.
- [ ] (@Sentinel) Verify PR 2 Next Actions buttons route correctly to placeholders/forms without unhandled exceptions.

---

## Phase 5: Documentation Sync (MANDATORY)

> Primary: @SlineDocs

- [ ] (@SlineDocs) Mark the Chat Routing and Dashboard Actions as completed in `MVP_ROADMAP.md` and remove TODOs from code.

---

## 7) Acceptance Criteria (MANDATORY)

- **PR 1**: Chat routing is fully functional from Orders and Work Items context. Navigation is triggered from View, NOT ViewModel.
- **Idempotency**: Clicking chat multiple times on the same task NEVER creates duplicate threads.
- **Resilience**: Network failures or RPC errors trigger a retry prompt or friendly SnackBar, preventing infinitely spinning loaders and crashes.
- **PR 2**: Dashboard Next Actions (Dispute, Review, Payment) trigger tangible View-level navigation, leaving no TODO comments behind.

## 8) Rollback Plan

- Git revert the individual PRs if chat creation starts failing or crashing the app.

## 9) References (From Scan)

- `lib/features/chat/services/message_service.dart` (RPC call implementation)
- `lib/features/orders/view/orders_dashboard_screen.dart` (TODO line 172)
- `lib/features/work/view/work_item_details_screen.dart` (TODO line 461)
- `lib/features/dashboard/viewmodels/dashboard_view_model.dart`
