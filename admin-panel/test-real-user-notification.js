const fetch = require('node-fetch');

async function testRealUserNotification() {
  console.log('=== Test: Real User Login and Notification ===\n');
  
  const customerId = 'ffeee61a-8497-4c70-857e-c8f0efb13a2a';
  
  try {
    // Step 1: Simulate Flutter app login
    console.log('1. Simulating Flutter app user login...');
    const loginData = {
      email: 'demo@zerda.com',
      password: 'demo123',
      fcm_token: 'flutter_fcm_token_' + Date.now(),
      device_id: 'flutter_device_' + Date.now(),
      platform: 'android'
    };
    
    let response = await fetch('http://localhost:3009/api/mobile/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(loginData)
    });
    
    let result = await response.json();
    
    if (!result.success) {
      // Create user if doesn't exist
      console.log('   User not found, creating...');
      response = await fetch('http://localhost:3009/api/mobile/auth/register', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: loginData.email,
          password: loginData.password,
          full_name: 'Demo User'
        })
      });
      
      result = await response.json();
      if (!result.success) {
        console.log('❌ Registration failed:', result.error);
        return;
      }
      
      // Login again
      response = await fetch('http://localhost:3009/api/mobile/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(loginData)
      });
      
      result = await response.json();
    }
    
    if (result.success) {
      console.log('   ✅ User logged in:', result.data.user.email);
      console.log('   User ID:', result.data.user.id);
      const userToken = result.data.token;
      const userId = result.data.user.id;
      const userEmail = result.data.user.email;
      
      // Step 2: Update FCM token with user info (simulating what AuthService does)
      console.log('\n2. Updating FCM token with user authentication info...');
      response = await fetch('http://localhost:3009/api/mobile/register-fcm-token', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          customerId,
          fcmToken: loginData.fcm_token,
          deviceId: loginData.device_id,
          platform: loginData.platform,
          userId: userId,
          userEmail: userEmail
        })
      });
      
      result = await response.json();
      console.log('   FCM update:', result.success ? '✅ Success' : '❌ Failed');
      
      // Step 3: Get admin token
      console.log('\n3. Admin login for sending notifications...');
      response = await fetch('http://localhost:3009/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          username: 'admin',
          password: 'admin123'
        })
      });
      
      const adminResult = await response.json();
      const adminToken = adminResult.data.token;
      console.log('   Admin login: ✅ Success');
      
      // Step 4: Send notification to authenticated users
      console.log('\n4. Sending notification to AUTHENTICATED users only...');
      response = await fetch(`http://localhost:3009/api/customers/${customerId}/notifications`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${adminToken}`
        },
        body: JSON.stringify({
          title: 'Giriş Yapmış Kullanıcılara Özel',
          message: 'Bu bildirimi sadece giriş yapmış kullanıcılar almalı',
          type: 'success',
          target: 'authenticated'
        })
      });
      
      result = await response.json();
      console.log('   Result:', result.success ? '✅ Success' : '❌ Failed');
      if (result.data) {
        console.log('   Notification ID:', result.data.id);
        console.log('   Status:', result.data.status);
      }
      
      // Step 5: Check if user can receive the notification
      console.log('\n5. Checking notification delivery status...');
      console.log('   The server console should show:');
      console.log('   - "📨 Sending to authenticated users only"');
      console.log('   - Query details and parameters');
      console.log('   - Number of authenticated tokens found');
      console.log('   - User email and authentication status');
      
      // Step 6: Test guest notification (should NOT reach this user)
      console.log('\n6. Sending notification to GUEST users (logged-in user should NOT receive)...');
      response = await fetch(`http://localhost:3009/api/customers/${customerId}/notifications`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${adminToken}`
        },
        body: JSON.stringify({
          title: 'Misafir Kullanıcılara Özel',
          message: 'Bu bildirimi giriş yapmış kullanıcılar almamalı',
          type: 'warning',
          target: 'guests'
        })
      });
      
      result = await response.json();
      console.log('   Result:', result.success ? '✅ Success' : '❌ Failed');
      
      console.log('\n=== Test Complete ===');
      console.log('✅ User authentication and notification targeting test completed.');
      console.log('Check the server console for detailed FCM token and query logs.');
      
    } else {
      console.log('❌ Login failed:', result.error);
    }
    
  } catch (error) {
    console.error('\n❌ Test error:', error.message);
  }
}

testRealUserNotification();