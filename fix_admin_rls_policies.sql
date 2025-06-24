-- Fix RLS Policies for Admin Access
-- This script ensures admin users have proper access to all tables

-- First, let's create helper functions that don't cause infinite recursion
CREATE OR REPLACE FUNCTION public.is_authenticated_user()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT auth.uid() IS NOT NULL;
$$;

CREATE OR REPLACE FUNCTION public.get_user_role()
RETURNS text
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT 
    CASE 
      WHEN auth.uid() IS NULL THEN 'anonymous'
      WHEN EXISTS (
        SELECT 1 FROM auth.users 
        WHERE id = auth.uid() 
        AND raw_user_meta_data->>'role' = 'super_admin'
      ) THEN 'super_admin'
      WHEN EXISTS (
        SELECT 1 FROM auth.users 
        WHERE id = auth.uid() 
        AND raw_user_meta_data->>'role' = 'admin'
      ) THEN 'admin'
      ELSE 'user'
    END;
$$;

CREATE OR REPLACE FUNCTION public.is_admin_user()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT get_user_role() IN ('admin', 'super_admin');
$$;

CREATE OR REPLACE FUNCTION public.is_super_admin_user()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT get_user_role() = 'super_admin';
$$;

-- Drop existing problematic policies
DROP POLICY IF EXISTS "admins_policy" ON admins;
DROP POLICY IF EXISTS "admins_select_policy" ON admins;
DROP POLICY IF EXISTS "admins_insert_policy" ON admins;
DROP POLICY IF EXISTS "admins_update_policy" ON admins;
DROP POLICY IF EXISTS "admins_delete_policy" ON admins;

DROP POLICY IF EXISTS "reports_policy" ON reports;
DROP POLICY IF EXISTS "reports_select_policy" ON reports;
DROP POLICY IF EXISTS "reports_insert_policy" ON reports;
DROP POLICY IF EXISTS "reports_update_policy" ON reports;

DROP POLICY IF EXISTS "maintenance_reports_policy" ON maintenance_reports;
DROP POLICY IF EXISTS "maintenance_reports_select_policy" ON maintenance_reports;
DROP POLICY IF EXISTS "maintenance_reports_insert_policy" ON maintenance_reports;
DROP POLICY IF EXISTS "maintenance_reports_update_policy" ON maintenance_reports;

DROP POLICY IF EXISTS "notification_queue_policy" ON notification_queue;
DROP POLICY IF EXISTS "notification_queue_select_policy" ON notification_queue;
DROP POLICY IF EXISTS "notification_queue_insert_policy" ON notification_queue;

DROP POLICY IF EXISTS "user_fcm_tokens_policy" ON user_fcm_tokens;
DROP POLICY IF EXISTS "user_fcm_tokens_select_policy" ON user_fcm_tokens;
DROP POLICY IF EXISTS "user_fcm_tokens_insert_policy" ON user_fcm_tokens;

-- Create new, permissive policies for admin access

-- Admins table policies
CREATE POLICY "admins_full_access_policy" ON admins
FOR ALL
TO authenticated
USING (is_admin_user())
WITH CHECK (is_admin_user());

-- Reports table policies  
CREATE POLICY "reports_admin_access_policy" ON reports
FOR ALL
TO authenticated
USING (is_admin_user())
WITH CHECK (is_admin_user());

-- Maintenance reports table policies
CREATE POLICY "maintenance_reports_admin_access_policy" ON maintenance_reports
FOR ALL
TO authenticated
USING (is_admin_user())
WITH CHECK (is_admin_user());

-- Notification queue policies
CREATE POLICY "notification_queue_admin_access_policy" ON notification_queue
FOR ALL
TO authenticated
USING (is_admin_user())
WITH CHECK (is_admin_user());

-- User FCM tokens policies
CREATE POLICY "user_fcm_tokens_admin_access_policy" ON user_fcm_tokens
FOR ALL
TO authenticated
USING (is_admin_user())
WITH CHECK (is_admin_user());

-- Also allow service role access for all tables (for Edge Functions)
CREATE POLICY "admins_service_role_policy" ON admins
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

CREATE POLICY "reports_service_role_policy" ON reports
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

CREATE POLICY "maintenance_reports_service_role_policy" ON maintenance_reports
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

CREATE POLICY "notification_queue_service_role_policy" ON notification_queue
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

CREATE POLICY "user_fcm_tokens_service_role_policy" ON user_fcm_tokens
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- Ensure RLS is enabled on all tables
ALTER TABLE admins ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE maintenance_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_queue ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_fcm_tokens ENABLE ROW LEVEL SECURITY;

-- Grant necessary permissions to authenticated users
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Grant permissions to service role (for Edge Functions)
GRANT USAGE ON SCHEMA public TO service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO service_role;

-- Verify the user has proper role in auth.users metadata
-- This should show the user's role
SELECT 
  id,
  email,
  raw_user_meta_data->>'role' as role,
  created_at
FROM auth.users
WHERE email LIKE '%admin%' OR raw_user_meta_data->>'role' IN ('admin', 'super_admin')
ORDER BY created_at DESC
LIMIT 5; 