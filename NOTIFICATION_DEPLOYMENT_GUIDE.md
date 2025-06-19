# 🚨 Fix Notification "Failed to fetch" Error

## **Current Issue**
Your Flutter app is getting this error:
```
NotificationService: Exception sending notification: ClientException: Failed to fetch, uri=https://cftjaukrygtzguqcafon.supabase.co/functions/v1/send_notification
```

**Root Cause**: The `send_notification` Edge Function is NOT deployed to your Supabase project.

## 🚀 **Complete Solution**

### **Step 1: Authentication**
```bash
# Login to Supabase (this will open your browser)
npx supabase login
```

### **Step 2: Link Your Project**
```bash
# Link to your specific project
npx supabase link --project-ref cftjaukrygtzguqcafon
```

### **Step 3: Deploy the Edge Function**
```bash
# Deploy the notification function
npx supabase functions deploy send_notification
```

### **Step 4: Set Firebase Environment Variables**

1. **Go to Supabase Dashboard** → **Settings** → **Edge Functions** → **Environment Variables**

2. **Add these variables**:
   - `FIREBASE_SERVICE_ACCOUNT`: Your Firebase service account JSON (complete JSON as a string)
   - `FIREBASE_PROJECT_ID`: Your Firebase project ID (e.g., "school-maintenance-admin-panel")

3. **How to get Firebase Service Account**:
   - Go to Firebase Console → Project Settings → Service Accounts
   - Click "Generate new private key"
   - Copy the entire JSON content
   - Paste it as the value for `FIREBASE_SERVICE_ACCOUNT`

### **Step 5: Verify Deployment**
```bash
# Check if function is deployed
npx supabase functions list

# Test the function
curl -X POST "https://cftjaukrygtzguqcafon.supabase.co/functions/v1/send_notification?debug" \
  -H "Authorization: Bearer YOUR_SUPABASE_ANON_KEY"
```

## 🔧 **Alternative: Manual Deployment via Supabase Dashboard**

If CLI doesn't work:

1. **Go to Supabase Dashboard** → **Edge Functions**
2. **Click "New Function"**
3. **Name**: `send_notification`
4. **Copy the content** from `supabase/functions/send_notification/index.ts`
5. **Deploy**

## ✅ **Testing After Deployment**

1. **Run your Flutter app**
2. **Try creating a report** that triggers notifications
3. **Check the logs** - you should now see:
   ```
   NotificationService: Notification sent successfully
   ```

## 🚨 **If You Still Get Errors**

### **Function Not Found (404)**
```bash
# Redeploy the function
npx supabase functions deploy send_notification --verify-jwt false
```

### **Firebase Credentials Missing**
- Double-check the `FIREBASE_SERVICE_ACCOUNT` variable in Supabase Dashboard
- Make sure it's valid JSON (use a JSON validator)
- Ensure `FIREBASE_PROJECT_ID` matches your Firebase project

### **Permission Errors**
- Make sure your Supabase service role key has the correct permissions
- Check that FCM is enabled in your Firebase project

## 📋 **Quick Commands Reference**

```bash
# Install Supabase CLI locally
npm install supabase --save-dev

# Login
npx supabase login

# Link project
npx supabase link --project-ref cftjaukrygtzguqcafon

# Deploy function
npx supabase functions deploy send_notification

# Check logs
npx supabase functions logs send_notification

# List functions
npx supabase functions list
```

## 🎯 **Expected Result**

After successful deployment, your notification logs should show:
```
NotificationService: Sending notification to supervisor: d4f155f7-0455-4c6d-abd7-558e3a07b2aa
NotificationService: Notification type: emergency
NotificationService: Notification sent successfully
MultiReportRepository: Notifications complete: 1/1 successful
```

## 🔗 **Helpful Links**

- [Supabase Edge Functions Documentation](https://supabase.com/docs/guides/functions)
- [Firebase Cloud Messaging Setup](https://firebase.google.com/docs/cloud-messaging)
- [Supabase CLI Reference](https://supabase.com/docs/reference/cli)

---

**Once you complete these steps, your notification system will work correctly! 🎉** 