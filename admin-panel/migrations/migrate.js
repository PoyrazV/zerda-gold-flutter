const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const fs = require('fs');

const DB_PATH = path.join(__dirname, '..', 'zerda_admin.db');

// Database'i oluştur ve tabloları kur
function createDatabase() {
  return new Promise((resolve, reject) => {
    const db = new sqlite3.Database(DB_PATH, (err) => {
      if (err) {
        console.error('Database bağlantı hatası:', err);
        reject(err);
        return;
      }
      console.log('✅ Database bağlantısı başarılı');
      
      // Tabloları oluştur
      db.serialize(() => {
        
        // 1. Users tablosu (Admin kullanıcıları)
        db.run(`CREATE TABLE IF NOT EXISTS users (
          id TEXT PRIMARY KEY,
          username TEXT UNIQUE NOT NULL,
          email TEXT UNIQUE NOT NULL,
          password_hash TEXT NOT NULL,
          role TEXT DEFAULT 'admin',
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )`, (err) => {
          if (err) console.error('Users tablosu hatası:', err);
          else console.log('✅ Users tablosu oluşturuldu');
        });

        // 2. Customers tablosu (Multi-tenant müşteriler)
        db.run(`CREATE TABLE IF NOT EXISTS customers (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          display_name TEXT NOT NULL,
          contact_email TEXT,
          contact_phone TEXT,
          logo_path TEXT,
          is_active BOOLEAN DEFAULT 1,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )`, (err) => {
          if (err) console.error('Customers tablosu hatası:', err);
          else console.log('✅ Customers tablosu oluşturuldu');
        });

        // 3. Customer Features tablosu (Her müşteri için ayrı feature'lar)
        db.run(`CREATE TABLE IF NOT EXISTS customer_features (
          id TEXT PRIMARY KEY,
          customer_id TEXT NOT NULL,
          feature_name TEXT NOT NULL,
          is_enabled BOOLEAN DEFAULT 1,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (customer_id) REFERENCES customers (id),
          UNIQUE(customer_id, feature_name)
        )`, (err) => {
          if (err) console.error('Customer Features tablosu hatası:', err);
          else console.log('✅ Customer Features tablosu oluşturuldu');
        });

        // 4. Theme Configurations tablosu
        db.run(`CREATE TABLE IF NOT EXISTS theme_configs (
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
        )`, (err) => {
          if (err) console.error('Theme Configs tablosu hatası:', err);
          else console.log('✅ Theme Configs tablosu oluşturuldu');
        });

        // 5. Assets tablosu (Logo, ikon vs.)
        db.run(`CREATE TABLE IF NOT EXISTS assets (
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
        )`, (err) => {
          if (err) console.error('Assets tablosu hatası:', err);
          else console.log('✅ Assets tablosu oluşturuldu');
        });

        // 6. App Builds tablosu (Build tracking)
        db.run(`CREATE TABLE IF NOT EXISTS app_builds (
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
        )`, (err) => {
          if (err) console.error('App Builds tablosu hatası:', err);
          else console.log('✅ App Builds tablosu oluşturuldu');
        });

        // 7. Sessions tablosu (Login sessions)
        db.run(`CREATE TABLE IF NOT EXISTS sessions (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          token TEXT UNIQUE NOT NULL,
          expires_at DATETIME NOT NULL,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (user_id) REFERENCES users (id)
        )`, (err) => {
          if (err) console.error('Sessions tablosu hatası:', err);
          else console.log('✅ Sessions tablosu oluşturuldu');
        });

        console.log('🎉 Tüm tablolar başarıyla oluşturuldu!');
        db.close((err) => {
          if (err) reject(err);
          else resolve();
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