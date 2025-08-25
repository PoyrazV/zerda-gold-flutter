const mysql = require('mysql2/promise');
const bcrypt = require('bcryptjs');
require('dotenv').config();

async function testPasswordVerify() {
  const connection = await mysql.createConnection({
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'zerda_admin'
  });

  try {
    console.log('Testing password verification...\n');
    
    // Get demo user
    const [users] = await connection.execute(
      'SELECT * FROM mobile_users WHERE email = ?',
      ['demo@zerda.com']
    );
    
    if (users.length === 0) {
      console.log('❌ Demo user not found in mobile_users table');
      
      // Check regular users table
      const [regularUsers] = await connection.execute(
        'SELECT * FROM users WHERE email = ?',
        ['demo@zerda.com']
      );
      
      if (regularUsers.length > 0) {
        console.log('ℹ️ User found in users table but not in mobile_users table');
        console.log('Creating mobile user...');
        
        // Create mobile user
        const hashedPassword = await bcrypt.hash('demo123456', 10);
        const userId = require('crypto').randomUUID();
        
        await connection.execute(
          `INSERT INTO mobile_users (id, email, password_hash, full_name, is_verified, created_at) 
           VALUES (?, ?, ?, ?, 1, NOW())`,
          [userId, 'demo@zerda.com', hashedPassword, 'Demo User']
        );
        
        console.log('✅ Mobile user created');
      }
    } else {
      const user = users[0];
      console.log('User found in mobile_users:');
      console.log('  ID:', user.id);
      console.log('  Email:', user.email);
      console.log('  Full Name:', user.full_name);
      console.log('  Verified:', user.is_verified);
      
      // Test password
      const testPassword = 'demo123456';
      const isValid = await bcrypt.compare(testPassword, user.password_hash);
      
      console.log('\nPassword test:');
      console.log('  Testing:', testPassword);
      console.log('  Hash:', user.password_hash.substring(0, 20) + '...');
      console.log('  Valid:', isValid);
      
      if (!isValid) {
        console.log('\nUpdating password...');
        const newHash = await bcrypt.hash('demo123456', 10);
        await connection.execute(
          'UPDATE mobile_users SET password_hash = ? WHERE email = ?',
          [newHash, 'demo@zerda.com']
        );
        console.log('✅ Password updated');
      }
    }
    
  } catch (error) {
    console.error('Error:', error.message);
  } finally {
    await connection.end();
  }
}

testPasswordVerify();