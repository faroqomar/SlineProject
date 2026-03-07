-- Storage RLS Test Fixtures
--
-- These fixtures create test data for storage RLS policy testing.
-- They provide users, conversations, and storage objects for testing
-- the signed URL access controls.
--
-- Usage:
--   psql -d your_database -f storage_rls_test_data.sql
--
-- Or run via Supabase MCP in staging environment before running tests.

-- Test User IDs (consistent with test/rls/fixtures/rls_test_users.dart)
DO $$
DECLARE
    v_client_id uuid := '11111111-1111-1111-1111-111111111111';
    v_freelancer_id uuid := '22222222-2222-2222-2222-222222222222';
    v_other_client_id uuid := '33333333-3333-3333-3333-333333333333';
    v_admin_id uuid := '44444444-4444-4444-4444-444444444444';
    v_conversation_id uuid := 'cccccccc-cccc-cccc-cccc-cccccccccccc';
BEGIN
    -- Insert test profiles (if not exists)
    INSERT INTO public.profiles (id, full_name, roles, active_role)
    VALUES 
        (v_client_id, 'Test Client', '{client}', 'client')
    ON CONFLICT (id) DO UPDATE SET 
        full_name = EXCLUDED.full_name,
        roles = EXCLUDED.roles;

    INSERT INTO public.profiles (id, full_name, roles, active_role)
    VALUES 
        (v_freelancer_id, 'Test Freelancer', '{freelancer}', 'freelancer')
    ON CONFLICT (id) DO UPDATE SET 
        full_name = EXCLUDED.full_name,
        roles = EXCLUDED.roles;

    INSERT INTO public.profiles (id, full_name, roles, active_role)
    VALUES 
        (v_other_client_id, 'Other Test Client', '{client}', 'client')
    ON CONFLICT (id) DO UPDATE SET 
        full_name = EXCLUDED.full_name,
        roles = EXCLUDED.roles;

    INSERT INTO public.profiles (id, full_name, roles, active_role)
    VALUES 
        (v_admin_id, 'Test Admin', '{client,admin}', 'client')
    ON CONFLICT (id) DO UPDATE SET 
        full_name = EXCLUDED.full_name,
        roles = EXCLUDED.roles;

    -- Insert test conversation between client and freelancer
    INSERT INTO public.conversations (id, user1_id, user2_id, created_at)
    VALUES (v_conversation_id, v_client_id, v_freelancer_id, now())
    ON CONFLICT (id) DO NOTHING;

    -- Note: Storage objects cannot be inserted via SQL directly.
    -- The actual storage objects should be created via the test harness
    -- using the Supabase Storage API. This fixture provides the metadata.
    
    RAISE NOTICE 'Storage RLS test fixtures created successfully';
    RAISE NOTICE 'Test Client ID: %', v_client_id;
    RAISE NOTICE 'Test Freelancer ID: %', v_freelancer_id;
    RAISE NOTICE 'Other Client ID: %', v_other_client_id;
    RAISE NOTICE 'Admin ID: %', v_admin_id;
    RAISE NOTICE 'Conversation ID: %', v_conversation_id;
END $$;

-- Storage paths expected by tests:
-- chat-attachments/convos/cccccccc-cccc-cccc-cccc-cccccccccccc/test-file.jpg
-- task-images/11111111-1111-1111-1111-111111111111/test-task-image.jpg
-- avatars/11111111-1111-1111-1111-111111111111/test-avatar.jpg

-- Expected test outcomes:
-- 1. Client CAN access chat-attachments in their conversation
-- 2. Freelancer CAN access chat-attachments in their conversation  
-- 3. Other client CANNOT access chat-attachments in conversation they're not part of
-- 4. Admin CAN access all chat-attachments (for dispute resolution)
-- 5. Owner CAN access their task-images
-- 6. Non-owner CANNOT access others' task-images
-- 7. Admin CAN access all task-images