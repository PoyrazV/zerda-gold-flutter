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
const crypto = require('crypto');
const admin = require('firebase-admin');

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

// Initialize Firebase Admin SDK
let firebaseInitialized = false;
try {
  // For development, we'll use a placeholder service account
  // In production, you would use: admin.initializeApp({ credential: admin.credential.applicationDefault() });
  // Or provide a real service account key file
  console.log('📝 Firebase Admin SDK: Using placeholder configuration');
  console.log('⚠️ To enable FCM, add your Firebase service account key to firebase-service-account.json');
  
  // Check if service account file exists
  const serviceAccountPath = path.join(__dirname, 'firebase-service-account.json');
  if (fs.existsSync(serviceAccountPath)) {
    const serviceAccount = require(serviceAccountPath);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId: serviceAccount.project_id
    });
    firebaseInitialized = true;
    console.log('🔥 Firebase Admin SDK initialized with service account');
  } else {
    console.log('⚠️ Firebase service account not found. FCM notifications will not work.');
    console.log('📝 Create firebase-service-account.json in admin-panel folder to enable FCM');
  }
} catch (error) {
  console.log('❌ Failed to initialize Firebase Admin:', error.message);
}

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

// ============= MOBILE APP AUTHENTICATION =============

// POST - Mobile app login
app.post('/api/mobile/auth/login', async (req, res) => {
  try {
    const { email, password, fcm_token, device_id, platform } = req.body;
    
    if (!email || !password) {
      return res.status(400).json({
        success: false,
        error: 'Email ve şifre gerekli'
      });
    }
    
    db.get(
      'SELECT * FROM mobile_users WHERE email = ?',
      [email],
      async (err, user) => {
        if (err) {
          return res.status(500).json({ success: false, error: err.message });
        }
        
        if (!user) {
          return res.status(401).json({ success: false, error: 'Kullanıcı bulunamadı' });
        }
        
        if (!user.is_active) {
          return res.status(403).json({ success: false, error: 'Hesap devre dışı' });
        }
        
        const isValidPassword = await bcrypt.compare(password, user.password_hash);
        if (!isValidPassword) {
          return res.status(401).json({ success: false, error: 'Geçersiz şifre' });
        }
        
        // Generate session token
        const sessionToken = jwt.sign(
          { userId: user.id, email: user.email, type: 'mobile' },
          JWT_SECRET,
          { expiresIn: '30d' }
        );
        
        const sessionId = uuidv4();
        const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000); // 30 days
        
        // Save session
        db.run(
          `INSERT INTO mobile_sessions (id, user_id, token, device_id, fcm_token, platform, expires_at) 
           VALUES (?, ?, ?, ?, ?, ?, ?)`,
          [sessionId, user.id, sessionToken, device_id, fcm_token, platform, expiresAt],
          (err) => {
            if (err) {
              console.error('Session save error:', err);
            }
          }
        );
        
        // Update last login
        db.run(
          'UPDATE mobile_users SET last_login = CURRENT_TIMESTAMP WHERE id = ?',
          [user.id]
        );
        
        // Update FCM token with user info if provided
        if (fcm_token) {
          db.run(
            `UPDATE fcm_tokens 
             SET user_id = ?, user_email = ?, is_authenticated = 1, last_login = CURRENT_TIMESTAMP, updated_at = datetime('now')
             WHERE fcm_token = ? AND customer_id = ?`,
            [user.id, user.email, fcm_token, 'ffeee61a-8497-4c70-857e-c8f0efb13a2a'],
            (updateErr) => {
              if (updateErr) {
                console.error('FCM token update error:', updateErr);
              } else {
                db.get(
                  'SELECT changes() as changes',
                  (err, result) => {
                    if (result && result.changes > 0) {
                      console.log(`✅ FCM token updated for user: ${user.email}`);
                    } else {
                      console.log(`⚠️ FCM token not found for update: ${fcm_token}`);
                    }
                  }
                );
              }
            }
          );
        }
        
        res.json({
          success: true,
          message: 'Giriş başarılı',
          data: {
            token: sessionToken,
            user: {
              id: user.id,
              email: user.email,
              full_name: user.full_name,
              profile_image: user.profile_image,
              is_verified: user.is_verified
            }
          }
        });
      }
    );
  } catch (error) {
    console.error('Mobile login error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// POST - Mobile app register
app.post('/api/mobile/auth/register', async (req, res) => {
  try {
    const { email, password, full_name, fcm_token, device_id, platform } = req.body;
    
    if (!email || !password) {
      return res.status(400).json({
        success: false,
        error: 'Email ve şifre gerekli'
      });
    }
    
    // Check if user exists
    db.get('SELECT id FROM mobile_users WHERE email = ?', [email], async (err, existing) => {
      if (err) {
        return res.status(500).json({ success: false, error: err.message });
      }
      
      if (existing) {
        return res.status(409).json({ success: false, error: 'Bu email zaten kayıtlı' });
      }
      
      const userId = uuidv4();
      const hashedPassword = await bcrypt.hash(password, 10);
      const verificationToken = uuidv4();
      
      db.run(
        `INSERT INTO mobile_users (id, email, password_hash, full_name, verification_token, is_verified) 
         VALUES (?, ?, ?, ?, ?, 1)`, // Auto-verify for now
        [userId, email, hashedPassword, full_name || email.split('@')[0], verificationToken],
        function(err) {
          if (err) {
            return res.status(500).json({ success: false, error: err.message });
          }
          
          // Auto login after register
          const sessionToken = jwt.sign(
            { userId, email, type: 'mobile' },
            JWT_SECRET,
            { expiresIn: '30d' }
          );
          
          const sessionId = uuidv4();
          const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
          
          db.run(
            `INSERT INTO mobile_sessions (id, user_id, token, device_id, fcm_token, platform, expires_at) 
             VALUES (?, ?, ?, ?, ?, ?, ?)`,
            [sessionId, userId, sessionToken, device_id, fcm_token, platform, expiresAt]
          );
          
          // Link FCM token if provided
          if (fcm_token && device_id) {
            const customerId = 'ffeee61a-8497-4c70-857e-c8f0efb13a2a';
            
            db.run(
              `UPDATE fcm_tokens 
               SET user_id = ?, user_email = ?, is_authenticated = 1, last_login = CURRENT_TIMESTAMP 
               WHERE fcm_token = ? AND customer_id = ?`,
              [userId, email, fcm_token, customerId]
            );
          }
          
          res.status(201).json({
            success: true,
            message: 'Kayıt başarılı',
            data: {
              token: sessionToken,
              user: {
                id: userId,
                email,
                full_name: full_name || email.split('@')[0],
                is_verified: true
              }
            }
          });
        }
      );
    });
  } catch (error) {
    console.error('Mobile register error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// POST - Mobile app logout
app.post('/api/mobile/auth/logout', async (req, res) => {
  try {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];
    const { fcm_token } = req.body;
    
    if (token) {
      // Delete session
      db.run('DELETE FROM mobile_sessions WHERE token = ?', [token]);
    }
    
    if (fcm_token) {
      // Remove user info from FCM token
      db.run(
        `UPDATE fcm_tokens 
         SET user_id = NULL, user_email = NULL, is_authenticated = 0, updated_at = datetime('now')
         WHERE fcm_token = ?`,
        [fcm_token],
        (err) => {
          if (err) {
            console.error('FCM token logout update error:', err);
          } else {
            console.log(`✅ FCM token cleared on logout for token: ${fcm_token.substring(0, 20)}...`);
          }
        }
      );
    }
    
    res.json({ success: true, message: 'Çıkış başarılı' });
  } catch (error) {
    console.error('Mobile logout error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// GET - Verify mobile token
app.get('/api/mobile/auth/verify', (req, res) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  
  if (!token) {
    return res.status(401).json({ success: false, error: 'Token gerekli' });
  }
  
  jwt.verify(token, JWT_SECRET, (err, decoded) => {
    if (err) {
      return res.status(401).json({ success: false, error: 'Geçersiz token' });
    }
    
    if (decoded.type !== 'mobile') {
      return res.status(403).json({ success: false, error: 'Yetkilendirme hatası' });
    }
    
    db.get(
      'SELECT id, email, full_name, profile_image, is_verified FROM mobile_users WHERE id = ?',
      [decoded.userId],
      (err, user) => {
        if (err || !user) {
          return res.status(404).json({ success: false, error: 'Kullanıcı bulunamadı' });
        }
        
        res.json({
          success: true,
          data: { user }
        });
      }
    );
  });
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

// ============= FCM HELPER FUNCTIONS =============

async function sendFCMNotification(customerId, notificationData) {
  if (!firebaseInitialized) {
    console.log('⚠️ Firebase not initialized, skipping FCM notification');
    return { success: false, reason: 'firebase_not_initialized' };
  }

  return new Promise((resolve) => {
    // Build query based on target
    let query = 'SELECT fcm_token FROM fcm_tokens WHERE customer_id = ?';
    const params = [customerId];
    
    // Filter by target type
    if (notificationData.target === 'authenticated') {
      query += ' AND is_authenticated = 1 AND user_id IS NOT NULL';
      console.log('📨 Sending to authenticated users only');
    } else if (notificationData.target === 'guests') {
      query += ' AND (is_authenticated = 0 OR user_id IS NULL)';
      console.log('📨 Sending to guest users only');
    } else {
      console.log('📨 Sending to all users');
    }
    
    // Get FCM tokens based on target
    db.all(
      query,
      params,
      async (err, tokens) => {
        if (err) {
          console.error('Error fetching FCM tokens:', err);
          return resolve({ success: false, error: err.message });
        }

        if (!tokens || tokens.length === 0) {
          console.log(`No FCM tokens found for customer ${customerId}`);
          return resolve({ success: false, reason: 'no_tokens' });
        }

        const fcmTokens = tokens.map(t => t.fcm_token);
        console.log(`🔥 Sending FCM to ${fcmTokens.length} tokens for customer ${customerId}`);
        console.log(`📋 Notification content:
          Title: ${notificationData.title}
          Message: ${notificationData.message}
          Type: ${notificationData.type}
          Target: ${notificationData.target}`);

        try {
          // Prepare message with BOTH notification and data fields
          // This ensures the notification works when app is killed
          const baseMessage = {
            // Include notification field for system to display when app is killed
            notification: {
              title: notificationData.title || 'Zerda Gold',
              body: notificationData.message || '',
            },
            // Also include data for custom handling when app is in foreground
            data: {
              title: notificationData.title || 'Zerda Gold',
              body: notificationData.message || '',
              type: notificationData.type || 'info',
              id: notificationData.id || '',
              timestamp: new Date().toISOString(),
              click_action: 'FLUTTER_NOTIFICATION_CLICK',
            },
            android: {
              priority: 'high',
              notification: {
                channelId: 'zerda_notifications',
                priority: 'high',
                defaultSound: true,
                clickAction: 'FLUTTER_NOTIFICATION_CLICK',
              },
              // Enable wake lock for background processing
              ttl: 86400000, // 24 hours
            },
            apns: {
              payload: {
                aps: {
                  alert: {
                    title: notificationData.title || 'Zerda Gold',
                    body: notificationData.message || '',
                  },
                  badge: 1,
                  sound: 'default',
                  contentAvailable: true,
                  mutableContent: true,
                },
              },
              headers: {
                'apns-priority': '10',
              },
            },
          };

          // Send to each token individually for better compatibility
          const sendPromises = fcmTokens.map(token => {
            const message = { ...baseMessage, token };
            console.log(`📤 Sending FCM message to token: ${token.substring(0, 20)}...`);
            return admin.messaging().send(message)
              .then(response => {
                console.log(`✅ FCM sent successfully to ${token.substring(0, 20)}... Response: ${response}`);
                return { success: true, response, token };
              })
              .catch(error => {
                console.error(`❌ FCM failed for ${token.substring(0, 20)}... Error: ${error.message}`);
                return { success: false, error, token };
              });
          });

          const results = await Promise.all(sendPromises);
          const successCount = results.filter(r => r.success).length;
          const failureCount = results.filter(r => !r.success).length;
          
          const response = {
            successCount,
            failureCount,
            responses: results
          };
          
          console.log(`🔥 FCM sent successfully: ${response.successCount} success, ${response.failureCount} failures`);
          
          // Clean up invalid tokens
          if (response.failureCount > 0) {
            const invalidTokens = [];
            results.forEach((result) => {
              if (!result.success) {
                const errorCode = result.error?.code || result.error?.errorInfo?.code;
                if (errorCode === 'messaging/invalid-registration-token' || 
                    errorCode === 'messaging/registration-token-not-registered' ||
                    errorCode === 'messaging/invalid-argument') {
                  invalidTokens.push(result.token);
                }
              }
            });
            
            // Remove invalid tokens from database
            if (invalidTokens.length > 0) {
              const placeholders = invalidTokens.map(() => '?').join(',');
              db.run(`DELETE FROM fcm_tokens WHERE fcm_token IN (${placeholders})`, invalidTokens, (err) => {
                if (err) {
                  console.error('Error cleaning up invalid FCM tokens:', err);
                } else {
                  console.log(`🧹 Cleaned up ${invalidTokens.length} invalid FCM tokens`);
                }
              });
            }
          }
          
          resolve({
            success: true,
            successCount: response.successCount,
            failureCount: response.failureCount,
            responses: response.responses
          });
          
        } catch (fcmError) {
          console.error('FCM sending error:', fcmError);
          resolve({ success: false, error: fcmError.message });
        }
      }
    );
  });
}

// ============= NOTIFICATION MANAGEMENT ROUTES =============

// GET - Müşteri bildirimlerini listele
app.get('/api/customers/:customerId/notifications', authenticateToken, (req, res) => {
  const { customerId } = req.params;
  const { limit = 50, offset = 0 } = req.query;

  db.all(
    `SELECT * FROM notifications 
     WHERE customer_id = ? 
     ORDER BY created_at DESC 
     LIMIT ? OFFSET ?`,
    [customerId, parseInt(limit), parseInt(offset)],
    (err, notifications) => {
      if (err) {
        return res.status(500).json({ success: false, error: err.message });
      }

      res.json({
        success: true,
        data: notifications,
        total: notifications.length
      });
    }
  );
});

// POST - Yeni bildirim gönder
app.post('/api/customers/:customerId/notifications', authenticateToken, async (req, res) => {
  const { customerId } = req.params;
  const { title, message, type = 'info', target = 'all', scheduled_time = null } = req.body;

  if (!title || !message) {
    return res.status(400).json({
      success: false,
      error: 'Başlık ve mesaj gerekli'
    });
  }

  const notificationId = uuidv4();
  const now = new Date().toISOString();

  try {
    // Insert notification
    await new Promise((resolve, reject) => {
      db.run(
        `INSERT INTO notifications (id, customer_id, title, message, type, target, status, scheduled_time, created_at, updated_at)
         VALUES (?, ?, ?, ?, ?, ?, 'pending', ?, ?, ?)`,
        [notificationId, customerId, title, message, type, target, scheduled_time, now, now],
        function(err) {
          if (err) reject(err);
          else resolve();
        }
      );
    });

    // Anlık gönderim için (scheduled_time null ise)
    if (!scheduled_time) {
      try {
        // Status'u sent olarak güncelle
        await new Promise((resolve, reject) => {
          db.run(
            'UPDATE notifications SET status = "sent", sent_at = ? WHERE id = ?',
            [now, notificationId],
            function(err) {
              if (err) reject(err);
              else resolve();
            }
          );
        });

        // WebSocket ile anlık bildirim gönder
        io.to(`customer_${customerId}`).emit('notification_sent', {
          id: notificationId,
          title,
          message,
          type,
          target,
          timestamp: now
        });

        // FCM push notification gönder
        const fcmResult = await sendFCMNotification(customerId, {
          id: notificationId,
          title,
          message,
          type,
          target
        });

        console.log(`📱 Push Notification Gönderildi:
          Customer: ${customerId}
          Title: ${title}
          Message: ${message}
          Type: ${type}
          Target: ${target}
          FCM: ${fcmResult.success ? `✅ ${fcmResult.successCount} sent` : `❌ ${fcmResult.reason || fcmResult.error}`}`);
      } catch (updateError) {
        console.error(`❌ Notification status update failed for ${notificationId}:`, updateError);
      }
    }

    res.status(201).json({
      success: true,
      message: 'Bildirim başarıyla oluşturuldu',
      data: {
        id: notificationId,
        title,
        message,
        type,
        target,
        status: scheduled_time ? 'scheduled' : 'sent',
        created_at: now
      }
    });

  } catch (error) {
    console.error('Single notification error:', error);
    res.status(500).json({
      success: false,
      error: 'Bildirim gönderilirken hata oluştu: ' + error.message
    });
  }
});

// PUT - Bildirim güncelle
app.put('/api/customers/:customerId/notifications/:notificationId', authenticateToken, (req, res) => {
  const { customerId, notificationId } = req.params;
  const { title, message, type, target, scheduled_time, status } = req.body;
  const now = new Date().toISOString();

  db.run(
    `UPDATE notifications 
     SET title = COALESCE(?, title),
         message = COALESCE(?, message),
         type = COALESCE(?, type),
         target = COALESCE(?, target),
         scheduled_time = COALESCE(?, scheduled_time),
         status = COALESCE(?, status),
         updated_at = ?
     WHERE id = ? AND customer_id = ?`,
    [title, message, type, target, scheduled_time, status, now, notificationId, customerId],
    function(err) {
      if (err) {
        return res.status(500).json({ success: false, error: err.message });
      }

      if (this.changes === 0) {
        return res.status(404).json({
          success: false,
          error: 'Bildirim bulunamadı'
        });
      }

      res.json({
        success: true,
        message: 'Bildirim başarıyla güncellendi'
      });
    }
  );
});

// DELETE - Bildirim sil
app.delete('/api/customers/:customerId/notifications/:notificationId', authenticateToken, (req, res) => {
  const { customerId, notificationId } = req.params;

  db.run(
    'DELETE FROM notifications WHERE id = ? AND customer_id = ?',
    [notificationId, customerId],
    function(err) {
      if (err) {
        return res.status(500).json({ success: false, error: err.message });
      }

      if (this.changes === 0) {
        return res.status(404).json({
          success: false,
          error: 'Bildirim bulunamadı'
        });
      }

      res.json({
        success: true,
        message: 'Bildirim başarıyla silindi'
      });
    }
  );
});

// POST - Toplu bildirim gönder
app.post('/api/notifications/broadcast', authenticateToken, async (req, res) => {
  const { title, message, type = 'info', target = 'all', customerIds = [], excludeCustomerIds = [] } = req.body;

  if (!title || !message) {
    return res.status(400).json({
      success: false,
      error: 'Başlık ve mesaj gerekli'
    });
  }

  // Hedef gruba göre müşterileri belirle
  let customersToNotify = [];
  
  if (customerIds.length > 0) {
    // Belirli müşteriler belirtilmişse onları kullan
    const placeholders = customerIds.map(() => '?').join(',');
    const query = `SELECT id FROM customers WHERE id IN (${placeholders})`;
    customersToNotify = await new Promise((resolve, reject) => {
      db.all(query, customerIds, (err, results) => {
        if (err) reject(err);
        else resolve(results);
      });
    });
  } else {
    // Target'a göre filtreleme yap
    if (target === 'authenticated') {
      // Sadece giriş yapmış kullanıcıları al (FCM token tablosundan)
      const query = `
        SELECT DISTINCT customer_id as id 
        FROM fcm_tokens
        WHERE is_authenticated = 1 AND user_id IS NOT NULL
      `;
      customersToNotify = await new Promise((resolve, reject) => {
        db.all(query, [], (err, results) => {
          if (err) reject(err);
          else resolve(results || []);
        });
      });
    } else if (target === 'guests') {
      // Sadece misafir kullanıcıları al (FCM token tablosundan)
      const query = `
        SELECT DISTINCT customer_id as id 
        FROM fcm_tokens
        WHERE is_authenticated = 0 OR user_id IS NULL
      `;
      customersToNotify = await new Promise((resolve, reject) => {
        db.all(query, [], (err, results) => {
          if (err) reject(err);
          else resolve(results || []);
        });
      });
    } else {
      // Tüm müşterileri al - customers tablosundan
      const query = 'SELECT id FROM customers';
      customersToNotify = await new Promise((resolve, reject) => {
        db.all(query, [], (err, results) => {
          if (err) reject(err);
          else resolve(results || []);
        });
      });
    }
    
    // excludeCustomerIds varsa onları filtrele
    if (excludeCustomerIds.length > 0) {
      customersToNotify = customersToNotify.filter(c => !excludeCustomerIds.includes(c.id));
    }
  }
  
  console.log(`📢 Broadcast notification - Target: ${target}, Customers found: ${customersToNotify.length}`);

  try {
    const customers = customersToNotify;

    const now = new Date().toISOString();
    const sentNotifications = [];
    const failedNotifications = [];

    // Her müşteri için notification ekleme işlemini sıralı olarak bekleyelim
    for (const customer of customers) {
      const notificationId = uuidv4();
      
      try {
        await new Promise((resolve, reject) => {
          db.run(
            `INSERT INTO notifications (id, customer_id, title, message, type, target, status, created_at, updated_at, sent_at)
             VALUES (?, ?, ?, ?, ?, ?, 'sent', ?, ?, ?)`,
            [notificationId, customer.id, title, message, type, target, now, now, now],
            function(err) {
              if (err) reject(err);
              else resolve();
            }
          );
        });

        // WebSocket ile anlık bildirim gönder
        io.to(`customer_${customer.id}`).emit('notification_sent', {
          id: notificationId,
          title,
          message,
          type,
          target,
          timestamp: now
        });

        // FCM push notification gönder
        const fcmResult = await sendFCMNotification(customer.id, {
          id: notificationId,
          title,
          message,
          type,
          target
        });

        sentNotifications.push({
          customerId: customer.id,
          notificationId,
          status: 'sent',
          fcm: fcmResult.success ? `✅ ${fcmResult.successCount}` : `❌ ${fcmResult.reason || fcmResult.error}`
        });

        console.log(`📱 Broadcast Notification Gönderildi - Customer: ${customer.id}, FCM: ${fcmResult.success ? `✅ ${fcmResult.successCount} sent` : `❌ ${fcmResult.reason || fcmResult.error}`}`);
      } catch (dbError) {
        failedNotifications.push({
          customerId: customer.id,
          error: dbError.message
        });
        console.error(`❌ Broadcast Notification Başarısız - Customer: ${customer.id} - Error: ${dbError.message}`);
      }
    }

    res.json({
      success: true,
      message: `${sentNotifications.length} müşteriye bildirim gönderildi${failedNotifications.length > 0 ? `, ${failedNotifications.length} başarısız` : ''}`,
      sentCount: sentNotifications.length,
      data: {
        totalSent: sentNotifications.length,
        totalFailed: failedNotifications.length,
        notifications: sentNotifications,
        failures: failedNotifications
      }
    });

  } catch (error) {
    console.error('Broadcast notification error:', error);
    res.status(500).json({
      success: false,
      error: 'Bildirim gönderilirken hata oluştu: ' + error.message
    });
  }
});

// GET - Bildirim istatistikleri
app.get('/api/customers/:customerId/notifications/stats', authenticateToken, (req, res) => {
  const { customerId } = req.params;

  db.all(
    `SELECT 
       status,
       type,
       COUNT(*) as count,
       DATE(created_at) as date
     FROM notifications 
     WHERE customer_id = ?
     GROUP BY status, type, DATE(created_at)
     ORDER BY date DESC`,
    [customerId],
    (err, stats) => {
      if (err) {
        return res.status(500).json({ success: false, error: err.message });
      }

      // Toplam istatistikler
      db.get(
        `SELECT 
           COUNT(*) as total,
           SUM(CASE WHEN status = 'sent' THEN 1 ELSE 0 END) as sent,
           SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END) as pending,
           SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) as failed
         FROM notifications 
         WHERE customer_id = ?`,
        [customerId],
        (err, totals) => {
          if (err) {
            return res.status(500).json({ success: false, error: err.message });
          }

          res.json({
            success: true,
            data: {
              totals: totals || { total: 0, sent: 0, pending: 0, failed: 0 },
              detailed: stats
            }
          });
        }
      );
    }
  );
});


// Public endpoint for mobile app notification polling (no auth required)
app.get('/api/mobile/notifications/:customerId', (req, res) => {
  const { customerId } = req.params;
  const { since } = req.query; // Last notification ID (UUID string)

  let query = `SELECT * FROM notifications 
               WHERE customer_id = ? AND status = 'sent'`;
  let params = [customerId];

  if (since) {
    // For UUID-based filtering, we compare based on created_at timestamp
    // First get the timestamp of the 'since' notification
    const sinceQuery = `SELECT created_at FROM notifications WHERE id = ? AND customer_id = ?`;
    
    db.get(sinceQuery, [since, customerId], (sinceErr, sinceRow) => {
      if (sinceErr) {
        console.error('Since timestamp lookup error:', sinceErr);
        return res.status(500).json({ success: false, error: sinceErr.message });
      }

      if (sinceRow) {
        // Get notifications newer than the 'since' notification
        query += ` AND created_at > ?`;
        params.push(sinceRow.created_at);
      }

      query += ` ORDER BY created_at DESC LIMIT 20`;

      db.all(query, params, (err, notifications) => {
        if (err) {
          console.error('Mobile notifications error:', err);
          return res.status(500).json({ success: false, error: err.message });
        }

        console.log(`📱 Mobile notifications query for ${customerId}: Found ${notifications ? notifications.length : 0} notifications${since ? ` since ${since}` : ''}`);

        res.json({
          success: true,
          notifications: notifications || [],
          count: notifications ? notifications.length : 0,
          timestamp: new Date().toISOString()
        });
      });
    });
  } else {
    // No since parameter - get all recent notifications
    query += ` ORDER BY created_at DESC LIMIT 20`;

    db.all(query, params, (err, notifications) => {
      if (err) {
        console.error('Mobile notifications error:', err);
        return res.status(500).json({ success: false, error: err.message });
      }

      console.log(`📱 Mobile notifications query for ${customerId}: Found ${notifications ? notifications.length : 0} notifications (all recent)`);

      res.json({
        success: true,
        notifications: notifications || [],
        count: notifications ? notifications.length : 0,
        timestamp: new Date().toISOString()
      });
    });
  }
});

// FCM Token Registration - Mobile API endpoint (supports user info)
app.post('/api/mobile/register-fcm-token', async (req, res) => {
  const { customerId, fcmToken, platform, deviceId, userId, userEmail } = req.body;

  if (!customerId || !fcmToken || !deviceId) {
    return res.status(400).json({ 
      success: false, 
      error: 'Missing required fields: customerId, fcmToken, or deviceId' 
    });
  }

  const tokenId = uuidv4();
  
  try {
    // First, delete any existing tokens for this device ID (ensure only one token per device)
    await new Promise((resolve, reject) => {
      db.run(
        `DELETE FROM fcm_tokens 
         WHERE customer_id = ? AND device_id = ? AND fcm_token != ?`,
        [customerId, deviceId, fcmToken],
        function(err) {
          if (err) return reject(err);
          console.log(`Cleaned up ${this.changes} old tokens for device ${deviceId}`);
          resolve();
        }
      );
    });

    // Now update or insert the token
    await new Promise((resolve, reject) => {
      db.run(
        `INSERT OR REPLACE INTO fcm_tokens 
         (id, customer_id, fcm_token, platform, device_id, user_id, user_email, is_authenticated, created_at, updated_at) 
         VALUES (
           COALESCE((SELECT id FROM fcm_tokens WHERE customer_id = ? AND device_id = ?), ?),
           ?, ?, ?, ?, ?, ?, ?,
           COALESCE((SELECT created_at FROM fcm_tokens WHERE customer_id = ? AND device_id = ?), CURRENT_TIMESTAMP),
           CURRENT_TIMESTAMP
         )`,
        [
          // For ID selection
          customerId, deviceId, tokenId,
          // For insert values
          customerId, 
          fcmToken, 
          platform || 'flutter', 
          deviceId,
          userId || null,
          userEmail || null,
          userId ? 1 : 0,
          // For created_at selection
          customerId, deviceId
        ],
        function(err) {
          if (err) return reject(err);
          resolve();
        }
      );
    });

    console.log(`🔥 FCM token registered for customer ${customerId}: ${fcmToken.substring(0, 20)}...`);
    
    res.json({
      success: true,
      message: 'FCM token registered successfully',
      tokenId,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('FCM token registration error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// ==================== GOLD PRODUCTS MANAGEMENT ====================

// API Ninjas configuration
const API_NINJAS_KEY = 'qsHGB+VLocvWUHhJp1Hz2w==NMto19ZMjVwc7axC';
const API_NINJAS_URL = 'https://api.api-ninjas.com/v1/commodityprice?name=gold';

// Gold price cache - 1 minute cache to reduce API calls
let goldPriceCache = null;
let lastGoldPriceFetch = null;
const GOLD_CACHE_DURATION = 60 * 1000; // 1 dakika

// Get current gold price from API Ninjas with caching
app.get('/api/gold-price/current', async (req, res) => {
  try {
    // Check cache first
    const now = Date.now();
    if (goldPriceCache && lastGoldPriceFetch && (now - lastGoldPriceFetch) < GOLD_CACHE_DURATION) {
      console.log('🔄 Returning cached gold price (saved ' + Math.round((now - lastGoldPriceFetch) / 1000) + ' seconds ago)');
      return res.json(goldPriceCache);
    }
    
    console.log('📡 Fetching fresh gold price from API Ninjas...');
    const fetch = (await import('node-fetch')).default;
    const response = await fetch(API_NINJAS_URL, {
      headers: {
        'X-Api-Key': API_NINJAS_KEY
      }
    });
    
    if (!response.ok) {
      throw new Error(`API responded with status ${response.status}`);
    }
    
    const data = await response.json();
    
    // Calculate gram price from ounce price
    const ouncePrice = data.price || 0;
    const gramPrice = ouncePrice / 31.1035; // 1 troy ounce = 31.1035 grams
    
    // Prepare response and cache it
    const responseData = {
      success: true,
      data: {
        ounce_price_usd: ouncePrice,
        gram_price_usd: gramPrice,
        currency: 'USD',
        updated: data.updated || new Date().toISOString(),
        source: 'API Ninjas',
        cached_at: new Date().toISOString()
      }
    };
    
    // Update cache
    goldPriceCache = responseData;
    lastGoldPriceFetch = now;
    console.log('✅ Gold price fetched and cached successfully');
    
    res.json(responseData);
  } catch (error) {
    console.error('Gold price fetch error:', error);
    
    // If we have cached data, return it even if expired
    if (goldPriceCache) {
      console.log('⚠️ API failed, returning expired cache');
      goldPriceCache.data.source = 'Expired Cache';
      return res.json(goldPriceCache);
    }
    
    res.json({
      success: false,
      error: 'Altın fiyatı alınamadı',
      fallback: {
        ounce_price_usd: 3381.6,
        gram_price_usd: 108.73,
        currency: 'USD',
        source: 'Fallback'
      }
    });
  }
});

// Get all gold products for a customer
app.get('/api/customers/:customerId/gold-products', (req, res) => {
  const { customerId } = req.params;
  
  db.all(
    `SELECT * FROM gold_products 
     WHERE customer_id = ? 
     ORDER BY display_order, name`,
    [customerId],
    (err, products) => {
      if (err) {
        console.error('Database error:', err);
        return res.status(500).json({
          success: false,
          error: 'Veritabanı hatası'
        });
      }
      
      res.json({
        success: true,
        products: products || []
      });
    }
  );
});

// Create a new gold product
app.post('/api/customers/:customerId/gold-products', (req, res) => {
  const { customerId } = req.params;
  const { name, weight_grams, buy_millesimal, sell_millesimal, display_order } = req.body;
  
  // Validation
  if (!name || !weight_grams || !buy_millesimal || !sell_millesimal) {
    return res.status(400).json({
      success: false,
      error: 'Tüm alanlar zorunludur'
    });
  }
  
  const id = crypto.randomBytes(16).toString('hex');
  
  db.run(
    `INSERT INTO gold_products 
     (id, customer_id, name, weight_grams, buy_millesimal, sell_millesimal, display_order, is_active)
     VALUES (?, ?, ?, ?, ?, ?, ?, 1)`,
    [id, customerId, name, weight_grams, buy_millesimal, sell_millesimal, display_order || 0],
    function(err) {
      if (err) {
        console.error('Database error:', err);
        return res.status(500).json({
          success: false,
          error: 'Ürün eklenemedi'
        });
      }
      
      // Get the created product
      db.get(
        'SELECT * FROM gold_products WHERE id = ?',
        [id],
        (err, product) => {
          if (err || !product) {
            return res.status(500).json({
              success: false,
              error: 'Ürün oluşturuldu ancak getirilemedi'
            });
          }
          
          // Emit WebSocket event for real-time update
          io.emit('gold-products-updated', {
            action: 'added',
            customerId: customerId,
            product: product,
            timestamp: new Date().toISOString()
          });
          
          console.log('📢 WebSocket event emitted: gold-products-updated (added)');
          
          res.json({
            success: true,
            product: product
          });
        }
      );
    }
  );
});

// Update a gold product
app.put('/api/customers/:customerId/gold-products/:productId', (req, res) => {
  const { customerId, productId } = req.params;
  const { name, weight_grams, buy_millesimal, sell_millesimal, display_order, is_active } = req.body;
  
  const updates = [];
  const values = [];
  
  if (name !== undefined) {
    updates.push('name = ?');
    values.push(name);
  }
  if (weight_grams !== undefined) {
    updates.push('weight_grams = ?');
    values.push(weight_grams);
  }
  if (buy_millesimal !== undefined) {
    updates.push('buy_millesimal = ?');
    values.push(buy_millesimal);
  }
  if (sell_millesimal !== undefined) {
    updates.push('sell_millesimal = ?');
    values.push(sell_millesimal);
  }
  if (display_order !== undefined) {
    updates.push('display_order = ?');
    values.push(display_order);
  }
  if (is_active !== undefined) {
    updates.push('is_active = ?');
    values.push(is_active ? 1 : 0);
  }
  
  if (updates.length === 0) {
    return res.status(400).json({
      success: false,
      error: 'Güncellenecek alan bulunamadı'
    });
  }
  
  updates.push('updated_at = CURRENT_TIMESTAMP');
  values.push(productId, customerId);
  
  db.run(
    `UPDATE gold_products 
     SET ${updates.join(', ')}
     WHERE id = ? AND customer_id = ?`,
    values,
    function(err) {
      if (err) {
        console.error('Database error:', err);
        return res.status(500).json({
          success: false,
          error: 'Ürün güncellenemedi'
        });
      }
      
      if (this.changes === 0) {
        return res.status(404).json({
          success: false,
          error: 'Ürün bulunamadı'
        });
      }
      
      // Get updated product
      db.get(
        'SELECT * FROM gold_products WHERE id = ?',
        [productId],
        (err, product) => {
          // Emit WebSocket event for real-time update
          io.emit('gold-products-updated', {
            action: 'updated',
            customerId: customerId,
            product: product,
            timestamp: new Date().toISOString()
          });
          
          console.log('📢 WebSocket event emitted: gold-products-updated (updated)');
          
          res.json({
            success: true,
            product: product
          });
        }
      );
    }
  );
});

// Delete a gold product
app.delete('/api/customers/:customerId/gold-products/:productId', (req, res) => {
  const { customerId, productId } = req.params;
  
  db.run(
    'DELETE FROM gold_products WHERE id = ? AND customer_id = ?',
    [productId, customerId],
    function(err) {
      if (err) {
        console.error('Database error:', err);
        return res.status(500).json({
          success: false,
          error: 'Ürün silinemedi'
        });
      }
      
      if (this.changes === 0) {
        return res.status(404).json({
          success: false,
          error: 'Ürün bulunamadı'
        });
      }
      
      // Emit WebSocket event for real-time update
      io.emit('gold-products-updated', {
        action: 'deleted',
        customerId: customerId,
        productId: productId,
        timestamp: new Date().toISOString()
      });
      
      console.log('📢 WebSocket event emitted: gold-products-updated (deleted)');
      
      res.json({
        success: true,
        message: 'Ürün başarıyla silindi'
      });
    }
  );
});

// ==================== MOBILE USERS MANAGEMENT ====================

// GET - List all mobile users
app.get('/api/mobile-users', authenticateToken, (req, res) => {
  const { page = 1, limit = 20, search = '', status = 'all' } = req.query;
  const offset = (page - 1) * limit;
  
  let query = `
    SELECT 
      id,
      email,
      full_name,
      is_active,
      is_verified,
      created_at,
      last_login
    FROM mobile_users
    WHERE 1=1
  `;
  
  const params = [];
  
  // Add search filter
  if (search) {
    query += ` AND (email LIKE ? OR full_name LIKE ?)`;
    params.push(`%${search}%`, `%${search}%`);
  }
  
  // Add status filter
  if (status === 'active') {
    query += ` AND is_active = 1`;
  } else if (status === 'inactive') {
    query += ` AND is_active = 0`;
  }
  
  // Get total count
  const countQuery = query.replace('SELECT id, email, full_name, is_active, is_verified, created_at, last_login', 'SELECT COUNT(*) as total');
  
  db.get(countQuery, params, (err, countResult) => {
    if (err) {
      return res.status(500).json({ success: false, error: err.message });
    }
    
    const total = countResult.total;
    
    // Add ordering and pagination
    query += ` ORDER BY last_login DESC LIMIT ? OFFSET ?`;
    params.push(parseInt(limit), parseInt(offset));
    
    db.all(query, params, (err, users) => {
      if (err) {
        return res.status(500).json({ success: false, error: err.message });
      }
      
      res.json({
        success: true,
        data: users,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total: total,
          totalPages: Math.ceil(total / limit)
        }
      });
    });
  });
});

// GET - Get single mobile user details
app.get('/api/mobile-users/:userId', authenticateToken, (req, res) => {
  const { userId } = req.params;
  
  db.get(
    `SELECT 
      id,
      email,
      full_name,
      is_active,
      is_verified,
      created_at,
      updated_at,
      last_login
    FROM mobile_users 
    WHERE id = ?`,
    [userId],
    (err, user) => {
      if (err) {
        return res.status(500).json({ success: false, error: err.message });
      }
      
      if (!user) {
        return res.status(404).json({ success: false, error: 'Kullanıcı bulunamadı' });
      }
      
      // Get user's notifications
      db.all(
        `SELECT 
          n.id,
          n.title,
          n.message,
          n.type,
          n.created_at,
          n.status
        FROM notifications n
        WHERE n.customer_id IN (
          SELECT DISTINCT customer_id 
          FROM fcm_tokens 
          WHERE user_id = ?
        )
        ORDER BY n.created_at DESC
        LIMIT 10`,
        [userId],
        (err, notifications) => {
          if (err) {
            console.error('Error fetching notifications:', err);
            notifications = [];
          }
          
          // Get user's login sessions
          db.all(
            `SELECT 
              created_at as login_time,
              ip_address,
              user_agent
            FROM mobile_sessions
            WHERE user_id = ?
            ORDER BY created_at DESC
            LIMIT 10`,
            [userId],
            (err, sessions) => {
              if (err) {
                console.error('Error fetching sessions:', err);
                sessions = [];
              }
              
              res.json({
                success: true,
                data: {
                  user,
                  notifications: notifications || [],
                  sessions: sessions || []
                }
              });
            }
          );
        }
      );
    }
  );
});

// PUT - Update mobile user status (active/inactive)
app.put('/api/mobile-users/:userId/status', authenticateToken, (req, res) => {
  const { userId } = req.params;
  const { is_active } = req.body;
  
  db.run(
    `UPDATE mobile_users 
     SET is_active = ?, updated_at = CURRENT_TIMESTAMP 
     WHERE id = ?`,
    [is_active ? 1 : 0, userId],
    function(err) {
      if (err) {
        return res.status(500).json({ success: false, error: err.message });
      }
      
      if (this.changes === 0) {
        return res.status(404).json({ success: false, error: 'Kullanıcı bulunamadı' });
      }
      
      res.json({
        success: true,
        message: `Kullanıcı ${is_active ? 'aktif' : 'pasif'} duruma getirildi`
      });
    }
  );
});

// DELETE - Delete mobile user
app.delete('/api/mobile-users/:userId', authenticateToken, (req, res) => {
  const { userId } = req.params;
  
  // First delete related records
  db.serialize(() => {
    // Delete FCM tokens
    db.run('DELETE FROM fcm_tokens WHERE user_id = ?', [userId]);
    
    // Delete sessions
    db.run('DELETE FROM mobile_sessions WHERE user_id = ?', [userId]);
    
    // Delete the user
    db.run(
      'DELETE FROM mobile_users WHERE id = ?',
      [userId],
      function(err) {
        if (err) {
          return res.status(500).json({ success: false, error: err.message });
        }
        
        if (this.changes === 0) {
          return res.status(404).json({ success: false, error: 'Kullanıcı bulunamadı' });
        }
        
        res.json({
          success: true,
          message: 'Kullanıcı başarıyla silindi'
        });
      }
    );
  });
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