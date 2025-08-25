const fetch = require('node-fetch');

async function testLoginFCMUpdate() {
  console.log('=== Test: Login FCM Token Update ===\n');
  
  const customerId = 'ffeee61a-8497-4c70-857e-c8f0efb13a2a';
  const testFcmToken = 'test_fcm_' + Date.now();
  const testDeviceId = 'test_device_' + Date.now();
  
  try {
    // Step 1: Register FCM token as guest first
    console.log('1. Registering FCM token as GUEST...');
    let response = await fetch('http://localhost:3009/api/mobile/register-fcm-token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        customerId,
        fcmToken: testFcmToken,
        deviceId: testDeviceId,
        platform: 'android'
        // No user info - guest registration
      })
    });
    
    let result = await response.json();
    console.log('   Guest registration:', result.success ? '✅ Success' : '❌ Failed');
    
    // Step 2: Login with demo user (this should update FCM token)
    console.log('\n2. Login with demo@zerda.com...');
    response = await fetch('http://localhost:3009/api/mobile/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: 'demo@zerda.com',
        password: 'demo123',
        fcm_token: testFcmToken,  // Same token
        device_id: testDeviceId,
        platform: 'android'
      })
    });
    
    result = await response.json();
    
    if (result.success) {
      console.log('   ✅ Login successful');
      console.log('   User ID:', result.data.user.id);
      console.log('   User Email:', result.data.user.email);
      
      // Step 3: Update FCM token with user info (simulating what app should do)
      console.log('\n3. Updating FCM token with user info after login...');
      response = await fetch('http://localhost:3009/api/mobile/register-fcm-token', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          customerId,
          fcmToken: testFcmToken,
          deviceId: testDeviceId,
          platform: 'android',
          userId: result.data.user.id,
          userEmail: result.data.user.email
        })
      });
      
      const updateResult = await response.json();
      console.log('   FCM update:', updateResult.success ? '✅ Success' : '❌ Failed');
      
      // Step 4: Check token status in database
      console.log('\n4. Running database check...');
      const { exec } = require('child_process');
      exec('node check-fcm-tokens.js', (error, stdout, stderr) => {
        if (error) {
          console.error('Error checking tokens:', error);
          return;
        }
        console.log(stdout);
        
        console.log('\n=== Test Complete ===');
        console.log('The FCM token should now be marked as authenticated.');
        console.log('Check if is_authenticated = 1 and user_id is set.');
      });
      
    } else {
      console.log('   ❌ Login failed:', result.error);
    }
    
  } catch (error) {
    console.error('\n❌ Test error:', error.message);
  }
}

testLoginFCMUpdate();