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