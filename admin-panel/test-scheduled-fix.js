const fetch = require('node-fetch');

// Configuration
const API_URL = 'http://localhost:3009';
const ADMIN_USERNAME = 'admin';
const ADMIN_PASSWORD = 'admin123';
const CUSTOMER_ID = 'ffeee61a-8497-4c70-857e-c8f0efb13a2a'; // Default customer ID

async function testScheduledNotificationFix() {
    console.log('🔧 Testing Fixed Scheduled Notification System...\n');
    console.log('📝 This test will create notifications scheduled for 1 minute from now\n');
    
    try {
        // Step 1: Login
        console.log('1️⃣ Logging in...');
        const loginResponse = await fetch(`${API_URL}/api/auth/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                username: ADMIN_USERNAME,
                password: ADMIN_PASSWORD
            })
        });
        
        const loginData = await loginResponse.json();
        if (!loginData.success) {
            throw new Error('Login failed: ' + loginData.error);
        }
        
        const token = loginData.data.token;
        console.log('✅ Login successful!\n');
        
        // Step 2: Create a notification scheduled for 1 minute from now
        const scheduledTime = new Date(Date.now() + 1 * 60 * 1000); // 1 minute from now
        const scheduledTimeISO = scheduledTime.toISOString();
        
        console.log('2️⃣ Creating scheduled notification...');
        console.log(`   Current time: ${new Date().toLocaleString('tr-TR')}`);
        console.log(`   Scheduled for: ${scheduledTime.toLocaleString('tr-TR')}`);
        console.log(`   ISO format: ${scheduledTimeISO}`);
        console.log(`   Timezone offset: ${new Date().getTimezoneOffset()} minutes`);
        
        const notificationPayload = {
            title: 'Test Zamanlanmış Bildirim (1 Dakika)',
            message: 'Bu bildirim 1 dakika sonra gönderilecek - Fix Test',
            type: 'warning',
            target: 'all',
            scheduled_time: scheduledTimeISO
        };
        
        const createResponse = await fetch(`${API_URL}/api/customers/${CUSTOMER_ID}/notifications`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}`
            },
            body: JSON.stringify(notificationPayload)
        });
        
        const createData = await createResponse.json();
        if (!createData.success) {
            throw new Error('Failed to create notification: ' + createData.error);
        }
        
        const notificationId = createData.data.id;
        console.log('✅ Notification created with ID:', notificationId);
        console.log('   Status:', createData.data.status);
        console.log('   Message:', createData.message, '\n');
        
        // Step 3: Check notification status
        console.log('3️⃣ Checking notification status...');
        const checkResponse = await fetch(`${API_URL}/api/customers/${CUSTOMER_ID}/notifications`, {
            headers: {
                'Authorization': `Bearer ${token}`
            }
        });
        
        const notifications = await checkResponse.json();
        const ourNotification = notifications.data.find(n => n.id === notificationId);
        
        if (ourNotification) {
            console.log('📋 Notification Details:');
            console.log('   ID:', ourNotification.id);
            console.log('   Title:', ourNotification.title);
            console.log('   Status:', ourNotification.status);
            console.log('   Scheduled Time:', ourNotification.scheduled_time);
            console.log('   Created At:', ourNotification.created_at);
            
            if (ourNotification.status === 'scheduled') {
                console.log('\n✅ SUCCESS: Notification is properly scheduled!');
                console.log(`⏰ It will be sent at ${new Date(ourNotification.scheduled_time).toLocaleString('tr-TR')}`);
                console.log('📝 The cron job will process it in approximately 1 minute.');
                
                // Step 4: Monitor the notification
                console.log('\n4️⃣ Monitoring notification status (will check every 20 seconds for 2 minutes)...\n');
                
                let checks = 0;
                const maxChecks = 6; // Check 6 times (2 minutes total)
                
                const checkInterval = setInterval(async () => {
                    checks++;
                    
                    const monitorResponse = await fetch(`${API_URL}/api/customers/${CUSTOMER_ID}/notifications`, {
                        headers: {
                            'Authorization': `Bearer ${token}`
                        }
                    });
                    
                    const monitorData = await monitorResponse.json();
                    const monitoredNotification = monitorData.data.find(n => n.id === notificationId);
                    
                    const currentTime = new Date();
                    console.log(`[Check ${checks}/${maxChecks}] ${currentTime.toLocaleTimeString('tr-TR')}`);
                    
                    if (monitoredNotification) {
                        console.log(`   Status: ${monitoredNotification.status}`);
                        
                        if (monitoredNotification.status === 'sent') {
                            console.log(`   ✅ NOTIFICATION SENT at ${monitoredNotification.sent_at}!`);
                            console.log('\n🎉 Test completed successfully! Scheduled notification system is working!');
                            clearInterval(checkInterval);
                            process.exit(0);
                        } else if (monitoredNotification.status === 'scheduled') {
                            const timeLeft = Math.ceil((new Date(monitoredNotification.scheduled_time) - currentTime) / 1000);
                            console.log(`   ⏳ Still scheduled, ${timeLeft} seconds remaining`);
                        } else {
                            console.log(`   ⚠️ Unexpected status: ${monitoredNotification.status}`);
                        }
                    } else {
                        console.log('   ❌ Notification not found');
                    }
                    
                    if (checks >= maxChecks) {
                        console.log('\n⚠️ Test timed out. Notification was not sent within 2 minutes.');
                        console.log('Check server logs for cron job execution details.');
                        clearInterval(checkInterval);
                        process.exit(1);
                    }
                }, 20000); // Check every 20 seconds
                
            } else if (ourNotification.status === 'sent') {
                console.log('\n⚠️ WARNING: Notification was sent immediately instead of being scheduled!');
                console.log('This indicates the scheduling fix did not work properly.');
                process.exit(1);
            } else {
                console.log('\n⚠️ WARNING: Notification status is', ourNotification.status, 'instead of "scheduled"');
                process.exit(1);
            }
        } else {
            console.log('❌ ERROR: Could not find the notification in the list');
            process.exit(1);
        }
        
    } catch (error) {
        console.error('❌ Test failed:', error.message);
        process.exit(1);
    }
}

// Run the test
console.log('========================================');
console.log('   SCHEDULED NOTIFICATION FIX TEST');
console.log('========================================\n');
testScheduledNotificationFix();