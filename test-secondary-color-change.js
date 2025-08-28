// Test script to change secondary color via Admin Panel API
const http = require('http');

// Test changing secondary color to different values
const testColors = [
  { color: '#FFD700', name: 'Gold' },
  { color: '#FF69B4', name: 'Hot Pink' },
  { color: '#00CED1', name: 'Dark Turquoise' },
  { color: '#E8D095', name: 'Original Golden' },
  { color: '#9370DB', name: 'Medium Purple' },
  { color: '#FFA500', name: 'Orange' }
];

const customerId = 'ffeee61a-8497-4c70-857e-c8f0efb13a2a';

async function changeSecondaryColor(colorHex, colorName) {
  const data = JSON.stringify({
    theme_type: 'dark',
    primary_color: '#18214F',  // Keep primary color constant
    secondary_color: colorHex,  // Change secondary color
    accent_color: '#FF6B6B',
    background_color: '#FFFFFF',
    text_color: '#000000',
    success_color: '#4CAF50',
    error_color: '#F44336',
    warning_color: '#FF9800',
    font_family: 'Inter',
    font_size_scale: 1.0
  });

  const options = {
    hostname: 'localhost',
    port: 3009,
    path: `/api/customers/${customerId}/theme`,
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': data.length,
      'Authorization': 'Bearer test-token' // Replace with actual token if auth is enabled
    }
  };

  return new Promise((resolve, reject) => {
    const req = http.request(options, (res) => {
      let responseData = '';

      res.on('data', (chunk) => {
        responseData += chunk;
      });

      res.on('end', () => {
        if (res.statusCode === 200) {
          console.log(`✅ Successfully changed secondary color to ${colorName} (${colorHex})`);
          resolve(JSON.parse(responseData));
        } else {
          console.error(`❌ Failed to change color: ${res.statusCode}`);
          reject(new Error(`HTTP ${res.statusCode}: ${responseData}`));
        }
      });
    });

    req.on('error', (e) => {
      console.error(`❌ Error: ${e.message}`);
      reject(e);
    });

    req.write(data);
    req.end();
  });
}

async function testSecondaryColorChanges() {
  console.log('🎨 Testing Secondary Color Changes from Admin Panel\n');
  console.log('📱 Make sure the mobile app is running and observing changes\n');
  console.log('🔍 Watch for changes in:\n');
  console.log('   - Tab indicators and selected labels');
  console.log('   - Selected text in filters and segments');
  console.log('   - Swap icons and other accent colors\n');
  
  for (const testColor of testColors) {
    console.log(`\n🔄 Changing secondary color to ${testColor.name}...`);
    try {
      await changeSecondaryColor(testColor.color, testColor.name);
      console.log('⏳ Waiting 5 seconds for app to sync...');
      await new Promise(resolve => setTimeout(resolve, 5000));
    } catch (error) {
      console.error(`Failed to change to ${testColor.name}:`, error.message);
    }
  }
  
  console.log('\n✅ Test completed! Check the mobile app to verify secondary color changes.');
  console.log('🎯 All golden/amber UI elements should now change together!');
}

// Run the test
testSecondaryColorChanges();