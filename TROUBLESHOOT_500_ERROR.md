# Troubleshoot 500 Error - Admin Creation

## 🔍 **Current Issue**
Getting `{"error":"An unexpected error occurred"}` when creating admin with payload:
```json
{"name":"Ashraf","email":"ashraf@gmail.com","password":"12345678","role":"admin"}
```

## 🚀 **Quick Fix Steps**

### Step 1: Redeploy the Function
```bash
supabase functions deploy create-admin-user
```

### Step 2: Check Function Logs
```bash
# Watch logs in real-time
supabase functions logs create-admin-user --follow

# Or check recent logs
supabase functions logs create-admin-user -n 50
```

### Step 3: Test Admin Creation
1. Login as super admin
2. Go to super admin dashboard 
3. Try creating the admin again
4. Watch the logs for detailed error messages

## 🔧 **What Was Fixed**

1. **✅ Fixed Supabase Client Initialization**:
   - Was: `Deno.env.get('https://cftjaukrygtzguqcafon.supabase.co')`
   - Now: `'https://cftjaukrygtzguqcafon.supabase.co'`

2. **✅ Added Detailed Error Logging**:
   - Function now logs exact error details
   - Easier to identify the root cause

3. **✅ Improved Error Response**:
   - Returns error details in development
   - Better debugging information

## 🐛 **Common Causes of 500 Error**

### 1. **Database Schema Issues**
- Make sure `admins` table has `role` column
- Check if RLS policies allow the operation

### 2. **Authentication Issues**  
- Verify super admin role in database
- Check if current user has proper permissions

### 3. **Service Role Key Issues**
- Ensure service role key is correct
- Verify it has admin privileges

### 4. **Email Validation Issues**
- Check if email format is valid
- Verify email doesn't already exist

## 🔍 **Debug Commands**

```bash
# Check if function is deployed
supabase functions list

# See function status
supabase functions inspect create-admin-user

# Check database connection
supabase db inspect

# View project settings
supabase projects list
```

## 📋 **Verify Database Setup**

Check your `admins` table structure:
```sql
-- Run this in Supabase SQL Editor
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'admins';
```

Expected columns:
- `id` (uuid, primary key)
- `name` (text)
- `email` (text)
- `auth_user_id` (uuid)
- `role` (text) ← **Make sure this exists!**
- `created_at` (timestamp)
- `updated_at` (timestamp)

## 🎯 **Next Steps**

1. **Redeploy** the function with fixes
2. **Check logs** for specific error details  
3. **Verify database** schema is correct
4. **Test again** and share the detailed error from logs

The logs will show the exact error message that's causing the 500 response! 📝 