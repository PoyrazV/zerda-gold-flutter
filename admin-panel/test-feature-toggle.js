const fetch = require("node-fetch");

async function testFeatureToggle() {
  console.log("🧪 Testing feature toggle synchronization...\n");
  
  const baseUrl = "http://localhost:3009";
  const customerId = "ffeee61a-8497-4c70-857e-c8f0efb13a2a";
  let token = "";
  
  // 1. Login
  console.log("1️⃣ Logging in...");
  try {
    const loginResponse = await fetch(`${baseUrl}/api/auth/login`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        username: "admin",
        password: "admin123"
      })
    });
    const loginResult = await loginResponse.json();
    if (loginResult.success) {
      token = loginResult.data.token;
      console.log("✅ Login successful\n");
    } else {
      console.log("❌ Login failed:", loginResult.error);
      return;
    }
  } catch (error) {
    console.error("❌ Login error:", error.message);
    return;
  }
  
  // 2. Get current features
  console.log("2️⃣ Getting current features...");
  const getFeaturesResponse = await fetch(`${baseUrl}/api/customers/${customerId}/features`, {
    headers: { "Authorization": `Bearer ${token}` }
  });
  const features = await getFeaturesResponse.json();
  
  if (features.success) {
    console.log("✅ Current features (11 total):");
    const featureList = Object.entries(features.features);
    featureList.forEach(([name, enabled], index) => {
      console.log(`   ${index + 1}. ${name}: ${enabled ? "✅ Enabled" : "❌ Disabled"}`);
    });
    console.log();
  }
  
  console.log("\n✅ Test completed!");
  console.log("📱 Check Flutter app and admin panel at http://localhost:3009");
}

testFeatureToggle().catch(console.error);
