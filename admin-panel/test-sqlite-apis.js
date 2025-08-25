const fetch = require('node-fetch');

async function testSQLiteAPIs() {
  console.log('🔍 Testing SQLite Admin Panel APIs...\n');
  
  // Login first
  const loginResponse = await fetch('http://localhost:3009/api/auth/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username: 'admin', password: 'admin123' })
  });
  const loginResult = await loginResponse.json();
  
  if (!loginResult.success) {
    console.log('❌ Login failed:', loginResult.error);
    return;
  }
  
  const token = loginResult.data.token;
  const customerId = 'ffeee61a-8497-4c70-857e-c8f0efb13a2a';
  
  console.log('✅ Login successful\n');
  
  // Test customers API
  try {
    const customersResponse = await fetch('http://localhost:3009/api/customers', {
      headers: { 'Authorization': `Bearer ${token}` }
    });
    const customers = await customersResponse.json();
    console.log('📊 Customers API:', customers.success ? '✅ Working' : '❌ Failed');
    if (customers.success) {
      console.log(`   Found ${customers.data?.length || 0} customers`);
      if (customers.data?.length > 0) {
        console.log(`   Customer: ${customers.data[0].display_name}`);
      }
    } else {
      console.log('   Error:', customers.error);
    }
  } catch (e) {
    console.log('📊 Customers API: ❌ Error -', e.message);
  }
  
  // Test features API
  try {
    const featuresResponse = await fetch(`http://localhost:3009/api/customers/${customerId}/features`, {
      headers: { 'Authorization': `Bearer ${token}` }
    });
    const features = await featuresResponse.json();
    console.log('🔧 Features API:', features.success ? '✅ Working' : '❌ Failed');
    if (features.success) {
      console.log(`   Found ${Object.keys(features.features).length} features`);
    } else {
      console.log('   Error:', features.error);
    }
  } catch (e) {
    console.log('🔧 Features API: ❌ Error -', e.message);
  }
  
  // Test theme API
  try {
    const themeResponse = await fetch(`http://localhost:3009/api/customers/${customerId}/theme`, {
      headers: { 'Authorization': `Bearer ${token}` }
    });
    const theme = await themeResponse.json();
    console.log('🎨 Theme API:', theme.success ? '✅ Working' : '❌ Failed');
    if (!theme.success) {
      console.log('   Error:', theme.error);
    }
  } catch (e) {
    console.log('🎨 Theme API: ❌ Error -', e.message);
  }
  
  // Test notifications API
  try {
    const notifResponse = await fetch(`http://localhost:3009/api/customers/${customerId}/notifications`, {
      headers: { 'Authorization': `Bearer ${token}` }
    });
    const notifications = await notifResponse.json();
    console.log('📧 Notifications API:', notifications.success ? '✅ Working' : '❌ Failed');
    if (notifications.success) {
      console.log(`   Found ${notifications.data?.length || 0} notifications`);
    } else {
      console.log('   Error:', notifications.error);
    }
  } catch (e) {
    console.log('📧 Notifications API: ❌ Error -', e.message);
  }
  
  // Test gold products API
  try {
    const goldResponse = await fetch(`http://localhost:3009/api/customers/${customerId}/gold-products`, {
      headers: { 'Authorization': `Bearer ${token}` }
    });
    const goldProducts = await goldResponse.json();
    console.log('🏅 Gold Products API:', goldProducts.success ? '✅ Working' : '❌ Failed');
    if (goldProducts.success) {
      console.log(`   Found ${goldProducts.data?.length || 0} gold products`);
    } else {
      console.log('   Error:', goldProducts.error);
    }
  } catch (e) {
    console.log('🏅 Gold Products API: ❌ Error -', e.message);
  }
}

testSQLiteAPIs().catch(console.error);