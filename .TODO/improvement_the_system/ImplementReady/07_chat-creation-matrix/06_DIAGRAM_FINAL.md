# Redesigned Diagram (Final): Chat Creation Matrix

```mermaid
flowchart TD
    START[User attempts startConversation] --> AUTH{Auth.uid() correct?}
    AUTH -->|No| DENY_AUTH[DENY: Unauthenticated or Identity Theft]
    AUTH -->|Yes| CTX{Context Type?}

    %% Path A: Task-Linked
    CTX -->|Task Context| T1{User Role?}
    T1 -->|Freelancer| T2{Has active bid or booking?}
    T1 -->|Owner| T3{app.allow_owner_task_conversation?}

    T2 -->|Yes| ALLOW_T[ALLOW via start_task_conversation_v1]
    T2 -->|No| DENY_T1[DENY: Task access restricted]

    T3 -->|true| ALLOW_REJECT[ALLOW: Reject Flow Exception]
    T3 -->|false| DENY_T2[DENY: Owner cannot initiate chat]

    %% Path B: Direct DM
    CTX -->|Direct DM| R1{Active Role?}
    R1 -->|Freelancer| DENY_F[DENY: Freelancers cannot initiate DMs]
    R1 -->|Client| R2{Freelancer in Favorites?}

    R2 -->|Yes| ALLOW_D[ALLOW via start_direct_conversation_v1]
    R2 -->|No| DENY_D[DENY: Favorites rule not satisfied]

    %% Post-Insert
    ALLOW_T --> NORM[Normalize user1_id < user2_id]
    ALLOW_REJECT --> NORM
    ALLOW_D --> NORM
    NORM --> DONE[Conversation Established]

    style ALLOW_T fill:#9f9,stroke:#333,stroke-width:2px
    style ALLOW_REJECT fill:#9f9,stroke:#333,stroke-width:2px
    style ALLOW_D fill:#9f9,stroke:#333,stroke-width:2px
    style DENY_AUTH fill:#f99,stroke:#333
    style DENY_T1 fill:#f99,stroke:#333
    style DENY_T2 fill:#f99,stroke:#333
    style DENY_F fill:#f99,stroke:#333
    style DENY_D fill:#f99,stroke:#333
```
