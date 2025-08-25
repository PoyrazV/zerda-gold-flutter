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

console.log('🔄 Guest vs Authenticated Notification Test');
console.log('============================================\n');

async function sendTargetedNotification(targetType) {
  const customerId = 'ffeee61a-8497-4c70-857e-c8f0efb13a2a';
  
  return new Promise((resolve, reject) => {
    let query, params, targetName;
    
    if (targetType === 'guest') {
      query = `SELECT fcm_token, user_email, is_authenticated 
               FROM fcm_tokens 
               WHERE customer_id = ? AND (is_authenticated = 0 OR user_id IS NULL)`;
      targetName = 'GUEST users';
    } else {
      query = `SELECT fcm_token, user_email, is_authenticated 
               FROM fcm_tokens 
               WHERE customer_id = ? AND is_authenticated = 1 AND user_id IS NOT NULL`;
      targetName = 'AUTHENTICATED users';
    }
    
    db.all(query, [customerId], async (err, tokens) => {
      if (err) {
        console.error('Database error:', err);
        reject(err);
        return;
      }
      
      console.log(`📱 Found ${tokens.length} ${targetName}\n`);
      
      if (tokens.length === 0) {
        console.log(`⚠️  No ${targetName} found to send notification to.`);
        resolve({ sent: 0, target: targetName });
        return;
      }
      
      let successCount = 0;
      
      for (const token of tokens) {
        const message = {
          data: {
            title: `🎯 ${targetType.toUpperCase()} Test`,
            body: `This notification is for ${targetName} only. User: ${token.user_email || 'Guest'}`,
            type: 'info',
            timestamp: new Date().toISOString(),
            target: targetType
          },
          android: {
            priority: 'high'
          },
          token: token.fcm_token
        };
        
        try {
          const response = await admin.messaging().send(message);
          console.log(`✅ Sent to ${token.user_email || 'Guest'}`);
          console.log(`   Token: ${token.fcm_token.substring(0, 30)}...`);
          console.log(`   Message ID: ${response.substring(0, 40)}...\n`);
          successCount++;
        } catch (error) {
          console.log(`❌ Failed to send to ${token.user_email || 'Guest'}: ${error.message}\n`);
        }
      }
      
      resolve({ sent: successCount, target: targetName, total: tokens.length });
    });
  });
}

async function runTest() {
  console.log('📊 Current Token Status:\n');
  
  // Show current state
  db.all(
    `SELECT user_email, is_authenticated, device_id 
     FROM fcm_tokens 
     WHERE customer_id = 'ffeee61a-8497-4c70-857e-c8f0efb13a2a'`,
    [],
    async (err, tokens) => {
      if (err) {
        console.error('Error:', err);
        db.close();
        return;
      }
      
      tokens.forEach(token => {
        console.log(`Device: ${token.device_id}`);
        console.log(`User: ${token.user_email || 'Guest'}`);
        console.log(`Authenticated: ${token.is_authenticated ? 'YES' : 'NO'}\n`);
      });
      
      console.log('🚀 Starting targeted notification tests...\n');
      console.log('─'.repeat(45) + '\n');
      
      // Test guest notifications
      console.log('TEST 1: Sending to GUEST users only...');
      const guestResult = await sendTargetedNotification('guest');
      
      console.log('─'.repeat(45) + '\n');
      
      // Wait 3 seconds
      await new Promise(resolve => setTimeout(resolve, 3000));
      
      // Test authenticated notifications
      console.log('TEST 2: Sending to AUTHENTICATED users only...');
      const authResult = await sendTargetedNotification('authenticated');
      
      console.log('─'.repeat(45) + '\n');
      console.log('📈 Test Summary:\n');
      console.log(`Guest Notifications: ${guestResult.sent}/${guestResult.total || 0} sent`);
      console.log(`Auth Notifications: ${authResult.sent}/${authResult.total || 0} sent`);
      
      console.log('\n✨ Expected Behavior:');
      console.log('- If logged in: Should receive ONLY authenticated notification');
      console.log('- If guest: Should receive ONLY guest notification');
      console.log('- NO user should receive both notifications');
      
      db.close();
      process.exit(0);
    }
  );
}

runTest();