const fetch = require('node-fetch');

async function testLogin() {
  console.log('Testing login with FCM token...\n');
  
  const loginData = {
    email: 'demo@zerda.com',
    password: 'demo123456',
    fcm_token: 'cMfZPdSoQa-OWThIl7DvZE:APA91bGJhmz8crOT-bodEcRyqq8Q8RfB4HfZ_hO3J3LYaS7ymW3p7na8UMlNcoD1h8XbD4dBdakpPuIgD9PQdKcN8EN-jdomTqj5I_4D3R5j1qotHpRt_sQ',
    device_id: 'test-device-123',
    platform: 'android'
  };
  
  try {
    const response = await fetch('http://localhost:3009/api/mobile/auth/login', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(loginData)
    });
    
    const result = await response.json();
    
    if (result.success) {
      console.log('✅ Login successful!');
      console.log('User:', result.data.user.email);
      console.log('Token:', result.data.token.substring(0, 50) + '...');
    } else {
      console.log('❌ Login failed:', result.error);
    }
    
  } catch (error) {
    console.error('Error:', error.message);
  }
}

testLogin();