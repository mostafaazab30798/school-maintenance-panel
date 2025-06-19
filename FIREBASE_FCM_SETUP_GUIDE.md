# 🔥 Firebase FCM Permission Fix Guide

## 🚨 **Current Error**
```
Permission denied on resource project school-maintenance-admin-panel
```

This means your Firebase service account doesn't have FCM permissions.

## 🚀 **Complete Solution**

### **Step 1: Enable FCM API**

1. **Go to Google Cloud Console**: https://console.cloud.google.com/apis/library/fcm.googleapis.com
2. **Select your project**: `school-maintenance-admin-panel`
3. **Click "ENABLE"** to enable Firebase Cloud Messaging API

### **Step 2: Create Service Account with FCM Permissions**

1. **Go to Google Cloud Console**: https://console.cloud.google.com/iam-admin/serviceaccounts
2. **Select your project**: `school-maintenance-admin-panel`
3. **Click "CREATE SERVICE ACCOUNT"**

**Service Account Details**:
- **Name**: `fcm-notification-service`
- **Description**: `Service account for sending FCM notifications`

### **Step 3: Assign FCM Permissions**

After creating the service account:

1. **Click on the service account** you just created
2. **Go to "PERMISSIONS" tab**
3. **Click "GRANT ACCESS"**
4. **Add these roles**:
   - `Firebase Cloud Messaging API Admin`
   - `Firebase Admin SDK Service Agent`
   - `Cloud Messaging Admin`

**OR** use the legacy role:
   - `Firebase Service Management Service Agent`

### **Step 4: Generate New Private Key**

1. **Go to "KEYS" tab**
2. **Click "ADD KEY" → "Create new key"**
3. **Choose "JSON" format**
4. **Download the JSON file**

### **Step 5: Update Supabase Environment Variables**

1. **Go to Supabase Dashboard** → **Settings** → **Edge Functions** → **Environment Variables**

2. **Update/Add these variables**:

**FIREBASE_SERVICE_ACCOUNT**:
```json
{
  "type": "service_account",
  "project_id": "school-maintenance-admin-panel",
  "private_key_id": "your-key-id",
  "private_key": "-----BEGIN PRIVATE KEY-----\nyour-private-key\n-----END PRIVATE KEY-----\n",
  "client_email": "fcm-notification-service@school-maintenance-admin-panel.iam.gserviceaccount.com",
  "client_id": "your-client-id",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/fcm-notification-service%40school-maintenance-admin-panel.iam.gserviceaccount.com"
}
```

**FIREBASE_PROJECT_ID**:
```
school-maintenance-admin-panel
```

### **Step 6: Alternative - Use Firebase Admin SDK**

If IAM roles don't work, try these specific permissions:

1. **Go to Firebase Console** → **Project Settings** → **Service Accounts**
2. **Click "Generate new private key"**
3. **Use this key** - it has built-in FCM permissions

### **Step 7: Verify Project Configuration**

Make sure your Firebase project:

1. **Has FCM enabled**: Firebase Console → Cloud Messaging
2. **Has the correct project ID**: Check project settings
3. **Supports your app**: Android/iOS app configured

## 🧪 **Test the Fix**

After updating the service account:

1. **Create a new report** in your app
2. **Check for this success message**:
   ```
   ✅ Token 1: Delivered successfully (messageId)
   ```

## 🔍 **Debug Commands**

### **Test FCM API Access**
```bash
npx supabase functions logs send_notification --follow
```

### **Test Direct API Call**
```bash
curl -X POST "https://cftjaukrygtzguqcafon.supabase.co/functions/v1/send_notification?debug" \
  -H "Authorization: Bearer YOUR_SUPABASE_ANON_KEY"
```

## 🚨 **Common Issues**

### **Issue: "Service account not found"**
- Make sure the JSON is valid
- Check project ID matches exactly
- Verify the service account exists

### **Issue: "API not enabled"**
- Enable FCM API in Google Cloud Console
- Wait 5-10 minutes for propagation

### **Issue: "Invalid credentials"**
- Regenerate the service account key
- Copy the entire JSON exactly
- Remove any extra whitespace/formatting

## 📊 **Expected Result**

After the fix:
```
NotificationService: Notification sent successfully
✅ Token 1: Delivered successfully (projects/school-maintenance-admin-panel/messages/abc123)
📱 Your phone receives the notification!
```

## 🔗 **Helpful Links**

- [Firebase Console](https://console.firebase.google.com/)
- [Google Cloud Console](https://console.cloud.google.com/)
- [FCM API Reference](https://firebase.google.com/docs/cloud-messaging/server)
- [Service Account Setup](https://firebase.google.com/docs/admin/setup#set-up-project-and-service-account)

---

**Follow these steps to fix the FCM permission issue and enable notifications! 🔥📱** 