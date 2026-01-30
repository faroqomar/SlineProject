# Phase 2: Unified Management & Notes System Implementation Plan

## Overview
Implement a centralized "Order Management" panel for Booking and Tender tasks. This system serves as the immutable record of all interactions, notes, and lifecycle events (extensions, price changes) for a job. It acts as the "paper trail" for dispute resolution.

## Prerequisites
- **Phase 1 (Booking & Wallet)** must be completed (Completed).
- **Auth & RLS** must be active (Active).

## Phase 0: Strategic Planning (Completed)

**Goal:** Create a perfect, step-by-step implementation plan.
**Agent:** `@SlinePlanner`

1.  **Context Scan:** Checked `SUPABASE_SETUP.md` (Table missing). Checked `STRUCTURE.md`.
2.  **Gap Analysis:** `work_logs` table, models, services, and UI components are completely missing.
3.  **Plan Verification:**
    -   **RLS**: Strict logic required (`is_work_log_participant`).
    -   **N+1**: Will use JOINs when fetching logs with authors.
    -   **Theme**: Will use `GlassContainer` for the panel.

## Phase 1: Database & Backend

**Goal:** Robust data foundation with RLS and Security.
**Agent:** `@Supabase_Ops`

1.  **Schema Execution**:
    -   Create `work_logs` table:
        ```sql
        create table public.work_logs (
          id uuid not null default gen_random_uuid() primary key,
          author_id uuid not null references public.profiles(id),
          related_entity_id uuid not null, -- task_id or booking_id
          related_entity_type text not null, -- 'task', 'booking'
          content text not null, -- The note or system message
          is_private boolean not null default false, -- True = Private Note, False = Shared Lo
          metadata jsonb default '{}'::jsonb, -- Store event details {type: 'extension_request', status: 'pending'}
          created_at timestamptz not null default now()
        );
        ```
    -   Create Index: `idx_work_logs_entity` on `(related_entity_id, created_at desc)`.

2.  **Functions & Policies**:
    -   **Function**: `is_work_log_participant(entity_id, type, user_id)`
        -   Logic:
            -   If `related_entity_type` = 'task': check `tasks` table (client_id, freelancer_id).
            -   If `related_entity_type` = 'booking': check `bookings` table (client_id, provider_id).
    -   **RLS Policies**:
        -   `work_logs_select`:
            -   If `is_private` = true: `auth.uid() = author_id`
            -   If `is_private` = false: `is_work_log_participant(...)`
        -   `work_logs_insert`: `is_work_log_participant(...)` (Parties can add notes).
        -   `work_logs_update`: `false` (Immutable).
        -   `work_logs_delete`: `false` (Immutable).

---

## Phase 2: Data Layer (Models & Services)

**Goal:** Type-safe data access.
**Agent:** `@Architect`

1.  **Model**:
    -   Create `lib/features/management/models/work_log_model.dart`.
    -   Fields: `id`, `authorId`, `relatedEntityId`, `relatedEntityType`, `content`, `isPrivate`, `metadata`, `createdAt`.
    -   Include `author` (Profile) via JOIN.

2.  **Service**:
    -   Create `lib/features/management/services/work_log_service.dart`.
    -   Methods:
        -   `getLogs(entityId)`: Fetch logs with author profile.
        -   `addLog(WorkLog)`: Insert new log.
        -   `logEvent(type, payload)`: Helper for system events (extensions, etc.).

---

## Phase 3: Business Logic (MVVM)

**Goal:** Clean state management.
**Agent:** `@Architect`

1.  **ViewModel**:
    -   Create `lib/features/management/viewmodels/order_management_view_model.dart`.
    -   Extend `ChangeNotifier`.
    -   State: `List<WorkLog>`, `isLoading`, `isSending`.
    -   Methods:
        -   `loadLogs(entityId)`
        -   `postNote(content, isPrivate)`
        -   `requestExtension(days)`
        -   `proposePriceChange(amount)`

2.  **Integration**:
    -   Register Provider in `IntegrationWrapper` or `MainNavigationScreen` (or potentially strictly feature-scoped).

---

## Phase 4: UI & UX Design

**Goal:** "Wowed" user experience with SLine Aesthetics.
**Agent:** `@Pixel`

1.  **OrderManagementPanel Widget**:
    -   Create `lib/features/management/view/order_management_panel.dart`.
    -   Design:
        -   **Header**: "Order Management" (Glassmorphic).
        -   **Action Grid**: Buttons for "Extension", "Price Change", "Refund".
        -   **Timeline**: Vertical list of `work_logs`.
            -   **System Event**: Centered, small text/badge.
            -   **Note**: Chat-bubble style (Left/Right not strictly needed if singular stream, but maybe distinguished by color).
            -   **Private Note**: Distinctive "Yellow/Lock" style.
    -   **Input Area**: Text field for adding notes + "Private" toggle.

2.  **Integration**:
    -   Embed `OrderManagementPanel` into:
        -   `BookingDetailsScreen` (Bottom section or Tab).
        -   `TaskDetailsScreen` (if status is active).

---

## Phase 5: Verification & Documentation

**Goal:** Zero regressions.
**Agents:** `@Sentinel`, `@SlineDocs`

1.  **Testing**:
    -   **Manual**:
        -   Check RLS: Post private note, switch user -> Should not see.
        -   Check Public: Post shared note -> Both see.
        -   Check System Event: "Request Extension" -> Appears in log.
    -   **Code**: `dart fix`, `flutter analyze`.

2.  **Docs**:
    -   Update `SUPABASE_SETUP.md` with `work_logs`.
    -   Update `DEVELOPER_GUIDE.md` with "Order Management" section.
