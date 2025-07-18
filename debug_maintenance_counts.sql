-- Debug script to check maintenance_counts table status
-- Run these queries in your Supabase SQL Editor

-- 1. Check if there's any data in the table
SELECT 
  COUNT(*) as total_records,
  COUNT(CASE WHEN status = 'submitted' THEN 1 END) as submitted_records,
  COUNT(CASE WHEN status = 'draft' THEN 1 END) as draft_records
FROM public.maintenance_counts;

-- 2. Check the actual data (if any exists)
SELECT 
  id,
  school_id,
  school_name,
  supervisor_id,
  status,
  created_at
FROM public.maintenance_counts
ORDER BY created_at DESC
LIMIT 10;

-- 3. Check if there are any schools in the schools table
SELECT 
  COUNT(*) as total_schools,
  COUNT(DISTINCT name) as unique_school_names
FROM public.schools;

-- 4. Check supervisor assignments
SELECT 
  COUNT(*) as total_supervisors,
  COUNT(DISTINCT supervisor_id) as unique_supervisors
FROM public.supervisors;

-- 5. Check admin-supervisor relationships
SELECT 
  COUNT(*) as total_admin_supervisor_assignments
FROM public.admin_supervisors;

-- 6. Check if the current user has any supervisor assignments
-- (This will show results only if you're logged in as an admin)
SELECT 
  a.name as admin_name,
  a.role as admin_role,
  s.id as supervisor_id,
  s.name as supervisor_name
FROM public.admins a
JOIN public.admin_supervisors ads ON a.id = ads.admin_id
JOIN public.supervisors s ON ads.supervisor_id = s.id
WHERE a.auth_user_id = auth.uid();

-- 7. Check RLS policies for maintenance_counts
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies 
WHERE tablename = 'maintenance_counts';

-- 8. Test if current user can access maintenance_counts data
-- (This will show results only if you're logged in)
SELECT 
  COUNT(*) as accessible_records
FROM public.maintenance_counts mc
WHERE EXISTS (
  SELECT 1 FROM public.admin_supervisors ads
  JOIN public.admins a ON ads.admin_id = a.id
  WHERE a.auth_user_id = auth.uid()
  AND ads.supervisor_id = mc.supervisor_id
)
OR EXISTS (
  SELECT 1 FROM public.admins a
  WHERE a.auth_user_id = auth.uid()
  AND a.role = 'super_admin'
);

-- 9. Check if there are any maintenance counts for supervisors assigned to current admin
SELECT 
  mc.id,
  mc.school_name,
  mc.status,
  mc.created_at,
  s.name as supervisor_name
FROM public.maintenance_counts mc
JOIN public.supervisors s ON mc.supervisor_id = s.id
JOIN public.admin_supervisors ads ON s.id = ads.supervisor_id
JOIN public.admins a ON ads.admin_id = a.id
WHERE a.auth_user_id = auth.uid()
ORDER BY mc.created_at DESC;

-- 10. Check for any error logs or issues
SELECT 
  'Database setup appears correct' as status,
  (SELECT COUNT(*) FROM public.maintenance_counts) as maintenance_counts,
  (SELECT COUNT(*) FROM public.schools) as schools,
  (SELECT COUNT(*) FROM public.supervisors) as supervisors,
  (SELECT COUNT(*) FROM public.admins) as admins; 