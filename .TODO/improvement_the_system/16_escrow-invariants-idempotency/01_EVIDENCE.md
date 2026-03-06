# Audit Evidence: 16_escrow-invariants-idempotency.md

## Skills applied:

- Evidence-First Reading
- Invariants & Contracts
- Idempotency & Concurrency

## 1. App-Side Triggers

- **File**: [work_management_service.dart](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/work/services/work_management_service.dart)
- **Code**:

```dart
Future<void> approveDelivery({
  required String entityId,
  required String entityType,
}) async {
  await _supabase.rpc(
    'rpc_approve_delivery',
    params: {'entity_type': entityType, 'entity_id': entityId},
  );
}
```

- **Finding**: The app-side service does NOT generate an idempotency key. It relies entirely on the server-side RPC to generate it.

## 2. Database RPC: `rpc_approve_delivery`

- **Source**: [SUPABASE_SETUP.md](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/SUPABASE_SETUP.md#L1841)
- **Logic Snippet**:

```sql
-- Inside rpc_approve_delivery
v_idempotency_key := encode(
  extensions.digest(
    entity_id::text || ':release_with_fee:' || now()::text,
    'sha256'
  ),
  'hex'
);
PERFORM process_payment_event_ledger(
  'release_with_fee',
  'booking',
  entity_id,
  v_idempotency_key,
  ...
);
```

- **Finding**: confirmed that internal idempotency key is generated using a combination of `entity_id`, a constant string, and `now()`.

## 3. Ledger Orchestration: `process_payment_event_ledger`

- **Source**: [SUPABASE_SETUP.md](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/SUPABASE_SETUP.md#L1430)
- **Finding**: This is the core function for double-entry ledger lines. It is called by `rpc_approve_delivery`.

## 4. Constraint: `journal_entries` Idempotency

- **Source**: [SUPABASE_SETUP.md](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/SUPABASE_SETUP.md#L583)
- **Table Definition**:

```sql
CREATE TABLE journal_entries (
  id uuid PRIMARY KEY,
  ...
  idempotency_key text UNIQUE,
  ...
);
```

- **Finding**: Unique constraint confirmed on `idempotency_key`, providing the physical layer of protection.
