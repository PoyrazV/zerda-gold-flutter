const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const fs = require('fs');

const DB_PATH = path.join(__dirname, '..', 'zerda_admin.db');

// SQL statements for tables
const createTables = [
  // Users table
  `CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    username TEXT UNIQUE NOT NULL,
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    role TEXT DEFAULT 'admin',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
  )`,

  // Customers table
  `CREATE TABLE IF NOT EXISTS customers (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    display_name TEXT NOT NULL,
    contact_email TEXT,
    contact_phone TEXT,
    logo_path TEXT,
    is_active BOOLEAN DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
  )`,

  // Customer Features table
  `CREATE TABLE IF NOT EXISTS customer_features (
    id TEXT PRIMARY KEY,
    customer_id TEXT NOT NULL,
    feature_name TEXT NOT NULL,
    is_enabled BOOLEAN DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers (id),
    UNIQUE(customer_id, feature_name)
  )`,

  // Theme Configurations table
  `CREATE TABLE IF NOT EXISTS theme_configs (
    id TEXT PRIMARY KEY,
    customer_id TEXT NOT NULL,
    theme_type TEXT DEFAULT 'light',
    primary_color TEXT DEFAULT '#18214F',
    secondary_color TEXT DEFAULT '#D4B896',
    accent_color TEXT DEFAULT '#FF6B6B',
    background_color TEXT DEFAULT '#FFFFFF',
    text_color TEXT DEFAULT '#000000',
    success_color TEXT DEFAULT '#4CAF50',
    error_color TEXT DEFAULT '#F44336',
    warning_color TEXT DEFAULT '#FF9800',
    font_family TEXT DEFAULT 'Inter',
    font_size_scale REAL DEFAULT 1.0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers (id),
    UNIQUE(customer_id)
  )`,

  // Assets table
  `CREATE TABLE IF NOT EXISTS assets (
    id TEXT PRIMARY KEY,
    customer_id TEXT NOT NULL,
    asset_type TEXT NOT NULL,
    asset_name TEXT NOT NULL,
    file_path TEXT NOT NULL,
    file_size INTEGER,
    mime_type TEXT,
    is_active BOOLEAN DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers (id)
  )`,

  // App Builds table
  `CREATE TABLE IF NOT EXISTS app_builds (
    id TEXT PRIMARY KEY,
    customer_id TEXT NOT NULL,
    version TEXT NOT NULL,
    build_number INTEGER NOT NULL,
    platform TEXT NOT NULL,
    file_path TEXT,
    file_size INTEGER,
    status TEXT DEFAULT 'pending',
    build_log TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers (id)
  )`,

  // Sessions table
  `CREATE TABLE IF NOT EXISTS sessions (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    token TEXT UNIQUE NOT NULL,
    expires_at DATETIME NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users (id)
  )`
];

async function createDatabase() {
  return new Promise((resolve, reject) => {
    const db = new sqlite3.Database(DB_PATH, (err) => {
      if (err) {
        console.error('Database bağlantı hatası:', err);
        reject(err);
        return;
      }
      console.log('✅ Database bağlantısı başarılı');
      
      let completedTables = 0;
      const totalTables = createTables.length;
      
      createTables.forEach((sql, index) => {
        db.run(sql, (err) => {
          if (err) {
            console.error(`Tablo ${index + 1} hatası:`, err);
          } else {
            console.log(`✅ Tablo ${index + 1} oluşturuldu`);
          }
          
          completedTables++;
          if (completedTables === totalTables) {
            console.log('🎉 Tüm tablolar başarıyla oluşturuldu!');
            db.close((err) => {
              if (err) reject(err);
              else resolve();
            });
          }
        });
      });
    });
  });
}

// Migration'ı çalıştır
if (require.main === module) {
  createDatabase()
    .then(() => {
      console.log('✅ Migration tamamlandı!');
      process.exit(0);
    })
    .catch((err) => {
      console.error('❌ Migration hatası:', err);
      process.exit(1);
    });
}

module.exports = { createDatabase };