const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const sqlite3 = require('sqlite3').verbose();
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const multer = require('multer');
const { v4: uuidv4 } = require('uuid');
const fs = require('fs');
const path = require('path');
const http = require('http');
const socketIo = require('socket.io');

const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

const PORT = 3009;
const DB_PATH = path.join(__dirname, 'zerda_admin.db');
const JWT_SECRET = process.env.JWT_SECRET || 'zerda-admin-secret-key-2024';

// Middleware
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: [
        "'self'", 
        "'unsafe-inline'", 
        "'unsafe-eval'",
        "https://unpkg.com",
        "https://cdnjs.cloudflare.com"
      ],
      styleSrc: [
        "'self'", 
        "'unsafe-inline'",
        "https://cdnjs.cloudflare.com"
      ],
      fontSrc: [
        "'self'",
        "https://cdnjs.cloudflare.com"
      ],
      connectSrc: [
        "'self'",
        "http://localhost:3009",
        "ws://localhost:3009"
      ]
    }
  }
}));
app.use(cors());
app.use(express.json());
app.use(express.static('.'));

// Rate limiting - Increased for testing
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 1000 // limit each IP to 1000 requests per windowMs (increased for testing)
});
app.use('/api/', limiter);

// File upload configuration
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDir = path.join(__dirname, 'uploads');
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const customerId = req.params.customerId || 'default';
    const timestamp = Date.now();
    const ext = path.extname(file.originalname);
    cb(null, `${customerId}_${timestamp}${ext}`);
  }
});

const upload = multer({
  storage: storage,
  limits: {
    fileSize: 5 * 1024 * 1024 // 5MB limit
  },
  fileFilter: (req, file, cb) => {
    const allowedTypes = /jpeg|jpg|png|svg|ico/;
    const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
    const mimetype = allowedTypes.test(file.mimetype);
    
    if (mimetype && extname) {
      return cb(null, true);
    } else {
      cb(new Error('Sadece resim dosyaları kabul edilir!'));
    }
  }
});

// Database connection
const db = new sqlite3.Database(DB_PATH);

// JWT Middleware
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ success: false, error: 'Access token gerekli' });
  }

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({ success: false, error: 'Geçersiz token' });
    }
    req.user = user;
    next();
  });
};

// Socket.io connection
io.on('connection', (socket) => {
  console.log('👤 Yeni client bağlandı:', socket.id);
  
  socket.on('join_customer', (customerId) => {
    socket.join(`customer_${customerId}`);
    console.log(`👥 Client ${socket.id} müşteri odasına katıldı: ${customerId}`);
  });
  
  socket.on('disconnect', () => {
    console.log('👋 Client bağlantısı kesildi:', socket.id);
  });
});

// ============= AUTHENTICATION ROUTES =============

// POST - Login
app.post('/api/auth/login', async (req, res) => {
  try {
    const { username, password } = req.body;
    
    if (!username || !password) {
      return res.status(400).json({
        success: false,
        error: 'Kullanıcı adı ve şifre gerekli'
      });
    }

    db.get(
      'SELECT * FROM users WHERE username = ? OR email = ?',
      [username, username],
      async (err, user) => {
        if (err) {
          return res.status(500).json({ success: false, error: err.message });
        }
        
        if (!user) {
          return res.status(401).json({ success: false, error: 'Kullanıcı bulunamadı' });
        }

        const isValidPassword = await bcrypt.compare(password, user.password_hash);
        if (!isValidPassword) {
          return res.status(401).json({ success: false, error: 'Geçersiz şifre' });
        }

        const token = jwt.sign(
          { userId: user.id, username: user.username, role: user.role },
          JWT_SECRET,
          { expiresIn: '24h' }
        );

        res.json({
          success: true,
          message: 'Giriş başarılı',
          data: {
            token,
            user: {
              id: user.id,
              username: user.username,
              email: user.email,
              role: user.role
            }
          }
        });
      }
    );
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// ============= CUSTOMER MANAGEMENT ROUTES =============

// GET - Tüm müşterileri listele
app.get('/api/customers', authenticateToken, (req, res) => {
  db.all('SELECT * FROM customers ORDER BY created_at DESC', (err, customers) => {
    if (err) {
      return res.status(500).json({ success: false, error: err.message });
    }
    
    res.json({
      success: true,
      data: customers
    });
  });
});

// GET - Belirli bir müşteriyi getir
app.get('/api/customers/:id', authenticateToken, (req, res) => {
  const customerId = req.params.id;
  
  db.get('SELECT * FROM customers WHERE id = ?', [customerId], (err, customer) => {
    if (err) {
      return res.status(500).json({ success: false, error: err.message });
    }
    
    if (!customer) {
      return res.status(404).json({ success: false, error: 'Müşteri bulunamadı' });
    }
    
    res.json({
      success: true,
      data: customer
    });
  });
});

// ============= FEATURE MANAGEMENT ROUTES =============

// GET - Müşteri feature'larını getir
app.get('/api/customers/:id/features', (req, res) => {
  const customerId = req.params.id;
  
  db.all(
    'SELECT feature_name, is_enabled FROM customer_features WHERE customer_id = ?',
    [customerId],
    (err, features) => {
      if (err) {
        return res.status(500).json({ success: false, error: err.message });
      }
      
      // Feature'ları object formatına dönüştür
      const featureObj = {};
      features.forEach(feature => {
        featureObj[feature.feature_name] = Boolean(feature.is_enabled);
      });
      
      res.json({
        success: true,
        features: featureObj
      });
    }
  );
});

// POST - Müşteri feature'ını güncelle
app.post('/api/customers/:id/features/:featureName', authenticateToken, (req, res) => {
  const { id: customerId, featureName } = req.params;
  const { enabled } = req.body;
  
  if (typeof enabled !== 'boolean') {
    return res.status(400).json({
      success: false,
      error: 'enabled parametresi boolean olmalı'
    });
  }
  
  db.run(
    `UPDATE customer_features 
     SET is_enabled = ?, updated_at = CURRENT_TIMESTAMP 
     WHERE customer_id = ? AND feature_name = ?`,
    [enabled, customerId, featureName],
    function(err) {
      if (err) {
        return res.status(500).json({ success: false, error: err.message });
      }
      
      if (this.changes === 0) {
        return res.status(404).json({ 
          success: false, 
          error: 'Feature bulunamadı' 
        });
      }
      
      // WebSocket ile değişikliği bildir
      io.to(`customer_${customerId}`).emit('feature_updated', {
        featureName,
        enabled,
        timestamp: new Date().toISOString()
      });
      
      res.json({
        success: true,
        message: `${featureName} feature ${enabled ? 'aktif' : 'pasif'} edildi`
      });
    }
  );
});

// ============= THEME MANAGEMENT ROUTES =============

// GET - Müşteri tema konfigürasyonunu getir
app.get('/api/customers/:id/theme', (req, res) => {
  const customerId = req.params.id;
  
  db.get(
    'SELECT * FROM theme_configs WHERE customer_id = ?',
    [customerId],
    (err, theme) => {
      if (err) {
        return res.status(500).json({ success: false, error: err.message });
      }
      
      if (!theme) {
        // Varsayılan tema döndür
        const defaultTheme = {
          theme_type: 'dark',
          primary_color: '#18214F',
          secondary_color: '#D4B896',
          accent_color: '#FF6B6B',
          background_color: '#FFFFFF',
          text_color: '#000000',
          success_color: '#4CAF50',
          error_color: '#F44336',
          warning_color: '#FF9800',
          font_family: 'Inter',
          font_size_scale: 1.0
        };
        
        return res.json({
          success: true,
          data: defaultTheme
        });
      }
      
      res.json({
        success: true,
        data: theme
      });
    }
  );
});

// POST - Müşteri tema konfigürasyonunu güncelle
app.post('/api/customers/:id/theme', authenticateToken, (req, res) => {
  const customerId = req.params.id;
  const themeData = req.body;
  
  // Mevcut tema var mı kontrol et
  db.get(
    'SELECT id FROM theme_configs WHERE customer_id = ?',
    [customerId],
    (err, existing) => {
      if (err) {
        return res.status(500).json({ success: false, error: err.message });
      }
      
      if (existing) {
        // Güncelle
        db.run(
          `UPDATE theme_configs SET 
           theme_type = ?, primary_color = ?, secondary_color = ?, 
           accent_color = ?, background_color = ?, text_color = ?,
           success_color = ?, error_color = ?, warning_color = ?,
           font_family = ?, font_size_scale = ?, updated_at = CURRENT_TIMESTAMP
           WHERE customer_id = ?`,
          [
            themeData.theme_type, themeData.primary_color, themeData.secondary_color,
            themeData.accent_color, themeData.background_color, themeData.text_color,
            themeData.success_color, themeData.error_color, themeData.warning_color,
            themeData.font_family, themeData.font_size_scale, customerId
          ],
          (err) => {
            if (err) {
              return res.status(500).json({ success: false, error: err.message });
            }
            
            // WebSocket ile değişikliği bildir
            io.to(`customer_${customerId}`).emit('theme_updated', {
              theme: themeData,
              timestamp: new Date().toISOString()
            });
            
            res.json({
              success: true,
              message: 'Tema konfigürasyonu güncellendi'
            });
          }
        );
      } else {
        // Yeni oluştur
        const themeId = uuidv4();
        db.run(
          `INSERT INTO theme_configs 
           (id, customer_id, theme_type, primary_color, secondary_color, 
            accent_color, background_color, text_color, success_color, 
            error_color, warning_color, font_family, font_size_scale) 
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
          [
            themeId, customerId, themeData.theme_type, themeData.primary_color,
            themeData.secondary_color, themeData.accent_color, themeData.background_color,
            themeData.text_color, themeData.success_color, themeData.error_color,
            themeData.warning_color, themeData.font_family, themeData.font_size_scale
          ],
          (err) => {
            if (err) {
              return res.status(500).json({ success: false, error: err.message });
            }
            
            res.json({
              success: true,
              message: 'Tema konfigürasyonu oluşturuldu'
            });
          }
        );
      }
    }
  );
});

// ============= ASSET MANAGEMENT ROUTES =============

// POST - Asset upload
app.post('/api/customers/:customerId/assets/:assetType', authenticateToken, upload.single('file'), (req, res) => {
  const { customerId, assetType } = req.params;
  const file = req.file;
  
  if (!file) {
    return res.status(400).json({ success: false, error: 'Dosya yüklenmedi' });
  }
  
  const assetId = uuidv4();
  const relativePath = path.relative(__dirname, file.path);
  
  db.run(
    `INSERT INTO assets (id, customer_id, asset_type, asset_name, file_path, file_size, mime_type)
     VALUES (?, ?, ?, ?, ?, ?, ?)`,
    [assetId, customerId, assetType, file.filename, relativePath, file.size, file.mimetype],
    function(err) {
      if (err) {
        return res.status(500).json({ success: false, error: err.message });
      }
      
      // WebSocket ile değişikliği bildir
      io.to(`customer_${customerId}`).emit('asset_uploaded', {
        assetType,
        assetId,
        fileName: file.filename,
        timestamp: new Date().toISOString()
      });
      
      res.json({
        success: true,
        message: 'Asset başarıyla yüklendi',
        data: {
          id: assetId,
          type: assetType,
          fileName: file.filename,
          path: relativePath,
          size: file.size
        }
      });
    }
  );
});

// GET - Dashboard istatistikleri
app.get('/api/dashboard/stats', authenticateToken, (req, res) => {
  Promise.all([
    new Promise((resolve) => {
      db.get('SELECT COUNT(*) as count FROM customers', (err, result) => {
        resolve(err ? 0 : result.count);
      });
    }),
    new Promise((resolve) => {
      db.get('SELECT COUNT(*) as count FROM customer_features WHERE is_enabled = 1', (err, result) => {
        resolve(err ? 0 : result.count);
      });
    }),
    new Promise((resolve) => {
      db.get('SELECT COUNT(*) as count FROM assets', (err, result) => {
        resolve(err ? 0 : result.count);
      });
    })
  ]).then(([customers, activeFeatures, totalAssets]) => {
    res.json({
      success: true,
      data: {
        totalCustomers: customers,
        activeFeatures: activeFeatures,
        totalAssets: totalAssets,
        lastUpdate: new Date().toISOString()
      }
    });
  });
});

// ============= BACKWARDS COMPATIBILITY =============

// GET - Eski API uyumluluğu (mobil uygulama için)
app.get('/api/features', (req, res) => {
  // Default customer için feature'ları döndür
  db.all(
    'SELECT feature_name, is_enabled FROM customer_features WHERE customer_id = (SELECT id FROM customers LIMIT 1)',
    (err, features) => {
      if (err) {
        return res.status(500).json({ success: false, error: err.message });
      }
      
      const featureObj = {};
      features.forEach(feature => {
        featureObj[feature.feature_name] = Boolean(feature.is_enabled);
      });
      
      res.json({
        success: true,
        features: featureObj
      });
    }
  );
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
    service: 'Zerda Advanced Admin Panel',
    version: '2.0.0'
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
server.listen(PORT, () => {
  console.log(`🚀 Zerda Advanced Admin Panel çalışıyor: http://localhost:${PORT}`);
  console.log(`📱 API Endpoint: http://localhost:${PORT}/api`);
  console.log(`⚙️  Admin Panel: http://localhost:${PORT}`);
  console.log(`🔐 Login: admin/admin123`);
  console.log(`🔌 WebSocket: Aktif`);
  console.log(`📊 Multi-tenant: Aktif`);
  console.log(`🎨 Theme Management: Aktif`);
  
  console.log('✅ Gelişmiş admin panel hazır!');
});

module.exports = { app, server, io };