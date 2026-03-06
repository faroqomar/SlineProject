# 06_DIAGRAM_FINAL (Production-Grade)

```mermaid
graph TD
    subgraph Identity ["Identity Layer"]
        Auth[Supabase Auth] --> UserContext[auth.uid / auth.jwt]
    end

    subgraph Policies ["RLS Boundary (Zero-Trust)"]
        direction TB
        Self["Self-Service (uid = id)"]
        Involved["Participatory (is_participant)"]
        Public["Public Read (status = 'open')"]
        System["System Execution (service_role)"]
    end

    UserContext -->|auth.role = 'anon'| Public
    UserContext -->|auth.role = 'authenticated'| Self
    UserContext -->|auth.role = 'authenticated'| Involved
    UserContext -->|auth.role = 'service_role'| System

    %% Data Mapping
    Self --> Tables1["profiles (Personal Info)"]
    Self --> Tables2["notifications, favorites"]
    Involved --> Tables3["conversations, messages, bookings"]
    Involved --> Tables4["tasks (In-Progress)"]
    Public --> Tables5["tasks (Open), profiles (Summaries via RPC)"]
    System --> Tables6["ledger_lines, journal_entries, audits"]

    %% Visual Styling
    style System fill:#f96,stroke:#333,stroke-width:2px
    style Public fill:#fff,stroke:#333,stroke-dasharray: 5 5
    style Identity fill:#ccf,stroke:#333
```

_Design Principles: Roles are clearly segmented. PII is locked behind 'Self'. Business processes are locked behind 'Involved'. Critical finance is reserved for 'System'._
