---
description: Security rules for Admin Dashboard Service Role usage
globs: ["sline_admin/**/services/*.service.ts", "sline_admin/**/actions/*.ts"]
alwaysApply: true
---

# Admin Security Rules (Service Role)

## CRITICAL: Service Role Key Usage

The `SUPABASE_SERVICE_ROLE_KEY` bypasses all Row Level Security (RLS). Misuse can destroy the database.

### 1. Server-Side Execution Only
- **NEVER** import `createServiceRoleClient` in a file that does not have `'use server'`.
- **NEVER** throw raw errors. Return `ActionResult` with `{ success: false, error: ... }`.
- **ALL** Admin Reads/Writes must go through Server Actions.

### 2. Input Validation & Authorization
- **Zod Validation**: Every action MUST validate input schema first.
- **DB Permission Check**: Verify role via DB helper, NOT metadata.

```typescript
// ✅ REQUIRED PATTERN
export async function deleteData(id: string): Promise<ActionResult> {
  // 1. Validate Input
  const parsed = idSchema.safeParse(id);
  if (!parsed.success) return { success: false, error: { code: 'INVALID_INPUT', message: 'Invalid ID' } };

  // 2. Verify Caller
  const { isAuthorized, user } = await verifyAdminRole();
  if (!isAuthorized) return { success: false, error: { code: 'UNAUTHORIZED', message: 'Insufficient Permissions' } };

  // 3. Execute ...
}
```

### 3. Detailed Audit Logging
Any **State Change** must log to `audit_logs` atomically.

**Required Meta Fields:**
- `request_id` (UUID)
- `ip_address`
- `user_agent`
- `reason` (Mandatory for destructive actions)
- `before/after` status (if applicable)

```typescript
await tx.from('audit_logs').insert({
  action: 'BAN_USER',
  admin_id: user.id,
  target_id: id,
  reason: reason,
  meta: {
    ip: headers().get('x-forwarded-for'),
    request_id: crypto.randomUUID(),
    user_agent: headers().get('user-agent')
  }
});
```

### 4. Concurrency & Integrity
- **Stale Write Protection**: Use `version` or `updated_at` checks for sensitive updates.
- **Idempotency**: Ensure retrying a 'Refund' action doesn't process twice.
