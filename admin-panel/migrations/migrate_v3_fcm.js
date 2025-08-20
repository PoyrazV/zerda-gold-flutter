const sqlite3 = require('sqlite3').verbose();
const path = require('path');

const DB_PATH = path.join(__dirname, '..', 'zerda_admin.db');

// Migration v3: Add FCM tokens table
function migrateV3() {
  return new Promise((resolve, reject) => {
    const db = new sqlite3.Database(DB_PATH, (err) => {
      if (err) {
        console.error('❌ Database connection error:', err.message);
        return reject(err);
      }
      console.log('📦 Connected to SQLite database for FCM migration');
    });

    // Add FCM tokens table
    const createFCMTokensTable = `
      CREATE TABLE IF NOT EXISTS fcm_tokens (
        id TEXT PRIMARY KEY,
        customer_id TEXT NOT NULL,
        fcm_token TEXT NOT NULL,
        platform TEXT NOT NULL DEFAULT 'flutter',
        device_id TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(customer_id, fcm_token),
        FOREIGN KEY (customer_id) REFERENCES customers(id)
      )`;

    db.run(createFCMTokensTable, (err) => {
      if (err) {
        console.error('❌ Error creating fcm_tokens table:', err.message);
        db.close();
        return reject(err);
      }
      console.log('✅ FCM tokens table created successfully');

      // Create index for faster lookups
      db.run('CREATE INDEX IF NOT EXISTS idx_fcm_customer_id ON fcm_tokens(customer_id)', (err) => {
        if (err) {
          console.error('❌ Error creating index:', err.message);
        } else {
          console.log('✅ FCM tokens index created');
        }

        db.close((err) => {
          if (err) {
            console.error('❌ Error closing database:', err.message);
            return reject(err);
          }
          console.log('🔥 FCM migration v3 completed successfully');
          resolve();
        });
      });
    });
  });
}

// Run migration if called directly
if (require.main === module) {
  migrateV3().catch(console.error);
}

module.exports = migrateV3;