

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

