-- Comprehensive setup for maintenance_counts and damage_counts tables
-- Run this in your Supabase SQL Editor

-- 1. Create maintenance_counts table
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

-- 2. Create damage_counts table (if not exists)
CREATE TABLE IF NOT EXISTS damage_counts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id UUID NOT NULL REFERENCES schools(id),
    school_name TEXT NOT NULL,
    supervisor_id UUID NOT NULL REFERENCES auth.users(id),
    
    -- Status of the damage report
    status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'submitted')),
    
    -- JSONB columns for storing damage data
    item_counts JSONB DEFAULT '{}',
    damage_notes JSONB DEFAULT '{}',
    repair_status JSONB DEFAULT '{}',
    estimated_costs JSONB DEFAULT '{}',
    section_photos JSONB DEFAULT '{}',
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Unique constraint to prevent duplicate damage counts per school-supervisor combination
    UNIQUE(school_id, supervisor_id)
);

-- 3. Create indexes for maintenance_counts
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

-- 4. Create indexes for damage_counts
CREATE INDEX IF NOT EXISTS idx_damage_counts_supervisor ON damage_counts(supervisor_id);
CREATE INDEX IF NOT EXISTS idx_damage_counts_school ON damage_counts(school_id);
CREATE INDEX IF NOT EXISTS idx_damage_counts_status ON damage_counts(status);
CREATE INDEX IF NOT EXISTS idx_damage_counts_created_at ON damage_counts(created_at);

-- Create GIN index for JSONB columns for better query performance
CREATE INDEX IF NOT EXISTS idx_damage_counts_item_counts ON damage_counts USING GIN (item_counts);
CREATE INDEX IF NOT EXISTS idx_damage_counts_damage_notes ON damage_counts USING GIN (damage_notes);

-- 5. Insert sample maintenance count data
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

-- 6. Insert sample damage count data
INSERT INTO damage_counts (
    school_id,
    school_name,
    supervisor_id,
    item_counts,
    status
) VALUES (
    'school_001',
    'المدرسة الابتدائية الأولى', 
    (SELECT id FROM auth.users LIMIT 1),
    '{
        "co2_9kg": 0,
        "split_ac": 2,
        "joky_pump": 0,
        "low_boxes": 0,
        "window_ac": 1,
        "cabinet_ac": 2,
        "package_ac": 0,
        "water_sink": 1,
        "copper_cable": 0,
        "hidden_boxes": 0,
        "plastic_chair": 1,
        "upvc_50_meter": 1,
        "dry_powder_6kg": 0,
        "fire_pump_1750": 3,
        "upvc_pipes_4_5": 1,
        "fire_alarm_panel": 1,
        "circuit_breaker_250": 0,
        "circuit_breaker_400": 1,
        "booster_pump_3_phase": 1,
        "circuit_breaker_1250": 0,
        "fire_suppression_box": 0,
        "glass_fiber_tank_3000": 0,
        "glass_fiber_tank_4000": 0,
        "glass_fiber_tank_5000": 1,
        "pvc_pipe_connection_4": 0,
        "plastic_chair_external": 1,
        "elevator_pulley_machine": 0,
        "electric_water_heater_50l": 0,
        "electric_water_heater_100l": 0,
        "fluorescent_36w_sub_branch": 1,
        "fluorescent_48w_main_branch": 0,
        "electrical_distribution_unit": 1
    }'::jsonb,
    'submitted'
) ON CONFLICT DO NOTHING;

-- 7. Enable RLS on both tables
ALTER TABLE maintenance_counts ENABLE ROW LEVEL SECURITY;
ALTER TABLE damage_counts ENABLE ROW LEVEL SECURITY;

-- 8. RLS Policies for maintenance_counts
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

-- 9. RLS Policies for damage_counts
-- Policy for admins to see their assigned schools' damage counts
CREATE POLICY "Admins can view damage counts for their assigned schools"
    ON damage_counts FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM admin_supervisors 
            WHERE admin_supervisors.admin_id = auth.uid()
            AND admin_supervisors.supervisor_id = damage_counts.supervisor_id
        )
        OR 
        -- Super admins can see all
        EXISTS (
            SELECT 1 FROM admins
            WHERE admins.id = auth.uid()
            AND admins.role = 'super_admin'
        )
    );

-- Policy for supervisors to manage their schools' damage counts
CREATE POLICY "Supervisors can manage their schools' damage counts"
    ON damage_counts FOR ALL
    USING (supervisor_id = auth.uid())
    WITH CHECK (supervisor_id = auth.uid());

-- Policy for admins to insert damage counts for their assigned schools
CREATE POLICY "Admins can insert damage counts for assigned schools"
    ON damage_counts FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM admin_supervisors 
            WHERE admin_supervisors.admin_id = auth.uid()
            AND admin_supervisors.supervisor_id = damage_counts.supervisor_id
        )
        OR 
        -- Super admins can insert for anyone
        EXISTS (
            SELECT 1 FROM admins
            WHERE admins.id = auth.uid()
            AND admins.role = 'super_admin'
        )
    );

-- 10. Verify the setup
SELECT 'Tables created successfully' as status;
SELECT COUNT(*) as maintenance_counts_count FROM maintenance_counts;
SELECT COUNT(*) as damage_counts_count FROM damage_counts; 