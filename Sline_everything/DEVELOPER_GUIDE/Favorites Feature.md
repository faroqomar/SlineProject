
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

