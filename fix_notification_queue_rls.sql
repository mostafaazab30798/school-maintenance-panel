-- Fix notification_queue Table RLS Issues
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

-- 2. Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_notification_queue_user_id ON notification_queue(user_id);
CREATE INDEX IF NOT EXISTS idx_notification_queue_processed ON notification_queue(processed);
CREATE INDEX IF NOT EXISTS idx_notification_queue_created_at ON notification_queue(created_at);

-- 3. Enable RLS on notification_queue
ALTER TABLE notification_queue ENABLE ROW LEVEL SECURITY;

-- 4. Drop any existing problematic policies
DROP POLICY IF EXISTS "Allow admins to manage notification queue" ON notification_queue;
DROP POLICY IF EXISTS "Allow supervisors to view own notifications" ON notification_queue;

-- 5. Create proper RLS policies using our helper functions

-- Allow admins to insert/update notifications for their supervisors
CREATE POLICY "Admins can manage notification queue for assigned supervisors" ON notification_queue
FOR ALL USING (
  user_id IN (
    SELECT s.id FROM supervisors s
    WHERE s.admin_id = get_admin_id_for_user(auth.uid())
  )
  OR is_super_admin_user(auth.uid())
);

-- Allow system/service role to manage all notifications (for Edge Functions)
CREATE POLICY "Service role can manage all notifications" ON notification_queue
FOR ALL TO service_role
USING (true);

-- Allow authenticated users to view their own notifications
CREATE POLICY "Users can view own notifications" ON notification_queue
FOR SELECT USING (user_id = auth.uid());

-- 6. Create user_fcm_tokens table if it doesn't exist
CREATE TABLE IF NOT EXISTS user_fcm_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  fcm_token TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, fcm_token)
);

-- 7. Create indexes for user_fcm_tokens
CREATE INDEX IF NOT EXISTS idx_user_fcm_tokens_user_id ON user_fcm_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_user_fcm_tokens_token ON user_fcm_tokens(fcm_token);

-- 8. Enable RLS on user_fcm_tokens
ALTER TABLE user_fcm_tokens ENABLE ROW LEVEL SECURITY;

-- 9. RLS policies for user_fcm_tokens

-- Drop existing policies
DROP POLICY IF EXISTS "Users can manage own FCM tokens" ON user_fcm_tokens;

-- Allow users to manage their own FCM tokens
CREATE POLICY "Users can manage own FCM tokens" ON user_fcm_tokens
FOR ALL USING (user_id = auth.uid());

-- Allow service role to manage all FCM tokens (for Edge Functions)
CREATE POLICY "Service role can manage all FCM tokens" ON user_fcm_tokens
FOR ALL TO service_role
USING (true);

-- Allow admins to view FCM tokens of their assigned supervisors
CREATE POLICY "Admins can view FCM tokens of assigned supervisors" ON user_fcm_tokens
FOR SELECT USING (
  user_id IN (
    SELECT s.id FROM supervisors s
    WHERE s.admin_id = get_admin_id_for_user(auth.uid())
  )
  OR is_super_admin_user(auth.uid())
);

-- 10. Grant permissions
GRANT ALL ON notification_queue TO authenticated;
GRANT ALL ON user_fcm_tokens TO authenticated;

-- 11. Create function to clean up old notifications
CREATE OR REPLACE FUNCTION cleanup_old_notifications()
RETURNS void AS $$
BEGIN
  DELETE FROM notification_queue 
  WHERE created_at < NOW() - INTERVAL '30 days' 
  AND processed = true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 12. Verify tables were created successfully
SELECT 
  'notification_queue' as table_name,
  EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_name = 'notification_queue'
  ) as exists,
  (
    SELECT rowsecurity 
    FROM pg_tables 
    WHERE tablename = 'notification_queue'
  ) as rls_enabled
UNION ALL
SELECT 
  'user_fcm_tokens' as table_name,
  EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_name = 'user_fcm_tokens'
  ) as exists,
  (
    SELECT rowsecurity 
    FROM pg_tables 
    WHERE tablename = 'user_fcm_tokens'
  ) as rls_enabled;

-- 13. Show success message
SELECT 'Notification queue and FCM tokens tables created with proper RLS policies!' as status; 