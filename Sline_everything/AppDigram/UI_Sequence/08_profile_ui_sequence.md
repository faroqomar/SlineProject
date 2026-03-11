# 8.14 Profile Flow

# 8.15 Settings Flow

# 8.16 Saved Tasks / Favorites Flow

# 8.17 Portfolio / Public Profile Preview Flow

## Purpose

Governs user profile configuration, atomic role switching, viewing portfolios, tracking saved tasks and favorite freelancers.

## Sequences

### Atomic Role Switch Flow

```mermaid
sequenceDiagram
    participant User
    participant ProfileUI
    participant RoleCoordinator
    participant RoleRPC
    participant ViewModels

    User->>ProfileUI: Tap "Switch to Freelancer"
    ProfileUI->>RoleCoordinator: toggleRole()

    RoleCoordinator->>RoleRPC: switch_active_role() (Atomic DB Check)
    RoleRPC-->>RoleCoordinator: Success

    Note over RoleCoordinator: Trigger strict teardown contract
    RoleCoordinator->>ViewModels: execute protocol: teardown()
    ViewModels-->>ViewModels: Clear caches, sockets, feed data

    RoleCoordinator->>SupabaseAuth: Refresh JWT Session
    RoleCoordinator->>ProfileUI: Navigate -> Dashboard
    ProfileUI->>User: Renders freshly loaded Freelancer environment
```

### Portfolio Management

```mermaid
flowchart TD
    Profile[Profile Settings] --> PortfolioHub[Manage Portfolio]
    PortfolioHub --> Form[[Add Item Sheet]]
    Form -->|Pick Image| Compressor[Compress Image Data]
    Compressor --> Storage[Upload to Supabase Storage]
    Storage -->|Get Path| DB[Insert public.portfolio_items]
    DB --> PortfolioHub[Update List]

    Client[Any User] --> Preview[Public Profile Preview]
    Preview -->|Renders| SignedUrl(Fetches Signed Storage URL)
```

## Screen Details

- **Role Switching**: Rate limited (max 3/min) on both Client and Server. Fully tears down local Provider dependencies.
- **Favorites & Saved**: Favorites exist heavily to enable direct DMs `ux_convo_pair_direct`. Saved tasks live purely for tracking purposes under the profile tab.
- **Portfolio Options**: Handled as an inline list on the public profile preview, expanding to full-screen views on interaction.
