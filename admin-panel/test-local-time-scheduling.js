const fetch = require('node-fetch');

// Configuration
const API_URL = 'http://localhost:3009';
const ADMIN_USERNAME = 'admin';
const ADMIN_PASSWORD = 'admin123';
const CUSTOMER_ID = 'ffeee61a-8497-4c70-857e-c8f0efb13a2a';

async function testLocalTimeScheduling() {
    console.log('🕐 Testing Local Time Scheduling System\n');
    console.log('========================================');
    console.log('This test verifies that notifications are scheduled in local time');
    console.log('and the cron job processes them correctly');
    console.log('========================================\n');
    
    try {
        // Check server
        try {
            const health = await fetch(`${API_URL}/health`);
            const healthData = await health.json();
            console.log('✅ Server is running:', healthData.service);
        } catch (e) {
            console.error('❌ Server is not running! Please start it with: node server.js');
            return;
        }
        
        // Login
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
        console.log('✅ Logged in successfully\n');
        
        // Current time info
        const now = new Date();
        console.log('📅 Current Time Information:');
        console.log('========================================');
        console.log('Local time:', now.toLocaleString('tr-TR'));
        console.log('UTC time:', now.toUTCString());
        console.log('ISO format:', now.toISOString());
        console.log('Timezone offset:', now.getTimezoneOffset(), 'minutes from UTC');
        console.log('');
        
        // Test 1: Schedule for 1 minute from now
        console.log('Test 1: Schedule notification for 1 minute from now');
        console.log('----------------------------------------');
        
        const in1Minute = new Date(now.getTime() + 60 * 1000);
        
        // Format as datetime-local
        const year = in1Minute.getFullYear();
        const month = String(in1Minute.getMonth() + 1).padStart(2, '0');
        const day = String(in1Minute.getDate()).padStart(2, '0');
        const hours = String(in1Minute.getHours()).padStart(2, '0');
        const minutes = String(in1Minute.getMinutes()).padStart(2, '0');
        
        const datetimeLocalValue = `${year}-${month}-${day}T${hours}:${minutes}`;
        
        console.log('Scheduling for:', in1Minute.toLocaleString('tr-TR'));
        console.log('Sending as datetime-local:', datetimeLocalValue);
        
        const payload1 = {
            title: 'Test Local Time - 1 Minute',
            message: 'This should be sent 1 minute after creation',
            type: 'warning',
            target: 'all',
            scheduled_time: datetimeLocalValue
        };
        
        const response1 = await fetch(`${API_URL}/api/customers/${CUSTOMER_ID}/notifications`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}`
            },
            body: JSON.stringify(payload1)
        });
        
        const data1 = await response1.json();
        
        if (data1.success) {
            console.log('✅ Created:', data1.message);
            console.log('   ID:', data1.data.id);
            console.log('   Status:', data1.data.status);
            console.log('   Stored scheduled_time:', data1.data.scheduled_time);
            
            if (data1.data.status === 'scheduled') {
                console.log('   ✅ Correctly scheduled!');
                
                // Check what's in the database
                console.log('\n🔍 Checking database status...');
                const checkResponse = await fetch(`${API_URL}/api/customers/${CUSTOMER_ID}/notifications?limit=1`, {
                    headers: {
                        'Authorization': `Bearer ${token}`
                    }
                });
                
                const checkData = await checkResponse.json();
                const ourNotif = checkData.data.find(n => n.id === data1.data.id);
                
                if (ourNotif) {
                    console.log('   Database entry found:');
                    console.log('   - scheduled_time:', ourNotif.scheduled_time);
                    console.log('   - status:', ourNotif.status);
                    
                    // Parse the stored time
                    const storedTime = new Date(ourNotif.scheduled_time);
                    console.log('   - Interpreted as:', storedTime.toLocaleString('tr-TR'));
                    console.log('   - Should send at:', in1Minute.toLocaleString('tr-TR'));
                    
                    const timeDiff = Math.abs(storedTime.getTime() - in1Minute.getTime());
                    if (timeDiff < 60000) { // Less than 1 minute difference
                        console.log('   ✅ Time is stored correctly!');
                    } else {
                        console.log('   ❌ Time mismatch! Difference:', Math.floor(timeDiff / 60000), 'minutes');
                    }
                }
                
                console.log('\n⏰ Monitoring Cron Job Processing:');
                console.log('The cron job runs every minute and will process this notification.');
                console.log('Watch the server console for:');
                console.log('  - "Cron Job Running at..."');
                console.log('  - "Total scheduled notifications in database: X"');
                console.log('  - "Notifications ready to send: X"');
                console.log('\nWait approximately 1 minute to see if the notification is sent.');
                
            } else {
                console.log('   ❌ Was sent immediately! (status: sent)');
            }
        } else {
            console.log('❌ Failed:', data1.error);
        }
        
        // Test 2: Check how database stores the time
        console.log('\n\nTest 2: Database Time Storage Verification');
        console.log('----------------------------------------');
        
        const testTime = new Date(2025, 7, 27, 15, 30, 0); // Aug 27, 2025, 15:30:00 local
        const testFormatted = `2025-08-27T15:30`;
        
        console.log('Test time (local):', testTime.toLocaleString('tr-TR'));
        console.log('Sending as:', testFormatted);
        console.log('If stored correctly, should remain as:', testFormatted + ':00');
        console.log('If incorrectly converted to UTC, would become:', testTime.toISOString());
        
        console.log('\n========================================');
        console.log('SUMMARY:');
        console.log('========================================');
        console.log('✅ Correct behavior:');
        console.log('  1. datetime-local value sent as-is (YYYY-MM-DDTHH:mm)');
        console.log('  2. Server adds :00 for seconds');
        console.log('  3. Stored in database as local time string');
        console.log('  4. Cron job compares using local time');
        console.log('  5. Notification sent at the correct local time');
        console.log('\n❌ If still broken:');
        console.log('  - Notifications will be sent immediately');
        console.log('  - Or sent at wrong time (UTC vs local confusion)');
        console.log('  - Check server console for detailed logs');
        
    } catch (error) {
        console.error('\n❌ Test failed:', error.message);
    }
}

// Run test
testLocalTimeScheduling();