-- Admin Management System Database Setup
-- Run this in your Supabase SQL Editor

-- 1. Create admins table
CREATE TABLE IF NOT EXISTS admins (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  auth_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'admin' CHECK (role IN ('admin', 'super_admin')),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 2. Add admin_id column to supervisors table (if not exists)
ALTER TABLE supervisors 
ADD COLUMN IF NOT EXISTS admin_id UUID REFERENCES admins(id) ON DELETE SET NULL;

-- 3. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_supervisors_admin_id ON supervisors(admin_id);
CREATE INDEX IF NOT EXISTS idx_admins_auth_user_id ON admins(auth_user_id);
CREATE INDEX IF NOT EXISTS idx_admins_email ON admins(email);
CREATE INDEX IF NOT EXISTS idx_admins_role ON admins(role);

-- 4. Enable Row Level Security (RLS)
ALTER TABLE admins ENABLE ROW LEVEL SECURITY;
ALTER TABLE supervisors ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE maintenance_reports ENABLE ROW LEVEL SECURITY;

-- 5. RLS Policies for Admins table
-- Admins can only see their own record
CREATE POLICY "Admins can view own record" ON admins
  FOR SELECT USING (auth_user_id = auth.uid());

CREATE POLICY "Admins can update own record" ON admins
  FOR UPDATE USING (auth_user_id = auth.uid());

-- Super admins can see all records (optional - for super admin role)
CREATE POLICY "Super admins can view all admins" ON admins
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM admins 
      WHERE auth_user_id = auth.uid() 
      AND role = 'super_admin'
    )
  );

-- 6. RLS Policies for Supervisors table
-- Admins can only see their assigned supervisors
CREATE POLICY "Admins can view assigned supervisors" ON supervisors
  FOR SELECT USING (
    admin_id IN (
      SELECT id FROM admins 
      WHERE auth_user_id = auth.uid()
    )
    OR
    EXISTS (
      SELECT 1 FROM admins 
      WHERE auth_user_id = auth.uid() 
      AND role = 'super_admin'
    )
  );

CREATE POLICY "Admins can update assigned supervisors" ON supervisors
  FOR UPDATE USING (
    admin_id IN (
      SELECT id FROM admins 
      WHERE auth_user_id = auth.uid()
    )
    OR
    EXISTS (
      SELECT 1 FROM admins 
      WHERE auth_user_id = auth.uid() 
      AND role = 'super_admin'
    )
  );

CREATE POLICY "Admins can insert supervisors" ON supervisors
  FOR INSERT WITH CHECK (
    admin_id IN (
      SELECT id FROM admins 
      WHERE auth_user_id = auth.uid()
    )
    OR
    EXISTS (
      SELECT 1 FROM admins 
      WHERE auth_user_id = auth.uid() 
      AND role = 'super_admin'
    )
  );

-- 7. RLS Policies for Reports table
-- Admins can see reports of their supervisors
CREATE POLICY "Admins can view reports of assigned supervisors" ON reports
  FOR SELECT USING (
    supervisor_id IN (
      SELECT s.id FROM supervisors s
      INNER JOIN admins a ON s.admin_id = a.id
      WHERE a.auth_user_id = auth.uid()
    )
    OR
    EXISTS (
      SELECT 1 FROM admins 
      WHERE auth_user_id = auth.uid() 
      AND role = 'super_admin'
    )
  );

CREATE POLICY "Admins can insert reports for assigned supervisors" ON reports
  FOR INSERT WITH CHECK (
    supervisor_id IN (
      SELECT s.id FROM supervisors s
      INNER JOIN admins a ON s.admin_id = a.id
      WHERE a.auth_user_id = auth.uid()
    )
    OR
    EXISTS (
      SELECT 1 FROM admins 
      WHERE auth_user_id = auth.uid() 
      AND role = 'super_admin'
    )
  );

CREATE POLICY "Admins can update reports of assigned supervisors" ON reports
  FOR UPDATE USING (
    supervisor_id IN (
      SELECT s.id FROM supervisors s
      INNER JOIN admins a ON s.admin_id = a.id
      WHERE a.auth_user_id = auth.uid()
    )
    OR
    EXISTS (
      SELECT 1 FROM admins 
      WHERE auth_user_id = auth.uid() 
      AND role = 'super_admin'
    )
  );

-- 8. RLS Policies for Maintenance Reports table
-- Similar policies for maintenance reports
CREATE POLICY "Admins can view maintenance reports of assigned supervisors" ON maintenance_reports
  FOR SELECT USING (
    supervisor_id IN (
      SELECT s.id FROM supervisors s
      INNER JOIN admins a ON s.admin_id = a.id
      WHERE a.auth_user_id = auth.uid()
    )
    OR
    EXISTS (
      SELECT 1 FROM admins 
      WHERE auth_user_id = auth.uid() 
      AND role = 'super_admin'
    )
  );

CREATE POLICY "Admins can insert maintenance reports for assigned supervisors" ON maintenance_reports
  FOR INSERT WITH CHECK (
    supervisor_id IN (
      SELECT s.id FROM supervisors s
      INNER JOIN admins a ON s.admin_id = a.id
      WHERE a.auth_user_id = auth.uid()
    )
    OR
    EXISTS (
      SELECT 1 FROM admins 
      WHERE auth_user_id = auth.uid() 
      AND role = 'super_admin'
    )
  );

CREATE POLICY "Admins can update maintenance reports of assigned supervisors" ON maintenance_reports
  FOR UPDATE USING (
    supervisor_id IN (
      SELECT s.id FROM supervisors s
      INNER JOIN admins a ON s.admin_id = a.id
      WHERE a.auth_user_id = auth.uid()
    )
    OR
    EXISTS (
      SELECT 1 FROM admins 
      WHERE auth_user_id = auth.uid() 
      AND role = 'super_admin'
    )
  );

-- 9. Create function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 10. Create trigger for admins table
CREATE TRIGGER update_admins_updated_at 
  BEFORE UPDATE ON admins 
  FOR EACH ROW 
  EXECUTE FUNCTION update_updated_at_column();

-- 11. Sample data insertion function (for testing)
CREATE OR REPLACE FUNCTION create_sample_admin(
  admin_name TEXT,
  admin_email TEXT,
  admin_auth_user_id UUID
) RETURNS UUID AS $$
DECLARE
  admin_id UUID;
BEGIN
  INSERT INTO admins (name, email, auth_user_id)
  VALUES (admin_name, admin_email, admin_auth_user_id)
  RETURNING id INTO admin_id;
  
  RETURN admin_id;
END;
$$ LANGUAGE plpgsql;

-- 12. Function to assign supervisor to admin
CREATE OR REPLACE FUNCTION assign_supervisor_to_admin(
  supervisor_id_param UUID,
  admin_id_param UUID
) RETURNS BOOLEAN AS $$
BEGIN
  UPDATE supervisors 
  SET admin_id = admin_id_param 
  WHERE id = supervisor_id_param;
  
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

-- 13. Function to get admin statistics
CREATE OR REPLACE FUNCTION get_admin_stats(admin_id_param UUID)
RETURNS JSON AS $$
DECLARE
  supervisor_count INTEGER;
  report_count INTEGER;
  maintenance_count INTEGER;
  result JSON;
BEGIN
  -- Count supervisors
  SELECT COUNT(*) INTO supervisor_count
  FROM supervisors 
  WHERE admin_id = admin_id_param;
  
  -- Count reports
  SELECT COUNT(*) INTO report_count
  FROM reports r
  INNER JOIN supervisors s ON r.supervisor_id = s.id
  WHERE s.admin_id = admin_id_param;
  
  -- Count maintenance reports
  SELECT COUNT(*) INTO maintenance_count
  FROM maintenance_reports mr
  INNER JOIN supervisors s ON mr.supervisor_id = s.id
  WHERE s.admin_id = admin_id_param;
  
  result := json_build_object(
    'supervisors', supervisor_count,
    'reports', report_count,
    'maintenance', maintenance_count
  );
  
  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- 14. Helper function to get admin by auth_user_id
CREATE OR REPLACE FUNCTION get_admin_by_auth_id(auth_id UUID)
RETURNS TABLE(id UUID, name TEXT, email TEXT, role TEXT) AS $$
BEGIN
  RETURN QUERY
  SELECT a.id, a.name, a.email, a.role
  FROM admins a
  WHERE a.auth_user_id = auth_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 15. Helper function to check if user is super admin
CREATE OR REPLACE FUNCTION is_super_admin(auth_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS(
    SELECT 1 FROM admins
    WHERE auth_user_id = auth_id AND role = 'super_admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 16. Grant permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON admins TO authenticated;
GRANT EXECUTE ON FUNCTION get_admin_by_auth_id(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION is_super_admin(UUID) TO authenticated;

-- 17. Migration: Add report_source column to reports table
-- Add the new report_source column with constraint to limit values to the specified options
ALTER TABLE reports 
ADD COLUMN IF NOT EXISTS report_source TEXT CHECK (report_source IN ('unifier', 'check_list', 'consultant')) DEFAULT 'unifier';

-- Create index for better performance when filtering by report source
CREATE INDEX IF NOT EXISTS idx_reports_report_source ON reports(report_source);

-- Add comment to document the column
COMMENT ON COLUMN reports.report_source IS 'Source of the report: unifier, check_list, or consultant'; 