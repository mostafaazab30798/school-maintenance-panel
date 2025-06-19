# 📱 Notification Troubleshooting Guide

## ✅ **Current Status**
Your notification system is now working! The Edge Function is deployed and processing requests successfully.

## 🔧 **Recent Fixes Applied**
1. **FCM Payload Format**: Fixed data field type errors (all values now strings)
2. **Android Notification Structure**: Corrected invalid priority field
3. **Enhanced Debugging**: Added detailed success/failure logging

## 🧪 **Testing Notifications**

### **Step 1: Test App Notification**
1. **Create a new report** in your Flutter app
2. **Check debug console** for these logs:
   ```
   ✅ Token 1: Delivered successfully (messageId)
   ```

### **Step 2: Phone Setup Checklist**
Make sure your phone has:
- [ ] **App permissions**: Notifications enabled for your app
- [ ] **Do Not Disturb**: Disabled or app whitelisted
- [ ] **Background app refresh**: Enabled for your app
- [ ] **Battery optimization**: Disabled for your app
- [ ] **Internet connection**: WiFi or mobile data active

### **Step 3: FCM Token Verification**
Check if your FCM token is properly stored:

```dart
// Add this to your app for debugging
FirebaseMessaging.instance.getToken().then((token) {
  print('FCM Token: $token');
});
```

### **Step 4: Android Notification Channel**
Ensure notification channel is properly configured:

```dart
// In your main.dart or notification setup
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'reports_channel',
  'Reports Notifications',
  description: 'Notifications for new reports and maintenance requests',
  importance: Importance.high,
  playSound: true,
);

await flutterLocalNotificationsPlugin
    .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
    ?.createNotificationChannel(channel);
```

## 🚨 **Common Issues & Solutions**

### **Issue: "Sent 0/1 notifications"**
**Solution**: This was the FCM payload format issue - now fixed! ✅

### **Issue: Token not found**
```bash
# Check FCM tokens in Supabase
SELECT * FROM user_fcm_tokens WHERE user_id = 'your-supervisor-id';
```

### **Issue: App in background**
- Make sure your app can receive background notifications
- Check if FCM service is running

### **Issue: Firebase configuration**
1. **Verify Firebase project ID** in Edge Function environment variables
2. **Check service account JSON** is valid
3. **Ensure FCM is enabled** in Firebase Console

## 📱 **Testing with Firebase Console**

1. **Go to Firebase Console** → **Cloud Messaging**
2. **Click "Send your first message"**
3. **Enter**:
   - Title: "Test Notification"
   - Body: "Testing direct FCM"
   - Target: Your app's FCM token
4. **Send** and check if you receive it

## 🔍 **Debug Commands**

```bash
# Check Edge Function logs
npx supabase functions logs send_notification

# Test Edge Function directly
curl -X POST "https://cftjaukrygtzguqcafon.supabase.co/functions/v1/send_notification" \
  -H "Authorization: Bearer YOUR_SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "your-supervisor-id",
    "title": "Test Notification",
    "body": "Testing FCM delivery",
    "priority": "Emergency",
    "school_name": "Test School"
  }'
```

## 📊 **Expected Debug Output**

After the fix, you should see:
```
NotificationService: Notification sent successfully
✅ Token 1: Delivered successfully (projects/school-maintenance-admin-panel/messages/...)
NotificationService: Bulk notifications complete: 1/1 successful
```

## 🎯 **Next Steps**

1. **Test the notification** by creating a new report
2. **Check your phone** for the notification
3. **Verify debug logs** show successful delivery
4. **If still no notification**, check phone settings and FCM token

---

**The notification system is now properly configured and should deliver notifications to your phone! 📱✅** 