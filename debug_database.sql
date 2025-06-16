-- Debug Script for Admin Management System
-- Run this in Supabase SQL Editor to debug issues

-- 1. Check if tables exist
SELECT table_name, table_schema 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('admins', 'supervisors', 'reports', 'maintenance_reports');

-- 2. Check current data
SELECT 'admins' as table_name, COUNT(*) as count FROM admins
UNION ALL
SELECT 'supervisors', COUNT(*) FROM supervisors
UNION ALL  
SELECT 'reports', COUNT(*) FROM reports
UNION ALL
SELECT 'maintenance_reports', COUNT(*) FROM maintenance_reports;

-- 3. Check RLS status
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE tablename IN ('admins', 'supervisors', 'reports', 'maintenance_reports');

-- 4. Temporarily disable RLS for testing (ONLY FOR DEBUGGING)
-- CAUTION: This removes security - re-enable after testing!
ALTER TABLE admins DISABLE ROW LEVEL SECURITY;
ALTER TABLE supervisors DISABLE ROW LEVEL SECURITY;
ALTER TABLE reports DISABLE ROW LEVEL SECURITY;
ALTER TABLE maintenance_reports DISABLE ROW LEVEL SECURITY;

-- 5. Check existing admins
SELECT id, name, email, auth_user_id, role, created_at FROM admins;

-- 6. Check supervisor assignments
SELECT 
    s.id,
    s.username,
    s.email,
    s.admin_id,
    a.name as admin_name
FROM supervisors s
LEFT JOIN admins a ON s.admin_id = a.id
LIMIT 10;

-- 7. Check current auth user (run this when logged in)
SELECT auth.uid() as current_user_id;

-- 8. Create a test admin if none exists
-- Replace 'your-actual-auth-user-id' with a real UUID from auth.users
INSERT INTO admins (name, email, auth_user_id, role)
VALUES ('Test Admin', 'test@admin.com', 'your-actual-auth-user-id', 'super_admin')
ON CONFLICT (email) DO NOTHING;

-- 9. After testing, RE-ENABLE RLS (IMPORTANT!)
-- Uncomment these lines after debugging:
-- ALTER TABLE admins ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE supervisors ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE reports ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE maintenance_reports ENABLE ROW LEVEL SECURITY; 