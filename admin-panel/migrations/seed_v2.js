const sqlite3 = require('sqlite3').verbose();
const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const path = require('path');
const fs = require('fs');

const DB_PATH = path.join(__dirname, '..', 'zerda_admin.db');

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

// Mevcut zerda-config.json'dan feature'ları al
const configPath = path.join(__dirname, '..', 'zerda-config.json');

function getExistingFeatures() {
  let existingFeatures = {};
  try {
    if (fs.existsSync(configPath)) {
      const configData = JSON.parse(fs.readFileSync(configPath, 'utf8'));
      existingFeatures = configData.features || {};
      console.log('📋 Mevcut config\'ten feature\'lar alındı:', existingFeatures);
    }
  } catch (error) {
    console.log('⚠️ Mevcut config okunamadı, varsayılan değerler kullanılacak');
  }
  return existingFeatures;
}

async function seedDatabase() {
  const existingFeatures = getExistingFeatures();
  
  return new Promise(async (resolve, reject) => {
    const db = new sqlite3.Database(DB_PATH, (err) => {
      if (err) {
        reject(err);
        return;
      }

      console.log('✅ Database bağlantısı başarılı (seed)');

      const runAsync = (sql, params) => {
        return new Promise((resolve, reject) => {
          db.run(sql, params, function(err) {
            if (err) reject(err);
            else resolve(this);
          });
        });
      };

      (async () => {
        try {
          // 1. Admin kullanıcısı oluştur
          const adminId = uuidv4();
          const adminPassword = await bcrypt.hash('admin123', 10);
          
          await runAsync(
            `INSERT OR IGNORE INTO users (id, username, email, password_hash, role) VALUES (?, ?, ?, ?, ?)`,
            [adminId, 'admin', 'admin@zerda.com', adminPassword, 'admin']
          );
          console.log('✅ Admin kullanıcısı oluşturuldu (admin/admin123)');

          // 2. Demo müşteri oluştur (Default Zerda)
          const customerId = uuidv4();
          await runAsync(
            `INSERT OR IGNORE INTO customers (id, name, display_name, contact_email) VALUES (?, ?, ?, ?)`,
            [customerId, 'zerda-default', 'Zerda Default', 'support@zerda.com']
          );
          console.log('✅ Demo müşteri oluşturuldu');

          // 3. Her feature için customer_features kaydı oluştur
          let featuresCreated = 0;
          for (const featureName of defaultFeatures) {
            const featureId = uuidv4();
            const isEnabled = existingFeatures[featureName] !== undefined ? 
                             existingFeatures[featureName] : true;
            
            try {
              await runAsync(
                `INSERT OR IGNORE INTO customer_features (id, customer_id, feature_name, is_enabled) VALUES (?, ?, ?, ?)`,
                [featureId, customerId, featureName, isEnabled]
              );
              featuresCreated++;
              console.log(`✅ Feature oluşturuldu: ${featureName} (${isEnabled ? 'açık' : 'kapalı'})`);
            } catch (err) {
              console.error(`❌ Feature hatası ${featureName}:`, err);
            }
          }

          // 4. Varsayılan tema konfigürasyonu oluştur
          const themeId = uuidv4();
          await runAsync(
            `INSERT OR IGNORE INTO theme_configs (id, customer_id, theme_type, primary_color, secondary_color) VALUES (?, ?, ?, ?, ?)`,
            [themeId, customerId, 'dark', '#18214F', '#D4B896']
          );
          console.log('✅ Varsayılan tema konfigürasyonu oluşturuldu');

          console.log(`🎉 Seed data başarıyla eklendi! (${featuresCreated} feature oluşturuldu)`);
          
          db.close((err) => {
            if (err) reject(err);
            else resolve();
          });
        } catch (error) {
          console.error('Seed hatası:', error);
          db.close();
          reject(error);
        }
      })();
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