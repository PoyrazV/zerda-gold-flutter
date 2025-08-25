const fetch = require('node-fetch');

async function testPendingNotifications() {
  console.log('1. First login to get token...\n');
  
  const loginData = {
    email: 'demo@zerda.com',
    password: 'demo123',
    fcm_token: 'cMfZPdSoQa-OWThIl7DvZE:APA91bGJhmz8crOT-bodEcRyqq8Q8RfB4HfZ_hO3J3LYaS7ymW3p7na8UMlNcoD1h8XbD4dBdakpPuIgD9PQdKcN8EN-jdomTqj5I_4D3R5j1qotHpRt_sQ',
    device_id: 'test-device-123',
    platform: 'android'
  };
  
  try {
    // Login first
    const loginResponse = await fetch('http://localhost:3009/api/mobile/auth/login', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(loginData)
    });
    
    const loginResult = await loginResponse.json();
    
    if (!loginResult.success) {
      console.log('❌ Login failed:', loginResult.error);
      return;
    }
    
    console.log('✅ Login successful!');
    const token = loginResult.data.token;
    
    // Now test pending notifications endpoint
    console.log('\n2. Testing pending notifications endpoint...\n');
    
    console.log('   Using token:', token.substring(0, 50) + '...');
    
    const pendingResponse = await fetch('http://localhost:3009/api/mobile/notifications/pending', {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });
    
    console.log('   Response status:', pendingResponse.status);
    
    const pendingResult = await pendingResponse.json();
    
    if (pendingResult.success) {
      console.log('✅ Pending notifications response:');
      console.log('   Total found:', pendingResult.totalCount || pendingResult.notifications?.length || 0);
      console.log('   Delivered:', pendingResult.delivered || false);
      console.log('   Delivered count:', pendingResult.deliveredCount || 0);
      if (pendingResult.reason) {
        console.log('   Reason:', pendingResult.reason);
      }
      if (pendingResult.notifications && pendingResult.notifications.length > 0) {
        console.log('\n   Notifications:');
        pendingResult.notifications.slice(0, 3).forEach((n, i) => {
          console.log(`   ${i+1}. ${n.title} (${n.id})`);
        });
      }
    } else {
      console.log('❌ Failed to get pending notifications:', pendingResult.error);
    }
    
  } catch (error) {
    console.error('Error:', error.message);
  }
}

testPendingNotifications();