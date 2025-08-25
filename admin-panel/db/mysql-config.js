const mysql = require('mysql2');
require('dotenv').config();

// Create connection pool for better performance
const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'zerda_admin',
  port: process.env.DB_PORT || 3306,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  enableKeepAlive: true,
  keepAliveInitialDelay: 0
});

// Promisify for async/await support
const promisePool = pool.promise();

// Helper functions that match SQLite interface
const db = {
  // Execute a query and return first row (like db.get)
  async get(query, params = []) {
    try {
      const [rows] = await promisePool.execute(query, params);
      return rows[0] || null;
    } catch (error) {
      console.error('Database GET error:', error);
      throw error;
    }
  },

  // Execute a query and return all rows (like db.all)
  async all(query, params = []) {
    try {
      const [rows] = await promisePool.execute(query, params);
      return rows;
    } catch (error) {
      console.error('Database ALL error:', error);
      throw error;
    }
  },

  // Execute a query without returning rows (like db.run)
  async run(query, params = []) {
    try {
      const [result] = await promisePool.execute(query, params);
      return {
        insertId: result.insertId,
        affectedRows: result.affectedRows,
        changedRows: result.changedRows
      };
    } catch (error) {
      console.error('Database RUN error:', error);
      throw error;
    }
  },

  // Direct execute for complex queries
  async execute(query, params = []) {
    try {
      const [result] = await promisePool.execute(query, params);
      return result;
    } catch (error) {
      console.error('Database EXECUTE error:', error);
      throw error;
    }
  },

  // Transaction support
  async beginTransaction() {
    const connection = await promisePool.getConnection();
    await connection.beginTransaction();
    return connection;
  },

  // Test connection
  async testConnection() {
    try {
      await promisePool.execute('SELECT 1');
      console.log('✅ MySQL connection successful');
      return true;
    } catch (error) {
      console.error('❌ MySQL connection failed:', error.message);
      return false;
    }
  },

  // Close pool
  async close() {
    await promisePool.end();
  }
};

module.exports = db;