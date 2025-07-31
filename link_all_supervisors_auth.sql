-- Comprehensive script to link ALL supervisors to auth users
-- This handles both existing auth users and creates new ones as needed

-- Step 1: Add the auth_user_id column to supervisors table
ALTER TABLE supervisors 
ADD COLUMN IF NOT EXISTS auth_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL;

-- Add an index for better performance
CREATE INDEX IF NOT EXISTS idx_supervisors_auth_user_id ON supervisors(auth_user_id);

-- Step 2: Check current status of all supervisors
SELECT 
  s.id as supervisor_id,
  s.username,
  s.email,
  s.auth_user_id,
  CASE 
    WHEN s.auth_user_id IS NOT NULL THEN '✅ Already Linked'
    WHEN au.id IS NOT NULL THEN '🔄 Has Auth User (Not Linked)'
    ELSE '❌ No Auth User'
  END as status
FROM supervisors s
LEFT JOIN auth.users au ON s.email = au.email
ORDER BY s.created_at DESC;

-- Step 3: Create a function to handle supervisor auth user linking
CREATE OR REPLACE FUNCTION link_supervisor_to_auth_user(supervisor_email TEXT)
RETURNS UUID AS $$
DECLARE
  auth_user_id UUID;
  supervisor_record RECORD;
BEGIN
  -- Get supervisor details
  SELECT id, email, username INTO supervisor_record
  FROM supervisors 
  WHERE email = supervisor_email;
  
  IF supervisor_record IS NULL THEN
    RAISE EXCEPTION 'Supervisor not found with email: %', supervisor_email;
  END IF;
  
  -- Check if auth user already exists
  SELECT id INTO auth_user_id
  FROM auth.users 
  WHERE email = supervisor_email;
  
  -- If auth user doesn't exist, create one
  IF auth_user_id IS NULL THEN
    INSERT INTO auth.users (
      id,
      email,
      encrypted_password,
      email_confirmed_at,
      created_at,
      updated_at
    ) VALUES (
      gen_random_uuid(),
      supervisor_email,
      crypt('default123', gen_salt('bf')),
      now(),
      now(),
      now()
    ) RETURNING id INTO auth_user_id;
    
    RAISE NOTICE '✅ Created NEW auth user for supervisor: % (%) with auth_user_id: %', 
      supervisor_record.username, 
      supervisor_record.email,
      auth_user_id;
  ELSE
    RAISE NOTICE '✅ Linked EXISTING auth user for supervisor: % (%) with auth_user_id: %', 
      supervisor_record.username, 
      supervisor_record.email,
      auth_user_id;
  END IF;
  
  -- Update supervisor with auth_user_id
  UPDATE supervisors 
  SET auth_user_id = auth_user_id 
  WHERE email = supervisor_email;
  
  RETURN auth_user_id;
END;
$$ LANGUAGE plpgsql;

-- Step 4: Process all supervisors
DO $$
DECLARE
  supervisor_record RECORD;
  auth_user_id UUID;
BEGIN
  FOR supervisor_record IN 
    SELECT id, email, username 
    FROM supervisors 
    WHERE auth_user_id IS NULL
  LOOP
    -- Link supervisor to auth user (create if needed)
    SELECT link_supervisor_to_auth_user(supervisor_record.email) INTO auth_user_id;
  END LOOP;
  
  RAISE NOTICE '✅ Completed linking all supervisors to auth users';
END $$;

-- Step 5: Final verification - show all supervisors
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
ORDER BY s.created_at DESC;

-- Step 6: Summary statistics
SELECT 
  COUNT(*) as total_supervisors,
  COUNT(s.auth_user_id) as linked_supervisors,
  COUNT(*) - COUNT(s.auth_user_id) as unlinked_supervisors
FROM supervisors s; 