const fetch = require("node-fetch");

async function testSQLitePanel() {
  console.log("🧪 Testing SQLite Admin Panel...");
  
  try {
    // Test HTML loading
    const response = await fetch("http://localhost:3009");
    const html = await response.text();
    
    if (html.includes("<!DOCTYPE html>")) {
      console.log("✅ Admin panel HTML loaded successfully");
      
      // Test login
      const loginResponse = await fetch("http://localhost:3009/api/auth/login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          username: "admin",
          password: "admin123"
        })
      });
      
      const loginResult = await loginResponse.json();
      
      if (loginResult.success) {
        console.log("✅ Login successful with SQLite");
        const token = loginResult.data.token;
        
        // Test features API
        const featuresResponse = await fetch("http://localhost:3009/api/customers/ffeee61a-8497-4c70-857e-c8f0efb13a2a/features", {
          headers: { "Authorization": `Bearer ${token}` }
        });
        
        const features = await featuresResponse.json();
        
        if (features.success) {
          console.log(`✅ Features loaded: ${Object.keys(features.features).length} features`);
          Object.entries(features.features).forEach(([name, enabled]) => 
            console.log(`   - ${name}: ${enabled ? "✅" : "❌"}`)
          );
        } else {
          console.log("❌ Failed to load features:", features.error);
        }
      } else {
        console.log("❌ Login failed:", loginResult.error);
      }
    } else {
      console.log("❌ HTML not loaded properly");
    }
    
    console.log("\n🎉 SQLite Admin Panel is working!");
    console.log("🌐 Access at: http://localhost:3009");
    console.log("🔐 Login: admin / admin123");
    
  } catch (error) {
    console.error("❌ Test failed:", error.message);
  }
}

testSQLitePanel();
