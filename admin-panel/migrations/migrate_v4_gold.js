const sqlite3 = require('sqlite3').verbose();
const path = require('path');

// Database path
const dbPath = path.join(__dirname, '..', 'zerda_admin.db');

// Create database connection
const db = new sqlite3.Database(dbPath, (err) => {
  if (err) {
    console.error('Error opening database:', err);
    process.exit(1);
  }
  console.log('Connected to the SQLite database.');
});

// Migration SQL
const migrationSQL = `
-- Create gold_products table for managing gold products per customer
CREATE TABLE IF NOT EXISTS gold_products (
  id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
  customer_id TEXT NOT NULL,
  name TEXT NOT NULL,                -- Product name (e.g., "Gram Altın", "Çeyrek Altın")
  weight_grams REAL NOT NULL,        -- Weight in grams (e.g., 1.0, 1.75, 3.5, 7.0)
  buy_millesimal REAL NOT NULL,      -- Buy millesimal (e.g., 0.990, 0.995)
  sell_millesimal REAL NOT NULL,     -- Sell millesimal (e.g., 0.999, 1.000)
  is_active INTEGER DEFAULT 1,       -- 1 = active, 0 = inactive
  display_order INTEGER DEFAULT 0,   -- Display order in the app
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_gold_products_customer 
  ON gold_products(customer_id, is_active);

-- Create index for ordering
CREATE INDEX IF NOT EXISTS idx_gold_products_order 
  ON gold_products(display_order, name);

-- Create trigger to update updated_at timestamp
CREATE TRIGGER IF NOT EXISTS update_gold_products_updated_at 
  AFTER UPDATE ON gold_products
  FOR EACH ROW
  BEGIN
    UPDATE gold_products 
    SET updated_at = CURRENT_TIMESTAMP 
    WHERE id = NEW.id;
  END;

-- Insert default gold products for existing customers
INSERT INTO gold_products (customer_id, name, weight_grams, buy_millesimal, sell_millesimal, display_order)
SELECT 
  id as customer_id,
  'Ons Altın' as name,
  31.1035 as weight_grams,
  0.995 as buy_millesimal,
  1.000 as sell_millesimal,
  1 as display_order
FROM customers
WHERE NOT EXISTS (
  SELECT 1 FROM gold_products 
  WHERE customer_id = customers.id 
  AND name = 'Ons Altın'
);
`;

// Run migration
db.serialize(() => {
  db.exec(migrationSQL, (err) => {
    if (err) {
      console.error('Migration failed:', err);
      process.exit(1);
    }
    console.log('Migration v4 (Gold Products) completed successfully!');
    
    // Verify the migration
    db.all("SELECT name FROM sqlite_master WHERE type='table' AND name='gold_products'", (err, rows) => {
      if (err) {
        console.error('Verification failed:', err);
      } else if (rows.length > 0) {
        console.log('✓ gold_products table created successfully');
        
        // Count default products created
        db.get("SELECT COUNT(*) as count FROM gold_products", (err, row) => {
          if (!err && row) {
            console.log(`✓ ${row.count} default gold product(s) created`);
          }
        });
      }
    });
  });
});

// Close database connection
db.close((err) => {
  if (err) {
    console.error('Error closing database:', err);
  } else {
    console.log('Database connection closed.');
  }
});