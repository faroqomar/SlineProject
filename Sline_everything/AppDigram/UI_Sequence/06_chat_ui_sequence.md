# 8.11 Chat / Conversation Flow

# 8.12 Notifications Flow

## Purpose

Showcases the realtime messaging streams, DM creation logic (gated by Favorites), Direct Chat Offers, and system Notifications.

## Sequences

### Sending a Message & Realtime

```mermaid
sequenceDiagram
    participant User
    participant ChatUI
    participant ChatVM
    participant Realtime
    participant DB

    User->>ChatUI: Type & Send
    ChatUI->>ChatVM: sendMessage(text)

    ChatVM->>DB: insert ('messages', payload)

    Note over Realtime: Triggered by Postgres CDC
    DB-->>Realtime: Push event
    Realtime-->>ChatVM: handleMessagePayload
    ChatVM->>ChatUI: Update ListView
```

### Direct Chat Offer Flow

```mermaid
flowchart TD
    Chat[Chat Screen] -->|Create Direct Offer| OfferModal[[Direct Offer Form]]
    OfferModal -->|Submit Price/Days| Service[DirectOffersService]
    Service -->|Insert DB| ChatTile[Render Offer Tile in Chat]

    Client[Client in Chat] -->|Sees Tile| Accept[Accept Offer]
    Accept --> Payment[QiCard Checkout]
    Payment -->|Success| Ledger[Escrow Held: Offer Active]
    Ledger --> Dashboard[Offer appears in Dashboard Work list]
```

### Notifications Flow

```mermaid
flowchart TD
    BackendTrigger[Server DB Trigger/Edge Fn] -->|Insert| PushQueue[notification_push_queue]
    PushQueue --> FCM[FCM/Push Service]
    FCM --> Device[User Device]
    Device -->|Tap Push| AppOpen[App Resolves Deep Link]

    AppOpen --> Sync[Foreground Sync]
    Sync --> NotifVM[Fetch Unread Notifications]
    NotifVM --> UI[Updates Badge & Feed]
```

## State Rules

- **Chat Realtime Integration**: Inbox syncs based on the `messages` stream to avoid N+1 queries on conversations. Typing presence has a 15s TTL.
- **Direct Offers**: Requires payment to activate. No work starts until the payment executes from the chat.
- **Favorites Gate**: Clients can only start direct chats out of nowhere with a Freelancer if the Freelancer is recorded in the `favorites` table. Atomic RPC `start_direct_conversation_v1` is used.
