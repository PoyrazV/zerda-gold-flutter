const fetch = require('node-fetch');

// Configuration
const API_URL = 'http://localhost:3009';
const ADMIN_USERNAME = 'admin';
const ADMIN_PASSWORD = 'admin123';
const CUSTOMER_ID = 'ffeee61a-8497-4c70-857e-c8f0efb13a2a';

async function debugTimeHandling() {
    console.log('🔍 Debugging Time Handling for Scheduled Notifications\n');
    console.log('========================================');
    console.log('LOCAL SYSTEM TIME INFORMATION:');
    console.log('========================================');
    
    const now = new Date();
    console.log('Current Date Object:', now);
    console.log('ISO String:', now.toISOString());
    console.log('Local String:', now.toString());
    console.log('Locale String (tr-TR):', now.toLocaleString('tr-TR'));
    console.log('Timezone Offset (minutes):', now.getTimezoneOffset());
    console.log('Timestamp (ms):', now.getTime());
    
    console.log('\n========================================');
    console.log('TESTING DIFFERENT SCHEDULED TIMES:');
    console.log('========================================\n');
    
    try {
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
        
        // Test cases with different time offsets
        const testCases = [
            { minutes: 0.25, label: '15 seconds' },
            { minutes: 0.75, label: '45 seconds' },
            { minutes: 1, label: '1 minute' },
            { minutes: 2, label: '2 minutes' },
            { minutes: 5, label: '5 minutes' }
        ];
        
        for (const testCase of testCases) {
            console.log(`\n📅 Testing: Notification scheduled for ${testCase.label} from now`);
            console.log('----------------------------------------');
            
            const scheduledTime = new Date(Date.now() + testCase.minutes * 60 * 1000);
            const scheduledTimeISO = scheduledTime.toISOString();
            
            console.log('  Current time (ms):', now.getTime());
            console.log('  Scheduled time (ms):', scheduledTime.getTime());
            console.log('  Difference (ms):', scheduledTime.getTime() - now.getTime());
            console.log('  Scheduled ISO:', scheduledTimeISO);
            console.log('  Scheduled Local:', scheduledTime.toLocaleString('tr-TR'));
            
            const notificationPayload = {
                title: `Debug Test - ${testCase.label}`,
                message: `Should be scheduled for ${testCase.label} from creation`,
                type: 'info',
                target: 'all',
                scheduled_time: scheduledTimeISO
            };
            
            console.log('  Sending payload:', JSON.stringify(notificationPayload, null, 2));
            
            const createResponse = await fetch(`${API_URL}/api/customers/${CUSTOMER_ID}/notifications`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify(notificationPayload)
            });
            
            const createData = await createResponse.json();
            
            if (createData.success) {
                console.log(`  ✅ Result: ${createData.message}`);
                console.log(`     Status: ${createData.data.status}`);
                console.log(`     ID: ${createData.data.id}`);
                
                if (createData.data.status === 'scheduled') {
                    console.log('     ✅ CORRECTLY SCHEDULED');
                } else if (createData.data.status === 'sent') {
                    console.log('     ❌ INCORRECTLY SENT IMMEDIATELY');
                }
            } else {
                console.log(`  ❌ Failed: ${createData.error}`);
            }
        }
        
        console.log('\n========================================');
        console.log('CHECK SERVER CONSOLE OUTPUT');
        console.log('========================================');
        console.log('The server should have logged detailed information about each notification.');
        console.log('Look for lines starting with "📅 Scheduled notification check:"');
        console.log('\nIf notifications with >30 seconds are being sent immediately,');
        console.log('check the server logs for the time comparison details.');
        
    } catch (error) {
        console.error('\n❌ Test failed:', error.message);
    }
}

// Run debug
debugTimeHandling();