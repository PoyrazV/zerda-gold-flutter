const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database('./zerda_admin.db');

console.log('Testing notification queries directly...\n');

// Test 1: Check notifications table
console.log('1. Checking notifications for customer ffeee61a...');
db.all(
  "SELECT id, title, target, status, created_at FROM notifications WHERE customer_id = 'ffeee61a-8497-4c70-857e-c8f0efb13a2a' AND target = 'authenticated' LIMIT 5",
  (err, rows) => {
    if (err) console.error('Error:', err);
    else {
      console.log(`   Found ${rows.length} authenticated notifications`);
      rows.forEach(r => console.log(`   - ${r.title} (${r.status}) - ${r.created_at}`));
    }
    
    // Test 2: Check notification_deliveries
    console.log('\n2. Checking notification_deliveries...');
    db.all(
      "SELECT * FROM notification_deliveries LIMIT 5",
      (err, rows) => {
        if (err) console.error('Error:', err);
        else console.log(`   Found ${rows.length} delivery records`);
        
        // Test 3: The actual query
        console.log('\n3. Testing the actual pending notifications query...');
        const userId = '90f7e22f-7a7f-48ba-b591-86778ecdbf9d';
        const customerId = 'ffeee61a-8497-4c70-857e-c8f0efb13a2a';
        
        const query = `
          SELECT n.* 
          FROM notifications n
          WHERE n.customer_id = ?
            AND n.target = 'authenticated'
            AND n.status = 'sent'
            AND n.created_at >= datetime('now', '-7 days')
            AND NOT EXISTS (
              SELECT 1 FROM notification_deliveries nd 
              WHERE nd.notification_id = n.id 
              AND nd.user_id = ?
            )
          ORDER BY n.created_at DESC
          LIMIT 20`;
        
        db.all(query, [customerId, userId], (err, rows) => {
          if (err) {
            console.error('   Query error:', err);
          } else {
            console.log(`   Found ${rows.length} pending notifications`);
            if (rows.length > 0) {
              console.log('   First few:');
              rows.slice(0, 3).forEach(r => console.log(`   - ${r.title} (${r.id})`));
            }
          }
          
          db.close();
        });
      }
    );
  }
);