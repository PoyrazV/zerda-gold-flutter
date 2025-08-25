const mysql = require('mysql2/promise');
const fs = require('fs');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

async function initializeDatabase() {
  let connection;
  
  try {
    console.log('🚀 Initializing MySQL database...');
    
    // First connect without database to create it if needed
    connection = await mysql.createConnection({
      host: process.env.DB_HOST || 'localhost',
      user: process.env.DB_USER || 'root',
      password: process.env.DB_PASSWORD || '',
      port: process.env.DB_PORT || 3306,
      multipleStatements: true
    });
    
    console.log('✅ Connected to MySQL server');
    
    // Read and execute the SQL schema file
    const schemaPath = path.join(__dirname, 'create-mysql-schema.sql');
    const schema = fs.readFileSync(schemaPath, 'utf8');
    
    console.log('📝 Creating database and tables...');
    await connection.query(schema);
    
    console.log('✅ Database schema created successfully');
    
    // Verify tables were created
    await connection.query('USE zerda_admin');
    const [tables] = await connection.query('SHOW TABLES');
    console.log(`✅ Created ${tables.length} tables:`);
    tables.forEach(table => {
      const tableName = Object.values(table)[0];
      console.log(`   - ${tableName}`);
    });
    
    console.log('\n🎉 MySQL database initialization complete!');
    console.log('\n📌 Database Details:');
    console.log(`   Host: ${process.env.DB_HOST || 'localhost'}`);
    console.log(`   Database: zerda_admin`);
    console.log(`   User: ${process.env.DB_USER || 'root'}`);
    console.log('\n👤 Default Admin Credentials:');
    console.log('   Username: admin');
    console.log('   Password: admin123');
    console.log('\n📱 Test Mobile Users:');
    console.log('   Email: demo@zerda.com, Password: demo123');
    console.log('   Email: test@zerda.com, Password: test123');
    
  } catch (error) {
    console.error('❌ Error initializing database:', error.message);
    if (error.code === 'ER_ACCESS_DENIED_ERROR') {
      console.error('\n⚠️  Please check your MySQL credentials in the .env file');
      console.error('   DB_USER and DB_PASSWORD must be correct');
    } else if (error.code === 'ECONNREFUSED') {
      console.error('\n⚠️  Cannot connect to MySQL server');
      console.error('   Please make sure MySQL is running on port', process.env.DB_PORT || 3306);
    }
    process.exit(1);
  } finally {
    if (connection) {
      await connection.end();
    }
  }
}

// Run the initialization
initializeDatabase();