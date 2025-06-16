-- Debug Admin Creation Issues
-- Run these queries in Supabase SQL Editor to check for common problems

-- 1. Check if 'admins' table exists and has correct structure
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'admins'
ORDER BY ordinal_position;

-- 2. Check if the 'role' column exists (common issue)
SELECT EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_name = 'admins' 
    AND column_name = 'role'
) as role_column_exists;

-- 3. Check current super admin (replace with your auth_user_id)
SELECT * FROM admins WHERE role = 'super_admin';

-- 4. Check RLS policies on admins table
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'admins';

-- 5. Test if we can insert a basic admin record (manual test)
-- Replace 'your-auth-user-id' with an actual UUID
/*
INSERT INTO admins (name, email, auth_user_id, role) 
VALUES ('Test Admin', 'test@example.com', 'your-auth-user-id', 'admin');
*/

-- 6. Check if email already exists
SELECT * FROM admins WHERE email = 'ashraf@gmail.com';

-- 7. Check auth.users table for any existing user with that email
SELECT id, email, created_at FROM auth.users WHERE email = 'ashraf@gmail.com'; 