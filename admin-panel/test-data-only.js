const admin = require('firebase-admin');
const sqlite3 = require('sqlite3').verbose();
const path = require('path');

// Initialize Firebase Admin
const serviceAccount = require('./firebase-service-account.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: serviceAccount.project_id
});

const dbPath = path.join(__dirname, 'zerda_admin.db');
const db = new sqlite3.Database(dbPath, sqlite3.OPEN_READONLY);

console.log('🧪 Data-Only FCM Notification Test');
console.log('===================================\n');

async function sendDataOnlyNotification() {
  const customerId = 'ffeee61a-8497-4c70-857e-c8f0efb13a2a';
  
  // Get guest tokens (for testing)
  db.all(
    `SELECT fcm_token, user_email, is_authenticated 
     FROM fcm_tokens 
     WHERE customer_id = ? AND (is_authenticated = 0 OR user_id IS NULL)`,
    [customerId],
    async (err, tokens) => {
      if (err) {
        console.error('Database error:', err);
        db.close();
        return;
      }
      
      console.log(`📱 Found ${tokens.length} guest token(s)\n`);
      
      if (tokens.length === 0) {
        console.log('❌ No guest tokens found!');
        console.log('   Make sure the app is running.');
        db.close();
        process.exit(1);
      }
      
      for (const tokenData of tokens) {
        console.log(`Testing data-only notification for: ${tokenData.user_email || 'Guest'}`);
        console.log(`Token: ${tokenData.fcm_token.substring(0, 40)}...`);
        
        // Data-only message - NO notification field
        const message = {
          // NO notification field - prevents Firebase auto-display
          data: {
            title: '🧪 Data-Only Test',
            body: 'This should appear only once! No duplicates.',
            type: 'info',
            timestamp: new Date().toISOString(),
            test: 'true',
            dataOnly: 'true'
          },
          android: {
            priority: 'high'
          },
          token: tokenData.fcm_token
        };
        
        console.log('\n📤 Sending data-only message (no notification field)...');
        
        try {
          const response = await admin.messaging().send(message);
          console.log('✅ Data-only notification sent successfully!');
          console.log('   Message ID:', response);
          console.log('\n✨ You should see only ONE notification!');
          console.log('   No duplicate from Firebase auto-display.');
        } catch (error) {
          console.log('❌ Failed to send notification:');
          console.log('   Error:', error.message);
        }
      }
      
      console.log('\n📊 Test Complete!');
      console.log('Check the app - you should see only ONE notification.');
      
      db.close();
      process.exit(0);
    }
  );
}

sendDataOnlyNotification();