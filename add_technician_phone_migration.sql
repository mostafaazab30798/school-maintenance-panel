-- Migration: Add phoneNumber field to technician structure
-- Date: 2024
-- Description: Update technician data structure to include phoneNumber field

-- Update the comment to include phoneNumber field
COMMENT ON COLUMN supervisors.technicians_detailed IS 
'JSON array storing technician details with structure: [{"name": "string", "workId": "string", "profession": "string", "phoneNumber": "string"}]';

-- Update validation constraint to include phoneNumber field
ALTER TABLE supervisors 
DROP CONSTRAINT IF EXISTS technicians_detailed_structure_check;

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
          jsonb_typeof(tech->'profession') = 'string' AND
          -- phoneNumber is optional, so we only check type if it exists
          (NOT (tech ? 'phoneNumber') OR jsonb_typeof(tech->'phoneNumber') = 'string')
        )
        FROM jsonb_array_elements(technicians_detailed) AS tech
      )
    )
  )
);

-- Update existing technician data to include empty phoneNumber field
UPDATE supervisors 
SET technicians_detailed = (
  SELECT jsonb_agg(
    tech || jsonb_build_object('phoneNumber', '')
  )
  FROM jsonb_array_elements(technicians_detailed) AS tech
)
WHERE technicians_detailed IS NOT NULL 
  AND jsonb_array_length(technicians_detailed) > 0
  AND NOT EXISTS (
    SELECT 1 
    FROM jsonb_array_elements(technicians_detailed) AS tech 
    WHERE tech ? 'phoneNumber'
  );

-- Update the helper function to support phoneNumber
CREATE OR REPLACE FUNCTION update_supervisor_technicians_detailed(
  supervisor_id_param UUID,
  technicians_data JSONB
) RETURNS BOOLEAN AS $$
BEGIN
  -- Validate input structure (phoneNumber is optional)
  IF NOT (
    jsonb_typeof(technicians_data) = 'array' AND
    (
      jsonb_array_length(technicians_data) = 0 OR
      (
        SELECT bool_and(
          jsonb_typeof(tech) = 'object' AND
          tech ? 'name' AND
          tech ? 'workId' AND 
          tech ? 'profession' AND
          -- phoneNumber is optional
          (NOT (tech ? 'phoneNumber') OR jsonb_typeof(tech->'phoneNumber') = 'string')
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

-- Success message
DO $$ 
BEGIN 
  RAISE NOTICE 'Technician phoneNumber field migration completed successfully!';
  RAISE NOTICE 'Updated structure: [{"name": "string", "workId": "string", "profession": "string", "phoneNumber": "string"}]';
  RAISE NOTICE 'phoneNumber field is optional and defaults to empty string';
END $$; 