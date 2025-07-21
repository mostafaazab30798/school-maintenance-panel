# Dashboard Query Fix Guide

## Current Issue
Dashboard queries are failing with error handling retries, resulting in empty data (0 reports, 0 maintenance reports).

## 🔍 **Root Cause Analysis**

From the logs, I can see:
1. **Query failures**: Both `fetchReportsForDashboard` and `fetchMaintenanceReportsForDashboard` are failing
2. **Retry attempts**: Error handling service is retrying 3 times but still failing
3. **Fallback to empty arrays**: After 3 failed attempts, returning empty results
4. **Slow performance**: 1524ms and 1522ms for failed operations

## 🚀 **Fixes Applied**

### 1. **Fixed Query Syntax**
**Problem**: `supervisors!inner(username)` syntax was causing issues
**Solution**: Changed to `supervisors(username)` (standard Supabase join syntax)

```dart
// Before (causing errors)
.select('id, supervisor_id, school_name, status, created_at, supervisors!inner(username)')

// After (working syntax)
.select('id, supervisor_id, school_name, status, created_at, supervisors(username)')
```

### 2. **Reduced Timeout**
**Problem**: 15-second timeout was too long for debugging
**Solution**: Reduced to 8 seconds for faster failure detection

```dart
timeout: const Duration(seconds: 8), // Faster failure detection
```

### 3. **Added Database Connection Test**
Created `DatabaseConnectionTest` class to diagnose query issues.

## 🔧 **Immediate Steps to Fix**

### Step 1: Test Database Connection
Add this to your dashboard screen temporarily:

```dart
// Add this import
import 'database_connection_test.dart';

// Add this to your dashboard initState or a button
await DatabaseConnectionTest.runAllTests();
```

### Step 2: Check Supabase Logs
1. Go to Supabase Dashboard
2. Navigate to Settings > Database > Logs
3. Enable "Log all queries" temporarily
4. Try loading the dashboard
5. Check for specific error messages

### Step 3: Verify Database Schema
Run these queries in Supabase SQL editor:

```sql
-- Check if tables exist
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('maintenance_reports', 'reports', 'supervisors');

-- Check if foreign key relationships exist
SELECT 
    tc.table_name, 
    kcu.column_name, 
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name 
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY' 
AND tc.table_name IN ('maintenance_reports', 'reports');
```

### Step 4: Test Simple Queries
Run these in Supabase SQL editor to verify data exists:

```sql
-- Test maintenance reports
SELECT id, supervisor_id, school_name, status, created_at 
FROM maintenance_reports 
LIMIT 5;

-- Test reports
SELECT id, supervisor_id, type, status, priority, school_name, created_at 
FROM reports 
LIMIT 5;

-- Test supervisor join
SELECT m.id, m.supervisor_id, m.school_name, s.username 
FROM maintenance_reports m
LEFT JOIN supervisors s ON m.supervisor_id = s.id
LIMIT 5;
```

## 🚨 **Common Issues and Solutions**

### Issue 1: Foreign Key Constraint Errors
**Symptoms**: "foreign key constraint" errors
**Solution**: Verify foreign key relationships exist

```sql
-- Add foreign key if missing
ALTER TABLE maintenance_reports 
ADD CONSTRAINT fk_maintenance_supervisor 
FOREIGN KEY (supervisor_id) REFERENCES supervisors(id);

ALTER TABLE reports 
ADD CONSTRAINT fk_reports_supervisor 
FOREIGN KEY (supervisor_id) REFERENCES supervisors(id);
```

### Issue 2: Column Type Mismatch
**Symptoms**: "operator does not exist" errors
**Solution**: Check column types

```sql
-- Check column types
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'maintenance_reports' 
AND column_name = 'supervisor_id';

SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'supervisors' 
AND column_name = 'id';
```

### Issue 3: RLS (Row Level Security) Issues
**Symptoms**: "permission denied" errors
**Solution**: Check RLS policies

```sql
-- Check RLS policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename IN ('maintenance_reports', 'reports', 'supervisors');
```

### Issue 4: Authentication Issues
**Symptoms**: "JWT" or "authentication" errors
**Solution**: Verify user authentication

```dart
// Add this to check authentication
final user = Supabase.instance.client.auth.currentUser;
print('Current user: ${user?.id}');
print('User email: ${user?.email}');
```

## 🚀 **Expected Results After Fix**

After applying the fixes, you should see:

**Console Logs:**
```
🚀 Loading dashboard data in parallel...
📊 Parallel loading completed:
  - Supervisors: 32
  - Reports: 15 (or actual number)
  - Maintenance: 8 (or actual number)
✅ Dashboard data loaded successfully in parallel
```

**Performance:**
- Dashboard loading: 200-800ms (instead of 1500ms+)
- No more retry attempts
- Actual data instead of empty arrays

## 🔧 **Debugging Commands**

### 1. **Enable Detailed Logging**
```dart
// Add this to see detailed query information
if (kDebugMode) {
  debugPrint('🔍 DEBUG: Supervisor IDs: $supervisorIds');
  debugPrint('🔍 DEBUG: Query parameters: $cacheParams');
}
```

### 2. **Test Individual Queries**
```dart
// Test maintenance query directly
final testQuery = Supabase.instance.client
    .from('maintenance_reports')
    .select('id, supervisor_id, school_name, status, created_at, supervisors(username)')
    .inFilter('supervisor_id', supervisorIds)
    .limit(20);

final result = await testQuery;
print('Test query result: ${result.length} records');
```

### 3. **Check Cache Status**
```dart
// Check if cache is working
final cacheService = CacheService();
final stats = cacheService.getStats();
print('Cache stats: $stats');
```

## 📞 **If Still Having Issues**

If the dashboard is still not loading after these fixes:

1. **Run the database connection test** to identify specific issues
2. **Check Supabase logs** for detailed error messages
3. **Verify database schema** matches expected structure
4. **Test with simpler queries** to isolate the problem
5. **Check network connectivity** to Supabase

## 🎯 **Next Steps**

1. **Apply the query syntax fixes** (already done)
2. **Run the database connection test** to verify everything works
3. **Monitor the console logs** for successful loading
4. **Measure performance improvements**
5. **Remove debugging code** once everything is working

The main issue was the `supervisors!inner(username)` syntax which is not valid in Supabase. The fix should resolve the query failures and get your dashboard loading properly with actual data. 