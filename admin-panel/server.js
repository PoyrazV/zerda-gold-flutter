const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = 3002;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static('.'));

// Config dosyası yolu
const CONFIG_FILE = path.join(__dirname, 'zerda-config.json');

// Varsayılan konfigürasyon
const defaultConfig = {
  timestamp: new Date().toISOString(),
  features: {
    dashboard: true,
    goldPrices: true,
    converter: true,
    alarms: true,
    portfolio: true,
    profile: true,
    watchlist: true,
    profitLossCalculator: true,
    performanceHistory: true,
    sarrafiyeIscilik: true,
    gecmisKurlar: true
  }
};

// Config dosyasını oku
function readConfig() {
  try {
    if (fs.existsSync(CONFIG_FILE)) {
      const data = fs.readFileSync(CONFIG_FILE, 'utf8');
      return JSON.parse(data);
    }
    return defaultConfig;
  } catch (error) {
    console.error('Config okuma hatası:', error);
    return defaultConfig;
  }
}

// Config dosyasını yaz
function writeConfig(config) {
  try {
    fs.writeFileSync(CONFIG_FILE, JSON.stringify(config, null, 2));
    return true;
  } catch (error) {
    console.error('Config yazma hatası:', error);
    return false;
  }
}

// API Routes

// GET - Mevcut konfigürasyonu al
app.get('/api/config', (req, res) => {
  const config = readConfig();
  res.json({
    success: true,
    data: config
  });
});

// POST - Konfigürasyonu güncelle
app.post('/api/config', (req, res) => {
  try {
    const { features } = req.body;
    
    if (!features || typeof features !== 'object') {
      return res.status(400).json({
        success: false,
        error: 'Geçersiz features objesi'
      });
    }

    const config = {
      timestamp: new Date().toISOString(),
      features: features
    };

    const saved = writeConfig(config);
    
    if (saved) {
      res.json({
        success: true,
        message: 'Konfigürasyon başarıyla kaydedildi',
        data: config
      });
    } else {
      res.status(500).json({
        success: false,
        error: 'Konfigürasyon kaydetme hatası'
      });
    }
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// GET - Sadece feature durumlarını al (mobil uygulama için)
app.get('/api/features', (req, res) => {
  const config = readConfig();
  res.json({
    success: true,
    features: config.features || {}
  });
});

// POST - Tek bir feature'ı güncelle
app.post('/api/features/:featureName', (req, res) => {
  try {
    const { featureName } = req.params;
    const { enabled } = req.body;
    
    if (typeof enabled !== 'boolean') {
      return res.status(400).json({
        success: false,
        error: 'enabled parametresi boolean olmalı'
      });
    }

    const config = readConfig();
    config.features[featureName] = enabled;
    config.timestamp = new Date().toISOString();

    const saved = writeConfig(config);
    
    if (saved) {
      res.json({
        success: true,
        message: `${featureName} feature ${enabled ? 'aktif' : 'pasif'} edildi`,
        data: config
      });
    } else {
      res.status(500).json({
        success: false,
        error: 'Konfigürasyon kaydetme hatası'
      });
    }
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// GET - Feature istatistikleri
app.get('/api/stats', (req, res) => {
  const config = readConfig();
  const features = config.features || {};
  
  const stats = {
    total: Object.keys(features).length,
    enabled: Object.values(features).filter(f => f).length,
    disabled: Object.values(features).filter(f => !f).length,
    lastUpdate: config.timestamp
  };

  res.json({
    success: true,
    stats: stats
  });
});

// POST - Tüm feature'ları reset et
app.post('/api/reset', (req, res) => {
  try {
    const saved = writeConfig(defaultConfig);
    
    if (saved) {
      res.json({
        success: true,
        message: 'Tüm ayarlar varsayılan duruma getirildi',
        data: defaultConfig
      });
    } else {
      res.status(500).json({
        success: false,
        error: 'Reset işlemi başarısız'
      });
    }
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Root route - Admin panel
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
});

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    service: 'Zerda Feature Config API'
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    error: 'Endpoint bulunamadı'
  });
});

// Error handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    success: false,
    error: 'Sunucu hatası'
  });
});

// Server'ı başlat
app.listen(PORT, () => {
  console.log(`🚀 Zerda Admin Panel Server çalışıyor: http://localhost:${PORT}`);
  console.log(`📱 API Endpoint: http://localhost:${PORT}/api`);
  console.log(`⚙️  Admin Panel: http://localhost:${PORT}`);
  
  // İlk başlatmada varsayılan config dosyası oluştur
  if (!fs.existsSync(CONFIG_FILE)) {
    writeConfig(defaultConfig);
    console.log('✅ Varsayılan konfigürasyon dosyası oluşturuldu');
  }
});

module.exports = app;