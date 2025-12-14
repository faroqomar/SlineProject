# Orders Feature Reference

## 1. Human Explanation
The Orders feature (often referred to as "My Published Tasks" or "Client Dashboard") allows a user (acting as a Client) to manage the tasks they have posted. It provides a central dashboard to view tasks by status, check incoming offers/bids, and take actions like editing, deleting, or accepting proposals.

Architecture (MVVM):
- **View (`lib/features/orders/view/`)**: `OrdersDashboardScreen` displays the list of tasks. `OrderCard` renders individual items. `OfferListSheet` handles the offer review flow.
- **ViewModel (`lib/features/orders/viewmodels/`)**: `OrdersViewModel` manages the list state, tabs (Open, In Progress, etc.), and actions (delete, accept offer).
- **Service (`lib/features/orders/services/`)**: `OrdersService` aggregates functionality from `TaskService` (fetching my posts) and `TaskRequestsService` (fetching offers).

## 2. Database & Supabase Mapping

This feature primarily consumes the `tasks` and `task_requests` tables.

### 2.1 Consumed Tables
- **`public.tasks`**: The core entity. Clients view tasks where `user_id = auth.uid()`.
- **`public.task_requests`**: Offers submitted by freelancers. Clients view these for their Open tasks.
- **`public.profiles`**: Joined to display bidder information (name, avatar).

### 2.2 Key Logic
- **My Published Tasks**: `SELECT * FROM tasks WHERE user_id = auth.uid()`.
- **Offers**: `SELECT *, profiles(*) FROM task_requests WHERE task_id = ?`.
- **Status Filtering**: Client-side filtering of the fetched tasks into tabs (Open, In Progress, Completed, Cancelled).

## 3. File Inventory

| File | Layer | Description |
| --- | --- | --- |
| `lib/features/orders/services/orders_service.dart` | Service | Facade service wrapping `TaskService` and `TaskRequestsService` for dashboard operations. |
| `lib/features/orders/viewmodels/orders_view_model.dart` | ViewModel | `ChangeNotifier` managing the dashboard state, tabs, and action execution. |
| `lib/features/orders/view/orders_dashboard_screen.dart` | View | The main screen with tab bar and task list. |
| `lib/features/orders/view/widgets/order_card.dart` | Widget | A card displaying task info, status badge, metrics (offers/time), and context actions. |
| `lib/features/orders/view/widgets/offer_list_sheet.dart` | Widget | Bottom sheet for reviewing, accepting, or rejecting offers. |

## 4. UI Flow

1.  **Dashboard**: User sees "My Published Tasks". Tabs filter the list.
2.  **Order Card**:
    *   **Open Tender**: Shows "X Offers". Action: "View Offers".
    *   **Assigned/In Progress**: Shows "Assigned to [Name]". Action: "View Status" (or Chat).
    *   **Menu**: 3-dot menu allows "Edit" (opens `CreateTaskScreen` in edit mode) and "Delete".
3.  **Offer Review**: Tapping "View Offers" opens `OfferListSheet`. User can Accept or Reject each bid. Accepting triggers status update to `assigned`.

## 5. Error Handling

| Origin | Error | User Message | Mitigation |
| --- | --- | --- | --- |
| Load Orders | Network/DB | "Failed to load orders" | Retry via pull-to-refresh. |
| Accept Offer | RLS/Logic | "Failed to accept offer" | Ensure task is still open and offer is pending. |
| Update Task | Schema Mismatch | "Database error" | Ensure columns like `packages` or `offers` are not sent if they don't exist in DB. |

## 6. Testing Checklist

- [ ] **Load**: Dashboard loads tasks created by the current user.
- [ ] **Tabs**: Switching tabs correctly filters the list (Open vs In Progress).
- [ ] **Edit**: "Edit" menu option opens the form pre-filled; saving updates the list.
- [ ] **Delete**: "Delete" menu option shows confirmation and removes task.
- [ ] **Offers**: "View Offers" shows the list of bidders with names/avatars.
- [ ] **Accept**: Accepting an offer closes the modal and updates task status (optimistically or via refresh).
