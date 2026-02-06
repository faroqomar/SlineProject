# Admin Database Reference

This file summarizes the **Supabase Schema** context you need to build the dashboard.
It is based on the SLine Mobile App (v2.1) schema.

## Core Tables (For Admin Oversight)

### 1. `profiles` (Users)
*   **Purpose**: The central identity registry.
*   **Admin Needs**:
    *   View all profiles (`SELECT *`).
    *   Edit core fields (ban user, verify identity) -> *Requires Service Role*.
    *   **Key Columns**:
        *   `id`: UUID (Matches Auth ID)
        *   `full_name`, `email`
        *   `avatar_url` (Path in storage)
        *   `roles`: `['client', 'freelancer']`
        *   `active_role`
        *   `created_at`

### 2. `tasks` (Jobs)
*   **Purpose**: The marketplace listings.
*   **Admin Needs**:
    *   Monitor content (illegal requests, spam).
    *   Force-close or cancel tasks in disputes.
    *   **Key Columns**:
        *   `id`, `title`, `description`, `budget`
        *   `status`: `'open' | 'assigned' | 'in_progress' | 'closed' | 'canceled'`
        *   `task_type`: `'tender' | 'booking'`
        *   `client_id`, `freelancer_id`

### 3. `disputes` (Proposed Table)
*   **Note**: This table might not exist yet in the main schema or is handled via `messages` with type `dispute_report`.
*   **Admin Need**: **Likely need to CREATE this table** for the dashboard to track tickets.
*   *Recommendation*: Create a specific `admin_tickets` or `disputes` table for structured tracking.

### 4. `audit_logs` (Crucial for Admin)
*   **Status**: Needs to be created.
*   **Purpose**: Record EVERY admin action.
*   **Schema Recommendation**:
    ```sql
    create table audit_logs (
      id uuid primary key default gen_random_uuid(),
      admin_id uuid not null references auth.users(id),
      action_type text not null, -- 'BAN_USER', 'REFUND_ORDER', 'VIEW_PRIVATE_CHAT'
      target_resource_id uuid, -- ID of the user/task affected
      details jsonb default '{}', -- Old/New values
      created_at timestamptz default now()
    );
    ```

### 5. `money` & `wallet_transactions`
*   **Admin Needs**:
    *   View financial flow.
    *   Manually process Refunds or Releases if automatic logic fails.
    *   **Status Enum**: `unpaid`, `held`, `released`, `refunded`.

---

## Enums to Know

You will need to map these to UI Badges (e.g., Green for 'active', Red for 'canceled').

**`booking_status_enum`**
*   `pending`
*   `confirmed`
*   `active` -> `delivered` -> `completed`
*   `canceled`, `declined`, `refunded`
*   `paid_request_pending`
*   `expired_unanswered`

**`task_type_enum`**
*   `tender` (Proposals)
*   `booking` (Direct Slot Booking)

---

## Storage Buckets (Admin Access)

Since we use `Service Role`, we can generate Signed URLs for **ANY** file, even in private buckets.

*   `avatars/`: User profile pics.
*   `task-images/`: Private attachments for tasks.
*   `chat-attachments/`: Private files in DMs (Use with caution, only for disputes).
*   `portfolio/`: Public images.

## Admin Protocols

1.  **Read-Only First**: Defaults should always be fetching data.
2.  **Destructive Actions**: Buttons like "Ban", "Delete", "Refund" should have a double-confirmation modal (e.g., "Type 'CONFIRM' to proceed").
3.  **No Direct SQL**: Use the Supabase JS Client methods (`.from('table').update(...)`) for type safety, avoiding raw SQL strings unless necessary for complex analytics.
