# Database Optimization Guide for Maintenance Reports

## Current Performance Issue
- **Problem**: `MaintenanceReportRepository.fetchMaintenanceReports` taking 631ms
- **Target**: Reduce to under 300ms (performance monitoring threshold)
- **Root Cause**: Missing database indexes and inefficient queries

## 🚀 Database Indexes to Create

### 1. Primary Indexes (High Priority)
```sql
-- Index for supervisor filtering (most common filter)
CREATE INDEX idx_maintenance_supervisor_id ON maintenance_reports(supervisor_id);

-- Index for status filtering (frequently used)
CREATE INDEX idx_maintenance_status ON maintenance_reports(status);

-- Index for ordering by creation date (always used)
CREATE INDEX idx_maintenance_created_at ON maintenance_reports(created_at DESC);
```

### 2. Composite Indexes (Medium Priority)
```sql
-- Composite index for supervisor + status queries
CREATE INDEX idx_maintenance_supervisor_status ON maintenance_reports(supervisor_id, status);

-- Composite index for supervisor + created_at queries
CREATE INDEX idx_maintenance_supervisor_created ON maintenance_reports(supervisor_id, created_at DESC);

-- Composite index for status + created_at queries
CREATE INDEX idx_maintenance_status_created ON maintenance_reports(status, created_at DESC);
```

### 3. Covering Indexes (Advanced Optimization)
```sql
-- Covering index for dashboard queries (minimal columns)
CREATE INDEX idx_maintenance_dashboard ON maintenance_reports(supervisor_id, status, created_at DESC) 
INCLUDE (id, school_name);

-- Covering index for list queries (all needed columns)
CREATE INDEX idx_maintenance_list ON maintenance_reports(supervisor_id, status, created_at DESC) 
INCLUDE (id, school_name, description, images, closed_at, completion_photos, completion_note);
```

## 🚀 Query Optimization Strategies

### 1. Selective Column Fetching
**Before:**
```sql
SELECT *, supervisors(username) FROM maintenance_reports
```

**After:**
```sql
SELECT 
  id,
  supervisor_id,
  school_name,
  description,
  status,
  images,
  created_at,
  closed_at,
  completion_photos,
  completion_note,
  supervisors!inner(username)
FROM maintenance_reports
```

### 2. Proper Pagination
```sql
-- Always use LIMIT and OFFSET for pagination
SELECT ... FROM maintenance_reports 
WHERE supervisor_id = ? 
ORDER BY created_at DESC 
LIMIT 20 OFFSET 0;
```

### 3. Optimized Joins
```sql
-- Use INNER JOIN for required relationships
SELECT ... FROM maintenance_reports 
INNER JOIN supervisors ON maintenance_reports.supervisor_id = supervisors.id
WHERE maintenance_reports.supervisor_id = ?
ORDER BY maintenance_reports.created_at DESC;
```

## 🚀 Application-Level Optimizations

### 1. Caching Strategy
- **Dashboard queries**: 2-minute cache TTL
- **List queries**: 5-minute cache TTL
- **Background refresh**: When cache is 80% expired

### 2. Query Patterns
- **Dashboard**: Use `fetchMaintenanceReportsForDashboard()` with limit=10
- **Lists**: Use `fetchMaintenanceReports()` with pagination
- **Counts**: Use `fetchMaintenanceReportCounts()` for statistics

### 3. Admin Filtering Optimization
- Cache admin supervisor IDs for 5 minutes
- Use `inFilter` for multiple supervisor IDs
- Apply most selective filters first

## 🚀 Monitoring and Maintenance

### 1. Performance Monitoring
```dart
// Check performance metrics
final metrics = PerformanceMonitoringService().getAllMetrics();
final maintenanceMetric = metrics['MaintenanceReportRepository:fetchMaintenanceReports'];
print('Average duration: ${maintenanceMetric.averageDuration.inMilliseconds}ms');
```

### 2. Cache Hit Rates
```dart
// Monitor cache performance
final cacheMetrics = PerformanceMonitoringService().getCacheMetrics();
final maintenanceCache = cacheMetrics['MaintenanceReportRepository'];
print('Cache hit rate: ${(maintenanceCache.hitRate * 100).toStringAsFixed(1)}%');
```

### 3. Database Query Analysis
```sql
-- Analyze query performance
EXPLAIN ANALYZE 
SELECT id, supervisor_id, school_name, status, created_at, supervisors!inner(username)
FROM maintenance_reports 
WHERE supervisor_id = 'some-id' 
ORDER BY created_at DESC 
LIMIT 20;
```

## 🚀 Expected Performance Improvements

### After Index Creation
- **Supervisor filtering**: 90% faster
- **Status filtering**: 85% faster
- **Ordering**: 80% faster
- **Overall query**: 70-80% faster

### After Query Optimization
- **Selective columns**: 30% less data transfer
- **Proper pagination**: 90% less data for dashboard
- **Optimized joins**: 20% faster joins

### After Caching
- **Cache hits**: Instant response (<50ms)
- **Background refresh**: No user waiting
- **Overall UX**: Much more responsive

## 🚀 Implementation Steps

1. **Create database indexes** (highest impact)
2. **Deploy optimized queries** (already implemented)
3. **Monitor performance metrics**
4. **Adjust cache TTL based on usage patterns**
5. **Consider database connection pooling**

## 🚀 Verification

After implementing these optimizations, you should see:
- Query time reduced from 631ms to under 300ms
- Cache hit rates above 70%
- Dashboard loading in under 200ms
- Better user experience with instant responses

## 🚀 Additional Recommendations

1. **Database Connection Pooling**: Use connection pooling to reduce connection overhead
2. **Query Result Caching**: Consider Redis for distributed caching
3. **Database Partitioning**: If data grows large, consider partitioning by date
4. **Read Replicas**: For high-traffic scenarios, use read replicas
5. **Query Optimization**: Regularly analyze slow queries and optimize them 