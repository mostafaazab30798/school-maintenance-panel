-- Remove Analytics Database Objects
-- This script removes all database objects created for the analytics system

-- Drop RPC functions (if they exist)
DROP FUNCTION IF EXISTS get_daily_supervisor_performance(text, text, text, text);
DROP FUNCTION IF EXISTS get_admin_performance_summary();

-- Drop materialized views (if they exist)
DROP MATERIALIZED VIEW IF EXISTS v_daily_supervisor_performance CASCADE;

-- Drop regular views (if they exist)
DROP VIEW IF EXISTS v_admin_performance_summary CASCADE;

-- Drop any analytics-specific indexes (if they were created)
-- Note: These were likely created as part of performance_optimization_indexes.sql
-- We'll keep the performance indexes as they benefit the overall system

-- Drop any analytics-specific tables (if any were created)
-- Note: No specific analytics tables were created, we used existing tables

-- Print confirmation
SELECT 'Analytics database objects removed successfully' as status; 