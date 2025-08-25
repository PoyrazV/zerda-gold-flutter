const fetch = require('node-fetch');

async function sendTestNotification() {
  console.log('Sending test notification...\n');
  
  // First login as admin
  const loginResponse = await fetch('http://localhost:3009/api/auth/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      username: 'admin',
      password: 'admin123'
    })
  });
  
  const loginResult = await loginResponse.json();
  
  if (!loginResult.success) {
    console.error('❌ Login failed:', loginResult.error);
    return;
  }
  
  const token = loginResult.token;
  console.log('✅ Logged in as admin\n');
  
  // Send notification
  const notificationData = {
    title: 'Test Bildirimi',
    message: 'Bu MySQL backend\'den gönderilen test bildirimidir.',
    type: 'info',
    priority: 'normal',
    target_audience: 'all',
    scheduled_at: null
  };
  
  const response = await fetch('http://localhost:3009/api/notifications/send', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`
    },
    body: JSON.stringify(notificationData)
  });
  
  const result = await response.json();
  
  if (result.success) {
    console.log('✅ Notification sent successfully!');
    console.log('   Title:', notificationData.title);
    console.log('   Message:', notificationData.message);
    console.log('   Target:', notificationData.target_audience);
    console.log('   Sent to:', result.sent_count || 0, 'users');
  } else {
    console.log('❌ Failed to send notification:', result.error);
  }
}

sendTestNotification().catch(console.error);