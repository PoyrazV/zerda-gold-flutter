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

console.log('🧪 Authenticated User Data-Only Test');
console.log('=====================================\n');

async function sendAuthDataOnlyNotification() {
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
      
      console.log(`📱 Found ${tokens.length} authenticated token(s)\n`);
      
      if (tokens.length === 0) {
        console.log('❌ No authenticated tokens found!');
        console.log('   Please login in the app first.');
        db.close();
        process.exit(1);
      }
      
      for (const tokenData of tokens) {
        console.log(`Testing for: ${tokenData.user_email}`);
        console.log(`Token: ${tokenData.fcm_token.substring(0, 40)}...`);
        
        // Data-only message for authenticated users
        const message = {
          // NO notification field - prevents Firebase auto-display
          data: {
            title: '🔐 Authenticated User Test',
            body: `Hello ${tokenData.user_email}! This is a data-only notification. No duplicates!`,
            type: 'success',
            timestamp: new Date().toISOString(),
            test: 'true',
            dataOnly: 'true',
            authenticated: 'true'
          },
          android: {
            priority: 'high'
          },
          token: tokenData.fcm_token
        };
        
        console.log('\n📤 Sending authenticated data-only message...');
        
        try {
          const response = await admin.messaging().send(message);
          console.log('✅ Authenticated notification sent successfully!');
          console.log('   Message ID:', response);
          console.log('\n✨ Check results:');
          console.log('   - You should see only ONE notification');
          console.log('   - It should show your email in the message');
          console.log('   - No duplicate from Firebase');
        } catch (error) {
          console.log('❌ Failed to send notification:');
          console.log('   Error:', error.message);
        }
      }
      
      db.close();
      process.exit(0);
    }
  );
}

sendAuthDataOnlyNotification();