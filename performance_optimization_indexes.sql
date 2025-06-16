-- PERFORMANCE OPTIMIZATION INDEXES (FIXED VERSION)
-- Run these in your Supabase SQL Editor to dramatically improve report fetching speed

-- 1. Main performance index for reports (HIGHEST IMPACT)
CREATE INDEX IF NOT EXISTS idx_reports_performance 
ON reports(supervisor_id, created_at DESC, status, type);

-- 2. Index for filtering by status
CREATE INDEX IF NOT EXISTS idx_reports_status_created 
ON reports(status, created_at DESC);

-- 3. Index for filtering by type  
CREATE INDEX IF NOT EXISTS idx_reports_type_created 
ON reports(type, created_at DESC);

-- 4. Index for supervisor joins
CREATE INDEX IF NOT EXISTS idx_reports_supervisor_id 
ON reports(supervisor_id);

-- 5. Composite index for complex filters
CREATE INDEX IF NOT EXISTS idx_reports_composite 
ON reports(supervisor_id, status, type, created_at DESC);

-- Check if indexes were created successfully
SELECT 
    indexname, 
    tablename, 
    indexdef 
FROM pg_indexes 
WHERE tablename = 'reports' 
ORDER BY indexname;
