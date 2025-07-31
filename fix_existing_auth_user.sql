-- Fix script for supervisor: 9270ca9d-fe9a-4c5f-8a1b-cfc0077fb5a4
-- This handles the case where auth user already exists but isn't linked

-- Step 1: Add the auth_user_id column to supervisors table
ALTER TABLE supervisors 
ADD COLUMN IF NOT EXISTS auth_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL;

-- Add an index for better performance
CREATE INDEX IF NOT EXISTS idx_supervisors_auth_user_id ON supervisors(auth_user_id);

-- Step 2: Check the specific supervisor first
SELECT id, username, email, auth_user_id 
FROM supervisors 
WHERE id = '9270ca9d-fe9a-4c5f-8a1b-cfc0077fb5a4';

-- Step 3: Find existing auth user for this supervisor's email
SELECT id, email, created_at 
FROM auth.users 
WHERE email = 'mostafaazab3024@gmail.com';

-- Step 4: Link the existing auth user to the supervisor
DO $$
DECLARE
  supervisor_record RECORD;
  auth_user_record RECORD;
BEGIN
  -- Get supervisor details
  SELECT id, email, username INTO supervisor_record
  FROM supervisors 
  WHERE id = '9270ca9d-fe9a-4c5f-8a1b-cfc0077fb5a4';
  
  IF supervisor_record IS NULL THEN
    RAISE EXCEPTION 'Supervisor not found with ID: 9270ca9d-fe9a-4c5f-8a1b-cfc0077fb5a4';
  END IF;
  
  -- Get existing auth user
  SELECT id, email INTO auth_user_record
  FROM auth.users 
  WHERE email = supervisor_record.email;
  
  IF auth_user_record IS NULL THEN
    RAISE EXCEPTION 'Auth user not found for email: %', supervisor_record.email;
  END IF;
  
  -- Update supervisor with existing auth_user_id
  UPDATE supervisors 
  SET auth_user_id = auth_user_record.id 
  WHERE id = '9270ca9d-fe9a-4c5f-8a1b-cfc0077fb5a4';
  
  RAISE NOTICE '✅ Linked existing auth user for supervisor: % (%) with auth_user_id: %', 
    supervisor_record.username, 
    supervisor_record.email,
    auth_user_record.id;
END $$;

-- Step 5: Verify the setup for this supervisor
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

-- Step 6: Show all supervisors for comparison
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