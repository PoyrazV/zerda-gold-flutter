const mysql = require('mysql2/promise');
require('dotenv').config();

async function updateFeatures() {
  const connection = await mysql.createConnection({
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'zerda_admin'
  });

  try {
    console.log('🔄 Updating features to 11 new features...\n');
    
    const customerId = 'ffeee61a-8497-4c70-857e-c8f0efb13a2a';
    
    // 1. Delete existing features
    await connection.execute(
      'DELETE FROM feature_configs WHERE customer_id = ?',
      [customerId]
    );
    console.log('✅ Deleted old features');
    
    // 2. Insert 11 new features with Turkish names
    const features = [
      { name: 'currency', displayName: 'Döviz', enabled: true },
      { name: 'gold', displayName: 'Altın', enabled: true },
      { name: 'converter', displayName: 'Çevirici', enabled: true },
      { name: 'alarms', displayName: 'Alarm', enabled: true },
      { name: 'portfolio', displayName: 'Portföy', enabled: true },
      { name: 'profile', displayName: 'Profil', enabled: true },
      { name: 'watchlist', displayName: 'Takip Listem', enabled: true },
      { name: 'profitLossCalculator', displayName: 'Kar/Zarar Hesaplama', enabled: true },
      { name: 'performanceHistory', displayName: 'Performans Geçmişi', enabled: true },
      { name: 'sarrafiyeIscilik', displayName: 'Sarrafiye İşçilikleri', enabled: true },
      { name: 'gecmisKurlar', displayName: 'Geçmiş Kurlar', enabled: true }
    ];
    
    for (const feature of features) {
      await connection.execute(
        `INSERT INTO feature_configs (customer_id, feature_name, enabled, config_data) 
         VALUES (?, ?, ?, ?)`,
        [customerId, feature.name, feature.enabled, JSON.stringify({ displayName: feature.displayName })]
      );
      console.log(`✅ Added feature: ${feature.displayName} (${feature.name})`);
    }
    
    // 3. Verify features
    const [rows] = await connection.execute(
      'SELECT feature_name, enabled, config_data FROM feature_configs WHERE customer_id = ? ORDER BY id',
      [customerId]
    );
    
    console.log('\n📊 Final feature list:');
    rows.forEach((row, index) => {
      const config = JSON.parse(row.config_data || '{}');
      console.log(`   ${index + 1}. ${config.displayName || row.feature_name}: ${row.enabled ? '✅ Enabled' : '❌ Disabled'}`);
    });
    
    console.log('\n🎉 Features updated successfully!');
    
  } catch (error) {
    console.error('❌ Error updating features:', error.message);
    console.error(error);
  } finally {
    await connection.end();
  }
}

updateFeatures();