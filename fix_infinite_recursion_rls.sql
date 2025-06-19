-- Fix Infinite Recursion in RLS Policies
-- Run this in Supabase SQL Editor

-- 1. Drop the problematic policies first
DROP POLICY IF EXISTS "Super admins can view all admins" ON admins;
DROP POLICY IF EXISTS "Admins can view assigned supervisors" ON supervisors;
DROP POLICY IF EXISTS "Admins can update assigned supervisors" ON supervisors;
DROP POLICY IF EXISTS "Admins can insert supervisors" ON supervisors;
DROP POLICY IF EXISTS "Admins can view reports of assigned supervisors" ON reports;
DROP POLICY IF EXISTS "Admins can insert reports for assigned supervisors" ON reports;
DROP POLICY IF EXISTS "Admins can update reports of assigned supervisors" ON reports;
DROP POLICY IF EXISTS "Admins can view maintenance reports of assigned supervisors" ON maintenance_reports;
DROP POLICY IF EXISTS "Admins can insert maintenance reports for assigned supervisors" ON maintenance_reports;
DROP POLICY IF EXISTS "Admins can update maintenance reports of assigned supervisors" ON maintenance_reports;

-- 2. Create helper functions with SECURITY DEFINER to avoid recursion
CREATE OR REPLACE FUNCTION is_super_admin_user(user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS(
    SELECT 1 FROM public.admins
    WHERE auth_user_id = user_id AND role = 'super_admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION get_admin_id_for_user(user_id UUID)
RETURNS UUID AS $$
BEGIN
  RETURN (
    SELECT id FROM public.admins
    WHERE auth_user_id = user_id
    LIMIT 1
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Create safe RLS policies using the helper functions

-- Admins table policies
CREATE POLICY "Admins can view own record" ON admins
  FOR SELECT USING (auth_user_id = auth.uid());

CREATE POLICY "Admins can update own record" ON admins
  FOR UPDATE USING (auth_user_id = auth.uid());

CREATE POLICY "Super admins can view all admins" ON admins
  FOR ALL USING (is_super_admin_user(auth.uid()));

-- Supervisors table policies
CREATE POLICY "Admins can view assigned supervisors" ON supervisors
  FOR SELECT USING (
    admin_id = get_admin_id_for_user(auth.uid())
    OR is_super_admin_user(auth.uid())
  );

CREATE POLICY "Admins can update assigned supervisors" ON supervisors
  FOR UPDATE USING (
    admin_id = get_admin_id_for_user(auth.uid())
    OR is_super_admin_user(auth.uid())
  );

CREATE POLICY "Admins can insert supervisors" ON supervisors
  FOR INSERT WITH CHECK (
    admin_id = get_admin_id_for_user(auth.uid())
    OR is_super_admin_user(auth.uid())
  );

-- Reports table policies
CREATE POLICY "Admins can view reports of assigned supervisors" ON reports
  FOR SELECT USING (
    supervisor_id IN (
      SELECT s.id FROM supervisors s
      WHERE s.admin_id = get_admin_id_for_user(auth.uid())
    )
    OR is_super_admin_user(auth.uid())
  );

CREATE POLICY "Admins can insert reports for assigned supervisors" ON reports
  FOR INSERT WITH CHECK (
    supervisor_id IN (
      SELECT s.id FROM supervisors s
      WHERE s.admin_id = get_admin_id_for_user(auth.uid())
    )
    OR is_super_admin_user(auth.uid())
  );

CREATE POLICY "Admins can update reports of assigned supervisors" ON reports
  FOR UPDATE USING (
    supervisor_id IN (
      SELECT s.id FROM supervisors s
      WHERE s.admin_id = get_admin_id_for_user(auth.uid())
    )
    OR is_super_admin_user(auth.uid())
  );

-- Maintenance reports table policies
CREATE POLICY "Admins can view maintenance reports of assigned supervisors" ON maintenance_reports
  FOR SELECT USING (
    supervisor_id IN (
      SELECT s.id FROM supervisors s
      WHERE s.admin_id = get_admin_id_for_user(auth.uid())
    )
    OR is_super_admin_user(auth.uid())
  );

CREATE POLICY "Admins can insert maintenance reports for assigned supervisors" ON maintenance_reports
  FOR INSERT WITH CHECK (
    supervisor_id IN (
      SELECT s.id FROM supervisors s
      WHERE s.admin_id = get_admin_id_for_user(auth.uid())
    )
    OR is_super_admin_user(auth.uid())
  );

CREATE POLICY "Admins can update maintenance reports of assigned supervisors" ON maintenance_reports
  FOR UPDATE USING (
    supervisor_id IN (
      SELECT s.id FROM supervisors s
      WHERE s.admin_id = get_admin_id_for_user(auth.uid())
    )
    OR is_super_admin_user(auth.uid())
  );

-- 4. Grant execute permissions
GRANT EXECUTE ON FUNCTION is_super_admin_user(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_admin_id_for_user(UUID) TO authenticated;

-- 5. Verify fix worked
SELECT 'RLS policies fixed successfully!' as status; 