# FCM Notification Testing Guide

## Overview
This guide explains how to test Firebase Cloud Messaging (FCM) notifications in your Zerda Gold app across different app states.

## Prerequisites

1. **Admin Panel Running**
   ```bash
   cd admin-panel
   npm start
   ```
   Server should be running at http://localhost:3009

2. **Flutter App Running**
   ```bash
   flutter run
   ```
   Ensure the app is running on a device or emulator

3. **Firebase Configuration**
   - ✅ Firebase service account configured (`admin-panel/firebase-service-account.json`)
   - ✅ Firebase initialized in Flutter app
   - ✅ FCM token registered (happens automatically when app starts)

## Testing Notifications

### Method 1: Using Test Script

1. **Run the test script:**
   ```bash
   cd admin-panel
   node test-notification.js
   ```

2. **The script will:**
   - Login to admin panel
   - Send a test notification
   - Display the result

### Method 2: Using Admin Panel UI

1. Open http://localhost:3009 in browser
2. Login with credentials:
   - Username: `admin`
   - Password: `admin123`
3. Navigate to Customers → Select customer → Send Notification
4. Fill in notification details and send

### Method 3: Using cURL

```bash
# First, get auth token
curl -X POST http://localhost:3009/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'

# Then send notification (replace TOKEN with the token from login)
curl -X POST http://localhost:3009/api/customers/112e0e89-1c16-485d-acda-d0a21a24bb95/notifications \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer TOKEN" \
  -d '{
    "title": "Test Notification",
    "message": "This is a test message",
    "type": "info"
  }'
```

## Testing Different App States

### 1. Foreground (App Open)
- **State:** App is currently visible and active
- **Expected:** 
  - In-app notification banner appears
  - Notification is added to notification center
  - Console shows: `🔥 FCM foreground message: [title]`

### 2. Background (App Minimized)
- **State:** Press home button to minimize app
- **Expected:**
  - System notification appears in notification tray
  - Notification sound/vibration (if enabled)
  - Console shows: `🔥 Background message received: [title]`
  - When app reopens, background notifications are processed

### 3. Terminated (App Closed)
- **State:** Swipe app away from recent apps
- **Expected:**
  - System notification appears in notification tray
  - Tapping notification opens the app
  - Background handler saves notification to SharedPreferences
  - When app starts, saved notifications are retrieved and displayed

## Troubleshooting

### Notifications Not Received

1. **Check FCM Token Registration**
   - Open app and check console for: `🔥 FCM Token: [token]`
   - Verify token is saved in database:
     ```sql
     sqlite3 admin-panel/zerda_admin.db
     SELECT * FROM fcm_tokens;
     ```

2. **Check Firebase Configuration**
   - Ensure `google-services.json` is in `android/app/`
   - Verify Firebase project ID matches service account

3. **Check Network**
   - Device must have internet connection
   - For emulator, use `10.0.2.2:3009` instead of `localhost:3009`

4. **Check Permissions**
   - Android: Notification permission must be granted
   - Check Settings → Apps → Zerda Gold → Notifications

### Background Notifications Not Working

1. **Battery Optimization**
   - Disable battery optimization for the app
   - Settings → Battery → App launch → Zerda Gold → Manual management

2. **Background Restrictions**
   - Some devices (Xiaomi, Huawei) have aggressive background restrictions
   - Enable auto-start permission for the app

3. **Check Logs**
   ```bash
   # Android logs
   adb logcat | grep -i firebase
   
   # Flutter logs
   flutter logs
   ```

## Implementation Details

### What We Fixed

1. **Replaced deprecated `sendMulticast`** with individual `send()` calls
2. **Added comprehensive background handler** with local notification display
3. **Implemented background notification persistence** using SharedPreferences
4. **Added high priority settings** for reliable delivery
5. **Created notification channel** for Android 8.0+
6. **Added proper FCM permissions** in AndroidManifest.xml

### Key Files Modified

- `lib/services/notification_service.dart` - Enhanced background handler
- `admin-panel/server.js` - Fixed FCM implementation
- `android/app/src/main/AndroidManifest.xml` - Added FCM configuration

## Success Indicators

✅ FCM token generated and logged
✅ Notifications received in foreground
✅ Notifications received in background
✅ Notifications received when app is terminated
✅ Background notifications saved and retrieved on app start
✅ Local notifications displayed properly
✅ Console logs show notification processing

## Next Steps

1. Test on physical devices (more reliable than emulators)
2. Test with different notification types (info, warning, error, success)
3. Implement notification actions (buttons in notifications)
4. Add notification scheduling
5. Implement topic-based notifications for groups