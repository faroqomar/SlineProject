⸻

  ✅ That’s the full documentation for Categories.
 
 ⸻
 
 # Categories Feature Reference
 
 ## 1. Human Explanation
 The categories module provides a read-mostly catalog of service categories (e.g., "Design", "Development"). It powers dropdowns and filters in `tasks` creation and browsing. Admins seed and manage categories; regular users only read them. The feature is implemented with MVVM: `CategoriesViewModel` coordinates reads via `CategoriesRepository` → `CategoriesService`, and UI in `categories_screen.dart` remains declarative.
 
 ## 2. Database & Supabase Mapping
 
 ### 2.1 `public.categories`
 | Column | Type | Purpose / Usage | Notes |
 | --- | --- | --- | --- |
 | `id` | `uuid` (PK) | Category identifier | Default `gen_random_uuid()` |
 | `name` | `text` | Human-readable name | Unique (case-insensitive) via index on `lower(name)` |
 | `icon_url` | `text` | Optional icon path/URL | Nullable |
 | `created_at` | `timestamptz` | Created timestamp | Default `now()` (UTC) |
 
 ### 2.2 `public.tasks` (relevant FK)
 | Column | Type | Purpose / Usage | Notes |
 | --- | --- | --- | --- |
 | `category_id` | `uuid` (FK → `categories.id`) | Tasks link to a category | Indexed as `idx_tasks_category_id` |
 
 ### 2.3 Indexes & Constraints
 - `uq_categories_name`: `UNIQUE (lower(name))` prevents duplicates with different cases.
 - `idx_categories_name_lower`: index on `lower(name)` accelerates search/sort.
 - `idx_tasks_category_id`: speeds up task filtering by category.
 
 ### 2.4 RLS Policies (Summary)
 | Table | Action | Who | Rule / Notes |
 | --- | --- | --- | --- |
 | `public.categories` | SELECT | Authenticated | Read-only for app users |
 | `public.categories` | INSERT/UPDATE/DELETE | Admin/Service role | Managed via seeds/Dashboard (not by clients) |
 | `public.tasks` | SELECT | Authenticated | Standard app-wide policy |
 
 ## 3. File Inventory
 | File | Layer | Description |
 | --- | --- | --- |
 | `lib/features/categories/services/categories_service.dart` | Service | Executes PostgREST reads from `public.categories`, provides simple in-memory cache, and client-side search fallback. |
 | `lib/features/categories/data/categories_repository.dart` | Repository | Wraps the service, exposes `getAll`, `getById`, `getCachedOrFetch`, and surfaces `currentUser`. |
 | `lib/features/categories/viewmodels/categories_view_model.dart` | ViewModel | `ChangeNotifier` handling loading state, errors, search query, and list data. |
 | `lib/features/categories/view/categories_screen.dart` | View | Material 3 UI for listing/searching categories using the ViewModel. |
 | `lib/features/categories/models/category_model.dart` | Model | Immutable model mapping DB columns (`id`, `name`, `icon_url`, `created_at`) with UTC handling. |
 
 ## 4. ERD Diagram
 ```mermaid
 erDiagram
   CATEGORIES ||--o{ TASKS : "category_id"
 
   CATEGORIES {
     uuid id PK
     text name
     text icon_url
   }
 
   TASKS {
     uuid id PK
     uuid category_id FK
   }
 ```
 
 ```text
 categories (id, name, icon_url)
      │
      └──< tasks (category_id)
 ```
 
 ## 5. Supabase Snippets
 
 ### 5.1 SQL
 ```sql
 -- Read categories (app users)
 select id, name, icon_url from public.categories order by name asc;
 
 -- Insert a category (admin/service role only)
 insert into public.categories (name, icon_url) values ('Design', 'icons/design.png');
 
 -- Update a category name (admin only)
 update public.categories set name = 'UI/UX Design' where id = '...';
 
 -- Delete a category (admin only)
 delete from public.categories where id = '...';
 
 -- Tasks by category name
 select t.*
 from public.tasks t
 join public.categories c on c.id = t.category_id
 where lower(c.name) = lower('Design');
 ```
 
 ### 5.2 Dart (supabase_flutter)
 ```dart
 final supabase = Supabase.instance.client;
 
 // Fetch all categories ordered by name (matches CategoriesService.getAll)
 Future<List<CategoryModel>> fetchCategories({int limit = 200}) async {
   final rows = await supabase
       .from('categories')
       .select()
       .order('name', ascending: true)
       .limit(limit);
 
   return (rows as List<dynamic>)
       .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
       .toList();
 }
 
 // Get a single category by id (may return null)
 Future<CategoryModel?> getCategoryById(String id) async {
   final row = await supabase
       .from('categories')
       .select()
       .eq('id', id)
       .maybeSingle();
   return row == null ? null : CategoryModel.fromJson(row as Map<String, dynamic>);
 }
 
 // Friendly error mapping example for a write (admin-only path)
 Future<void> adminRenameCategory(String id, String newName) async {
   try {
     await supabase
         .from('categories')
         .update({'name': newName})
         .eq('id', id);
   } on PostgrestException catch (e) {
     if (e.code == '23505') {
       throw const FormatException('A category with that name already exists.');
     }
     if (e.code == '42501') {
       throw const FormatException('You do not have permission to modify categories.');
     }
     rethrow;
   }
 }
 ```
 
 ## 6. Error Handling
 | Origin | Error | User Message | Mitigation |
 | --- | --- | --- | --- |
 | Read categories | Network/timeout | "Unable to fetch categories. Check your connection." | Retry with cached data if available. |
 | Admin writes | 23505 (unique violation) | "A category with that name already exists." | Suggest a different name. |
 | Admin writes | 42501 (RLS/permission denied) | "You do not have permission to modify categories." | Use service role/admin tools. |
 | Any | 22P02 (invalid input syntax) | "Invalid identifier provided." | Validate IDs before sending. |
 
 ## 7. Extra Notes & Testing Checklist
 - **Caching**: `CategoriesService` maintains a simple in-memory cache; call `clearCache()` to refresh.
 - **UTC**: `created_at` is UTC; no conversion needed for display beyond human formatting.
 - **Search**: Service performs client-side search when SDK lacks `.ilike`; consider server-side search later.
 - **Seeding**: See `SUPABASE_SETUP.md` for seed values and indexes (`uq_categories_name`, `idx_categories_name_lower`).
 
 Testing checklist:
 - **List**: Fetch categories and verify alphabetical ordering.
 - **Search**: Apply a search query and confirm client-side filter works.
 - **Cache**: Verify `getCachedOrFetch()` returns cached data after a first load.
 - **Tasks join**: Query tasks by `category_id` and ensure correct filtering.
 - **Permission**: Attempt a write with a user token and confirm RLS denial.
