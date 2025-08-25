const fetch = (...args) => import('node-fetch').then(({default: fetch}) => fetch(...args));

async function testProfileFlow() {
  const API_URL = 'http://localhost:3009/api/mobile/auth';
  
  console.log('🧪 Testing Profile Data Flow');
  console.log('============================');
  
  try {
    // Test 1: Login with demo user
    console.log('\n📝 Test 1: Login with demo user...');
    
    const loginResponse = await fetch(`${API_URL}/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: 'demo@zerda.com',
        password: 'demo123'
      })
    });
    
    const loginData = await loginResponse.json();
    
    if (loginData.success) {
      console.log('✅ Login successful!');
      console.log(`   User: ${loginData.data.user.full_name}`);
      console.log(`   Email: ${loginData.data.user.email}`);
      console.log(`   User ID: ${loginData.data.user.id}`);
      
      const token = loginData.data.token;
      
      // Test 2: Verify token and get user data
      console.log('\n🔐 Test 2: Verifying user data via token...');
      const verifyResponse = await fetch(`${API_URL}/verify`, {
        method: 'GET',
        headers: { 
          'Authorization': `Bearer ${token}`
        }
      });
      
      const verifyData = await verifyResponse.json();
      
      if (verifyData.success) {
        console.log('✅ User data retrieved successfully!');
        console.log(`   Profile data:`);
        console.log(`   - Name: ${verifyData.data.user.full_name}`);
        console.log(`   - Email: ${verifyData.data.user.email}`);
        console.log(`   - ID: ${verifyData.data.user.id}`);
        console.log(`   - Verified: ${verifyData.data.user.is_verified}`);
      } else {
        console.log('❌ Failed to retrieve user data:', verifyData.error);
      }
      
      // Test 3: Login with test user
      console.log('\n📝 Test 3: Login with test user...');
      
      const testLoginResponse = await fetch(`${API_URL}/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: 'test@zerda.com',
          password: 'test123'
        })
      });
      
      const testLoginData = await testLoginResponse.json();
      
      if (testLoginData.success) {
        console.log('✅ Test user login successful!');
        console.log(`   User: ${testLoginData.data.user.full_name}`);
        console.log(`   Email: ${testLoginData.data.user.email}`);
      } else {
        console.log('❌ Test user login failed:', testLoginData.error);
      }
      
      console.log('\n============================');
      console.log('🎉 Profile data flow tests completed!');
      console.log('\n📱 In the Flutter app:');
      console.log('   1. Login with demo@zerda.com / demo123');
      console.log('   2. Navigate to Profile screen');
      console.log('   3. You should see "Demo User" and "demo@zerda.com"');
      console.log('   4. Logout and login with test@zerda.com / test123');
      console.log('   5. Profile should show "Test User" and "test@zerda.com"');
      
    } else {
      console.log('❌ Login failed:', loginData.error);
    }
    
  } catch (error) {
    console.error('❌ Test error:', error.message);
  }
}

// Run the test
testProfileFlow();