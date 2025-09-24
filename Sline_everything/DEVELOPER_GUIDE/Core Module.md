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
