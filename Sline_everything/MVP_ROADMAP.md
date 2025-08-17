

# 📌 Sline MVP Roadmap

Each feature below is broken down step-by-step for clarity.  
This file serves as the central reference for MVP development progress.  

---

## 🔹 1. Project Initialization

Step | Feature | Description | Status
--- | --- | --- | ---
1.1 | Create clean Flutter project | Modular folder structure with **core**, **features**, **shared** | ✅ Completed
1.2 | Setup Supabase | Create Supabase project, enable **auth**, **roles**, **storage** | ✅ Completed
1.3 | Connect Supabase to Flutter | Using `supabase_flutter`, add keys via env config | ✅ Completed

---

## 🔹 2. App Navigation

Step | Feature | Description | Status
--- | --- | --- | ---
2.1 | Add Bottom Navigation Bar | 4 tabs: Home, Messages, Tasks, Profile | ✅ Completed
2.2 | Add placeholder screens | Each tab shows a page with its name | ✅ Completed
2.3 | Setup Navigation Provider | Centralized navigation state with Provider (`IndexedStack`) | ✅ Completed

---

## 🔹 3. Authentication

Step | Feature | Description | Status
--- | --- | --- | ---
3.1 | Sign up / Sign in | Email/password login via Supabase Auth | ✅ Completed
3.2 | Social login (optional) | Apple/Google sign-in (optional for MVP) | ⏳ Planned
3.3 | Auth state management | Redirect login ↔ home based on session | ✅ Completed
3.4 | Role selection | Assign Client/Freelancer role on sign up | ✅ Completed

---

## 🔹 4. Tasks Module

Step | Feature | Description | Status
--- | --- | --- | ---
4.1 | Create `tasks` table in Supabase | Columns: id, title, description, budget, category, skills, status, createdAt | ✅ Completed
4.2 | TaskModel | Flutter model for tasks with JSON serialization | ✅ Completed
4.3 | TaskService | Supabase CRUD (createTask, getTasks) | ✅ Completed
4.4 | Create Task Screen | Form to create new task with validation | ✅ Completed
4.5 | HomeController integration | Fetch tasks from Supabase and manage state | ✅ Completed
4.6 | HomeScreen UI | Show tasks list with `TaskCard` | ✅ Completed
4.7 | Task Details Screen | Full view of a task with PriceFormatter & DateFormatter | ✅ Completed
4.8 | TaskCard widget | Beautiful summary card for each task | ✅ Completed
4.9 | Search & Filter | Filter by category/skills, search tasks by keyword | ✅ Completed
4.10 | Edit/Delete Task | Allow owners to update/remove tasks | ✅ Completed
4.11 | Display Publisher Info | Show user name and avatar in task cards | ✅ Completed

---

## 🔹 5. Messaging System

Step | Feature | Description | Status
--- | --- | --- | ---
5.1 | Message model | Store senderId, receiverId, content, timestamp in Supabase | ✅ Completed
5.2 | Real-time messaging | Realtime integration planned, initial groundwork completed with conversation fetching and logger | ⏳ In Progress
5.3 | Chat UI | Task-specific chat thread in "Messages" tab | ✅ Completed
5.4 | Link chat to requests | Each conversation tied to a task | ✅ Completed

---

## 🔹 6. Task Requests Management

Step | Feature | Description | Status
--- | --- | --- | ---
6.1 | Requests Screen | Placeholder for offers/requests per task | ⏳ Planned
6.2 | Accept/Reject requests | Clients can accept or reject freelancer bids | ⏳ Planned
6.3 | Connect with Messaging | Requests auto-create chat thread | ⏳ Planned

---

## 🔹 7. Profile & Settings

Step | Feature | Description | Status
--- | --- | --- | ---
7.1 | Profile screen | Show avatar, full name, email, phone | ✅ Completed
7.2 | Edit profile | Update avatar, name, phone | ✅ Completed
7.3 | Switch role | Toggle between Client ↔ Freelancer | ⏳ Planned
7.4 | My Tasks | List tasks created by current user | ✅ Completed
7.5 | Account management | Logout, delete account, reset password | ⏳ Planned

---

## 🔹 8. Infrastructure

Step | Feature | Description | Status
--- | --- | --- | ---
8.1 | Logger service | Centralized debug/error logs with PrettyPrinter (debug-only) | ✅ Completed
8.2 | Constants & Config | Shared constants and env setup | ✅ Completed
8.3 | Theme system | Material 3 Light/Dark theme | ⏳ Planned
8.4 | Localization | Arabic (RTL) + English (LTR) | ⏳ Planned
8.5 | Documentation | STRUCTURE.md, SUPABASE_SETUP.md, Sline_Log.md synced | ✅ Completed

---

# 🎯 Summary

- ✅ Completed: Initialization, Navigation, Authentication, Tasks (up to Details).
- 🔜 Next focus: Messaging System (5.x), and Requests (6.x).
- 📦 This roadmap ensures Sline MVP is production-ready once Messaging and Requests are complete.
# 📌 Sline MVP Roadmap (Updated)

**Last Updated:** 2025-08-17

Each feature below is broken down step-by-step for clarity.

---

## 🔹 1. Project Initialization — ✅ Completed
## 🔹 2. App Navigation — ✅ Completed
## 🔹 3. Authentication — ✅ Completed
## 🔹 4. Tasks Module — ✅ Completed

---

## 🔹 5. Messaging System

Step | Feature | Description | Status
--- | --- | --- | ---
5.1 | Message model | senderId, receiverId, content, timestamp | ✅ Completed
5.2 | Real-time messaging | Realtime on conversations/messages with subscriptions | ✅ Completed
5.3 | Chat UI | Task-specific chat thread + WhatsApp-like list | ✅ Completed
5.4 | Conversation linking | Conversation tied to a task and participant pair | ✅ Completed
5.5 | **Attachments** | Image/File upload to **private** bucket + signed URLs | ✅ Completed (v1.4)
5.6 | Read receipts | Message read status + UI tick marks | ⏳ Planned
5.7 | Typing indicators | Per-conversation typing state | ⏳ Planned

---

## 🔹 6. Task Requests Management

Step | Feature | Description | Status
--- | --- | --- | ---
6.1 | Requests Screen | Offers/requests per task | ⏳ Planned
6.2 | Accept/Reject | Client accepts/rejects freelancer bids | ⏳ Planned
6.3 | Link with Messaging | Requests auto-create chat thread | ⏳ Planned

---

## 🔹 7. Profile & Settings

Step | Feature | Description | Status
--- | --- | --- | ---
7.1 | Profile screen | Avatar, name, email, phone | ✅ Completed
7.2 | Edit profile | Update avatar, name, phone | ✅ Completed
7.3 | Switch role | Toggle Client ↔ Freelancer | ⏳ Planned
7.4 | My Tasks | List and manage user’s posted tasks | ✅ Completed
7.5 | Account management | Logout, delete account, reset password | ⏳ Planned

---

## 🔹 8. Infrastructure

Step | Feature | Description | Status
--- | --- | --- | ---
8.1 | Logger service | Pretty-printed debug logs | ✅ Completed
8.2 | Constants & Config | Shared constants and env | ✅ Completed
8.3 | Theme system | Material 3 Light/Dark | ⏳ Planned
8.4 | Localization | Arabic (RTL) + English (LTR) | ⏳ Planned
8.5 | Documentation | Keep docs synced (this update) | ✅ Completed

---

# 🎯 Summary
- ✅ Messaging now supports **attachments** with private storage + signed URLs.
- 🔜 Next: **Read receipts** (5.6) ثم **Typing indicators** (5.7).
# 📌 Sline MVP Roadmap (Up-to-date)

**Last Updated:** 2025-08-17

This file is the single source of truth for MVP progress. Each step is bite-sized and traceable to code or SQL.

---

## 🔹 1) Project Initialization — ✅ Completed
## 🔹 2) App Navigation — ✅ Completed
## 🔹 3) Authentication — ✅ Completed
## 🔹 4) Tasks Module — ✅ Completed

---

## 🔹 5) Messaging System
Step | Feature | Description | Status
--- | --- | --- | ---
5.1 | Message model | `sender_id`, `receiver_id`, `content`, timestamps | ✅ Completed
5.2 | Realtime messaging | Channels for conversations & messages | ✅ Completed
5.3 | Chat UI | WhatsApp-like thread + conversations list | ✅ Completed
5.4 | Conversation linking | Each pair+task → single conversation | ✅ Completed
5.5 | **Attachments** | Private storage bucket + signed URLs | ✅ Completed (v1.4)
5.6 | **Realtime optimization** | Upsert-in-place (no full refetch per event) | ✅ Completed (v1.5)
5.7 | Read receipts | Persisted read/delivered + UI indicators | ⏳ Planned
5.8 | Typing indicators | Presence table + UI | 🚧 Deferred (out of scope for now)

---

## 🔹 6) Task Requests Management — ⏳ Planned
- Requests screen, accept/reject, auto-create chat

## 🔹 7) Profile & Settings — 🟡 Mixed
- Profile view/edit, avatar upload — ✅
- My Tasks — ✅
- Switch role — ⏳ Planned
- Account management (logout/reset/delete) — ⏳ Planned

## 🔹 8) Infrastructure — 🟡 Mixed
- Logger service (AppLogger) — ✅
- Constants & config — ✅
- Theme (M3 Light/Dark) — ⏳ Planned
- Localization (AR/EN) — ⏳ Planned
- Documentation kept current — ✅

---

# 🎯 Summary
- ✅ Attachments with private storage & signed URLs
- ✅ Realtime optimized (no full list refetch)
- ✅ Immediate image bubble rendering on send
- 🔜 Read receipts & requests flow next