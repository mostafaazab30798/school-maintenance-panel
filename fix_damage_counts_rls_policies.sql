-- Fix RLS Policies for Damage Counts and Maintenance Counts
-- This script fixes the RLS policies to match the current admin service implementation
-- Run this in your Supabase SQL Editor

-- 1. Drop existing problematic RLS policies
DROP POLICY IF EXISTS "Admins can view damage counts for their assigned schools" ON damage_counts;
DROP POLICY IF EXISTS "Admins can insert damage counts for assigned schools" ON damage_counts;
DROP POLICY IF EXISTS "Admins can view maintenance counts for their assigned schools" ON maintenance_counts;
DROP POLICY IF EXISTS "Admins can insert maintenance counts for assigned schools" ON maintenance_counts;

-- 2. Create helper functions to avoid infinite recursion
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

-- 3. Create new RLS policies for damage_counts that match the admin service
CREATE POLICY "Admins can view damage counts for their assigned supervisors" ON damage_counts
  FOR SELECT USING (
    supervisor_id IN (
      SELECT s.id FROM supervisors s
      WHERE s.admin_id = get_admin_id_for_user(auth.uid())
    )
    OR is_super_admin_user(auth.uid())
  );

CREATE POLICY "Admins can insert damage counts for their assigned supervisors" ON damage_counts
  FOR INSERT WITH CHECK (
    supervisor_id IN (
      SELECT s.id FROM supervisors s
      WHERE s.admin_id = get_admin_id_for_user(auth.uid())
    )
    OR is_super_admin_user(auth.uid())
  );

CREATE POLICY "Admins can update damage counts for their assigned supervisors" ON damage_counts
  FOR UPDATE USING (
    supervisor_id IN (
      SELECT s.id FROM supervisors s
      WHERE s.admin_id = get_admin_id_for_user(auth.uid())
    )
    OR is_super_admin_user(auth.uid())
  );

-- 4. Create new RLS policies for maintenance_counts that match the admin service
CREATE POLICY "Admins can view maintenance counts for their assigned supervisors" ON maintenance_counts
  FOR SELECT USING (
    supervisor_id IN (
      SELECT s.id FROM supervisors s
      WHERE s.admin_id = get_admin_id_for_user(auth.uid())
    )
    OR is_super_admin_user(auth.uid())
  );

CREATE POLICY "Admins can insert maintenance counts for their assigned supervisors" ON maintenance_counts
  FOR INSERT WITH CHECK (
    supervisor_id IN (
      SELECT s.id FROM supervisors s
      WHERE s.admin_id = get_admin_id_for_user(auth.uid())
    )
    OR is_super_admin_user(auth.uid())
  );

CREATE POLICY "Admins can update maintenance counts for their assigned supervisors" ON maintenance_counts
  FOR UPDATE USING (
    supervisor_id IN (
      SELECT s.id FROM supervisors s
      WHERE s.admin_id = get_admin_id_for_user(auth.uid())
    )
    OR is_super_admin_user(auth.uid())
  );

-- 5. Grant execute permissions
GRANT EXECUTE ON FUNCTION is_super_admin_user(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_admin_id_for_user(UUID) TO authenticated;

-- 6. Test the policies
SELECT 'RLS policies fixed successfully!' as status;

-- 7. Verify the current user can access damage_counts
SELECT 
  COUNT(*) as accessible_damage_records
FROM public.damage_counts dc
WHERE EXISTS (
  SELECT 1 FROM supervisors s
  WHERE s.admin_id = get_admin_id_for_user(auth.uid())
  AND s.id = dc.supervisor_id
)
OR is_super_admin_user(auth.uid());

-- 8. Verify the current user can access maintenance_counts
SELECT 
  COUNT(*) as accessible_maintenance_records
FROM public.maintenance_counts mc
WHERE EXISTS (
  SELECT 1 FROM supervisors s
  WHERE s.admin_id = get_admin_id_for_user(auth.uid())
  AND s.id = mc.supervisor_id
)
OR is_super_admin_user(auth.uid()); 