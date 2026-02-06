# Admin Dashboard - Supabase Control & Data Flow

This document explains **exactly how** we control the database and the flow of data.

## 1. The "Two-Brain" Concept

We interact with Supabase in two completely different ways within the same app.

| Client Type | Key Used | Where? | Purpose | Safety |
|---|---|---|---|---|
| **Auth Client** | `ANON_KEY` | Client Components & Middleware | Logging in, Checking Session, Reading Public Data | Safe for Browser |
| **Service Client** | `SERVICE_ROLE_KEY` | **Server Actions ONLY** | Banning users, Refunding money, Viewing private data | **DANGER** - Server Only |

---

## 2. Step-by-Step Control Flow: "Banning a User"

Here is the lifecycle of an Admin Action to understand the control.

### Step 1: The Trigger (Client Side)
The Admin clicks the red "Ban User" button in `UserDetailScreen.tsx`.
*   **Code**: Calls the ViewModel `banUser(userId)`.
*   **Role**: UI only. No database logic here.

### Step 2: The Logic (Server Action)
The request travels to `features/users/services/user_actions.ts`.
This function is marked with `'use server'`.

**The Sequence:**
1.  **Verify Admin**: It checks `await supabase.auth.getUser()`. If the user isn't an admin -> Throw Error "Unauthorized".
2.  **Initialize God Mode**: It calls `createServiceRoleClient()`.
3.  **Execute Logic**:
    ```typescript
    // 1. Update the User Status
    await supabaseAdmin.from('profiles').update({ is_banned: true }).eq('id', userId);
    
    // 2. Log the Action (CRITICAL)
    await supabaseAdmin.from('audit_logs').insert({
      admin_id: adminUser.id,
      action: 'BAN_USER',
      target_id: userId
    });
    ```
4.  **Revalidate**: Tells Next.js to refresh the UI (`revalidatePath('/users')`).

### Step 3: The Result
The function returns `{ success: true }`. The UI shows a green toast "User Banned".

---

## 3. How to Generate Types (Type Safety)

To ensure we control the data correctly, we need TypeScript types that match the DB exactly.

**Command to Run:**
```bash
npx supabase gen types typescript --project-id "isddrknbjsgaantjojhm" --schema public > types/supabase.ts
```

**Usage:**
```typescript
import { Database } from '@/types/supabase';
// Now TS knows that 'profiles' has a 'full_name' column!
```

---

## 4. Safety Rules (The Control Protocol)

1.  **Never Import Service Key in Components**:
    *   Next.js will throw an error if `SUPABASE_SERVICE_ROLE_KEY` is used in a file starting with `'use client'`. This is a built-in safety mechanism.

2.  **Always Verify "Who is Asking?"**:
    *   Just because you *can* use the Service Key doesn't mean you *should*.
    *   Every Server Action MUST start with: `const { data: { user } } = await createAuthClient().auth.getUser()`.

3.  **Audit Everything**:
    *   With great power comes great responsibility. Since standard RLS doesn't stop the Service Key, the `audit_logs` table is your only safety net to track mistakes.
