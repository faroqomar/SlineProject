# Sline Improvement Plan & Checklist

This document tracks the step-by-step execution plan for Sline v2.0.
**Status**: Planning / Ready for Execution

---

## 🏗️ Phase 1: Critical UI & Stability Repairs
*Fix the "broken windows" first. The app must look and feel broken-free before adding complex logic.*

- [x] **1.1 Fix Layout Rendering Issues**
    - [x] Tender Details Screen: Ensure layout matches design screenshots.
    - [x] Booking Details Screen: Fix constrained box/overflow errors.
- [x] **1.2 Add Skeleton Loading States**
    - [x] Tender Details (replace spinners).
    - [x] Booking Details.
    - [x] Offers List.
    - [x] Chat Thread.
- [x] **1.3 Visual Polish**
    - [x] Add smooth tab transitions (animations between main tabs).

---

## 🔌 Phase 2: Data Wiring & Core Dependencies
*Ensure the plumbing works. Real data must flow before we build complex flows on top of it.*

- [x] **2.1 Categories System**
    - [x] Ensure "Create Task" properly loads categories from Supabase.
    - [x] Ensure selected category is saved correctly to the Task record.
- [x] **2.2 Booking Packages**
    - [x] Ensure Basic/Standard/Premium packages are stored in Supabase.
    - [x] Display package details correctly in the Booking UI.
- [x] **2.3 Demo Payment Infrastructure** (Internal Testing Tool)
    - [x] Implement `DemoPaymentService` (mock success/failure).
    - [x] Ensure architecture allows swapping this for Stripe/Gateway later.

---

## 💬 Phase 3: Communication Infrastructure
*The backbone of the marketplace. Chat logic first, then notifications link to it.*

- [x] **3.1 Chat Integration Logic (Foundation)**
    - [x] **Booking -> Chat Entry:** Add "Start Conversation" button on Booking Details.
    - [x] **Idempotency:** Logic to check `if (chatExists) openIt else createNew`.
    - [x] **Context Widget:** Show pinned context at top of chat:
        - [x] If Task chat → show Task title + status
        - [x] If Booking chat → show Booking date/time + selected package
- [ ] **3.2 Notification System Fixes**
    - [ ] Fix Deep Links: Tapping "New Offer" -> Opens Offer List.
    - [ ] Fix Deep Links: Tapping "New Message" -> Opens the specific Chat thread (using logic from 3.1).
    - [ ] Fix Spam: Group messages (don't push notify for *every* message if app is open).

---

## 🔄 Phase 4: Order & Transaction Workflows
*The core business logic. Statuses > Transactions > UI.*

- [ ] **4.1 Flow Audit & Technical Prep**
    - [ ] List all missing screens for Tender & Booking flows.
    - [ ] **Blocker Fix:** Update `OrdersViewModel` with proper Enum handling for all Task Statuses.
    - [ ] Map out missing transitions (e.g., "After Accept -> Go to where?").
- [ ] **4.2 Core Logic Implementation** (Statuses & Transitions)
    - [ ] **Tender Flow:** Assigned -> Delivered -> Revision -> Completed.
    - [ ] **Booking Flow:** Pending -> Confirmed -> Completed.
    - [ ] **Payment Flow:** escrow_held -> released_to_freelancer / refunded_to_client (+ frozen during dispute).
    - [ ] **Dispute Flow:** Cancellation logic & 'Dispute' status handling.
- [ ] **4.3 Transactional Chat Elements** (UI)
    - [ ] **Offer Cards:** Display "New Offer" bubble inside Chat stream.
    - [ ] **Action Buttons:** Add "Accept" / "Pay Now" buttons directly in Chat (linked to 4.2 logic).

---

## 👤 Phase 5: Profiles, Trust & Social Proof
*Enhancing the human element. Who am I hiring?*

- [ ] **5.1 Publisher Profile Preview**
    - [ ] Entry point: Tap avatar in Tender/Booking details.
    - [ ] Profile View: Show basic info, portfolio summary.
- [ ] **5.2 Ratings & Reviews**
    - [ ] Database: Create `reviews` table and sql functions.
    - [ ] UI: "Write Review" screen after order completion.
    - [ ] UI: Display Star Ratings on User Profiles and Command Cards.

---

## 🔍 Phase 6: Discovery & Organization
*Helping users find what they need faster.*

- [ ] **6.1 Search Enhancements**
    - [ ] Implement Local Search History.
    - [ ] Implement "Trending Tags" suggestions.
- [ ] **6.2 Advanced Filters**
    - [ ] Build Multi-criteria Filter Modal (Budget, Skills, Location).
- [ ] **6.3 Task Templates**
    - [ ] "Save as Template" feature for frequent posters.

---

## 🚀 Phase 7: Launch Readiness (Onboarding & Global)
*Critical items for App Store approval and first-time user experience.*

- [ ] **7.1 Onboarding Flow**
    - [ ] Intro Slides (Carousel explaining Tenders vs Bookings).
    - [ ] Role Selection (Graphic screen: Client vs Freelancer).
- [ ] **7.2 Safety & Compliance**
    - [ ] Implement "Report User/Content" menu actions.
    - [ ] Implement "Block User" logic (hide messages).
    - [ ] Add "Delete Account" flow (GDPR/Apple requirement).
    - [ ] Add Static Pages: Privacy Policy & Terms link/view.
- [ ] **7.3 Localization (Arabic/MENA)**
    - [ ] Set up `flutter_localizations` & ARB files.
    - [ ] Extract hardcoded strings.
    - [ ] Verify & Fix RTL Layouts (Mirroring icons, alignment).
    - [ ] Add Language Toggle in Settings.

---

## 🔮 Phase 8: Future / Advanced Features
*Nice-to-haves for v2.1+*

- [ ] **8.1 In-App Media Viewer** (Replace external browser).
- [ ] **8.2 Video Consultations** (Agora/Twilio integration).

---

## 🛠 Appendix: Clean Code & Roadmap Debts
- [ ] Implement `ConversationListTile` online presence logic (when presence service ready).
- [ ] Verify Social Login implementation plan.
