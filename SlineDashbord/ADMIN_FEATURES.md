# SLine Admin Dashboard - Feature Requirements

This document outlines the operational capabilities required for the "Control Room".

## 1. Authorization & Role Guard
- [ ] **Login Page**: Standard Supabase Email/Password login.
- [ ] **Middleware Protection**:
    - Redirect unauthenticated users.
    - Check for `admin` role claim.
- [ ] **Session Management**: maintain secure http-only cookie sessions.

## 2. Main Dashboard (Overview)
**"The Pulse of SLine"**
- **Metrics Cards**:
    - Total Users (Clients vs Freelancers).
    - Active Tasks (Requests this week).
    - Revenue/Escrow Volume (Total held funds).
    - Open Disputes/Tickets.
- **Recent Activity Feed**:
    - Live feed of new user signups, posted tasks, or crucial system events.

## 3. User Management (`/users`)
**"The Phonebook"**
- **Data Table**:
    - Searchable by Name, Email, UUID.
    - Filter by Role (Client/Freelancer) or Status (Active/Banned).
    - Columns: Avatar, Name, Email, Role, Joined Date, Status.
- **User Detail View (`/users/[id]`)**:
    - **Header**: Big profile card + Quick Actions (Ban, Reset Password, Send Notification).
    - **Tabs**:
        - **Info**: Raw profile data.
        - **Activity**: History of tasks posted or bids made.
        - **Wallet**: Current balance and transaction history.
        - **Logs**: Previous admin actions taken on this user.

## 4. Task/Work Management (`/tasks`)
**"The Marketplace Overwatch"**
- **Data Table**:
    - Filter by Status (Open, In Progress, Dispute).
    - Filter by Type (Tender vs Booking).
- **Moderation**:
    - Ability to flag task descriptions (e.g., offensive content).
    - **Force Cancel**: Admin ability to cancel a task that is stuck, triggering automatic refund logic via Edge Functions.

## 5. Dispute Resolution Center (`/disputes`)
**"The Courtroom"**
*This is the most complex module.*
- **Ticket System**:
    - When a user reports a problem, a Ticket is created.
- **Investigation Interface**:
    - **Evidence View**: Ability to see the chat history linked to the specific Task/Booking (ReadOnly).
    - **Attachments**: View files shared in the chat.
- **Verdict Actions**:
    - **Release Funds**: Force release escrow to Freelancer.
    - **Refund Client**: Force return funds to Client.
    - **Split**: (Advanced) Partial refund.

## 6. Audit Logs (`/audit`)
**"The Black Box"**
- A read-only immutable list of all actions taken within this dashboard.
- **Columns**: Admin Name, Action (e.g., "Banned User X"), Resource ID, Timestamp.
- *Why?* To accountability. If an admin abuses power, we know who and when.

## 7. Configuration & Tools
- **Global Settings**:
    - Toggle new registrations (Maintenance Mode).
    - Update banner announcements.
- **Notification Center**:
    - Send Push Notification to All Users (System Broadcast).
    - Send email to specific user.

---

## Development Phases
1.  **Foundation**: Setup Next.js, Auth, and "Read-Only" views for Users/Tasks.
2.  **Actions**: Implement Banning and Basic Moderation.
3.  **Logs**: Implement the Audit Log system to track the actions above.
4.  **Disputes**: The complex logic for financial intervention.
5.  **Analytics**: Charts and graphs.
