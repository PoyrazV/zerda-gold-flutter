// Migration v5: Add user authentication fields to fcm_tokens table
// This migration adds user-related fields to support targeted notifications

const sqlite3 = require('sqlite3').verbose();
const path = require('path');

const DB_PATH = path.join(__dirname, '..', 'zerda_admin.db');

function runMigration() {
  return new Promise((resolve, reject) => {
    const db = new sqlite3.Database(DB_PATH);
    
    console.log('🔄 Starting migration v5: User authentication fields...');
    
    db.serialize(() => {
      // 1. Add user fields to fcm_tokens table
      const alterStatements = [
        // Add user_id column
        `ALTER TABLE fcm_tokens ADD COLUMN user_id TEXT`,
        
        // Add is_authenticated flag
        `ALTER TABLE fcm_tokens ADD COLUMN is_authenticated INTEGER DEFAULT 0`,
        
        // Add user_email for reference
        `ALTER TABLE fcm_tokens ADD COLUMN user_email TEXT`,
        
        // Add last_login timestamp
        `ALTER TABLE fcm_tokens ADD COLUMN last_login DATETIME`
      ];
      
      let completed = 0;
      const errors = [];
      
      alterStatements.forEach((statement, index) => {
        db.run(statement, (err) => {
          completed++;
          
          if (err) {
            // Column might already exist, check if it's that error
            if (err.message.includes('duplicate column name')) {
              console.log(`⚠️ Column already exists (statement ${index + 1})`);
            } else {
              console.error(`❌ Error in statement ${index + 1}:`, err.message);
              errors.push(err);
            }
          } else {
            console.log(`✅ Statement ${index + 1} executed successfully`);
          }
          
          if (completed === alterStatements.length) {
            // Create indexes for faster queries
            db.run('CREATE INDEX IF NOT EXISTS idx_fcm_user_id ON fcm_tokens(user_id)', (err) => {
              if (err) {
                console.error('❌ Error creating user_id index:', err.message);
              } else {
                console.log('✅ Created index on user_id');
              }
              
              db.run('CREATE INDEX IF NOT EXISTS idx_fcm_authenticated ON fcm_tokens(is_authenticated)', (err) => {
                if (err) {
                  console.error('❌ Error creating is_authenticated index:', err.message);
                } else {
                  console.log('✅ Created index on is_authenticated');
                }
                
                // 2. Create mobile_users table for mobile app authentication
                const createMobileUsersTable = `
                  CREATE TABLE IF NOT EXISTS mobile_users (
                    id TEXT PRIMARY KEY,
                    email TEXT UNIQUE NOT NULL,
                    password_hash TEXT NOT NULL,
                    full_name TEXT,
                    phone_number TEXT,
                    profile_image TEXT,
                    is_active INTEGER DEFAULT 1,
                    is_verified INTEGER DEFAULT 0,
                    verification_token TEXT,
                    reset_token TEXT,
                    reset_token_expires DATETIME,
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    last_login DATETIME
                  )`;
                
                db.run(createMobileUsersTable, (err) => {
                  if (err) {
                    console.error('❌ Error creating mobile_users table:', err.message);
                    errors.push(err);
                  } else {
                    console.log('✅ Mobile users table created successfully');
                  }
                  
                  // 3. Create mobile_sessions table
                  const createMobileSessionsTable = `
                    CREATE TABLE IF NOT EXISTS mobile_sessions (
                      id TEXT PRIMARY KEY,
                      user_id TEXT NOT NULL,
                      token TEXT UNIQUE NOT NULL,
                      device_id TEXT,
                      fcm_token TEXT,
                      platform TEXT,
                      app_version TEXT,
                      expires_at DATETIME NOT NULL,
                      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                      last_activity DATETIME DEFAULT CURRENT_TIMESTAMP,
                      FOREIGN KEY (user_id) REFERENCES mobile_users(id) ON DELETE CASCADE
                    )`;
                  
                  db.run(createMobileSessionsTable, (err) => {
                    if (err) {
                      console.error('❌ Error creating mobile_sessions table:', err.message);
                      errors.push(err);
                    } else {
                      console.log('✅ Mobile sessions table created successfully');
                    }
                    
                    // Create indexes for sessions table
                    db.run('CREATE INDEX IF NOT EXISTS idx_mobile_sessions_user_id ON mobile_sessions(user_id)', (err) => {
                      if (err) {
                        console.error('❌ Error creating session index:', err.message);
                      }
                      
                      db.run('CREATE INDEX IF NOT EXISTS idx_mobile_sessions_token ON mobile_sessions(token)', (err) => {
                        if (err) {
                          console.error('❌ Error creating token index:', err.message);
                        }
                        
                        // 4. Add sample mobile users for testing
                        const bcrypt = require('bcryptjs');
                        const { v4: uuidv4 } = require('uuid');
                        
                        const sampleUsers = [
                          {
                            id: uuidv4(),
                            email: 'demo@zerda.com',
                            password: 'demo123',
                            full_name: 'Demo User',
                            is_verified: 1
                          },
                          {
                            id: uuidv4(),
                            email: 'test@zerda.com',
                            password: 'test123',
                            full_name: 'Test User',
                            is_verified: 1
                          }
                        ];
                        
                        let usersProcessed = 0;
                        
                        sampleUsers.forEach(user => {
                          const hashedPassword = bcrypt.hashSync(user.password, 10);
                          
                          db.run(
                            `INSERT OR IGNORE INTO mobile_users (id, email, password_hash, full_name, is_verified) 
                             VALUES (?, ?, ?, ?, ?)`,
                            [user.id, user.email, hashedPassword, user.full_name, user.is_verified],
                            (err) => {
                              usersProcessed++;
                              
                              if (err) {
                                console.error(`❌ Error inserting user ${user.email}:`, err.message);
                              } else {
                                console.log(`✅ Sample user created: ${user.email}`);
                              }
                              
                              if (usersProcessed === sampleUsers.length) {
                                // Migration complete
                                db.close((err) => {
                                  if (err) {
                                    console.error('Error closing database:', err);
                                  }
                                  
                                  if (errors.length > 0) {
                                    console.log(`\n⚠️ Migration completed with ${errors.length} errors`);
                                    resolve(false);
                                  } else {
                                    console.log('\n✅ Migration v5 completed successfully!');
                                    console.log('\n📝 Sample users created:');
                                    console.log('   - demo@zerda.com (password: demo123)');
                                    console.log('   - test@zerda.com (password: test123)');
                                    resolve(true);
                                  }
                                });
                              }
                            }
                          );
                        });
                      });
                    });
                  });
                });
              });
            });
          }
        });
      });
    });
  });
}

// Run migration if called directly
if (require.main === module) {
  runMigration()
    .then(success => {
      process.exit(success ? 0 : 1);
    })
    .catch(err => {
      console.error('Migration failed:', err);
      process.exit(1);
    });
}

module.exports = runMigration;