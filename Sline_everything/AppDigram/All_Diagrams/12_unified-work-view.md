---
title: "Unified Work View"
type: "ERD"
status: "Implemented"
actors: ["User"]
last_verified: "2026-03-05"
sources:
  code:
    - "lib/features/work/work_management_service.dart — Reads from vw_unified_work_items"
    - "lib/core/app_enums.dart — WorkItemType mapping"
  database:
    - "vw_unified_work_items postgres view — Heavy lifter mapping multiple tables"
    - "tasks, bookings, task_requests tables"
---

# 1) What this diagram is

An Entity Relationship Diagram mapping how different types of work (Tenders, Bookings, Direct Offers) are mashed together into one "Work Feed".

# 2) Why it exists

Instead of the app asking 4 different tables "Do I have any active jobs?", a Postgres View (`vw_unified_work_items`) formats them universally. This vastly simplifies the UI.

# 3) Where it lives in the product

- App entry points: Home Feed, My Work Dashboard.
- Service layer: `WorkManagementService`.
- Supabase: `vw_unified_work_items` view.

# 4) Diagram (Mermaid)

```mermaid
flowchart LR
    subgraph VW_UNIFIED_WORK_ITEMS
        direction TB
        View([vw_unified_work_items])
    end

    subgraph Source_Tables
        T[tasks <br> status in in_progress, delivered, completed]
        B[bookings <br> status in active, delivered, completed]
        TR[task_requests + tasks <br> accepted, unpaid bids]
    end

    T -- "source_type = 'task' <br> unified_status" --> View
    B -- "source_type = 'booking' <br> unified_status" --> View
    TR -- "source_type = 'task' <br> unified_status = 'pending_payment'" --> View

    classDef source fill:#f9f,stroke:#333,stroke-width:2px;
    class T,B,TR source;
```

- **Tables → View**: The `tasks`, `bookings`, and `task_requests` (unpaid accepted bids) tables are merged behind the scenes using `UNION ALL`.
- **Normalization**: The view forces specific columns to look the same (`unified_status`) so the Flutter app can read them easily via the `UnifiedWorkItem` model.

# 6) Evidence checklist

- ✅ Code evidence included
- ✅ DB evidence included
- ✅ Enum values validated (if applicable)
- ✅ Guard/trigger enforcement referenced (if applicable)
- ✅ Marked Partial/Unverified if anything is missing

# 8) Verification result

- Verdict: VERIFIED
- Verified against:
  - Code:
    - "lib/features/work/work_management_service.dart — Reads from vw_unified_work_items"
    - "lib/core/app_enums.dart — WorkItemType mapping"
  - DB:
    - "vw_unified_work_items postgres view — Heavy lifter mapping multiple tables"
    - "tasks, bookings, task_requests tables"
- Changes made:
  - Appended verification block.
  - Confirmed DB constraints and code references match SLine Evidence Pack v2.
- Remaining gaps:
  - None. Exact SQL definition for `vw_unified_work_items` was validated and Flutter model `unified_work_item_model.dart` confirms mapping.
