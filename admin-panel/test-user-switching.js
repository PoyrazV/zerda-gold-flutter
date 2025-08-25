const sqlite3 = require('sqlite3').verbose();
const path = require('path');

const dbPath = path.join(__dirname, 'zerda_admin.db');
const db = new sqlite3.Database(dbPath, sqlite3.OPEN_READONLY);

console.log('🧪 User Switching Notification Test');
console.log('=====================================\n');

// Test scenarios
console.log('📋 Test Senaryoları:\n');
console.log('1. Giriş yapmadan önce (Misafir)');
console.log('   - Guest bildirimlerini almalısınız');
console.log('   - Authenticated bildirimlerini ALMAMALISINIZ\n');

console.log('2. Zahan Poyraz olarak giriş yaptığınızda');
console.log('   - Authenticated bildirimlerini almalısınız');
console.log('   - Guest bildirimlerini ALMAMALISINIZ\n');

console.log('3. Çıkış yaptığınızda');
console.log('   - Tekrar guest bildirimlerini almalısınız\n');

console.log('4. Başka kullanıcı ile giriş yaptığınızda');
console.log('   - O kullanıcıya özel bildirimleri almalısınız\n');

// Check current FCM tokens
console.log('📱 Mevcut FCM Token Durumu:\n');

db.all(
  `SELECT 
    fcm_token,
    device_id,
    user_id,
    user_email,
    is_authenticated,
    customer_id,
    updated_at
   FROM fcm_tokens
   ORDER BY updated_at DESC`,
  [],
  (err, tokens) => {
    if (err) {
      console.error('Error:', err);
      db.close();
      return;
    }

    if (tokens.length === 0) {
      console.log('⚠️  Hiç FCM token bulunamadı!');
      console.log('   Lütfen uygulamayı çalıştırın: flutter run\n');
    } else {
      tokens.forEach((token, index) => {
        console.log(`Token #${index + 1}:`);
        console.log(`  Device ID: ${token.device_id || 'YOK (Sorun!)'}`);
        console.log(`  User: ${token.user_email || 'Misafir'}`);
        console.log(`  Authenticated: ${token.is_authenticated ? 'EVET' : 'HAYIR'}`);
        console.log(`  Customer: ${token.customer_id}`);
        console.log(`  Last Update: ${token.updated_at}`);
        console.log('');
      });
    }

    // Test instructions
    console.log('🔧 Test Adımları:\n');
    console.log('1. Flutter uygulamasını çalıştırın:');
    console.log('   flutter run\n');
    
    console.log('2. Admin paneli başlatın:');
    console.log('   cd admin-panel && npm start\n');
    
    console.log('3. Admin panelden bildirim gönderin:');
    console.log('   - "Misafirlere" seçeneği ile');
    console.log('   - "Giriş Yapmış Kullanıcılara" seçeneği ile\n');
    
    console.log('4. Uygulamada giriş/çıkış yapın ve tekrar test edin\n');
    
    console.log('5. FCM token durumunu kontrol edin:');
    console.log('   node check-user-fcm-tokens.js\n');

    // Check for issues
    console.log('🔍 Potansiyel Sorunlar:\n');
    
    const noDeviceId = tokens.filter(t => !t.device_id);
    if (noDeviceId.length > 0) {
      console.log(`❌ ${noDeviceId.length} token'da device_id eksik!`);
      console.log('   Bu token\'lar düzgün çalışmayacak.\n');
    }

    const multipleTokens = tokens.length > 1;
    if (multipleTokens) {
      console.log(`⚠️  Birden fazla token var (${tokens.length})!`);
      console.log('   Duplicate bildirimler alabilirsiniz.\n');
    }

    const wrongCustomer = tokens.filter(t => t.customer_id !== 'ffeee61a-8497-4c70-857e-c8f0efb13a2a');
    if (wrongCustomer.length > 0) {
      console.log(`❌ ${wrongCustomer.length} token yanlış customer ID'ye sahip!`);
      console.log('   Bu token\'lar bildirim almayacak.\n');
    }

    if (noDeviceId.length === 0 && !multipleTokens && wrongCustomer.length === 0) {
      console.log('✅ Token yapılandırması doğru görünüyor!\n');
    }

    db.close();
  }
);