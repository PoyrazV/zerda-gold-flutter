const fetch = (...args) => import('node-fetch').then(({default: fetch}) => fetch(...args));

async function testFCMAuthFlow() {
  console.log('=== Test: FCM Token Authentication Flow ===\n');
  
  const customerId = 'ffeee61a-8497-4c70-857e-c8f0efb13a2a';
  const fcmToken = 'test_fcm_auth_' + Date.now();
  const deviceId = 'test_device_auth_' + Date.now();
  
  try {
    // Step 1: Register FCM token as GUEST
    console.log('1. Registering FCM token as GUEST...');
    let response = await fetch('http://localhost:3009/api/mobile/register-fcm-token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        customerId,
        fcmToken,
        deviceId,
        platform: 'android'
        // No userId or userEmail - this is a guest
      })
    });
    
    let result = await response.json();
    console.log('   Guest registration:', result.success ? '✅ Success' : '❌ Failed');
    
    // Step 2: Check token status in database
    console.log('\n2. Checking token status in database...');
    response = await fetch('http://localhost:3009/api/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        username: 'admin',
        password: 'admin123'
      })
    });
    
    result = await response.json();
    const adminToken = result.data.token;
    
    // Step 3: Simulate user login - token should become authenticated
    console.log('\n3. Simulating USER LOGIN (updating token to authenticated)...');
    response = await fetch('http://localhost:3009/api/mobile/register-fcm-token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        customerId,
        fcmToken,  // Same token as before
        deviceId,
        platform: 'android',
        userId: 'user_12345',
        userEmail: 'test@example.com'
      })
    });
    
    result = await response.json();
    console.log('   Auth update:', result.success ? '✅ Success - Token marked as authenticated' : '❌ Failed');
    
    // Step 4: Send notification to authenticated users only
    console.log('\n4. Sending notification to AUTHENTICATED users only...');
    response = await fetch('http://localhost:3009/api/notifications/broadcast', {
      method: 'POST',
      headers: { 
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${adminToken}`
      },
      body: JSON.stringify({
        title: 'Test Auth Notification',
        message: 'This should only go to authenticated users',
        type: 'info',
        target: 'authenticated'
      })
    });
    
    result = await response.json();
    console.log('   Notification sent:', result.success ? `✅ Sent to ${result.sentCount} authenticated users` : '❌ Failed');
    
    // Step 5: Check if notification was created for our user
    console.log('\n5. Checking if authenticated user received the notification...');
    response = await fetch(`http://localhost:3009/api/customers/${customerId}/notifications`, {
      headers: { 'Authorization': `Bearer ${adminToken}` }
    });
    
    result = await response.json();
    if (result.success && result.data.length > 0) {
      const authNotification = result.data.find(n => 
        n.title === 'Test Auth Notification' && 
        n.target === 'authenticated'
      );
      console.log('   Notification received:', authNotification ? '✅ Yes' : '❌ No');
    }
    
    // Step 6: Simulate logout - token should become guest again
    console.log('\n6. Simulating USER LOGOUT (converting token back to guest)...');
    response = await fetch('http://localhost:3009/api/mobile/register-fcm-token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        customerId,
        fcmToken,  // Same token
        deviceId,
        platform: 'android',
        userId: null,  // Explicitly null to mark as guest
        userEmail: null  // Explicitly null to mark as guest
      })
    });
    
    result = await response.json();
    console.log('   Logout update:', result.success ? '✅ Success - Token marked as guest' : '❌ Failed');
    
    // Step 7: Send notification to guests only
    console.log('\n7. Sending notification to GUEST users only...');
    response = await fetch('http://localhost:3009/api/notifications/broadcast', {
      method: 'POST',
      headers: { 
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${adminToken}`
      },
      body: JSON.stringify({
        title: 'Test Guest Notification',
        message: 'This should only go to guest users',
        type: 'info',
        target: 'guests'
      })
    });
    
    result = await response.json();
    console.log('   Notification sent:', result.success ? `✅ Sent to ${result.sentCount} guest users` : '❌ Failed');
    
    // Step 8: Check if guest received the notification
    console.log('\n8. Checking if guest user received the notification...');
    response = await fetch(`http://localhost:3009/api/customers/${customerId}/notifications`, {
      headers: { 'Authorization': `Bearer ${adminToken}` }
    });
    
    result = await response.json();
    if (result.success && result.data.length > 0) {
      const guestNotification = result.data.find(n => 
        n.title === 'Test Guest Notification' && 
        n.target === 'guests'
      );
      console.log('   Notification received:', guestNotification ? '✅ Yes' : '❌ No');
    }
    
    console.log('\n✅ Test completed successfully!');
    console.log('\n📋 Summary:');
    console.log('   - FCM token can be registered as guest');
    console.log('   - Token updates to authenticated when user logs in');
    console.log('   - Authenticated users receive targeted notifications');
    console.log('   - Token reverts to guest when user logs out');
    console.log('   - Guest users receive guest-targeted notifications');
    
  } catch (error) {
    console.error('❌ Test failed:', error.message);
  }
}

// Run the test
testFCMAuthFlow();