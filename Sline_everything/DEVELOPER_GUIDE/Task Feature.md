Got it ✅ — thanks for sending both halves of the Tasks module (tasks + task requests).
Here’s the professional DEVELOPER_GUIDE.md section for the Tasks module, in the same structured style we used for Booking, Chat, Favorites, Home, and Profile.

⸻

✅ Tasks Module – Developer Guide

1. Human Explanation

The Tasks module is the heart of the marketplace:
It manages the posting, browsing, and requesting of freelance tasks.
	•	Clients create tasks (title, description, budget, category, images).
	•	Freelancers browse tasks and submit offers/requests.
	•	Both interact through linked modules (Chat, Booking, Favorites).

Why it exists:
Tasks are the entry point for all interactions. Without a task, there’s no marketplace activity.

User Flow Example:
	1.	Client posts a new task.
	2.	Task is visible in listings (task cards).
	3.	Freelancer views task details.
	4.	Freelancer submits a request (price + message).
	5.	Client reviews requests → accepts one.
	6.	Accepted request triggers downstream flows (chat creation, booking).

⸻

2. Database & Supabase Mapping

2.1 Tasks Table

Column	Type	Purpose / Usage	Notes
id	uuid (PK)	Unique identifier for the task	Default gen_random_uuid()
user_id	uuid (FK)	References profiles.id (task owner/client)	RLS: must equal auth.uid() on insert/update
title	text	Task title	Required
description	text	Detailed explanation	
budget_cents	int	Budget in cents (avoids float rounding issues)	
category_id	uuid (FK)	References categories.id	
status	enum	open / assigned / closed	Controlled via triggers
created_at	timestamptz	Task creation timestamp	Default now()

2.2 Task Requests Table

Column	Type	Purpose / Usage	Notes
id	uuid (PK)	Unique request	
task_id	uuid (FK)	References tasks.id	RLS: freelancer must not be task owner
freelancer_id	uuid (FK)	References profiles.id	Must equal auth.uid() on insert
message	text	Proposal message	
price_cents	int	Freelancer’s proposed price (cents)	
status	enum	pending / accepted / rejected	Only task owner can update
created_at	timestamptz	Request creation	

2.3 Images (Storage)
	•	Bucket: task_images/
	•	Each task can have 0–N images.
	•	Signed URLs are generated for display.

2.4 RLS Policies

Tasks:

-- Only owner can insert their own task
create policy "tasks_insert_owner"
on tasks for insert
with check (user_id = auth.uid());

-- Only owner can update/delete
create policy "tasks_update_owner"
on tasks for update using (user_id = auth.uid());

Task Requests:

-- Freelancers can submit requests
create policy "requests_insert_freelancer"
on task_requests for insert
with check (freelancer_id = auth.uid());

-- Task owners can update request status
create policy "requests_update_owner"
on task_requests for update
using (task_id in (select id from tasks where user_id = auth.uid()));


⸻

3. File Inventory

File	Role / Purpose
task_service.dart	Supabase queries for tasks (CRUD: create, list, update).
task_requests_service.dart	Supabase queries for task requests (submit, update status).
task_image_service.dart	Uploads & manages task images in Supabase Storage.
create_task_screen.dart	UI for creating a new task.
task_details_screen.dart	UI showing task info + list of requests.
task_card.dart	Widget to render task preview in lists.
task_request_model.dart	Data class for task requests.
requests_list_screen.dart	UI showing all requests for a task (for client).
request_tile.dart	Widget displaying a single request.
submit_request_sheet.dart	UI bottom sheet for freelancers to submit a request.


⸻

4. ERD Diagram

erDiagram
  profiles {
    uuid id PK
    text full_name
  }
  tasks {
    uuid id PK
    uuid user_id FK
    text title
    text description
    int budget_cents
    uuid category_id FK
    task_status_enum status
  }
  task_requests {
    uuid id PK
    uuid task_id FK
    uuid freelancer_id FK
    text message
    int price_cents
    request_status_enum status
  }

  profiles ||--o{ tasks : "posts"
  tasks ||--o{ task_requests : "receives"
  profiles ||--o{ task_requests : "submits"

ASCII Fallback

profiles (id, name)
   |             \
   |              \
   |               > task_requests (task_id, freelancer_id, price, status)
   v
tasks (id, user_id, title, budget, status)


⸻

5. Supabase Snippets

SQL

-- Insert new task
insert into tasks (user_id, title, description, budget_cents, category_id)
values (auth.uid(), 'Design a logo', 'Need modern logo', 5000, '<cat_id>');

-- Submit request
insert into task_requests (task_id, freelancer_id, message, price_cents)
values ('<task_id>', auth.uid(), 'I can deliver in 3 days', 4500);

-- Accept request
update task_requests
set status = 'accepted'
where id = '<req_id>';

Dart (supabase_flutter)

// Create task
await supabase.from('tasks').insert({
  'user_id': supabase.auth.currentUser!.id,
  'title': 'Build Website',
  'description': 'Need a Flutter web app',
  'budget_cents': 100000,
});

// Submit request
await supabase.from('task_requests').insert({
  'task_id': taskId,
  'freelancer_id': supabase.auth.currentUser!.id,
  'message': 'I can do this in 2 weeks',
  'price_cents': 95000,
});

// Accept request
await supabase.from('task_requests')
  .update({'status': 'accepted'})
  .eq('id', requestId);


⸻

6. Error Handling

Error	Cause	User-Friendly Message
permission denied for table tasks	Tried editing another user’s task	“You can only manage your own tasks.”
duplicate key value violates unique	Duplicate task/request id	“This entry already exists.”
RLS violation	Non-owner updating request	“You are not allowed to modify this request.”
storage object not found	Task image deleted / expired URL	“Image not available. Please re-upload.”


⸻

7. Extra Notes
	•	Status enums: enforce state transitions (open → assigned → closed).
	•	Signed URLs: task images are private; always generate short-lived signed URLs.
	•	Budget stored as cents (int) to avoid floating-point rounding issues.
	•	Testing Checklist:
	1.	Client creates task → visible in list.
	2.	Freelancer submits request → appears under task.
	3.	Client accepts request → status changes to assigned.
	4.	Non-owner tries update → denied by RLS.
	5.	Task image loads via signed URL.

⸻

✅ With this guide, new developers (or AI assistants) can confidently implement, extend, and debug the Tasks module.

Do you want me to also separate documentation into two sub-sections (Tasks core + Task Requests), like we did with Profile + Portfolio, or keep it unified as above?✅ Perfect — thanks for sending all Task module files (both parts: tasks + task requests).
Here’s the Task Module – Developer Guide, written in the same professional style we used for Booking, Chat, Favorites, Profile, Home, and Saved:

⸻

📌 Task Module – Developer Guide

1. Human Explanation

The Task Module is the foundation of the SLine app.
It manages the job posting and offer flow between Clients and Freelancers:
	•	Client flow
• Create a new task (title, description, budget, category, images).
• Manage posted tasks, review incoming offers.
• Accept an offer → starts a conversation with the selected Freelancer.
	•	Freelancer flow
• Browse open tasks by category.
• Submit requests/offers with price & duration.
• Track request status (pending → accepted → rejected).

Why it exists:
Tasks are the central “unit of work” in the marketplace. Every booking, chat, or portfolio showcase ultimately ties back to a Task.

⸻

2. Database & Supabase Mapping

2.1 Tables & Columns

tasks

Column	Type	Purpose / Usage	Notes
id	uuid (PK)	Unique task identifier	Auto-generated
client_id	uuid (FK)	Owner (Client → profiles.id)	RLS: must equal auth.uid() on insert
title	text	Task title	Required
description	text	Detailed description	Required
category_id	uuid (FK)	Category reference	Optional but recommended
budget	int	Stored in cents (to avoid float issues)	Helpers in format_price.dart
status	text/enum	open, in_progress, completed, canceled	Controlled by triggers
created_at	timestamptz	Audit trail	Default now()


⸻

task_requests

Column	Type	Purpose / Usage	Notes
id	uuid (PK)	Unique request/offer id	Auto-generated
task_id	uuid (FK)	References tasks.id	Cascade delete
freelancer_id	uuid (FK)	Freelancer offering to do the task	Must equal auth.uid() on insert
price	int	Offer amount in cents	Required
duration	int	Duration in days (or hours, depending)	Required
status	text/enum	pending, accepted, rejected	Updated by client/freelancer actions
created_at	timestamptz	Audit trail	Default now()


⸻

2.2 RLS Policies

Tasks

-- Client can insert their own tasks
create policy "insert_own_tasks" on tasks for insert
with check (client_id = auth.uid());

-- Clients can update/delete their own tasks
create policy "update_delete_own_tasks" on tasks for update, delete
using (client_id = auth.uid());

-- Anyone authenticated can select (browse tasks)
create policy "select_all_tasks" on tasks for select using (true);

Task Requests

-- Freelancers can insert requests for tasks
create policy "insert_own_request" on task_requests for insert
with check (freelancer_id = auth.uid());

-- Clients can update request status for their tasks
create policy "client_updates_requests" on task_requests for update
using (task_id in (select id from tasks where client_id = auth.uid()));

-- Freelancers can view their own requests
create policy "view_own_requests" on task_requests for select
using (freelancer_id = auth.uid());


⸻

3. File Inventory

File	Purpose
task_controller.dart	Main state manager for creating, listing, and updating tasks.
task_filter_controller.dart	Manages filters (category, budget, status).
task_requests_controller.dart	Handles requests logic: submit offer, update status.
task_model.dart	Data model for tasks table.
task_request_model.dart	Data model for task_requests table.
task_service.dart	Supabase CRUD for tasks (insert, select, update, delete).
task_requests_service.dart	Supabase CRUD for task requests.
task_image_service.dart	Handles image uploads for tasks (Supabase storage).
create_task_screen.dart	UI for Clients to create a new task.
task_details_screen.dart	UI showing details of a task (client view + offers list).
task_card.dart	UI card for rendering a task in list/grid.
requests_list_screen.dart	UI showing requests (offers) for a task.
submit_request_sheet.dart	UI for Freelancer to submit an offer.
request_tile.dart	UI widget showing one request.


⸻

4. ERD Diagram

Mermaid

erDiagram
  profiles {
    uuid id PK
    text full_name
    text role
  }
  tasks {
    uuid id PK
    uuid client_id FK
    text title
    text description
    uuid category_id FK
    int budget
    text status
  }
  task_requests {
    uuid id PK
    uuid task_id FK
    uuid freelancer_id FK
    int price
    int duration
    text status
  }
  categories {
    uuid id PK
    text name
  }

  profiles ||--o{ tasks : "client_id"
  tasks ||--o{ task_requests : "task_id"
  profiles ||--o{ task_requests : "freelancer_id"
  categories ||--o{ tasks : "category_id"

ASCII Fallback

profiles (id, role, name)
   | \
   |  \ client_id
   |   \
   +----< tasks (id, title, desc, budget, status, category_id)
              |
              └─< task_requests (id, freelancer_id, price, duration, status)
categories (id, name) ───┘


⸻

5. Supabase Snippets

SQL

-- Create a new task
insert into tasks (client_id, title, description, category_id, budget)
values (auth.uid(), 'Design Logo', 'Need modern logo', 'cat123', 5000);

-- Submit a request
insert into task_requests (task_id, freelancer_id, price, duration)
values ('task123', auth.uid(), 4000, 7);

-- Accept a request
update task_requests set status = 'accepted'
where id = 'req123' and task_id in (
  select id from tasks where client_id = auth.uid()
);

Dart

// Create task
await supabase.from('tasks').insert({
  'client_id': supabase.auth.currentUser!.id,
  'title': titleController.text,
  'description': descController.text,
  'budget': 5000,
});

// Fetch open tasks
final tasks = await supabase.from('tasks')
    .select()
    .eq('status', 'open');

// Submit request
await supabase.from('task_requests').insert({
  'task_id': taskId,
  'freelancer_id': supabase.auth.currentUser!.id,
  'price': 4000,
  'duration': 7,
});

// Accept request (Client only)
await supabase.from('task_requests')
    .update({'status': 'accepted'})
    .eq('id', requestId);


⸻

6. Error Handling

Error	Cause	User-Friendly Message
permission denied for table tasks	RLS prevented action	“You can only manage your own tasks.”
permission denied for table task_requests	Freelancer/Client mismatch	“You are not allowed to update this request.”
duplicate key value violates unique constraint	Same freelancer tried to submit multiple requests	“You have already sent an offer for this task.”
foreign key violation	Task or category does not exist	“This task or category is invalid.”


⸻

7. Extra Notes
	•	Budget handling: Stored in cents → always use helpers to format.
	•	Images: Uploaded via task_image_service.dart to Supabase Storage.
	•	Status transitions:
	•	Task: open → in_progress → completed/canceled.
	•	Requests: pending → accepted/rejected.
	•	Integration:
	•	Accepting a request → automatically starts a Chat conversation.

✅ Testing Checklist
	1.	Client creates a task.
	2.	Freelancer sees it in the open list.
	3.	Freelancer submits request.
	4.	Client accepts → status updates.
	5.	Chat opens between Client and Freelancer.
	6.	Invalid update (wrong role) → rejected by RLS.
	7.	Delete task → cascade deletes related requests.

⸻

✅ With this guide, any developer (or AI assistant) can fully understand and work on the Task module, including how it connects to profiles, categories, and chat.

Do you want me to split this section into two parts (Tasks + Task Requests) like we did with Profile + Portfolio, or keep it unified in one section?