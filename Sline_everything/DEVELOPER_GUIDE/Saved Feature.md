Perfect 🚀 Thanks for sending all the files for the Saved Module.
I’ll now generate a clean, professional Developer Guide section in the same style as Booking, Chat, Favorites, Home, and Profile.

⸻

💾 Saved Module – Developer Guide

1. Human Explanation

The Saved Module allows users (primarily Clients) to bookmark tasks for later reference.
It works like a “favorites list” but for tasks, making it easier to keep track of interesting jobs without submitting an offer immediately.

Why it exists:
	•	Clients may want to browse tasks and save some before deciding which to pursue.
	•	It improves user experience by enabling a quick way to organize and revisit potential opportunities.
	•	Saved tasks are private (each user only sees their own saved tasks).

User Flow:
	1.	A Client browses available tasks.
	2.	They tap “Save” on a task → it is stored in the saved_tasks table.
	3.	Later, they open the Saved Tasks screen to view, manage, or remove saved tasks.
	4.	From there, they can navigate directly to task details.

⸻

2. Database & Supabase Mapping

Table: saved_tasks

Column	Type	Purpose / Usage	Notes
id	uuid PK	Unique identifier for each saved task	Auto-generated
user_id	uuid FK → profiles.id	The Client who saved the task	Enforced by RLS
task_id	uuid FK → tasks.id	The Task being saved	Prevents duplicates with unique constraint
created_at	timestamptz	Timestamp when the task was saved	Default now()

RLS Policies

-- Only owner can view their saved tasks
create policy "Saved tasks are viewable by owner"
on saved_tasks for select
using (user_id = auth.uid());

-- Only owner can insert
create policy "Users can save tasks for themselves"
on saved_tasks for insert
with check (user_id = auth.uid());

-- Only owner can delete
create policy "Users can remove their saved tasks"
on saved_tasks for delete
using (user_id = auth.uid());

Constraints
	•	Unique (user_id, task_id) → prevents saving the same task multiple times.

⸻

3. File Inventory

File	Role
saved_tasks_controller.dart	Manages state: fetch saved tasks, add/remove tasks, handle loading & errors.
saved_tasks_service.dart	Supabase integration (CRUD operations: select, insert, delete).
saved_task_model.dart	Dart model for a saved task record (id, userId, taskId, createdAt).
saved_tasks_screen.dart	UI screen listing all saved tasks with options to remove or navigate to task details.
saved_task_tile.dart	UI widget rendering a single saved task card.
saved_routes.dart	Defines navigation routes for accessing Saved Tasks within the app.


⸻

4. ERD Diagram

Mermaid

erDiagram
  profiles {
    uuid id PK
    text full_name
  }
  tasks {
    uuid id PK
    text title
  }
  saved_tasks {
    uuid id PK
    uuid user_id FK
    uuid task_id FK
    timestamptz created_at
  }

  profiles ||--o{ saved_tasks : "user_id"
  tasks ||--o{ saved_tasks : "task_id"

ASCII Fallback

profiles (id) ──< saved_tasks (user_id)
tasks (id)    ──< saved_tasks (task_id)


⸻

5. Supabase Snippets

SQL

-- Save a task
insert into saved_tasks (user_id, task_id)
values (auth.uid(), '<task_id>');

-- Fetch saved tasks
select * from saved_tasks
where user_id = auth.uid()
order by created_at desc;

-- Remove a saved task
delete from saved_tasks
where user_id = auth.uid() and task_id = '<task_id>';

Dart (supabase_flutter)

// Save a task
await supabase.from('saved_tasks').insert({
  'user_id': supabase.auth.currentUser!.id,
  'task_id': taskId,
});

// Fetch saved tasks
final rows = await supabase
    .from('saved_tasks')
    .select('*, tasks(title, description)')
    .eq('user_id', supabase.auth.currentUser!.id)
    .order('created_at', ascending: false);

// Remove saved task
await supabase.from('saved_tasks')
    .delete()
    .eq('user_id', supabase.auth.currentUser!.id)
    .eq('task_id', taskId);


⸻

6. Error Handling

Error	Cause	User-Friendly Message
duplicate key value violates unique constraint	User tried to save the same task twice	“This task is already in your saved list.”
permission denied for table saved_tasks	Tried accessing another user’s saved tasks	“You can only view your own saved tasks.”
row-level security policy violation	Supabase blocked insert/delete for non-owner	“Access denied. Please log in again.”
foreign key violation	Task no longer exists in tasks	“This task is no longer available.”


⸻

7. Extra Notes
	•	Privacy: Saved tasks are private to each user; not visible to others.
	•	Caching: Controller can cache saved tasks locally for faster UI.
	•	Extensibility: Could support categories/tags later.
	•	Testing Checklist:
	1.	Save a task → verify it appears in Saved screen.
	2.	Try saving the same task twice → expect error.
	3.	Remove a saved task → confirm removal.
	4.	Access saved tasks from another account → should not be visible.
	5.	Task deleted by Admin → ensure it disappears gracefully from Saved list.

⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻
