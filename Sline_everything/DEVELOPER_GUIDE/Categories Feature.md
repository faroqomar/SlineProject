
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

⸻

