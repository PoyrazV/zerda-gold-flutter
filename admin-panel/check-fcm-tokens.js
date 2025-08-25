const sqlite3 = require('sqlite3').verbose();
const path = require('path');

const DB_PATH = path.join(__dirname, 'zerda_admin.db');
const db = new sqlite3.Database(DB_PATH);

console.log('=== FCM Tokens Status Check ===\n');

db.all(
  `SELECT 
    fcm_token, 
    user_id, 
    user_email, 
    is_authenticated,
    platform,
    device_id,
    datetime(updated_at, 'localtime') as last_updated
   FROM fcm_tokens 
   WHERE customer_id = 'ffeee61a-8497-4c70-857e-c8f0efb13a2a'
   ORDER BY updated_at DESC`,
  [],
  (err, tokens) => {
    if (err) {
      console.error('Error:', err);
      db.close();
      return;
    }
    
    console.log(`Total tokens: ${tokens.length}\n`);
    
    const authTokens = tokens.filter(t => t.is_authenticated === 1);
    const guestTokens = tokens.filter(t => t.is_authenticated === 0);
    
    console.log(`Authenticated tokens: ${authTokens.length}`);
    console.log(`Guest tokens: ${guestTokens.length}\n`);
    
    console.log('Token Details:');
    console.log('─'.repeat(80));
    
    tokens.forEach((token, i) => {
      console.log(`Token ${i + 1}:`);
      console.log(`  FCM Token: ${token.fcm_token.substring(0, 30)}...`);
      console.log(`  User ID: ${token.user_id || 'NULL'}`);
      console.log(`  User Email: ${token.user_email || 'NULL'}`);
      console.log(`  Is Authenticated: ${token.is_authenticated ? 'YES' : 'NO'}`);
      console.log(`  Platform: ${token.platform}`);
      console.log(`  Device ID: ${token.device_id || 'NULL'}`);
      console.log(`  Last Updated: ${token.last_updated}`);
      console.log('─'.repeat(80));
    });
    
    // Check for potential issues
    console.log('\nPotential Issues:');
    const hasUserId = tokens.filter(t => t.user_id && t.user_id !== '');
    const markedAsAuth = tokens.filter(t => t.is_authenticated === 1);
    
    if (hasUserId.length !== markedAsAuth.length) {
      console.log(`⚠️ Mismatch: ${hasUserId.length} tokens have user_id but ${markedAsAuth.length} are marked as authenticated`);
    }
    
    const authWithoutUserId = tokens.filter(t => t.is_authenticated === 1 && (!t.user_id || t.user_id === ''));
    if (authWithoutUserId.length > 0) {
      console.log(`⚠️ ${authWithoutUserId.length} tokens marked as authenticated but have no user_id`);
    }
    
    const guestWithUserId = tokens.filter(t => t.is_authenticated === 0 && t.user_id && t.user_id !== '');
    if (guestWithUserId.length > 0) {
      console.log(`⚠️ ${guestWithUserId.length} tokens marked as guest but have user_id`);
      guestWithUserId.forEach(t => {
        console.log(`   - Token: ${t.fcm_token.substring(0, 30)}... User: ${t.user_email}`);
      });
    }
    
    if (authWithoutUserId.length === 0 && guestWithUserId.length === 0) {
      console.log('✅ No authentication mismatches detected');
    }
    
    db.close();
  }
);