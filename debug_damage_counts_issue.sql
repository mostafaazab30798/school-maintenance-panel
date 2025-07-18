-- Debug Damage Counts Issue
-- Run this in your Supabase SQL Editor to diagnose the problem

-- 1. Check if damage_counts table exists and has data
SELECT 
  'Damage Counts Table Status' as info,
  (SELECT COUNT(*) FROM information_schema.tables WHERE table_name = 'damage_counts') as table_exists,
  (SELECT COUNT(*) FROM damage_counts) as total_records;

-- 2. Check if maintenance_counts table exists and has data
SELECT 
  'Maintenance Counts Table Status' as info,
  (SELECT COUNT(*) FROM information_schema.tables WHERE table_name = 'maintenance_counts') as table_exists,
  (SELECT COUNT(*) FROM maintenance_counts) as total_records;

-- 3. Check current user authentication
SELECT 
  'Current User Status' as info,
  auth.uid() as user_id,
  auth.jwt() ->> 'email' as email,
  current_user as database_user;

-- 4. Check if current user is an admin
SELECT 
  'Admin Status' as info,
  id as admin_id,
  name as admin_name,
  role as admin_role,
  auth_user_id
FROM public.admins 
WHERE auth_user_id = auth.uid();

-- 5. Check supervisor assignments for current admin
SELECT 
  'Supervisor Assignments' as info,
  s.id as supervisor_id,
  s.name as supervisor_name,
  s.admin_id as assigned_admin_id,
  a.name as assigned_admin_name
FROM public.supervisors s
LEFT JOIN public.admins a ON s.admin_id = a.id
WHERE s.admin_id = (
  SELECT id FROM public.admins WHERE auth_user_id = auth.uid()
);

-- 6. Check all damage counts with their supervisor info
SELECT 
  'Damage Counts with Supervisor Info' as info,
  dc.id as damage_count_id,
  dc.school_id,
  dc.school_name,
  dc.supervisor_id,
  s.name as supervisor_name,
  s.admin_id as supervisor_admin_id,
  a.name as supervisor_admin_name,
  dc.status,
  dc.created_at
FROM public.damage_counts dc
LEFT JOIN public.supervisors s ON dc.supervisor_id = s.id
LEFT JOIN public.admins a ON s.admin_id = a.id
ORDER BY dc.created_at DESC
LIMIT 10;

-- 7. Check RLS policies for damage_counts
SELECT 
  'RLS Policies for damage_counts' as info,
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies 
WHERE tablename = 'damage_counts'
ORDER BY policyname;

-- 8. Test direct access to damage_counts (should work for super admins)
SELECT 
  'Direct Access Test' as info,
  COUNT(*) as accessible_records
FROM public.damage_counts;

-- 9. Test filtered access based on supervisor assignments
SELECT 
  'Filtered Access Test' as info,
  COUNT(*) as accessible_records
FROM public.damage_counts dc
WHERE EXISTS (
  SELECT 1 FROM public.supervisors s
  WHERE s.admin_id = (
    SELECT id FROM public.admins WHERE auth_user_id = auth.uid()
  )
  AND s.id = dc.supervisor_id
);

-- 10. Check if there are any damage counts for the current admin's supervisors
SELECT 
  'Damage Counts for Current Admin Supervisors' as info,
  dc.id as damage_count_id,
  dc.school_name,
  dc.supervisor_id,
  s.name as supervisor_name,
  dc.status,
  dc.created_at
FROM public.damage_counts dc
INNER JOIN public.supervisors s ON dc.supervisor_id = s.id
WHERE s.admin_id = (
  SELECT id FROM public.admins WHERE auth_user_id = auth.uid()
)
ORDER BY dc.created_at DESC;

-- 11. Check if the admin_supervisors table exists and has data
SELECT 
  'Admin Supervisors Table Status' as info,
  (SELECT COUNT(*) FROM information_schema.tables WHERE table_name = 'admin_supervisors') as table_exists,
  (SELECT COUNT(*) FROM admin_supervisors) as total_relationships;

-- 12. If admin_supervisors table exists, check relationships
SELECT 
  'Admin Supervisor Relationships' as info,
  ads.admin_id,
  ads.supervisor_id,
  a.name as admin_name,
  s.name as supervisor_name
FROM public.admin_supervisors ads
LEFT JOIN public.admins a ON ads.admin_id = a.id
LEFT JOIN public.supervisors s ON ads.supervisor_id = s.id
WHERE ads.admin_id = (
  SELECT id FROM public.admins WHERE auth_user_id = auth.uid()
);

-- 13. Test the helper functions
SELECT 
  'Helper Functions Test' as info,
  is_super_admin_user(auth.uid()) as is_super_admin,
  get_admin_id_for_user(auth.uid()) as admin_id;

-- 14. Final test - what the RLS policies should allow
SELECT 
  'RLS Policy Test' as info,
  COUNT(*) as accessible_records
FROM public.damage_counts dc
WHERE (
  dc.supervisor_id IN (
    SELECT s.id FROM supervisors s
    WHERE s.admin_id = get_admin_id_for_user(auth.uid())
  )
  OR is_super_admin_user(auth.uid())
); 