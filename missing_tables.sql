-- Fix missing database schema for regular admin functionality
-- Run this in Supabase SQL Editor

-- 1. Add missing user_id column to admins table (maps to auth.users.id)
ALTER TABLE admins 
ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- Copy auth_user_id to user_id for existing records
UPDATE admins SET user_id = auth_user_id WHERE user_id IS NULL;

-- 2. Create admin_supervisors junction table
CREATE TABLE IF NOT EXISTS admin_supervisors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  supervisor_id UUID NOT NULL REFERENCES supervisors(id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(admin_id, supervisor_id)
);

-- 3. Migrate existing data from supervisors.admin_id to admin_supervisors table
INSERT INTO admin_supervisors (admin_id, supervisor_id)
SELECT a.user_id, s.id
FROM supervisors s
INNER JOIN admins a ON s.admin_id = a.id
WHERE a.user_id IS NOT NULL
ON CONFLICT (admin_id, supervisor_id) DO NOTHING;

-- 4. Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_admin_supervisors_admin_id ON admin_supervisors(admin_id);
CREATE INDEX IF NOT EXISTS idx_admin_supervisors_supervisor_id ON admin_supervisors(supervisor_id);
CREATE INDEX IF NOT EXISTS idx_admins_user_id ON admins(user_id);

-- 5. Enable RLS on admin_supervisors
ALTER TABLE admin_supervisors ENABLE ROW LEVEL SECURITY;

-- 6. RLS policies for admin_supervisors
CREATE POLICY "Admins can view own supervisor assignments" ON admin_supervisors
  FOR SELECT USING (admin_id = auth.uid());

CREATE POLICY "Super admins can view all supervisor assignments" ON admin_supervisors
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM admins 
      WHERE user_id = auth.uid() 
      AND role = 'super_admin'
    )
  );

-- Verify the fix
SELECT 'Schema fix completed successfully' as status; 