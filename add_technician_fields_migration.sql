-- Migration: Add technician fields (workId, profession) to supervisors table
-- Date: 2024
-- Description: Enhance technician data structure to include workId and profession

-- Add new column to store detailed technician information
ALTER TABLE supervisors 
ADD COLUMN IF NOT EXISTS technicians_detailed JSONB DEFAULT '[]'::jsonb;

-- Create index for better performance on technician queries
CREATE INDEX IF NOT EXISTS idx_supervisors_technicians_detailed 
ON supervisors USING GIN (technicians_detailed);

-- Add comment to document the new column structure
COMMENT ON COLUMN supervisors.technicians_detailed IS 
'JSON array storing technician details with structure: [{"name": "string", "workId": "string", "profession": "string"}]';

-- Example of the expected JSON structure:
-- technicians_detailed: [
--   {"name": "Ahmed Ali", "workId": "T001", "profession": "Electrician"},
--   {"name": "Mohammed Hassan", "workId": "T002", "profession": "Plumber"}
-- ]

-- Migration script to convert existing technicians array to detailed format
-- This will preserve existing data while adding empty workId and profession fields
UPDATE supervisors 
SET technicians_detailed = (
  SELECT jsonb_agg(
    jsonb_build_object(
      'name', technician_name,
      'workId', '',
      'profession', ''
    )
  )
  FROM jsonb_array_elements_text(
    CASE 
      WHEN technicians IS NULL THEN '[]'::jsonb
      ELSE technicians
    END
  ) AS technician_name
)
WHERE technicians IS NOT NULL AND jsonb_array_length(COALESCE(technicians, '[]'::jsonb)) > 0
AND (technicians_detailed IS NULL OR technicians_detailed = '[]'::jsonb);

-- Update RLS policies to include the new column (if RLS is enabled)
-- Note: This assumes existing RLS policies cover the technicians_detailed column
-- If specific policies are needed, they should be added here

-- Add validation constraint to ensure proper JSON structure
ALTER TABLE supervisors 
ADD CONSTRAINT technicians_detailed_structure_check 
CHECK (
  technicians_detailed IS NULL OR 
  (
    jsonb_typeof(technicians_detailed) = 'array' AND
    (
      jsonb_array_length(technicians_detailed) = 0 OR
      (
        SELECT bool_and(
          jsonb_typeof(tech) = 'object' AND
          tech ? 'name' AND
          tech ? 'workId' AND 
          tech ? 'profession' AND
          jsonb_typeof(tech->'name') = 'string' AND
          jsonb_typeof(tech->'workId') = 'string' AND
          jsonb_typeof(tech->'profession') = 'string'
        )
        FROM jsonb_array_elements(technicians_detailed) AS tech
      )
    )
  )
);

-- Create a function to help with technician management
CREATE OR REPLACE FUNCTION update_supervisor_technicians_detailed(
  supervisor_id_param UUID,
  technicians_data JSONB
) RETURNS BOOLEAN AS $$
BEGIN
  -- Validate input structure
  IF NOT (
    jsonb_typeof(technicians_data) = 'array' AND
    (
      jsonb_array_length(technicians_data) = 0 OR
      (
        SELECT bool_and(
          jsonb_typeof(tech) = 'object' AND
          tech ? 'name' AND
          tech ? 'workId' AND 
          tech ? 'profession'
        )
        FROM jsonb_array_elements(technicians_data) AS tech
      )
    )
  ) THEN
    RAISE EXCEPTION 'Invalid technicians data structure';
  END IF;

  -- Update the supervisor's technicians
  UPDATE supervisors 
  SET 
    technicians_detailed = technicians_data,
    updated_at = NOW()
  WHERE id = supervisor_id_param;

  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION update_supervisor_technicians_detailed(UUID, JSONB) TO authenticated;

-- Success message
DO $$ 
BEGIN 
  RAISE NOTICE 'Technician fields migration completed successfully!';
  RAISE NOTICE 'New column: technicians_detailed (JSONB)';
  RAISE NOTICE 'Structure: [{"name": "string", "workId": "string", "profession": "string"}]';
END $$; 