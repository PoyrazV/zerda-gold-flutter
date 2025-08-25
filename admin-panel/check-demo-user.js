const mysql = require('mysql2/promise');
const bcrypt = require('bcryptjs');
require('dotenv').config();

async function checkDemoUser() {
  const connection = await mysql.createConnection({
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'zerda_admin'
  });

  try {
    console.log('🔍 Checking Demo User...\n');
    
    // Check if demo user exists
    const [users] = await connection.execute(
      'SELECT * FROM users WHERE email = ?',
      ['demo@zerda.com']
    );
    
    if (users.length === 0) {
      console.log('❌ Demo user not found. Creating...\n');
      
      // Create demo user
      const hashedPassword = await bcrypt.hash('demo123456', 10);
      const userId = require('crypto').randomUUID();
      
      // Get next available ID
      const [maxId] = await connection.execute('SELECT MAX(id) as max_id FROM users');
      const newId = (maxId[0].max_id || 0) + 1;
      
      await connection.execute(
        `INSERT INTO users (id, username, email, password_hash, role, created_at) 
         VALUES (?, ?, ?, ?, ?, NOW())`,
        [newId, 'demo', 'demo@zerda.com', hashedPassword, 'user']
      );
      
      console.log('✅ Demo user created successfully');
      console.log('   Email: demo@zerda.com');
      console.log('   Password: demo123456');
    } else {
      const user = users[0];
      console.log('Demo user found:');
      console.log('  ID:', user.id);
      console.log('  Username:', user.username);
      console.log('  Email:', user.email);
      console.log('  Role:', user.role);
      console.log('  Active:', user.is_active ? 'Yes' : 'No');
      console.log('  Created:', user.created_at);
      
      // Update password to ensure it's demo123456
      const hashedPassword = await bcrypt.hash('demo123456', 10);
      await connection.execute(
        'UPDATE users SET password_hash = ? WHERE email = ?',
        [hashedPassword, 'demo@zerda.com']
      );
      
      console.log('\n✅ Password updated to: demo123456');
    }
    
  } catch (error) {
    console.error('Error:', error.message);
  } finally {
    await connection.end();
  }
}

checkDemoUser();