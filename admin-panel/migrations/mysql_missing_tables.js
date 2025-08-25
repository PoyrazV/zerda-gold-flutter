const mysql = require('mysql2/promise');
require('dotenv').config();

async function createMissingTables() {
  const connection = await mysql.createConnection({
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'zerda_admin'
  });

  try {
    console.log('🔄 Creating missing MySQL tables...\n');
    
    // 1. Create feature_configs table
    await connection.execute(`
      CREATE TABLE IF NOT EXISTS feature_configs (
        id INT AUTO_INCREMENT PRIMARY KEY,
        customer_id VARCHAR(255) NOT NULL,
        feature_name VARCHAR(100) NOT NULL,
        enabled BOOLEAN DEFAULT 1,
        config_data JSON,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        UNIQUE KEY unique_customer_feature (customer_id, feature_name),
        INDEX idx_customer_id (customer_id)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    `);
    console.log('✅ feature_configs table created');
    
    // 2. Create theme_configs table
    await connection.execute(`
      CREATE TABLE IF NOT EXISTS theme_configs (
        id INT AUTO_INCREMENT PRIMARY KEY,
        customer_id VARCHAR(255) NOT NULL UNIQUE,
        theme_type VARCHAR(50) DEFAULT 'dark',
        primary_color VARCHAR(7) DEFAULT '#18214F',
        secondary_color VARCHAR(7) DEFAULT '#D4B896',
        accent_color VARCHAR(7) DEFAULT '#FF6B6B',
        background_color VARCHAR(7) DEFAULT '#FFFFFF',
        text_color VARCHAR(7) DEFAULT '#000000',
        success_color VARCHAR(7) DEFAULT '#4CAF50',
        error_color VARCHAR(7) DEFAULT '#F44336',
        warning_color VARCHAR(7) DEFAULT '#FF9800',
        font_family VARCHAR(100) DEFAULT 'Inter',
        font_size_scale DECIMAL(3,2) DEFAULT 1.0,
        logo_path VARCHAR(500),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        INDEX idx_customer_id (customer_id)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    `);
    console.log('✅ theme_configs table created');
    
    // 3. Insert default features for existing customer
    const customerId = 'ffeee61a-8497-4c70-857e-c8f0efb13a2a';
    
    const features = [
      { name: 'dashboard', enabled: true },
      { name: 'goldPrices', enabled: true },
      { name: 'currencyExchange', enabled: true },
      { name: 'portfolio', enabled: true },
      { name: 'calculator', enabled: true },
      { name: 'alerts', enabled: true },
      { name: 'news', enabled: true },
      { name: 'support', enabled: true }
    ];
    
    for (const feature of features) {
      await connection.execute(
        `INSERT INTO feature_configs (customer_id, feature_name, enabled) 
         VALUES (?, ?, ?) 
         ON DUPLICATE KEY UPDATE enabled = VALUES(enabled)`,
        [customerId, feature.name, feature.enabled]
      );
    }
    console.log('✅ Default features inserted');
    
    // 4. Insert default theme for existing customer
    await connection.execute(
      `INSERT INTO theme_configs (customer_id) 
       VALUES (?) 
       ON DUPLICATE KEY UPDATE customer_id = VALUES(customer_id)`,
      [customerId]
    );
    console.log('✅ Default theme inserted');
    
    // 5. Verify tables
    const [tables] = await connection.execute('SHOW TABLES');
    console.log('\n📊 All tables in database:');
    tables.forEach(table => {
      const tableName = Object.values(table)[0];
      console.log(`   - ${tableName}`);
    });
    
    // 6. Verify feature configs
    const [featureRows] = await connection.execute(
      'SELECT * FROM feature_configs WHERE customer_id = ?',
      [customerId]
    );
    console.log(`\n✅ ${featureRows.length} features configured for customer`);
    
    // 7. Verify theme config
    const [themeRows] = await connection.execute(
      'SELECT * FROM theme_configs WHERE customer_id = ?',
      [customerId]
    );
    console.log(`✅ Theme configured for customer`);
    
    console.log('\n🎉 Migration completed successfully!');
    
  } catch (error) {
    console.error('❌ Migration error:', error.message);
    console.error(error);
  } finally {
    await connection.end();
  }
}

createMissingTables();