# RLS Authorization Proof: Disputes

## `disputes` Table RLS

**Source:** `20260310101000_dashboard_public_config_reports_disputes_bridge.sql` lines 159-198.

### Policies Found

| Policy Name             | Operation | Rule                                                               | Effect                                     |
| ----------------------- | --------- | ------------------------------------------------------------------ | ------------------------------------------ |
| `disputes_insert_own`   | INSERT    | `WITH CHECK (complainant_id = auth.uid())`                         | Users can only file disputes as themselves |
| `disputes_select_party` | SELECT    | `USING (complainant_id = auth.uid() OR defendant_id = auth.uid())` | Only parties can read their own disputes   |

### Policies NOT Found

| Policy              | Operation | Status                                                  |
| ------------------- | --------- | ------------------------------------------------------- |
| `disputes_update_*` | UPDATE    | ❌ MISSING — authenticated users CANNOT update disputes |
| `disputes_delete_*` | DELETE    | ❌ MISSING — authenticated users CANNOT delete disputes |

> **Verdict (Positive):** Since no UPDATE policy exists for `authenticated` role, **participants CANNOT change `disputes.status`** via direct table writes. Only `service_role` or `SECURITY DEFINER` RPCs can mutate status. This is **correct by omission** but should be made explicit with a deny policy.

### Recommended Explicit Deny

```sql
CREATE POLICY disputes_deny_update ON public.disputes FOR UPDATE TO authenticated USING (false);
CREATE POLICY disputes_deny_delete ON public.disputes FOR DELETE TO authenticated USING (false);
```

---

## `dispute_messages` Table RLS — ❌ NOT FOUND

**Evidence:** Searched all migrations for `POLICY.*dispute_messages` → No results.
`SUPABASE_SETUP.md` does not document any RLS policies for `dispute_messages`.

> **Risk:** If RLS is enabled but no policies exist → all reads/writes are blocked (secure by default in Supabase). However, this also means the dispute messaging feature is **non-functional** for regular users.

---

## `dispute_evidence` Table RLS — ❌ NOT FOUND

**Evidence:** Searched all migrations for `POLICY.*dispute_evidence` → No results.

> **Same risk as above:** Secure by default (all blocked), but non-functional.

---

## Admin Access

Admin dispute actions would need to go through `service_role` or `SECURITY DEFINER` RPCs. The migration `20260310101000` mentions admin RPCs (`admin_triage_report`, `admin_close_report`) but these apply to `reports`, not `disputes`.

> **Gap:** No admin-specific RPC exists for changing dispute status.
