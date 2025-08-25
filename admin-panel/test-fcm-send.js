const sqlite3 = require('sqlite3').verbose();
const admin = require('firebase-admin');
const path = require('path');

const dbPath = path.join(__dirname, 'zerda_admin.db');
const db = new sqlite3.Database(dbPath, sqlite3.OPEN_READONLY);

// Initialize Firebase Admin
const serviceAccount = require('./firebase-service-account.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: serviceAccount.project_id
});

console.log('🧪 FCM Notification Test');
console.log('========================\n');

// Test function
async function testSendNotification() {
  const customerId = 'ffeee61a-8497-4c70-857e-c8f0efb13a2a';
  
  // Get authenticated tokens
  db.all(
    `SELECT fcm_token, user_email, is_authenticated 
     FROM fcm_tokens 
     WHERE customer_id = ? AND is_authenticated = 1 AND user_id IS NOT NULL`,
    [customerId],
    async (err, tokens) => {
      if (err) {
        console.error('Database error:', err);
        db.close();
        return;
      }
      
      console.log(`📱 Found ${tokens.length} authenticated token(s):\n`);
      
      if (tokens.length === 0) {
        console.log('❌ No authenticated tokens found!');
        console.log('   Make sure you are logged in the app.');
        db.close();
        process.exit(1);
      }
      
      for (const tokenData of tokens) {
        console.log(`Testing token for: ${tokenData.user_email}`);
        console.log(`Token: ${tokenData.fcm_token.substring(0, 40)}...`);
        console.log(`Authenticated: ${tokenData.is_authenticated ? 'YES' : 'NO'}\n`);
        
        const message = {
          notification: {
            title: '🧪 Test: Authenticated User Notification',
            body: `This is a test notification for ${tokenData.user_email}. You should receive this because you are logged in.`
          },
          data: {
            type: 'info',
            timestamp: new Date().toISOString(),
            test: 'true'
          },
          android: {
            priority: 'high',
            notification: {
              channelId: 'zerda_notifications',
              priority: 'high',
              defaultSound: true,
              defaultVibrateTimings: true,
            }
          },
          token: tokenData.fcm_token
        };
        
        try {
          const response = await admin.messaging().send(message);
          console.log('✅ Notification sent successfully!');
          console.log('   Message ID:', response);
          console.log('');
        } catch (error) {
          console.log('❌ Failed to send notification:');
          console.log('   Error:', error.message);
          if (error.code === 'messaging/invalid-registration-token' || 
              error.code === 'messaging/registration-token-not-registered') {
            console.log('   ⚠️  Token is invalid or expired. User needs to restart the app.');
          }
          console.log('');
        }
      }
      
      // Also test guest tokens
      console.log('\n📱 Checking guest tokens:\n');
      
      db.all(
        `SELECT fcm_token, user_email, is_authenticated 
         FROM fcm_tokens 
         WHERE customer_id = ? AND (is_authenticated = 0 OR user_id IS NULL)`,
        [customerId],
        (err, guestTokens) => {
          if (err) {
            console.error('Database error:', err);
            db.close();
            return;
          }
          
          console.log(`Found ${guestTokens.length} guest token(s)`);
          
          if (guestTokens.length > 0) {
            console.log('\n⚠️  Guest tokens exist. These will receive guest notifications.');
          }
          
          console.log('\n📊 Summary:');
          console.log(`- Authenticated tokens: ${tokens.length}`);
          console.log(`- Guest tokens: ${guestTokens.length}`);
          console.log('\nTest completed!');
          
          db.close();
          process.exit(0);
        }
      );
    }
  );
}

// Run test
testSendNotification();