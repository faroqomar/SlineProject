

# Profile Feature Reference

## 1. Human Explanation
The Profile feature manages a user’s app identity beyond `auth.users`. It loads and edits `profiles` (name, bio, role, avatar path), changes email/password through Supabase Auth, and shows the user’s own tasks. MVVM flow:
- UI in `lib/features/profile/view/` renders the form and actions.
- `ProfileViewModel` orchestrates reads/writes, avatar upload, and navigation.
- `ProfileRepository` performs DB updates and delegates avatar upload to `AvatarService` (private storage + signed URLs).

## 2. Database & Supabase Mapping

### 2.1 `public.profiles`
| Column | Type | Purpose / Usage | Notes |
| --- | --- | --- | --- |
| `id` | `uuid` (PK, FK → `auth.users.id`) | Identity link to Supabase Auth | Primary join key across modules |
| `full_name` | `text` | Display name | Editable in Profile screen |
| `email` | `text` | Cached email for quick reads | Updated alongside Auth when changed |
| `bio` | `text` | Short description | Editable in Profile screen |
| `role` | `text` | `client` or `freelancer` | Toggles Home/Tasks UX |
| `avatar_url` | `text` | Private storage path in `avatars` bucket | Use signed URLs for display |
| `created_at` | `timestamptz` | Creation time (UTC) | Default `now()` |

RLS (summary): Users can `SELECT/UPDATE` only their row (`auth.uid() = id`). Any mutation requires a valid session.

### 2.2 Storage buckets (private)
| Bucket | Purpose | Used by | Notes |
| --- | --- | --- | --- |
| `avatars` | Profile images | `AvatarService` and `SignedAvatar` | Store path only; generate signed URL for display |

## 3. File Inventory
| File | Layer | Description |
| --- | --- | --- |
| `lib/features/profile/data/profile_repository.dart` | Repository | Wraps Supabase calls for profile load/update, email updates, role change, password reset, avatar upload, and my-tasks helpers. |
| `lib/features/profile/services/avatar_service.dart` | Service | Uploads avatar to `avatars` bucket and creates short-lived signed URLs. Stores only the storage path in DB. |
| `lib/features/profile/viewmodels/profile_view_model.dart` | ViewModel | `ChangeNotifier` that binds form controllers, updates profile, uploads avatar, handles logout/role change, and loads user tasks. |
| `lib/features/profile/view/profile_screen.dart` | View | Material 3 profile UI with form fields, avatar, role toggle, password reset, and sign out. |
| `lib/features/profile/view/widgets/profile_avatar_widget.dart` | Widget | Renders a profile avatar via a signed URL for a private storage path. |

## 4. ERD Diagram (Context)
```mermaid
erDiagram
  AUTH_USERS ||--|| PROFILES : "id = id"
  PROFILES ||--o{ TASKS : "user_id"
  PROFILES ||--o{ STORAGE_AVATARS : "avatar_url (path)"

  AUTH_USERS { uuid id PK, text email }
  PROFILES { uuid id PK/FK, text full_name, text email, text bio, text role, text avatar_url, timestamptz created_at }
  TASKS { uuid id PK, uuid user_id FK, text title }
  STORAGE_AVATARS { text path PK }
```

```text
auth.users (id, email)
   └── profiles (id=auth.users.id, full_name, email, bio, role, avatar_url)
            └──(path) avatars bucket (private, signed URLs)
   └── tasks (user_id → profiles.id)
```

## 5. Supabase Snippets

### 5.1 SQL (core operations)
```sql
-- Load my profile
select id, full_name, email, bio, role, avatar_url
from public.profiles
where id = auth.uid();

-- Update profile fields (RLS enforces id = auth.uid())
update public.profiles
set full_name = 'New Name', bio = 'About me', role = 'freelancer'
where id = auth.uid();

-- Change avatar path after upload
update public.profiles
set avatar_url = concat('avatars/', auth.uid(), '/', extract(epoch from now())::bigint, '.jpg')
where id = auth.uid();
```

### 5.2 Dart (supabase_flutter)
```dart
final supabase = Supabase.instance.client;

// Fetch profile (ProfileRepository.fetchProfile)
final me = supabase.auth.currentUser!.id;
final row = await supabase.from('profiles').select().eq('id', me).single();

// Update profile fields (ProfileRepository.updateProfileFields)
await supabase.from('profiles').update({
  'full_name': fullName,
  'bio': bio,
}).eq('id', me);

// Change auth email (ProfileRepository.updateUserEmail)
await supabase.auth.updateUser(UserAttributes(email: newEmail));

// Upload avatar via AvatarService and save path
final path = await AvatarService(supabase).uploadAvatar(
  userId: me,
  bytes: imageBytes,
  contentType: 'image/jpeg',
  fileExt: 'jpg',
);
await supabase.from('profiles').update({'avatar_url': path}).eq('id', me);

// Create signed URL for display
final signed = await AvatarService(supabase).createSignedUrl(path);
```

## 6. Error Handling
| Origin | Error | User-Facing Message | Mitigation |
| --- | --- | --- | --- |
| Profiles update | `42501` RLS denied | "Session expired. Please log in again." | Re-authenticate and retry. |
| Auth email change | `AuthException` | "Unable to change email right now." | Prompt to retry; ensure email is valid and unique. |
| Avatar upload | `StorageException` | "Upload failed. Please try again." | Validate file type/size; retry. |
| Signed URL | Expired URL | "Image link expired. Refreshing…" | Regenerate signed URL lazily. |
| IDs | `22P02` invalid UUID | "Invalid identifier." | Validate IDs before requests. |

## 7. Extra Notes & Testing Checklist
- **Store paths, not signed URLs** in `profiles.avatar_url`; generate signed URLs at render time.
- **UTC**: All timestamps are UTC; convert with `toLocal()` where needed.
- **Session required**: All RLS-protected queries require an active session.
- **Home/Tasks impact**: Updating `role` affects Home/Tasks UX next load.

Testing checklist:
- Load profile → fields populate in `ProfileViewModel` controllers.
- Update name/bio → persisted in `public.profiles` and reflected in UI.
- Upload avatar → path saved, signed URL generated, and image renders.
- Change email → Auth email updated; cached profile email optional sync.
- Change role → Home reflects the role after reload.
- Fetch my tasks → user’s tasks load and render; delete/update works.
