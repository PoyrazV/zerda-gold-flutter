const sqlite3 = require('sqlite3').verbose();
const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const path = require('path');

const DB_PATH = path.join(__dirname, '..', 'zerda_admin.db');

// Mevcut zerda-config.json'dan feature'ları al
const fs = require('fs');
const configPath = path.join(__dirname, '..', 'zerda-config.json');

// Varsayılan feature'lar
const defaultFeatures = [
  'dashboard',
  'goldPrices', 
  'converter',
  'alarms',
  'portfolio',
  'profile',
  'watchlist',
  'profitLossCalculator',
  'performanceHistory',
  'sarrafiyeIscilik',
  'gecmisKurlar'
];

async function seedDatabase() {
  return new Promise((resolve, reject) => {
    const db = new sqlite3.Database(DB_PATH, (err) => {
      if (err) {
        reject(err);
        return;
      }

      db.serialize(async () => {
        
        // 1. Admin kullanıcısı oluştur
        const adminId = uuidv4();
        const adminPassword = await bcrypt.hash('admin123', 10);
        
        db.run(`INSERT OR IGNORE INTO users (id, username, email, password_hash, role) 
                VALUES (?, ?, ?, ?, ?)`, 
          [adminId, 'admin', 'admin@zerda.com', adminPassword, 'admin'], 
          function(err) {
            if (err) console.error('Admin kullanıcı hatası:', err);
            else console.log('✅ Admin kullanıcısı oluşturuldu (admin/admin123)');
          }
        );

        // 2. Demo müşteri oluştur (Default Zerda)
        const customerId = uuidv4();
        db.run(`INSERT OR IGNORE INTO customers (id, name, display_name, contact_email) 
                VALUES (?, ?, ?, ?)`,
          [customerId, 'zerda-default', 'Zerda Default', 'support@zerda.com'],
          function(err) {
            if (err) console.error('Demo müşteri hatası:', err);
            else console.log('✅ Demo müşteri oluşturuldu');
          }
        );

        // 3. Mevcut config'den feature'ları al ve müşteriye ata
        let existingFeatures = {};
        try {
          if (fs.existsSync(configPath)) {
            const configData = JSON.parse(fs.readFileSync(configPath, 'utf8'));
            existingFeatures = configData.features || {};
          }
        } catch (error) {
          console.log('Mevcut config okunamadı, varsayılan değerler kullanılacak');
        }

        // Her feature için customer_features kaydı oluştur
        defaultFeatures.forEach((featureName) => {
          const featureId = uuidv4();
          const isEnabled = existingFeatures[featureName] !== undefined ? 
                           existingFeatures[featureName] : true;
          
          db.run(`INSERT OR IGNORE INTO customer_features 
                  (id, customer_id, feature_name, is_enabled) 
                  VALUES (?, ?, ?, ?)`,
            [featureId, customerId, featureName, isEnabled],
            function(err) {
              if (err) console.error(`Feature ${featureName} hatası:`, err);
            }
          );
        });

        // 4. Varsayılan tema konfigürasyonu oluştur
        const themeId = uuidv4();
        db.run(`INSERT OR IGNORE INTO theme_configs 
                (id, customer_id, theme_type, primary_color, secondary_color) 
                VALUES (?, ?, ?, ?, ?)`,
          [themeId, customerId, 'dark', '#18214F', '#D4B896'],
          function(err) {
            if (err) console.error('Theme config hatası:', err);
            else console.log('✅ Varsayılan tema konfigürasyonu oluşturuldu');
          }
        );

        console.log('🎉 Seed data başarıyla eklendi!');
        console.log('📋 Demo müşteri özellikleri mevcut config\'den alındı');
        
        db.close();
        resolve();
      });
    });
  });
}

// Seed'i çalıştır
if (require.main === module) {
  seedDatabase()
    .then(() => {
      console.log('✅ Seed tamamlandı!');
      process.exit(0);
    })
    .catch((err) => {
      console.error('❌ Seed hatası:', err);
      process.exit(1);
    });
}

module.exports = { seedDatabase };