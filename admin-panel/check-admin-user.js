const sqlite3 = require('sqlite3').verbose();
const path = require('path');

const DB_PATH = path.join(__dirname, 'zerda_admin.db');
const db = new sqlite3.Database(DB_PATH);

console.log('\n🔍 Checking Admin User...\n');

db.get(
  "SELECT * FROM users WHERE username = 'admin'",
  (err, user) => {
    if (err) {
      console.error('Error:', err);
    } else if (user) {
      console.log('Admin user found:');
      console.log('  ID:', user.id);
      console.log('  Username:', user.username);
      console.log('  Email:', user.email);
      console.log('  Role:', user.role);
      console.log('  Created:', user.created_at);
      console.log('\n✅ Admin user exists in database');
      console.log('   Use credentials: admin / admin123');
    } else {
      console.log('❌ Admin user not found!');
      console.log('\nRun this to create admin user:');
      console.log('  cd admin-panel');
      console.log('  node migrations/seed.js');
    }
    db.close();
  }
);