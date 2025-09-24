Got it ✅ I’ll merge and re-organize both drafts you shared into one authoritative Chat Module section so nothing is missed.
Here’s the final cleaned version for DEVELOPER_GUIDE.md:

⸻

📩 Chat Module – Developer Guide

1. Human Explanation

The Chat Module enables real-time communication between clients and freelancers.
It supports:
	•	Conversations: One-to-one messaging tied either to a task (job discussion) or direct client–freelancer contact.
	•	Messages: Text and file-based communication.
	•	Attachments: Images/files uploaded to Supabase Storage with signed URLs.
	•	UI Widgets: Message bubbles, attachment previews, and list screens for conversations.

User Flow
	1.	A client posts a task.
	2.	A freelancer submits an offer.
	3.	When the offer is accepted → a conversation opens.
	4.	Both parties can exchange text and attachments in this chat.

⸻

2. Database & Supabase Mapping

Column / Table	Type	Purpose / Usage	Notes
conversations.id	uuid	Primary key for a chat	RLS: must include current user in members
conversations.task_id	uuid	Links conversation to a task	Optional
conversations.members	uuid[]	Array of profile IDs (client + freelancer)	Used for RLS checks
messages.id	uuid	Primary key	
messages.conversation_id	uuid	FK → conversations.id	
messages.sender_id	uuid	FK → profiles.id	
messages.content	text	Message text	Nullable if attachment-only
messages.attachment_url	text	Signed URL for file in attachments bucket	
messages.created_at	timestamptz	Ordering + history	Default now()
storage.objects (attachments)	file	Actual uploaded files	RLS: allow read/write only for conversation members

Example RLS Policies

-- Conversations: only participants can read
create policy "Users can read their conversations"
on conversations for select
using (auth.uid() = any(members));

-- Messages: only participants can insert
create policy "Users can send messages in joined conversations"
on messages for insert
with check (
  auth.uid() = sender_id
  and auth.uid() = any(
    (select members from conversations where id = conversation_id)
  )
);


⸻

3. File Inventory

File	Role
chat_controller.dart	Orchestrates chat logic (loading conversations/messages, sending, updating state).
conversation_model.dart	Data model for conversations. Contains members, optional task link.
message_model.dart	Data model for messages (content, sender, attachment).
message_service.dart	CRUD operations for messages in Supabase.
attachment_service.dart	Manages storage operations (upload, delete, signed URLs).
attachment_payload.dart	Metadata wrapper for attachments (path, mime type, etc.).
attachment_exceptions.dart	Custom errors for attachments (invalid type, oversize, etc.).
compress_service.dart	Compresses images before upload.
pick_image_service.dart	Wraps image_picker for selecting local images.
upload_service.dart	Low-level file upload logic to Supabase Storage.
send_attachment_usecase.dart	Combines compression + upload + message creation.
mime_utils.dart	Helpers to detect and validate MIME types.
attachment_message_tile.dart	UI widget to render an attachment in a chat bubble.
message_bubble.dart	UI for text messages with sender/receiver styling.
chat_screen.dart	Screen for a single conversation (messages list + input bar).
messages_screen.dart	Lists all conversations.


⸻

4. ERD Diagram

Mermaid

erDiagram
  profiles {
    uuid id PK
    text full_name
    text avatar_url
  }
  conversations {
    uuid id PK
    uuid task_id FK
    uuid[] members
  }
  messages {
    uuid id PK
    uuid conversation_id FK
    uuid sender_id FK
    text content
    text attachment_url
    timestamptz created_at
  }
  tasks {
    uuid id PK
    text title
  }

  profiles ||--o{ conversations : "members"
  conversations ||--o{ messages : "has"
  profiles ||--o{ messages : "sends"
  tasks ||--o{ conversations : "optional link"

ASCII Fallback

profiles (id, name, avatar)
   |         \
   |          \ sends
   |           \
conversations ----< messages
   | (members[])     (content, attachment_url)
   |
   +-- tasks (optional link)


⸻

5. Supabase Snippets

SQL

-- Insert new conversation
insert into conversations (id, members, task_id)
values (gen_random_uuid(), array['<client>', '<freelancer>'], '<task_id>');

-- Insert new message
insert into messages (conversation_id, sender_id, content)
values ('<conv_id>', auth.uid(), 'Hello!');

-- Query messages
select * from messages
where conversation_id = '<conv_id>'
order by created_at;

Dart (supabase_flutter)

// Send text message
await supabase.from('messages').insert({
  'conversation_id': convId,
  'sender_id': supabase.auth.currentUser!.id,
  'content': messageText,
});

// Upload + send attachment
final file = File(pickedImage.path);
final path = 'attachments/${supabase.auth.currentUser!.id}/${DateTime.now().toIso8601String()}';
await supabase.storage.from('attachments').upload(path, file);

final signedUrl = await supabase.storage
    .from('attachments')
    .createSignedUrl(path, 3600);

await supabase.from('messages').insert({
  'conversation_id': convId,
  'sender_id': supabase.auth.currentUser!.id,
  'attachment_url': signedUrl,
});


⸻

6. Error Handling

Error	Cause	User-friendly message
permission denied for table messages	User not in conversation	“You are not allowed to send messages in this chat.”
new row violates row-level security	RLS policy blocked	“Access denied: not a participant in this conversation.”
storage object not found	Attachment deleted or expired signed URL	“This file is no longer available.”
payload too large	File exceeds allowed size	“This file is too large. Please compress or choose another.”
invalid input syntax for uuid	Wrong conversation/user ID	“Something went wrong with chat IDs. Please try again.”
Invalid file type	Non-supported extension	“Unsupported file type. Please upload an image or document.”


⸻

7. Extra Notes
	•	Signed URLs: Attachments are private; signed URLs expire (default 3600s). UI must refresh them.
	•	Realtime: Supabase Realtime subscription is recommended to auto-update chat messages.
	•	Compression: Images compressed before upload → reduces bandwidth.
	•	Testing Checklist:
	•	Create conversation (client + freelancer).
	•	Send text message.
	•	Send attachment.
	•	Confirm signed URL loads.
	•	Attempt sending as non-member → should fail.
	•	Expired URL → confirm refresh logic works.

⸻

?