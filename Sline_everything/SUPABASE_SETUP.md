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

**Last updated:** 2025-08-22

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

#### 🔤 Enum: `task_type_enum`
```sql
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'task_type_enum') THEN
    CREATE TYPE public.task_type_enum AS ENUM ('tender','booking');
  END IF;
END$$;

ALTER TABLE public.tasks
  ADD COLUMN IF NOT EXISTS task_type public.task_type_enum NOT NULL DEFAULT 'tender',
  ADD COLUMN IF NOT EXISTS session_price_bigint BIGINT,
  ADD COLUMN IF NOT EXISTS hour_rate_bigint BIGINT;

CREATE INDEX IF NOT EXISTS idx_tasks_type_created_at
  ON public.tasks (task_type, created_at DESC);
```

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

## 📦 Task Requests (Offers) — DONE

### جدول `task_requests`
```sql
CREATE TABLE IF NOT EXISTS public.task_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id uuid NOT NULL REFERENCES public.tasks(id) ON DELETE CASCADE,
  bidder_id uuid NOT NULL REFERENCES public.profiles(id),
  price BIGINT NOT NULL,
  days integer NOT NULL,
  note text,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','accepted','rejected')),
  created_at timestamptz NOT NULL DEFAULT now()
);
```

### فهارس & قيود
```sql
CREATE INDEX IF NOT EXISTS idx_task_requests_task_created
  ON public.task_requests (task_id, created_at DESC);

-- عرض pending واحد لكل (task_id, bidder_id)
CREATE UNIQUE INDEX IF NOT EXISTS uq_task_requests_unique_pending_per_user
  ON public.task_requests(task_id, bidder_id)
  WHERE status = 'pending';
```

### RLS Policies
```sql
ALTER TABLE public.task_requests ENABLE ROW LEVEL SECURITY;

-- المالك يشوف كل العروض على مهمته (tender فقط)
CREATE POLICY IF NOT EXISTS "owner_selects_offers"
ON public.task_requests FOR SELECT
USING (EXISTS (
  SELECT 1 FROM public.tasks t
  WHERE t.id = task_requests.task_id
    AND t.user_id = auth.uid()
    AND t.task_type = 'tender'::task_type_enum
));

-- المزايد يشوف عروضه فقط
CREATE POLICY IF NOT EXISTS "bidder_selects_own_offers"
ON public.task_requests FOR SELECT
USING (bidder_id = auth.uid());

-- الإدراج: المزايد نفسه وعلى مهمة tender
CREATE POLICY IF NOT EXISTS "bidder_inserts_offer"
ON public.task_requests FOR INSERT
WITH CHECK (bidder_id = auth.uid() AND EXISTS (
  SELECT 1 FROM public.tasks t
  WHERE t.id = task_requests.task_id
    AND t.task_type = 'tender'::task_type_enum
));

-- التعديل (accept/reject): فقط مالك المهمة (tender)
CREATE POLICY IF NOT EXISTS "owner_updates_offer_status"
ON public.task_requests FOR UPDATE
USING (EXISTS (
  SELECT 1 FROM public.tasks t
  WHERE t.id = task_requests.task_id
    AND t.user_id = auth.uid()
    AND t.task_type = 'tender'::task_type_enum
));
```

### Triggers (حماية)
```sql
-- منع إدراج عرض على مهمة booking
CREATE OR REPLACE FUNCTION public.trg_check_task_is_tender() RETURNS trigger AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.tasks t
                 WHERE t.id = NEW.task_id AND t.task_type = 'tender') THEN
    RAISE EXCEPTION 'Offers are only allowed on tender tasks';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_task_requests_only_for_tender ON public.task_requests;
CREATE TRIGGER trg_task_requests_only_for_tender
  BEFORE INSERT ON public.task_requests
  FOR EACH ROW EXECUTE FUNCTION public.trg_check_task_is_tender();

-- (اختياري) منع تعديل أي شيء غير status
CREATE OR REPLACE FUNCTION public.trg_task_requests_allow_status_only() RETURNS trigger AS $$
BEGIN
  IF NEW.status IS DISTINCT FROM OLD.status THEN
    RETURN NEW;
  END IF;
  RAISE EXCEPTION 'Only status updates are allowed';
END;
$$ LANGUAGE plpgsql;

-- ملاحظة: فعّل هذا التريغر فقط إذا رغبت بقفل باقي الحقول أثناء lifecycle
-- DROP TRIGGER IF EXISTS trg_task_requests_status_only ON public.task_requests;
-- CREATE TRIGGER trg_task_requests_status_only
--   BEFORE UPDATE ON public.task_requests
--   FOR EACH ROW EXECUTE FUNCTION public.trg_task_requests_allow_status_only();
```

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

## 📜 Grants & Privileges — Snapshot

> Current table-level privileges as reported by information_schema (anon/authenticated/postgres/service_role). RLS still applies on top, but wide GRANTs for `anon` are risky in production.

| table_schema | table_name            | grantee       | privilege_type |
| ------------ | --------------------- | ------------- | -------------- |
| public       | conversation_presence | anon          | DELETE         |
| public       | conversation_presence | anon          | INSERT         |
| public       | conversation_presence | anon          | REFERENCES     |
| public       | conversation_presence | anon          | SELECT         |
| public       | conversation_presence | anon          | TRIGGER        |
| public       | conversation_presence | anon          | TRUNCATE       |
| public       | conversation_presence | anon          | UPDATE         |
| public       | conversation_presence | authenticated | DELETE         |
| public       | conversation_presence | authenticated | INSERT         |
| public       | conversation_presence | authenticated | REFERENCES     |
| public       | conversation_presence | authenticated | SELECT         |
| public       | conversation_presence | authenticated | TRIGGER        |
| public       | conversation_presence | authenticated | TRUNCATE       |
| public       | conversation_presence | authenticated | UPDATE         |
| public       | conversation_presence | postgres      | DELETE         |
| public       | conversation_presence | postgres      | INSERT         |
| public       | conversation_presence | postgres      | REFERENCES     |
| public       | conversation_presence | postgres      | SELECT         |
| public       | conversation_presence | postgres      | TRIGGER        |
| public       | conversation_presence | postgres      | TRUNCATE       |
| public       | conversation_presence | postgres      | UPDATE         |
| public       | conversation_presence | service_role  | DELETE         |
| public       | conversation_presence | service_role  | INSERT         |
| public       | conversation_presence | service_role  | REFERENCES     |
| public       | conversation_presence | service_role  | SELECT         |
| public       | conversation_presence | service_role  | TRIGGER        |
| public       | conversation_presence | service_role  | TRUNCATE       |
| public       | conversation_presence | service_role  | UPDATE         |
| public       | conversations         | anon          | DELETE         |
| public       | conversations         | anon          | INSERT         |
| public       | conversations         | anon          | REFERENCES     |
| public       | conversations         | anon          | SELECT         |
| public       | conversations         | anon          | TRIGGER        |
| public       | conversations         | anon          | TRUNCATE       |
| public       | conversations         | anon          | UPDATE         |
| public       | conversations         | authenticated | DELETE         |
| public       | conversations         | authenticated | INSERT         |
| public       | conversations         | authenticated | REFERENCES     |
| public       | conversations         | authenticated | SELECT         |
| public       | conversations         | authenticated | TRIGGER        |
| public       | conversations         | authenticated | TRUNCATE       |
| public       | conversations         | authenticated | UPDATE         |
| public       | conversations         | postgres      | DELETE         |
| public       | conversations         | postgres      | INSERT         |
| public       | conversations         | postgres      | REFERENCES     |
| public       | conversations         | postgres      | SELECT         |
| public       | conversations         | postgres      | TRIGGER        |
| public       | conversations         | postgres      | TRUNCATE       |
| public       | conversations         | postgres      | UPDATE         |
| public       | conversations         | service_role  | DELETE         |
| public       | conversations         | service_role  | INSERT         |
| public       | conversations         | service_role  | REFERENCES     |
| public       | conversations         | service_role  | SELECT         |
| public       | conversations         | service_role  | TRIGGER        |
| public       | conversations         | service_role  | TRUNCATE       |
| public       | conversations         | service_role  | UPDATE         |
| public       | messages              | anon          | DELETE         |
| public       | messages              | anon          | INSERT         |
| public       | messages              | anon          | REFERENCES     |
| public       | messages              | anon          | SELECT         |
| public       | messages              | anon          | TRIGGER        |
| public       | messages              | anon          | TRUNCATE       |
| public       | messages              | anon          | UPDATE         |
| public       | messages              | authenticated | DELETE         |
| public       | messages              | authenticated | INSERT         |
| public       | messages              | authenticated | REFERENCES     |
| public       | messages              | authenticated | SELECT         |
| public       | messages              | authenticated | TRIGGER        |
| public       | messages              | authenticated | TRUNCATE       |
| public       | messages              | authenticated | UPDATE         |
| public       | messages              | postgres      | DELETE         |
| public       | messages              | postgres      | INSERT         |
| public       | messages              | postgres      | REFERENCES     |
| public       | messages              | postgres      | SELECT         |
| public       | messages              | postgres      | TRIGGER        |
| public       | messages              | postgres      | TRUNCATE       |
| public       | messages              | postgres      | UPDATE         |
| public       | messages              | service_role  | DELETE         |
| public       | messages              | service_role  | INSERT         |
| public       | messages              | service_role  | REFERENCES     |
| public       | messages              | service_role  | SELECT         |
| public       | messages              | service_role  | TRIGGER        |
| public       | messages              | service_role  | TRUNCATE       |
| public       | messages              | service_role  | UPDATE         |
| public       | profiles              | anon          | DELETE         |
| public       | profiles              | anon          | INSERT         |
| public       | profiles              | anon          | REFERENCES     |
| public       | profiles              | anon          | SELECT         |
| public       | profiles              | anon          | TRIGGER        |
| public       | profiles              | anon          | TRUNCATE       |
| public       | profiles              | anon          | UPDATE         |
| public       | profiles              | authenticated | DELETE         |
| public       | profiles              | authenticated | INSERT         |
| public       | profiles              | authenticated | REFERENCES     |
| public       | profiles              | authenticated | SELECT         |
| public       | profiles              | authenticated | TRIGGER        |
| public       | profiles              | authenticated | TRUNCATE       |
| public       | profiles              | authenticated | UPDATE         |
| public       | profiles              | postgres      | DELETE         |
| public       | profiles              | postgres      | INSERT         |
| public       | profiles              | postgres      | REFERENCES     |
| public       | profiles              | postgres      | SELECT         |
| public       | profiles              | postgres      | TRIGGER        |
| public       | profiles              | postgres      | TRUNCATE       |
| public       | profiles              | postgres      | UPDATE         |
| public       | profiles              | service_role  | DELETE         |
| public       | profiles              | service_role  | INSERT         |
| public       | profiles              | service_role  | REFERENCES     |
| public       | profiles              | service_role  | SELECT         |
| public       | profiles              | service_role  | TRIGGER        |
| public       | profiles              | service_role  | TRUNCATE       |
| public       | profiles              | service_role  | UPDATE         |
| public       | task_requests         | anon          | DELETE         |
| public       | task_requests         | anon          | INSERT         |
| public       | task_requests         | anon          | REFERENCES     |
| public       | task_requests         | anon          | SELECT         |
| public       | task_requests         | anon          | TRIGGER        |
| public       | task_requests         | anon          | TRUNCATE       |
| public       | task_requests         | anon          | UPDATE         |
| public       | task_requests         | authenticated | DELETE         |
| public       | task_requests         | authenticated | INSERT         |
| public       | task_requests         | authenticated | REFERENCES     |
| public       | task_requests         | authenticated | SELECT         |
| public       | task_requests         | authenticated | TRIGGER        |
| public       | task_requests         | authenticated | TRUNCATE       |
| public       | task_requests         | authenticated | UPDATE         |
| public       | task_requests         | postgres      | DELETE         |
| public       | task_requests         | postgres      | INSERT         |
| public       | task_requests         | postgres      | REFERENCES     |
| public       | task_requests         | postgres      | SELECT         |
| public       | task_requests         | postgres      | TRIGGER        |
| public       | task_requests         | postgres      | TRUNCATE       |
| public       | task_requests         | postgres      | UPDATE         |
| public       | task_requests         | service_role  | DELETE         |
| public       | task_requests         | service_role  | INSERT         |
| public       | task_requests         | service_role  | REFERENCES     |
| public       | task_requests         | service_role  | SELECT         |
| public       | task_requests         | service_role  | TRIGGER        |
| public       | task_requests         | service_role  | TRUNCATE       |
| public       | task_requests         | service_role  | UPDATE         |
| public       | tasks                 | anon          | DELETE         |
| public       | tasks                 | anon          | INSERT         |
| public       | tasks                 | anon          | REFERENCES     |
| public       | tasks                 | anon          | SELECT         |
| public       | tasks                 | anon          | TRIGGER        |
| public       | tasks                 | anon          | TRUNCATE       |
| public       | tasks                 | anon          | UPDATE         |
| public       | tasks                 | authenticated | DELETE         |
| public       | tasks                 | authenticated | INSERT         |
| public       | tasks                 | authenticated | REFERENCES     |
| public       | tasks                 | authenticated | SELECT         |
| public       | tasks                 | authenticated | TRIGGER        |
| public       | tasks                 | authenticated | TRUNCATE       |
| public       | tasks                 | authenticated | UPDATE         |
| public       | tasks                 | postgres      | DELETE         |
| public       | tasks                 | postgres      | INSERT         |
| public       | tasks                 | postgres      | REFERENCES     |
| public       | tasks                 | postgres      | SELECT         |
| public       | tasks                 | postgres      | TRIGGER        |
| public       | tasks                 | postgres      | TRUNCATE       |
| public       | tasks                 | postgres      | UPDATE         |
| public       | tasks                 | service_role  | DELETE         |
| public       | tasks                 | service_role  | INSERT         |
| public       | tasks                 | service_role  | REFERENCES     |
| public       | tasks                 | service_role  | SELECT         |
| public       | tasks                 | service_role  | TRIGGER        |
| public       | tasks                 | service_role  | TRUNCATE       |
| public       | tasks                 | service_role  | UPDATE         |
| public       | test_table            | anon          | DELETE         |
| public       | test_table            | anon          | INSERT         |
| public       | test_table            | anon          | REFERENCES     |
| public       | test_table            | anon          | SELECT         |
| public       | test_table            | anon          | TRIGGER        |
| public       | test_table            | anon          | TRUNCATE       |
| public       | test_table            | anon          | UPDATE         |
| public       | test_table            | authenticated | DELETE         |
| public       | test_table            | authenticated | INSERT         |
| public       | test_table            | authenticated | REFERENCES     |
| public       | test_table            | authenticated | SELECT         |
| public       | test_table            | authenticated | TRIGGER        |
| public       | test_table            | authenticated | TRUNCATE       |
| public       | test_table            | authenticated | UPDATE         |
| public       | test_table            | postgres      | DELETE         |
| public       | test_table            | postgres      | INSERT         |
| public       | test_table            | postgres      | REFERENCES     |
| public       | test_table            | postgres      | SELECT         |
| public       | test_table            | postgres      | TRIGGER        |
| public       | test_table            | postgres      | TRUNCATE       |
| public       | test_table            | postgres      | UPDATE         |
| public       | test_table            | service_role  | DELETE         |
| public       | test_table            | service_role  | INSERT         |
| public       | test_table            | service_role  | REFERENCES     |
| public       | test_table            | service_role  | SELECT         |
| public       | test_table            | service_role  | TRIGGER        |
| public       | test_table            | service_role  | TRUNCATE       |
| public       | test_table            | service_role  | UPDATE         |
| public       | user_conversations    | anon          | DELETE         |
| public       | user_conversations    | anon          | INSERT         |
| public       | user_conversations    | anon          | REFERENCES     |
| public       | user_conversations    | anon          | SELECT         |
| public       | user_conversations    | anon          | TRIGGER        |
| public       | user_conversations    | anon          | TRUNCATE       |
| public       | user_conversations    | anon          | UPDATE         |
| public       | user_conversations    | authenticated | DELETE         |
| public       | user_conversations    | authenticated | INSERT         |
| public       | user_conversations    | authenticated | REFERENCES     |
| public       | user_conversations    | authenticated | SELECT         |
| public       | user_conversations    | authenticated | TRIGGER        |
| public       | user_conversations    | authenticated | TRUNCATE       |
| public       | user_conversations    | authenticated | UPDATE         |
| public       | user_conversations    | postgres      | DELETE         |
| public       | user_conversations    | postgres      | INSERT         |
| public       | user_conversations    | postgres      | REFERENCES     |
| public       | user_conversations    | postgres      | SELECT         |
| public       | user_conversations    | postgres      | TRIGGER        |
| public       | user_conversations    | postgres      | TRUNCATE       |
| public       | user_conversations    | postgres      | UPDATE         |
| public       | user_conversations    | service_role  | DELETE         |
| public       | user_conversations    | service_role  | INSERT         |
| public       | user_conversations    | service_role  | REFERENCES     |
| public       | user_conversations    | service_role  | SELECT         |
| public       | user_conversations    | service_role  | TRIGGER        |
| public       | user_conversations    | service_role  | TRUNCATE       |
| public       | user_conversations    | service_role  | UPDATE         |
| public       | users                 | anon          | DELETE         |
| public       | users                 | anon          | INSERT         |
| public       | users                 | anon          | REFERENCES     |
| public       | users                 | anon          | SELECT         |
| public       | users                 | anon          | TRIGGER        |
| public       | users                 | anon          | TRUNCATE       |
| public       | users                 | anon          | UPDATE         |
| public       | users                 | authenticated | DELETE         |
| public       | users                 | authenticated | INSERT         |
| public       | users                 | authenticated | REFERENCES     |
| public       | users                 | authenticated | SELECT         |
| public       | users                 | authenticated | TRIGGER        |
| public       | users                 | authenticated | TRUNCATE       |
| public       | users                 | authenticated | UPDATE         |
| public       | users                 | postgres      | DELETE         |
| public       | users                 | postgres      | INSERT         |
| public       | users                 | postgres      | REFERENCES     |
| public       | users                 | postgres      | SELECT         |
| public       | users                 | postgres      | TRIGGER        |
| public       | users                 | postgres      | TRUNCATE       |
| public       | users                 | postgres      | UPDATE         |
| public       | users                 | service_role  | DELETE         |
| public       | users                 | service_role  | INSERT         |
| public       | users                 | service_role  | REFERENCES     |
| public       | users                 | service_role  | SELECT         |
| public       | users                 | service_role  | TRIGGER        |
| public       | users                 | service_role  | TRUNCATE       |
| public       | users                 | service_role  | UPDATE         |

### ⚠️ Notes
- `anon` currently holds wide privileges (INSERT/UPDATE/DELETE) on multiple tables; RLS reduces risk but consider revoking to limit surface area.
- Keep `service_role` superwide only for server-side (never used in client apps).
- Re-evaluate `test_table` and drop or restrict if not needed.

## 7) Why This Matters
- Private attachments remain secure; clients only see what they’re allowed to see.
- Realtime feels instant without network churn (local upsert).
- Queries are predictable and stable across SDK updates.
### 🧪 Quick DB Tests (JWT/RLS Simulation)
```sql
-- محاكاة مستخدم (bidder)
SELECT set_config('request.jwt.claims', json_build_object('sub','00000000-0000-0000-0000-000000000001')::text, true);

-- محاكاة دور authenticated
SET ROLE authenticated;

-- محاولة إدراج عرض على مهمة booking → يجب أن تفشل
INSERT INTO public.task_requests(task_id, bidder_id, price, days, note)
VALUES ('<booking-task-id>', '00000000-0000-0000-0000-000000000001', 10000, 3, 'test');

-- إدراج عرض على مهمة tender → ينجح
INSERT INTO public.task_requests(task_id, bidder_id, price, days, note)
VALUES ('<tender-task-id>', '00000000-0000-0000-0000-000000000001', 15000, 5, 'can deliver fast');
```
# 
## Booking — DDL + RLS + Triggers + Quick Tests

> This section defines the scheduling subsystem (availability slots + bookings), status guards, indexes, and RLS. Store timestamps in UTC; convert to local time in the app UI.

### 0) Required extensions
```sql
create extension if not exists btree_gist;
create extension if not exists pgcrypto;
```

### 1) Enum: booking status
```sql
do $$
begin
  if not exists (
    select 1 from pg_type t join pg_namespace n on n.oid = t.typnamespace
    where t.typname = 'booking_status_enum' and n.nspname = 'public'
  ) then
    create type public.booking_status_enum as enum ('pending','confirmed','canceled','completed');
  end if;
end $$;
```

### 2) Tables
```sql
-- Provider availability windows
create table if not exists public.availability_slots (
  id uuid primary key default gen_random_uuid(),
  provider_id uuid not null,
  starts_at timestamptz not null,
  ends_at   timestamptz not null,
  is_blocked boolean not null default false,
  created_at timestamptz not null default now(),
  constraint chk_slot_time check (ends_at > starts_at)
);

-- Client bookings against specific slots
create table if not exists public.bookings (
  id uuid primary key default gen_random_uuid(),
  task_id uuid,
  provider_id uuid not null,
  client_id uuid not null,
  slot_id uuid not null references public.availability_slots(id) on delete cascade,
  status public.booking_status_enum not null default 'pending',
  note text,
  created_at timestamptz not null default now()
);

-- FKs to auth.users
alter table public.availability_slots
  add constraint fk_slots_provider
  foreign key (provider_id) references auth.users(id) on delete cascade;

alter table public.bookings
  add constraint fk_bookings_provider
  foreign key (provider_id) references auth.users(id) on delete cascade;

alter table public.bookings
  add constraint fk_bookings_client
  foreign key (client_id) references auth.users(id) on delete cascade;
```

### 3) Indexes & anti-overlap
```sql
-- Common filters
create index if not exists idx_slots_provider_starts
  on public.availability_slots (provider_id, starts_at);

create index if not exists idx_bookings_client_created
  on public.bookings (client_id, created_at desc);

create index if not exists idx_bookings_provider_created
  on public.bookings (provider_id, created_at desc);

-- Prevent double-booking the same slot when status is active
create unique index if not exists uq_bookings_slot_active
  on public.bookings (slot_id)
  where status in ('pending','confirmed');

-- Prevent overlapping slots per provider using GiST
do $$
begin
  if not exists (
    select 1 from pg_indexes where schemaname='public' and indexname='excl_slots_provider_time'
  ) then
    execute $ex$
      create index excl_slots_provider_time
      on public.availability_slots
      using gist (
        provider_id,
        tstzrange(starts_at, ends_at, '[)') with &&
      )
      where is_blocked = false;
    $ex$;
  end if;
end $$;
```

#### Optional: trigger alternative for overlap prevention
```sql
create or replace function public.fn_reject_overlapping_slots()
returns trigger language plpgsql as $$
begin
  if NEW.is_blocked = false then
    if exists (
      select 1 from public.availability_slots s
      where s.provider_id = NEW.provider_id
        and s.is_blocked = false
        and tstzrange(s.starts_at, s.ends_at, '[)') && tstzrange(NEW.starts_at, NEW.ends_at, '[)')
        and s.id <> coalesce(NEW.id, '00000000-0000-0000-0000-000000000000'::uuid)
    ) then
      raise exception 'Overlapping availability slot for provider %', NEW.provider_id;
    end if;
  end if;
  return NEW;
end $$;

drop trigger if exists trg_no_overlap_slots on public.availability_slots;
create trigger trg_no_overlap_slots
before insert or update on public.availability_slots
for each row execute function public.fn_reject_overlapping_slots();
```

### 4) Booking status transition guard
```sql
create or replace function public.fn_booking_guard()
returns trigger language plpgsql as $$
declare
  old_status public.booking_status_enum := coalesce(OLD.status, 'pending');
  new_status public.booking_status_enum := NEW.status;
begin
  if TG_OP = 'UPDATE' and old_status <> new_status then
    if old_status = 'pending' and new_status in ('confirmed','canceled') then
      -- ok
    elsif old_status = 'confirmed' and new_status in ('completed','canceled') then
      -- ok
    else
      raise exception 'Invalid booking status transition: % -> %', old_status, new_status;
    end if;
  end if;
  return NEW;
end $$;

drop trigger if exists trg_booking_guard on public.bookings;
create trigger trg_booking_guard
before update on public.bookings
for each row execute function public.fn_booking_guard();
```

### 5) Row Level Security (RLS)
```sql
alter table public.availability_slots enable row level security;
alter table public.bookings enable row level security;

-- availability_slots: anyone authenticated can read; only owner writes
drop policy if exists "slots_select_read" on public.availability_slots;
create policy "slots_select_read"
on public.availability_slots for select
to authenticated
using (true);

drop policy if exists "slots_write_owner" on public.availability_slots;
create policy "slots_write_owner"
on public.availability_slots for all
to authenticated
using (provider_id = auth.uid())
with check (provider_id = auth.uid());

-- bookings: client inserts, both parties read, provider updates (confirm/complete), client cancels
drop policy if exists "bookings_insert_by_client" on public.bookings;
create policy "bookings_insert_by_client"
on public.bookings for insert
to authenticated
with check (
  client_id = auth.uid()
  and not exists (
    select 1 from public.availability_slots s
    where s.id = slot_id and s.is_blocked = true
  )
);

drop policy if exists "bookings_select_by_parties" on public.bookings;
create policy "bookings_select_by_parties"
on public.bookings for select
to authenticated
using (
  client_id = auth.uid() or provider_id = auth.uid()
);

drop policy if exists "bookings_update_by_provider" on public.bookings;
create policy "bookings_update_by_provider"
on public.bookings for update
to authenticated
using (provider_id = auth.uid())
with check (provider_id = auth.uid());

-- client cancels only
drop policy if exists "bookings_cancel_by_client" on public.bookings;
create policy "bookings_cancel_by_client"
on public.bookings for update
to authenticated
using (client_id = auth.uid())
with check (client_id = auth.uid() and status = 'canceled');
```

### 6) Quick tests (JWT/RLS smoke)
```sql
-- set as PROVIDER
select set_config('request.jwt.claims', json_build_object('sub','<PROVIDER_UUID>','role','authenticated')::text, true);

-- create a slot
insert into public.availability_slots(provider_id, starts_at, ends_at)
values ('<PROVIDER_UUID>', now() + interval '1 day', now() + interval '1 day 1 hour')
returning *;

-- set as CLIENT
select set_config('request.jwt.claims', json_build_object('sub','<CLIENT_UUID>','role','authenticated')::text, true);

-- read slots
select id, provider_id, starts_at, ends_at from public.availability_slots order by starts_at limit 5;

-- create a booking (pending)
insert into public.bookings(provider_id, client_id, slot_id, note)
values ('<PROVIDER_UUID>','<CLIENT_UUID>','<SLOT_ID>','demo booking')
returning id, status;

-- double-book same slot → should fail
insert into public.bookings(provider_id, client_id, slot_id)
values ('<PROVIDER_UUID>','<CLIENT_UUID>','<SLOT_ID>');

-- provider confirms
select set_config('request.jwt.claims', json_build_object('sub','<PROVIDER_UUID>','role','authenticated')::text, true);
update public.bookings set status='confirmed' where id='<BOOKING_ID>' returning id,status;

-- client tries invalid update → should fail
select set_config('request.jwt.claims', json_build_object('sub','<CLIENT_UUID>','role','authenticated')::text, true);
update public.bookings set status='completed' where id='<BOOKING_ID>';

-- client cancels
update public.bookings set status='canceled' where id='<BOOKING_ID>' returning id,status;
```

> Notes
> - Store times in UTC; convert with `toLocal()` in Flutter.
> - Hide management buttons by role in UI (don’t rely only on RLS for UX).
# 
## B1 — Categories (DB-first)

> Goal: make categories dynamic (DB) while keeping current UI unchanged. We add the `categories` table, seed it, and add a nullable FK `tasks.category_id` so UI can switch later with minimal work.

### 1) Table + Indexes (Idempotent)
```sql
-- Table
create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  icon_url text,
  created_at timestamptz not null default now(),
  constraint uq_categories_name unique (name)
);

-- Case-insensitive search performance (optional)
create index if not exists idx_categories_name_lower
  on public.categories (lower(name));
```

### 2) RLS (Read-only for app clients)
```sql
alter table public.categories enable row level security;

-- Allow all authenticated users to read
create policy if not exists "categories_select_all"
on public.categories for select
to authenticated
using (true);

-- ⚠️ We intentionally DO NOT add insert/update/delete policies.
-- That keeps categories read-only from the client.
-- Admins can manage categories via SQL console or service-role backend only.
```

### 3) Seed (Idempotent upsert by name)
> Replace the list below with your preferred set. This mirrors the current in-app constants.
```sql
insert into public.categories (name, icon_url)
values
  ('Design',      null),
  ('Development', null),
  ('Marketing',   null),
  ('Photography', null),
  ('Writing',     null),
  ('Cleaning',    null),
  ('Other',       null)
on conflict (name) do nothing;
```

### 4) Tasks ↔ Categories (nullable FK)
```sql
-- Add FK column (nullable for smooth migration)
alter table public.tasks
  add column if not exists category_id uuid references public.categories(id);

-- Helpful index for filters
create index if not exists idx_tasks_category_id
  on public.tasks (category_id);

-- Optional backfill: map text-based tasks.category to categories by name
update public.tasks t
set category_id = c.id
from public.categories c
where t.category_id is null
  and c.name ilike t.category;
```

### 5) Quick Tests (JWT/RLS simulation)
```sql
-- Act as any authenticated user
select set_config('request.jwt.claims', json_build_object('sub','00000000-0000-0000-0000-000000000001','role','authenticated')::text, true);

-- Read should work
select id, name from public.categories order by name limit 10;

-- Write should fail (no insert policy)
insert into public.categories (name) values ('TestShouldFail');  -- expect RLS error
```
---

## 📚 Categories (B1) — Schema, RLS, Seed (DB‑first)

> Idempotent SQL. Safe to re-run.

```sql
-- 1) Table
create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  icon_url text,
  created_at timestamptz not null default now()
);

-- 2) Uniqueness & lookup performance
create unique index if not exists uq_categories_name
  on public.categories (lower(name));
create index if not exists idx_categories_name_lower
  on public.categories ((lower(name)));

-- 3) RLS (read-only for authenticated users)
alter table public.categories enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where policyname = 'categories_select_auth'
      and schemaname = 'public'
      and tablename  = 'categories'
  ) then
    create policy "categories_select_auth"
    on public.categories for select
    to authenticated
    using (true);
  end if;
end$$;

-- 4) Tasks: add FK category_id (nullable) and relax legacy text column
alter table public.tasks
  add column if not exists category_id uuid references public.categories(id);

create index if not exists idx_tasks_category_id
  on public.tasks (category_id);

-- Allow NULL in legacy text column to support DB-first rollout
alter table public.tasks
  alter column category drop not null,
  alter column category drop default;

-- 5) Seed (idempotent)
insert into public.categories (id, name)
values
  ('5a4767ab-ef09-4c4a-8dde-6b45c2b040e3','Cleaning'),
  ('6ec632a0-e5f1-426e-ba6a-839167f9b6ae','Design'),
  ('fe47be26-cf55-4918-9032-f75314341492','Development'),
  ('1b11a22a-1d65-4da8-9ebf-faca877c15fd','Marketing'),
  ('870360da-1eea-4a36-bdd4-2dc0f35c77f6','Other'),
  ('9550c76b-9096-4aca-b310-560b019582da','Photography'),
  ('8c357ad7-4f90-4999-b685-38f356384068','Writing')
on conflict (id) do nothing;
-- A) Status enum
do $$
begin
  if not exists (select 1 from pg_type where typname = 'booking_status_enum') then
    create type public.booking_status_enum as enum ('pending','confirmed','canceled','completed');
  end if;
end$$;

-- B) Tables
create table if not exists public.availability_slots (
  id uuid primary key default gen_random_uuid(),
  provider_id uuid not null references public.profiles(id),
  starts_at timestamptz not null,
  ends_at   timestamptz not null,
  is_blocked boolean not null default false,
  created_at timestamptz not null default now(),
  constraint chk_slots_time check (ends_at > starts_at)
);

create table if not exists public.bookings (
  id uuid primary key default gen_random_uuid(),
  task_id uuid not null references public.tasks(id) on delete cascade,
  provider_id uuid not null references public.profiles(id),
  client_id uuid not null references public.profiles(id),
  slot_id uuid not null references public.availability_slots(id),
  status public.booking_status_enum not null default 'pending',
  note text,
  created_at timestamptz not null default now()
);

-- C) Indexes
create index if not exists idx_slots_provider_starts
  on public.availability_slots (provider_id, starts_at);

create index if not exists idx_bookings_client_created
  on public.bookings (client_id, created_at desc);

create index if not exists idx_bookings_provider_created
  on public.bookings (provider_id, created_at desc);

-- Prevent double-booking on active states
create unique index if not exists uq_bookings_slot_active
  on public.bookings (slot_id)
  where status in ('pending','confirmed');

-- D) Overlap prevention (trigger — portable, no GiST dependency)
create or replace function public.fn_reject_overlapping_slots()
returns trigger language plpgsql as $$
begin
  if new.is_blocked = false then
    if exists (
      select 1 from public.availability_slots s
      where s.provider_id = new.provider_id
        and s.is_blocked = false
        and tstzrange(s.starts_at, s.ends_at, '[)') && tstzrange(new.starts_at, new.ends_at, '[)')
        and s.id <> coalesce(new.id, '00000000-0000-0000-0000-000000000000'::uuid)
    ) then
      raise exception 'Overlapping availability slot for provider %', new.provider_id;
    end if;
  end if;
  return new;
end $$;

drop trigger if exists trg_no_overlap_slots on public.availability_slots;
create trigger trg_no_overlap_slots
before insert or update on public.availability_slots
for each row execute function public.fn_reject_overlapping_slots();

-- E) RLS
alter table public.availability_slots enable row level security;
alter table public.bookings          enable row level security;

-- availability_slots
do $$
begin
  if not exists (
    select 1 from pg_policies
    where policyname='slots_select_all' and schemaname='public' and tablename='availability_slots'
  ) then
    create policy "slots_select_all"
    on public.availability_slots for select
    to authenticated
    using (true);
  end if;

  if not exists (
    select 1 from pg_policies
    where policyname='slots_cud_owner' and schemaname='public' and tablename='availability_slots'
  ) then
    create policy "slots_cud_owner"
    on public.availability_slots for all
    to authenticated
    using (provider_id = auth.uid())
    with check (provider_id = auth.uid());
  end if;
end$$;

-- bookings
do $$
begin
  if not exists (
    select 1 from pg_policies
    where policyname='bookings_select_owner_or_client' and schemaname='public' and tablename='bookings'
  ) then
    create policy "bookings_select_owner_or_client"
    on public.bookings for select
    to authenticated
    using (provider_id = auth.uid() or client_id = auth.uid());
  end if;

  if not exists (
    select 1 from pg_policies
    where policyname='bookings_insert_client_only' and schemaname='public' and tablename='bookings'
  ) then
    create policy "bookings_insert_client_only"
    on public.bookings for insert
    to authenticated
    with check (
      client_id = auth.uid()
      and not exists (
        select 1 from public.bookings b
        where b.slot_id = bookings.slot_id
          and b.status in ('pending','confirmed')
      )
    );
  end if;

  if not exists (
    select 1 from pg_policies
    where policyname='bookings_update_roles' and schemaname='public' and tablename='bookings'
  ) then
    create policy "bookings_update_roles"
    on public.bookings for update
    to authenticated
    using (
      (provider_id = auth.uid()) or (client_id = auth.uid())
    )
    with check (
      -- provider can confirm/complete; client can cancel
      (
        provider_id = auth.uid() and new.status in ('confirmed','completed')
      ) or (
        client_id = auth.uid() and new.status = 'canceled'
      )
    );
  end if;
end$$;
## ✅ Sprint 2 (Finalized) — Booking, Categories (DB-first), Portfolio (images)

**Date:** 2025-08-23

This section summarizes the DB/RLS/Storage we finalized in Sprint 2.

### A) Booking — Tables, Indexes, RLS, Trigger

```sql
-- 1) Enum for booking status
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'booking_status_enum') THEN
    CREATE TYPE public.booking_status_enum AS ENUM ('pending','confirmed','canceled','completed');
  END IF;
END$$;

-- 2) availability_slots
CREATE TABLE IF NOT EXISTS public.availability_slots (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  starts_at timestamptz NOT NULL,
  ends_at   timestamptz NOT NULL,
  is_blocked boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT chk_slot_time CHECK (ends_at > starts_at)
);

-- 3) bookings
CREATE TABLE IF NOT EXISTS public.bookings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id uuid NOT NULL REFERENCES public.tasks(id) ON DELETE CASCADE,
  provider_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  client_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  slot_id uuid NOT NULL REFERENCES public.availability_slots(id) ON DELETE CASCADE,
  status public.booking_status_enum NOT NULL DEFAULT 'pending',
  note text,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- 4) Indexes
CREATE INDEX IF NOT EXISTS idx_slots_provider_starts
  ON public.availability_slots (provider_id, starts_at);

CREATE INDEX IF NOT EXISTS idx_bookings_client_created
  ON public.bookings (client_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_bookings_provider_created
  ON public.bookings (provider_id, created_at DESC);

-- Prevent double-booking of an active slot
CREATE UNIQUE INDEX IF NOT EXISTS uq_bookings_slot_active
  ON public.bookings (slot_id)
  WHERE status IN ('pending','confirmed');

-- 5) Overlap protection (trigger)
CREATE OR REPLACE FUNCTION public.fn_reject_overlapping_slots() RETURNS trigger AS $$
BEGIN
  IF NEW.is_blocked = false THEN
    IF EXISTS (
      SELECT 1 FROM public.availability_slots s
      WHERE s.provider_id = NEW.provider_id
        AND s.is_blocked = false
        AND tstzrange(s.starts_at, s.ends_at, '[)') && tstzrange(NEW.starts_at, NEW.ends_at, '[)')
        AND s.id <> COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::uuid)
    ) THEN
      RAISE EXCEPTION 'Overlapping availability slot for provider %', NEW.provider_id;
    END IF;
  END IF;
  RETURN NEW;
END$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_no_overlap_slots ON public.availability_slots;
CREATE TRIGGER trg_no_overlap_slots
BEFORE INSERT OR UPDATE ON public.availability_slots
FOR EACH ROW EXECUTE FUNCTION public.fn_reject_overlapping_slots();

-- 6) RLS
ALTER TABLE public.availability_slots ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;

-- availability_slots RLS
DROP POLICY IF EXISTS slots_select_all ON public.availability_slots;
CREATE POLICY slots_select_all
ON public.availability_slots FOR SELECT
USING (true);

DROP POLICY IF EXISTS slots_owner_write ON public.availability_slots;
CREATE POLICY slots_owner_write
ON public.availability_slots FOR ALL
USING (auth.uid() = provider_id)
WITH CHECK (auth.uid() = provider_id);

-- bookings RLS
DROP POLICY IF EXISTS bookings_insert_client ON public.bookings;
CREATE POLICY bookings_insert_client
ON public.bookings FOR INSERT
WITH CHECK (
  auth.uid() = client_id AND
  NOT EXISTS (
    SELECT 1 FROM public.bookings b2
    WHERE b2.slot_id = NEW.slot_id AND b2.status IN ('pending','confirmed')
  )
);

DROP POLICY IF EXISTS bookings_select_participants ON public.bookings;
CREATE POLICY bookings_select_participants
ON public.bookings FOR SELECT
USING (
  auth.uid() = client_id OR auth.uid() = provider_id
);

DROP POLICY IF EXISTS bookings_update_transitions ON public.bookings;
CREATE POLICY bookings_update_transitions
ON public.bookings FOR UPDATE
USING (
  (auth.uid() = provider_id) OR (auth.uid() = client_id)
)
WITH CHECK (true);

CREATE TABLE IF NOT EXISTS public.categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  icon_url text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_categories_name ON public.categories (lower(name));
CREATE INDEX IF NOT EXISTS idx_categories_name_lower ON public.categories ((lower(name)));

ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS categories_select_all ON public.categories;
CREATE POLICY categories_select_all
ON public.categories FOR SELECT
USING (true);

-- tasks FK (nullable during migration)
ALTER TABLE public.tasks
  ADD COLUMN IF NOT EXISTS category_id uuid REFERENCES public.categories(id);
CREATE INDEX IF NOT EXISTS idx_tasks_category_id ON public.tasks(category_id);

-- Seed (idempotent)
INSERT INTO public.categories (id, name)
VALUES
  ('6ec632a0-e5f1-426e-ba6a-839167f9b6ae','Design'),
  ('fe47be26-cf55-4918-9032-f75314341492','Development'),
  ('1b11a22a-1d65-4da8-9ebf-faca877c15fd','Marketing'),
  ('9550c76b-9096-4aca-b310-560b019582da','Photography'),
  ('8c357ad7-4f90-4999-b685-38f356384068','Writing'),
  ('5a4767ab-ef09-4c4a-8dde-6b45c2b040e3','Cleaning'),
  ('870360da-1eea-4a36-bdd4-2dc0f35c77f6','Other')
ON CONFLICT (id) DO NOTHING;

-- Table
CREATE TABLE IF NOT EXISTS public.portfolio_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  title text NOT NULL,
  description text,
  image_path text, -- storage path, not public URL
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_portfolio_owner_created
  ON public.portfolio_items (owner_id, created_at DESC);

ALTER TABLE public.portfolio_items ENABLE ROW LEVEL SECURITY;

-- RLS
DROP POLICY IF EXISTS portfolio_select_owner_or_public ON public.portfolio_items;
CREATE POLICY portfolio_select_owner_or_public
ON public.portfolio_items FOR SELECT
USING (true);

DROP POLICY IF EXISTS portfolio_crud_owner ON public.portfolio_items;
CREATE POLICY portfolio_crud_owner
ON public.portfolio_items FOR ALL
USING (auth.uid() = owner_id)
WITH CHECK (auth.uid() = owner_id);
-- Create bucket (SQL-compatible signature)
SELECT storage.create_bucket('portfolio', false, false, NULL);

-- Storage RLS
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE policyname = 'portfolio_insert_auth'
      AND schemaname = 'storage'
      AND tablename  = 'objects'
  ) THEN
    CREATE POLICY "portfolio_insert_auth"
    ON storage.objects FOR INSERT TO authenticated
    WITH CHECK (
      bucket_id = 'portfolio' AND owner = auth.uid()
    );
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE policyname = 'portfolio_select_auth'
      AND schemaname = 'storage'
      AND tablename  = 'objects'
  ) THEN
    CREATE POLICY "portfolio_select_auth"
    ON storage.objects FOR SELECT TO authenticated
    USING (bucket_id = 'portfolio');
  END IF;
END$$;

### 6) Notes
- Keep using the in-app constants for now; UI will switch to DB later.
- When ready to manage from the app, add explicit admin policies (e.g., match `auth.uid()` to an `admins` table), or perform writes via server-side service-role.
- `tasks.category_id` is optional; new UI can pass it, and old UI can keep using `tasks.category` text until fully migrated.