# Audit Notes: Dispute Lifecycle

**Skills Selected:**

1. **State Machine & Lifecycle**: To define valid transitions between 'open', 'active', and 'resolved'.
2. **Evidence-First Reading**: All findings are backed by `SUPABASE_SETUP.md` and `dispute_service.dart`.
3. **Threat Modeling (Security)**: Assessing risks in fund resolution and evidence privacy.
4. **Diagram Crafting (Mermaid)**: To produce a production-grade visualization.
5. **DB-First Financial Modeling**: Mapping dispute resolution to the Ledger `process_payment_event_ledger` RPC.
6. **RLS & Privilege Boundaries**: Ensuring only authorized parties (Admins/Complainants) can act.

**Why these skills fit:**
The system is a financial-legal hybrid (escrow resolution). State transitions must be strict, financial impacts must be atomic (Ledger), and security is paramount to prevent fraud.

**Skills intentionally not used:**

- **Repo Mapping**: The structure is already well-understood from the project context.
- **Idempotency & Concurrency**: While important, it's secondary to the core lifecycle logic which is currently the main gap.

---

## Evidence Summary

### 1. Database Schema

- **Table `disputes`**: Contains `status` (text), `task_id`, `complainant_id`, `defendant_id`.
- **Table `dispute_messages`**: thread for communication.
- **Table `dispute_evidence`**: storage for files.
- **Status Values**: 'open' (confirmed by code), 'resolved' (mentioned in diagram), 'active' (mentioned in diagram).
- **Missing**: A formal `dispute_status_enum` or transition guard (trigger).

### 2. Logic & Services

- **`DisputeService.submitDispute()`**: Confirmed to insert `status: 'open'`.
- **`process_payment_event_ledger`**: The destination for resolution funds (refund/release).
- **Admin Actions**: Mentioned as "UNVERIFIED" in the original diagram, but `SUPABASE_SETUP.md` mentions `admin_triage_report` and `admin_close_report` which likely drive this.

### 3. Security & RLS

- **RLS (v2.18)**: "complainant insert and party visibility".
- **Gaps**: No explicit `UPDATE` policy shown for status changes; assumed to be restricted to Admins (or system via RPC).
