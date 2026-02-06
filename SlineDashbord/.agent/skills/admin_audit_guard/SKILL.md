---
description: Specialized guard to ensure ALL descriptive actions are Audit Logged
---

# Admin Audit Guard

**Goal**: Prevent any "Silent Mutations" (changes to DB without a trace).

## The Rule
**"If you change the state of the world, you must sign your name."**

## Inspection Logic

Scan `*.service.ts` files for:
1.  **Mutations**: Methods calling `.insert()`, `.update()`, `.delete()`, `.upsert()`, or `.rpc()`.
2.  **Audit Check**: Inside the SAME function scope (or transaction), is there a call to table `audit_logs`?

### Pass Condition
```typescript
// ✅ PASS
await prisma.users.update(...);
await prisma.audit_logs.create(...); // Found!
```

### Fail Condition
```typescript
// ❌ FAIL
export async function banUser(id) {
  await supabase.from('profiles').update({ banned: true })...; 
  // No audit log found nearby!
}
```

## How to Fix
1.  Identify the missing log.
2.  Add the `audit_logs` insert immediately after the mutation.
3.  Ensure `reason`, `admin_id`, and `meta` are populated.
