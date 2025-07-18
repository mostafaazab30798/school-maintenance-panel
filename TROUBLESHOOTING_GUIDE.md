# Troubleshooting Guide: Maintenance Counts & Damage Counts Data Loading

## Quick Diagnosis Steps

### Step 1: Check Database Data
Run this in your Supabase SQL Editor to see if there's data:

```sql
-- Check if maintenance_counts table has data
SELECT COUNT(*) as total_records FROM public.maintenance_counts;

-- Check if damage_counts table has data  
SELECT COUNT(*) as total_records FROM public.damage_counts;

-- Check if schools table has data
SELECT COUNT(*) as total_schools FROM public.schools;

-- Check if supervisors table has data
SELECT COUNT(*) as total_supervisors FROM public.supervisors;
```

### Step 2: Check Admin-Supervisor Relationships
```sql
-- Check if current admin has supervisor assignments
SELECT 
  a.name as admin_name,
  a.role as admin_role,
  s.id as supervisor_id,
  s.name as supervisor_name
FROM public.admins a
JOIN public.admin_supervisors ads ON a.id = ads.admin_id
JOIN public.supervisors s ON ads.supervisor_id = s.id
WHERE a.auth_user_id = auth.uid();
```

### Step 3: Test Data Access
```sql
-- Test if current user can access maintenance_counts
SELECT COUNT(*) as accessible_records
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
```

## Common Issues & Solutions

### Issue 1: No Data in Tables
**Symptoms**: Both screens show empty state
**Solution**: Run the test data insertion script:

```sql
-- Run add_test_maintenance_data.sql to add sample data
```

### Issue 2: RLS Policy Blocking Access
**Symptoms**: Data exists but admin can't see it
**Solution**: Check and fix RLS policies:

```sql
-- Check existing RLS policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies 
WHERE tablename IN ('maintenance_counts', 'damage_counts');

-- If policies are missing, run the setup script
-- setup_maintenance_and_damage_tables.sql
```

### Issue 3: Admin-Supervisor Relationship Missing
**Symptoms**: Admin exists but has no supervisor assignments
**Solution**: Create admin-supervisor relationships:

```sql
-- Add admin-supervisor relationships
INSERT INTO public.admin_supervisors (admin_id, supervisor_id)
SELECT a.id, s.id
FROM public.admins a
CROSS JOIN public.supervisors s
WHERE a.auth_user_id = auth.uid()
ON CONFLICT (admin_id, supervisor_id) DO NOTHING;
```

### Issue 4: Authentication Issues
**Symptoms**: Admin not found or authentication errors
**Solution**: Check admin setup:

```sql
-- Check if current user is an admin
SELECT * FROM public.admins WHERE auth_user_id = auth.uid();

-- If not found, create admin record
INSERT INTO public.admins (name, email, auth_user_id, role)
VALUES ('Admin User', 'admin@example.com', auth.uid(), 'admin')
ON CONFLICT (auth_user_id) DO NOTHING;
```

## Debug Logging

The code now includes debug logging. Check your Flutter console for these messages:

### Maintenance Counts Debug Messages
```
🔍 DEBUG: Starting _onLoadMaintenanceCountRecords
🔍 DEBUG: Admin found: true/false
🔍 DEBUG: Admin role: admin/super_admin
🔍 DEBUG: Getting supervisor IDs for regular admin
🔍 DEBUG: Supervisor IDs: [list of IDs]
🔍 DEBUG: Using supervisor ID: [ID]
🔍 DEBUG: Calling repository.getAllMaintenanceCountRecords
🔍 DEBUG: Repository returned [X] records
```

### Repository Debug Messages
```
🔍 DEBUG: Starting getAllMaintenanceCountRecords
🔍 DEBUG: supervisorId: [ID or null]
🔍 DEBUG: Query executed successfully
🔍 DEBUG: Response length: [X]
🔍 DEBUG: Parsed [X] MaintenanceCount objects
```

## Testing Checklist

### Database Level
- [ ] `maintenance_counts` table exists and has data
- [ ] `damage_counts` table exists and has data
- [ ] `schools` table has school records
- [ ] `supervisors` table has supervisor records
- [ ] `admins` table has admin records
- [ ] `admin_supervisors` table has relationships
- [ ] RLS policies are properly configured

### Application Level
- [ ] Admin is properly authenticated
- [ ] Admin has supervisor assignments
- [ ] Debug logs show successful data retrieval
- [ ] No authentication errors in console
- [ ] No database permission errors

### UI Level
- [ ] Maintenance counts screen shows data
- [ ] Damage counts screen shows data
- [ ] Export functionality works
- [ ] Detail screens load properly
- [ ] Refresh functionality works

## Quick Fix Commands

### If Tables Are Empty
```sql
-- Run this to add test data
\i add_test_maintenance_data.sql
```

### If RLS Policies Are Missing
```sql
-- Run this to set up proper policies
\i setup_maintenance_and_damage_tables.sql
```

### If Admin Has No Supervisor Assignments
```sql
-- Run this to assign all supervisors to current admin
INSERT INTO public.admin_supervisors (admin_id, supervisor_id)
SELECT a.id, s.id
FROM public.admins a
CROSS JOIN public.supervisors s
WHERE a.auth_user_id = auth.uid()
ON CONFLICT (admin_id, supervisor_id) DO NOTHING;
```

## Expected Results

After fixing the issues, you should see:

### Maintenance Counts Screen
- List of maintenance count records
- Each record shows school name, status, creation date
- Records are sorted by creation date (newest first)
- Export button appears when data is available

### Damage Counts Screen
- List of schools with damage data
- Each school shows total damaged items count
- Schools are displayed in a grid layout
- Export button appears when data is available

## Next Steps

1. Run the debug SQL queries to identify the specific issue
2. Apply the appropriate fix based on the diagnosis
3. Test the screens to verify data loads
4. Check debug logs for any remaining issues
5. If problems persist, check the console for specific error messages 