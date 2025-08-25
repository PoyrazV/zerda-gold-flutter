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

console.log('🎭 Edge Cases Test');
console.log('==================\n');

const edgeCases = [
  {
    name: 'Emoji Test',
    title: '🎉🔥💎 Emoji Bildirim 🚀✨🌟',
    body: 'Emojiler: 😀😃😄😁😆😅🤣😂 Altın 💰 Dolar 💵 Euro 💶'
  },
  {
    name: 'Special Characters',
    title: 'Special <>&"\'` Characters',
    body: 'HTML: <script>alert("test")</script> & SQL: DROP TABLE; -- Comment'
  },
  {
    name: 'Turkish Characters',
    title: 'Türkçe Karakterler: ğüşöçıĞÜŞÖÇİ',
    body: 'İstanbul\'da güzel bir gün. Öğleden sonra çay içelim. Şöyle güzel!'
  },
  {
    name: 'Long Text',
    title: 'Çok Uzun Başlık ' + 'A'.repeat(100),
    body: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. '.repeat(20)
  },
  {
    name: 'Empty Body',
    title: 'Sadece Başlık Var',
    body: ''
  },
  {
    name: 'Numbers and Math',
    title: 'USD: $1,234.56 | EUR: €987.65',
    body: 'Altın: ₺2.345,67 | %15.5 artış | 10²=100 | π≈3.14'
  },
  {
    name: 'Line Breaks',
    title: 'Çok Satırlı Mesaj',
    body: 'Satır 1\nSatır 2\n\nBoş satır sonrası\n\t• Tab ile liste\n\t• İkinci öğe'
  },
  {
    name: 'Unicode Symbols',
    title: '♠♣♥♦ ★☆☀☁ ⚡⚠✓✗',
    body: '←↑→↓ ⌘⌥⌫⏎ ①②③④⑤ ▲▼◀▶'
  }
];

async function sendEdgeCaseNotification(token, edgeCase, index) {
  const message = {
    data: {
      title: edgeCase.title || 'No Title',
      body: edgeCase.body || 'No Body',
      type: 'info',
      timestamp: new Date().toISOString(),
      edgeCaseTest: edgeCase.name,
      testNumber: index.toString()
    },
    android: {
      priority: 'high'
    },
    token: token
  };

  try {
    const response = await admin.messaging().send(message);
    console.log(`✅ ${edgeCase.name}`);
    console.log(`   Title length: ${edgeCase.title.length} chars`);
    console.log(`   Body length: ${edgeCase.body.length} chars`);
    console.log(`   Message ID: ${response.substring(0, 30)}...`);
    return true;
  } catch (error) {
    console.log(`❌ ${edgeCase.name} failed: ${error.message}`);
    return false;
  }
}

async function runTest() {
  const customerId = 'ffeee61a-8497-4c70-857e-c8f0efb13a2a';
  
  db.all(
    `SELECT fcm_token, user_email 
     FROM fcm_tokens 
     WHERE customer_id = ? 
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
      console.log(`📱 Testing with: ${token.user_email || 'Guest'}\n`);
      console.log(`📤 Sending ${edgeCases.length} edge case notifications...\n`);
      
      let successCount = 0;
      
      for (let i = 0; i < edgeCases.length; i++) {
        const success = await sendEdgeCaseNotification(
          token.fcm_token, 
          edgeCases[i], 
          i + 1
        );
        if (success) successCount++;
        
        // Wait 1 second between notifications
        if (i < edgeCases.length - 1) {
          await new Promise(resolve => setTimeout(resolve, 1000));
        }
      }
      
      console.log('\n' + '─'.repeat(50));
      console.log('\n📊 Test Summary:\n');
      console.log(`✅ Successfully sent: ${successCount}/${edgeCases.length}`);
      
      console.log('\n🔍 Check Results:');
      console.log('─'.repeat(50));
      edgeCases.forEach((ec, i) => {
        console.log(`${i + 1}. ${ec.name}:`);
        console.log(`   - Should display correctly`);
        console.log(`   - No encoding issues`);
        console.log(`   - No security breaches`);
      });
      
      console.log('\n✨ Success Criteria:');
      console.log('[ ] All emojis display correctly');
      console.log('[ ] Special characters are escaped safely');
      console.log('[ ] Turkish characters show properly');
      console.log('[ ] Long text is truncated appropriately');
      console.log('[ ] Empty body handled gracefully');
      console.log('[ ] No XSS or injection vulnerabilities');
      console.log('[ ] Unicode symbols render correctly');
      console.log('[ ] Line breaks preserved where applicable');
      
      db.close();
      process.exit(0);
    }
  );
}

runTest();