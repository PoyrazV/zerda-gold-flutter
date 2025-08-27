const fetch = require('node-fetch');

// Configuration
const API_URL = 'http://localhost:3009';
const ADMIN_USERNAME = 'admin';
const ADMIN_PASSWORD = 'admin123';
const CUSTOMER_ID = 'ffeee61a-8497-4c70-857e-c8f0efb13a2a';

async function testDatetimeLocalFormat() {
    console.log('🔧 Testing datetime-local Format Fix\n');
    console.log('========================================');
    console.log('This test simulates how the admin panel sends datetime values');
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
        
        // Test 1: Simulate datetime-local format (without seconds, without Z)
        console.log('📅 Test 1: datetime-local format (as sent by admin panel)');
        console.log('----------------------------------------');
        
        const now = new Date();
        const in2Minutes = new Date(now.getTime() + 2 * 60 * 1000);
        
        // Format as datetime-local would (YYYY-MM-DDTHH:mm)
        const year = in2Minutes.getFullYear();
        const month = String(in2Minutes.getMonth() + 1).padStart(2, '0');
        const day = String(in2Minutes.getDate()).padStart(2, '0');
        const hours = String(in2Minutes.getHours()).padStart(2, '0');
        const minutes = String(in2Minutes.getMinutes()).padStart(2, '0');
        
        const datetimeLocalFormat = `${year}-${month}-${day}T${hours}:${minutes}`;
        
        console.log('  Current time:', now.toLocaleString('tr-TR'));
        console.log('  Target time:', in2Minutes.toLocaleString('tr-TR'));
        console.log('  datetime-local format:', datetimeLocalFormat);
        console.log('  (Note: No seconds, no Z suffix)\n');
        
        const payload1 = {
            title: 'Test datetime-local Format',
            message: 'Should be scheduled 2 minutes from now',
            type: 'warning',
            target: 'all',
            scheduled_time: datetimeLocalFormat // This is how admin panel sends it
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
            console.log(`  ✅ Result: ${data1.message}`);
            console.log(`     Status: ${data1.data.status}`);
            
            if (data1.data.status === 'scheduled') {
                console.log('     ✅ SUCCESS: Correctly scheduled!');
                console.log(`     Will be sent at: ${new Date(data1.data.scheduled_time).toLocaleString('tr-TR')}`);
            } else if (data1.data.status === 'sent') {
                console.log('     ❌ FAILED: Sent immediately instead of being scheduled!');
            }
        } else {
            console.log(`  ❌ Failed: ${data1.error}`);
        }
        
        // Test 2: ISO format (as sent by test scripts)
        console.log('\n📅 Test 2: ISO format (as sent by test scripts)');
        console.log('----------------------------------------');
        
        const in3Minutes = new Date(now.getTime() + 3 * 60 * 1000);
        const isoFormat = in3Minutes.toISOString();
        
        console.log('  Target time:', in3Minutes.toLocaleString('tr-TR'));
        console.log('  ISO format:', isoFormat);
        console.log('  (Note: Has seconds and Z suffix)\n');
        
        const payload2 = {
            title: 'Test ISO Format',
            message: 'Should be scheduled 3 minutes from now',
            type: 'info',
            target: 'all',
            scheduled_time: isoFormat
        };
        
        const response2 = await fetch(`${API_URL}/api/customers/${CUSTOMER_ID}/notifications`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}`
            },
            body: JSON.stringify(payload2)
        });
        
        const data2 = await response2.json();
        
        if (data2.success) {
            console.log(`  ✅ Result: ${data2.message}`);
            console.log(`     Status: ${data2.data.status}`);
            
            if (data2.data.status === 'scheduled') {
                console.log('     ✅ SUCCESS: Correctly scheduled!');
                console.log(`     Will be sent at: ${new Date(data2.data.scheduled_time).toLocaleString('tr-TR')}`);
            } else if (data2.data.status === 'sent') {
                console.log('     ❌ FAILED: Sent immediately instead of being scheduled!');
            }
        } else {
            console.log(`  ❌ Failed: ${data2.error}`);
        }
        
        console.log('\n========================================');
        console.log('SUMMARY:');
        console.log('========================================');
        console.log('If both tests show "scheduled" status, the fix is working!');
        console.log('Check the server console for detailed logging.');
        console.log('\n⚠️ Remember: Server must be restarted after the fix!');
        
    } catch (error) {
        console.error('\n❌ Test failed:', error.message);
    }
}

// Run test
testDatetimeLocalFormat();