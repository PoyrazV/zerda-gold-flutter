const fetch = require('node-fetch');

// Configuration
const API_URL = 'http://localhost:3009';
const ADMIN_USERNAME = 'admin';
const ADMIN_PASSWORD = 'admin123';
const CUSTOMER_ID = 'ffeee61a-8497-4c70-857e-c8f0efb13a2a';

async function testAdminPanelFormat() {
    console.log('🎯 Testing Admin Panel Datetime Format\n');
    console.log('This test simulates EXACTLY what the admin panel now sends');
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
        
        // Create datetime-local value exactly as HTML input would
        const now = new Date();
        const futureTime = new Date(now.getTime() + 2 * 60 * 1000); // 2 minutes from now
        
        // Format as YYYY-MM-DDTHH:mm (exactly what datetime-local gives)
        const year = futureTime.getFullYear();
        const month = String(futureTime.getMonth() + 1).padStart(2, '0');
        const day = String(futureTime.getDate()).padStart(2, '0');
        const hours = String(futureTime.getHours()).padStart(2, '0');
        const minutes = String(futureTime.getMinutes()).padStart(2, '0');
        
        const datetimeLocalValue = `${year}-${month}-${day}T${hours}:${minutes}`;
        
        console.log('📅 Admin Panel Format Test');
        console.log('========================================');
        console.log('Current time:', now.toLocaleString('tr-TR'));
        console.log('Target time:', futureTime.toLocaleString('tr-TR'));
        console.log('Admin panel sends:', datetimeLocalValue);
        console.log('Format details:');
        console.log('  - Length:', datetimeLocalValue.length, 'characters');
        console.log('  - Has seconds?: No');
        console.log('  - Has Z suffix?: No');
        console.log('  - Format: YYYY-MM-DDTHH:mm\n');
        
        // Send exactly what admin panel would send
        const payload = {
            title: 'Admin Panel Test',
            message: 'This simulates admin panel sending datetime-local directly',
            type: 'warning',
            target: 'all',
            scheduled_time: datetimeLocalValue  // No conversion, raw datetime-local
        };
        
        console.log('📤 Sending payload:', JSON.stringify(payload, null, 2));
        
        const response = await fetch(`${API_URL}/api/customers/${CUSTOMER_ID}/notifications`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}`
            },
            body: JSON.stringify(payload)
        });
        
        const data = await response.json();
        
        console.log('\n📥 Server Response:');
        console.log('========================================');
        
        if (data.success) {
            console.log('✅ Success:', data.message);
            console.log('Notification ID:', data.data.id);
            console.log('Status:', data.data.status);
            console.log('Scheduled for:', data.data.scheduled_time);
            
            if (data.data.status === 'scheduled') {
                console.log('\n🎉 SUCCESS! Notification is properly scheduled!');
                console.log('The notification will be sent at:', 
                    new Date(data.data.scheduled_time).toLocaleString('tr-TR'));
                console.log('\n✅ Admin panel datetime format is now working correctly!');
            } else if (data.data.status === 'sent') {
                console.log('\n❌ PROBLEM: Notification was sent immediately!');
                console.log('Expected: scheduled');
                console.log('Got: sent');
                console.log('\nThis means the server-side fix is not working properly.');
                console.log('Check that:');
                console.log('1. Server has been restarted after the fix');
                console.log('2. The datetime parsing logic is correct');
            }
        } else {
            console.log('❌ Error:', data.error);
        }
        
        console.log('\n========================================');
        console.log('💡 What should happen:');
        console.log('1. Admin panel sends: YYYY-MM-DDTHH:mm');
        console.log('2. Server adds seconds: YYYY-MM-DDTHH:mm:00');
        console.log('3. Server parses as local time');
        console.log('4. If >10 seconds in future → scheduled');
        console.log('5. Cron job sends it at the right time');
        
    } catch (error) {
        console.error('\n❌ Test failed:', error.message);
    }
}

// Run test
testAdminPanelFormat();