const mysql = require('mysql2/promise');
require('dotenv').config();

async function checkGoldTable() {
  const connection = await mysql.createConnection({
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'zerda_admin'
  });

  try {
    console.log('🔍 Checking gold_products table structure...\n');
    
    const [columns] = await connection.execute(
      `SHOW COLUMNS FROM gold_products`
    );
    
    console.log('Gold products table columns:');
    columns.forEach(col => {
      console.log(`  - ${col.Field} (${col.Type}) ${col.Null === 'NO' ? 'NOT NULL' : 'NULL'} ${col.Key ? col.Key : ''}`);
    });
    
    // Check if we need to add missing columns
    const columnNames = columns.map(col => col.Field);
    
    if (!columnNames.includes('weight_grams')) {
      console.log('\n⚠️ Missing weight_grams column. Adding...');
      await connection.execute('ALTER TABLE gold_products ADD COLUMN weight_grams DECIMAL(10,2) DEFAULT 1');
      console.log('✅ Added weight_grams column');
    }
    
    if (!columnNames.includes('buy_millesimal')) {
      console.log('\n⚠️ Missing buy_millesimal column. Adding...');
      await connection.execute('ALTER TABLE gold_products ADD COLUMN buy_millesimal INT DEFAULT 995');
      console.log('✅ Added buy_millesimal column');
    }
    
    if (!columnNames.includes('sell_millesimal')) {
      console.log('\n⚠️ Missing sell_millesimal column. Adding...');
      await connection.execute('ALTER TABLE gold_products ADD COLUMN sell_millesimal INT DEFAULT 995');
      console.log('✅ Added sell_millesimal column');
    }
    
    if (!columnNames.includes('display_order')) {
      console.log('\n⚠️ Missing display_order column. Adding...');
      await connection.execute('ALTER TABLE gold_products ADD COLUMN display_order INT DEFAULT 0');
      console.log('✅ Added display_order column');
    }
    
    if (!columnNames.includes('is_active')) {
      console.log('\n⚠️ Missing is_active column. Adding...');
      await connection.execute('ALTER TABLE gold_products ADD COLUMN is_active TINYINT(1) DEFAULT 1');
      console.log('✅ Added is_active column');
    }
    
    console.log('\n✅ Table structure check complete');
    
  } catch (error) {
    console.error('Error:', error.message);
  } finally {
    await connection.end();
  }
}

checkGoldTable();