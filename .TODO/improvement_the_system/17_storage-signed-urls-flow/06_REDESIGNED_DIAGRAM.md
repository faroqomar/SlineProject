# Redesigned Diagram: Storage Signed URLs Flow

```mermaid
sequenceDiagram
    participant U as User Display (SignedAvatar)
    participant App as Flutter App (TimedCache)
    participant Svc as Storage Service (Avatar/Chat)
    participant DB as Postgres (Profiles/Convos)
    participant S as Supabase Storage (storage.objects)

    Note over App, U: Check local cache for valid signed URL
    alt URL in cache and NOT expired
        App->>U: Display Image (Cached URL)
    else URL expired or not in cache
        App->>DB: SELECT path FROM [Table] WHERE id = [target_id]
        DB-->>App: "convos/456/attachment.png"

        App->>Svc: createSignedUrl(path, TTL)
        Svc->>S: createSignedUrl(path, TTL)

        Note over S: RLS Policy: can_access_chat_attachment(path, auth.uid()) OR is_admin(auth.uid())

        alt Authorized
            S-->>Svc: "https://...token=XYZ&expires_in=3600"
            Svc-->>App: signedUrl
            App->>App: Store in local TimedCache
            App->>U: Image.network(signedUrl)
        else Access Denied (Audit Failure)
            S-->>Svc: 403 Forbidden
            Svc-->>App: null / Error
            App->>U: Display Error/Placeholder
        end
    end

    Note right of S: Admin Auditor Path override
    S->>DB: Check profiles.roles for 'admin'
    DB-->>S: Role: 'admin'
    Note over S: Policy permits SELECT via is_admin helper
```

## Key Improvements

1. **Caching Layer**: Added `TimedCache` logic on the Flutter App side to prevent redundant RPC calls for the same image during a session.
2. **Object-Level RLS**: Explicitly included the `can_access_chat_attachment` check in the flow, closing the gap of broad bucket access.
3. **Admin/Auditor Access**: Added a path for administrative override, essential for dispute resolution.
4. **TTL Clarity**: Flow reflects standard TTLs (1h/2h) instead of the placeholder 600s.
5. **Detailed Failure Mode**: Added the "Access Denied" alternate path.
