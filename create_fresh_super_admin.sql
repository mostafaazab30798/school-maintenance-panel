-- Fresh Super Admin Creation Script
-- Use this after flushing the database to create your first super admin

-- INSTRUCTIONS:
-- 1. First create a user in Supabase Auth Dashboard (Authentication → Users → Add User)
-- 2. Copy the auth_user_id (UUID) from the created user
-- 3. Replace the values below with your actual information
-- 4. Run this script in Supabase SQL Editor

-- Replace these values with your actual information:
INSERT INTO public.admins (name, email, auth_user_id, role, created_at)
VALUES (
  'Super Admin',  -- Replace with your actual name
  'superadmin@yourdomain.com',  -- Replace with your actual email (MUST match the auth user email exactly)
  'PASTE-YOUR-UUID-HERE',  -- Replace with the UUID from Supabase Auth Dashboard
  'super_admin',
  NOW()
);

-- Verify the super admin was created successfully
SELECT id, name, email, role, auth_user_id, created_at 
FROM public.admins 
WHERE role = 'super_admin';

-- Check that the auth user exists (should return 1 row)
SELECT id, email, email_confirmed_at 
FROM auth.users 
WHERE id = 'PASTE-YOUR-UUID-HERE';  -- Replace with the same UUID

-- If everything is successful, you should see:
-- 1. One admin record with role 'super_admin'
-- 2. One auth user record with matching email 