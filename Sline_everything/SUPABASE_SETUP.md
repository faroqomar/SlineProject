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
- Enabled Supabase Realtime on `messages` and `conversations` tables.
- Verified subscriptions deliver new messages instantly between accounts.
- Adjusted queries to handle null/empty last messages safely in realtime updates.
- Added `listenToMessagesRealtime()` in message_service.dart and integrated in chat_controller.dart.
- Replaced `inFilter()` with `.in_()` in Supabase queries to fix undefined method error.

### 🛠 SQL Policies and Setup Implemented

```sql
-- Conversations policies
create policy "Allow users to read conversations"
on conversations for select
using (auth.uid() = user1_id or auth.uid() = user2_id);

create policy "Allow users to insert conversations"
on conversations for insert
with check (auth.uid() = user1_id or auth.uid() = user2_id);

-- Messages policies
create policy "Allow users to read messages"
on messages for select
using (auth.uid() = sender_id or auth.uid() in (
  select user1_id from conversations where conversations.id = messages.conversation_id
  union
  select user2_id from conversations where conversations.id = messages.conversation_id
));

create policy "Allow users to insert messages"
on messages for insert
with check (auth.uid() = sender_id);

-- Enable realtime for messages and conversations
alter publication supabase_realtime add table messages;
alter publication supabase_realtime add table conversations;
```

### 🔐 Additional Configuration
- Supabase Realtime enabled for `messages` and `conversations`.
- Policies ensure only participants of a conversation can view or send messages.
- Insert policies restricted to authenticated users only.
- Handled null/empty `last_message` to avoid UI crashes.
- Confirmed fetch joins with `profiles` for publisher info (avatar + name).
- Real-time subscriptions verified: messages now appear instantly for both participants without refresh.

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

# 🔧 Supabase Setup for Sline App (Up-to-date)

**Last updated:** 2025-08-17

هذا الملف يجمّع كل ما أنجزناه حتى الآن بخصوص إعداد الـ DB + RLS + Realtime + Storage (المرفقات) في Supabase.

---

## ✅ الجداول الأساسية

### 1) `profiles`
- `id` UUID (PK → `auth.users.id`)
- `full_name` text
- `avatar_url` text
- `created_at` timestamp (default now())

### 2) `tasks`
- `id` UUID (PK)
- `user_id` UUID (FK → `auth.users.id`)
- `title` text
- `description` text
- `budget` numeric
- `deadline` timestamp
- `category` text
- `skills` text[]
- `status` text (`open` | `assigned` | `closed`)
- `created_at` timestamp (default now())

### 3) `conversations`
- `id` UUID (PK)
- `task_id` UUID (FK → `tasks.id`)
- `user1_id` UUID (FK → `profiles.id`)
- `user2_id` UUID (FK → `profiles.id`)
- `created_at` timestamp (default now())

### 4) `messages`
> **محدّث** لدعم المرفقات وحقول الاستلام.
- `id` UUID (PK)
- `conversation_id` UUID (FK → `conversations.id`)
- `sender_id` UUID (FK → `profiles.id`)
- `receiver_id` UUID (FK → `profiles.id`)  ← **جديد**
- `content` text (قد يكون فارغًا عند رسائل المرفقات فقط)
- `attachment_url` text          ← **جديد**
- `attachment_type` text         ← **جديد** (`image` | `file`)
- `attachment_name` text         ← **جديد**
- `attachment_size` integer      ← **جديد** (bytes)
- `created_at` timestamp (default now())

#### 🔁 علاقات/مفاتيح أجنبية
- `conversations.user1_id → profiles.id`
- `conversations.user2_id → profiles.id`
- `messages.conversation_id → conversations.id`
- `messages.sender_id → profiles.id`
- `messages.receiver_id → profiles.id`

#### 🧱 سكريبت ترقية آمنة (Idempotent)
نفّذ التالي في SQL Editor لتحديث جدول الرسائل:
```sql
ALTER TABLE public.messages
  ADD COLUMN IF NOT EXISTS receiver_id     uuid REFERENCES public.profiles(id),
  ADD COLUMN IF NOT EXISTS attachment_url  text,
  ADD COLUMN IF NOT EXISTS attachment_type text,
  ADD COLUMN IF NOT EXISTS attachment_name text,
  ADD COLUMN IF NOT EXISTS attachment_size integer;

-- فهرس لأداء أفضل في الاستعلامات حسب المحادثة والزمن
CREATE INDEX IF NOT EXISTS idx_messages_convo_created
  ON public.messages (conversation_id, created_at);
```

---

## 🔐 سياسات RLS (محدّثة)

### `conversations`
```sql
-- قراءة: المشارك فقط
CREATE POLICY IF NOT EXISTS "Allow users to read conversations"
ON public.conversations FOR SELECT
USING (auth.uid() = user1_id OR auth.uid() = user2_id);

-- إدراج: أحد الطرفين فقط
CREATE POLICY IF NOT EXISTS "Allow users to insert conversations"
ON public.conversations FOR INSERT
WITH CHECK (auth.uid() = user1_id OR auth.uid() = user2_id);
```

### `messages`
```sql
-- قراءة: المرسل أو أي مشارك في المحادثة
CREATE POLICY IF NOT EXISTS "Allow users to read messages"
ON public.messages FOR SELECT
USING (
  auth.uid() = sender_id OR
  auth.uid() IN (
    SELECT user1_id FROM public.conversations WHERE conversations.id = messages.conversation_id
    UNION
    SELECT user2_id FROM public.conversations WHERE conversations.id = messages.conversation_id
  )
);

-- إدراج: المرسل فقط
CREATE POLICY IF NOT EXISTS "Allow users to insert messages"
ON public.messages FOR INSERT
WITH CHECK (auth.uid() = sender_id);
```

> **ملاحظة:** وجود `receiver_id` لا يغيّر صلاحيات القراءة لأن المشاركين يُستدل عليهم من `conversations`.

---

## 🔴 التخزين (Storage) — المرفقات

- **Bucket:** `chat-attachments` (Private)
- الرفع يتم بمسار: `conversationId/random_filename`
- العرض يتم عبر **Signed URLs** قصيرة العمر (ساعة افتراضيًا)

### إنشاء البكت (من الواجهة)
1) Storage → Create bucket → الاسم: `chat-attachments` → Private

### سياسات التخزين (Objects)
> تم إصلاح مشكلة التحقق من وجود السياسة: اسم العمود هو `policyname` وليس `polname`، ونفلتر `schemaname = 'storage'`.

```sql
-- INSERT policy: السماح بالرفع للمستخدمين المصدَّقين ضمن نفس البكت
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE policyname = 'chat_attach_insert_auth'
      AND schemaname = 'storage'
      AND tablename  = 'objects'
  ) THEN
    CREATE POLICY "chat_attach_insert_auth"
    ON storage.objects
    FOR INSERT
    TO authenticated
    WITH CHECK (
      bucket_id = 'chat-attachments'
      AND owner = auth.uid()
    );
  END IF;
END$$;

-- SELECT policy: السماح بقراءة الميتاداتا (مطلوب لتوليد Signed URLs)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE policyname = 'chat_attach_select_auth'
      AND schemaname = 'storage'
      AND tablename  = 'objects'
  ) THEN
    CREATE POLICY "chat_attach_select_auth"
    ON storage.objects
    FOR SELECT
    TO authenticated
    USING (bucket_id = 'chat-attachments');
  END IF;
END$$;
```

### تحقق سريع
```sql
SELECT policyname, schemaname, tablename, cmd
FROM pg_policies
WHERE schemaname='storage' AND tablename='objects'
ORDER BY policyname;
```

---

## 📡 Realtime
فعّلنا Realtime على الجداول:
```sql
ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
ALTER PUBLICATION supabase_realtime ADD TABLE public.conversations;
```

---

## 🧩 نقاط تطبيقية (Flutter)

- **Model** `Message` (محدّث):
  - الحقول الجديدة: `attachment_url`, `attachment_type`, `attachment_name`, `attachment_size`, `receiver_id`
- **Service**
  - `AttachmentService`: رفع بايتات إلى `chat-attachments` + إنشاء Signed URLs
  - `MessageService`:
    - `createOrGetConversation`: فلترة زوج المستخدمين بأي ترتيب
    - `sendMessage`: يدعم نص/مرفق
    - `getMessages`: يرجّع الحقول الجديدة
    - Realtime: stream مرتب حسب `created_at`
- **UI**
  - `ChatScreen`: أزرار اختيار صورة/ملف + عرض صورة كمصغّر أو ملف كبطاقة
- **حزم**
  - `image_picker`, `file_picker`

---

## 🧪 Troubleshooting
- **42703: polname لا يوجد** → استخدم `policyname` + `schemaname='storage'`.
- **RLS: new row violates row-level security** → تحقق من:
  1) اسم البكت صحيح `chat-attachments`
  2) رفع يتم بمفتاح عميل (ليس service_role)
  3) سياسة INSERT أعلاه مضافة
- **Signed URL يفشل** → تأكد من سياسة SELECT على `storage.objects` موجودة وأن الملف في نفس البكت.

---

## 📜 مرجع سريع (نسخة علاقات/مفاتيح)
- `conversations.user1_id → profiles.id`
- `conversations.user2_id → profiles.id`
- `messages.conversation_id → conversations.id`
- `messages.sender_id → profiles.id`
- `messages.receiver_id → profiles.id`
# 🔧 Supabase Setup for SLine — What We Did (DB + RLS + Realtime + Storage)

**Last Updated:** 2025-08-17

This document summarizes exactly what we set up and changed in Supabase for SLine.

---

## ✅ TL;DR — Implemented
- **Core tables**: `profiles`, `tasks`, `conversations`, `messages` (extended for attachments & receipts-ready).
- **RLS policies**: locked down reads/writes so only conversation participants can read, and only senders can insert messages.
- **Realtime**: enabled on `messages` and `conversations`.
- **Storage (attachments)**: private bucket `chat-attachments`, upload via client, display via Signed URLs.
- **Indexes & query ergonomics**: added composite index on `(conversation_id, created_at)` and standardized query chaining (`.or/.in_` before `.order/.limit`).

---

## 1) Tables (Schema)

### `profiles`
- `id` UUID (PK → `auth.users.id`)
- `full_name` text
- `avatar_url` text
- `created_at` timestamptz default now()

### `tasks`
- `id` UUID (PK)
- `user_id` UUID (FK → `auth.users.id`)
- `title` text, `description` text, `budget` numeric, `deadline` timestamptz
- `category` text, `skills` text[]
- `status` text (`open` | `assigned` | `closed`)
- `created_at` timestamptz default now()

### `conversations`
- `id` UUID (PK)
- `task_id` UUID (FK → `tasks.id`)
- `user1_id` UUID (FK → `profiles.id`)
- `user2_id` UUID (FK → `profiles.id`)
- `created_at` timestamptz default now()

### `messages` (extended)
- `id` UUID (PK)
- `conversation_id` UUID (FK → `conversations.id`)
- `sender_id` UUID (FK → `profiles.id`)
- `receiver_id` UUID (FK → `profiles.id`)  ← **added**
- `content` text
- `attachment_url` text  ← **added** (storage path, not public URL)
- `attachment_type` text ← **added** (`image` | `file`)
- `attachment_name` text ← **added**
- `attachment_size` int  ← **added** (bytes)
- `created_at` timestamptz default now()

**Index (performance):**
```sql
CREATE INDEX IF NOT EXISTS idx_messages_convo_created
  ON public.messages (conversation_id, created_at);
```

**Idempotent upgrade script:**
```sql
ALTER TABLE public.messages
  ADD COLUMN IF NOT EXISTS receiver_id     uuid REFERENCES public.profiles(id),
  ADD COLUMN IF NOT EXISTS attachment_url  text,
  ADD COLUMN IF NOT EXISTS attachment_type text,
  ADD COLUMN IF NOT EXISTS attachment_name text,
  ADD COLUMN IF NOT EXISTS attachment_size integer;
```

---

## 2) Row-Level Security (RLS) Policies

### `conversations`
```sql
CREATE POLICY IF NOT EXISTS "Allow users to read conversations"
ON public.conversations FOR SELECT
USING (auth.uid() = user1_id OR auth.uid() = user2_id);

CREATE POLICY IF NOT EXISTS "Allow users to insert conversations"
ON public.conversations FOR INSERT
WITH CHECK (auth.uid() = user1_id OR auth.uid() = user2_id);
```

### `messages`
```sql
CREATE POLICY IF NOT EXISTS "Allow users to read messages"
ON public.messages FOR SELECT
USING (
  auth.uid() = sender_id OR auth.uid() IN (
    SELECT user1_id FROM public.conversations WHERE conversations.id = messages.conversation_id
    UNION
    SELECT user2_id FROM public.conversations WHERE conversations.id = messages.conversation_id
  )
);

CREATE POLICY IF NOT EXISTS "Allow users to insert messages"
ON public.messages FOR INSERT
WITH CHECK (auth.uid() = sender_id);
```

> Note: `receiver_id` exists for business logic but read-permission relies on conversation membership.

---

## 3) Realtime
Enabled publications so inserts/updates stream to the client:
```sql
ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
ALTER PUBLICATION supabase_realtime ADD TABLE public.conversations;
```
**Client pattern:** subscribe to messages for the active conversation and **upsert** into the local list (avoid full refetch per event).

---

## 4) Storage (Attachments)
- **Bucket:** `chat-attachments` (Private)
- **Upload path:** `convos/<conversation_id>/<random_safe_name>`
- **Display:** via **Signed URL** (default expiry 3600s)

**RLS policies for `storage.objects`:**
```sql
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE policyname = 'chat_attach_insert_auth'
      AND schemaname = 'storage'
      AND tablename  = 'objects'
  ) THEN
    CREATE POLICY "chat_attach_insert_auth"
    ON storage.objects
    FOR INSERT
    TO authenticated
    WITH CHECK (
      bucket_id = 'chat-attachments' AND owner = auth.uid()
    );
  END IF;
END$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE policyname = 'chat_attach_select_auth'
      AND schemaname = 'storage'
      AND tablename  = 'objects'
  ) THEN
    CREATE POLICY "chat_attach_select_auth"
    ON storage.objects
    FOR SELECT
    TO authenticated
    USING (bucket_id = 'chat-attachments');
  END IF;
END$$;
```

**Verify policies:**
```sql
SELECT policyname, schemaname, tablename, cmd
FROM pg_policies
WHERE schemaname='storage' AND tablename='objects'
ORDER BY policyname;
```

---

## 5) Query Tips (Supabase Dart)
To avoid `undefined_method` and over-fetching:
- Call `.or(...)` and `.in_(...)` **before** `.order(...)` and `.limit(...)`.
- For nested relations (e.g., `last_message:messages!conversation_id(...)`), constrain payload with:
  - `.order('created_at', foreignTable: 'messages', ascending: false)`
  - `.limit(1, foreignTable: 'messages')`

---

## 6) Optional / Deferred
- **Typing indicators** via `conversation_presence` table + cleanup trigger. Deferred until after read receipts.

---

## 7) Why This Matters
- Private attachments remain secure; clients only see what they’re allowed to see.
- Realtime feels instant without network churn (local upsert).
- Queries are predictable and stable across SDK updates.