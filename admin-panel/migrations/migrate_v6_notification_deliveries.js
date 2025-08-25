const sqlite3 = require('sqlite3').verbose();
const path = require('path');

// Database path
const dbPath = path.join(__dirname, '..', 'zerda_admin.db');

// Open database
const db = new sqlite3.Database(dbPath, (err) => {
  if (err) {
    console.error('❌ Error opening database:', err.message);
    process.exit(1);
  }
  console.log('✅ Connected to the SQLite database.');
});

// Create notification_deliveries table for tracking which notifications have been delivered to which users
const createNotificationDeliveriesTable = `
  CREATE TABLE IF NOT EXISTS notification_deliveries (
    id TEXT PRIMARY KEY,
    notification_id TEXT NOT NULL,
    user_id TEXT NOT NULL,
    delivered_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    delivery_method TEXT DEFAULT 'fcm',
    read_at DATETIME,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (notification_id) REFERENCES notifications(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES mobile_users(id) ON DELETE CASCADE,
    UNIQUE(notification_id, user_id)
  )`;

// Add indices for performance
const createIndices = [
  `CREATE INDEX IF NOT EXISTS idx_deliveries_user_id ON notification_deliveries(user_id)`,
  `CREATE INDEX IF NOT EXISTS idx_deliveries_notification_id ON notification_deliveries(notification_id)`,
  `CREATE INDEX IF NOT EXISTS idx_deliveries_delivered_at ON notification_deliveries(delivered_at)`,
  `CREATE INDEX IF NOT EXISTS idx_notifications_target ON notifications(target)`,
  `CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at)`,
  `CREATE INDEX IF NOT EXISTS idx_notifications_status ON notifications(status)`
];

// Run migration
console.log('🚀 Running migration v6: Notification Deliveries...');

db.serialize(() => {
  // Create notification_deliveries table
  db.run(createNotificationDeliveriesTable, (err) => {
    if (err) {
      console.error('❌ Error creating notification_deliveries table:', err.message);
      db.close();
      process.exit(1);
    }
    console.log('✅ Created notification_deliveries table');
    
    // Create indices
    let completedIndices = 0;
    createIndices.forEach((indexQuery, index) => {
      db.run(indexQuery, (err) => {
        if (err) {
          console.error(`❌ Error creating index ${index + 1}:`, err.message);
        } else {
          console.log(`✅ Created index ${index + 1}/${createIndices.length}`);
        }
        
        completedIndices++;
        if (completedIndices === createIndices.length) {
          console.log('✅ Migration v6 completed successfully!');
          db.close();
        }
      });
    });
  });
});