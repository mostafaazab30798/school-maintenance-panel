-- Test script for single supervisor: 9270ca9d-fe9a-4c5f-8a1b-cfc0077fb5a4

-- Step 1: Add the auth_user_id column to supervisors table
ALTER TABLE supervisors 
ADD COLUMN IF NOT EXISTS auth_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL;

-- Add an index for better performance
CREATE INDEX IF NOT EXISTS idx_supervisors_auth_user_id ON supervisors(auth_user_id);

-- Step 2: Check the specific supervisor first
SELECT id, username, email, auth_user_id 
FROM supervisors 
WHERE id = '9270ca9d-fe9a-4c5f-8a1b-cfc0077fb5a4';

-- Step 3: Create auth user for this specific supervisor only
DO $$
DECLARE
  supervisor_record RECORD;
  auth_user_id UUID;
BEGIN
  -- Get supervisor details
  SELECT id, email, username INTO supervisor_record
  FROM supervisors 
  WHERE id = '9270ca9d-fe9a-4c5f-8a1b-cfc0077fb5a4';
  
  IF supervisor_record IS NULL THEN
    RAISE EXCEPTION 'Supervisor not found with ID: 9270ca9d-fe9a-4c5f-8a1b-cfc0077fb5a4';
  END IF;
  
  -- Create auth user
  INSERT INTO auth.users (
    id,
    email,
    encrypted_password,
    email_confirmed_at,
    created_at,
    updated_at
  ) VALUES (
    gen_random_uuid(),
    supervisor_record.email,
    crypt('default123', gen_salt('bf')),
    now(),
    now(),
    now()
  ) RETURNING id INTO auth_user_id;
  
  -- Update supervisor with auth_user_id
  UPDATE supervisors 
  SET auth_user_id = auth_user_id 
  WHERE id = '9270ca9d-fe9a-4c5f-8a1b-cfc0077fb5a4';
  
  RAISE NOTICE '✅ Created auth user for supervisor: % (%) with auth_user_id: %', 
    supervisor_record.username, 
    supervisor_record.email,
    auth_user_id;
END $$;

-- Step 4: Verify the setup for this supervisor
SELECT 
  s.id as supervisor_id,
  s.username,
  s.email,
  s.auth_user_id,
  au.email as auth_email,
  CASE 
    WHEN s.auth_user_id IS NOT NULL THEN '✅ Linked'
    ELSE '❌ Not linked'
  END as status
FROM supervisors s
LEFT JOIN auth.users au ON s.auth_user_id = au.id
WHERE s.id = '9270ca9d-fe9a-4c5f-8a1b-cfc0077fb5a4';

-- Step 5: Show all supervisors for comparison
SELECT 
  s.id as supervisor_id,
  s.username,
  s.email,
  s.auth_user_id,
  CASE 
    WHEN s.auth_user_id IS NOT NULL THEN '✅ Linked'
    ELSE '❌ Not linked'
  END as status
FROM supervisors s
ORDER BY s.created_at DESC; 