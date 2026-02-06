# Admin Dashboard - Type Definitions (Models)

This file bridges the gap between the Supabase Database Schema and our TypeScript codebase.
**Copy these into `features/[feature]/models/types.ts` when building.**

## 1. Core User Types (`features/users/models/types.ts`)

```typescript
export type UserRole = 'client' | 'freelancer' | 'admin' | 'super_admin';

export interface UserProfile {
  id: string; // UUID from auth.users
  email: string; // from auth.users (joined)
  fullName: string; // db: full_name
  avatarUrl: string | null; // db: avatar_url
  roles: UserRole[];
  activeRole: UserRole; // db: active_role
  createdAt: string; // ISO Date
  isBanned?: boolean; // Derived from metadata or separate flag
}

export type AdminActionType = 'BAN_USER' | 'UNBAN_USER' | 'VERIFY_IDENTITY' | 'RESET_PASSWORD';
```

## 2. Task Models (`features/tasks/models/types.ts`)

```typescript
export type TaskStatus = 'open' | 'assigned' | 'in_progress' | 'closed' | 'canceled';
export type TaskType = 'tender' | 'booking';

export interface AdminTask {
  id: string;
  title: string;
  description: string;
  status: TaskStatus;
  type: TaskType;
  budget: number;
  
  // Relations
  clientId: string;
  clientName?: string; // Joined
  freelancerId?: string;
  freelancerName?: string; // Joined
  
  createdAt: string;
}
```

## 3. Dispute Models (`features/disputes/models/types.ts`)

```typescript
export type DisputeStatus = 'open' | 'resolved' | 'escalated';
export type DisputeVerdict = 'refund_client' | 'release_freelancer' | 'split' | null;

export interface DisputeTicket {
  id: string;
  taskId: string;
  reporterId: string;
  reason: string;
  status: DisputeStatus;
  verdict: DisputeVerdict;
  
  // Evidence
  chatConversationId?: string;
  
  createdAt: string;
  resolvedAt?: string;
}
```

## 4. Audit Log (`features/logs/models/types.ts`)

```typescript
export interface AuditLogEntry {
  id: string;
  adminId: string;
  adminEmail: string; // Joined
  actionType: string;
  targetResourceId: string;
  details: Record<string, any>; // JSONB
  createdAt: string;
}
```

## 5. Generic API Responses

```typescript
export interface PaginatedResponse<T> {
  data: T[];
  count: number;
  page: number;
  totalPages: number;
}

export interface ActionResult<T> {
  success: boolean;
  data?: T;
  error?: string;
}
```
