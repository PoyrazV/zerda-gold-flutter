const admin = require('firebase-admin');
const sqlite3 = require('sqlite3').verbose();
const path = require('path');

// Initialize Firebase Admin
const serviceAccount = require('./firebase-service-account.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: serviceAccount.project_id
});

const dbPath = path.join(__dirname, 'zerda_admin.db');
const db = new sqlite3.Database(dbPath, sqlite3.OPEN_READONLY);

console.log('🎨 Testing Different Notification Types');
console.log('========================================\n');

async function sendNotificationWithType(token, type, index) {
  const typeConfig = {
    'info': { icon: 'ℹ️', title: 'Bilgi Mesajı', body: 'Bu bir bilgilendirme mesajıdır.' },
    'success': { icon: '✅', title: 'Başarılı İşlem', body: 'İşleminiz başarıyla tamamlandı!' },
    'warning': { icon: '⚠️', title: 'Uyarı', body: 'Dikkat edilmesi gereken bir durum var.' },
    'error': { icon: '❌', title: 'Hata', body: 'Bir hata oluştu, lütfen tekrar deneyin.' }
  };

  const config = typeConfig[type];
  
  const message = {
    data: {
      title: `${config.icon} ${config.title}`,
      body: config.body,
      type: type,
      timestamp: new Date().toISOString(),
      testNumber: index.toString()
    },
    android: {
      priority: 'high'
    },
    token: token
  };

  try {
    const response = await admin.messaging().send(message);
    console.log(`${config.icon} ${type.toUpperCase()} notification sent!`);
    console.log(`   Message ID: ${response.substring(0, 50)}...`);
    return true;
  } catch (error) {
    console.log(`❌ Failed to send ${type} notification:`, error.message);
    return false;
  }
}

async function testAllTypes() {
  const customerId = 'ffeee61a-8497-4c70-857e-c8f0efb13a2a';
  
  db.all(
    `SELECT fcm_token, user_email, is_authenticated 
     FROM fcm_tokens 
     WHERE customer_id = ? 
     ORDER BY is_authenticated DESC
     LIMIT 1`,
    [customerId],
    async (err, tokens) => {
      if (err) {
        console.error('Database error:', err);
        db.close();
        return;
      }
      
      if (tokens.length === 0) {
        console.log('❌ No tokens found!');
        db.close();
        process.exit(1);
      }
      
      const token = tokens[0];
      console.log(`📱 Testing with token for: ${token.user_email || 'Guest'}\n`);
      
      const types = ['info', 'success', 'warning', 'error'];
      let successCount = 0;
      
      console.log('📤 Sending notifications with 2-second delays...\n');
      
      for (let i = 0; i < types.length; i++) {
        const success = await sendNotificationWithType(token.fcm_token, types[i], i + 1);
        if (success) successCount++;
        
        // Wait 2 seconds between notifications
        if (i < types.length - 1) {
          await new Promise(resolve => setTimeout(resolve, 2000));
        }
      }
      
      console.log('\n📊 Test Results:');
      console.log(`✅ Successfully sent: ${successCount}/${types.length}`);
      console.log('\n🔍 Check the app for:');
      console.log('   - 4 different notifications');
      console.log('   - Each with different icon and color');
      console.log('   - NO duplicates for any notification');
      
      db.close();
      process.exit(0);
    }
  );
}

testAllTypes();