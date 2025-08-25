const fetch = require('node-fetch');

async function testAuthenticatedNotifications() {
  console.log('=== Test: Authenticated User Notifications ===\n');
  
  const customerId = 'ffeee61a-8497-4c70-857e-c8f0efb13a2a';
  const fcmToken = 'test_fcm_token_' + Date.now();
  const deviceId = 'test_device_' + Date.now();
  
  try {
    // Step 1: Register FCM token as guest
    console.log('1. Registering FCM token as GUEST...');
    let response = await fetch('http://localhost:3009/api/mobile/register-fcm-token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        customerId,
        fcmToken,
        deviceId,
        platform: 'android'
      })
    });
    
    let result = await response.json();
    console.log('   Guest registration:', result.success ? '✅ Success' : '❌ Failed');
    
    // Step 2: Register same FCM token as authenticated user
    console.log('\n2. Updating FCM token as AUTHENTICATED user...');
    response = await fetch('http://localhost:3009/api/mobile/register-fcm-token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        customerId,
        fcmToken,
        deviceId,
        platform: 'android',
        userId: 'user_123',
        userEmail: 'test@example.com'
      })
    });
    
    result = await response.json();
    console.log('   Auth registration:', result.success ? '✅ Success' : '❌ Failed');
    
    // Step 3: Get admin token
    console.log('\n3. Getting admin token...');
    response = await fetch('http://localhost:3009/api/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        username: 'admin',
        password: 'admin123'
      })
    });
    
    const loginResult = await response.json();
    if (!loginResult.success) {
      console.log('❌ Admin login failed:', loginResult.error);
      return;
    }
    const adminToken = loginResult.data.token;
    console.log('   Admin login: ✅ Success');
    
    // Step 4: Send notification to authenticated users
    console.log('\n4. Sending notification to AUTHENTICATED users...');
    response = await fetch(`http://localhost:3009/api/customers/${customerId}/notifications`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${adminToken}`
      },
      body: JSON.stringify({
        title: 'Test - Authenticated Users Only',
        message: 'This notification should only go to logged-in users',
        type: 'info',
        target: 'authenticated'
      })
    });
    
    result = await response.json();
    console.log('   Send result:', result.success ? '✅ Success' : '❌ Failed');
    if (result.data) {
      console.log('   Notification ID:', result.data.id);
    }
    
    // Step 5: Check server logs (they should show debug info)
    console.log('\n5. Check server console for detailed logs:');
    console.log('   - FCM token registration details');
    console.log('   - Query used to fetch tokens');
    console.log('   - Number of tokens found');
    console.log('   - User authentication status');
    
    // Step 6: Test with guest target
    console.log('\n6. Sending notification to GUEST users...');
    response = await fetch(`http://localhost:3009/api/customers/${customerId}/notifications`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${adminToken}`
      },
      body: JSON.stringify({
        title: 'Test - Guest Users Only',
        message: 'This notification should only go to non-logged-in users',
        type: 'info',
        target: 'guests'
      })
    });
    
    result = await response.json();
    console.log('   Send result:', result.success ? '✅ Success' : '❌ Failed');
    
    // Step 7: Register another token as guest and test "all" target
    const guestToken = 'guest_fcm_token_' + Date.now();
    console.log('\n7. Registering another token as GUEST...');
    response = await fetch('http://localhost:3009/api/mobile/register-fcm-token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        customerId,
        fcmToken: guestToken,
        deviceId: 'guest_device_' + Date.now(),
        platform: 'android'
      })
    });
    
    console.log('\n8. Sending notification to ALL users...');
    response = await fetch(`http://localhost:3009/api/customers/${customerId}/notifications`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${adminToken}`
      },
      body: JSON.stringify({
        title: 'Test - All Users',
        message: 'This notification should go to everyone',
        type: 'info',
        target: 'all'
      })
    });
    
    result = await response.json();
    console.log('   Send result:', result.success ? '✅ Success' : '❌ Failed');
    
    console.log('\n=== Test Complete ===');
    console.log('Check the server console for detailed debug output.');
    
  } catch (error) {
    console.error('\n❌ Test error:', error.message);
  }
}

testAuthenticatedNotifications();