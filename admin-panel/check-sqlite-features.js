const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database('zerda_admin.db');

console.log('🔍 Checking SQLite feature tables...\n');

// Check customer_features
db.all('SELECT * FROM customer_features WHERE customer_id = ?', ['ffeee61a-8497-4c70-857e-c8f0efb13a2a'], (err, features) => {
  if (err) {
    console.log('❌ customer_features error:', err.message);
    
    // Try app_features
    db.all('SELECT * FROM app_features', (err2, features2) => {
      if (err2) {
        console.log('❌ app_features error:', err2.message);
        
        // Show all tables with "feature" in name
        db.all(`SELECT name FROM sqlite_master WHERE type='table' AND name LIKE '%feature%'`, (err3, tables) => {
          console.log('\n📊 Tables containing "feature":');
          tables.forEach(table => console.log('   -', table.name));
          db.close();
        });
      } else {
        console.log('✅ app_features found:', features2.length, 'features');
        features2.forEach((feature, index) => {
          console.log(`   ${index + 1}. ${feature.feature_name || feature.name}: ${feature.enabled || feature.is_enabled ? '✅' : '❌'}`);
        });
        db.close();
      }
    });
  } else {
    console.log('✅ customer_features found:', features.length, 'features');
    features.forEach((feature, index) => {
      console.log(`   ${index + 1}. ${feature.feature_name || feature.name}: ${feature.enabled || feature.is_enabled ? '✅' : '❌'}`);
    });
    db.close();
  }
});