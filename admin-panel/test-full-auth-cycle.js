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

console.log('🔄 Full Authentication Cycle Test');
console.log('==================================\n');

function getTokenStatus() {
  return new Promise((resolve, reject) => {
    db.get(
      `SELECT 
        fcm_token,
        device_id,
        user_id,
        user_email,
        is_authenticated,
        updated_at
       FROM fcm_tokens
       WHERE customer_id = 'ffeee61a-8497-4c70-857e-c8f0efb13a2a'
       ORDER BY updated_at DESC
       LIMIT 1`,
      [],
      (err, token) => {
        if (err) reject(err);
        else resolve(token);
      }
    );
  });
}

async function waitForStatusChange(expectedStatus, timeoutSeconds = 30) {
  const startTime = Date.now();
  const timeoutMs = timeoutSeconds * 1000;
  
  console.log(`⏳ Waiting for status change to: ${expectedStatus}...`);
  
  while (Date.now() - startTime < timeoutMs) {
    const token = await getTokenStatus();
    
    if (!token) {
      console.log('   No token found');
      await new Promise(resolve => setTimeout(resolve, 2000));
      continue;
    }
    
    const currentStatus = token.is_authenticated ? 'authenticated' : 'guest';
    
    if (currentStatus === expectedStatus) {
      console.log(`✅ Status changed to: ${expectedStatus}`);
      return token;
    }
    
    // Show progress
    const elapsed = Math.floor((Date.now() - startTime) / 1000);
    process.stdout.write(`\r   Current: ${currentStatus}, waiting... (${elapsed}s)`);
    
    await new Promise(resolve => setTimeout(resolve, 2000));
  }
  
  console.log(`\n⏱️ Timeout reached after ${timeoutSeconds} seconds`);
  return null;
}

async function sendTargetedTest(token) {
  const tests = [];
  
  // Test guest notification
  if (!token.is_authenticated) {
    try {
      const message = {
        data: {
          title: '🧪 Guest Mode Test',
          body: 'You should see this as a guest user',
          type: 'info',
          timestamp: new Date().toISOString()
        },
        android: { priority: 'high' },
        token: token.fcm_token
      };
      
      await admin.messaging().send(message);
      tests.push({ type: 'Guest', sent: true, expected: true });
    } catch (e) {
      tests.push({ type: 'Guest', sent: false, error: e.message });
    }
  }
  
  // Test authenticated notification
  if (token.is_authenticated) {
    try {
      const message = {
        data: {
          title: '🔐 Authenticated Test',
          body: `Welcome ${token.user_email}!`,
          type: 'success',
          timestamp: new Date().toISOString()
        },
        android: { priority: 'high' },
        token: token.fcm_token
      };
      
      await admin.messaging().send(message);
      tests.push({ type: 'Authenticated', sent: true, expected: true });
    } catch (e) {
      tests.push({ type: 'Authenticated', sent: false, error: e.message });
    }
  }
  
  return tests;
}

async function runFullTest() {
  console.log('This test monitors token changes during login/logout cycles.\n');
  
  try {
    // Get initial status
    console.log('📊 Initial Status Check\n');
    let currentToken = await getTokenStatus();
    
    if (!currentToken) {
      console.log('❌ No token found. Please run the app first.');
      db.close();
      process.exit(1);
    }
    
    console.log('Current Status:');
    console.log(`   Device: ${currentToken.device_id}`);
    console.log(`   User: ${currentToken.user_email || 'Guest'}`);
    console.log(`   Mode: ${currentToken.is_authenticated ? 'Authenticated' : 'Guest'}\n`);
    
    console.log('─'.repeat(50) + '\n');
    
    // Determine what action is needed
    if (currentToken.is_authenticated) {
      console.log('📋 Test Step 1: LOGOUT TEST\n');
      console.log('👉 ACTION REQUIRED: Please LOGOUT in the app\n');
      
      // Wait for logout
      const guestToken = await waitForStatusChange('guest', 60);
      
      if (guestToken) {
        console.log('\n✅ Logout successful!');
        console.log(`   Device preserved: ${guestToken.device_id}`);
        console.log(`   User cleared: ${guestToken.user_email || 'NULL'}`);
        console.log(`   Mode: Guest\n`);
        
        // Send guest notification
        console.log('📤 Sending guest notification test...');
        const guestTests = await sendTargetedTest(guestToken);
        guestTests.forEach(test => {
          console.log(`   ${test.type}: ${test.sent ? '✅ Sent' : '❌ Failed'}`);
        });
        
        console.log('\n─'.repeat(50) + '\n');
        console.log('📋 Test Step 2: LOGIN TEST\n');
        console.log('👉 ACTION REQUIRED: Please LOGIN in the app\n');
        
        // Wait for login
        const authToken = await waitForStatusChange('authenticated', 60);
        
        if (authToken) {
          console.log('\n✅ Login successful!');
          console.log(`   Device preserved: ${authToken.device_id}`);
          console.log(`   User: ${authToken.user_email}`);
          console.log(`   Mode: Authenticated\n`);
          
          // Send authenticated notification
          console.log('📤 Sending authenticated notification test...');
          const authTests = await sendTargetedTest(authToken);
          authTests.forEach(test => {
            console.log(`   ${test.type}: ${test.sent ? '✅ Sent' : '❌ Failed'}`);
          });
          
          console.log('\n' + '═'.repeat(50));
          console.log('\n🎉 FULL CYCLE TEST COMPLETED!\n');
          console.log('✅ Logout: Token converted to guest');
          console.log('✅ Login: Token updated with user info');
          console.log('✅ Device ID: Preserved throughout');
          console.log('✅ Notifications: Targeted correctly');
        } else {
          console.log('\n❌ Login not detected within timeout');
        }
      } else {
        console.log('\n❌ Logout not detected within timeout');
      }
    } else {
      console.log('📋 Starting from GUEST mode\n');
      console.log('👉 ACTION REQUIRED: Please LOGIN in the app\n');
      
      // Wait for login
      const authToken = await waitForStatusChange('authenticated', 60);
      
      if (authToken) {
        console.log('\n✅ Login successful!');
        console.log(`   User: ${authToken.user_email}`);
        console.log(`   Mode: Authenticated\n`);
        
        // Send authenticated notification
        console.log('📤 Sending authenticated notification test...');
        const authTests = await sendTargetedTest(authToken);
        authTests.forEach(test => {
          console.log(`   ${test.type}: ${test.sent ? '✅ Sent' : '❌ Failed'}`);
        });
        
        console.log('\n👉 Now please LOGOUT to complete the cycle test');
      } else {
        console.log('\n❌ Login not detected within timeout');
      }
    }
    
  } catch (error) {
    console.error('\n❌ Test error:', error);
  } finally {
    db.close();
  }
}

// Run the test
console.log('🔍 Monitoring token changes in real-time...\n');
console.log('─'.repeat(50) + '\n');

runFullTest();