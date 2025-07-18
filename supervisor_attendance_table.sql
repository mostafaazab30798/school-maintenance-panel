-- Create supervisor attendance table
CREATE TABLE IF NOT EXISTS supervisor_attendance (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    supervisor_id UUID NOT NULL REFERENCES supervisors(id) ON DELETE CASCADE,
    photo_url TEXT NOT NULL,
    date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_supervisor_attendance_supervisor_id ON supervisor_attendance(supervisor_id);
CREATE INDEX IF NOT EXISTS idx_supervisor_attendance_date ON supervisor_attendance(date);

-- Enable Row Level Security (RLS)
ALTER TABLE supervisor_attendance ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
-- Policy for supervisors to view their own attendance
CREATE POLICY "Supervisors can view their own attendance" ON supervisor_attendance
    FOR SELECT USING (
        auth.uid() IN (
            SELECT auth_user_id FROM supervisors WHERE id = supervisor_id
        )
    );

-- Policy for admins to view attendance of their assigned supervisors
CREATE POLICY "Admins can view attendance of their supervisors" ON supervisor_attendance
    FOR SELECT USING (
        supervisor_id IN (
            SELECT s.id FROM supervisors s
            JOIN admins a ON s.admin_id = a.id
            WHERE a.auth_user_id = auth.uid()
        )
    );

-- Policy for super admins to view all attendance
CREATE POLICY "Super admins can view all attendance" ON supervisor_attendance
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM admins 
            WHERE auth_user_id = auth.uid() AND role = 'super_admin'
        )
    );

-- Policy for creating attendance records (supervisors can create their own)
CREATE POLICY "Supervisors can create their own attendance" ON supervisor_attendance
    FOR INSERT WITH CHECK (
        auth.uid() IN (
            SELECT auth_user_id FROM supervisors WHERE id = supervisor_id
        )
    );

-- Policy for updating attendance records (supervisors can update their own)
CREATE POLICY "Supervisors can update their own attendance" ON supervisor_attendance
    FOR UPDATE USING (
        auth.uid() IN (
            SELECT auth_user_id FROM supervisors WHERE id = supervisor_id
        )
    );

-- Policy for deleting attendance records (supervisors can delete their own)
CREATE POLICY "Supervisors can delete their own attendance" ON supervisor_attendance
    FOR DELETE USING (
        auth.uid() IN (
            SELECT auth_user_id FROM supervisors WHERE id = supervisor_id
        )
    );

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to automatically update updated_at
CREATE TRIGGER update_supervisor_attendance_updated_at 
    BEFORE UPDATE ON supervisor_attendance 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column(); 