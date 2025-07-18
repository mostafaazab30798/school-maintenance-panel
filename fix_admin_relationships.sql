-- Fix admin-supervisor relationships
-- This is the most common cause of data not showing up

-- 1. First, let's see what we're working with
SELECT 
  'Current Status' as info,
  (SELECT COUNT(*) FROM public.admins) as total_admins,
  (SELECT COUNT(*) FROM public.supervisors) as total_supervisors,
  (SELECT COUNT(*) FROM public.admin_supervisors) as total_relationships;

-- 2. Create admin-supervisor relationships for all admins
-- This assigns all supervisors to all admins (you can modify this logic later)
INSERT INTO public.admin_supervisors (admin_id, supervisor_id)
SELECT 
  a.id as admin_id,
  s.id as supervisor_id
FROM public.admins a
CROSS JOIN public.supervisors s
ON CONFLICT (admin_id, supervisor_id) DO NOTHING;

-- 3. Verify the relationships were created
SELECT 
  'After Fix' as info,
  (SELECT COUNT(*) FROM public.admin_supervisors) as total_relationships;

-- 4. Show the relationships
SELECT 
  a.name as admin_name,
  a.role as admin_role,
  s.name as supervisor_name
FROM public.admins a
JOIN public.admin_supervisors ads ON a.id = ads.admin_id
JOIN public.supervisors s ON ads.supervisor_id = s.id
ORDER BY a.name, s.name;

-- 5. Test if current user can now access maintenance_counts
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

-- 6. Test if current user can now access damage_counts
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

-- 7. If the above tests return 0, let's also check RLS policies
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies 
WHERE tablename IN ('maintenance_counts', 'damage_counts')
ORDER BY tablename, policyname; 