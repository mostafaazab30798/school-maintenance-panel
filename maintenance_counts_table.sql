-- Create maintenance_counts table for tracking maintenance equipment counts
CREATE TABLE IF NOT EXISTS maintenance_counts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id UUID NOT NULL REFERENCES schools(id),
    school_name TEXT NOT NULL,
    supervisor_id UUID NOT NULL REFERENCES auth.users(id),
    
    -- Status of the maintenance count
    status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'submitted')),
    
    -- JSONB columns for storing maintenance data
    item_counts JSONB DEFAULT '{}',
    text_answers JSONB DEFAULT '{}',
    yes_no_answers JSONB DEFAULT '{}',
    yes_no_with_counts JSONB DEFAULT '{}',
    survey_answers JSONB DEFAULT '{}',
    maintenance_notes JSONB DEFAULT '{}',
    fire_safety_alarm_panel_data JSONB DEFAULT '{}',
    fire_safety_condition_only_data JSONB DEFAULT '{}',
    fire_safety_expiry_dates JSONB DEFAULT '{}',
    section_photos JSONB DEFAULT '{}',
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Unique constraint to prevent duplicate maintenance counts per school-supervisor combination
    UNIQUE(school_id, supervisor_id)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_maintenance_counts_supervisor ON maintenance_counts(supervisor_id);
CREATE INDEX IF NOT EXISTS idx_maintenance_counts_school ON maintenance_counts(school_id);
CREATE INDEX IF NOT EXISTS idx_maintenance_counts_status ON maintenance_counts(status);
CREATE INDEX IF NOT EXISTS idx_maintenance_counts_created_at ON maintenance_counts(created_at);

-- Create GIN indexes for JSONB columns for better query performance
CREATE INDEX IF NOT EXISTS idx_maintenance_counts_item_counts ON maintenance_counts USING GIN (item_counts);
CREATE INDEX IF NOT EXISTS idx_maintenance_counts_text_answers ON maintenance_counts USING GIN (text_answers);
CREATE INDEX IF NOT EXISTS idx_maintenance_counts_yes_no_answers ON maintenance_counts USING GIN (yes_no_answers);
CREATE INDEX IF NOT EXISTS idx_maintenance_counts_survey_answers ON maintenance_counts USING GIN (survey_answers);
CREATE INDEX IF NOT EXISTS idx_maintenance_counts_maintenance_notes ON maintenance_counts USING GIN (maintenance_notes);

-- Sample data for testing
INSERT INTO maintenance_counts (
    school_id,
    school_name,
    supervisor_id,
    item_counts,
    text_answers,
    yes_no_answers,
    survey_answers,
    status
) VALUES (
    'school_001',
    'المدرسة الابتدائية الأولى',
    (SELECT id FROM auth.users LIMIT 1),
    '{
        "fire_boxes": 8,
        "fire_extinguishers": 15,
        "diesel_pump": 1,
        "electric_pump": 2,
        "auxiliary_pump": 1,
        "water_pumps": 3,
        "electrical_panels": 5
    }'::jsonb,
    '{
        "water_meter_number": "WM-001-2024",
        "electricity_meter_number": "EM-001-2024"
    }'::jsonb,
    '{
        "wall_cracks": false,
        "roof_leaks": true,
        "concrete_damage": false,
        "elevator_working": true,
        "water_system_working": true
    }'::jsonb,
    '{
        "fire_alarm_system_condition": "جيد",
        "fire_boxes_condition": "يحتاج صيانة",
        "diesel_pump_condition": "جيد",
        "electric_pump_condition": "جيد",
        "water_pumps_condition": "يحتاج صيانة",
        "electrical_panels_condition": "جيد"
    }'::jsonb,
    'submitted'
) ON CONFLICT DO NOTHING;

-- RLS (Row Level Security) policies
ALTER TABLE maintenance_counts ENABLE ROW LEVEL SECURITY;

-- Policy for admins to see their assigned schools' maintenance counts
CREATE POLICY "Admins can view maintenance counts for their assigned schools"
    ON maintenance_counts FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM admin_supervisors 
            WHERE admin_supervisors.admin_id = auth.uid()
            AND admin_supervisors.supervisor_id = maintenance_counts.supervisor_id
        )
        OR 
        -- Super admins can see all
        EXISTS (
            SELECT 1 FROM admins
            WHERE admins.id = auth.uid()
            AND admins.role = 'super_admin'
        )
    );

-- Policy for supervisors to manage their schools' maintenance counts
CREATE POLICY "Supervisors can manage their schools' maintenance counts"
    ON maintenance_counts FOR ALL
    USING (supervisor_id = auth.uid())
    WITH CHECK (supervisor_id = auth.uid());

-- Policy for admins to insert maintenance counts for their assigned schools
CREATE POLICY "Admins can insert maintenance counts for assigned schools"
    ON maintenance_counts FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM admin_supervisors 
            WHERE admin_supervisors.admin_id = auth.uid()
            AND admin_supervisors.supervisor_id = maintenance_counts.supervisor_id
        )
        OR 
        -- Super admins can insert for anyone
        EXISTS (
            SELECT 1 FROM admins
            WHERE admins.id = auth.uid()
            AND admins.role = 'super_admin'
        )
    ); 