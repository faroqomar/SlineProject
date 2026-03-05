-- Migration: 20260301_auth_profile_bootstrap.sql

-- 1. Create the trigger function
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, email, avatar_url, active_role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'avatar_url', ''),
    COALESCE(NEW.raw_user_meta_data->>'active_role', 'client')
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

-- 2. Create the trigger on auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- 3. Create the temporary self-heal RPC
CREATE OR REPLACE FUNCTION public.rpc_ensure_self_profile()
RETURNS public.profiles
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_profile public.profiles;
  v_user_email text;
BEGIN
  -- We must only operate on the authenticated user's ID
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Get current user email from auth
  SELECT email INTO v_user_email FROM auth.users WHERE id = auth.uid();
  
  -- Insert profile if it doesn't exist
  INSERT INTO public.profiles (id, email, full_name, active_role)
  VALUES (auth.uid(), v_user_email, '', 'client')
  ON CONFLICT (id) DO NOTHING;

  -- Return the guaranteed profile row
  SELECT * INTO v_profile FROM public.profiles WHERE id = auth.uid();
  RETURN v_profile;
END;
$$;
