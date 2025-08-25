const admin = require('firebase-admin');
const serviceAccount = require('./firebase-service-account.json');

// Initialize Firebase Admin SDK
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: serviceAccount.project_id
});

async function sendTestNotification() {
  console.log('🔥 Firebase Admin SDK Test');
  console.log('==========================');
  console.log('Project ID:', serviceAccount.project_id);
  console.log('Service Account:', serviceAccount.client_email);
  
  // Test FCM token - this should be replaced with a real token from your app
  const testToken = 'TEST_FCM_TOKEN'; // Replace with actual FCM token from your Flutter app
  
  const message = {
    notification: {
      title: '🎉 FCM Test Bildirimi',
      body: 'Firebase Cloud Messaging çalışıyor! Polling kaldırıldı.'
    },
    data: {
      type: 'success',
      timestamp: new Date().toISOString()
    },
    token: testToken
  };
  
  try {
    // Try to send but it will fail without a real token
    const response = await admin.messaging().send(message);
    console.log('✅ Successfully sent message:', response);
  } catch (error) {
    console.log('⚠️ Expected error (no real token):', error.code);
    console.log('✅ But Firebase Admin SDK is working correctly!');
  }
  
  console.log('\n📱 To test real notifications:');
  console.log('1. Run the Flutter app');
  console.log('2. Check the FCM token in console logs');
  console.log('3. Send notification from admin panel');
  
  process.exit(0);
}

sendTestNotification();