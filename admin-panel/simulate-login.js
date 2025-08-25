const sqlite3 = require('sqlite3').verbose();
const path = require('path');

const dbPath = path.join(__dirname, 'zerda_admin.db');
const db = new sqlite3.Database(dbPath);

console.log('🔐 Simulating Login Token Update');
console.log('=================================\n');

async function simulateLogin(email = 'poyraz@gmail.com') {
  const customerId = 'ffeee61a-8497-4c70-857e-c8f0efb13a2a';
  
  // Get current token
  db.get(
    `SELECT * FROM fcm_tokens 
     WHERE customer_id = ? 
     ORDER BY updated_at DESC 
     LIMIT 1`,
    [customerId],
    (err, token) => {
      if (err) {
        console.error('Error:', err);
        db.close();
        return;
      }
      
      if (!token) {
        console.log('❌ No token found');
        db.close();
        return;
      }
      
      console.log('📱 Current Token:');
      console.log(`   Device: ${token.device_id}`);
      console.log(`   User: ${token.user_email || 'Guest'}`);
      console.log(`   Authenticated: ${token.is_authenticated ? 'YES' : 'NO'}\n`);
      
      if (token.is_authenticated) {
        console.log('⚠️  Already authenticated!');
        db.close();
        return;
      }
      
      // Generate a user ID for the simulation
      const userId = '67b7a87f-b965-4710-8229-f901c4bcb40f';
      
      console.log(`🔄 Simulating login as ${email}...\n`);
      
      // Update token to authenticated mode
      db.run(
        `UPDATE fcm_tokens 
         SET user_id = ?,
             user_email = ?,
             is_authenticated = 1,
             updated_at = CURRENT_TIMESTAMP
         WHERE customer_id = ? AND device_id = ?`,
        [userId, email, customerId, token.device_id],
        function(err) {
          if (err) {
            console.error('Update error:', err);
            db.close();
            return;
          }
          
          console.log('✅ Token updated successfully!');
          console.log(`   ${this.changes} row(s) affected\n`);
          
          // Verify the update
          db.get(
            `SELECT * FROM fcm_tokens 
             WHERE customer_id = ? AND device_id = ?`,
            [customerId, token.device_id],
            (err, updated) => {
              if (err) {
                console.error('Verification error:', err);
                db.close();
                return;
              }
              
              console.log('📊 New Token Status:');
              console.log(`   Device: ${updated.device_id} (preserved ✅)`);
              console.log(`   User: ${updated.user_email} (set ✅)`);
              console.log(`   User ID: ${updated.user_id} (set ✅)`);
              console.log(`   Authenticated: ${updated.is_authenticated ? 'YES' : 'NO'} (authenticated ✅)`);
              console.log(`   FCM Token: ${updated.fcm_token.substring(0, 30)}... (preserved ✅)\n`);
              
              console.log('─'.repeat(50));
              console.log('\n✨ Login simulation complete!');
              console.log(`   The token is now authenticated as ${email}.`);
              console.log('   Run notification tests to verify targeting.\n');
              
              console.log('Next steps:');
              console.log('1. Run: node test-guest-vs-auth.js');
              console.log('2. Verify authenticated notifications are received');
              console.log('3. Verify guest notifications are NOT received');
              
              db.close();
            }
          );
        }
      );
    }
  );
}

// Check command line arguments
const args = process.argv.slice(2);
const email = args[0] || 'poyraz@gmail.com';

simulateLogin(email);