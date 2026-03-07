# 06. Minimal Patch Plan (Production Blockers)

## Blocker 1: Broad RLS allows Path Guessing (chat-attachments)

### SQL Patch (Additive)

Replace the broad `chat_attach_select_auth` policy with a restricted one, leveraging the existing migration helper.

```sql
-- 1. Drop existing permissive policy
DROP POLICY IF EXISTS "chat_attach_select_auth" ON storage.objects;

-- 2. Create the strict Object-Level policy
CREATE POLICY "chat_attach_select_restricted"
ON storage.objects FOR SELECT TO authenticated
USING (
  bucket_id = 'chat-attachments' AND
  public.can_access_chat_attachment(name, auth.uid())
);
```

### Verification

Attempt a `SELECT` with a user who is not a participant in the `convos/uuid/` route. Observe `403 Forbidden`.

## Blocker 2: Missing Admin Dispute Path

### SQL Patch

Update the `can_access_chat_attachment` function to bypass participant checks for `admin` users.

```sql
CREATE OR REPLACE FUNCTION public.can_access_chat_attachment(p_object_name text, p_uid uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_parts text[];
  v_conversation_id uuid;
  v_user1 uuid;
  v_user2 uuid;
  v_is_admin boolean;
BEGIN
  IF p_uid IS NULL OR p_object_name IS NULL OR p_object_name = '' THEN
    RETURN false;
  END IF;

  -- 1. Check if user is an admin
  SELECT EXISTS (
    SELECT 1 FROM public.profiles WHERE id = p_uid AND role = 'admin'
  ) INTO v_is_admin;

  IF v_is_admin THEN RETURN true; END IF;

  -- 2. Verify participant route
  v_parts := string_to_array(p_object_name, '/');
  IF array_length(v_parts, 1) < 2 OR v_parts[1] <> 'convos' THEN
    RETURN false;
  END IF;

  BEGIN
    v_conversation_id := v_parts[2]::uuid;
  EXCEPTION WHEN OTHERS THEN
    RETURN false;
  END;

  SELECT user1_id, user2_id INTO v_user1, v_user2
  FROM public.conversations
  WHERE id = v_conversation_id;

  IF NOT FOUND THEN RETURN false; END IF;

  RETURN p_uid = v_user1 OR p_uid = v_user2;
END;
$$;
```

### Verification

Log in as an Admin in the dispute dashboard and attempt to render a chat attachment. It should not return 403.

## Blocker 3: Cache Stampede in `AttachmentMessageTile`

### Flutter Code Patch

Update `lib/features/chat/attachments/widgets/attachment_message_tile.dart` to use `SignedUrlCache`.

```dart
// Modify _AttachmentMessageTileState.initState
@override
void initState() {
  super.initState();
  _loadSignedUrl();
}

Future<void> _loadSignedUrl() async {
  final cached = SignedUrlCache.get(widget.storagePath);
  if (cached != null) {
    if (mounted) setState(() => _resolvedUrl = cached);
    return;
  }

  // Call API and store in cache
  final freshUrl = widget.signedUrlResolver?.call(widget.storagePath) ??
    SupabaseAttachmentUploader().createSignedUrl(
      widget.storagePath,
      expiresInSeconds: 3600,
    );

  final resolved = await freshUrl;
  SignedUrlCache.set(widget.storagePath, resolved);

  if (mounted) setState(() => _resolvedUrl = resolved);
}
```

### Verification

Scroll rapidly through a chat history. Monitor the network tab (or flutter DevTools) to ensure `storage/v1/object/sign/chat-attachments` is called only once per unique image path while the cache is valid.
