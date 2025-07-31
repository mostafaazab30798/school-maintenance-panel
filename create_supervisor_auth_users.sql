-- Step 1: Add the auth_user_id column to supervisors table
ALTER TABLE supervisors 
ADD COLUMN IF NOT EXISTS auth_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL;

-- Add an index for better performance
CREATE INDEX IF NOT EXISTS idx_supervisors_auth_user_id ON supervisors(auth_user_id);

-- Step 2: Create a function to create auth users for supervisors
CREATE OR REPLACE FUNCTION create_auth_user_for_supervisor(
  supervisor_email TEXT,
  supervisor_password TEXT DEFAULT 'default123'
)
RETURNS UUID AS $$
DECLARE
  auth_user_id UUID;
BEGIN
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
    supervisor_email,
    crypt(supervisor_password, gen_salt('bf')),
    now(),
    now(),
    now()
  ) RETURNING id INTO auth_user_id;
  
  -- Update supervisor with auth_user_id
  UPDATE supervisors 
  SET auth_user_id = auth_user_id 
  WHERE email = supervisor_email;
  
  RETURN auth_user_id;
END;
$$ LANGUAGE plpgsql;

-- Step 3: Create auth users for all supervisors who don't have one
-- This will create auth users for supervisors with default password 'default123'
-- You should change these passwords later through the password change functionality

DO $$
DECLARE
  supervisor_record RECORD;
BEGIN
  FOR supervisor_record IN 
    SELECT id, email, username 
    FROM supervisors 
    WHERE auth_user_id IS NULL
  LOOP
    -- Create auth user for this supervisor
    PERFORM create_auth_user_for_supervisor(supervisor_record.email, 'default123');
    
    RAISE NOTICE 'Created auth user for supervisor: % (%)', 
      supervisor_record.username, 
      supervisor_record.email;
  END LOOP;
END $$;

-- Step 4: Verify the setup
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