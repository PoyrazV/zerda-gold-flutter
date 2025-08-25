const sqlite3 = require('sqlite3').verbose();
const path = require('path');

const dbPath = path.join(__dirname, 'zerda_admin.db');
const db = new sqlite3.Database(dbPath);

console.log('🧹 Starting FCM Token Cleanup...\n');

// Step 1: Show current token status
db.all(
  `SELECT 
    customer_id,
    COUNT(*) as token_count,
    COUNT(DISTINCT device_id) as unique_devices,
    COUNT(CASE WHEN is_authenticated = 1 THEN 1 END) as authenticated_tokens,
    COUNT(CASE WHEN is_authenticated = 0 OR is_authenticated IS NULL THEN 1 END) as guest_tokens
   FROM fcm_tokens
   GROUP BY customer_id`,
  [],
  (err, stats) => {
    if (err) {
      console.error('Error getting stats:', err);
      return;
    }

    console.log('📊 Current Token Statistics:');
    stats.forEach(stat => {
      console.log(`  Customer: ${stat.customer_id}`);
      console.log(`    Total Tokens: ${stat.token_count}`);
      console.log(`    Unique Devices: ${stat.unique_devices}`);
      console.log(`    Authenticated: ${stat.authenticated_tokens}`);
      console.log(`    Guest: ${stat.guest_tokens}`);
      console.log('');
    });

    // Step 2: Find duplicate tokens (same device_id or same fcm_token)
    db.all(
      `SELECT 
        fcm_token,
        device_id,
        COUNT(*) as count
       FROM fcm_tokens
       WHERE device_id IS NOT NULL
       GROUP BY device_id
       HAVING COUNT(*) > 1`,
      [],
      (err, duplicates) => {
        if (err) {
          console.error('Error finding duplicates:', err);
          return;
        }

        if (duplicates.length > 0) {
          console.log(`⚠️  Found ${duplicates.length} devices with duplicate tokens\n`);
          
          // Step 3: Clean up duplicates - keep only the most recent one
          duplicates.forEach(dup => {
            console.log(`  Cleaning duplicates for device: ${dup.device_id}`);
            
            // Delete all but the most recent token for each device
            db.run(
              `DELETE FROM fcm_tokens 
               WHERE device_id = ? 
               AND id NOT IN (
                 SELECT id FROM fcm_tokens 
                 WHERE device_id = ? 
                 ORDER BY updated_at DESC, created_at DESC 
                 LIMIT 1
               )`,
              [dup.device_id, dup.device_id],
              function(err) {
                if (err) {
                  console.error(`    ❌ Error: ${err.message}`);
                } else {
                  console.log(`    ✅ Removed ${this.changes} duplicate token(s)`);
                }
              }
            );
          });
        } else {
          console.log('✅ No duplicate tokens found');
        }

        // Step 4: Remove tokens without device_id (old tokens)
        db.run(
          `DELETE FROM fcm_tokens 
           WHERE device_id IS NULL OR device_id = ''`,
          [],
          function(err) {
            if (err) {
              console.error('Error removing old tokens:', err);
            } else if (this.changes > 0) {
              console.log(`\n🗑️  Removed ${this.changes} token(s) without device_id`);
            }

            // Step 5: Show final statistics
            setTimeout(() => {
              db.all(
                `SELECT 
                  customer_id,
                  COUNT(*) as token_count,
                  COUNT(DISTINCT device_id) as unique_devices
                 FROM fcm_tokens
                 GROUP BY customer_id`,
                [],
                (err, finalStats) => {
                  if (err) {
                    console.error('Error getting final stats:', err);
                  } else {
                    console.log('\n✨ Final Token Statistics:');
                    finalStats.forEach(stat => {
                      console.log(`  Customer: ${stat.customer_id}`);
                      console.log(`    Total Tokens: ${stat.token_count}`);
                      console.log(`    Unique Devices: ${stat.unique_devices}`);
                    });
                  }
                  
                  db.close();
                  console.log('\n✅ Cleanup completed!');
                }
              );
            }, 1000);
          }
        );
      }
    );
  }
);