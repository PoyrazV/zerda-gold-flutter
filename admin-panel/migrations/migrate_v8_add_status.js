const sqlite3 = require('sqlite3').verbose();
const path = require('path');

// Open database
const dbPath = path.join(__dirname, '..', 'zerda_admin.db');
const db = new sqlite3.Database(dbPath);

console.log('Starting Status Column Migration v8...\n');

db.serialize(() => {
  // Add status column to user_alerts table if it doesn't exist
  db.run(`ALTER TABLE user_alerts ADD COLUMN status TEXT DEFAULT 'active'`, (err) => {
    if (err) {
      if (err.message.includes('duplicate column name')) {
        console.log('✓ Status column already exists in user_alerts table');
      } else {
        console.error('Error adding status column to user_alerts:', err);
      }
    } else {
      console.log('✓ Added status column to user_alerts table');
      
      // Update existing records
      db.run(`UPDATE user_alerts SET status = CASE 
        WHEN is_active = 1 THEN 'active' 
        ELSE 'triggered' 
      END`, (err) => {
        if (err) {
          console.error('Error updating status values:', err);
        } else {
          console.log('✓ Updated status values for existing alerts');
        }
      });
    }
  });
  
  // Add current_price column to user_portfolio if it doesn't exist
  db.run(`ALTER TABLE user_portfolio ADD COLUMN current_price REAL`, (err) => {
    if (err) {
      if (err.message.includes('duplicate column name')) {
        console.log('✓ Current_price column already exists in user_portfolio table');
      } else {
        console.error('Error adding current_price column to user_portfolio:', err);
      }
    } else {
      console.log('✓ Added current_price column to user_portfolio table');
      
      // Initialize current_price to purchase_price for existing records
      db.run(`UPDATE user_portfolio SET current_price = purchase_price WHERE current_price IS NULL`, (err) => {
        if (err) {
          console.error('Error updating current_price values:', err);
        } else {
          console.log('✓ Initialized current_price values for existing portfolio items');
        }
      });
    }
  });
  
  console.log('\n✅ Status Column Migration v8 completed successfully!');
});

db.close((err) => {
  if (err) {
    console.error('Error closing database:', err);
  } else {
    console.log('\nDatabase connection closed.');
  }
});