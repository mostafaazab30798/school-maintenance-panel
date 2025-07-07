-- Create schools table
CREATE TABLE IF NOT EXISTS schools (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    code VARCHAR(50) UNIQUE,
    address TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create supervisor_schools junction table for many-to-many relationship
CREATE TABLE IF NOT EXISTS supervisor_schools (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    supervisor_id UUID NOT NULL REFERENCES supervisors(id) ON DELETE CASCADE,
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(supervisor_id, school_id)
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_supervisor_schools_supervisor_id ON supervisor_schools(supervisor_id);
CREATE INDEX IF NOT EXISTS idx_supervisor_schools_school_id ON supervisor_schools(school_id);
CREATE INDEX IF NOT EXISTS idx_schools_name ON schools(name);
CREATE INDEX IF NOT EXISTS idx_schools_code ON schools(code);

-- Add RLS policies for schools table
ALTER TABLE schools ENABLE ROW LEVEL SECURITY;

-- Super admins can see all schools
CREATE POLICY "Super admins can view all schools" ON schools
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM admins 
            WHERE auth_user_id = auth.uid() 
            AND role = 'super_admin'
        )
    );

-- Admins can see schools assigned to their supervisors
CREATE POLICY "Admins can view schools assigned to their supervisors" ON schools
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM admins a
            JOIN supervisors s ON s.admin_id = a.id
            JOIN supervisor_schools ss ON ss.supervisor_id = s.id
            WHERE a.auth_user_id = auth.uid() 
            AND ss.school_id = schools.id
        )
    );

-- Supervisors can see their assigned schools
CREATE POLICY "Supervisors can view their assigned schools" ON schools
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM supervisors s
            JOIN admins a ON s.admin_id = a.id
            JOIN supervisor_schools ss ON ss.supervisor_id = s.id
            WHERE a.auth_user_id = auth.uid() 
            AND ss.school_id = schools.id
        )
    );

-- Super admins can manage schools
CREATE POLICY "Super admins can manage schools" ON schools
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM admins 
            WHERE auth_user_id = auth.uid() 
            AND role = 'super_admin'
        )
    );

-- Add RLS policies for supervisor_schools table
ALTER TABLE supervisor_schools ENABLE ROW LEVEL SECURITY;

-- Super admins can see all supervisor-school assignments
CREATE POLICY "Super admins can view all supervisor schools" ON supervisor_schools
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM admins 
            WHERE auth_user_id = auth.uid() 
            AND role = 'super_admin'
        )
    );

-- Admins can see assignments for their supervisors
CREATE POLICY "Admins can view their supervisors' school assignments" ON supervisor_schools
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM admins a
            JOIN supervisors s ON s.admin_id = a.id
            WHERE a.auth_user_id = auth.uid() 
            AND s.id = supervisor_schools.supervisor_id
        )
    );

-- Supervisors can see their own assignments
CREATE POLICY "Supervisors can view their school assignments" ON supervisor_schools
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM supervisors s
            JOIN admins a ON s.admin_id = a.id
            WHERE a.auth_user_id = auth.uid() 
            AND s.id = supervisor_schools.supervisor_id
        )
    );

-- Super admins can manage supervisor-school assignments
CREATE POLICY "Super admins can manage supervisor schools" ON supervisor_schools
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM admins 
            WHERE auth_user_id = auth.uid() 
            AND role = 'super_admin'
        )
    );

-- Add trigger to update schools updated_at timestamp
CREATE OR REPLACE FUNCTION update_schools_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER schools_updated_at_trigger
    BEFORE UPDATE ON schools
    FOR EACH ROW
    EXECUTE FUNCTION update_schools_updated_at(); 