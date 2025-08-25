const mysql = require('mysql2/promise');
require('dotenv').config();

async function checkFCMTokens() {
  const connection = await mysql.createConnection({
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'zerda_admin'
  });

  try {
    console.log('🔍 Checking FCM tokens in database...\n');
    
    const customerId = 'ffeee61a-8497-4c70-857e-c8f0efb13a2a';
    
    // Check all FCM tokens
    const [tokens] = await connection.execute(
      'SELECT * FROM fcm_tokens WHERE customer_id = ?',
      [customerId]
    );
    
    console.log(`Found ${tokens.length} FCM tokens for customer ${customerId}\n`);
    
    if (tokens.length > 0) {
      tokens.forEach((token, index) => {
        console.log(`Token ${index + 1}:`);
        console.log(`  ID: ${token.id}`);
        console.log(`  Token: ${token.fcm_token?.substring(0, 50)}...`);
        console.log(`  Device: ${token.device_id}`);
        console.log(`  Platform: ${token.platform}`);
        console.log(`  User ID: ${token.user_id || 'N/A'}`);
        console.log(`  User Email: ${token.user_email || 'N/A'}`);
        console.log(`  Authenticated: ${token.is_authenticated ? 'Yes' : 'No'}`);
        console.log(`  Active: ${token.is_active ? 'Yes' : 'No'}`);
        console.log(`  Created: ${token.created_at}`);
        console.log('');
      });
    } else {
      console.log('❌ No FCM tokens found');
      console.log('\nTrying to add a test token...');
      
      // Add a test FCM token
      const testToken = 'cMfZPdSoQa-OWThIl7DvZE:APA91bGJhmz8crOT-bodEcRyqq8Q8RfB4HfZ_hO3J3LYaS7ymW3p7na8UMlNcoD1h8XbD4dBdakpPuIgD9PQdKcN8EN-jdomTqj5I_4D3R5j1qotHpRt_sQ';
      
      await connection.execute(
        `INSERT INTO fcm_tokens (customer_id, fcm_token, device_id, platform, is_active, created_at) 
         VALUES (?, ?, ?, ?, 1, NOW())`,
        [customerId, testToken, 'test-device-001', 'android']
      );
      
      console.log('✅ Test FCM token added successfully');
    }
    
  } catch (error) {
    console.error('Error:', error.message);
  } finally {
    await connection.end();
  }
}

checkFCMTokens();