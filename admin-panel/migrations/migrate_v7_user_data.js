const sqlite3 = require('sqlite3').verbose();
const path = require('path');

const dbPath = path.join(__dirname, '..', 'zerda_admin.db');

console.log('Starting User Data Tables Migration v7...');
console.log('Database path:', dbPath);

const db = new sqlite3.Database(dbPath);

db.serialize(() => {
  console.log('Creating user data tables...');
  
  // Create user watchlist table
  db.run(`
    CREATE TABLE IF NOT EXISTS user_watchlist (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      asset_code TEXT NOT NULL,
      asset_name TEXT,
      asset_type TEXT,
      buy_price REAL,
      sell_price REAL,
      added_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      UNIQUE(user_id, asset_code),
      FOREIGN KEY (user_id) REFERENCES mobile_users(id) ON DELETE CASCADE
    )
  `, (err) => {
    if (err) {
      console.error('Error creating user_watchlist table:', err);
    } else {
      console.log('✓ Created user_watchlist table');
    }
  });
  
  // Create user portfolio table
  db.run(`
    CREATE TABLE IF NOT EXISTS user_portfolio (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      asset_code TEXT NOT NULL,
      asset_name TEXT,
      asset_type TEXT,
      quantity REAL NOT NULL,
      purchase_price REAL NOT NULL,
      purchase_date DATETIME,
      notes TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES mobile_users(id) ON DELETE CASCADE
    )
  `, (err) => {
    if (err) {
      console.error('Error creating user_portfolio table:', err);
    } else {
      console.log('✓ Created user_portfolio table');
    }
  });
  
  // Create user alerts table
  db.run(`
    CREATE TABLE IF NOT EXISTS user_alerts (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      asset_code TEXT NOT NULL,
      asset_name TEXT,
      alert_type TEXT NOT NULL, -- 'above' or 'below'
      target_price REAL NOT NULL,
      current_price REAL,
      is_active BOOLEAN DEFAULT 1,
      triggered_at DATETIME,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES mobile_users(id) ON DELETE CASCADE
    )
  `, (err) => {
    if (err) {
      console.error('Error creating user_alerts table:', err);
    } else {
      console.log('✓ Created user_alerts table');
    }
  });
  
  // Create indexes for better performance
  db.run(`CREATE INDEX IF NOT EXISTS idx_watchlist_user ON user_watchlist(user_id)`, (err) => {
    if (!err) console.log('✓ Created index on user_watchlist(user_id)');
  });
  
  db.run(`CREATE INDEX IF NOT EXISTS idx_portfolio_user ON user_portfolio(user_id)`, (err) => {
    if (!err) console.log('✓ Created index on user_portfolio(user_id)');
  });
  
  db.run(`CREATE INDEX IF NOT EXISTS idx_alerts_user ON user_alerts(user_id)`, (err) => {
    if (!err) console.log('✓ Created index on user_alerts(user_id)');
  });
  
  db.run(`CREATE INDEX IF NOT EXISTS idx_alerts_active ON user_alerts(user_id, is_active)`, (err) => {
    if (!err) console.log('✓ Created index on user_alerts(user_id, is_active)');
  });
  
  console.log('\n✅ User Data Tables Migration v7 completed successfully!');
  console.log('Tables created:');
  console.log('  - user_watchlist');
  console.log('  - user_portfolio');
  console.log('  - user_alerts');
});

db.close((err) => {
  if (err) {
    console.error('Error closing database:', err);
  } else {
    console.log('\nDatabase connection closed.');
  }
});