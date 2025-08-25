const mysql = require('mysql2/promise');
require('dotenv').config();

async function addGoldProducts() {
  const connection = await mysql.createConnection({
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'zerda_admin'
  });

  try {
    console.log('🏆 Adding sample gold products...\n');
    
    const customerId = 'ffeee61a-8497-4c70-857e-c8f0efb13a2a';
    
    // Sample gold products
    const products = [
      {
        id: require('crypto').randomUUID(),
        customer_id: customerId,
        name: 'Gram Altın',
        weight_grams: 1,
        buy_millesimal: 995,
        sell_millesimal: 995,
        is_active: 1,
        display_order: 1
      },
      {
        id: require('crypto').randomUUID(),
        customer_id: customerId,
        name: 'Çeyrek Altın',
        weight_grams: 1.75,
        buy_millesimal: 916,
        sell_millesimal: 916,
        is_active: 1,
        display_order: 2
      },
      {
        id: require('crypto').randomUUID(),
        customer_id: customerId,
        name: 'Yarım Altın',
        weight_grams: 3.5,
        buy_millesimal: 916,
        sell_millesimal: 916,
        is_active: 1,
        display_order: 3
      },
      {
        id: require('crypto').randomUUID(),
        customer_id: customerId,
        name: 'Tam Altın',
        weight_grams: 7,
        buy_millesimal: 916,
        sell_millesimal: 916,
        is_active: 1,
        display_order: 4
      },
      {
        id: require('crypto').randomUUID(),
        customer_id: customerId,
        name: 'Ata Altın',
        weight_grams: 7.21,
        buy_millesimal: 916,
        sell_millesimal: 916,
        is_active: 1,
        display_order: 5
      },
      {
        id: require('crypto').randomUUID(),
        customer_id: customerId,
        name: 'Reşat Altın',
        weight_grams: 7.21,
        buy_millesimal: 916,
        sell_millesimal: 916,
        is_active: 1,
        display_order: 6
      },
      {
        id: require('crypto').randomUUID(),
        customer_id: customerId,
        name: '14 Ayar Altın',
        weight_grams: 1,
        buy_millesimal: 585,
        sell_millesimal: 585,
        is_active: 1,
        display_order: 7
      },
      {
        id: require('crypto').randomUUID(),
        customer_id: customerId,
        name: '18 Ayar Altın',
        weight_grams: 1,
        buy_millesimal: 750,
        sell_millesimal: 750,
        is_active: 1,
        display_order: 8
      },
      {
        id: require('crypto').randomUUID(),
        customer_id: customerId,
        name: '22 Ayar Altın',
        weight_grams: 1,
        buy_millesimal: 916,
        sell_millesimal: 916,
        is_active: 1,
        display_order: 9
      }
    ];
    
    // Clear existing products for this customer
    await connection.execute(
      'DELETE FROM gold_products WHERE customer_id = ?',
      [customerId]
    );
    console.log('✅ Cleared existing products');
    
    // Insert new products
    for (const product of products) {
      await connection.execute(
        `INSERT INTO gold_products 
         (id, customer_id, name, weight_grams, buy_millesimal, sell_millesimal, is_active, display_order, created_at) 
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW())`,
        [
          product.id,
          product.customer_id,
          product.name,
          product.weight_grams,
          product.buy_millesimal,
          product.sell_millesimal,
          product.is_active,
          product.display_order
        ]
      );
      console.log(`✅ Added: ${product.name}`);
    }
    
    console.log('\n✅ All gold products added successfully!');
    
    // List products
    const [result] = await connection.execute(
      'SELECT name, weight_grams, buy_millesimal FROM gold_products WHERE customer_id = ? ORDER BY display_order',
      [customerId]
    );
    
    console.log('\nCurrent products in database:');
    result.forEach(p => {
      console.log(`  - ${p.name}: ${p.weight_grams}g, ${p.buy_millesimal}‰`);
    });
    
  } catch (error) {
    console.error('Error:', error.message);
  } finally {
    await connection.end();
  }
}

addGoldProducts();