-- Create database if not exists
CREATE DATABASE IF NOT EXISTS zerda_admin CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE zerda_admin;

-- Drop tables if they exist (for clean setup)
DROP TABLE IF EXISTS notification_deliveries;
DROP TABLE IF EXISTS notifications;
DROP TABLE IF EXISTS gold_products;
DROP TABLE IF EXISTS fcm_tokens;
DROP TABLE IF EXISTS mobile_sessions;
DROP TABLE IF EXISTS mobile_users;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS users;

-- 1. Admin users table
CREATE TABLE users (
  id INT PRIMARY KEY AUTO_INCREMENT,
  username VARCHAR(100) UNIQUE NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  role VARCHAR(50) DEFAULT 'admin',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_username (username),
  INDEX idx_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2. Customers table
CREATE TABLE customers (
  id VARCHAR(36) PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  phone VARCHAR(20),
  address TEXT,
  company_name VARCHAR(255),
  tax_id VARCHAR(50),
  website VARCHAR(255),
  logo_url VARCHAR(500),
  primary_color VARCHAR(7) DEFAULT '#2563eb',
  secondary_color VARCHAR(7) DEFAULT '#1e40af',
  accent_color VARCHAR(7) DEFAULT '#f59e0b',
  features JSON,
  is_active BOOLEAN DEFAULT TRUE,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_email (email),
  INDEX idx_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 3. Mobile users table
CREATE TABLE mobile_users (
  id VARCHAR(36) PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  full_name VARCHAR(255),
  phone_number VARCHAR(20),
  profile_image TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  is_verified BOOLEAN DEFAULT FALSE,
  verification_token VARCHAR(255),
  reset_token VARCHAR(255),
  reset_token_expires DATETIME,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  last_login DATETIME,
  INDEX idx_email (email),
  INDEX idx_created (created_at),
  INDEX idx_is_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 4. Mobile sessions table
CREATE TABLE mobile_sessions (
  id VARCHAR(36) PRIMARY KEY,
  user_id VARCHAR(36) NOT NULL,
  token VARCHAR(500) UNIQUE NOT NULL,
  device_id VARCHAR(255),
  fcm_token VARCHAR(500),
  platform VARCHAR(20),
  ip_address VARCHAR(45),
  user_agent TEXT,
  expires_at DATETIME,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES mobile_users(id) ON DELETE CASCADE,
  INDEX idx_user_id (user_id),
  INDEX idx_token (token),
  INDEX idx_expires (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 5. FCM tokens table
CREATE TABLE fcm_tokens (
  id INT PRIMARY KEY AUTO_INCREMENT,
  customer_id VARCHAR(36),
  fcm_token VARCHAR(500) UNIQUE NOT NULL,
  device_id VARCHAR(255),
  platform VARCHAR(20),
  user_id VARCHAR(36),
  user_email VARCHAR(255),
  is_authenticated BOOLEAN DEFAULT FALSE,
  last_login DATETIME,
  is_active BOOLEAN DEFAULT TRUE,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE,
  INDEX idx_customer (customer_id),
  INDEX idx_user_id (user_id),
  INDEX idx_is_authenticated (is_authenticated),
  INDEX idx_fcm_token (fcm_token)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 6. Notifications table
CREATE TABLE notifications (
  id INT PRIMARY KEY AUTO_INCREMENT,
  customer_id VARCHAR(36) NOT NULL,
  title VARCHAR(255) NOT NULL,
  message TEXT NOT NULL,
  type VARCHAR(50) DEFAULT 'info',
  target VARCHAR(50) DEFAULT 'all',
  scheduled_time DATETIME,
  sent_at DATETIME,
  status VARCHAR(50) DEFAULT 'pending',
  success_count INT DEFAULT 0,
  failure_count INT DEFAULT 0,
  total_count INT DEFAULT 0,
  error_message TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE,
  INDEX idx_customer (customer_id),
  INDEX idx_status (status),
  INDEX idx_created (created_at),
  INDEX idx_scheduled (scheduled_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 7. Notification deliveries table
CREATE TABLE notification_deliveries (
  id INT PRIMARY KEY AUTO_INCREMENT,
  notification_id INT NOT NULL,
  fcm_token VARCHAR(500) NOT NULL,
  device_id VARCHAR(255),
  user_id VARCHAR(36),
  user_email VARCHAR(255),
  is_authenticated BOOLEAN DEFAULT FALSE,
  status VARCHAR(50) DEFAULT 'pending',
  sent_at DATETIME,
  delivered_at DATETIME,
  error_message TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (notification_id) REFERENCES notifications(id) ON DELETE CASCADE,
  INDEX idx_notification (notification_id),
  INDEX idx_status (status),
  INDEX idx_user_id (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 8. Gold products table
CREATE TABLE gold_products (
  id INT PRIMARY KEY AUTO_INCREMENT,
  customer_id VARCHAR(36) NOT NULL,
  name VARCHAR(255) NOT NULL,
  purity VARCHAR(50),
  weight VARCHAR(50),
  unit VARCHAR(20),
  buy_price DECIMAL(10, 2),
  sell_price DECIMAL(10, 2),
  stock_quantity INT DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE,
  INDEX idx_customer (customer_id),
  INDEX idx_is_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Insert default admin user (password: admin123)
INSERT INTO users (username, email, password_hash, role) VALUES 
('admin', 'admin@zerda.com', '$2a$10$5QzK1pe9HWzZdFy9GvJBn.wQJ6b9Q9kGxFxZK6XGkL1KjvFfZxWH2', 'admin');

-- Insert default customer
INSERT INTO customers (id, name, email, company_name, features) VALUES 
('ffeee61a-8497-4c70-857e-c8f0efb13a2a', 'Zerda Gold', 'info@zerdagold.com', 'Zerda Gold Ltd.', 
'{"dashboard": true, "goldPrices": true, "currencyExchange": true, "portfolio": true, "calculator": true, "alerts": true, "news": false, "support": true}');

-- Insert test mobile users (passwords: demo123 and test123)
INSERT INTO mobile_users (id, email, password_hash, full_name, is_active, is_verified) VALUES
('90f7e22f-7a7f-48ba-b591-86778ecdbf9d', 'demo@zerda.com', '$2a$10$bJGLHHRYbDrGXUXj0bQMTOhvZNkL4j5k1qH3sCxGXiU5xH8qZxKUa', 'Demo User', TRUE, TRUE),
('fe245810-308a-4d4e-a561-b980477aebe3', 'test@zerda.com', '$2a$10$MJfKpL2kaHrP3BkFXvU9OeJpO9ktT8c6bLWJ/ZVGM3CQz6eS9eEnG', 'Test User', TRUE, TRUE);

-- Insert sample gold products
INSERT INTO gold_products (customer_id, name, purity, weight, unit, buy_price, sell_price, stock_quantity) VALUES
('ffeee61a-8497-4c70-857e-c8f0efb13a2a', 'Cumhuriyet Altını', '22 Ayar', '7.216', 'gram', 8750.00, 8950.00, 50),
('ffeee61a-8497-4c70-857e-c8f0efb13a2a', 'Yarım Altın', '22 Ayar', '3.608', 'gram', 4375.00, 4475.00, 100),
('ffeee61a-8497-4c70-857e-c8f0efb13a2a', 'Çeyrek Altın', '22 Ayar', '1.804', 'gram', 2187.00, 2237.00, 150),
('ffeee61a-8497-4c70-857e-c8f0efb13a2a', 'Gram Altın', '24 Ayar', '1.000', 'gram', 1210.00, 1225.00, 500);