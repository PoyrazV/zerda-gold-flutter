const fetch = require('node-fetch');

// Configuration
const API_URL = 'http://localhost:3009';
const ADMIN_USERNAME = 'admin';
const ADMIN_PASSWORD = 'admin123';
const CUSTOMER_ID = 'ffeee61a-8497-4c70-857e-c8f0efb13a2a'; // Default customer ID

async function testScheduledNotification() {
    console.log('🔧 Testing Scheduled Notification System...\n');
    
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
        
        // Step 2: Create a notification scheduled for 2 minutes from now
        const scheduledTime = new Date(Date.now() + 2 * 60 * 1000); // 2 minutes from now
        const scheduledTimeISO = scheduledTime.toISOString();
        
        console.log('2️⃣ Creating scheduled notification...');
        console.log(`   Scheduled for: ${scheduledTime.toLocaleString('tr-TR')}`);
        console.log(`   ISO format: ${scheduledTimeISO}`);
        
        const notificationPayload = {
            title: 'Test Zamanlanmış Bildirim',
            message: 'Bu bildirim 2 dakika sonra gönderilecek',
            type: 'info',
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
                console.log('📝 The cron job will process it when the time comes.');
            } else {
                console.log('\n⚠️ WARNING: Notification status is', ourNotification.status, 'instead of "scheduled"');
            }
        } else {
            console.log('❌ ERROR: Could not find the notification in the list');
        }
        
        // Step 4: Test immediate notification for comparison
        console.log('\n4️⃣ Creating immediate notification for comparison...');
        const immediatePayload = {
            title: 'Test Anında Bildirim',
            message: 'Bu bildirim hemen gönderilecek',
            type: 'success',
            target: 'all'
            // No scheduled_time means immediate
        };
        
        const immediateResponse = await fetch(`${API_URL}/api/customers/${CUSTOMER_ID}/notifications`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}`
            },
            body: JSON.stringify(immediatePayload)
        });
        
        const immediateData = await immediateResponse.json();
        if (immediateData.success) {
            console.log('✅ Immediate notification sent successfully');
            console.log('   Status:', immediateData.data.status);
        }
        
        console.log('\n🎉 Test completed successfully!');
        console.log('📌 Check the database or wait 2 minutes to see if the scheduled notification is sent.');
        
    } catch (error) {
        console.error('❌ Test failed:', error.message);
        process.exit(1);
    }
}

// Run the test
testScheduledNotification();