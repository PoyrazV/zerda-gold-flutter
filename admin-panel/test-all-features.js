const fetch = require('node-fetch');

async function testAllFeatures() {
  console.log('🧪 Testing all admin panel features...\n');
  
  const baseUrl = 'http://localhost:3009';
  const customerId = 'ffeee61a-8497-4c70-857e-c8f0efb13a2a';
  let token = '';
  
  // 1. Login
  console.log('1️⃣ Testing Login...');
  try {
    const loginResponse = await fetch(`${baseUrl}/api/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        username: 'admin',
        password: 'admin123'
      })
    });
    const loginResult = await loginResponse.json();
    if (loginResult.success) {
      token = loginResult.data.token;
      console.log('✅ Login successful\n');
    } else {
      console.log('❌ Login failed:', loginResult.error);
      return;
    }
  } catch (error) {
    console.error('❌ Login error:', error.message);
    return;
  }
  
  // 2. Test Feature Toggle
  console.log('2️⃣ Testing Feature Toggle...');
  try {
    // Get current features
    const getFeaturesResponse = await fetch(`${baseUrl}/api/customers/${customerId}/features`, {
      headers: { 'Authorization': `Bearer ${token}` }
    });
    const features = await getFeaturesResponse.json();
    console.log('   Current features:', features.success ? 'Loaded' : 'Failed');
    
    // Toggle a feature
    const toggleResponse = await fetch(`${baseUrl}/api/customers/${customerId}/features/calculator`, {
      method: 'POST',
      headers: { 
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}` 
      },
      body: JSON.stringify({ enabled: false })
    });
    const toggleResult = await toggleResponse.json();
    console.log('   Toggle calculator:', toggleResult.success ? '✅ Success' : '❌ Failed');
    
    // Toggle back
    const toggleBackResponse = await fetch(`${baseUrl}/api/customers/${customerId}/features/calculator`, {
      method: 'POST',
      headers: { 
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}` 
      },
      body: JSON.stringify({ enabled: true })
    });
    const toggleBackResult = await toggleBackResponse.json();
    console.log('   Toggle back:', toggleBackResult.success ? '✅ Success' : '❌ Failed\n');
  } catch (error) {
    console.error('❌ Feature toggle error:', error.message, '\n');
  }
  
  // 3. Test Theme Customization
  console.log('3️⃣ Testing Theme Customization...');
  try {
    // Get current theme
    const getThemeResponse = await fetch(`${baseUrl}/api/customers/${customerId}/theme`, {
      headers: { 'Authorization': `Bearer ${token}` }
    });
    const currentTheme = await getThemeResponse.json();
    console.log('   Current theme:', currentTheme.success ? 'Loaded' : 'Failed');
    
    // Update theme
    const updateThemeResponse = await fetch(`${baseUrl}/api/customers/${customerId}/theme`, {
      method: 'POST',
      headers: { 
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}` 
      },
      body: JSON.stringify({
        primaryColor: '#FF0000',
        secondaryColor: '#00FF00',
        accentColor: '#0000FF'
      })
    });
    const updateResult = await updateThemeResponse.json();
    console.log('   Update theme:', updateResult.success ? '✅ Success' : '❌ Failed');
    
    // Reset theme
    const resetThemeResponse = await fetch(`${baseUrl}/api/customers/${customerId}/theme`, {
      method: 'POST',
      headers: { 
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}` 
      },
      body: JSON.stringify({
        primaryColor: '#18214F',
        secondaryColor: '#D4B896',
        accentColor: '#FF6B6B'
      })
    });
    const resetResult = await resetThemeResponse.json();
    console.log('   Reset theme:', resetResult.success ? '✅ Success' : '❌ Failed\n');
  } catch (error) {
    console.error('❌ Theme error:', error.message, '\n');
  }
  
  // 4. Test Notification Sending
  console.log('4️⃣ Testing Notification Sending...');
  try {
    const notificationResponse = await fetch(`${baseUrl}/api/customers/${customerId}/notifications`, {
      method: 'POST',
      headers: { 
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}` 
      },
      body: JSON.stringify({
        title: 'Test Bildirimi',
        message: 'Bu bir test bildirimidir',
        type: 'info',
        target: 'all'
      })
    });
    const notificationResult = await notificationResponse.json();
    console.log('   Send notification:', notificationResult.success ? '✅ Success' : `❌ Failed: ${notificationResult.error}`);
    
    // Get notification history
    const historyResponse = await fetch(`${baseUrl}/api/customers/${customerId}/notifications`, {
      headers: { 'Authorization': `Bearer ${token}` }
    });
    const history = await historyResponse.json();
    console.log('   Notification history:', history.success ? `Loaded (${history.data.length} notifications)` : 'Failed\n');
  } catch (error) {
    console.error('❌ Notification error:', error.message, '\n');
  }
  
  // 5. Test Gold Price API
  console.log('5️⃣ Testing Gold Price API...');
  try {
    const goldResponse = await fetch(`${baseUrl}/api/gold-price/current`);
    const goldData = await goldResponse.json();
    if (goldData.success) {
      console.log('   ✅ Gold price loaded:');
      console.log(`      - Ounce (USD): $${goldData.data.ounce_price_usd.toFixed(2)}`);
      console.log(`      - Gram (USD): $${goldData.data.gram_price_usd.toFixed(2)}`);
      console.log(`      - Source: ${goldData.data.source}\n`);
    } else {
      console.log('   ❌ Failed to load gold price\n');
    }
  } catch (error) {
    console.error('❌ Gold price error:', error.message, '\n');
  }
  
  // 6. Test Gold Products Management
  console.log('6️⃣ Testing Gold Products Management...');
  try {
    // Add a gold product
    const addProductResponse = await fetch(`${baseUrl}/api/customers/${customerId}/gold-products`, {
      method: 'POST',
      headers: { 
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}` 
      },
      body: JSON.stringify({
        name: 'Test Altın',
        weight: 10,
        unit: 'gram',
        purity: 0.995,
        buy_price: 2000,
        sell_price: 2100,
        stock_quantity: 100
      })
    });
    const addResult = await addProductResponse.json();
    const productId = addResult.productId;
    console.log('   Add product:', addResult.success ? '✅ Success' : '❌ Failed');
    
    // Get all products
    const getProductsResponse = await fetch(`${baseUrl}/api/customers/${customerId}/gold-products`, {
      headers: { 'Authorization': `Bearer ${token}` }
    });
    const products = await getProductsResponse.json();
    console.log('   Get products:', products.success ? `Loaded (${products.data?.length || 0} products)` : 'Failed');
    
    // Delete test product
    if (productId) {
      const deleteResponse = await fetch(`${baseUrl}/api/gold-products/${productId}`, {
        method: 'DELETE',
        headers: { 'Authorization': `Bearer ${token}` }
      });
      const deleteResult = await deleteResponse.json();
      console.log('   Delete product:', deleteResult.success ? '✅ Success' : '❌ Failed');
    }
  } catch (error) {
    console.error('❌ Gold products error:', error.message);
  }
  
  console.log('\n🎉 All tests completed!');
}

testAllFeatures().catch(console.error);