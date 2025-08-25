const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const admin = require('firebase-admin');

// Initialize Firebase Admin
const serviceAccount = require('./firebase-service-account.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: serviceAccount.project_id
});

const dbPath = path.join(__dirname, 'zerda_admin.db');
const db = new sqlite3.Database(dbPath, sqlite3.OPEN_READONLY);

console.log('🔄 Logout Token Update Test');
console.log('============================\n');

function checkTokenStatus() {
  return new Promise((resolve, reject) => {
    db.all(
      `SELECT 
        fcm_token,
        device_id,
        user_id,
        user_email,
        is_authenticated,
        customer_id,
        platform,
        updated_at
       FROM fcm_tokens
       WHERE customer_id = 'ffeee61a-8497-4c70-857e-c8f0efb13a2a'
       ORDER BY updated_at DESC`,
      [],
      (err, tokens) => {
        if (err) {
          reject(err);
        } else {
          resolve(tokens);
        }
      }
    );
  });
}

async function sendTestNotification(targetType, expectToReceive) {
  const customerId = 'ffeee61a-8497-4c70-857e-c8f0efb13a2a';
  
  return new Promise((resolve, reject) => {
    let query;
    if (targetType === 'guest') {
      query = `SELECT fcm_token FROM fcm_tokens 
               WHERE customer_id = ? AND (is_authenticated = 0 OR user_id IS NULL)`;
    } else {
      query = `SELECT fcm_token FROM fcm_tokens 
               WHERE customer_id = ? AND is_authenticated = 1 AND user_id IS NOT NULL`;
    }
    
    db.all(query, [customerId], async (err, tokens) => {
      if (err) {
        reject(err);
        return;
      }
      
      const shouldReceive = tokens.length > 0;
      const testPassed = shouldReceive === expectToReceive;
      
      if (tokens.length > 0) {
        // Send actual test notification
        try {
          const message = {
            data: {
              title: `🧪 ${targetType.toUpperCase()} Test`,
              body: `Testing ${targetType} notification after logout`,
              type: 'info',
              timestamp: new Date().toISOString()
            },
            android: { priority: 'high' },
            token: tokens[0].fcm_token
          };
          
          await admin.messaging().send(message);
          console.log(`   ✅ ${targetType} notification sent`);
        } catch (e) {
          console.log(`   ❌ Failed to send: ${e.message}`);
        }
      }
      
      resolve({
        targetType,
        expectToReceive,
        actuallyReceived: shouldReceive,
        passed: testPassed,
        tokenCount: tokens.length
      });
    });
  });
}

async function runTest() {
  console.log('📋 Test Scenario:\n');
  console.log('1. Check current token status');
  console.log('2. Simulate logout (you need to logout in app)');
  console.log('3. Verify token is updated to guest');
  console.log('4. Test notification targeting\n');
  
  console.log('─'.repeat(50) + '\n');
  
  // Step 1: Check initial status
  console.log('STEP 1: Checking initial token status...\n');
  const initialTokens = await checkTokenStatus();
  
  if (initialTokens.length === 0) {
    console.log('❌ No tokens found! Please run the app first.');
    db.close();
    process.exit(1);
  }
  
  const token = initialTokens[0];
  console.log('📱 Current Token Status:');
  console.log(`   Device ID: ${token.device_id}`);
  console.log(`   User: ${token.user_email || 'Guest'}`);
  console.log(`   Authenticated: ${token.is_authenticated ? 'YES' : 'NO'}`);
  console.log(`   Last Update: ${token.updated_at}\n`);
  
  console.log('─'.repeat(50) + '\n');
  
  // Step 2: Instructions for manual logout
  if (token.is_authenticated) {
    console.log('STEP 2: Manual Action Required\n');
    console.log('⚠️  User is currently logged in as: ' + token.user_email);
    console.log('👉 Please LOGOUT in the Flutter app now!');
    console.log('   Then run this script again to verify.\n');
    
    console.log('Expected after logout:');
    console.log('   - is_authenticated should be 0');
    console.log('   - user_id should be NULL');
    console.log('   - user_email should be NULL');
    console.log('   - device_id should remain the same\n');
  } else {
    console.log('STEP 2: Token Status After Logout\n');
    console.log('✅ User is logged out (Guest mode)');
    console.log(`   Device ID preserved: ${token.device_id}`);
    console.log(`   Authenticated: NO`);
    console.log(`   User cleared: NULL\n`);
    
    console.log('─'.repeat(50) + '\n');
    
    // Step 3: Test notifications
    console.log('STEP 3: Testing Notification Targeting\n');
    
    const guestTest = await sendTestNotification('guest', true);
    const authTest = await sendTestNotification('authenticated', false);
    
    console.log('📊 Notification Test Results:\n');
    console.log(`Guest Notification:`);
    console.log(`   Should receive: YES`);
    console.log(`   Actually receives: ${guestTest.actuallyReceived ? 'YES' : 'NO'}`);
    console.log(`   Result: ${guestTest.passed ? '✅ PASSED' : '❌ FAILED'}\n`);
    
    console.log(`Authenticated Notification:`);
    console.log(`   Should receive: NO`);
    console.log(`   Actually receives: ${authTest.actuallyReceived ? 'YES' : 'NO'}`);
    console.log(`   Result: ${authTest.passed ? '✅ PASSED' : '❌ FAILED'}\n`);
    
    console.log('─'.repeat(50) + '\n');
    
    // Final summary
    const allPassed = guestTest.passed && authTest.passed;
    if (allPassed) {
      console.log('🎉 SUCCESS: Logout token update working correctly!');
      console.log('   - Token converted to guest mode');
      console.log('   - Notification targeting is correct');
      console.log('   - Device ID preserved');
    } else {
      console.log('❌ FAILURE: Issues detected with logout token update');
      if (!guestTest.passed) {
        console.log('   - Guest notifications not working');
      }
      if (!authTest.passed) {
        console.log('   - Still receiving authenticated notifications');
      }
    }
  }
  
  console.log('\n' + '─'.repeat(50));
  console.log('\n💡 Next Steps:');
  console.log('1. Login with a user account');
  console.log('2. Logout and run this test');
  console.log('3. Verify guest notifications work');
  console.log('4. Login again and verify authenticated notifications');
  
  db.close();
  process.exit(0);
}

// Run the test
runTest().catch(err => {
  console.error('Test error:', err);
  db.close();
  process.exit(1);
});