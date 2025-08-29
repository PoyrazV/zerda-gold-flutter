const sqlite3 = require('sqlite3').verbose();
const path = require('path');

const DB_PATH = path.join(__dirname, 'zerda_admin.db');

console.log('🔄 Connecting to database...');

const db = new sqlite3.Database(DB_PATH, (err) => {
  if (err) {
    console.error('❌ Database connection error:', err);
    process.exit(1);
  }
  
  console.log('✅ Database connected');
  
  // First, count existing alarms
  db.get('SELECT COUNT(*) as count FROM user_alerts', (err, result) => {
    if (err) {
      console.error('❌ Error counting alarms:', err);
      db.close();
      process.exit(1);
    }
    
    const alarmCount = result ? result.count : 0;
    console.log(`📊 Found ${alarmCount} alarms in database`);
    
    if (alarmCount === 0) {
      console.log('✅ No alarms to delete');
      db.close();
      process.exit(0);
    }
    
    // Delete all alarms
    console.log('🗑️ Deleting all alarms...');
    
    db.run('DELETE FROM user_alerts', function(err) {
      if (err) {
        console.error('❌ Error deleting alarms:', err);
        db.close();
        process.exit(1);
      }
      
      console.log(`✅ Successfully deleted ${this.changes} alarms from database`);
      
      // Verify deletion
      db.get('SELECT COUNT(*) as count FROM user_alerts', (err, result) => {
        if (err) {
          console.error('❌ Error verifying deletion:', err);
        } else {
          const remaining = result ? result.count : 0;
          console.log(`📊 Remaining alarms in database: ${remaining}`);
        }
        
        db.close((err) => {
          if (err) {
            console.error('❌ Error closing database:', err);
          } else {
            console.log('✅ Database connection closed');
          }
          process.exit(0);
        });
      });
    });
  });
});