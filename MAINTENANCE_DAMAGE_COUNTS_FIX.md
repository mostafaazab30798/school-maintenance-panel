# Maintenance Counts and Damage Counts Data Loading Fix

## Issue Summary

The maintenance counts and damage counts screens are not showing data from the database because:

1. **Missing Database Table**: The `maintenance_counts` table doesn't exist in the database
2. **Potential Data Issues**: The `damage_counts` table exists but may have data access issues
3. **RLS Policies**: Row Level Security policies might be preventing data access

## Root Cause Analysis

### 1. Missing Maintenance Counts Table
The `maintenance_counts` table is referenced in the code but doesn't exist in the database. This causes:
- `CountInventoryScreen` to show empty state
- `MaintenanceCountsBloc` to fail when trying to load data
- Repository queries to return empty results

### 2. Data Access Issues
Both tables require proper RLS (Row Level Security) policies to allow admins to access data based on their supervisor assignments.

## Solution

### Step 1: Create Missing Database Tables

Run the following SQL script in your Supabase SQL Editor:

```sql
-- File: setup_maintenance_and_damage_tables.sql
-- This script creates both tables with proper structure and sample data
```

**Key Features:**
- Creates `maintenance_counts` table with all required JSONB columns
- Creates `damage_counts` table (if not exists) with proper structure
- Adds performance indexes for both tables
- Inserts sample data for testing
- Sets up proper RLS policies for admin access

### Step 2: Verify Database Setup

After running the SQL script, verify the setup:

```sql
-- Check if tables exist
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('maintenance_counts', 'damage_counts');

-- Check data counts
SELECT COUNT(*) as maintenance_counts_count FROM maintenance_counts;
SELECT COUNT(*) as damage_counts_count FROM damage_counts;

-- Check RLS policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename IN ('maintenance_counts', 'damage_counts');
```

### Step 3: Test Data Access

Test if the current admin can access the data:

```sql
-- Test admin access to maintenance counts
SELECT * FROM maintenance_counts 
WHERE supervisor_id IN (
    SELECT s.id FROM supervisors s
    JOIN admins a ON s.admin_id = a.id
    WHERE a.auth_user_id = auth.uid()
);

-- Test admin access to damage counts
SELECT * FROM damage_counts 
WHERE supervisor_id IN (
    SELECT s.id FROM supervisors s
    JOIN admins a ON s.admin_id = a.id
    WHERE a.auth_user_id = auth.uid()
);
```

## Code Analysis

### Maintenance Counts Flow

1. **Screen**: `CountInventoryScreen` loads with `LoadMaintenanceCountRecords` event
2. **Bloc**: `MaintenanceCountsBloc` handles the event in `_onLoadMaintenanceCountRecords`
3. **Repository**: `MaintenanceCountRepository.getAllMaintenanceCountRecords()` queries the database
4. **Issue**: Table doesn't exist, so query fails

### Damage Counts Flow

1. **Screen**: `DamageInventoryScreen` loads with `LoadSchoolsWithDamage` event
2. **Bloc**: `MaintenanceCountsBloc` handles the event in `_onLoadSchoolsWithDamage`
3. **Repository**: `DamageCountRepository.getSchoolsWithDamageCounts()` queries the database
4. **Issue**: RLS policies or data access issues prevent proper results

## Expected Behavior After Fix

### Maintenance Counts Screen
- Should display a list of maintenance count records
- Each record shows school name, status, and creation date
- Records are grouped by school
- Export functionality should work

### Damage Counts Screen
- Should display a list of schools with damage data
- Each school shows total damaged items count
- Schools without damage should also appear
- Export functionality should work

## Troubleshooting

### If Data Still Doesn't Load

1. **Check Admin Authentication**:
   ```dart
   // Add debug logging in AdminService
   print('Current user: ${_client.auth.currentUser?.id}');
   print('Admin role: ${await getCurrentUserRole()}');
   ```

2. **Check Supervisor Assignments**:
   ```dart
   // Add debug logging in MaintenanceCountsBloc
   final supervisorIds = await _adminService.getCurrentAdminSupervisorIds();
   print('Supervisor IDs: $supervisorIds');
   ```

3. **Check Database Permissions**:
   ```sql
   -- Test direct query access
   SELECT * FROM maintenance_counts LIMIT 5;
   SELECT * FROM damage_counts LIMIT 5;
   ```

### Common Issues

1. **RLS Policy Issues**: Make sure the admin has proper supervisor assignments
2. **Data Type Mismatches**: Ensure JSONB columns contain valid JSON
3. **Foreign Key Constraints**: Verify school_id and supervisor_id references exist
4. **Authentication Issues**: Ensure the user is properly authenticated

## Files Modified

1. **`setup_maintenance_and_damage_tables.sql`** - New file with complete table setup
2. **`maintenance_counts_table.sql`** - Individual maintenance counts table setup
3. **`damage_counts_table.sql`** - Existing file (verify it's applied)

## Testing Checklist

- [ ] Run the SQL setup script
- [ ] Verify tables exist in database
- [ ] Verify sample data is inserted
- [ ] Test maintenance counts screen loads data
- [ ] Test damage counts screen loads data
- [ ] Test export functionality
- [ ] Test detail screens work properly
- [ ] Verify RLS policies allow proper access

## Next Steps

1. Run the SQL setup script in Supabase
2. Test the screens to verify data loads
3. If issues persist, check the debug logs for specific error messages
4. Verify admin-supervisor-school relationships are properly set up 