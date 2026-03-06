# Current Diagram (As Audited): 12_unified-work-view

```mermaid
flowchart TD
    subgraph View_Aggregation [vw_unified_work_items]
        direction TB
        View([Postgres View])
    end

    subgraph Source_Tables [Primary Sources]
        Tasks[tasks <br> status: in_progress, delivered, completed]
        Bookings[bookings <br> status: active, delivered, completed]
        Awarded[tasks + task_requests <br> accepted, unpaid bids]
    end

    Tasks -- "source_type: task <br> mapped to UnifiedWorkStatus" --> View
    Bookings -- "source_type: booking <br> mapped to UnifiedWorkStatus" --> View
    Awarded -- "source_type: task <br> pending_payment" --> View

    subgraph Service_Logic [WorkManagementService]
        Service[WorkManagementService.getUnifiedWorkItem]
        Fallback[UnifiedWorkItemFallbackMapper]
    end

    View --> Service
    Fallback -. "Hardcoded Mapping <br> if View Null" .-> Service

    classDef source fill:#f9f,stroke:#333,stroke-width:2px;
    class Tasks,Bookings,Awarded source;
    classDef logic fill:#e1f5fe,stroke:#01579b,stroke-width:1px;
    class Service,Fallback logic;
```

### Analysis of Current State:

- **Strengths**: Consolidation works for core tasks and bookings.
- **Weaknesses**: Fallback logic in Dart indicates the view is not robust enough. Missing `direct_offers` and `disputed` status.
