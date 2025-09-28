
# Tasks Module Addendum (MVVM + Schema Sync)

## 1. MVVM Alignment (current code)
- **ViewModels**: `lib/features/tasks/viewmodels/`
  - `task_view_model.dart` – orchestrates core task flows.
  - `task_requests_view_model.dart` – submit/update offers, list requests.
  - `task_filter_view_model.dart` – search and category filter used on Home/Tasks lists.
- **Services**: `lib/features/tasks/services/`
  - `task_service.dart` – CRUD for `tasks`, joins `profiles` for author.
  - `task_requests_service.dart` – CRUD for `task_requests` with policy-aware calls.
  - `task_image_service.dart` – uploads task images to Storage (signed URLs for display).
- **Models**: `lib/features/tasks/models/`
  - `task_model.dart`, `task_request_model.dart`.
- **Views**: `lib/features/tasks/view/` – create, details, request submit, cards/tiles.

## 2. Database & Supabase Mapping (from SUPABASE_SETUP.md)

### 2.1 `public.tasks`
| Column | Type | Purpose / Usage | Notes |
| --- | --- | --- | --- |
| `id` | `uuid` (PK) | Task id | Default `gen_random_uuid()` |
| `user_id` | `uuid` (FK → `auth.users.id`) | Task owner (client) | RLS owner-only write |
| `title` | `text` | Title | Required |
| `description` | `text` | Details | Required |
| `budget` | `numeric`/`bigint` | Price field | Render with `format_price.dart` |
| `deadline` | `timestamptz` | Optional due date | UTC |
| `category` | `text` (legacy) | Pre-FK category label | Kept for back-compat |
| `skills` | `text[]` | Tags/skills | Optional |
| `status` | `text` | `open`/`assigned`/`closed` | Drives visibility/flows |
| `task_type` | `task_type_enum` | `tender` or `booking` | Default `tender` |
| `session_price_bigint` | `bigint` | Booking pricing (opt) | Only for booking-type tasks |
| `hour_rate_bigint` | `bigint` | Booking hourly (opt) | Only for booking-type tasks |
| `assigned_freelancer_id` | `uuid` (FK → `profiles.id`, null) | Winner | Set on accept/assign |
| `category_id` | `uuid` (FK → `categories.id`, null) | Category FK | Indexed |
| `created_at` | `timestamptz` | Created (UTC) | Default `now()` |

Indexes
- `idx_tasks_category_id` on `(category_id)`

### 2.2 `public.task_requests`
| Column | Type | Purpose / Usage | Notes |
| --- | --- | --- | --- |
| `id` | `uuid` (PK) | Request id | Default `gen_random_uuid()` |
| `task_id` | `uuid` (FK → `tasks.id`) | Target task | Indexed with created_at |
| `bidder_id` | `uuid` (FK → `profiles.id`) | Freelancer | Must equal `auth.uid()` on insert |
| `price` | `bigint` | Offer price (cents) | Positive required (guard) |
| `days` | `int` | Delivery days | Positive required (guard) |
| `note` | `text` | Optional message | Optional |
| `status` | `text` | `pending`/`accepted`/`rejected` | Default `pending` |
| `created_at` | `timestamptz` | Created (UTC) | Default `now()` |

Indexes & Constraints
- `idx_task_requests_task_created (task_id, created_at DESC)`
- `uq_task_requests_unique_pending_per_user (task_id, bidder_id) WHERE status = 'pending'`

### 2.3 Enums
- `task_type_enum`: `tender`, `booking`

### 2.4 RLS (summary)
- **tasks**: RLS ON. Owner-only insert/update/delete (`auth.uid() = user_id`). Authenticated users may select/browse.
- **task_requests**: RLS ON. Policies:
  - Owner selects offers for their tasks (tender only).
  - Bidder selects own offers.
  - Bidder inserts own offer (tender only).
  - Owner updates offer status.

### 2.5 Triggers/Guards
- `trg_task_requests_only_for_tender` → rejects offers on `booking` tasks.
- (Optional) Guard for positive `price` and `days` (documented in setup notes).

## 3. ERD (Addendum)
```mermaid
erDiagram
  PROFILES ||--o{ TASKS : "user_id"
  CATEGORIES ||--o{ TASKS : "category_id"
  TASKS ||--o{ TASK_REQUESTS : "task_id"
  PROFILES ||--o{ TASK_REQUESTS : "bidder_id"

  PROFILES { uuid id PK }
  CATEGORIES { uuid id PK, text name }
  TASKS { uuid id PK, uuid user_id FK, text title, task_type_enum task_type, text status }
  TASK_REQUESTS { uuid id PK, uuid task_id FK, uuid bidder_id FK, bigint price, int days, text status }
```

```text
profiles (id) ──< tasks (user_id)
profiles (id) ──< task_requests (bidder_id)
categories (id) ──< tasks (category_id)
tasks (id) ──< task_requests (task_id)
```

## 4. Supabase Snippets (accurate to schema)
```sql
-- Create tender task (owner-only)
insert into public.tasks (user_id, title, description, budget, task_type, category_id)
values (auth.uid(), 'Design Logo', 'Modern logo for brand', 500000, 'tender', '<cat_id>')
returning *;

-- Submit offer (tender-only; unique pending per (task, bidder))
insert into public.task_requests (task_id, bidder_id, price, days, note)
values ('<task_id>', auth.uid(), 150000, 5, 'I can deliver fast');

-- Accept offer (owner-only)
update public.task_requests
set status = 'accepted'
where id = '<req_id>'
  and task_id in (select id from public.tasks where user_id = auth.uid());
```

```dart
final supabase = Supabase.instance.client;

// List open tasks with category name and author (as in TaskService)
final rows = await supabase
  .from('tasks')
  .select('id, title, description, budget, user_id, status, task_type, category_id, category, created_at, deadline, skills, image_paths, categories(name)')
  .eq('status', 'open')
  .order('created_at', ascending: false);

// Create task (owner)
await supabase.from('tasks').insert({
  'user_id': supabase.auth.currentUser!.id,
  'title': 'Build Website',
  'description': 'Flutter web app',
  'budget': 100000,
  'task_type': 'tender',
  'category_id': '<cat_id>',
});

// Submit request (bidder)
await supabase.from('task_requests').insert({
  'task_id': taskId,
  'bidder_id': supabase.auth.currentUser!.id,
  'price': 90000,
  'days': 7,
  'note': 'Includes revisions',
});
```

## 5. Error Handling (addendum)
| Origin | Error | User-Facing Message | Mitigation |
| --- | --- | --- | --- |
| task_requests insert | `uq_task_requests_unique_pending_per_user` | "You already have a pending offer for this task." | Disable duplicate submit while pending. |
| task_requests insert | Trigger (not tender) | "Offers are only allowed on tender tasks." | Check `task_type` before enabling submit. |
| tasks/task_requests | `42501` (RLS) | "You don’t have permission for this action." | Verify role/ownership and session. |
| FK violations | `23503` | "Task or category does not exist." | Validate IDs, guard deletes. |

## 6. Extra Notes & Testing
- **Task types**: UI should hide offer flow when `task_type = 'booking'`.
- **Indexes**: Keep category and request ordering snappy via provided indexes.
- **UTC**: Convert `created_at` to local when displaying.

Testing checklist:
- Create tender task → appears in open list.
- Submit offer → one pending per (task, bidder) enforced.
- Accept offer as owner → status updates; downstream chat/booking flows proceed.
- Try offer on booking task → rejected by trigger.
- Non-owner updates → denied by RLS.
