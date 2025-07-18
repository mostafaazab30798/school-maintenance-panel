-- Check admin-supervisor relationships and RLS policies
-- Run this in your Supabase SQL Editor

-- 1. Check if current user is an admin
SELECT 
  id,
  name,
  email,
  role,
  auth_user_id
FROM public.admins 
WHERE auth_user_id = auth.uid();

-- 2. Check admin-supervisor relationships for current user
SELECT 
  a.name as admin_name,
  a.role as admin_role,
  s.id as supervisor_id,
  s.name as supervisor_name
FROM public.admins a
JOIN public.admin_supervisors ads ON a.id = ads.admin_id
JOIN public.supervisors s ON ads.supervisor_id = s.id
WHERE a.auth_user_id = auth.uid();

-- 3. Check if there are any admin-supervisor relationships at all
SELECT 
  COUNT(*) as total_admin_supervisor_relationships
FROM public.admin_supervisors;

-- 4. Check RLS policies for maintenance_counts
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

-- 5. Test if current user can access maintenance_counts data
SELECT 
  COUNT(*) as accessible_maintenance_records
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

-- 6. Test if current user can access damage_counts data
SELECT 
  COUNT(*) as accessible_damage_records
FROM public.damage_counts dc
WHERE EXISTS (
  SELECT 1 FROM public.admin_supervisors ads
  JOIN public.admins a ON ads.admin_id = a.id
  WHERE a.auth_user_id = auth.uid()
  AND ads.supervisor_id = dc.supervisor_id
)
OR EXISTS (
  SELECT 1 FROM public.admins a
  WHERE a.auth_user_id = auth.uid()
  AND a.role = 'super_admin'
);

-- 7. Show the actual maintenance count record
SELECT 
  id,
  school_id,
  school_name,
  supervisor_id,
  status,
  created_at
FROM public.maintenance_counts
ORDER BY created_at DESC;

-- 8. Check if the supervisor of the maintenance count is assigned to any admin
SELECT 
  mc.school_name,
  mc.supervisor_id,
  s.name as supervisor_name,
  CASE 
    WHEN ads.admin_id IS NOT NULL THEN 'Assigned to admin'
    ELSE 'NOT assigned to any admin'
  END as assignment_status
FROM public.maintenance_counts mc
JOIN public.supervisors s ON mc.supervisor_id = s.id
LEFT JOIN public.admin_supervisors ads ON s.id = ads.supervisor_id; 