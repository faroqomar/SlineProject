# Evidence Map: Escrow Idempotency Verification

## 1. App-Layer Call Chain

### 1.1. UI Entry Point

- **File**: [work_item_details_screen.dart](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/work/view/work_item_details_screen.dart#L621-L646)
- **Widget**: `ReviewDeliveryModal` triggered from `_showReviewModal()` (L621)
- **Wiring**: `onApprove: vm.approveDelivery` (L632)

### 1.2. Review Delivery Modal

- **File**: [review_delivery_modal.dart](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/work/view/widgets/review_delivery_modal.dart)
- **Approve handler**: `_handleApprove()` → `widget.onApprove()` (L39)
- **Guard**: Sets `_isLoading = true` before call (L37), catches errors and resets loading (L41-43)
- **⚠ GAP**: No **debounce** or button-disable after first tap — relies on `_isLoading` state to prevent double-tap, but there's a **race window** between tap and `setState` render.

### 1.3. ViewModel

- **File**: [work_item_details_view_model.dart](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/work/viewmodels/work_item_details_view_model.dart#L149-L168)
- **Method**: `approveDelivery()` (L149)
- **Key behavior**: Sets `_isLoading = true` then calls service. On success, calls `loadData()` to refresh state.
- **Error handling**: Catches all exceptions, sets `_error = 'Failed to approve delivery'`
- **⚠ GAP**: Does NOT differentiate between "failed" vs "already_processed" responses. A successful idempotent replay would also re-fetch data, which is correct, but error messages are generic.

### 1.4. Service Layer

- **File**: [work_management_service.dart](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/work/services/work_management_service.dart#L263-L281)
- **Method**: `approveDelivery()` (L263)
- **RPC call**: `rpc('rpc_approve_delivery', params: {'entity_type': entityType, 'entity_id': entityId})` (L268-271)
- **Key fact**: App does NOT generate or send an idempotency key. The key is generated entirely **server-side**.

---

## 2. Database RPCs (Live SQL — Verified 2026-03-06)

### 2.1. `rpc_approve_delivery` (Outer RPC)

- **Source**: Live `pg_get_functiondef` query
- **Language**: PL/pgSQL, `SECURITY DEFINER`
- **Key code** (booking branch):

```sql
v_idempotency_key := encode(
  extensions.digest(
    entity_id::text || ':release_with_fee:' || now()::text,
    'sha256'
  ), 'hex'
);
```

- **🔴 CRITICAL**: Uses `now()` — key changes on EVERY call.
- **Task branch**: Does NOT generate an idempotency key. No ledger call. Just `UPDATE tasks SET status = 'completed'`.
- **Auth check**: `v_client_id != v_uid` → `RAISE EXCEPTION 'Not authorized'`
- **Status check**: `v_status != 'delivered'` → `RAISE EXCEPTION 'Work not delivered'`
- **⚠ GAP (task branch)**: No `payment_status` check. No `FOR UPDATE` lock. No ledger entry.

### 2.2. `process_payment_event_ledger` (Inner Ledger Function)

- **Source**: Live `pg_get_functiondef` query
- **Section 5.2 (`release_with_fee`)** — extracted key evidence:

**Idempotency check (top of function)**:

```sql
SELECT id INTO v_existing_journal_id
FROM public.journal_entries
WHERE idempotency_key = p_idempotency_key
AND status = 'posted';

IF v_existing_journal_id IS NOT NULL THEN
  RETURN jsonb_build_object('ok', true, 'journal_entry_id', v_existing_journal_id, ...);
END IF;
```

✅ **Replay protection**: Returns existing journal ID if key already exists.

**Row lock**:

```sql
SELECT id, client_id, provider_id, status, payment_status, price AS amount_gross
INTO v_entity FROM public.bookings
WHERE id = p_related_entity_id FOR UPDATE;
```

✅ **Concurrency control**: `FOR UPDATE` on entity row.

**Status gate**:

```sql
IF v_booking_status != 'delivered' OR v_payment_status != 'held' THEN
  RETURN ... 'ERR_GATE_NOT_ALLOWED' ...
END IF;
```

✅ **Invariant enforced** inside ledger function.

**EXCEPTION handler**:

```sql
EXCEPTION WHEN unique_violation THEN
  IF SQLERRM LIKE '%journal_entries_idempotency_key%' THEN
    SELECT id INTO v_existing_journal_id FROM journal_entries WHERE idempotency_key = p_idempotency_key;
    IF v_existing_journal_id IS NOT NULL THEN
      RETURN jsonb_build_object('ok', true, 'journal_entry_id', v_existing_journal_id, ...);
    END IF;
  END IF;
```

✅ **Race handler**: Two-layer protection — check first, then catch unique_violation.

---

## 3. Database Constraints (Live — Verified 2026-03-06)

### 3.1. `journal_entries` constraints

| Constraint                            | Definition                                                               |
| ------------------------------------- | ------------------------------------------------------------------------ |
| `journal_entries_idempotency_key_key` | `UNIQUE (idempotency_key)`                                               |
| `ck_journal_entries_status_allowed`   | `CHECK (status IN ('posted', 'voided'))`                                 |
| `ck_journal_entries_currency_iqd`     | `CHECK (currency = 'IQD')`                                               |
| `ck_journal_entries_entity_null_pair` | `CHECK ((entity_type IS NULL AND entity_id IS NULL) OR (both NOT NULL))` |

### 3.2. `journal_entries` indexes

| Index                                 | Definition                                                         |
| ------------------------------------- | ------------------------------------------------------------------ |
| `journal_entries_idempotency_key_key` | `UNIQUE btree (idempotency_key)`                                   |
| `idx_journal_entries_idempotency`     | `UNIQUE btree (idempotency_key)` — **duplicate index**             |
| `uq_journal_entries_single_reversal`  | `UNIQUE btree ((meta->>'reversal_of_journal_entry_id')) WHERE ...` |

⚠ **MINOR**: Two duplicate unique indexes on `idempotency_key`. One should be dropped.

### 3.3. `ledger_lines` constraints

| Constraint                           | Definition                                    |
| ------------------------------------ | --------------------------------------------- |
| `ck_ledger_lines_amount_positive`    | `CHECK (amount > 0)`                          |
| `ck_ledger_lines_currency_iqd`       | `CHECK (currency = 'IQD')`                    |
| `ledger_lines_journal_entry_id_fkey` | `FK → journal_entries(id) ON DELETE RESTRICT` |
| `ledger_lines_account_id_fkey`       | `FK → accounts(id) ON DELETE RESTRICT`        |

---

## 4. Admin Dashboard

- **Result**: No admin dashboard exists in the Flutter codebase (`find_by_name` for `*admin*` directories returned 0 results).
- **Supabase Dashboard**: Journal entries and ledger lines can be inspected via Supabase Table Editor, but there is no dedicated admin UI for escrow monitoring.
