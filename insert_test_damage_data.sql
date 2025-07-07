-- First, let's check if the table exists
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' AND table_name = 'damage_counts';

-- If table doesn't exist, create it first
CREATE TABLE IF NOT EXISTS damage_counts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id UUID NOT NULL REFERENCES schools(id),
    school_name TEXT NOT NULL,
    supervisor_id UUID NOT NULL REFERENCES auth.users(id),
    status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'submitted')),
    item_counts JSONB DEFAULT '{}',
    section_photos JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Check if we have schools in the database
DO $$
DECLARE
    school_uuid UUID;
    supervisor_uuid UUID;
BEGIN
    -- Get a school UUID (any existing school)
    SELECT id INTO school_uuid FROM schools LIMIT 1;
    
    -- Get the supervisor UUID
    supervisor_uuid := '737dc1b3-ace1-48ad-b9f5-d81d43789b7c'::UUID;
    
    -- Check if we found a school
    IF school_uuid IS NULL THEN
        -- If no schools exist, create one for testing
        INSERT INTO schools (id, name, address) 
        VALUES (uuid_generate_v4(), 'المدرسة الابتدائية الأولى', 'حي الملك فهد - الرياض')
        RETURNING id INTO school_uuid;
        
        RAISE NOTICE 'Created new school with UUID: %', school_uuid;
    ELSE
        RAISE NOTICE 'Using existing school with UUID: %', school_uuid;
    END IF;
    
    -- Insert or update damage count data
    INSERT INTO damage_counts (
        school_id,
        school_name,
        supervisor_id,
        item_counts,
        status
    ) VALUES (
        school_uuid,
        'المدرسة الابتدائية الأولى',
        supervisor_uuid,
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
    ) ON CONFLICT (school_id, supervisor_id) DO UPDATE SET
        item_counts = EXCLUDED.item_counts,
        status = EXCLUDED.status,
        updated_at = NOW();
        
    RAISE NOTICE 'Successfully inserted/updated damage count data';
    
END $$;

-- Verify the data was inserted
SELECT 
    school_id,
    school_name,
    supervisor_id,
    status,
    jsonb_pretty(item_counts),
    created_at
FROM damage_counts 
WHERE supervisor_id = '737dc1b3-ace1-48ad-b9f5-d81d43789b7c'::UUID; 