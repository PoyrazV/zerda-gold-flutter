const fetch = require('node-fetch');

async function testNotificationSend() {
  console.log('Testing notification send...\n');
  
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
  
  const token = loginResult.data.token;
  console.log('✅ Logged in as admin\n');
  
  // Send notification
  const customerId = 'ffeee61a-8497-4c70-857e-c8f0efb13a2a';
  const notificationData = {
    title: 'Test Bildirimi',
    message: 'Bu admin panelden gönderilen test bildirimidir.',
    type: 'info',
    target: 'all'
  };
  
  console.log('Sending notification...');
  console.log('Data:', notificationData);
  
  const response = await fetch(`http://localhost:3009/api/customers/${customerId}/notifications`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`
    },
    body: JSON.stringify(notificationData)
  });
  
  const result = await response.json();
  console.log('\nResponse:', result);
  
  if (result.success) {
    console.log('\n✅ Notification sent successfully!');
    console.log('   Notification ID:', result.notificationId);
    console.log('   Message:', result.message);
  } else {
    console.log('\n❌ Failed to send notification:', result.error);
  }
}

testNotificationSend().catch(console.error);