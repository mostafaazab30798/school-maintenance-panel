-- Create damage_inventory table for separate damage tracking
CREATE TABLE IF NOT EXISTS damage_inventory (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id TEXT NOT NULL,
    school_name TEXT NOT NULL,
    supervisor_id UUID NOT NULL REFERENCES auth.users(id),
    
    -- Damage information
    damage_type TEXT NOT NULL, -- 'structural', 'electrical', 'mechanical', 'fire_safety'
    damage_severity TEXT NOT NULL, -- 'minor', 'major', 'critical'
    damage_description TEXT NOT NULL,
    damage_location TEXT, -- Specific location within the school
    repair_status TEXT DEFAULT 'pending', -- 'pending', 'in_progress', 'completed'
    estimated_cost DECIMAL(10,2),
    
    -- Photos and documentation
    damage_photos JSONB DEFAULT '[]',
    repair_photos JSONB DEFAULT '[]',
    
    -- Dates
    reported_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    repair_started_date TIMESTAMP WITH TIME ZONE,
    repair_completed_date TIMESTAMP WITH TIME ZONE,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_damage_inventory_supervisor ON damage_inventory(supervisor_id);
CREATE INDEX IF NOT EXISTS idx_damage_inventory_school ON damage_inventory(school_id);
CREATE INDEX IF NOT EXISTS idx_damage_inventory_type ON damage_inventory(damage_type);
CREATE INDEX IF NOT EXISTS idx_damage_inventory_severity ON damage_inventory(damage_severity);
CREATE INDEX IF NOT EXISTS idx_damage_inventory_status ON damage_inventory(repair_status);
CREATE INDEX IF NOT EXISTS idx_damage_inventory_reported_date ON damage_inventory(reported_date);

-- Sample data for testing
INSERT INTO damage_inventory (
    school_id,
    school_name,
    supervisor_id,
    damage_type,
    damage_severity,
    damage_description,
    damage_location,
    estimated_cost
) VALUES (
    'school_001',
    'المدرسة الابتدائية الأولى',
    (SELECT id FROM auth.users LIMIT 1), -- Use existing supervisor
    'electrical',
    'major',
    'تلف في اللوحة الكهربائية الرئيسية',
    'الطابق الأول - القاعة الرئيسية',
    5000.00
),
(
    'school_001',
    'المدرسة الابتدائية الأولى',
    (SELECT id FROM auth.users LIMIT 1),
    'structural',
    'minor',
    'تشقق في الجدار الخارجي',
    'الواجهة الشرقية',
    1500.00
); 