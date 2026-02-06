# SLine Admin Dashboard - Architecture & Tech Stack

> **Project Name**: `sline_admin`
> **Type**: Private Internal Tool (Next.js Web App)
> **Connection**: Connects directly to **existing SLine Supabase Project** (`isddrknbjsgaantjojhm`)
> **Pattern**: **Strict MVVM** (Model-View-ViewModel)

## 1. Connection Strategy (How it links?)

We do **NOT** create a new Supabase project. We connect to the **live SLine database**.

### The "Two-Key" System
*   **Mobile App** uses the `Anon Key` (Public, Limited by RLS).
*   **Admin Dashboard** uses the `Service Role Key` (Private, Bypasses RLS).

**How it works:**
1.  You copy the `Service Role Key` from your existing Supabase Dashboard > Settings > API.
2.  You put it in the `.env.local` of this new Next.js project.
3.  The dashboard uses this key to "Administer" the database (Ban users, refund money, see private chats) without being stopped by the RLS rules that apply to normal users.

---

## 2. Strict MVVM Architecture (Next.js Edition)

To match your Flutter mental model, we will use a **Feature-First MVVM** structure.

### The Layers
1.  **Model (`models/`)**: TypeScript Interfaces & Zod Schemas.
    *   *Role*: Defines "What the data looks like".
2.  **View (`view/`)**: React Components (TSX).
    *   *Role*: "How it looks". **Zero logic**. Just takes props from ViewModel.
    *   *Rule*: Never fetch data directly here.
3.  **ViewModel (`viewmodels/`)**: Custom React Hooks (`use...`).
    *   *Role*: "State & Logic". Handles `isLoading`, `error`, calling services, and preparing data for the View.
4.  **Service (`services/`)**: Server Actions (`'use server'`).
    *   *Role*: "The Bridge". Talks to Supabase using the Service Role Key. Securely executes database commands.

### Folder Structure

```text
sline_admin/
├── app/                    # Routing Layer (The "Navigation")
│   ├── (auth)/login/page.tsx
│   └── (dashboard)/
│       ├── users/page.tsx  # Instantiates <UsersScreen />
│       └── disputes/page.tsx
├── core/                   # Shared Infrastructure
│   ├── config/             # Environment variables
│   ├── theme/              # Colors, Fonts (Shadcn)
│   ├── ui/                 # Dumb Components (Button, Card) - Shadcn
│   └── lib/                # Supabase Clients (Server & Client)
├── features/               # MVVM Modules
│   ├── users/
│   │   ├── models/         # types.ts (User, Profile)
│   │   ├── services/       # user.actions.ts (Server Actions)
│   │   ├── viewmodels/     # useUserList.ts, useUserDetails.ts
│   │   └── view/           # components/ (UserTable.tsx, UserFilters.tsx)
│   ├── disputes/
│   │   ├── models/
│   │   ├── services/
│   │   ├── viewmodels/
│   │   └── view/
│   └── dashboard/          # (Overview Stats)
└── middleware.ts           # Auth Guard
```

---

## 3. Technology Stack

- **Framework**: **Next.js 15 (App Router)**
- **Language**: **TypeScript**
- **Styling**: **Tailwind CSS**
- **UI Architecture**: **MVVM** (Custom Hooks as ViewModels)
- **Data Layer**: **Server Actions** (as Services)
- **Validation**: **Zod** (for Models)

---

## 4. MVVM Implementation Example

**1. Service (`features/users/services/user_service.ts`)**
```typescript
'use server'
// Only this file touches the DB
export async function fetchUsers() {
  const supabase = createServiceRoleClient();
  return await supabase.from('profiles').select('*');
}
```

**2. ViewModel (`features/users/viewmodels/use_users_viewmodel.ts`)**
```typescript
'use client'
// Manages State
export function useUsersViewModel() {
  const [users, setUsers] = useState<User[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    fetchUsers().then(data => {
      setUsers(data);
      setIsLoading(false);
    });
  }, []);

  return { users, isLoading };
}
```

**3. View (`features/users/view/users_screen.tsx`)**
```tsx
'use client'
// Pure UI
export function UsersScreen() {
  const vm = useUsersViewModel(); // Bind VM

  if (vm.isLoading) return <Spinner />;
  
  return (
    <div className="p-4">
      {vm.users.map(user => <UserCard key={user.id} user={user} />)}
    </div>
  );
}
```
