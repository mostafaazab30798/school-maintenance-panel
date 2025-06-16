-- Script to create the first Super Admin
-- Step 1: First create a user in Supabase Auth Dashboard with email and password
-- Step 2: Get the auth_user_id from auth.users table
-- Step 3: Run this script with the correct auth_user_id

-- Example: Replace 'your-auth-user-id-here' with the actual UUID from auth.users
INSERT INTO public.admins (name, email, auth_user_id, role, created_at)
VALUES (
  'Super Admin',  -- Change this to the actual name
  'superadmin@example.com',  -- Change this to the actual email (must match auth user email)
  'your-auth-user-id-here',  -- Replace with actual UUID from auth.users table
  'super_admin',
  NOW()
);

-- Verify the super admin was created
SELECT id, name, email, role, created_at 
FROM public.admins 
WHERE role = 'super_admin';

-- Optional: Create a regular admin for testing
-- First create another auth user, then run:
/*
INSERT INTO public.admins (name, email, auth_user_id, role, created_at)
VALUES (
  'Regular Admin',
  'admin@example.com', 
  'another-auth-user-id-here',
  'admin',
  NOW()
);
*/ 