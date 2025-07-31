-- Step 1: Add the auth_user_id column to supervisors table
ALTER TABLE supervisors 
ADD COLUMN IF NOT EXISTS auth_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL;

-- Add an index for better performance
CREATE INDEX IF NOT EXISTS idx_supervisors_auth_user_id ON supervisors(auth_user_id);

-- Step 2: Check existing supervisors
SELECT id, username, email, auth_user_id 
FROM supervisors 
ORDER BY created_at DESC;

-- Step 3: Create auth users for supervisors (run this for each supervisor)
-- Replace 'supervisor-email@example.com' with the actual email
-- Replace 'supervisor-password' with a secure password
-- Replace 'supervisor-uuid-here' with the actual supervisor UUID from step 2

-- Example for one supervisor:
-- INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at)
-- VALUES (
--   gen_random_uuid(),
--   'supervisor-email@example.com',
--   crypt('supervisor-password', gen_salt('bf')),
--   now(),
--   now(),
--   now()
-- );

-- Step 4: Update supervisor with auth_user_id (after creating auth user)
-- Replace 'auth-user-uuid' with the UUID from the auth.users table
-- Replace 'supervisor-uuid' with the supervisor UUID from step 2
-- UPDATE supervisors 
-- SET auth_user_id = 'auth-user-uuid' 
-- WHERE id = 'supervisor-uuid';

-- Step 5: Verify the setup
SELECT 
  s.id as supervisor_id,
  s.username,
  s.email,
  s.auth_user_id,
  au.email as auth_email
FROM supervisors s
LEFT JOIN auth.users au ON s.auth_user_id = au.id
ORDER BY s.created_at DESC; 