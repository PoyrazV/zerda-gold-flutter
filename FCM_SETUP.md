# Firebase Cloud Messaging (FCM) Setup Guide

This guide explains how to set up Firebase Cloud Messaging for the ZerdaGold app to enable push notifications when the app is closed or in background.

## Prerequisites

1. A Firebase project
2. Flutter SDK installed
3. Node.js and npm installed

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project" or select existing project
3. Enter project name: `zerdagold` (or your preferred name)
4. Enable Google Analytics (optional)
5. Create the project

## Step 2: Add Android App to Firebase

1. In Firebase Console, click "Add app" → Android
2. Enter Android package name: `com.zerdagold.app`
3. Enter app nickname: `ZerdaGold Android`
4. Enter SHA-1 certificate (for production, get from your keystore)
5. Download `google-services.json`
6. Replace the placeholder file at `android/app/google-services.json`

## Step 3: Add iOS App to Firebase

1. In Firebase Console, click "Add app" → iOS
2. Enter iOS bundle ID: `com.zerdagold.app.testProject`
3. Enter app nickname: `ZerdaGold iOS`
4. Download `GoogleService-Info.plist`
5. Replace the placeholder file at `ios/Runner/GoogleService-Info.plist`
6. In Xcode, add `GoogleService-Info.plist` to the Runner target

## Step 4: Configure Firebase Admin SDK (Server)

1. In Firebase Console, go to Project Settings → Service Accounts
2. Click "Generate new private key"
3. Download the JSON file
4. Rename it to `firebase-service-account.json`
5. Place it in the `admin-panel` folder
6. **Important**: Add `firebase-service-account.json` to `.gitignore`

```bash
# In admin-panel folder
echo "firebase-service-account.json" >> .gitignore
```

## Step 5: Test FCM Integration

### Test with Real Device

1. **Start the admin panel server:**
   ```bash
   cd admin-panel
   node server.js
   ```

2. **Run the Flutter app on a real device:**
   ```bash
   flutter run --release
   ```
   > Note: FCM requires a real device, not an emulator

3. **Check FCM token registration:**
   - Watch console logs for: `🔥 FCM Token: [token]`
   - Check server logs for: `🔥 FCM token registered for customer...`

4. **Send test notification:**
   - Open admin panel: http://localhost:3009
   - Login with credentials
   - Go to Notifications section
   - Send a notification
   - Check server logs for: `🔥 FCM sent successfully`

### Test Different App States

1. **Foreground (app open):**
   - App should show both local notification and in-app notification

2. **Background (app minimized):**
   - Android notification tray should show the notification
   - Tapping notification should open the app

3. **Terminated (app closed):**
   - Android notification tray should show the notification
   - Tapping notification should launch the app

## Current Implementation Status

✅ **Completed:**
- Firebase dependencies added to pubspec.yaml
- Android FCM configuration
- iOS FCM configuration (basic)
- NotificationService FCM integration
- FCM token registration endpoint
- Admin panel FCM notification sending
- Database migration for FCM tokens

⚠️ **Requires Manual Setup:**
- Real Firebase project creation
- Downloading actual config files
- Adding service account key
- iOS Xcode project configuration

🧪 **Testing Required:**
- FCM notifications in all app states
- Token refresh handling
- Multi-device support

## Notification Flow

1. **App starts** → Firebase Core initializes
2. **NotificationService initializes** → Requests FCM permissions
3. **FCM token received** → Registers with server
4. **Admin sends notification** → Server uses FCM Admin SDK
5. **FCM delivers notification** → Device shows notification
6. **User taps notification** → App opens with notification data

## Troubleshooting

### Common Issues:

1. **"FCM permission denied"**
   - Check notification permissions in device settings
   - Ensure app has POST_NOTIFICATIONS permission

2. **"Firebase service account not found"**
   - Download service account JSON from Firebase Console
   - Place in admin-panel folder as `firebase-service-account.json`

3. **"No FCM tokens found"**
   - Ensure app successfully registered FCM token
   - Check database `fcm_tokens` table

4. **Notifications not showing**
   - Test on real device (not emulator)
   - Check Android notification settings
   - Verify Firebase project configuration

### Debug Commands:

```bash
# Check FCM tokens in database
cd admin-panel
sqlite3 zerda_admin.db "SELECT * FROM fcm_tokens;"

# Test notification manually
curl -X POST http://localhost:3009/api/mobile/register-fcm-token \
  -H "Content-Type: application/json" \
  -d '{"customerId":"112e0e89-1c16-485d-acda-d0a21a24bb95","fcmToken":"test-token"}'
```

## Security Notes

- Never commit `firebase-service-account.json` to version control
- Use environment variables for production deployment
- Implement proper authentication for admin panel
- Regularly rotate service account keys

## Next Steps

1. Create real Firebase project
2. Download and configure real config files
3. Test on physical devices
4. Set up production environment variables
5. Implement advanced FCM features (topics, conditional sending)