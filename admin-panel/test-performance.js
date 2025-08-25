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

console.log('⚡ Performance Test');
console.log('===================\n');
console.log('Testing notification delivery speed and reliability.\n');

async function sendBulkNotifications(token, count) {
  const startTime = Date.now();
  const results = [];
  
  console.log(`📤 Sending ${count} notifications...\n`);
  
  // Send all notifications in parallel
  const promises = [];
  
  for (let i = 1; i <= count; i++) {
    const message = {
      data: {
        title: `⚡ Performance Test ${i}/${count}`,
        body: `Message ${i} sent at ${new Date().toISOString()}`,
        type: 'info',
        timestamp: new Date().toISOString(),
        messageNumber: i.toString(),
        totalMessages: count.toString()
      },
      android: {
        priority: 'high'
      },
      token: token
    };
    
    const promise = admin.messaging().send(message)
      .then(response => {
        results.push({ 
          num: i, 
          success: true, 
          time: Date.now() - startTime,
          id: response.substring(0, 30)
        });
        return { success: true, num: i };
      })
      .catch(error => {
        results.push({ 
          num: i, 
          success: false, 
          time: Date.now() - startTime,
          error: error.message 
        });
        return { success: false, num: i };
      });
    
    promises.push(promise);
  }
  
  // Wait for all to complete
  await Promise.all(promises);
  
  const endTime = Date.now();
  const totalTime = endTime - startTime;
  
  return { results, totalTime, startTime, endTime };
}

async function runTest() {
  const customerId = 'ffeee61a-8497-4c70-857e-c8f0efb13a2a';
  const notificationCount = 10; // Send 10 notifications for performance test
  
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
      
      const { results, totalTime } = await sendBulkNotifications(
        token.fcm_token, 
        notificationCount
      );
      
      // Calculate statistics
      const successCount = results.filter(r => r.success).length;
      const failureCount = results.filter(r => !r.success).length;
      const avgTime = totalTime / notificationCount;
      
      // Sort by completion time
      results.sort((a, b) => a.time - b.time);
      const fastestTime = results[0]?.time || 0;
      const slowestTime = results[results.length - 1]?.time || 0;
      
      console.log('\n' + '─'.repeat(50));
      console.log('\n📊 Performance Results:\n');
      console.log('─'.repeat(50));
      console.log(`Total notifications: ${notificationCount}`);
      console.log(`✅ Successful: ${successCount}`);
      console.log(`❌ Failed: ${failureCount}`);
      console.log(`Success rate: ${(successCount / notificationCount * 100).toFixed(1)}%`);
      console.log('');
      console.log(`⏱️ Total time: ${totalTime}ms`);
      console.log(`⚡ Average time: ${avgTime.toFixed(2)}ms per notification`);
      console.log(`🚀 Fastest: ${fastestTime}ms`);
      console.log(`🐌 Slowest: ${slowestTime}ms`);
      console.log(`📈 Throughput: ${(notificationCount / (totalTime / 1000)).toFixed(2)} notifications/second`);
      
      if (failureCount > 0) {
        console.log('\n❌ Failed notifications:');
        results.filter(r => !r.success).forEach(r => {
          console.log(`   Message ${r.num}: ${r.error}`);
        });
      }
      
      console.log('\n🎯 Performance Benchmarks:');
      console.log('─'.repeat(50));
      console.log(`[ ] All ${notificationCount} notifications received`);
      console.log(`[ ] Average delivery < 500ms: ${avgTime < 500 ? '✅' : '❌'} (${avgTime.toFixed(0)}ms)`);
      console.log(`[ ] Success rate > 95%: ${successCount / notificationCount > 0.95 ? '✅' : '❌'} (${(successCount / notificationCount * 100).toFixed(0)}%)`);
      console.log(`[ ] No duplicates (should see exactly ${notificationCount} notifications)`);
      console.log(`[ ] Messages in correct order (1 to ${notificationCount})`);
      
      console.log('\n💡 Notes:');
      console.log('- High throughput indicates good server performance');
      console.log('- Check device for notification order and duplicates');
      console.log('- Network latency affects delivery times');
      
      db.close();
      process.exit(0);
    }
  );
}

runTest();