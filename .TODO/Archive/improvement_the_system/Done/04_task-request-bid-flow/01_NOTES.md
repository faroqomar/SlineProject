# Skill Selection & Notes

### Skills Selected

1. **Evidence-First Reading**
2. **State Machine & Lifecycle**
3. **Invariants & Contracts**
4. **Diagram Crafting (Mermaid)**
5. **RLS & Privilege Boundaries**

### Why these skills fit this diagram/file

This diagram focuses on the state transitions of a `task_request` (a bid). True understanding requires following the lifecycle states (pending -> accepted/rejected), extracting the invariant contracts surrounding the `tasks` state changing simultaneously (Invariants & Contracts), and securing the RPC invocations (RLS & Privilege Boundaries). Mermaid crafting is essential to fix the oversimplified `TR --> TR` approach in the current diagram.

### Skills intentionally not used

- **DB-First Financial Modeling**: While bids have prices, the actual financial transaction belongs to the ledger / booking payment lifecycle, not the bid itself.
- **Test Design**: Focus is on fixing the architectural model; testing strategy will be a subsection in the holistic report but not the primary driver of this audit.

### Observation Notes & Evidence

- **Oversimplification**: The current diagram is extremely simplistic (`TR --> TR` is not standard state machine behavior; it should be `pending --> accepted`, etc.).
- **Task Synergy**: Accepting a bid (`accept_task_request`) modifies the parent _Task_ state from `open` to `assigned`.
  - _Evidence_: `SUPABASE_SETUP.md:1412` - "Moves the task to assigned and sets both freelancer columns."
- **Replacement Logic**: The freelancer action `replace_task_request` where a pending bid is archived/deleted and a new one is created.
  - _Evidence_: `SUPABASE_SETUP.md:1889` - "Withdraws caller's pending offer and inserts a replacement."
- **24h Expiration**: Pending bids are not infinite.
  - _Evidence_: `SUPABASE_SETUP.md:1463` - "`process_expired_requests()` Finds >24h pending requests, expires them."
- **Conversation Guard Bypass**: A critical "hack" for rejections.
  - _Evidence_: `SUPABASE_SETUP.md:1885` - "The guard now allows the task owner to create a task-linked conversation when `app.allow_owner_task_conversation = 'true'` (set only by `reject_task_request`)."
- **QiCard Payment Transition**: For tenders, acceptance move from 'unpaid' to 'held'.
  - _Evidence_: `SUPABASE_SETUP.md:1913` - "Tender QiCard payment... after setting `task_requests.payment_status = 'held'` the function also updates the linked task (`freelancer_id`, `assigned_freelancer_id`, `status = 'in_progress'`)."
