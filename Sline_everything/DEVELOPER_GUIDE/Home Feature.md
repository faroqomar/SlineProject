# Home Feature Reference

## 1. Human Explanation
The Home feature is the authenticated discovery landing page. It renders a searchable, filterable feed of open tasks, reuses the same underlying discovery feed contract as Tender and Booking discovery, and keeps cross-user author data behind a safe profile-summary RPC.

- UI in `lib/features/home/view/` renders search, category chips, advanced filters, and the discovery list.
- `HomeViewModel` owns the feed state and implements the shared `DiscoveryFeedViewModelContract` used by Home, Tenders, and Bookings.
- `TaskFilterViewModel` applies client-side discovery filters to the currently loaded feed window.
- `TaskService` loads open tasks with a stable composite cursor and enriches author summaries via `rpc_get_profile_summaries`.

## 2. Database & Supabase Mapping
Home does not own tables; it reads shared discovery contracts.

### 2.1 `public.tasks` (consumed)
| Column | Type | Purpose / Usage | Notes |
| --- | --- | --- | --- |
| `id` | `uuid` | Task id | Used for navigation/details and stable pagination |
| `title` | `text` | Headline | Shown in list cards |
| `description` | `text` | Summary | Displayed in `TaskCard` |
| `budget` | `numeric`/`bigint` | Price field | Formatted via `format_price.dart` |
| `user_id` | `uuid` (FK → `profiles.id`) | Author | Enriched with safe profile summary data |
| `status` | `text`/enum | Feed visibility | Home fetch uses `status = 'open'` |
| `task_type` | enum | Discovery mode | Seller-level filters exclude tenders |
| `category_id` | `uuid` (FK) | Category filter | Joined to `categories(name)` |
| `created_at` | `timestamptz` | Primary sort / cursor | Ordered `DESC`; tied rows use `id DESC` |
| `deadline` | `timestamptz` | Delivery estimate fallback | Used if booking packages do not provide delivery days |
| `packages` | `jsonb` | Booking delivery estimate | Minimum `delivery` value drives delivery-time filters |
| `image_paths` | `text[]` | Thumbnails | Rendered via signed image helpers |

### 2.2 Safe profile summary boundary
- Function: `public.rpc_get_profile_summaries(p_ids uuid[])`
- Requires: authenticated session
- Returns only safe columns:
  - `id`
  - `full_name`
  - `avatar_url`
  - `bio`
  - `active_role`
  - `skills`
  - `created_at`
  - `seller_level`

RLS summary:
- `public.tasks` discovery reads are authenticated-only after the Home hardening migration.
- Base `public.profiles` reads are self-only; Home must not read another user directly from `profiles`.

## 3. File Inventory
| File | Layer | Description |
| --- | --- | --- |
| `lib/features/home/view/home_screen.dart` | View | Search/filter shell and shared discovery list for Home. |
| `lib/features/home/view/widgets/filters_modal.dart` | Widget | Sort, budget, delivery-time, and seller-level filter sheet. |
| `lib/features/home/viewmodels/home_view_model.dart` | ViewModel | Feed owner for Home; implements shared discovery contract and logs feed events. |
| `lib/features/tasks/viewmodels/discovery_feed_view_model_contract.dart` | ViewModel contract | Shared notifier contract used by Home, Tenders, and Bookings. |
| `lib/features/tasks/viewmodels/task_filter_view_model.dart` | ViewModel | Search/category/advanced filter state over the loaded discovery window. |
| `lib/features/tasks/view/widgets/discovery_task_sliver.dart` | Widget | Shared loading/empty/list/load-more sliver. |
| `lib/features/tasks/services/task_service.dart` | Service | Queries open tasks with composite cursor and safe summary enrichment. |
| `lib/features/profile/services/profile_summary_service.dart` | Service | Calls `rpc_get_profile_summaries` for cross-user summaries. |

## 4. ERD Diagram (Context)
```mermaid
erDiagram
  CATEGORIES ||--o{ TASKS : "category_id"

  CATEGORIES { uuid id PK, text name }
  TASKS { uuid id PK, uuid user_id FK, uuid category_id FK, text title, text description, timestamptz created_at }
```

```text
categories (id) ──< tasks (category_id)
```

## 5. Supabase Snippets

### 5.1 Dart (reads used by Home)
```dart
final rows = await supabase
  .from('tasks')
  .select('id, title, description, budget, user_id, status, task_type, category_id, category, created_at, deadline, skills, image_paths, packages, categories(name)')
  .eq('status', 'open')
  .order('created_at', ascending: false)
  .order('id', ascending: false);

final summaries = await supabase.rpc('rpc_get_profile_summaries', params: {
  'p_ids': rows.map((row) => row['user_id']).toSet().toList(),
});
```

### 5.2 Filter logic (ViewModel collaboration)
```dart
await feedViewModel.loadFeaturedTasks(
  filterController: context.read<TaskFilterViewModel>(),
  surface: 'home',
);

context.read<TaskFilterViewModel>().applyAdvancedFilters(
  deliveryTimes: const [TaskFilterViewModel.deliveryUpTo3Days],
  sellerLevels: const [TaskFilterViewModel.sellerLevel2],
);
```

## 6. Error Handling
| Origin | Error | User Message | Mitigation |
| --- | --- | --- | --- |
| Task fetch | Network/PostgREST | "Unable to load tasks." | Retry with pull-to-refresh; inspect `home_feed_load_failed` logs. |
| Summary RPC | Auth/RPC failure | "Author profile unavailable." | Render placeholders and inspect `profile_summary_rpc_failed`. |
| RLS | Permission denied | "Please sign in to view tasks." | Ensure valid session and hardened policies are deployed. |

## 7. Extra Notes & Testing Checklist
- Home, Tenders, and Bookings share the same feed owner through `DiscoveryFeedViewModelContract`; they do not own separate feed stores.
- Delivery-time and seller-level filters operate on the loaded discovery window, not the full corpus.
- Bookmark state is global through `SavedTasksViewModel`; Home no longer creates a local provider.

Testing checklist:
- Home initial load renders tasks and profile header through `loadHeaderProfile()`.
- Reaching the end of the list triggers exactly one load-more request.
- Delivery-time and seller-level filters change visible results as expected.
- Tenders and Bookings reuse the same feed state without creating duplicate providers.
- Cross-user author cards still render after `profiles` base-table reads are hardened.
