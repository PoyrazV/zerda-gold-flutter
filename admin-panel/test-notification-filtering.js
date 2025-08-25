const sqlite3 = require('sqlite3').verbose();
const path = require('path');

const DB_PATH = path.join(__dirname, 'zerda_admin.db');
const db = new sqlite3.Database(DB_PATH);

const CUSTOMER_ID = 'ffeee61a-8497-4c70-857e-c8f0efb13a2a';

console.log('🧪 Testing Notification Filtering...\n');

// Function to check FCM tokens
function checkTokens() {
  return new Promise((resolve) => {
    console.log('📊 Current FCM Tokens:');
    console.log('=' .repeat(80));
    
    db.all(
      'SELECT fcm_token, user_id, user_email, is_authenticated FROM fcm_tokens WHERE customer_id = ?',
      [CUSTOMER_ID],
      (err, tokens) => {
        if (err) {
          console.error('Error fetching tokens:', err);
          resolve();
          return;
        }
        
        if (!tokens || tokens.length === 0) {
          console.log('No FCM tokens found');
        } else {
          tokens.forEach((token, index) => {
            console.log(`\nToken #${index + 1}:`);
            console.log(`  FCM Token: ${token.fcm_token.substring(0, 30)}...`);
            console.log(`  User ID: ${token.user_id || 'NULL'}`);
            console.log(`  User Email: ${token.user_email || 'NULL'}`);
            console.log(`  Is Authenticated: ${token.is_authenticated ? 'YES' : 'NO'}`);
            console.log(`  Type: ${token.is_authenticated ? 'AUTHENTICATED USER' : 'GUEST USER'}`);
          });
        }
        
        console.log('\n' + '=' .repeat(80));
        resolve(tokens);
      }
    );
  });
}

// Function to test filtering
function testFiltering(tokens) {
  return new Promise((resolve) => {
    if (!tokens || tokens.length === 0) {
      console.log('\n⚠️ No tokens to test filtering');
      resolve();
      return;
    }
    
    console.log('\n🔍 Testing Notification Filters:');
    console.log('=' .repeat(80));
    
    // Test authenticated filter
    const authenticatedQuery = 'SELECT COUNT(*) as count FROM fcm_tokens WHERE customer_id = ? AND is_authenticated = 1 AND user_id IS NOT NULL AND user_id != ""';
    
    db.get(authenticatedQuery, [CUSTOMER_ID], (err, result) => {
      if (err) {
        console.error('Error testing authenticated filter:', err);
      } else {
        console.log(`\n✅ Authenticated Users Filter:`);
        console.log(`   Query: WHERE is_authenticated = 1 AND user_id IS NOT NULL AND user_id != ""`);
        console.log(`   Result: ${result.count} token(s) would receive authenticated notifications`);
      }
      
      // Test guest filter
      const guestQuery = 'SELECT COUNT(*) as count FROM fcm_tokens WHERE customer_id = ? AND is_authenticated = 0 AND (user_id IS NULL OR user_id = "")';
      
      db.get(guestQuery, [CUSTOMER_ID], (err, result) => {
        if (err) {
          console.error('Error testing guest filter:', err);
        } else {
          console.log(`\n✅ Guest Users Filter:`);
          console.log(`   Query: WHERE is_authenticated = 0 AND (user_id IS NULL OR user_id = "")`);
          console.log(`   Result: ${result.count} token(s) would receive guest notifications`);
        }
        
        // Test all users filter
        const allQuery = 'SELECT COUNT(*) as count FROM fcm_tokens WHERE customer_id = ?';
        
        db.get(allQuery, [CUSTOMER_ID], (err, result) => {
          if (err) {
            console.error('Error testing all filter:', err);
          } else {
            console.log(`\n✅ All Users Filter:`);
            console.log(`   Query: No additional filter`);
            console.log(`   Result: ${result.count} token(s) would receive notifications`);
          }
          
          console.log('\n' + '=' .repeat(80));
          resolve();
        });
      });
    });
  });
}

// Function to simulate scenarios
function simulateScenarios() {
  console.log('\n🎭 Simulating Notification Scenarios:');
  console.log('=' .repeat(80));
  
  // Get current tokens and categorize them
  db.all(
    'SELECT * FROM fcm_tokens WHERE customer_id = ?',
    [CUSTOMER_ID],
    (err, tokens) => {
      if (err || !tokens) {
        console.error('Error getting tokens for simulation:', err);
        return;
      }
      
      const authenticatedTokens = tokens.filter(t => t.is_authenticated === 1 && t.user_id && t.user_id !== '');
      const guestTokens = tokens.filter(t => t.is_authenticated === 0 && (!t.user_id || t.user_id === ''));
      
      console.log('\n📋 Scenario 1: Sending to GUEST users');
      console.log(`   Expected recipients: ${guestTokens.length} guest token(s)`);
      if (guestTokens.length > 0) {
        console.log('   Recipients would be:');
        guestTokens.forEach(t => {
          console.log(`     - Token ending in ...${t.fcm_token.slice(-10)}`);
        });
      }
      
      console.log('\n📋 Scenario 2: Sending to AUTHENTICATED users');
      console.log(`   Expected recipients: ${authenticatedTokens.length} authenticated token(s)`);
      if (authenticatedTokens.length > 0) {
        console.log('   Recipients would be:');
        authenticatedTokens.forEach(t => {
          console.log(`     - ${t.user_email || 'Unknown'} (Token ending in ...${t.fcm_token.slice(-10)})`);
        });
      }
      
      console.log('\n📋 Scenario 3: Sending to ALL users');
      console.log(`   Expected recipients: ${tokens.length} total token(s)`);
      
      console.log('\n' + '=' .repeat(80));
      console.log('\n✅ Test Complete!\n');
      
      // Check for potential issues
      const problematicTokens = tokens.filter(t => {
        // Check for inconsistent states
        if (t.is_authenticated === 1 && (!t.user_id || t.user_id === '')) {
          return true; // Marked as authenticated but no user ID
        }
        if (t.is_authenticated === 0 && t.user_id && t.user_id !== '') {
          return true; // Marked as guest but has user ID
        }
        return false;
      });
      
      if (problematicTokens.length > 0) {
        console.log('⚠️ WARNING: Found inconsistent token states:');
        problematicTokens.forEach(t => {
          console.log(`   - Token ...${t.fcm_token.slice(-10)}: is_authenticated=${t.is_authenticated}, user_id="${t.user_id || 'NULL'}"`);
        });
        console.log('   These tokens may cause unexpected behavior!');
      } else {
        console.log('✅ All tokens have consistent states.');
      }
      
      db.close();
    }
  );
}

// Run tests
async function runTests() {
  const tokens = await checkTokens();
  await testFiltering(tokens);
  simulateScenarios();
}

runTests();