# Dashboard Performance Troubleshooting Guide

## Current Issue
Dashboard loading is still taking a long time even after implementing database indexes.

## 🚀 **Immediate Optimizations Implemented**

### 1. **Parallel Loading**
- Dashboard now loads all data in parallel instead of sequentially
- Reduced from 5+ sequential calls to 5 parallel calls
- **Expected improvement**: 60-80% faster loading

### 2. **Dashboard-Optimized Methods**
- `fetchMaintenanceReportsForDashboard()`: Minimal columns, smaller limits
- `fetchReportsForDashboard()`: Optimized for dashboard scenarios
- **Expected improvement**: 30-50% less data transfer

### 3. **Smart Caching**
- Fast cache configuration (2-minute TTL for dashboard)
- Background refresh when cache is near expiry
- **Expected improvement**: Instant loading on cache hits

## 🔍 **Troubleshooting Steps**

### Step 1: Check Current Performance
```dart
// Add this to your dashboard screen to measure loading time
final stopwatch = Stopwatch()..start();
// ... dashboard loading code ...
stopwatch.stop();
print('Dashboard loaded in: ${stopwatch.elapsedMilliseconds}ms');
```

### Step 2: Identify Bottlenecks
Check the console logs for these patterns:

**If you see:**
```
🚀 Loading dashboard data in parallel...
📊 Parallel loading completed:
  - Supervisors: X
  - Reports: X  
  - Maintenance: X
✅ Dashboard data loaded successfully in parallel
```
**Then:** The parallel loading is working correctly.

**If you see:**
```
MaintenanceReportRepository: Starting fetchMaintenanceReports
```
**Then:** It's still using the old method instead of the dashboard method.

### Step 3: Check Database Query Performance
Run these queries in your Supabase SQL editor to check performance:

```sql
-- Check if indexes are being used
EXPLAIN ANALYZE 
SELECT id, supervisor_id, school_name, status, created_at, supervisors!inner(username)
FROM maintenance_reports 
WHERE supervisor_id = 'some-supervisor-id' 
ORDER BY created_at DESC 
LIMIT 20;

-- Check query execution time
SELECT 
  query,
  mean_exec_time,
  calls,
  total_exec_time
FROM pg_stat_statements 
WHERE query LIKE '%maintenance_reports%'
ORDER BY mean_exec_time DESC;
```

## 🚀 **Additional Optimizations to Try**

### 1. **Database Connection Pooling**
If you're using Supabase, ensure connection pooling is enabled:
```sql
-- Check current connections
SELECT count(*) FROM pg_stat_activity WHERE datname = current_database();

-- Check for connection issues
SELECT * FROM pg_stat_activity WHERE state = 'active';
```

### 2. **Query Optimization**
Add these indexes if not already created:
```sql
-- Composite index for dashboard queries
CREATE INDEX idx_maintenance_dashboard_optimized 
ON maintenance_reports(supervisor_id, status, created_at DESC) 
INCLUDE (id, school_name);

-- Index for reports dashboard
CREATE INDEX idx_reports_dashboard_optimized 
ON reports(supervisor_id, status, created_at DESC) 
INCLUDE (id, type, priority, school_name);
```

### 3. **Cache Warming**
Implement cache warming for frequently accessed data:
```dart
// Add this to your app initialization
Future<void> warmDashboardCache() async {
  final adminService = AdminService(Supabase.instance.client);
  final supervisorIds = await adminService.getCurrentAdminSupervisorIds();
  
  // Preload dashboard data in background
  unawaited(
    Future.wait([
      maintenanceRepository.fetchMaintenanceReportsForDashboard(
        supervisorIds: supervisorIds,
        limit: 20,
      ),
      reportRepository.fetchReportsForDashboard(
        supervisorIds: supervisorIds,
        limit: 50,
      ),
    ])
  );
}
```

### 4. **Reduce Data Transfer**
Check if you're fetching unnecessary data:
```dart
// Instead of fetching all reports, fetch only what's needed for dashboard
final dashboardReports = await reportRepository.fetchReportsForDashboard(
  supervisorIds: supervisorIds,
  limit: 50, // Limit for dashboard
);
```

## 🔧 **Debugging Commands**

### 1. **Performance Monitoring**
```dart
// Add this widget to your dashboard to monitor performance
PerformanceMonitorWidget()
```

### 2. **Cache Status Check**
```dart
// Check cache status
final cacheService = CacheService();
final stats = cacheService.getStats();
print('Cache stats: $stats');
```

### 3. **Database Query Analysis**
```dart
// Enable query logging in Supabase
// Go to Supabase Dashboard > Settings > Database > Logs
// Enable "Log all queries" temporarily
```

## 📊 **Expected Performance Targets**

After all optimizations:
- **First load**: 200-400ms (was 631ms+)
- **Cache hit**: <50ms (instant)
- **Background refresh**: No user waiting
- **Overall UX**: Responsive and smooth

## 🚨 **Common Issues and Solutions**

### Issue 1: Still Using Old Methods
**Symptoms:** Console shows old method names
**Solution:** Ensure you're using the new dashboard methods:
```dart
// Use these methods for dashboard
maintenanceRepository.fetchMaintenanceReportsForDashboard()
reportRepository.fetchReportsForDashboard()
```

### Issue 2: Cache Not Working
**Symptoms:** Always hitting database
**Solution:** Check cache configuration:
```dart
// Verify cache is enabled
final cacheService = CacheService();
print('Cache enabled: ${cacheService.isCached("test")}');
```

### Issue 3: Database Indexes Not Used
**Symptoms:** Queries still slow
**Solution:** Verify indexes exist:
```sql
-- Check if indexes exist
SELECT indexname, tablename 
FROM pg_indexes 
WHERE tablename = 'maintenance_reports';
```

### Issue 4: Too Much Data
**Symptoms:** Large response sizes
**Solution:** Implement pagination and limits:
```dart
// Use smaller limits for dashboard
limit: 20, // Instead of unlimited
```

## 🎯 **Next Steps**

1. **Measure current performance** using the debugging tools
2. **Identify the slowest operation** from the logs
3. **Apply targeted optimizations** based on the bottleneck
4. **Test and measure improvements**
5. **Repeat until target performance is achieved**

## 📞 **If Still Having Issues**

If dashboard loading is still slow after implementing all optimizations:

1. **Check network latency** to Supabase
2. **Monitor database CPU/memory usage**
3. **Consider database scaling** if needed
4. **Implement progressive loading** (load critical data first)
5. **Use skeleton screens** for better perceived performance

## 🚀 **Progressive Loading Implementation**

If you need even faster perceived performance:

```dart
// Load critical data first
emit(DashboardLoadingCritical());

// Load supervisors and basic stats
final supervisors = await supervisorRepository.fetchSupervisors();
final basicStats = await calculateBasicStats();

emit(DashboardLoadedBasic(supervisors, basicStats));

// Load detailed data in background
unawaited(_loadDetailedData());
```

This approach will show the dashboard faster while loading detailed data in the background. 