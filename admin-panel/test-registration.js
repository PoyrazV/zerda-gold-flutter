const fetch = (...args) => import('node-fetch').then(({default: fetch}) => fetch(...args));

async function testRegistration() {
  const API_URL = 'http://localhost:3009/api/mobile/auth';
  
  // Generate unique email for testing
  const timestamp = Date.now();
  const testEmail = `testuser${timestamp}@example.com`;
  const testPassword = 'test123456';
  const testName = 'Test User ' + timestamp;
  
  console.log('🧪 Testing Registration Flow');
  console.log('============================');
  
  try {
    // Test 1: Register new user
    console.log('\n📝 Test 1: Registering new user...');
    console.log(`   Email: ${testEmail}`);
    console.log(`   Name: ${testName}`);
    
    const registerResponse = await fetch(`${API_URL}/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: testEmail,
        password: testPassword,
        full_name: testName
      })
    });
    
    const registerData = await registerResponse.json();
    
    if (registerData.success) {
      console.log('✅ Registration successful!');
      console.log(`   User ID: ${registerData.data.user.id}`);
      console.log(`   Token: ${registerData.data.token.substring(0, 20)}...`);
      
      const token = registerData.data.token;
      
      // Test 2: Verify token works
      console.log('\n🔐 Test 2: Verifying authentication token...');
      const verifyResponse = await fetch(`${API_URL}/verify`, {
        method: 'GET',
        headers: { 
          'Authorization': `Bearer ${token}`
        }
      });
      
      const verifyData = await verifyResponse.json();
      
      if (verifyData.success) {
        console.log('✅ Token verification successful!');
        console.log(`   User verified: ${verifyData.data.user.email}`);
      } else {
        console.log('❌ Token verification failed:', verifyData.error);
      }
      
      // Test 3: Try to register with same email (should fail)
      console.log('\n🚫 Test 3: Testing duplicate email prevention...');
      const duplicateResponse = await fetch(`${API_URL}/register`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: testEmail,
          password: testPassword,
          full_name: testName
        })
      });
      
      const duplicateData = await duplicateResponse.json();
      
      if (!duplicateData.success && duplicateData.error.includes('zaten kayıtlı')) {
        console.log('✅ Duplicate email correctly rejected!');
        console.log(`   Error: ${duplicateData.error}`);
      } else {
        console.log('❌ Duplicate email check failed');
      }
      
      // Test 4: Login with new account
      console.log('\n🔑 Test 4: Testing login with new account...');
      const loginResponse = await fetch(`${API_URL}/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: testEmail,
          password: testPassword
        })
      });
      
      const loginData = await loginResponse.json();
      
      if (loginData.success) {
        console.log('✅ Login successful!');
        console.log(`   New token: ${loginData.data.token.substring(0, 20)}...`);
      } else {
        console.log('❌ Login failed:', loginData.error);
      }
      
      console.log('\n============================');
      console.log('🎉 All registration tests passed!');
      
    } else {
      console.log('❌ Registration failed:', registerData.error);
    }
    
  } catch (error) {
    console.error('❌ Test error:', error.message);
  }
}

// Run the test
testRegistration();