# 🚨 URGENT: Fix Firebase Permission Error

## **Current Error**
```
❌ Token 1: Failed - Permission denied on resource project school-maintenance-admin-panel
CONSUMER_INVALID - FCM API not accessible
```

## 🔍 **Root Cause Analysis**

The `CONSUMER_INVALID` error means one of these issues:

1. **FCM API not enabled** for your project
2. **Wrong Firebase project ID** 
3. **Firebase project doesn't exist**
4. **Service account has no permissions**

## 🚀 **IMMEDIATE FIX - Choose Option A or B**

### **Option A: Verify & Fix Firebase Project** ⭐ (Recommended)

#### **Step 1: Check Your Firebase Project**
1. Go to: https://console.firebase.google.com/
2. **Look for a project named**: `school-maintenance-admin-panel`
3. **If it doesn't exist**: Create it with this EXACT name
4. **If it exists**: Click on it and note the project ID

#### **Step 2: Enable FCM API**
1. **Go to Google Cloud Console**: https://console.cloud.google.com/
2. **Select your project**: `school-maintenance-admin-panel`
3. **Go to APIs & Services** → **Library**
4. **Search for**: `Firebase Cloud Messaging API`
5. **Click ENABLE** (wait 2-3 minutes)

#### **Step 3: Get Firebase Admin SDK Key**
1. **Firebase Console** → **Project Settings** → **Service Accounts**
2. **Click "Generate new private key"**
3. **Download the JSON file**
4. **Copy ALL the JSON content**

#### **Step 4: Update Supabase Environment Variables**
1. **Supabase Dashboard** → **Settings** → **Edge Functions** → **Environment Variables**
2. **Update these variables**:

**FIREBASE_SERVICE_ACCOUNT**: (Paste the entire JSON)
**FIREBASE_PROJECT_ID**: (Your actual project ID from Firebase Console)

### **Option B: Use Different Project ID** 🔄

Your project might have a different ID. Let's check:

#### **Step 1: Find Your Real Firebase Project**
1. **Go to**: https://console.firebase.google.com/
2. **Click on your project**
3. **Go to Project Settings** 
4. **Copy the "Project ID"** (might be different from display name)

#### **Step 2: Update Supabase Environment Variables**
Set `FIREBASE_PROJECT_ID` to your REAL project ID from Step 1.

## 🧪 **Test the Fix**

After updating:

1. **Create a new report** in your app
2. **Check console logs** - you should now see:
   ```
   🔍 Debug Info:
     Firebase Project ID: your-real-project-id
     Has Service Account: true
     Access Token Length: 1000+
   ✅ Token 1: Delivered successfully
   ```

## 🔍 **Debug Current Configuration**

**Test what's currently configured**:

1. Create a report and check debug logs for:
   ```
   🔍 Debug Info:
     Firebase Project ID: ???
     Has Service Account: true/false
     Access Token Length: ???
   ```

2. This tells us exactly what's wrong.

## 🚨 **Common Specific Fixes**

### **Issue: Project ID Mismatch**
- **Symptom**: Debug shows different project ID
- **Fix**: Update `FIREBASE_PROJECT_ID` in Supabase to match Firebase Console

### **Issue: No Service Account**
- **Symptom**: `Has Service Account: false`
- **Fix**: Add the Firebase Admin SDK JSON to `FIREBASE_SERVICE_ACCOUNT`

### **Issue: Invalid Service Account**
- **Symptom**: `Access Token Length: 0`
- **Fix**: Regenerate Firebase Admin SDK key and update Supabase

### **Issue: API Not Enabled**
- **Symptom**: Still getting `CONSUMER_INVALID` after fixes
- **Fix**: Enable FCM API in Google Cloud Console + wait 5 minutes

## 📱 **Alternative: Use Supabase Realtime Instead**

If Firebase continues to fail, we can switch to Supabase Realtime:

```dart
// In your supervisor app, listen for new reports
Supabase.instance.client
  .from('reports')
  .stream(primaryKey: ['id'])
  .eq('supervisor_id', currentUserId)
  .listen((data) {
    // Show local notification
    showLocalNotification('New Report', 'You have a new report');
  });
```

## 🎯 **Quick Test Commands**

```bash
# Check Firebase projects
curl "https://firebase.googleapis.com/v1beta1/projects" \
  -H "Authorization: Bearer $(gcloud auth print-access-token)"

# Test FCM API directly
curl -X POST "https://fcm.googleapis.com/v1/projects/YOUR_PROJECT_ID/messages:send" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

## 📞 **Next Steps**

1. **Follow Option A** (most likely to work)
2. **Test with a new report**
3. **Check debug logs** for configuration info
4. **If still failing**: Try Option B or switch to Supabase Realtime

---

**Fix the Firebase project configuration and FCM will work! 🔥📱** 