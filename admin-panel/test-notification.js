// Test script to send FCM notifications through the admin panel
const http = require('http');

// Admin panel configuration
const API_URL = 'http://localhost:3009';
const CUSTOMER_ID = '112e0e89-1c16-485d-acda-d0a21a24bb95';
const JWT_TOKEN = 'your-jwt-token-here'; // Update this after login

// Function to send test notification
function sendTestNotification(token) {
  const notificationData = {
    title: `Test Notification - ${new Date().toLocaleTimeString()}`,
    message: `This is a test notification sent at ${new Date().toLocaleTimeString()}. FCM should deliver this even when the app is closed.`,
    type: 'info',
    target: 'all'
  };

  const options = {
    hostname: 'localhost',
    port: 3009,
    path: `/api/customers/${CUSTOMER_ID}/notifications`,
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`
    }
  };

  const req = http.request(options, (res) => {
    let data = '';

    res.on('data', (chunk) => {
      data += chunk;
    });

    res.on('end', () => {
      const result = JSON.parse(data);
      console.log('✅ Notification sent successfully:');
      console.log(JSON.stringify(result, null, 2));
    });
  });

  req.on('error', (error) => {
    console.error('❌ Error sending notification:', error);
  });

  req.write(JSON.stringify(notificationData));
  req.end();
}

// Function to login and get JWT token
function loginAndSendNotification() {
  const loginData = {
    username: 'admin',
    password: 'admin123'
  };

  const options = {
    hostname: 'localhost',
    port: 3009,
    path: '/api/auth/login',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    }
  };

  const req = http.request(options, (res) => {
    let data = '';

    res.on('data', (chunk) => {
      data += chunk;
    });

    res.on('end', () => {
      const result = JSON.parse(data);
      if (result.success && result.data && result.data.token) {
        console.log('🔐 Login successful');
        console.log('🚀 Sending test notification...');
        sendTestNotification(result.data.token);
      } else if (result.success && result.token) {
        console.log('🔐 Login successful');
        console.log('🚀 Sending test notification...');
        sendTestNotification(result.token);
      } else {
        console.error('❌ Login failed:', result);
      }
    });
  });

  req.on('error', (error) => {
    console.error('❌ Error during login:', error);
  });

  req.write(JSON.stringify(loginData));
  req.end();
}

// Instructions
console.log('====================================');
console.log('FCM NOTIFICATION TEST SCRIPT');
console.log('====================================');
console.log('');
console.log('This script will send a test notification to your app.');
console.log('');
console.log('To test notifications in different app states:');
console.log('');
console.log('1. FOREGROUND: Keep the app open and run this script');
console.log('2. BACKGROUND: Press home button (app in background) and run this script');
console.log('3. TERMINATED: Close the app completely (swipe away) and run this script');
console.log('');
console.log('Make sure:');
console.log('- Admin panel server is running (npm start)');
console.log('- Flutter app is running on device/emulator');
console.log('- You have registered FCM token (open app once)');
console.log('');
console.log('Starting test in 3 seconds...');
console.log('');

// Start the test
setTimeout(() => {
  loginAndSendNotification();
}, 3000);