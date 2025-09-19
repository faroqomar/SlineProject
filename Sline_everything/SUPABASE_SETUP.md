تمام — قرأت الملف كاملًا ورتّبت لك كل شيء في وثيقة واحدة “مختصرة-واضحة” بدون حذف أي معلومة مهمة. تقدر تنسخ المحتوى أدناه وتحطه مكان الملف الحالي مباشرة.

⸻

إعداد Supabase لمشروع SLine — قاعدة البيانات + RLS + Realtime + التخزين

آخر تحديث: 2025-09-01
هذه الوثيقة هي المرجع الوحيد النهائي (Single Source of Truth) لكل ما يخص: الجداول، الـ enums، العلاقات، الفهارس، سياسات RLS، التريغرز/الدوال، التخزين، Realtime، وملاحظات دمج الـ SDK.
كل سكربتات SQL هنا idempotent (تقدر تعيد تشغيلها بأمان).

ثوابت مهمة
	•	NIL_UUID = 00000000-0000-0000-0000-000000000000
	•	جميع الأوقات مخزّنة بتوقيت UTC (حوّل في الواجهة بـ toLocal()).
	•	الهوية تأتي من auth.users؛ بيانات الملف الشخصي للاستخدام في التطبيق داخل public.profiles.

⸻

1) ملخص سريع (TL;DR)
	•	الجداول الأساسية:
profiles, users, roles, user_roles, tasks, task_requests, favorites,
conversations, messages, availability_slots, bookings, categories, portfolio_items.
	•	الأنواع (Enums): task_type_enum, booking_status_enum, message_type_enum.
	•	المرفقات: سلة خاصة chat-attachments + Signed URLs، وسلة portfolio لأعمال البورتفوليو.
	•	Realtime: مفعّل على messages وconversations.
	•	RLS: وصول للمحادثات/الرسائل للمشاركين فقط، عروض (offers) بحراسة مالك المهمة، حجوزات بصلاحيات دورية واضحة.
	•	فهارس: مسارات ساخنة (شات، مهام، حجوزات، تصنيفات، بورتفوليو).
	•	تريغرز/دوال: منع عروض على مهام booking، تحقق حمولة العرض، حارس انتقالات الحجز، منع تداخل المواعيد، حارس إنشاء المحادثات، تعيين تلقائي عند قبول العرض.
	•	ملاحظات SDK (Flutter/Dart): استخدام .in_() بدل inFilter()، ترتيب/حد على جداول فرعية، التعامل الآمن مع last_message، upsert مع Realtime.

⸻

2) نظرة على نموذج البيانات (ER مختصر)

profiles(id) ──< tasks(user_id)
      │             │
      │             └─< task_requests(task_id, bidder_id)
      │
      ├─< favorites(client_id → freelancer_id)
      │
      ├─< conversations(user1_id, user2_id, [task_id], initiated_by)
      │          └─< messages(conversation_id, sender_id, receiver_id, content, attachments, message_type, payload)
      │
      ├─< availability_slots(provider_id)
      │          └─< bookings(slot_id, provider_id, client_id, task_id)
      │
      └─< portfolio_items(owner_id)

categories(id) ──< tasks(category_id)

قيود فريدة/حراس مهمة:
	•	محادثة واحدة لكل (زوج مستخدمين, مهمة|بدون):
unique (least(user1_id,user2_id), greatest(user1_id,user2_id), coalesce(task_id, NIL_UUID))
	•	حجز نشط واحد لكل Slot (statuses: pending,confirmed).
	•	عرض Pending واحد لكل (task_id, bidder_id).

⸻

3) الـ Enums (idempotent)

-- نوع المهمة
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'task_type_enum') THEN
    CREATE TYPE public.task_type_enum AS ENUM ('tender','booking');
  END IF;
END$$;

-- حالات الحجز
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'booking_status_enum') THEN
    CREATE TYPE public.booking_status_enum AS ENUM ('pending','confirmed','canceled','completed');
  END IF;
END$$;

-- أنواع رسائل الشات
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'message_type_enum') THEN
    CREATE TYPE public.message_type_enum AS ENUM (
      'text','offer','offer_update','offer_accepted','offer_rejected',
      'delivery_submitted','end_early_request','dispute_report'
    );
  END IF;
END$$;


⸻

4) الجداول + الهدف من كل جدول

4.1 profiles
	•	الغرض: هوية التطبيق المرتبطة بـ auth.users.
	•	الأعمدة: id (PK→auth.users.id), full_name, avatar_url, created_at default now().

4.2 users (جدول خفيف للتطبيق)
	•	ملاحظة: استخدم profiles للربط والعرض.
	•	الأعمدة: id, full_name, email, avatar_url, phone, created_at.

4.3 roles / user_roles
	•	roles: تعريف الأدوار (client, freelancer…).
	•	user_roles: ربط M2M بين المستخدمين والأدوار.

4.4 tasks (المهام)
	•	الأعمدة:
id, user_id (FK→auth.users.id), title, description, budget, deadline,
category (نصي/تراثي), skills text[], status (open|assigned|closed),
task_type task_type_enum default 'tender',
session_price_bigint, hour_rate_bigint,
assigned_freelancer_id (FK→profiles.id, nullable),
category_id (FK→categories.id, nullable),
created_at.
	•	فهارس:

CREATE INDEX IF NOT EXISTS idx_tasks_user_status_created
  ON public.tasks (user_id, status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_tasks_type_created_at
  ON public.tasks (task_type, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_tasks_assigned_freelancer
  ON public.tasks (assigned_freelancer_id);

CREATE INDEX IF NOT EXISTS idx_tasks_category_id
  ON public.tasks (category_id);

4.5 task_requests (العروض/المناقصات)
	•	الغرض: عروض على مهام tender فقط.
	•	الأعمدة:
id, task_id (FK), bidder_id (FK→profiles.id), price BIGINT NOT NULL,
days INT NOT NULL, note, status ('pending','accepted','rejected') DEFAULT 'pending', created_at.
	•	فهارس/قيود:

CREATE INDEX IF NOT EXISTS idx_task_requests_task_created
  ON public.task_requests (task_id, created_at DESC);

CREATE UNIQUE INDEX IF NOT EXISTS uq_task_requests_unique_pending_per_user
  ON public.task_requests (task_id, bidder_id)
  WHERE status = 'pending';

4.6 favorites
	•	الغرض: تمكين محادثات عميل ↔ مستقل خارج سياق مهمة.
	•	الأعمدة: id, client_id (FK), freelancer_id (FK), created_at, unique (client_id, freelancer_id).
	•	فهارس: على client_id, freelancer_id.

4.7 conversations (المحادثات)
	•	الأعمدة:
id, task_id (FK nullable), user1_id (FK), user2_id (FK),
initiated_by (FK), created_at.
	•	قيود/فهارس:

CREATE UNIQUE INDEX IF NOT EXISTS uq_conversations_pair_task
ON public.conversations (
  least(user1_id, user2_id),
  greatest(user1_id, user2_id),
  coalesce(task_id, '00000000-0000-0000-0000-000000000000')
);

CREATE INDEX IF NOT EXISTS idx_conversations_task  ON public.conversations (task_id);
CREATE INDEX IF NOT EXISTS idx_conversations_user1 ON public.conversations (user1_id);
CREATE INDEX IF NOT EXISTS idx_conversations_user2 ON public.conversations (user2_id);

4.8 messages (رسائل الشات)
	•	الأعمدة:
id, conversation_id (FK), sender_id (FK), receiver_id (FK, nullable),
content text (قد يكون فارغًا إذا الرسالة مرفق فقط),
attachment_url text, attachment_type text ('image'|'file'),
attachment_name text, attachment_size int,
message_type message_type_enum default 'text',
payload jsonb default '{}' (مثل {price, days, note})،
created_at.
	•	فهارس:

CREATE INDEX IF NOT EXISTS idx_messages_convo_created
  ON public.messages (conversation_id, created_at);

4.9 نظام الحجوزات (Booking)

الجداول:
	•	availability_slots (نوافذ توفر المزوّد)
	•	bookings (حجوزات العميل على Slot محدد)

CREATE TABLE IF NOT EXISTS public.availability_slots (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id uuid NOT NULL REFERENCES public.profiles(id),
  starts_at timestamptz NOT NULL,
  ends_at   timestamptz NOT NULL,
  is_blocked boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT chk_slot_time CHECK (ends_at > starts_at)
);

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

CREATE INDEX IF NOT EXISTS idx_slots_provider_starts
  ON public.availability_slots (provider_id, starts_at);

CREATE INDEX IF NOT EXISTS idx_bookings_client_created
  ON public.bookings (client_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_bookings_provider_created
  ON public.bookings (provider_id, created_at DESC);

CREATE UNIQUE INDEX IF NOT EXISTS uq_bookings_slot_active
  ON public.bookings (slot_id)
  WHERE status IN ('pending','confirmed');

4.10 categories (إصدار DB أولًا)

CREATE TABLE IF NOT EXISTS public.categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  icon_url text,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS uq_categories_name
  ON public.categories (lower(name));
CREATE INDEX IF NOT EXISTS idx_categories_name_lower
  ON public.categories ((lower(name)));

ALTER TABLE public.tasks
  ADD COLUMN IF NOT EXISTS category_id uuid REFERENCES public.categories(id);
CREATE INDEX IF NOT EXISTS idx_tasks_category_id ON public.tasks (category_id);

-- Seed (idempotent)
INSERT INTO public.categories (id, name) VALUES
  ('6ec632a0-e5f1-426e-ba6a-839167f9b6ae','Design'),
  ('fe47be26-cf55-4918-9032-f75314341492','Development'),
  ('1b11a22a-1d65-4da8-9ebf-faca877c15fd','Marketing'),
  ('9550c76b-9096-4aca-b310-560b019582da','Photography'),
  ('8c357ad7-4f90-4999-b685-38f356384068','Writing'),
  ('5a4767ab-ef09-4c4a-8dde-6b45c2b040e3','Cleaning'),
  ('870360da-1eea-4a36-bdd4-2dc0f35c77f6','Other')
ON CONFLICT (id) DO NOTHING;

4.11 portfolio_items + التخزين

CREATE TABLE IF NOT EXISTS public.portfolio_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  title text NOT NULL,
  description text,
  image_path text, -- مسار في Storage
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_portfolio_owner_created
  ON public.portfolio_items (owner_id, created_at DESC);

ملاحظة: جداول/لقطات قديمة موجودة (conversation_presence, test_table, user_conversations) — موثقة في الملحق أ (لقطة الصلاحيات). راجع لاحقًا للحذف/التقييد إن لم تكن لازمة.

⸻

5) سياسات RLS (ملخّص + SQL جاهز)

5.1 tasks
	•	مفعّل RLS.
	•	الإدراج/التعديل/الحذف: المالك فقط (auth.uid() = user_id).
	•	القراءة: كل مستخدم مصدّق.

5.2 task_requests

ALTER TABLE public.task_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY IF NOT EXISTS owner_selects_offers
ON public.task_requests FOR SELECT
USING (EXISTS (
  SELECT 1 FROM public.tasks t
  WHERE t.id = task_requests.task_id
    AND t.user_id = auth.uid()
    AND t.task_type = 'tender'::task_type_enum
));

CREATE POLICY IF NOT EXISTS bidder_selects_own_offers
ON public.task_requests FOR SELECT
USING (bidder_id = auth.uid());

CREATE POLICY IF NOT EXISTS bidder_inserts_offer
ON public.task_requests FOR INSERT
WITH CHECK (bidder_id = auth.uid() AND EXISTS (
  SELECT 1 FROM public.tasks t
  WHERE t.id = task_requests.task_id
    AND t.task_type = 'tender'::task_type_enum
));

CREATE POLICY IF NOT EXISTS owner_updates_offer_status
ON public.task_requests FOR UPDATE
USING (EXISTS (
  SELECT 1 FROM public.tasks t
  WHERE t.id = task_requests.task_id
    AND t.user_id = auth.uid()
    AND t.task_type = 'tender'::task_type_enum
));

5.3 favorites

ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;
CREATE POLICY IF NOT EXISTS favorites_select_own  ON public.favorites FOR SELECT USING (client_id = auth.uid());
CREATE POLICY IF NOT EXISTS favorites_insert_own  ON public.favorites FOR INSERT WITH CHECK (client_id = auth.uid());
CREATE POLICY IF NOT EXISTS favorites_delete_own  ON public.favorites FOR DELETE USING (client_id = auth.uid());

5.4 conversations

ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;

CREATE POLICY IF NOT EXISTS conversations_select_participants
ON public.conversations FOR SELECT
USING (auth.uid() = user1_id OR auth.uid() = user2_id);

CREATE POLICY IF NOT EXISTS conversations_insert_client_only
ON public.conversations FOR INSERT
WITH CHECK (
  initiated_by = auth.uid()
  AND (user1_id = auth.uid() OR user2_id = auth.uid())
  AND (
    (task_id IS NOT NULL AND EXISTS (
      SELECT 1 FROM public.tasks t WHERE t.id = task_id AND t.user_id = auth.uid()
    ))
    OR
    (task_id IS NULL AND EXISTS (
      SELECT 1 FROM public.favorites f
      WHERE f.client_id = auth.uid()
        AND f.freelancer_id = CASE
          WHEN user1_id = auth.uid() THEN user2_id ELSE user1_id
        END
    ))
  )
);

5.5 messages

ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY IF NOT EXISTS messages_select_participants
ON public.messages FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.conversations c
    WHERE c.id = messages.conversation_id
      AND (c.user1_id = auth.uid() OR c.user2_id = auth.uid())
  )
);

CREATE POLICY IF NOT EXISTS messages_insert_participants_only
ON public.messages FOR INSERT
WITH CHECK (
  sender_id = auth.uid()
  AND EXISTS (
    SELECT 1 FROM public.conversations c
    WHERE c.id = messages.conversation_id
      AND (c.user1_id = auth.uid() OR c.user2_id = auth.uid())
  )
  AND (
    message_type NOT IN ('offer_accepted','offer_rejected')
    OR EXISTS (
      SELECT 1 FROM public.conversations c
      LEFT JOIN public.tasks t ON t.id = c.task_id
      WHERE c.id = messages.conversation_id
        AND (
          (c.task_id IS NOT NULL AND t.user_id = auth.uid())  -- لو مرتبطة بمهمة: مالك المهمة فقط
          OR
          (c.task_id IS NULL AND c.initiated_by = auth.uid()) -- بدون مهمة: المُبادر فقط
        )
    )
  )
);

5.6 الحجز (availability_slots, bookings)

ALTER TABLE public.availability_slots ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings          ENABLE ROW LEVEL SECURITY;

CREATE POLICY IF NOT EXISTS slots_select_all
ON public.availability_slots FOR SELECT TO authenticated USING (true);

CREATE POLICY IF NOT EXISTS slots_cud_owner
ON public.availability_slots FOR ALL TO authenticated
USING (provider_id = auth.uid()) WITH CHECK (provider_id = auth.uid());

CREATE POLICY IF NOT EXISTS bookings_select_owner_or_client
ON public.bookings FOR SELECT TO authenticated
USING (provider_id = auth.uid() OR client_id = auth.uid());

CREATE POLICY IF NOT EXISTS bookings_insert_client_only
ON public.bookings FOR INSERT TO authenticated
WITH CHECK (
  client_id = auth.uid()
  AND NOT EXISTS (
    SELECT 1 FROM public.bookings b
    WHERE b.slot_id = bookings.slot_id AND b.status IN ('pending','confirmed')
  )
);

CREATE POLICY IF NOT EXISTS bookings_update_roles
ON public.bookings FOR UPDATE TO authenticated
USING ((provider_id = auth.uid()) OR (client_id = auth.uid()))
WITH CHECK (
  (provider_id = auth.uid() AND NEW.status IN ('confirmed','completed'))
  OR (client_id = auth.uid() AND NEW.status = 'canceled')
);

5.7 categories

ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
CREATE POLICY IF NOT EXISTS categories_select_auth
ON public.categories FOR SELECT TO authenticated USING (true);

5.8 portfolio_items

ALTER TABLE public.portfolio_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY IF NOT EXISTS portfolio_select_owner_or_public
ON public.portfolio_items FOR SELECT USING (true);
CREATE POLICY IF NOT EXISTS portfolio_crud_owner
ON public.portfolio_items FOR ALL
USING (auth.uid() = owner_id) WITH CHECK (auth.uid() = owner_id);


⸻

6) التريغرز/الدوال (حُرّاس ومنطق تلقائي)

6.1 عروض المهام (tender فقط + قيَم موجبة)

CREATE OR REPLACE FUNCTION public.trg_check_task_is_tender() RETURNS trigger AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.tasks t
                 WHERE t.id = NEW.task_id AND t.task_type = 'tender') THEN
    RAISE EXCEPTION 'Offers are only allowed on tender tasks';
  END IF;
  IF NEW.price <= 0 OR NEW.days <= 0 THEN
    RAISE EXCEPTION 'Offer price and days must be positive';
  END IF;
  RETURN NEW;
END;$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_task_requests_only_for_tender ON public.task_requests;
CREATE TRIGGER trg_task_requests_only_for_tender
  BEFORE INSERT ON public.task_requests
  FOR EACH ROW EXECUTE FUNCTION public.trg_check_task_is_tender();

(اختياري) قفل التعديلات غير status أثناء دورة حياة العرض — الدالة موجودة ويمكن تفعيل التريغر عند الحاجة.

6.2 حارس إنشاء المحادثات (Client-only)

CREATE OR REPLACE FUNCTION public.trg_conversations_guard() RETURNS trigger AS $$
BEGIN
  IF NEW.task_id IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1 FROM public.tasks t WHERE t.id = NEW.task_id AND t.user_id = NEW.initiated_by
    ) THEN
      RAISE EXCEPTION 'Only task owner can start a task conversation';
    END IF;
  ELSE
    IF NOT EXISTS (
      SELECT 1 FROM public.favorites f
      WHERE f.client_id = NEW.initiated_by
        AND f.freelancer_id = CASE
          WHEN NEW.user1_id = NEW.initiated_by THEN NEW.user2_id ELSE NEW.user1_id END
    ) THEN
      RAISE EXCEPTION 'Only clients can start non-task conversations with their favorites';
    END IF;
  END IF;
  RETURN NEW;
END;$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_conversations_guard ON public.conversations;
CREATE TRIGGER trg_conversations_guard
  BEFORE INSERT ON public.conversations
  FOR EACH ROW EXECUTE FUNCTION public.trg_conversations_guard();

6.3 رسائل الشات: تحقق حمولة العرض + تعيين تلقائي عند القبول

CREATE OR REPLACE FUNCTION public.trg_messages_validate_payload() RETURNS trigger AS $$
BEGIN
  IF NEW.message_type IN ('offer','offer_update') THEN
    IF NOT (NEW.payload ? 'price' AND NEW.payload ? 'days') THEN
      RAISE EXCEPTION 'Offer messages require price and days in payload';
    END IF;
  END IF;
  RETURN NEW;
END;$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_messages_validate_payload ON public.messages;
CREATE TRIGGER trg_messages_validate_payload
  BEFORE INSERT ON public.messages
  FOR EACH ROW EXECUTE FUNCTION public.trg_messages_validate_payload();

CREATE OR REPLACE FUNCTION public.trg_messages_offer_accepted() RETURNS trigger AS $$
BEGIN
  IF NEW.message_type = 'offer_accepted' THEN
    UPDATE public.tasks
      SET assigned_freelancer_id = NEW.sender_id,
          status = 'assigned'
    WHERE id = (SELECT c.task_id FROM public.conversations c WHERE c.id = NEW.conversation_id);
  END IF;
  RETURN NULL;
END;$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_messages_offer_accepted ON public.messages;
CREATE TRIGGER trg_messages_offer_accepted
  AFTER INSERT ON public.messages
  FOR EACH ROW EXECUTE FUNCTION public.trg_messages_offer_accepted();

6.4 الحجز: منع التداخل + حارس انتقال الحالة

-- منع تداخل فترات التوفر لنفس المزوّد
CREATE OR REPLACE FUNCTION public.fn_reject_overlapping_slots() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.is_blocked = FALSE THEN
    IF EXISTS (
      SELECT 1 FROM public.availability_slots s
      WHERE s.provider_id = NEW.provider_id
        AND s.is_blocked = FALSE
        AND tstzrange(s.starts_at, s.ends_at, '[)') && tstzrange(NEW.starts_at, NEW.ends_at, '[)')
        AND s.id <> COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::uuid)
    ) THEN
      RAISE EXCEPTION 'Overlapping availability slot for provider %', NEW.provider_id;
    END IF;
  END IF;
  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS trg_no_overlap_slots ON public.availability_slots;
CREATE TRIGGER trg_no_overlap_slots
BEFORE INSERT OR UPDATE ON public.availability_slots
FOR EACH ROW EXECUTE FUNCTION public.fn_reject_overlapping_slots();

-- انتقالات حالة الحجز المسموحة
CREATE OR REPLACE FUNCTION public.fn_booking_guard() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
  old_status public.booking_status_enum := COALESCE(OLD.status, 'pending');
  new_status public.booking_status_enum := NEW.status;
BEGIN
  IF TG_OP = 'UPDATE' AND old_status <> new_status THEN
    IF old_status = 'pending'   AND new_status IN ('confirmed','canceled') THEN RETURN NEW; END IF;
    IF old_status = 'confirmed' AND new_status IN ('completed','canceled') THEN RETURN NEW; END IF;
    RAISE EXCEPTION 'Invalid booking status transition: % -> %', old_status, new_status;
  END IF;
  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS trg_booking_guard ON public.bookings;
CREATE TRIGGER trg_booking_guard
BEFORE UPDATE ON public.bookings
FOR EACH ROW EXECUTE FUNCTION public.fn_booking_guard();


⸻

7) التخزين (Storage)
	•	سلال:
	•	chat-attachments (Private) — المسار المقترح: convos/<conversation_id>/<random>
	•	portfolio (Private) — صور أعمال البورتفوليو
	•	سياسات storage.objects:

-- chat-attachments
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE policyname = 'chat_attach_insert_auth'
      AND schemaname = 'storage' AND tablename = 'objects'
  ) THEN
    CREATE POLICY "chat_attach_insert_auth"
    ON storage.objects FOR INSERT TO authenticated
    WITH CHECK (bucket_id = 'chat-attachments' AND owner = auth.uid());
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE policyname = 'chat_attach_select_auth'
      AND schemaname = 'storage' AND tablename = 'objects'
  ) THEN
    CREATE POLICY "chat_attach_select_auth"
    ON storage.objects FOR SELECT TO authenticated
    USING (bucket_id = 'chat-attachments');
  END IF;
END$$;

-- portfolio
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE policyname = 'portfolio_insert_auth'
      AND schemaname = 'storage' AND tablename = 'objects'
  ) THEN
    CREATE POLICY "portfolio_insert_auth"
    ON storage.objects FOR INSERT TO authenticated
    WITH CHECK (bucket_id = 'portfolio' AND owner = auth.uid());
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE policyname = 'portfolio_select_auth'
      AND schemaname = 'storage' AND tablename = 'objects'
  ) THEN
    CREATE POLICY "portfolio_select_auth"
    ON storage.objects FOR SELECT TO authenticated
    USING (bucket_id = 'portfolio');
  END IF;
END$$;

-- تحقق من السياسات (مهم: عمود اسم السياسة هو policyname وليس polname)
SELECT policyname, schemaname, tablename, cmd
FROM pg_policies
WHERE schemaname='storage' AND tablename='objects'
ORDER BY policyname;


⸻

8) Realtime

ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
ALTER PUBLICATION supabase_realtime ADD TABLE public.conversations;

العميل (Flutter): اشترك فقط على قناة المحادثة النشطة واعمل upsert للرسالة في الذاكرة (لا تعمل refetch كامل لكل حدث).

⸻

9) ملاحظات الدمج (Flutter + Supabase Dart)
	•	استخدم .in_() بدل inFilter() (تم إصلاح خطأ undefined method).
	•	لعلاقات متداخلة (مثل last_message):
.order('created_at', foreignTable: 'messages', ascending: false) +
.limit(1, foreignTable: 'messages')
	•	استدعاءات .or(...) و .in_(...) قبل .order(...) و .limit(...).
	•	listenToMessagesRealtime() مدمجة في message_service.dart ومتصلة بـ chat_controller.dart.
	•	تعامل آمن مع last_message (قد تكون Map | List | null).
	•	تأكد أن المحادثات بدون رسائل لا تكسر الواجهة (last_message = null).

⸻

10) اختبارات دخان سريعة (JWT/RLS)

10.1 عروض (offers)

-- انتحال مستخدم مزايد
SELECT set_config('request.jwt.claims', json_build_object('sub','00000000-0000-0000-0000-000000000001','role','authenticated')::text, true);
SET ROLE authenticated;

-- إدراج على مهمة booking → يفشل
INSERT INTO public.task_requests(task_id, bidder_id, price, days, note)
VALUES ('<booking-task-id>', '00000000-0000-0000-0000-000000000001', 10000, 3, 'test');

-- إدراج على مهمة tender → ينجح
INSERT INTO public.task_requests(task_id, bidder_id, price, days, note)
VALUES ('<tender-task-id>', '00000000-0000-0000-0000-000000000001', 15000, 5, 'fast');

10.2 حجوزات

-- كمزوّد
SELECT set_config('request.jwt.claims', json_build_object('sub','<PROVIDER_UUID>','role','authenticated')::text, true);
INSERT INTO public.availability_slots(provider_id, starts_at, ends_at)
VALUES ('<PROVIDER_UUID>', now() + interval '1 day', now() + interval '1 day 1 hour') RETURNING *;

-- كعميل
SELECT set_config('request.jwt.claims', json_build_object('sub','<CLIENT_UUID>','role','authenticated')::text, true);
INSERT INTO public.bookings(provider_id, client_id, task_id, slot_id, note)
VALUES ('<PROVIDER_UUID>','<CLIENT_UUID>','<TASK_ID>','<SLOT_ID>','demo') RETURNING id,status;

-- حجز نفس الـ slot مرة ثانية → يفشل
INSERT INTO public.bookings(provider_id, client_id, task_id, slot_id)
VALUES ('<PROVIDER_UUID>','<CLIENT_UUID>','<TASK_ID>','<SLOT_ID>');

10.3 تصنيفات (قراءة فقط)

SELECT set_config('request.jwt.claims', json_build_object('sub','00000000-0000-0000-0000-000000000001','role','authenticated')::text, true);
SELECT id, name FROM public.categories ORDER BY name LIMIT 10;  -- OK
INSERT INTO public.categories (name) VALUES ('ShouldFail');     -- RLS error (متوقع)


⸻

11) الأمن: GRANTs مقابل RLS

RLS يقلل المخاطر حتى مع صلاحيات واسعة، لكن من الأفضل تقليل GRANTs المفتوحة خاصة على anon.
توصية: راجع الملحق أ، ثم نفّذ تقليص الصلاحيات (مثال):

REVOKE ALL ON TABLE public.tasks          FROM anon;
REVOKE ALL ON TABLE public.messages       FROM anon;
REVOKE ALL ON TABLE public.conversations  FROM anon;
-- أبقِ service_role للخادم فقط (لا يُستخدم في تطبيق العميل).


⸻

12) سجل التغييرات
	•	Sprint 3
	•	favorites + سياسة “عميل فقط” لبدء المحادثات + تريغر حارس.
	•	قيد فريد للمحادثة لكل زوج + مهمة.
	•	messages: إضافة message_type + payload + تحقق الحمولة.
	•	تعيين مستقل تلقائي عند offer_accepted.
	•	تشديد task_requests (tender-only + price/days موجبة).
	•	Sprint 2
	•	نظام الحجز (slots + bookings) + حارس الانتقالات + منع التداخل.
	•	التصنيفات DB-first + Seed + FK في tasks.
	•	portfolio_items + سلة portfolio وسياساتها.
	•	سابقًا
	•	دعم مرفقات الشات، Signed URLs، Realtime، وإضافة assigned_freelancer_id.

⸻

13) Troubleshooting (سريع)
	•	42703: عمود polname غير موجود → العمود الصحيح في pg_policies هو policyname، وفلتر schemaname='storage'.
	•	RLS على INSERT للتخزين → تحقق من اسم السلة، استخدام مفتاح عميل (ليس service_role)، ووجود سياسة INSERT.
	•	Signed URL يفشل → تأكد من سياسة SELECT على storage.objects للبكت الصحيح.
	•	ازدواج رسائل Realtime → استخدم upsert بالمعرّف بدل إعادة الجلب الكامل.
	•	خطأ undefined method → استبدل inFilter() بـ .in_() في Supabase Dart.

⸻

الملحق أ — لقطة الصلاحيات الحالية (GRANTS)

هذه اللقطة طويلة (من information_schema) وتُظهر أن anon لديه صلاحيات واسعة على عدة جداول. رغم أن RLS يقيّد فعليًا، يُفضّل تقليص هذه الصلاحيات قبل الإنتاج.
المحتوى كما في الملف الأصلي محفوظ هنا (القائمة الكاملة التي تبدأ بـ conversation_presence وتنتهي بـ users). استخدمها للمراجعة والتقليص بحسب الحاجة.

(القائمة الطويلة محفوظة دون تغيير — راجع قسم “Grants & Privileges — Snapshot” في النص الأصلي لديك، أو اتركها في نفس الوثيقة بعد هذا الملحق كما هي.)

⸻

ملاحظات نهائية
	•	المحادثات/الرسائل: المشاركة تُستدل من conversations وليس من receiver_id (الأخير لأغراض منطق الأعمال فقط).
	•	المرفقات: المسار المخزَّن هو مسار Storage، والعرض دائمًا عبر Signed URL قصيرة العمر.
	•	التصنيفات: متاحة قراءة فقط من العميل؛ إدارة الإضافة/التعديل عبر SQL أو خدمة بخادم بمفتاح service_role.

لو حاب أحوّل هذا كله لملف جاهز للاستبدال (Markdown) بنفس اسم ملفك، قلّي ونسلمه لك بنفس التنسيق.

6.2 حارس إنشاء المحادثات (Task-linked: non-owner only)

CREATE OR REPLACE FUNCTION public.conversations_before_insert_guard()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_other       uuid;
  v_task_owner  uuid;
  v_me          uuid := auth.uid();
  tmp           uuid;
BEGIN
  IF v_me IS NULL THEN
    RAISE EXCEPTION 'unauthenticated';
  END IF;

  -- initiated_by defaults to current user
  IF NEW.initiated_by IS NULL THEN
    NEW.initiated_by := v_me;
  END IF;
  IF NEW.initiated_by IS DISTINCT FROM v_me THEN
    RAISE EXCEPTION 'initiated_by must equal current user';
  END IF;

  -- initiator must be one of the two participants
  IF NOT (NEW.user1_id = v_me OR NEW.user2_id = v_me) THEN
    RAISE EXCEPTION 'initiator must be one of the participants';
  END IF;

  -- Task-linked conversation: owner cannot initiate; the other must be the task owner
  IF NEW.task_id IS NOT NULL THEN
    SELECT t.user_id INTO v_task_owner
    FROM public.tasks t
    WHERE t.id = NEW.task_id;

    IF v_task_owner IS NULL THEN
      RAISE EXCEPTION 'linked task not found';
    END IF;

    IF v_task_owner = v_me THEN
      RAISE EXCEPTION 'task owner cannot start a task-linked conversation';
    END IF;

    v_other := CASE WHEN NEW.user1_id = v_me THEN NEW.user2_id ELSE NEW.user1_id END;
    IF v_other IS DISTINCT FROM v_task_owner THEN
      RAISE EXCEPTION 'for a task-linked chat, the other participant must be the task owner';
    END IF;

    -- normalize order to avoid duplicates
    IF NEW.user1_id > NEW.user2_id THEN
      tmp := NEW.user1_id; NEW.user1_id := NEW.user2_id; NEW.user2_id := tmp;
    END IF;

  -- Non-task conversation: require favorite relation
  ELSE
    v_other := CASE WHEN NEW.user1_id = v_me THEN NEW.user2_id ELSE NEW.user1_id END;
    IF NOT EXISTS (
      SELECT 1
      FROM public.favorites f
      WHERE f.client_id = v_me
        AND f.freelancer_id = v_other
    ) THEN
      RAISE EXCEPTION 'to start a non-task chat, the other user must be in your favorites';
    END IF;
  END IF;

  RETURN NEW;
END
$function$;

-- Trigger (replace old name if needed)
DROP TRIGGER IF EXISTS trg_conversations_before_insert_guard ON public.conversations;
CREATE TRIGGER trg_conversations_before_insert_guard
BEFORE INSERT ON public.conversations
FOR EACH ROW EXECUTE FUNCTION public.conversations_before_insert_guard();
6.2.1 RPC: start_task_conversation_v1 (non-owner starts task chat)

```sql
DROP FUNCTION IF EXISTS public.start_task_conversation_v1(uuid);

CREATE OR REPLACE FUNCTION public.start_task_conversation_v1(p_task_id uuid)
RETURNS conversations
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_owner uuid;
  v_me    uuid := auth.uid();
  v_a     uuid;
  v_b     uuid;
  v_convo conversations;
BEGIN
  SELECT t.user_id INTO v_owner FROM tasks t WHERE t.id = p_task_id;
  IF v_owner IS NULL THEN
    RAISE EXCEPTION 'task not found' USING ERRCODE = 'P0001';
  END IF;

  IF v_owner = v_me THEN
    RAISE EXCEPTION 'task owner cannot start a task-linked conversation' USING ERRCODE = 'P0001';
  END IF;

  v_a := LEAST(v_owner, v_me);
  v_b := GREATEST(v_owner, v_me);

  SELECT * INTO v_convo
  FROM conversations
  WHERE task_id = p_task_id
    AND LEAST(user1_id, user2_id) = v_a
    AND GREATEST(user1_id, user2_id) = v_b
  LIMIT 1;

  IF FOUND THEN
    RETURN v_convo;
  END IF;

  INSERT INTO conversations (id, task_id, user1_id, user2_id, initiated_by)
  VALUES (gen_random_uuid(), p_task_id, v_a, v_b, v_me)
  RETURNING * INTO v_convo;

  RETURN v_convo;
END;
$$;

GRANT EXECUTE ON FUNCTION public.start_task_conversation_v1(uuid) TO authenticated;
> ملاحظة: إذا عندك لقسم قديم باسم “6.2 حارس إنشاء المحادثات (Client-only)”، استبدله بالكامل بالنص الجديد أعلاه.

---

# 2) Sline_Log.md
## أضِف مدخلة نسخة جديدة تحت “Version History”

ابحث عن عنوان `## 📋 Version History` وألصق المقطع التالي **مباشرة بعده**:

## Avatar Storage Setup (2025-09-19)

# Supabase Setup – Avatars Bucket

## 📦 Avatar Storage Setup (2025-09-19)

### 1. Create Bucket
```sql
select storage.create_bucket('avatars', true);
-- Allow authenticated users to insert their own avatar
create policy avatars_insert_own
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'avatars' and owner = auth.uid());

-- Allow authenticated users to select (read) their own avatar
create policy avatars_select_own
  on storage.objects for select
  to authenticated
  using (bucket_id = 'avatars' and owner = auth.uid());