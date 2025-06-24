-- Quick RLS Fix for Admin Access
-- Option 1: Temporarily disable RLS (quick fix)
ALTER TABLE admins DISABLE ROW LEVEL SECURITY;
ALTER TABLE reports DISABLE ROW LEVEL SECURITY;
ALTER TABLE maintenance_reports DISABLE ROW LEVEL SECURITY;

-- Option 2: If you want to keep RLS enabled, create very permissive policies
-- Uncomment the following lines if you prefer to keep RLS enabled:

/*
-- Drop all existing policies first
DROP POLICY IF EXISTS "admins_policy" ON admins;
DROP POLICY IF EXISTS "reports_policy" ON reports;
DROP POLICY IF EXISTS "maintenance_reports_policy" ON maintenance_reports;

-- Create permissive policies for authenticated users
CREATE POLICY "admins_all_access" ON admins FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "reports_all_access" ON reports FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "maintenance_reports_all_access" ON maintenance_reports FOR ALL TO authenticated USING (true) WITH CHECK (true);
*/

-- Check current user authentication status
SELECT 
  auth.uid() as user_id,
  auth.jwt() ->> 'email' as email,
  auth.jwt() ->> 'role' as role_from_jwt,
  current_user as database_user; 