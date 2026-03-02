# Documentation Full Review Report — 2026-03-02

**Scope:** Full_Review (entire codebase and Sline_everything/ docs)  
**Plan reference:** Plan Missing: Risk Elevated  
**Constraints:** No code or doc changes; analysis and report only.

---

## 1. Documentation delta list

Which docs in `Sline_everything/` are outdated vs current code:

| Document | Status | Delta summary |
|----------|--------|----------------|
| **SUPABASE_SETUP.md** | **Outdated** | **Last Updated** and **Version** show 2026-02-24 / 2.16. Migrations through **20260307** exist (direct_offers table, RLS, triggers, ledger RPC, `20260307_fix_ledger_event_type_enum.sql`). Doc already describes `direct_offers` (§5.14), `related_entity_type_enum` with `direct_offer`, and ledger; it does **not** list migrations 20260303–20260307 in a changelog or "Last Updated" and does not mention the ledger enum cast fix. |
| **STRUCTURE.md** | **Outdated** | **supabase/functions:** Only lists `booking_decline_refund`, `qicard_payment_create`, `qicard_payment_recovery`, `qicard_webhook_handler`. Codebase has **`qicard_payment_create_direct_offer/`** and **`qicard_payment_recovery_direct_offer/`** — not mentioned. **lib/features:** Feature list omits **`direct_offers`** (exists: `models/`, `services/`, `view/`, `viewmodels/`). "Recent migration themes" do not mention direct-offer or ledger-enum-fix migrations. |
| **DEVELOPER_GUIDE.md** | **Outdated** | **Chat §2.5 / §2.6:** States "DM requires freelancer in client favorites" and "trg_conversations_guard: Only clients can start non-task DMs with favorites." **SUPABASE_SETUP.md** (and Key Business Rules) state "DM conversations NO LONGER require favorites relationship (Changed v2.1)" — contradiction. **Chat §2.2** `message_type_enum`: doc lists `text`, `offer`, … `dispute_report` but **omits `system`** (SUPABASE_SETUP §4.3 and code include it). **Trigger/function names:** Doc uses `trg_conversations_guard` and `trg_messages_validate_payload`; SUPABASE_SETUP and migrations use `trg_conversations_before_insert_guard` / `conversations_before_insert_guard()` and `trg_messages_before_insert_validate` / `messages_before_insert_validate()`. **Direct offers:** Doc says "lib/features/direct_offers/ (model, service)" but code also has **view** (`direct_offer_details_screen.dart`) and **viewmodels** (`direct_offer_details_view_model.dart`) — inventory incomplete. |
| **MVP_ROADMAP.md** | **Minor gap** | No dedicated row for "Direct Chat Offers" or "Direct offers flow"; feature is live in code and documented in DEVELOPER_GUIDE/SUPABASE_SETUP. Could be a sub-row under Chat or Workspace. |
| **Sline_Log.md** | **Largely current** | Entries through 2.16.9 (ChatFix) and 2.16.8/2.16.7; direct_offers and 20260303+ migrations are not yet logged as a versioned release. |
| **ARCHITECTURE_ANALYSIS.md** | **Intentional historical** | Self-describes as historical; points to STRUCTURE/DEVELOPER_GUIDE/SUPABASE_SETUP for current state. Orders decommission note is current. |
| **CODE_REVIEW.md** | **Intentional historical** | Guardrail on navigation consolidation is current; other content is historical. |
| **COMPREHENSIVE_ANALYSIS_SUMMARY.md** | **Intentional historical** | Explicitly archival; points to DEVELOPER_GUIDE, STRUCTURE, SUPABASE_SETUP for current state. |

---

## 2. Reference integrity scan

### Broken or missing paths / names

- **DEVELOPER_GUIDE.md §11 Quick Links:** References **`DEVELOPER_GUIDE/Inventory Feature.md` (Planned)**. That file **does not exist** in `Sline_everything/DEVELOPER_GUIDE/` (only 14 feature files present; no "Inventory Feature.md"). So the path is broken; the "(Planned)" label suggests it is a placeholder, not a current contract.

- **Chat trigger/function names in DEVELOPER_GUIDE:**  
  - Doc: `trg_conversations_guard` → actual (SUPABASE_SETUP + migrations): **`trg_conversations_before_insert_guard`** and **`conversations_before_insert_guard()`**.  
  - Doc: `trg_messages_validate_payload` → actual: **`trg_messages_before_insert_validate`** and **`messages_before_insert_validate()`**.  
  So references are **wrong names** (shortened/legacy); they do not point to non-existent DB objects but could mislead someone implementing from the guide.

### Validated references (correct)

- **.cursor/rules/error-handling.mdc** — exists; referenced by DEVELOPER_GUIDE, CODE_REVIEW, Sline_Log.
- **lib/core/utils/error_mapper.dart** — exists; referenced across docs.
- **direct_offers** table and §5.14 in SUPABASE_SETUP — match migrations (20260303_direct_offer_ledger_rpc, 20260303_direct_offers_table_rls_trigger, 20260304, 20260305, 20260306).
- **process_payment_event_ledger** — documented; migration 20260307 fixes enum cast (TEXT → payment_event_type_enum).
- **archive_conversation_v1** — documented in SUPABASE_SETUP; migration 20260302_chat_archive_rpc_and_storage_helper.
- **Views:** `vw_unified_work_items`, `wallet_balances` — in SUPABASE_SETUP and migrations.
- **Orders decommission:** `lib/features/orders/README.md` and docs consistently describe removal and tombstone; STRUCTURE, DEVELOPER_GUIDE, ARCHITECTURE_ANALYSIS, Sline_Log aligned.

### DB object names (tables, views, RPCs, triggers)

- **Tables:** profiles, tasks, task_requests, conversations, direct_offers, messages, bookings, etc. — names in SUPABASE_SETUP match migration usage.
- **Enums:** task_type_enum, booking_status_enum, message_type_enum, payment_status_enum, payment_event_type_enum, related_entity_type_enum (with `direct_offer`), ledger_account_type_enum, ledger_direction_enum — documented and used in migrations.
- **RPCs:** process_payment_event_ledger, archive_conversation_v1, rpc_get_profile_summaries, rpc_submit_delivery, rpc_approve_delivery, etc. — references in docs match migration/usage.
- **Triggers:** fn_booking_guard, fn_direct_offer_guard, trg_conversations_before_insert_guard, trg_messages_before_insert_validate, trg_wallet_transactions_freeze, etc. — SUPABASE_SETUP names are correct; DEVELOPER_GUIDE Chat section uses the wrong/shortened names above.

---

## 3. Renamed or moved modules

- **Orders:** Docs correctly state the standalone orders runtime was removed and only `lib/features/orders/README.md` remains; no incorrect references to moved orders code.
- **service_card.dart:** STRUCTURE correctly notes "lib/features/home/view/widgets/service_card.dart was removed as dead code."
- **direct_offers:** New feature; not a rename. STRUCTURE simply omits it from the feature list and from supabase/functions.

No other renamed or moved modules were found that docs still reference under old paths.

---

## 4. Outdated statements (e.g. "X does Y" when code now does Z)

- **"DM requires freelancer in client favorites"** (DEVELOPER_GUIDE Chat §2.5 table and Triggers bullet): Current behavior (per SUPABASE_SETUP v2.1) is that **DM conversations no longer require the favorites relationship**. So the guide overstates the restriction.
- **"Only clients can start non-task DMs with favorites"** (DEVELOPER_GUIDE same section): Same as above; should align with "DM without favorites allowed (v2.1)."
- **message_type_enum** (DEVELOPER_GUIDE Chat §2.2): Doc says values "text, offer, offer_update, …" and **omits `system`**. SUPABASE_SETUP §4.3 and code include `system`; the guide is incomplete.
- **SUPABASE_SETUP "Last Updated: 2026-02-24":** Post-dated migrations (20260301–20260307) exist; the date is no longer accurate for "current" schema state.

---

## 5. Pipeline gate

**Pipeline gate: PROCEED**

Rationale:  
- The only **missing** reference is **`DEVELOPER_GUIDE/Inventory Feature.md`**, explicitly marked "(Planned)"; it is a placeholder, not a contract required for current execution.  
- **Wrong trigger/function names** in DEVELOPER_GUIDE are doc accuracy issues; the actual DB objects exist and are correctly named in SUPABASE_SETUP.  
- **DM/favorites** and **message_type_enum** are doc inconsistencies with current schema/behavior; they do not indicate missing code or broken build assumptions.  
- No broken refs were found that **invalidate plan assumptions** (e.g. missing tables, RPCs, or critical paths).  
Recommendation: Proceed with a follow-up docs sync to fix the deltas and references above.

---

## 6. Evidence

### Doc files validated

- `Sline_everything/SUPABASE_SETUP.md` (full scan + sections 1–5, 6–7, 9, triggers/RPCs)
- `Sline_everything/DEVELOPER_GUIDE.md` (Parts I–II, Chat, Profile, Data Model, Quick Links, error mapping)
- `Sline_everything/STRUCTURE.md` (full)
- `Sline_everything/MVP_ROADMAP.md` (full)
- `Sline_everything/Sline_Log.md` (version history and recent entries)
- `Sline_everything/ARCHITECTURE_ANALYSIS.md` (overview and current notes)
- `Sline_everything/CODE_REVIEW.md` (guardrails and references)
- `Sline_everything/COMPREHENSIVE_ANALYSIS_SUMMARY.md` (intro and references)
- `Sline_everything/DEVELOPER_GUIDE/` (all 14 feature .md files, including Orders Feature.md)

### Code and backend paths validated

- **lib/features:** auth, booking, categories, chat, dashboard, **direct_offers**, favorites, home, management, notifications, portfolio, profile, proposals, saved, search, services, tasks, wallet, work; and orders (README only).
- **supabase/functions:** _shared, booking_decline_refund, qicard_payment_create, qicard_payment_recovery, **qicard_payment_create_direct_offer**, **qicard_payment_recovery_direct_offer**, qicard_webhook_handler.
- **supabase/migrations:** 20260224–20260307 (names and presence of direct_offers, ledger, chat archive, enum fix).
- **lib/core:** config, models, providers, services, theme, utils, widgets; `error_mapper.dart`, `loading_utils.dart`, `payment_runtime_config.dart`, etc.
- **.cursor/rules:** error-handling.mdc and other .mdc files present.

### DB objects cross-checked

- Tables: direct_offers, conversations, messages, tasks, bookings, profiles, work_logs, journal_entries, ledger_lines, etc. (SUPABASE_SETUP vs migrations).
- Enums: message_type_enum (incl. system), payment_event_type_enum, related_entity_type_enum (incl. direct_offer).
- RPCs: process_payment_event_ledger, archive_conversation_v1.
- Triggers: fn_booking_guard, fn_direct_offer_guard, trg_conversations_before_insert_guard, messages_before_insert_validate, trg_wallet_transactions_freeze.

---

*End of report.*
