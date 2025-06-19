-- SIMPLE FIX for notification_queue RLS Issues
-- Run this in Supabase SQL Editor

-- 1. Create notification_queue table if it doesn't exist
CREATE TABLE IF NOT EXISTS notification_queue (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  notification_type TEXT NOT NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  data JSONB DEFAULT '{}'::jsonb,
  processed BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 2. Create user_fcm_tokens table if it doesn't exist
CREATE TABLE IF NOT EXISTS user_fcm_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  fcm_token TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, fcm_token)
);

-- 3. Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_notification_queue_user_id ON notification_queue(user_id);
CREATE INDEX IF NOT EXISTS idx_notification_queue_processed ON notification_queue(processed);
CREATE INDEX IF NOT EXISTS idx_user_fcm_tokens_user_id ON user_fcm_tokens(user_id);

-- 4. Enable RLS on both tables
ALTER TABLE notification_queue ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_fcm_tokens ENABLE ROW LEVEL SECURITY;

-- 5. Drop any existing policies to start fresh
DROP POLICY IF EXISTS "Allow admins to manage notification queue" ON notification_queue;
DROP POLICY IF EXISTS "Allow supervisors to view own notifications" ON notification_queue;
DROP POLICY IF EXISTS "Users can manage own FCM tokens" ON user_fcm_tokens;
DROP POLICY IF EXISTS "Service role can manage all notifications" ON notification_queue;
DROP POLICY IF EXISTS "Service role can manage all FCM tokens" ON user_fcm_tokens;

-- 6. Create SIMPLE RLS policies

-- notification_queue policies
CREATE POLICY "Allow authenticated users to manage notification queue" ON notification_queue
FOR ALL TO authenticated
USING (true);

CREATE POLICY "Allow service role to manage notification queue" ON notification_queue
FOR ALL TO service_role
USING (true);

-- user_fcm_tokens policies  
CREATE POLICY "Allow authenticated users to manage FCM tokens" ON user_fcm_tokens
FOR ALL TO authenticated
USING (true);

CREATE POLICY "Allow service role to manage FCM tokens" ON user_fcm_tokens
FOR ALL TO service_role
USING (true);

-- 7. Grant permissions
GRANT ALL ON notification_queue TO authenticated;
GRANT ALL ON user_fcm_tokens TO authenticated;
GRANT ALL ON notification_queue TO service_role;
GRANT ALL ON user_fcm_tokens TO service_role;

-- 8. Simple verification (without problematic column references)
SELECT 'notification_queue' as table_name, 
       EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'notification_queue') as created
UNION ALL
SELECT 'user_fcm_tokens' as table_name,
       EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_fcm_tokens') as created;

-- 9. Success message
SELECT 'Simple notification tables created successfully!' as status; 