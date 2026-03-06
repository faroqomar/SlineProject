# Improved Diagram: 16_escrow-invariants-idempotency

## Skills applied:

- Diagram Crafting (Mermaid)
- Idempotency & Concurrency
- Invariants & Contracts

---

## Redesigned Escrow Release Flow

The improved flow introduces **Stable Idempotency Keys** (independent of time) and **Row-Level Locking** to prevent race conditions during concurrent retries.

```mermaid
flowchart TD
    App["work_management_service.dart\nrpc('rpc_approve_delivery', {entity_type, entity_id})"] --> RPC1[rpc_approve_delivery]

    %% Step 1: Concurrency Control
    RPC1 --> Lock["SELECT id, status, payment_status \nFROM bookings/tasks \nWHERE id = entity_id \nFOR UPDATE"]

    %% Step 2: Invariant Guard
    Lock --> Guard{"status = 'delivered' AND\npayment_status = 'held'?"}

    %% Step 3: Stable Key Generation
    Guard -- "Yes" --> KeyGen["v_idempotency_key = extensions.digest(\n  entity_id || ':release:' || status,\n  'sha256'\n)"]

    %% Step 4: Atomic Ledger Entry
    KeyGen --> Ledger["process_payment_event_ledger(\n  p_idempotency_key = v_idempotency_key\n)"]

    Ledger --> Journal["INSERT INTO journal_entries\n(idempotency_key, status)\nVALUES (v_idempotency_key, 'posted')\nON CONFLICT (idempotency_key)\nDO UPDATE SET status = 'posted'\nRETURNING id"]

    Journal --> LedgerLines["INSERT INTO ledger_lines\n(journal_id, account, direction, amount)\nVALUES (...ledger triple-entry...)"]

    %% Step 5: Final State Transition
    LedgerLines --> UpdateEntity["UPDATE entity SET\nstatus = 'completed',\npayment_status = 'released',\nreview_expires_at = NULL"]

    %% Terminal States
    UpdateEntity --> Success["Return JSON {success: true,\njournal_id: v_journal_id}"]
    Guard -- "No (Already Released)" --> EarlyOut["Return JSON {success: true,\nmessage: 'already_processed'}"]

    %% Error Handling
    Journal -- "Already Posted" --> Replay["Return Existing journal_id\n✅ Safe Idempotent Replay"]
```

### Key Improvements:

1. **Stable Hash**: Removed `now()` from the digest. The key is now derived from the entity ID and the starting status. This allows retries to yield the same key.
2. **Pessimistic Locking**: `FOR UPDATE` prevents multiple simultaneous requests from processing the same entity.
3. **Internal Guard**: Explicitly checks `status` and `payment_status` before touching the ledger.
4. **On Conflict handling**: Uses DB-native atomic conflict resolution for the journal entry.
