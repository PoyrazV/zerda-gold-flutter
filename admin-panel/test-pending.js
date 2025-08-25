const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database('./zerda_admin.db');

const customerId = 'ffeee61a-8497-4c70-857e-c8f0efb13a2a';
const userId = '90f7e22f-7a7f-48ba-b591-86778ecdbf9d';

console.log('Testing pending notifications query...');
console.log('Customer ID:', customerId);
console.log('User ID:', userId);

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
  LIMIT 10`;

db.all(query, [customerId, userId], (err, rows) => {
  if (err) {
    console.log('Error:', err);
  } else {
    console.log('\nPending notifications found:', rows?.length || 0);
    if (rows && rows.length > 0) {
      console.log('\nNotifications:');
      rows.forEach((row, i) => {
        console.log(`${i+1}. ${row.title} (${row.id}) - Created: ${row.created_at}`);
      });
    }
  }
  db.close();
});