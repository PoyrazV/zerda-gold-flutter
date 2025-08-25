const sqlite3 = require('sqlite3').verbose();
const path = require('path');

const dbPath = path.join(__dirname, 'zerda_admin.db');
const db = new sqlite3.Database(dbPath, sqlite3.OPEN_READONLY);

console.log('🔍 Checking FCM tokens and user associations...\n');

// Check all FCM tokens
db.all(
  `SELECT 
    fcm_token,
    user_id,
    user_email,
    is_authenticated,
    customer_id,
    platform,
    device_id,
    created_at,
    updated_at
   FROM fcm_tokens
   ORDER BY created_at DESC`,
  [],
  (err, tokens) => {
    if (err) {
      console.error('Error:', err);
      return;
    }

    console.log(`Found ${tokens.length} FCM token(s):\n`);
    
    tokens.forEach((token, index) => {
      console.log(`Token #${index + 1}:`);
      console.log('  FCM Token:', token.fcm_token ? token.fcm_token.substring(0, 40) + '...' : 'NULL');
      console.log('  User ID:', token.user_id || 'NULL (Guest)');
      console.log('  User Email:', token.user_email || 'NULL (Guest)');
      console.log('  Is Authenticated:', token.is_authenticated ? 'YES' : 'NO');
      console.log('  Customer ID:', token.customer_id);
      console.log('  Platform:', token.platform);
      console.log('  Device ID:', token.device_id || 'NULL');
      console.log('  Created:', token.created_at);
      console.log('  Updated:', token.updated_at);
      console.log('');
    });

    // Check users
    console.log('\n📱 Checking registered users:\n');
    db.all(
      `SELECT id, email FROM users`,
      [],
      (err, users) => {
        if (err) {
          console.error('Error:', err);
          return;
        }
        
        if (users.length === 0) {
          console.log('No users found for this customer.');
        } else {
          users.forEach(user => {
            console.log(`User: ${user.email} - ID: ${user.id}`);
          });
        }

        // Check mobile sessions
        console.log('\n🔐 Checking mobile sessions:\n');
        db.all(
          `SELECT 
            user_id,
            fcm_token,
            device_id,
            platform,
            created_at
           FROM mobile_sessions
           WHERE expires_at > datetime('now')
           ORDER BY created_at DESC`,
          [],
          (err, sessions) => {
            if (err) {
              console.error('Error:', err);
              db.close();
              return;
            }
            
            if (sessions.length === 0) {
              console.log('No active mobile sessions found.');
            } else {
              sessions.forEach((session, index) => {
                console.log(`Session #${index + 1}:`);
                console.log('  User ID:', session.user_id || 'NULL');
                console.log('  FCM Token:', session.fcm_token ? session.fcm_token.substring(0, 40) + '...' : 'NULL');
                console.log('  Device ID:', session.device_id || 'NULL');
                console.log('  Platform:', session.platform);
                console.log('  Created:', session.created_at);
                console.log('');
              });
            }
            
            db.close();
          }
        );
      }
    );
  }
);