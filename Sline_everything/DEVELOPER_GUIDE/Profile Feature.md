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

⸻

