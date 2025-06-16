-- Debug Authentication Issues
-- Run this in Supabase SQL Editor to diagnose login problems

-- 1. Check all auth users
SELECT 
  id,
  email,
  email_confirmed_at,
  created_at,
  last_sign_in_at
FROM auth.users
ORDER BY created_at DESC;

-- 2. Check all admin records
SELECT 
  id,
  name,
  email,
  auth_user_id,
  role,
  created_at
FROM public.admins
ORDER BY created_at DESC;

-- 3. Check if auth users have corresponding admin records
SELECT 
  au.id as auth_user_id,
  au.email as auth_email,
  a.id as admin_id,
  a.name as admin_name,
  a.role as admin_role,
  CASE 
    WHEN a.id IS NULL THEN 'MISSING ADMIN RECORD'
    ELSE 'ADMIN RECORD EXISTS'
  END as status
FROM auth.users au
LEFT JOIN public.admins a ON au.id = a.auth_user_id
ORDER BY au.created_at DESC;

-- 4. Find orphaned admin records (admin without auth user)
SELECT 
  a.id,
  a.name,
  a.email,
  a.auth_user_id,
  a.role,
  'ORPHANED - NO AUTH USER' as status
FROM public.admins a
LEFT JOIN auth.users au ON a.auth_user_id = au.id
WHERE au.id IS NULL;

-- 5. Create Super Admin if needed
-- Replace the values below with your actual admin email and details
-- First, find the auth_user_id from the results above

/*
-- Uncomment and modify this section to create missing admin records
-- Replace 'your-actual-auth-user-id' with the UUID from query 1 above
-- Replace 'admin@example.com' with your actual admin email

INSERT INTO public.admins (name, email, auth_user_id, role, created_at)
VALUES (
  'Super Admin',  -- Change this name
  'admin@example.com',  -- Use the EXACT email from auth.users
  'your-actual-auth-user-id',  -- Replace with actual UUID
  'super_admin',  -- or 'admin' for regular admin
  NOW()
)
ON CONFLICT (email) DO UPDATE SET
  auth_user_id = EXCLUDED.auth_user_id,
  role = EXCLUDED.role,
  updated_at = NOW();
*/

-- 6. Verify RLS policies are not blocking access
-- This will show if RLS is enabled on tables
SELECT 
  schemaname,
  tablename,
  rowsecurity
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN ('admins', 'supervisors', 'reports', 'maintenance_reports'); 