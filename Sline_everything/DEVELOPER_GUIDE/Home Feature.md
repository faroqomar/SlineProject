

# Home Feature Reference

## 1. Human Explanation
The Home feature is the authenticated landing page. It shows a searchable, filterable feed of featured/open tasks and routes to other modules (create task, saved tasks, task details). It follows MVVM:
- UI in `lib/features/home/view/` renders search/filter controls and task list.
- `HomeViewModel` loads/refreshes featured tasks and updates `TaskFilterViewModel`.
- `TaskService` provides the Supabase reads for tasks and joins `profiles` for author display.

## 2. Database & Supabase Mapping
Home does not own tables; it reads from feature tables to populate the dashboard.

### 2.1 `public.tasks` (consumed)
| Column | Type | Purpose / Usage | Notes |
| --- | --- | --- | --- |
| `id` | `uuid` | Task id | Used for navigation/details |
| `title` | `text` | Headline | Shown in list cards |
| `description` | `text` | Summary | Displayed in `TaskCard` |
| `budget` | `numeric`/`bigint` | Price field | Formatted via `format_price.dart` |
| `user_id` | `uuid` (FK → `profiles.id`) | Author | Joined to display name/avatar |
| `status` | `text`/enum | Filters (e.g., `open`) | Home fetch uses `status = 'open'` |
| `task_type` | enum | Context | E.g., `tender` |
| `category_id` | `uuid` (FK) | Category filter | Joined to `categories(name)` |
| `created_at` | `timestamptz` | Sort by newest | UTC |
| `image_paths` | `text[]` | Thumbnails | Shown by `TaskCard` via signed images |

Related tables: `public.profiles` for author name/avatar, `public.categories` for name label.

RLS: Reads allowed for authenticated users; writes follow feature-specific policies in Tasks.

## 3. File Inventory
| File | Layer | Description |
| --- | --- | --- |
| `lib/features/home/view/home_screen.dart` | View | Dashboard UI with search, category filter, refresh, and navigation to details/create/saved tasks. |
| `lib/features/home/view/widgets/service_card.dart` | Widget | Reusable card (if used in home) for linking to modules. |
| `lib/features/home/viewmodels/home_view_model.dart` | ViewModel | `ChangeNotifier` that loads/refreshes featured tasks and passes them to `TaskFilterViewModel`. |
| `lib/features/tasks/viewmodels/task_filter_view_model.dart` | ViewModel | Holds filtered list, search text, and category filter state used by `HomeScreen`. |

## 4. ERD Diagram (Context)
```mermaid
erDiagram
  PROFILES ||--o{ TASKS : "user_id"
  CATEGORIES ||--o{ TASKS : "category_id"

  PROFILES { uuid id PK, text full_name, text avatar_url }
  CATEGORIES { uuid id PK, text name }
  TASKS { uuid id PK, uuid user_id FK, uuid category_id FK, text title, text description, timestamptz created_at }
```

```text
profiles (id) ──< tasks (user_id)
categories (id) ──< tasks (category_id)
```

## 5. Supabase Snippets

### 5.1 Dart (reads used by Home)
```dart
final supabase = Supabase.instance.client;

// Fetch open tasks with category name and author info (as in TaskService)
final rows = await supabase
  .from('tasks')
  .select('id, title, description, budget, user_id, status, task_type, category_id, category, created_at, deadline, skills, image_paths, categories(name)')
  .eq('status', 'open')
  .order('created_at', ascending: false);
```

### 5.2 Filter logic (ViewModel collaboration)
```dart
// HomeViewModel.loadFeaturedTasks(...) populates TaskFilterViewModel
await homeViewModel.loadFeaturedTasks(filterController: context.read<TaskFilterViewModel>());
```

## 6. Error Handling
| Origin | Error | User Message | Mitigation |
| --- | --- | --- | --- |
| Task fetch | Network/PostgREST | "Unable to load tasks." | Retry with pull-to-refresh; log via `AppLogger`. |
| Profile join | Missing profile | "Author profile unavailable." | Render placeholder name/avatar. |
| RLS | Permission denied | "Please sign in to view tasks." | Ensure valid session. |

## 7. Extra Notes & Testing Checklist
- **Performance**: Avoid N+1 joins in UI; TaskService already batches and hydrates author names/avatars.
- **UTC**: Times are UTC; convert with `formatUtcToLocal()` for display.
- **Saved tasks**: Home integrates with `SavedTasksViewModel` to sync bookmark icons after refresh.

Testing checklist:
- Home loads with featured open tasks on first display.
- Search and category filter update the list immediately.
- Pull-to-refresh reloads tasks and syncs saved-state icons.
- Navigate to task details and back; state is preserved.
- Create a new task → returning to Home refreshes and shows it if `open`.
