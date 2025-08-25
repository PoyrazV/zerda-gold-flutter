const http = require('http');

const CUSTOMER_ID = 'ffeee61a-8497-4c70-857e-c8f0efb13a2a';
const API_URL = 'http://localhost:3009';

console.log('\n🔔 Testing Authenticated User Notification...\n');

// First, login to get token
const loginData = JSON.stringify({
  username: 'admin',
  password: 'admin123'
});

const loginOptions = {
  hostname: 'localhost',
  port: 3009,
  path: '/api/auth/login',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': loginData.length
  }
};

const loginReq = http.request(loginOptions, (res) => {
  let data = '';
  
  res.on('data', (chunk) => {
    data += chunk;
  });
  
  res.on('end', () => {
    try {
      const response = JSON.parse(data);
      
      if (response.success && response.token) {
        console.log('✅ Admin login successful');
        
        // Now send notification to authenticated users
        const notificationData = JSON.stringify({
          title: 'Test - Authenticated Users Only',
          message: `This notification should ONLY go to logged-in users. Time: ${new Date().toLocaleTimeString()}`,
          type: 'info',
          target: 'authenticated'
        });
        
        const notificationOptions = {
          hostname: 'localhost',
          port: 3009,
          path: `/api/customers/${CUSTOMER_ID}/notifications`,
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Content-Length': notificationData.length,
            'Authorization': `Bearer ${response.token}`
          }
        };
        
        console.log('\n📤 Sending notification to AUTHENTICATED users...');
        console.log('   Target: authenticated');
        console.log('   Title: Test - Authenticated Users Only');
        
        const notificationReq = http.request(notificationOptions, (notifRes) => {
          let notifData = '';
          
          notifRes.on('data', (chunk) => {
            notifData += chunk;
          });
          
          notifRes.on('end', () => {
            try {
              const notifResponse = JSON.parse(notifData);
              
              if (notifResponse.success) {
                console.log('\n✅ Notification sent successfully!');
                console.log('   Notification ID:', notifResponse.data.id);
                console.log('   Status:', notifResponse.data.status);
                console.log('\n📱 Check your phone now!');
                console.log('   - If you are LOGGED IN: You should receive the notification');
                console.log('   - If you are LOGGED OUT: You should NOT receive it');
              } else {
                console.log('\n❌ Failed to send notification:', notifResponse.error);
              }
            } catch (e) {
              console.error('\n❌ Error parsing notification response:', e);
              console.log('Raw response:', notifData);
            }
          });
        });
        
        notificationReq.on('error', (e) => {
          console.error('\n❌ Error sending notification:', e);
        });
        
        notificationReq.write(notificationData);
        notificationReq.end();
        
      } else {
        console.log('❌ Admin login failed:', response.error || 'Unknown error');
      }
    } catch (e) {
      console.error('❌ Error parsing login response:', e);
      console.log('Raw response:', data);
    }
  });
});

loginReq.on('error', (e) => {
  console.error('❌ Error connecting to admin panel:', e);
  console.log('\nMake sure the admin panel is running:');
  console.log('  cd admin-panel');
  console.log('  npm start');
});

loginReq.write(loginData);
loginReq.end();