Here’s a detailed English description of your idea, written as a clear product + system concept.

Concept: Direct Chat Offers (Chat-to-Work Flow)

You want a 1-to-1 chat between a Client and a Freelancer to act as a “deal-making room”, where the freelancer can send a formal offer directly inside the conversation, without creating a Task and without using Booking.

This offer is not just a message. It is a real business object in the system with its own lifecycle, payment flow, and work tracking. Once the client accepts (and pays), it automatically becomes an active “work item” that appears in both users’ dashboards and follows the same work cycle your app already uses.

In short:
Chat → Offer → Payment → Work Dashboard → Delivery → Completion

⸻

What the Offer Represents

A Direct Offer is essentially a micro-contract between two users.

It contains structured details like:
	•	Service title or short summary (optional)
	•	Description / scope (what will be delivered)
	•	Price
	•	Duration (days)
	•	Extra notes or conditions (optional)

It has a status (sent, accepted, active, delivered, completed, canceled, etc.) and a payment status (unpaid, held in escrow, released, refunded).

⸻

Why This Feature Exists

Many real freelancing deals start like this:
	•	The client and freelancer talk privately.
	•	They agree on a custom service.
	•	The freelancer wants to turn the agreement into a trackable, payable job without forcing the client to post a public task or go through booking.

So your feature gives a fast path:
	•	No public marketplace flow.
	•	No tender/bidding flow.
	•	No booking slot flow.
Just direct agreement with proper tracking and payment.

⸻

How It Works in the App (User Experience)

1) Conversation starts

Client and Freelancer are chatting in a private conversation.

2) Freelancer creates an offer inside chat

The freelancer taps a button like “Make Offer”.
A simple offer composer opens (bottom sheet / modal):
	•	Price
	•	Duration
	•	Scope notes (optional)
Then the freelancer taps Send Offer.

3) The offer appears as a structured card inside the chat

In the message list, the offer is displayed as a rich “Offer Card” (not plain text).
The client can view details and respond.

4) Client accepts and pays

The client clicks Accept & Pay.
Payment happens using your wallet/escrow logic:
	•	Funds are held (escrow) when the offer is accepted.
	•	The offer becomes an active work item.

5) Offer becomes Work in the Dashboard

Now the system treats it like real work:
	•	It appears in the Client’s dashboard under active jobs.
	•	It appears in the Freelancer’s dashboard under active jobs.
	•	A timeline / work log tracks every major action.

6) Delivery and completion flow

The freelancer marks the work as delivered (or sends deliverables).
The client approves.
The system releases escrow funds to the freelancer (minus fees if you have them).
The offer ends as Completed.

⸻

How It Connects to Your Existing System

This feature is designed to reuse your existing foundation instead of inventing a new world:
	•	Chat system: messages + conversation already exist.
	•	Wallet / escrow: payment events already exist.
	•	Work lifecycle: dashboards and work logs already exist.

So Direct Offers become a new “entity type” that plugs into:
	•	payments (as a related entity)
	•	work logs / timeline
	•	dashboards (active/completed lists)

This keeps your app consistent: even if a job starts from chat, it still ends up in the same operational pipeline as everything else.

⸻

Key Value
	•	Makes the app feel “real” for freelancers: they can close deals instantly.
	•	Removes friction: no task posting, no booking constraints.
	•	Still keeps structure: offers are tracked, paid, and auditable.
	•	Fits scale: later you can add revisions, attachments, milestones, dispute handling, and ratings without changing the core idea.
تمام. راح أبني لك “Chat-to-Offer” flow مضبوط: محادثة DM بين شخصين، الفريلانسر يسوي Offer مو مرتبط لا بـ Booking ولا بـ Task، والكلينت يقدر يقبله ويدفع، وبعدين يصير “Work Item” ينضاف للـ Dashboard ويمشي بنفس الـ lifecycle مال التطبيق.

الفكرة تستغل اللي عندك جاهز بالسيستم:
	•	عندك chat + conversations + messages جاهزة.  ￼
	•	وعندك message types أصلا داعمة للـ offer/offer_update/offer_accepted/offer_rejected.  ￼
	•	وعندك wallet/escrow flows (held/released/refunded) جاهزة ومثبتة بالتطبيق.  ￼
	•	وعندك work_logs كـ timeline موحد ينربط على entities.  ￼
	•	والـ MVVM flow واضح عندك (View → ViewModel → Service/Repo → Supabase).  ￼

⸻

1) Entities الجديدة اللي نحتاجها (DB)

Direct Offer Table (جديد)

اسم مقترح: direct_offers

الفكرة: هذا هو “العقد” اللي يطلع من الشات.

Columns الأساسية:
	•	id uuid PK
	•	conversation_id uuid FK → conversations.id
	•	client_id uuid FK → profiles.id
	•	freelancer_id uuid FK → profiles.id
	•	title text (اختياري، مثال: “Logo Design”)
	•	description text (اختياري)
	•	price numeric (أو bigint cents)
	•	days int (مدة)
	•	status enum/text
	•	payment_status نفس payment_status_enum عندك (unpaid/held/released/refunded)  ￼
	•	created_at, updated_at

ليش conversation_id؟
حتى يصير الـ Offer “جزء من الشات” وبنفس الوقت ينفذ حياة الـ Work بدون Task/Booking.

Work Logs (موجود) بس نوسعه

انت أصلا عندك work_logs polymorphic على task/booking.  ￼
نضيف نوع ثالث:
	•	related_entity_type = 'direct_offer'
	•	related_entity_id = direct_offers.id

حتى أي خطوة بالـ lifecycle تتسجل تايملاين موحد.

⸻

2) Life Cycle (State Machine) للـ Direct Offer

DirectOfferStatus (جديد)
	•	draft (بس داخل UI قبل الإرسال)
	•	sent
	•	accepted
	•	rejected
	•	paid_request_pending (اختياري إذا تريد pay-first approval مثل booking v2)
	•	active
	•	delivered
	•	completed
	•	canceled
	•	refunded

انت عندك booking lifecycle قوي (pay-first + guard) وتكدر تستلهمه هنا.

⸻

3) Diagram 1: Sequence Diagram (من الشات إلى الـ Dashboard)

sequenceDiagram
  autonumber
  participant C as Client (App)
  participant F as Freelancer (App)
  participant VM as Chat/Offer ViewModel
  participant S as OfferService (Supabase)
  participant DB as Supabase DB
  participant W as Wallet/RPC

  Note over C,F: Conversation exists (DM) via conversations/messages
  F->>VM: Tap "Make Offer" inside chat
  VM->>S: createDirectOffer(draft data)
  S->>DB: INSERT direct_offers(status='sent', payment_status='unpaid')
  S->>DB: INSERT messages(type='offer', payload={offer_id, price, days})
  DB-->>S: OK
  S-->>VM: Offer created + message sent
  VM-->>F: Show Offer bubble card in chat

  C->>VM: Open offer card (from chat bubble)
  VM->>S: fetchOffer(offer_id)
  S->>DB: SELECT direct_offers WHERE id=offer_id (RLS participant only)
  DB-->>S: offer data
  S-->>VM: offer data

  C->>VM: Accept + Pay
  VM->>W: process_payment_event(escrow_hold, related_entity_type='direct_offer', related_entity_id=offer_id)
  W->>DB: INSERT wallet_transactions + set payment_status='held'
  DB-->>W: OK
  W-->>VM: Payment held (escrow)

  VM->>S: acceptOffer(offer_id)
  S->>DB: UPDATE direct_offers status='active'
  S->>DB: INSERT messages(type='offer_accepted', payload={offer_id})
  S->>DB: INSERT work_logs(related_entity_type='direct_offer', related_entity_id=offer_id, content='Offer accepted & started')
  DB-->>S: OK

  VM-->>C: Offer moved to Work Dashboard (Active)
  VM-->>F: Offer appears in Freelancer Work Dashboard (Active)

  F->>VM: Deliver work
  VM->>S: markDelivered(offer_id)
  S->>DB: UPDATE direct_offers status='delivered'
  S->>DB: INSERT messages(type='delivery_submitted', payload={offer_id})
  DB-->>S: OK

  C->>VM: Approve & Complete
  VM->>W: process_payment_event(release_with_fee, related_entity_type='direct_offer', related_entity_id=offer_id)
  W->>DB: INSERT wallet_transactions + set payment_status='released'
  DB-->>W: OK
  VM->>S: markCompleted(offer_id)
  S->>DB: UPDATE direct_offers status='completed'
  S->>DB: INSERT work_logs(..., content='Completed')


⸻

4) Diagram 2: ERD (علاقات الداتا)

erDiagram
  PROFILES ||--o{ CONVERSATIONS : user1_id/user2_id
  CONVERSATIONS ||--o{ MESSAGES : conversation_id

  PROFILES ||--o{ DIRECT_OFFERS : client_id
  PROFILES ||--o{ DIRECT_OFFERS : freelancer_id
  CONVERSATIONS ||--o{ DIRECT_OFFERS : conversation_id

  DIRECT_OFFERS ||--o{ WORK_LOGS : related_entity_id
  DIRECT_OFFERS ||--o{ WALLET_TRANSACTIONS : related_entity_id

  PROFILES {
    uuid id PK
    text full_name
  }

  CONVERSATIONS {
    uuid id PK
    uuid user1_id
    uuid user2_id
    uuid task_id NULL
  }

  MESSAGES {
    uuid id PK
    uuid conversation_id
    uuid sender_id
    message_type_enum message_type
    jsonb payload
  }

  DIRECT_OFFERS {
    uuid id PK
    uuid conversation_id FK
    uuid client_id FK
    uuid freelancer_id FK
    numeric price
    int days
    text status
    payment_status_enum payment_status
  }

  WORK_LOGS {
    uuid id PK
    uuid related_entity_id
    text related_entity_type
  }

  WALLET_TRANSACTIONS {
    uuid id PK
    uuid user_id
    numeric amount
    text status
    uuid related_entity_id
    text related_entity_type
  }

ملاحظة: messages.message_type_enum أصلا عندك بيه offer و offer_update وغيرها.  ￼

⸻

5) الربط بالـ UI داخل التطبيق (بدون ما نخرب MVVM)

New Feature Module مقترح
lib/features/direct_offers/ ... (مثل باقي الميزات)  ￼

داخل ChatScreen
	•	زر:
Make Offer
سطر إنكليزي
زر “سوي عرض” يطلع BottomSheet

BottomSheet: Offer Composer
	•	price
	•	days
	•	note/description (اختياري)
	•	زر Send

داخل الرسائل (Chat bubbles)
	•	إذا message_type == offer:
	•	نعرض OfferCard (Price + Days + Status)
	•	Buttons للكلينت: Accept & Pay / Reject
	•	Buttons للفريلانسر: Update Offer (إذا بعده sent) / Cancel

Dashboard

نضيف Tab أو Section:
	•	“Work” (يعرض active/delivered/completed direct offers)
	•	نفس تجربة Orders بس entity جديد.

⸻

6) أهم قرارات أمان (RLS + Guards)

هذا لازم يكون “حديد” لأن عروض خارج Tasks/Bookings ممكن تصير spam أو تلاعب:

RLS على direct_offers
	•	SELECT: فقط client_id أو freelancer_id
	•	INSERT: بس freelancer_id = auth.uid() (إذا تريد تمنع الكلينت يسوي offer)
	•	UPDATE:
	•	freelancer يقدر يعدل إذا status=sent فقط
	•	client يقدر يقبل/يرفض
	•	أي transition حساس يفضل Trigger/RPC guard مثل booking guard  ￼

Guard Trigger
	•	يمنع:
	•	Accept بدون payment held (إذا تريد pay-first)
	•	Update بعد accept
	•	Deliver قبل active
	•	Complete قبل delivered

⸻

7) التنفيذ “بالضبط شنو نسوي” كخطوات
	1.	DB

	•	Create table direct_offers
	•	Add enum/status constraints + indexes
	•	Add RLS policies
	•	Add trigger fn_direct_offer_guard() (مثل booking guard style)  ￼

	2.	Chat integration

	•	عند إرسال offer:
	•	INSERT direct_offers
	•	INSERT messages(type=‘offer’, payload يحتوي offer_id + price/days)
	•	عند update:
	•	UPDATE direct_offers
	•	INSERT messages(type=‘offer_update’)

	3.	Payment integration

	•	reuse process_payment_event RPC بس نمرر:
	•	related_entity_type='direct_offer'
	•	related_entity_id=offer_id

	4.	Dashboard

	•	DirectOffersScreen: list by status
	•	Details screen: timeline (work_logs) + actions

⸻

