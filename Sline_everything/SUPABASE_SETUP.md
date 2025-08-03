### 6. `conversations`
- Stores user-to-user chat conversations.
- Columns:
  - `id` (UUID, primary key)
  - `task_id` (UUID, foreign key to tasks)
  - `user1_id` (UUID, foreign key to profiles)
  - `user2_id` (UUID, foreign key to profiles)
  - `created_at` (timestamp, default: now())

### 7. `messages`
- Stores chat messages linked to conversations.
- Columns:
  - `id` (UUID, primary key)
  - `conversation_id` (UUID, foreign key to conversations)
  - `sender_id` (UUID, foreign key to profiles)
  - `content` (text)
  - `created_at` (timestamp, default: now())

### ✅ Relationships (Recent)
- `conversations.user1_id → profiles.id`
- `conversations.user2_id → profiles.id`
- `messages.conversation_id → conversations.id`
- `messages.sender_id → profiles.id`

### ✅ Recent Fixes
- Added `profiles` table relationships for `conversations`.
- Implemented safe Supabase query handling for `last_message` field (handles Map/List/null).
- Verified relationships fetch publisher info via `profiles` table
- Ensured safe handling for conversations with no messages (last_message = null)
# Supabase Setup for Sline App

## ✅ Tables Created

### 1. `users`
- Stores user profile data.
- Columns:
  - `id` (UUID, primary key)
  - `full_name` (text)
  - `email` (text)
  - `avatar_url` (text)
  - `phone` (text, optional)
  - `created_at` (timestamp)

### 2. `roles`
- Stores available user roles.
- Columns:
  - `id` (UUID, primary key)
  - `name` (text): e.g., "client", "freelancer"

### 3. `user_roles`
- M2M table for assigning users to roles.
- Columns:
  - `user_id` (UUID, foreign key to users)
  - `role_id` (UUID, foreign key to roles)

### 4. `tasks`
- Stores job/task listings posted by clients.
- Columns:
  - `id` (UUID, primary key, auto-generated)
  - `user_id` (UUID, foreign key to auth.users)
    - Publisher Info: Linked to users table (user_id → users.id)
  - `title` (text)
  - `description` (text)
  - `budget` (numeric)
  - `deadline` (timestamp)
  - `category` (text)
  - `skills` (array of text)
  - `status` (text): allowed values `open`, `assigned`, `closed`
  - `created_at` (timestamp, default: now())

### 5. `profiles`
- Stores extended user profile data for publisher info.
- Columns:
  - `id` (UUID, primary key, references `auth.users.id`)
  - `full_name` (text)
  - `avatar_url` (text)
  - `created_at` (timestamp, default: now())

### ✅ Relationships
- `tasks.user_id → auth.users.id`  
- `profiles.id → auth.users.id`  
- Used for joining task listings with publisher info (full_name, avatar_url).

### ✅ Recent Fixes
- Added `profiles` table to store `full_name` and `avatar_url`.
- Ensured tasks join with `profiles` instead of `users` to avoid schema cache errors.
- Verified Supabase policies allow selecting publisher info alongside tasks.

## ✅ Policies Enabled

### 1. `users`
- Select, insert, update allowed if:
  - Authenticated user ID matches row's `id`.

### 2. `roles`, `user_roles`
- Read-only access enabled for all authenticated users.

### 3. `tasks`
- RLS enabled.
- Policies:
  - ✅ Insert: Allowed only if `auth.uid() = user_id`
  - ✅ Select: Allowed for all authenticated users
  - ✅ Update: Allowed only if `auth.uid() = user_id`
  - ✅ Delete: Allowed only if `auth.uid() = user_id`
  - ✅ Verified: Owners can now update/delete their own tasks via Profile > My Tasks

## ✅ Auth Configuration
- Email + password sign-up enabled.
- Users are automatically added to `users` table via Supabase Function/trigger (optional to implement).

## 🧩 Completed Integration
- ✅ TaskModel implemented to match Supabase `tasks` table.
- ✅ TaskService added with create and fetch operations.
- ✅ CreateTaskScreen fully functional.
- ✅ HomeController fetches and displays real tasks on HomeScreen.
