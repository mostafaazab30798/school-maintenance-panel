-- Fix Admin Authentication Issue
-- This script creates an admin record for an existing auth user

-- Step 1: Check existing auth users
SELECT 
  id as auth_user_id,
  email,
  created_at,
  email_confirmed_at
FROM auth.users
ORDER BY created_at DESC
LIMIT 10;

-- Step 2: Check existing admin records
SELECT 
  id,
  name,
  email,
  auth_user_id,
  role,
  created_at
FROM public.admins
ORDER BY created_at DESC;

-- Step 3: Create admin record for your user
-- REPLACE THE VALUES BELOW WITH YOUR ACTUAL INFORMATION
-- Replace 'your-email@example.com' with your actual email
-- Replace 'Your Name' with your actual name
-- Replace 'your-auth-user-id-here' with the UUID from Step 1

INSERT INTO public.admins (name, email, auth_user_id, role, created_at)
VALUES (
  'Your Name',  -- CHANGE THIS to your actual name
  'your-email@example.com',  -- CHANGE THIS to your actual email
  'your-auth-user-id-here',  -- CHANGE THIS to your actual auth user ID
  'admin',  -- Use 'super_admin' if you want super admin privileges
  NOW()
)
ON CONFLICT (email) DO UPDATE SET
  auth_user_id = EXCLUDED.auth_user_id,
  role = EXCLUDED.role,
  name = EXCLUDED.name,
  updated_at = NOW();

-- Step 4: Verify the admin record was created
SELECT 
  a.id,
  a.name,
  a.email,
  a.role,
  a.auth_user_id,
  au.email as auth_email
FROM public.admins a
JOIN auth.users au ON a.auth_user_id = au.id
WHERE a.email = 'your-email@example.com'  -- CHANGE THIS to your actual email
ORDER BY a.created_at DESC; 