# Improved Production-Grade Diagram: 12_unified-work-view

```mermaid
flowchart TD
    subgraph Data_Layer [Supabase / Postgres]
        direction TB

        subgraph Sources [Source Tables - RLS Protected]
            T[tasks]
            B[bookings]
            DO[direct_offers]
            TR[task_requests]
        end

        subgraph Overrides [Global Overrides]
            D[disputes]
        end

        View{{"vw_unified_work_items <br> WITH security_invoker = true"}}

        T -- "Branch 1: Active Work" --> View
        B -- "Branch 2: Bookings" --> View
        T & TR -- "Branch 3: Awarded (Unpaid)" --> View
        DO -- "Branch 4: Chat Offers" --> View

        D -. "LEFT JOIN <br> status: disputed" .-> View
    end

    subgraph App_Layer [Flutter MVVM]
        Service[WorkManagementService]
        Model[UnifiedWorkItemModel]

        View -- "Single Stream / Query" --> Service
        Service -- "Zero Logic Mapping" --> Model
    end

    subgraph Security_Context [RLS Context]
        UID[auth.uid]
    end

    UID ==> Sources
    UID ==> View

    classDef source fill:#fff3e0,stroke:#ff9800,stroke-width:2px;
    class T,B,DO,TR,D source;
    classDef aggregate fill:#e8f5e9,stroke:#4caf50,stroke-width:2px;
    class View aggregate;
    classDef security fill:#ffebee,stroke:#f44336,stroke-dasharray: 5 5;
    class UID security;
```

### Key Improvements:

1.  **Completeness**: Added `Branch 4` for `direct_offers` and `disputes` override.
2.  **Security**: View is marked `SECURITY_INVOKER` to natively respect RLS on source tables.
3.  **Simplicity**: Removed the need for a fallback mapper in Flutter; the view is the "Single Source of Truth".
4.  **Auditability**: `security_invoker` ensures that `auth.uid()` filtering happens at the DB level, not the app level.
