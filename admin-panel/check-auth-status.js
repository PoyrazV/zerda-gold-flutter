const sqlite3 = require('sqlite3').verbose();
const path = require('path');

const DB_PATH = path.join(__dirname, 'zerda_admin.db');
const db = new sqlite3.Database(DB_PATH);

const CUSTOMER_ID = 'ffeee61a-8497-4c70-857e-c8f0efb13a2a';

console.log('\n🔍 Checking Authentication Status of FCM Tokens...\n');
console.log('=' .repeat(80));

// Check all FCM tokens
db.all(
  `SELECT 
    fcm_token, 
    user_id, 
    user_email, 
    is_authenticated,
    platform,
    device_id,
    created_at,
    updated_at
  FROM fcm_tokens 
  WHERE customer_id = ?
  ORDER BY updated_at DESC`,
  [CUSTOMER_ID],
  (err, tokens) => {
    if (err) {
      console.error('Error:', err);
      db.close();
      return;
    }
    
    console.log(`Found ${tokens ? tokens.length : 0} FCM token(s)\n`);
    
    if (tokens && tokens.length > 0) {
      tokens.forEach((token, index) => {
        console.log(`Token #${index + 1}:`);
        console.log(`  FCM Token: ${token.fcm_token.substring(0, 40)}...`);
        console.log(`  User ID: ${token.user_id || '[NULL]'}`);
        console.log(`  User Email: ${token.user_email || '[NULL]'}`);
        console.log(`  Is Authenticated: ${token.is_authenticated} (${token.is_authenticated === 1 ? 'YES' : 'NO'})`);
        console.log(`  Platform: ${token.platform || '[NULL]'}`);
        console.log(`  Device ID: ${token.device_id || '[NULL]'}`);
        console.log(`  Created: ${token.created_at}`);
        console.log(`  Updated: ${token.updated_at}`);
        
        // Determine status
        if (token.is_authenticated === 1 && token.user_id) {
          console.log(`  ✅ STATUS: AUTHENTICATED USER - Will receive authenticated notifications`);
        } else if (token.is_authenticated === 0 && (!token.user_id || token.user_id === '')) {
          console.log(`  👤 STATUS: GUEST USER - Will receive guest notifications`);
        } else {
          console.log(`  ⚠️ STATUS: INCONSISTENT STATE!`);
          console.log(`     Problem: is_authenticated=${token.is_authenticated} but user_id="${token.user_id}"`);
        }
        console.log('-' .repeat(80));
      });
    } else {
      console.log('No FCM tokens found in database.');
    }
    
    // Check notification sending logic
    console.log('\n📊 Testing Notification Queries:\n');
    
    // Test authenticated query
    db.all(
      `SELECT fcm_token, user_email FROM fcm_tokens 
       WHERE customer_id = ? 
       AND is_authenticated = 1 
       AND user_id IS NOT NULL 
       AND user_id != ""`,
      [CUSTOMER_ID],
      (err, authTokens) => {
        if (err) {
          console.error('Error testing auth query:', err);
        } else {
          console.log(`Authenticated User Query Results: ${authTokens.length} token(s)`);
          if (authTokens.length > 0) {
            authTokens.forEach(t => {
              console.log(`  - ${t.user_email || 'Unknown'} (${t.fcm_token.substring(0, 20)}...)`);
            });
          } else {
            console.log('  ❌ No authenticated users found - authenticated notifications won\'t be sent!');
          }
        }
        
        // Test guest query
        db.all(
          `SELECT fcm_token FROM fcm_tokens 
           WHERE customer_id = ? 
           AND is_authenticated = 0 
           AND (user_id IS NULL OR user_id = "")`,
          [CUSTOMER_ID],
          (err, guestTokens) => {
            if (err) {
              console.error('Error testing guest query:', err);
            } else {
              console.log(`\nGuest User Query Results: ${guestTokens.length} token(s)`);
              if (guestTokens.length > 0) {
                guestTokens.forEach(t => {
                  console.log(`  - Guest (${t.fcm_token.substring(0, 20)}...)`);
                });
              }
            }
            
            console.log('\n' + '=' .repeat(80));
            console.log('\n💡 SOLUTION:');
            console.log('If authenticated notifications are not working:');
            console.log('1. Make sure you are logged in on the Flutter app');
            console.log('2. Check that login updates the FCM token with user info');
            console.log('3. Verify is_authenticated is set to 1 after login');
            console.log('4. Restart the app after login to ensure token is updated\n');
            
            db.close();
          }
        );
      }
    );
  }
);