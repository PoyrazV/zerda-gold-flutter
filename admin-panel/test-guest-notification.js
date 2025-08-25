const fetch = require('node-fetch');

async function testGuestNotificationTargeting() {
  console.log('=== Test: Guest-Only Notification Targeting ===\n');
  
  const customerId = 'ffeee61a-8497-4c70-857e-c8f0efb13a2a';
  
  try {
    // Step 1: Register a guest FCM token
    console.log('1. Registering GUEST FCM token...');
    let response = await fetch('http://localhost:3009/api/mobile/register-fcm-token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        customerId,
        fcmToken: 'guest_token_' + Date.now(),
        deviceId: 'guest_device_' + Date.now(),
        platform: 'android'
        // No userId or userEmail - this is a guest
      })
    });
    
    let result = await response.json();
    console.log('   Guest token registered:', result.success ? '✅ Success' : '❌ Failed');
    
    // Step 2: Register an authenticated user token
    console.log('\n2. Registering AUTHENTICATED user FCM token...');
    const authToken = 'auth_token_' + Date.now();
    response = await fetch('http://localhost:3009/api/mobile/register-fcm-token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        customerId,
        fcmToken: authToken,
        deviceId: 'auth_device_' + Date.now(),
        platform: 'android',
        userId: 'user_123',
        userEmail: 'test@example.com'
      })
    });
    
    result = await response.json();
    console.log('   Auth token registered:', result.success ? '✅ Success' : '❌ Failed');
    
    // Step 3: Simulate logout - token should become guest
    console.log('\n3. Simulating LOGOUT (converting auth token to guest)...');
    response = await fetch('http://localhost:3009/api/mobile/register-fcm-token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        customerId,
        fcmToken: authToken,  // Same token as before
        deviceId: 'auth_device_' + Date.now(),
        platform: 'android',
        userId: null,  // Explicitly null to clear auth
        userEmail: null  // Explicitly null to clear auth
      })
    });
    
    result = await response.json();
    console.log('   Logout update:', result.success ? '✅ Success' : '❌ Failed');
    
    // Step 4: Get admin token
    console.log('\n4. Getting admin token...');
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
    
    // Step 5: Send notification to GUESTS only
    console.log('\n5. Sending notification to GUEST users only...');
    response = await fetch(`http://localhost:3009/api/customers/${customerId}/notifications`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${adminToken}`
      },
      body: JSON.stringify({
        title: 'Misafir Test',
        message: 'Bu bildirim sadece misafir kullanıcılara gitmeli',
        type: 'info',
        target: 'guests'
      })
    });
    
    result = await response.json();
    console.log('   Send result:', result.success ? '✅ Success' : '❌ Failed');
    
    console.log('\n6. Check server console for:');
    console.log('   - "📨 Sending to guest users only"');
    console.log('   - Query showing guest filter conditions');
    console.log('   - Number of guest tokens found (should be 2)');
    console.log('   - List of tokens with their auth status');
    
    console.log('\n=== Test Complete ===');
    console.log('Both the original guest token and the logged-out token should receive the notification.');
    console.log('No authenticated users should receive guest-only notifications.');
    
  } catch (error) {
    console.error('\n❌ Test error:', error.message);
  }
}

testGuestNotificationTargeting();