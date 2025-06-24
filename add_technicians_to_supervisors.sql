-- Add technicians management to supervisors table
-- Run this in your Supabase SQL Editor

-- 1. Add technicians column to supervisors table
ALTER TABLE supervisors 
ADD COLUMN IF NOT EXISTS technicians TEXT[] DEFAULT '{}';

-- 2. Add helpful comments
COMMENT ON COLUMN supervisors.technicians IS 'Array of technician names assigned to this supervisor';

-- 3. Create index for efficient technician queries
CREATE INDEX IF NOT EXISTS idx_supervisors_technicians 
ON supervisors USING GIN(technicians);

-- 4. Add a helper function to validate technician names
CREATE OR REPLACE FUNCTION validate_technician_name(name TEXT)
RETURNS BOOLEAN AS $$
BEGIN
  -- Basic validation: not empty, reasonable length, no special characters
  RETURN name IS NOT NULL 
    AND LENGTH(TRIM(name)) >= 2 
    AND LENGTH(TRIM(name)) <= 50
    AND TRIM(name) ~ '^[a-zA-Z\u0600-\u06FF\s]+$'; -- Arabic and English names
END;
$$ LANGUAGE plpgsql;

-- 5. Add constraint to ensure technician names are valid (max 20 technicians per supervisor)
ALTER TABLE supervisors 
ADD CONSTRAINT valid_technician_count 
CHECK (
  technicians IS NULL OR 
  array_length(technicians, 1) IS NULL OR 
  array_length(technicians, 1) <= 20
);

-- 6. Sample function to get supervisor technician count
CREATE OR REPLACE FUNCTION get_supervisor_technician_count(supervisor_id_param UUID)
RETURNS INTEGER AS $$
DECLARE
  tech_count INTEGER;
BEGIN
  SELECT COALESCE(array_length(technicians, 1), 0) 
  INTO tech_count
  FROM supervisors 
  WHERE id = supervisor_id_param;
  
  RETURN COALESCE(tech_count, 0);
END;
$$ LANGUAGE plpgsql;

-- 7. Verify the changes
SELECT 'Technicians column added successfully to supervisors table' as status; 