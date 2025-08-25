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

console.log('🔍 Duplicate Prevention Test');
console.log('============================\n');
console.log('This test sends 5 rapid notifications to verify NO duplicates appear.\n');

async function sendRapidNotifications() {
  const customerId = 'ffeee61a-8497-4c70-857e-c8f0efb13a2a';
  
  return new Promise((resolve, reject) => {
    db.all(
      `SELECT fcm_token, user_email, is_authenticated 
       FROM fcm_tokens 
       WHERE customer_id = ? 
       ORDER BY is_authenticated DESC
       LIMIT 1`,
      [customerId],
      async (err, tokens) => {
        if (err) {
          console.error('Database error:', err);
          reject(err);
          return;
        }
        
        if (tokens.length === 0) {
          console.log('❌ No tokens found!');
          reject('No tokens');
          return;
        }
        
        const token = tokens[0];
        console.log(`📱 Testing with: ${token.user_email || 'Guest'}\n`);
        console.log('📤 Sending 5 rapid data-only notifications...\n');
        
        const results = [];
        
        for (let i = 1; i <= 5; i++) {
          const message = {
            // DATA-ONLY: No notification field
            data: {
              title: `📬 Test Message #${i}`,
              body: `Data-only notification ${i} of 5 - Should appear only once!`,
              type: 'info',
              timestamp: new Date().toISOString(),
              messageNumber: i.toString(),
              testType: 'duplicate-prevention'
            },
            android: {
              priority: 'high'
            },
            token: token.fcm_token
          };
          
          try {
            const response = await admin.messaging().send(message);
            console.log(`✅ Message #${i} sent`);
            console.log(`   ID: ${response.substring(0, 40)}...`);
            results.push({ num: i, success: true });
          } catch (error) {
            console.log(`❌ Message #${i} failed: ${error.message}`);
            results.push({ num: i, success: false });
          }
          
          // Small delay between messages (100ms)
          if (i < 5) {
            await new Promise(resolve => setTimeout(resolve, 100));
          }
        }
        
        resolve(results);
      }
    );
  });
}

async function runTest() {
  try {
    const results = await sendRapidNotifications();
    
    const successCount = results.filter(r => r.success).length;
    
    console.log('\n' + '─'.repeat(45));
    console.log('\n📊 Test Results:\n');
    console.log(`✅ Successfully sent: ${successCount}/5 notifications`);
    
    console.log('\n🔎 IMPORTANT - Check your device:');
    console.log('─'.repeat(45));
    console.log('✓ You should see EXACTLY 5 notifications');
    console.log('✓ Each numbered 1 through 5');
    console.log('✓ NO duplicates (not 10 notifications)');
    console.log('✓ Each notification appears only ONCE');
    
    console.log('\n🎯 Success Criteria:');
    console.log('─'.repeat(45));
    console.log('[ ] Exactly 5 notifications visible');
    console.log('[ ] No Firebase auto-display duplicates');
    console.log('[ ] No local notification duplicates');
    console.log('[ ] All messages in correct order (1-5)');
    
    console.log('\n💡 If you see duplicates:');
    console.log('- Check if notification field exists in message');
    console.log('- Verify background handler not showing local notifications');
    console.log('- Ensure data-only format is used');
    
  } catch (error) {
    console.error('\n❌ Test failed:', error);
  }
  
  db.close();
  process.exit(0);
}

runTest();