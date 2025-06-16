-- Quick Fix: Create Admin Record for Existing Auth User
-- This script will create an admin record for an existing auth user

-- Step 1: Find your auth user (look for your email)
SELECT 
  id as auth_user_id,
  email,
  created_at,
  email_confirmed_at
FROM auth.users
ORDER BY created_at DESC
LIMIT 10;

-- Step 2: Copy the auth_user_id from above and use it below
-- IMPORTANT: Replace the values below with your actual information

DO $$
DECLARE
    user_email TEXT := 'your-email@example.com';    -- CHANGE THIS to your actual email
    user_name TEXT := 'Admin User';                 -- CHANGE THIS to your preferred name
    user_role TEXT := 'super_admin';                -- Use 'super_admin' or 'admin'
    auth_user_uuid UUID;
BEGIN
    -- Find the auth user ID automatically
    SELECT id INTO auth_user_uuid 
    FROM auth.users 
    WHERE email = user_email;
    
    -- Check if we found the user
    IF auth_user_uuid IS NULL THEN
        RAISE EXCEPTION 'No auth user found with email: %', user_email;
    END IF;
    
    -- Create or update the admin record
    INSERT INTO public.admins (name, email, auth_user_id, role, created_at)
    VALUES (user_name, user_email, auth_user_uuid, user_role, NOW())
    ON CONFLICT (email) DO UPDATE SET
        auth_user_id = EXCLUDED.auth_user_id,
        role = EXCLUDED.role,
        name = EXCLUDED.name,
        updated_at = NOW();
    
    RAISE NOTICE 'Admin record created/updated successfully for: %', user_email;
END $$;

-- Step 3: Verify the admin was created
SELECT 
    a.id,
    a.name,
    a.email,
    a.role,
    a.auth_user_id,
    au.email as auth_email
FROM public.admins a
JOIN auth.users au ON a.auth_user_id = au.id
ORDER BY a.created_at DESC; 