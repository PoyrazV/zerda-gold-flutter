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
    // Get FCM tokens for the customer
    db.all(
      'SELECT fcm_token FROM fcm_tokens WHERE customer_id = ?',
      [customerId],
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

        try {
          // Prepare the message with high priority for background delivery
          const baseMessage = {
            notification: {
              title: notificationData.title,
              body: notificationData.message,
            },
            data: {
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
                defaultVibrateTimings: true,
              },
            },
            apns: {
              payload: {
                aps: {
                  alert: {
                    title: notificationData.title,
                    body: notificationData.message,
                  },
                  sound: 'default',
                  contentAvailable: true,
                },
              },
            },
          };

          // Send to each token individually for better compatibility
          const sendPromises = fcmTokens.map(token => {
            const message = { ...baseMessage, token };
            return admin.messaging().send(message)
              .then(response => ({ success: true, response, token }))
              .catch(error => ({ success: false, error, token }));
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
          type
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
  const { title, message, type = 'info', customerIds = [], excludeCustomerIds = [] } = req.body;

  if (!title || !message) {
    return res.status(400).json({
      success: false,
      error: 'Başlık ve mesaj gerekli'
    });
  }

  // Tüm müşterilere gönder (eğer customerIds belirtilmemişse)
  let query = 'SELECT id FROM customers';
  let params = [];

  if (customerIds.length > 0) {
    const placeholders = customerIds.map(() => '?').join(',');
    query += ` WHERE id IN (${placeholders})`;
    params = customerIds;
  } else if (excludeCustomerIds.length > 0) {
    const placeholders = excludeCustomerIds.map(() => '?').join(',');
    query += ` WHERE id NOT IN (${placeholders})`;
    params = excludeCustomerIds;
  }

  try {
    // Promisify db.all
    const customers = await new Promise((resolve, reject) => {
      db.all(query, params, (err, results) => {
        if (err) reject(err);
        else resolve(results);
      });
    });

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
             VALUES (?, ?, ?, ?, ?, 'all', 'sent', ?, ?, ?)`,
            [notificationId, customer.id, title, message, type, now, now, now],
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
          target: 'all',
          timestamp: now
        });

        // FCM push notification gönder
        const fcmResult = await sendFCMNotification(customer.id, {
          id: notificationId,
          title,
          message,
          type
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

// FCM Token Registration - Mobile API endpoint
app.post('/api/mobile/register-fcm-token', async (req, res) => {
  const { customerId, fcmToken, platform, deviceId } = req.body;

  if (!customerId || !fcmToken) {
    return res.status(400).json({ success: false, error: 'Missing customerId or fcmToken' });
  }

  const tokenId = uuidv4();
  
  try {
    // First, try to update existing token
    await new Promise((resolve, reject) => {
      db.run(
        `UPDATE fcm_tokens SET fcm_token = ?, platform = ?, device_id = ?, updated_at = CURRENT_TIMESTAMP 
         WHERE customer_id = ? AND (fcm_token = ? OR device_id = ?)`,
        [fcmToken, platform || 'flutter', deviceId || null, customerId, fcmToken, deviceId || null],
        function(err) {
          if (err) return reject(err);
          resolve(this.changes);
        }
      );
    }).then((changes) => {
      // If no rows were updated, insert new token
      if (changes === 0) {
        return new Promise((resolve, reject) => {
          db.run(
            `INSERT OR REPLACE INTO fcm_tokens (id, customer_id, fcm_token, platform, device_id) 
             VALUES (?, ?, ?, ?, ?)`,
            [tokenId, customerId, fcmToken, platform || 'flutter', deviceId || null],
            function(err) {
              if (err) return reject(err);
              resolve();
            }
          );
        });
      }
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