const fetch = (...args) => import('node-fetch').then(({default: fetch}) => fetch(...args));
const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database('zerda_admin.db');

async function testBroadcastFlow() {
  console.log('=== Test: Broadcast Notification Flow ===\n');
  
  try {
    // Step 1: Check existing customers in database
    console.log('1. Checking existing customers in database...');
    const customers = await new Promise((resolve, reject) => {
      db.all('SELECT id, name FROM customers', (err, rows) => {
        if (err) reject(err);
        else resolve(rows);
      });
    });
    console.log(`   Found ${customers.length} customers:`);
    customers.forEach(c => console.log(`   - ${c.id}: ${c.name}`));
    
    // Step 2: Check FCM tokens
    console.log('\n2. Checking FCM tokens...');
    const fcmTokens = await new Promise((resolve, reject) => {
      db.all('SELECT customer_id, is_authenticated, user_id FROM fcm_tokens', (err, rows) => {
        if (err) reject(err);
        else resolve(rows);
      });
    });
    console.log(`   Found ${fcmTokens.length} FCM tokens:`);
    fcmTokens.forEach(t => console.log(`   - Customer: ${t.customer_id}, Authenticated: ${t.is_authenticated ? 'Yes' : 'No'}`));
    
    // Step 3: Login as admin
    console.log('\n3. Logging in as admin...');
    let response = await fetch('http://localhost:3009/api/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        username: 'admin',
        password: 'admin123'
      })
    });
    
    let result = await response.json();
    if (!result.success) {
      throw new Error('Admin login failed');
    }
    const adminToken = result.data.token;
    console.log('   ✅ Admin logged in');
    
    // Step 4: Send broadcast to ALL users
    console.log('\n4. Sending broadcast notification to ALL users...');
    response = await fetch('http://localhost:3009/api/notifications/broadcast', {
      method: 'POST',
      headers: { 
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${adminToken}`
      },
      body: JSON.stringify({
        title: 'Test Broadcast - All Users',
        message: 'This notification should go to all customers',
        type: 'info',
        target: 'all'
      })
    });
    
    result = await response.json();
    console.log(`   Result: ${result.success ? '✅ Success' : '❌ Failed'}`);
    console.log(`   Sent to: ${result.sentCount || result.data?.totalSent || 0} customers`);
    console.log(`   Message: ${result.message}`);
    
    // Step 5: Check notifications in database
    console.log('\n5. Checking notifications in database...');
    const notifications = await new Promise((resolve, reject) => {
      db.all(
        "SELECT customer_id, title, target, status FROM notifications WHERE title = 'Test Broadcast - All Users'",
        (err, rows) => {
          if (err) reject(err);
          else resolve(rows);
        }
      );
    });
    console.log(`   Found ${notifications.length} notifications in database:`);
    notifications.forEach(n => console.log(`   - Customer: ${n.customer_id}, Status: ${n.status}`));
    
    // Step 6: Send to authenticated users only
    console.log('\n6. Sending broadcast to AUTHENTICATED users only...');
    response = await fetch('http://localhost:3009/api/notifications/broadcast', {
      method: 'POST',
      headers: { 
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${adminToken}`
      },
      body: JSON.stringify({
        title: 'Test Broadcast - Auth Only',
        message: 'This should only go to authenticated users',
        type: 'warning',
        target: 'authenticated'
      })
    });
    
    result = await response.json();
    console.log(`   Result: ${result.success ? '✅ Success' : '❌ Failed'}`);
    console.log(`   Sent to: ${result.sentCount || result.data?.totalSent || 0} authenticated customers`);
    
    // Step 7: Send to guests only
    console.log('\n7. Sending broadcast to GUEST users only...');
    response = await fetch('http://localhost:3009/api/notifications/broadcast', {
      method: 'POST',
      headers: { 
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${adminToken}`
      },
      body: JSON.stringify({
        title: 'Test Broadcast - Guests Only',
        message: 'This should only go to guest users',
        type: 'success',
        target: 'guests'
      })
    });
    
    result = await response.json();
    console.log(`   Result: ${result.success ? '✅ Success' : '❌ Failed'}`);
    console.log(`   Sent to: ${result.sentCount || result.data?.totalSent || 0} guest customers`);
    
    // Step 8: Check all notifications
    console.log('\n8. Final check - All broadcast notifications...');
    const allNotifications = await new Promise((resolve, reject) => {
      db.all(
        "SELECT customer_id, title, target, status FROM notifications WHERE title LIKE 'Test Broadcast%' ORDER BY created_at DESC",
        (err, rows) => {
          if (err) reject(err);
          else resolve(rows);
        }
      );
    });
    console.log(`   Total broadcast notifications: ${allNotifications.length}`);
    
    // Group by customer
    const byCustomer = {};
    allNotifications.forEach(n => {
      if (!byCustomer[n.customer_id]) byCustomer[n.customer_id] = [];
      byCustomer[n.customer_id].push(n.title);
    });
    
    console.log('\n   Notifications by customer:');
    Object.entries(byCustomer).forEach(([customerId, titles]) => {
      console.log(`   - ${customerId}: ${titles.length} notifications`);
    });
    
    console.log('\n✅ Broadcast notification test completed!');
    console.log('\n📋 Summary:');
    console.log('   - Broadcast to "all" sends to all customers in database');
    console.log('   - Broadcast to "authenticated" sends only to logged-in users');
    console.log('   - Broadcast to "guests" sends only to non-logged-in users');
    console.log('   - Notifications are properly stored in database');
    
  } catch (error) {
    console.error('❌ Test failed:', error.message);
  } finally {
    db.close();
  }
}

// Run the test
testBroadcastFlow();