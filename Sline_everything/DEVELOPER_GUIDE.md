# 🧭 Developer Guide – SLine App

This document is the single source of truth for understanding the SLine project.  
It explains the architecture, folder structure, feature modules, and how each part connects to Supabase.  

Use this file as a **map** when making changes or adding new features.

Perfect — you want the Core module documented in the same professional, structured way we did for Booking.
Here’s the proposed draft for DEVELOPER_GUIDE.md (Core section):

⸻

🧩 Core Module (lib/core/)

⸻

📚 Purpose
	•	Provide shared services like Supabase client, logging, and helpers.
	•	Define global models that are used across multiple features.
	•	Expose UI widgets that are not feature-specific (bottom nav, signed image loaders).
	•	Centralize utilities (formatting, theming).

⸻

🔑 Supabase / State / Services

File	Purpose
supabase_config.dart	Initializes the global Supabase client with project URL & anon key. Used by all services.
navigation_provider.dart	Global state for current tab (bottom navigation). Backed by ChangeNotifier.
logger_service.dart	Wrapper around logger with pretty print formatting. Debug-only logging enabled via kDebugMode.


⸻

🎨 Theming & Constants

File	Purpose
app_colors.dart	Centralized Material 3 color definitions. Exposes constants like AppColors.primary, surfaceContainer, etc.


⸻

🗂️ Utilities

File	Purpose
format_date.dart	Helpers for formatting timestamps. Includes formatUtcToLocal and formatRangeUtcToLocal.
format_price.dart	Converts integer-based budget/prices (stored as cents) into human-readable strings.


⸻

👤 Global Models

File	Purpose
user_profile.dart	Defines the UserProfile model mapped to Supabase profiles table (id, full_name, avatar_url). Provides fromJson and toJson.


⸻

🖼️ Shared Widgets

File	Purpose
custom_bottom_nav_bar.dart	Custom Material 3 NavigationBar used in MainNavigationScreen. Binds with NavigationProvider.
signed_avatar.dart	Displays user avatars. Accepts Supabase storage path OR legacy public URL. Uses signed URL generation + caching.
signed_image.dart	Generic signed image renderer for Supabase storage paths (with cache + placeholder).


⸻

🔗 Supabase Links

Core does not define new database tables, but it connects to several Supabase resources:

Supabase Resource	Usage
public.profiles	Source of truth for UserProfile.
Storage bucket: avatars	Used by SignedAvatar + ProfileController. Signed URLs generated client-side.
Any feature service	All services import supabase_config.dart to access the Supabase client.


⸻

📊 Example Snippets

1. Access Supabase globally

import 'package:sline_app/core/services/supabase_config.dart';

final response = await supabase.from('profiles').select().eq('id', userId);

2. Use Logger

import 'package:sline_app/core/services/logger_service.dart';

AppLogger.i("Fetching tasks...");

3. Date formatting

final formatted = formatUtcToLocal(DateTime.now().toUtc());


⸻

🔄 Relationships
	•	Profiles (DB) ↔ UserProfile model ↔ SignedAvatar / SignedImage.
	•	Navigation ↔ NavigationProvider ↔ CustomBottomNavBar.
	•	Supabase client ↔ supabase_config.dart ↔ All feature services.


⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻

🔑 Auth Feature

1. Human-Friendly Overview

The Auth feature is responsible for user authentication and session lifecycle. It provides signup and login flows, integrates directly with Supabase Auth (email/password), and ensures that the current session is always available across the app.

Without authentication, users cannot interact with tasks, chat, bookings, or profile data.
	•	Login: Collects email + password → validates with Supabase → stores session.
	•	Signup: Creates a new Supabase user → inserts a linked row into profiles.
	•	Session Handling: Listens to Supabase auth state changes and keeps UI in sync.

⸻

2. Supabase Variables & DB Dependencies

Variable / Field	Location (Supabase)	Purpose	Notes
auth.users	Supabase built-in	Stores core identity	Immutable id (uuid) is FK for profiles and other tables
profiles.id	FK → auth.users.id	Extended profile info	All app features reference this
profiles.full_name	profiles table	Display name	Optional during signup
profiles.avatar_url	profiles table	Path in avatars bucket	Used with signed URLs
auth.session	SDK (client)	Current user session	Needed for RLS on every query


⸻

3. File Map

File	Role	What It Contains
features/auth/presentation/login_screen.dart	UI	Login form, input validation, calls AuthController.login()
features/auth/presentation/signup_screen.dart	UI	Signup form, collects credentials, calls AuthController.signup()
features/auth/services/auth_service.dart	Service	Wraps Supabase SDK methods: signInWithPassword, signUp, signOut, currentUser
features/auth/data/auth_repository.dart	Repository	Converts raw Supabase responses into app-level results, central place for error mapping
features/auth/controllers/auth_controller.dart	Controller	State management (loading, errors, session user), notifies listeners, connects UI ↔ Service/Repo


⸻

4. Error Handling Conventions
	•	Service Level (auth_service.dart)
	•	Catch Supabase exceptions (AuthException)
	•	Return them as error objects instead of throwing raw exceptions.
	•	Repository Level (auth_repository.dart)
	•	Map Supabase error messages → human-friendly text.
	•	Example: "Invalid login credentials" → "Email or password is incorrect"
	•	Controller Level (auth_controller.dart)
	•	Store error in authError field.
	•	Call notifyListeners() to update the UI.
	•	UI Level (login_screen.dart, signup_screen.dart)
	•	Display error using a SnackBar or inline text under input fields.
	•	Show a loading spinner when authController.isLoading is true.

⸻

5. State Flow Diagram

Signup Flow (similar for Login):

[User enters form data]
        │
        ▼
   AuthController.signup()
        │
        ▼
   AuthRepository.signup()
        │
        ▼
   AuthService.signUp()  --->  Supabase Auth (signUp API)
        │
        ▼
   Repository maps result (success/error)
        │
        ▼
   Controller updates state (user or error)
        │
        ▼
   UI listens → shows success (navigate) or error (SnackBar)

This guarantees a clear separation of concerns:
UI never talks directly to Supabase, only to the Controller → Repository → Service chain.

⸻

6. Example Supabase Queries

Signup

final response = await supabase.auth.signUp(
  email: email,
  password: password,
  data: {'full_name': fullName}, // optional metadata
);

Login

final response = await supabase.auth.signInWithPassword(
  email: email,
  password: password,
);

Get Current User

final user = supabase.auth.currentUser;

Logout

await supabase.auth.signOut();


⸻

7. ERD (Simplified)

auth.users (built-in Supabase)
        │
        ▼
profiles (app-owned table)
 id (PK, FK → auth.users.id)
 full_name
 avatar_url
 created_at


⸻

✅ With this section, any developer (or AI assistant) will know:
	•	What the Auth feature does
	•	Where Supabase connections are
	•	How error handling flows
	•	The state pipeline (UI → Controller → Repo → Service → Supabase)
	•	Which files to open for what purpose
	•	Sample queries and schema diagram

⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻

📅 Booking Feature

1) Human-Readable Overview

The Booking feature lets a client reserve a provider’s available time slot for a task.
It covers two flows:
	•	Provider flow: create/manage availability slots (open or blocked), see incoming bookings, confirm or complete work.
	•	Client flow: browse a provider’s available slots, request a booking for a specific task, and cancel if needed.

Key design choices:
	•	All timestamps are stored in UTC; UI always displays local time.
	•	A slot can be booked by at most one active booking (pending/confirmed) — enforced with a unique partial index.
	•	RLS ensures each party only sees/edits what they own (provider vs. client rules).

⸻

2) Supabase Mapping (Tables, Columns, Policies)

2.1 Tables & Columns

Table	Column	Type	Purpose / Notes
availability_slots	id	uuid PK	Slot identifier
	provider_id	uuid FK → profiles.id	Owner of the slot (the freelancer)
	starts_at / ends_at	timestamptz	UTC time window; ends_at > starts_at check
	is_blocked	boolean	True = not bookable (provider blocks personal time)
	created_at	timestamptz	Audit trail
bookings	id	uuid PK	Booking identifier
	task_id	uuid FK → tasks.id	Linked task
	provider_id	uuid FK → profiles.id	Provider receiving the booking
	client_id	uuid FK → profiles.id	Client making the booking
	slot_id	uuid FK → availability_slots.id	The reserved slot
	status	booking_status_enum	pending → confirmed → completed (or canceled)
	note	text	Optional client message
	created_at	timestamptz	Audit trail

2.2 Enums

Enum	Values	Notes
booking_status_enum	pending, confirmed, canceled, completed	Guards state transitions in trigger

2.3 Indexes & Constraints
	•	No double booking on the same slot:

CREATE UNIQUE INDEX IF NOT EXISTS uq_bookings_slot_active
  ON public.bookings (slot_id)
  WHERE status IN ('pending','confirmed');


	•	Performance indexes:
	•	idx_slots_provider_starts (provider_id, starts_at)
	•	idx_bookings_client_created (client_id, created_at desc)
	•	idx_bookings_provider_created (provider_id, created_at desc)

2.4 RLS Policies (Summary)

Table	Policy	Who	Action	Rule
availability_slots	slots_select_all	authenticated	SELECT	true
	slots_cud_owner	authenticated	ALL	provider_id = auth.uid()
bookings	bookings_select_owner_or_client	authenticated	SELECT	provider_id = auth.uid() OR client_id = auth.uid()
	bookings_insert_client_only	authenticated	INSERT	client_id = auth.uid() AND slot not already active
	bookings_update_roles	authenticated	UPDATE	Provider can confirm/complete; Client can cancel

2.5 Triggers / Business Guards
	•	No overlapping open slots for the same provider:
	•	Trigger: trg_no_overlap_slots → fn_reject_overlapping_slots
	•	Booking status transitions guard:
	•	Trigger: trg_booking_guard → fn_booking_guard
	•	Allowed:
	•	pending → confirmed (provider) / canceled (client)
	•	confirmed → completed (provider) / canceled (client)

⸻

3) File Inventory (Flutter)

File	Role	What it does
features/booking/services/booking_service.dart	Service	Supabase queries for slots & bookings (list/create/update). Converts maps ↔ models.
features/booking/controllers/booking_controller.dart	Controller	ChangeNotifier state: lists, loading flags, pagination, mutations (create slot, book, confirm, cancel).
features/booking/models/slot_model.dart	Model	AvailabilitySlot (id, providerId, startsAt, endsAt, isBlocked). UTC serialization helpers.
features/booking/models/booking_model.dart	Model	Booking (id, taskId, providerId, clientId, slotId, status, note). Enum mapping.
features/booking/presentation/availability_screen.dart	UI	Provider calendar/list view. Create/block slots. Pull-to-refresh + infinite scroll.
features/booking/presentation/add_slot_sheet.dart	UI	Bottom sheet to pick local start/end, convert to UTC, create slot or block time.
features/booking/presentation/booking_sheet.dart	UI	Client-side flow to book a slot for a given task (+ optional note).
features/booking/presentation/bookings_list_screen.dart	UI	Tabs: “As Client” & “As Provider”; status filters; pagination; actions (confirm/complete/cancel).

Convention: Service owns Supabase calls, Controller owns UI state + orchestration, UI is dumb (reads state, triggers controller methods).

⸻

4) ERD (Mini)

Mermaid

erDiagram
  PROFILES ||--o{ AVAILABILITY_SLOTS : "provider_id"
  PROFILES ||--o{ BOOKINGS : "provider_id / client_id"
  AVAILABILITY_SLOTS ||--o{ BOOKINGS : "slot_id"
  TASKS ||--o{ BOOKINGS : "task_id"

  PROFILES {
    uuid id PK
    text full_name
  }
  AVAILABILITY_SLOTS {
    uuid id PK
    uuid provider_id FK
    timestamptz starts_at
    timestamptz ends_at
    bool is_blocked
  }
  BOOKINGS {
    uuid id PK
    uuid task_id FK
    uuid provider_id FK
    uuid client_id FK
    uuid slot_id FK
    booking_status_enum status
    text note
  }
  TASKS {
    uuid id PK
    uuid user_id
  }

ASCII (fallback)

profiles (id) ──< availability_slots (provider_id)
     │                     │
     │                     └─< bookings (slot_id, provider_id, client_id)
     │
tasks (id) ────────────────────────────────┘ (task_id)


⸻

5) Example SQL & Supabase Dart Snippets

5.1 Create Slot (Provider)

Dart (Service)

final insert = await supabase
  .from('availability_slots')
  .insert({
    'provider_id': providerId, // must equal auth.uid() under RLS
    'starts_at'  : startsUtc.toIso8601String(),
    'ends_at'    : endsUtc.toIso8601String(),
    'is_blocked' : isBlocked,
  })
  .select()
  .single();

5.2 List Provider Slots (Paged)

final rows = await supabase
  .from('availability_slots')
  .select()
  .eq('provider_id', providerId)
  .gte('starts_at', sinceUtc.toIso8601String())
  .order('starts_at')               // server-side sort
  .range(offset, offset + limit - 1);

5.3 Book a Slot (Client)

final row = await supabase
  .from('bookings')
  .insert({
    'task_id'    : taskId,
    'provider_id': providerId,
    'client_id'  : clientId,   // must equal auth.uid() under RLS
    'slot_id'    : slotId,
    'note'       : note,
  })
  .select()
  .single();

5.4 List My Bookings (As Client)

final rows = await supabase
  .from('bookings')
  .select("""
    *,
    availability_slots!inner(*)
  """)
  .eq('client_id', myId) // RLS also enforces this
  .order('created_at', ascending: false)
  .range(offset, offset + limit - 1);

5.5 Confirm / Complete (Provider) & Cancel (Client)

// Provider confirms
await supabase.from('bookings').update({'status': 'confirmed'}).eq('id', bookingId);

// Provider completes
await supabase.from('bookings').update({'status': 'completed'}).eq('id', bookingId);

// Client cancels
await supabase.from('bookings').update({'status': 'canceled'}).eq('id', bookingId);

The trigger (fn_booking_guard) and RLS (bookings_update_roles) jointly ensure only valid transitions by the authorized party.

⸻

6) Error Handling & Common Pitfalls

Client/Controller conventions
	•	Map Postgres error codes (e.g., 23505 unique violation) → user-friendly messages:
	•	“This time slot is already booked. Please choose another.”
	•	For overlap trigger errors on slot creation:
	•	“This slot overlaps with an existing one.”

Common pitfalls
	•	Timezone bugs: Always convert UI local → UTC before insert; and UTC → local for display.
	•	RLS denials:
	•	Creating a slot with mismatched provider_id (must be auth.uid()).
	•	Inserting a booking with client_id != auth.uid().
	•	Ordering + Pagination: Apply filters before .order(); use range() instead of client-side slicing.
	•	Double booking race: Unique partial index on bookings(slot_id) with active statuses prevents it.

⸻

7) Testing Checklist (Manual / Automated)
	•	Provider creates a non-overlapping open slot → appears in list.
	•	Provider tries overlapping slot → fails with friendly error.
	•	Client books an open slot → status pending.
	•	Provider confirms, then completes → allowed.
	•	Client cancels from pending/confirmed → allowed.
	•	Second client tries to book the same slot while active → fails.
	•	Lists (as Client / as Provider) show correct items with correct sorting & pagination.
	•	All date/times render in local timezone.

⸻

8) UI Flow (High-level)
	•	AvailabilityScreen (provider):
	•	FAB → AddSlotSheet → create open/blocked slot → refresh → list updates.
	•	TaskDetails → BookingSheet (client):
	•	Pick provider slot → submit booking (pending) → success SnackBar.
	•	BookingsListScreen:
	•	Tabs: As Client / As Provider → action chips (Confirm, Complete, Cancel).

⸻

9) Integration Notes
	•	Works alongside Tasks: A booking always references a task (task_id).
	•	Compatible with Chat: You can later notify participants on status changes with Realtime or Notifications.
	•	Plays well with Profile: Avatars, names, etc., pulled via joins or client caches.

⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻


⸻

🗂 Categories Module

🔰 Overview

The Categories module is a lightweight part of the system that defines service categories (e.g., “Design”, “Development”, “Marketing”) that freelancers can attach to their tasks or profiles.
It’s essentially a reference table + retrieval service, used across Tasks, Profiles, and Search features.

This module is read-mostly:
	•	Admin defines the available categories (via DB seeding or Supabase dashboard).
	•	Users only fetch and display categories, not edit them directly (in MVP).

⸻

📊 Supabase Data Model

Table	Field Name	Type	Purpose
categories	id	UUID/Int	Unique identifier for the category
	name	Text	Display name of the category (e.g. “Design”)
	icon	Text/URL	(Optional) reference to an icon/image stored in storage
	created_at	Timestamp	Auto-generated

🔗 Relationships:
	•	categories are referenced by tasks.category_id or profiles.specialization.

⸻

🧩 Files

File	Purpose
category_model.dart	Defines the Category data model → parses from Supabase row (id, name, icon).
categories_service.dart	Service layer → fetch categories from Supabase. Handles DB queries & error handling.


⸻

📄 category_model.dart
	•	Simple data class (Category) with fields:
	•	id, name, icon.
	•	Provides:
	•	fromJson(Map<String, dynamic>) → parse from Supabase response.
	•	toJson() → map back to JSON when needed.

⸻

📄 categories_service.dart
	•	Handles Supabase queries:
	•	getCategories() → returns List<Category> from the categories table.
	•	Abstracts DB calls so UI/controllers don’t directly query Supabase.

Example:

final response = await supabase.from('categories').select();
return response.map((row) => Category.fromJson(row)).toList();


⸻

⚙️ API / Query Snippets
	•	Get all categories:

select * from categories order by name;

	•	Insert new category (admin only):

insert into categories (name, icon) values ('Design', '🎨');


⸻

🧭 Usage Flow
	1.	UI Screens (like Task Creation, Profile setup) → ask for available categories.
	2.	Controller calls CategoriesService.getCategories().
	3.	Supabase returns list → mapped into Category model.
	4.	Dropdowns / Filters are populated dynamically.

⸻

✅ That’s the full documentation for Categories.

⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻

Got it ✅ I’ll merge and re-organize both drafts you shared into one authoritative Chat Module section so nothing is missed.
Here’s the final cleaned version for DEVELOPER_GUIDE.md:

⸻

📩 Chat Module – Developer Guide

1. Human Explanation

The Chat Module enables real-time communication between clients and freelancers.
It supports:
	•	Conversations: One-to-one messaging tied either to a task (job discussion) or direct client–freelancer contact.
	•	Messages: Text and file-based communication.
	•	Attachments: Images/files uploaded to Supabase Storage with signed URLs.
	•	UI Widgets: Message bubbles, attachment previews, and list screens for conversations.

User Flow
	1.	A client posts a task.
	2.	A freelancer submits an offer.
	3.	When the offer is accepted → a conversation opens.
	4.	Both parties can exchange text and attachments in this chat.

⸻

2. Database & Supabase Mapping

Column / Table	Type	Purpose / Usage	Notes
conversations.id	uuid	Primary key for a chat	RLS: must include current user in members
conversations.task_id	uuid	Links conversation to a task	Optional
conversations.members	uuid[]	Array of profile IDs (client + freelancer)	Used for RLS checks
messages.id	uuid	Primary key	
messages.conversation_id	uuid	FK → conversations.id	
messages.sender_id	uuid	FK → profiles.id	
messages.content	text	Message text	Nullable if attachment-only
messages.attachment_url	text	Signed URL for file in attachments bucket	
messages.created_at	timestamptz	Ordering + history	Default now()
storage.objects (attachments)	file	Actual uploaded files	RLS: allow read/write only for conversation members

Example RLS Policies

-- Conversations: only participants can read
create policy "Users can read their conversations"
on conversations for select
using (auth.uid() = any(members));

-- Messages: only participants can insert
create policy "Users can send messages in joined conversations"
on messages for insert
with check (
  auth.uid() = sender_id
  and auth.uid() = any(
    (select members from conversations where id = conversation_id)
  )
);


⸻

3. File Inventory

File	Role
chat_controller.dart	Orchestrates chat logic (loading conversations/messages, sending, updating state).
conversation_model.dart	Data model for conversations. Contains members, optional task link.
message_model.dart	Data model for messages (content, sender, attachment).
message_service.dart	CRUD operations for messages in Supabase.
attachment_service.dart	Manages storage operations (upload, delete, signed URLs).
attachment_payload.dart	Metadata wrapper for attachments (path, mime type, etc.).
attachment_exceptions.dart	Custom errors for attachments (invalid type, oversize, etc.).
compress_service.dart	Compresses images before upload.
pick_image_service.dart	Wraps image_picker for selecting local images.
upload_service.dart	Low-level file upload logic to Supabase Storage.
send_attachment_usecase.dart	Combines compression + upload + message creation.
mime_utils.dart	Helpers to detect and validate MIME types.
attachment_message_tile.dart	UI widget to render an attachment in a chat bubble.
message_bubble.dart	UI for text messages with sender/receiver styling.
chat_screen.dart	Screen for a single conversation (messages list + input bar).
messages_screen.dart	Lists all conversations.


⸻

4. ERD Diagram

Mermaid

erDiagram
  profiles {
    uuid id PK
    text full_name
    text avatar_url
  }
  conversations {
    uuid id PK
    uuid task_id FK
    uuid[] members
  }
  messages {
    uuid id PK
    uuid conversation_id FK
    uuid sender_id FK
    text content
    text attachment_url
    timestamptz created_at
  }
  tasks {
    uuid id PK
    text title
  }

  profiles ||--o{ conversations : "members"
  conversations ||--o{ messages : "has"
  profiles ||--o{ messages : "sends"
  tasks ||--o{ conversations : "optional link"

ASCII Fallback

profiles (id, name, avatar)
   |         \
   |          \ sends
   |           \
conversations ----< messages
   | (members[])     (content, attachment_url)
   |
   +-- tasks (optional link)


⸻

5. Supabase Snippets

SQL

-- Insert new conversation
insert into conversations (id, members, task_id)
values (gen_random_uuid(), array['<client>', '<freelancer>'], '<task_id>');

-- Insert new message
insert into messages (conversation_id, sender_id, content)
values ('<conv_id>', auth.uid(), 'Hello!');

-- Query messages
select * from messages
where conversation_id = '<conv_id>'
order by created_at;

Dart (supabase_flutter)

// Send text message
await supabase.from('messages').insert({
  'conversation_id': convId,
  'sender_id': supabase.auth.currentUser!.id,
  'content': messageText,
});

// Upload + send attachment
final file = File(pickedImage.path);
final path = 'attachments/${supabase.auth.currentUser!.id}/${DateTime.now().toIso8601String()}';
await supabase.storage.from('attachments').upload(path, file);

final signedUrl = await supabase.storage
    .from('attachments')
    .createSignedUrl(path, 3600);

await supabase.from('messages').insert({
  'conversation_id': convId,
  'sender_id': supabase.auth.currentUser!.id,
  'attachment_url': signedUrl,
});


⸻

6. Error Handling

Error	Cause	User-friendly message
permission denied for table messages	User not in conversation	“You are not allowed to send messages in this chat.”
new row violates row-level security	RLS policy blocked	“Access denied: not a participant in this conversation.”
storage object not found	Attachment deleted or expired signed URL	“This file is no longer available.”
payload too large	File exceeds allowed size	“This file is too large. Please compress or choose another.”
invalid input syntax for uuid	Wrong conversation/user ID	“Something went wrong with chat IDs. Please try again.”
Invalid file type	Non-supported extension	“Unsupported file type. Please upload an image or document.”


⸻

7. Extra Notes
	•	Signed URLs: Attachments are private; signed URLs expire (default 3600s). UI must refresh them.
	•	Realtime: Supabase Realtime subscription is recommended to auto-update chat messages.
	•	Compression: Images compressed before upload → reduces bandwidth.
	•	Testing Checklist:
	•	Create conversation (client + freelancer).
	•	Send text message.
	•	Send attachment.
	•	Confirm signed URL loads.
	•	Attempt sending as non-member → should fail.
	•	Expired URL → confirm refresh logic works.

⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻

⸻

⭐ Favorites Module – Developer Guide

1. Human Explanation

The Favorites module lets Clients save Freelancers as “favorites” for quick access and relationship management.

Why it exists:
	•	Shortcuts for Clients to revisit preferred Freelancers.
	•	Enables direct chat initiation between a Client and a Freelancer (without needing a posted task).

User Flow:
	1.	Client browses Freelancers.
	2.	Client taps Add to Favorites.
	3.	Freelancer is saved in the Client’s Favorites List.
	4.	Client can start a chat directly from Favorites.

⸻

2. Database & Supabase Mapping

Tables

Table	Column	Type	Purpose / Usage
favorites	id	uuid (PK)	Unique favorite record
	client_id	uuid (FK → profiles.id)	The Client saving a favorite
	freelancer_id	uuid (FK → profiles.id)	The Freelancer being favorited
	created_at	timestamptz	Timestamp of action
profiles	id	uuid (PK)	Shared across app for Clients & Freelancers
	full_name	text	Used to display names in Favorites UI
	avatar_url	text	Profile picture shown in Favorites

RLS Policies

-- Select only own favorites
create policy "favorites_select_own"
on favorites for select
using (client_id = auth.uid());

-- Insert only for self
create policy "favorites_insert_own"
on favorites for insert
with check (client_id = auth.uid());

-- Delete only own favorites
create policy "favorites_delete_own"
on favorites for delete
using (client_id = auth.uid());

Constraints
	•	Unique (client_id, freelancer_id) → prevents duplicate favorites.

⸻

3. File Inventory

File	Purpose
favorites_controller.dart	Holds state, manages add/remove logic. Talks to FavoritesService.
favorites_service.dart	Supabase integration (CRUD: insert, select, delete).
favorite_model.dart	Dart model for a favorite record.
favorites_screen.dart	Screen showing the list of favorited Freelancers.
favorite_card.dart	UI widget: renders one Freelancer card in Favorites.
favorites_routes.dart	Routing configuration to navigate to Favorites screen.


⸻

4. State Flow Diagram

flowchart LR
    UI[Favorites Screen / Favorite Card] --> C[FavoritesController]
    C --> S[FavoritesService]
    S --> DB[(Supabase: favorites table)]
    DB --> S
    S --> C
    C --> UI

Explanation:
	•	UI layer (screen + card) triggers add/remove actions.
	•	Controller updates app state and calls Service.
	•	Service executes Supabase queries (insert, select, delete).
	•	DB (Supabase) enforces RLS and constraints.
	•	Data flows back → Service → Controller → UI refresh.

⸻

5. ERD Diagram

Mermaid

erDiagram
    profiles ||--o{ favorites : "client_id"
    profiles ||--o{ favorites : "freelancer_id"

ASCII Fallback

profiles (id, full_name, avatar_url)
   | \
   |  \ client_id
   |   \
   +----< favorites >----+
             /           \
   freelancer_id          profiles (id, full_name, avatar_url)


⸻

6. Supabase Snippets

SQL

-- Add a favorite
insert into favorites (client_id, freelancer_id)
values (auth.uid(), 'freelancer-uuid');

-- Get my favorites
select f.*, p.full_name, p.avatar_url
from favorites f
join profiles p on f.freelancer_id = p.id
where f.client_id = auth.uid();

-- Remove a favorite
delete from favorites
where client_id = auth.uid()
  and freelancer_id = 'freelancer-uuid';

Dart (supabase_flutter)

// Add a favorite
await supabase.from('favorites').insert({
  'client_id': supabase.auth.currentUser!.id,
  'freelancer_id': freelancerId,
});

// Fetch favorites with profile data
final favorites = await supabase
  .from('favorites')
  .select('freelancer_id, profiles(full_name, avatar_url)')
  .eq('client_id', supabase.auth.currentUser!.id);

// Remove favorite
await supabase.from('favorites')
  .delete()
  .eq('client_id', supabase.auth.currentUser!.id)
  .eq('freelancer_id', freelancerId);


⸻

7. Error Handling

Error	Cause	User-friendly message
duplicate key value violates unique constraint	Trying to favorite the same freelancer twice	“This freelancer is already in your favorites.”
permission denied for table favorites	User not authorized by RLS	“You can only manage your own favorites.”
row-level security policy violation	Supabase blocked due to policy	“Access denied.”


⸻

8. Extra Notes
	•	Unique Constraint prevents duplicate favorites.
	•	Chat Integration: A Client can initiate direct chat from Favorites.
	•	Testing Checklist:
	1.	Add a Freelancer to Favorites.
	2.	Verify they appear in the list.
	3.	Try to add them again → expect friendly error.
	4.	Remove them → confirm removal in UI.
	5.	Start a chat from a Favorite → ensure access allowed.

⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻


⸻

🏠 Home Module – Developer Guide

1. Human Explanation

The Home Module is the entry point of the app once a user is authenticated.
It displays available services, highlights core features, and routes the user to the relevant feature modules (Tasks, Favorites, Bookings, Profile, etc.).
	•	Purpose: Central dashboard for navigating the app.
	•	User Flow:
	1.	User logs in → redirected to Home.
	2.	HomeController checks the user role (Client vs. Freelancer).
	3.	Based on role, UI shows appropriate services (e.g., post a task, browse tasks, manage offers).
	4.	Clicking a ServiceCard navigates into the corresponding module.

⸻

2. Database & Supabase Mapping

The Home module itself doesn’t directly manipulate Supabase tables.
Instead, it depends on data from other modules (like tasks, profile, favorites) to display contextual information.
	•	Indirect Dependencies:
	•	profiles table → used by HomeController to check role (client / freelancer).
	•	Other feature modules supply their own data for services.

Table	Column	Purpose in Home
profiles	role	Determines which services appear.


⸻

3. File Inventory

File	Purpose
home_controller.dart	Handles logic for deciding what to show on the home screen. Checks profile role and manages state.
home_screen.dart	UI for the main home page. Renders service cards based on controller logic.
service_card.dart	Reusable widget for displaying a single service (title, description, icon, tap handler).


⸻

4. State Flow Diagram

flowchart LR
    Controller[HomeController] --> Service[Other Feature Services]
    Service --> Supabase[Supabase DB]
    Supabase --> Service
    Service --> Controller
    Controller --> UI[HomeScreen + ServiceCard]

Explanation:
	•	HomeController queries ProfileService (inside profile module).
	•	Profile data (role) comes from Supabase.
	•	Controller decides which services to expose.
	•	UI (HomeScreen) renders the appropriate ServiceCards.

⸻

5. ERD Diagram (Contextual)

erDiagram
    profiles {
      uuid id PK
      text role
    }
    profiles ||--o{ services : "determines available services"

ASCII Fallback:

profiles (id, role)
   |
   +-- determines --> available services (UI only)


⸻

6. Supabase Snippets

Even though Home doesn’t query directly, here’s how role-check logic works:

SQL:

select role from profiles where id = auth.uid();

Dart (supabase_flutter):

final profile = await supabase
    .from('profiles')
    .select('role')
    .eq('id', supabase.auth.currentUser!.id)
    .single();

final role = profile['role'];
if (role == 'client') {
  // Show client services
} else {
  // Show freelancer services
}


⸻

7. Error Handling

Error	Cause	User-friendly Message
row not found	Profile doesn’t exist yet	“Please complete your profile before using the app.”
permission denied	RLS prevents access	“You don’t have permission to access this data.”


⸻

8. Extra Notes
	•	Role switching: If a user changes their role (via Profile module), HomeController will reflect it automatically on next load.
	•	Extensibility: New modules (e.g., Reports, Analytics) can be added simply by defining a new ServiceCard and wiring navigation.
	•	Testing Checklist:
	•	Log in as client → correct services shown.
	•	Log in as freelancer → correct services shown.
	•	Click each service card → navigates to correct module.
	•	Profile without role → prompts setup.

⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻

Awesome — I’ve consolidated everything into a polished, Profile Module – Developer Guide you can paste straight into DEVELOPER_GUIDE.md. It covers Profile and Portfolio, with schema tables, ERD, Supabase SQL & Dart snippets, error mapping, and a testing checklist.

⸻

👤 Profile Module – Developer Guide

1) Human Explanation

The Profile module manages user identity and presentation beyond basic authentication. It extends Supabase’s auth.users with an app-owned profiles table (name, avatar, role, language). It also includes a Portfolio sub-feature so freelancers can showcase work.

Why it exists
	•	auth.users only provides email + id.
	•	The app needs richer identity (display name, role, language, avatar) used across Tasks, Chat, Bookings, Favorites, and Home.
	•	Freelancers can publish Portfolio items (title, description, image) to build trust.

User flow
	1.	User signs up → auth.users row created.
	2.	A profiles row (same UUID) is created (seed/trigger or first-run insert).
	3.	On Profile screen, user can:
	•	Edit full_name, role, language.
	•	Upload avatar (stored in avatars bucket; displayed via signed URLs).
	•	Reset password or logout.
	4.	Freelancer adds Portfolio entries (image stored in portfolio bucket) viewable on their profile.

⸻

2) Database & Supabase Mapping

2.1 Tables & Columns

profiles

Column	Type	Purpose / Usage	Notes
id	uuid (PK, FK → auth.users.id)	Identity link to Supabase Auth	Primary join key across modules
full_name	text	Display name	Editable
avatar_url	text	Storage path in avatars bucket	Signed URL generated client-side
role	text / enum	client | freelancer	Drives Home/Tasks experience
language	text	en / ar / tr …	Used by UI language toggle
created_at	timestamptz	Creation timestamp	Default now()

portfolios

Column	Type	Purpose / Usage	Notes
id	uuid (PK)	Portfolio item id	Generated server/client
user_id	uuid (FK → profiles.id)	Owner of the item	RLS checks owner
title	text	Item title	Displayed in list & detail
description	text	Item description	Optional but recommended
image_url	text	Storage path in portfolio bucket	Signed URL for rendering
created_at	timestamptz	Creation timestamp	Default now()

2.2 Storage Buckets
	•	avatars: private; store profile images at paths like avatars/<user_id>/avatar.png.
	•	portfolio: private; store portfolio images at portfolio/<user_id>/<uuid>.<ext>.
	•	Access in UI via signed URLs (short-lived); refresh on demand.

2.3 RLS Policies (examples)

-- PROFILES: owner can read & update
create policy "profiles_select_own"
on profiles for select
using (id = auth.uid());

create policy "profiles_update_own"
on profiles for update
using (id = auth.uid());

-- PORTFOLIOS: owner can CRUD their items, everyone can SELECT (if you want public)
-- If portfolios should be public-readable, split policies accordingly:
create policy "portfolios_select_public"
on portfolios for select
using (true);

create policy "portfolios_cud_owner"
on portfolios for all
using (user_id = auth.uid());

Adjust select policy for portfolios depending on whether you want public visibility or only owner/clients visibility.

2.4 Constraints & Triggers (optional but recommended)
	•	Unique user profile per auth user (PK = id).
	•	Optional trigger to auto-create profiles row on signup (or handle in app after signup).

⸻

3) File Inventory

Profile Core

File	Role / Purpose
profile_controller.dart	ChangeNotifier: load profile, update fields, handle role toggle, logout, password reset, avatar workflow (delegates to service).
avatar_service.dart	Supabase storage ops for avatar: upload, overwrite (upsert), create signed URL.
profile_screen.dart	Container screen: composes avatar, form, toggles, logout/password reset actions.
profile_view.dart	Read-only details view (name, avatar signed URL, role, language).
profile_form.dart	Form fields: full_name, (email display), etc. Validation & submit.
profile_avatar.dart	Avatar widget: uses signed path + placeholder + cache-bust.
profile_avatar_widget.dart	Shared avatar renderer with caching/fallback variants.
profile_language_toggle.dart	Toggle UI: changes language field and updates app localization.
profile_role_toggle.dart	Toggle UI: changes role (client/freelancer), used by Home.
profile_logout_button.dart	Triggers supabase.auth.signOut().
profile_password_reset.dart	Sends password reset with Supabase Auth (email).

Portfolio Sub-Module

File	Role / Purpose
portfolio_controller.dart	Manage list & CRUD of portfolio items (load, add, edit, delete).
portfolio_screen.dart	Displays portfolio grid/list for a user.
portfolio_tile.dart	UI card per item (title, image signed URL).
add_portfolio_sheet.dart	Bottom sheet for new item: pick image, fill title/description.
edit_portfolio_sheet.dart	Bottom sheet to edit existing item fields & image.
portfolio_details_sheet.dart	Detailed item view (full image + description).
image_placeholder.dart	Placeholder while image loads / missing.


⸻

4) ERD Diagram

erDiagram
  auth_users {
    uuid id PK
    text email
  }
  profiles {
    uuid id PK
    text full_name
    text avatar_url
    text role
    text language
    timestamptz created_at
  }
  portfolios {
    uuid id PK
    uuid user_id FK
    text title
    text description
    text image_url
    timestamptz created_at
  }

  auth_users ||--o| profiles : "identity (same id)"
  profiles  ||--o{ portfolios : "owns"

ASCII fallback

auth.users (id, email)
        |
        v
profiles (id=auth.users.id, full_name, avatar_url, role, language, created_at)
        |
        +--< portfolios (id, user_id, title, description, image_url, created_at)


⸻

5) Supabase Snippets

SQL

-- Fetch my profile
select * from profiles where id = auth.uid();

-- Update profile fields (name, role, language)
update profiles
set full_name = 'New Name', role = 'freelancer', language = 'en'
where id = auth.uid();

-- Change avatar path after successful upload
update profiles
set avatar_url = 'avatars/' || auth.uid() || '/avatar.png'
where id = auth.uid();

-- Insert a portfolio item
insert into portfolios (user_id, title, description, image_url)
values (auth.uid(), 'Website Project', 'Landing page design', 'portfolio/<uid>/<uuid>.png')
returning *;

-- Delete a portfolio item (owner only)
delete from portfolios
where id = '<portfolio_id>' and user_id = auth.uid();

Dart (supabase_flutter)

// 1) Load profile
final myId = supabase.auth.currentUser!.id;
final profile = await supabase
  .from('profiles')
  .select()
  .eq('id', myId)
  .single();

// 2) Update profile fields
await supabase.from('profiles').update({
  'full_name': fullNameController.text.trim(),
  'role': selectedRole,          // 'client' or 'freelancer'
  'language': selectedLanguage,  // e.g., 'en'
}).eq('id', myId);

// 3) Upload avatar (private bucket) + update path
final avatarPath = 'avatars/$myId/avatar.png';
await supabase.storage
  .from('avatars')
  .upload(avatarPath, avatarFile, fileOptions: const FileOptions(upsert: true));

final signedUrlRes = await supabase.storage
  .from('avatars')
  .createSignedUrl(avatarPath, 3600);

await supabase.from('profiles').update({
  // Store the storage path (not the signed URL)
  'avatar_url': avatarPath,
}).eq('id', myId);

// 4) Add portfolio item
final portfolioPath = 'portfolio/$myId/${DateTime.now().millisecondsSinceEpoch}.jpg';
await supabase.storage
  .from('portfolio')
  .upload(portfolioPath, pickedImage, fileOptions: const FileOptions(upsert: true));

await supabase.from('portfolios').insert({
  'user_id': myId,
  'title': titleController.text.trim(),
  'description': descController.text.trim(),
  'image_url': portfolioPath, // store path; create signed URL when rendering
});

// 5) Create signed URL when displaying images
final signed = await supabase.storage
  .from('avatars')
  .createSignedUrl(avatarPath, 3600); // use in Image.network(signed)

Friendly error handling pattern

Future<T> guard<T>(Future<T> Function() run, {String fallback = "Something went wrong."}) async {
  try {
    return await run();
  } on PostgrestException catch (e) {
    // Map known codes
    if (e.code == '42501') throw "Access denied.";
    if (e.code == '23505') throw "Already exists.";
    throw e.message ?? fallback;
  } on StorageException catch (e) {
    throw e.message ?? "Upload failed.";
  } catch (_) {
    throw fallback;
  }
}


⸻

6) Error Handling

Error / Code	Typical Cause	User-friendly Message
permission denied / RLS	Updating another user’s profile; non-owner CRUD	“You can only manage your own profile/portfolio.”
row-level security policy violation	Missing/incorrect policies	“Access denied. Please log in again.”
23505 unique_violation	Duplicate portfolio id (rare) / unique constraints	“This item already exists.”
storage object not found	Bad/old path; deleted file	“Image not available. Please re-upload.”
invalid input syntax for uuid	Wrong id passed	“Something went wrong with IDs. Please try again.”
Expired signed URL (no code)	URL TTL elapsed	“Image link expired. Refreshing…”

Best practices
	•	Store paths in DB, not signed URLs.
	•	Re-create signed URLs on view (and on TTL expiry).
	•	Map low-level errors to clear messages at the Controller/Repository layer.

⸻

7) Extra Notes & Testing Checklist

Extra Notes
	•	Signed URLs: keep TTL small (e.g., 3600s). Recreate on demand; consider a small in-memory cache with expiry.
	•	Avatar cache bust: change filename or append a query string when a user uploads a new avatar to force UI refresh.
	•	Role switching: updating profiles.role should immediately alter Home & Tasks options on next load.
	•	Localization: profiles.language feeds a global localization provider.
	•	Privacy: keep buckets private; always use signed URLs in UI.

Testing Checklist
	1.	Create: signup → profiles row exists; default fields sane.
	2.	Read: profile loads; role/language/Avatar render with signed URL.
	3.	Update: change name/role/language → reflected in DB & UI.
	4.	Avatar: upload → storage path updated; old cache busted; signed URL loads.
	5.	Portfolio: add/edit/delete items, images display via signed URLs.
	6.	RLS: attempt to update another user’s profile/portfolio → blocked.
	7.	Reset Password: email flow succeeds; UI feedback shown.
	8.	Logout: session cleared; app navigates to Auth screens.

⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻⸻
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

