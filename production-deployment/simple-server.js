const express = require('express');
const { Pool } = require('pg');
const path = require('path');
const fs = require('fs');
const session = require('express-session');

// Load environment variables
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 5000;

// Database connection
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: false
});

// Session configuration
app.use(session({
  secret: process.env.SESSION_SECRET || 'your-secret-key',
  resave: false,
  saveUninitialized: false,
  cookie: { secure: false, maxAge: 24 * 60 * 60 * 1000 } // 24 hours
}));

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static('public'));

// Okta configuration
const OKTA_CLIENT_ID = process.env.OKTA_CLIENT_ID;
const OKTA_CLIENT_SECRET = process.env.OKTA_CLIENT_SECRET;
const OKTA_ISSUER = process.env.OKTA_ISSUER;
const OKTA_REDIRECT_URI = process.env.OKTA_REDIRECT_URI || 'http://localhost:5000/callback';

// Authentication middleware
const requireAuth = (req, res, next) => {
  if (!req.session.user) {
    return res.status(401).json({ error: 'Authentication required' });
  }
  next();
};

// Canvas API configuration
const CANVAS_API_URL = process.env.CANVAS_API_URL;
const CANVAS_API_TOKEN = process.env.CANVAS_API_TOKEN;

// Okta authentication endpoints
app.get('/login', (req, res) => {
  const state = Math.random().toString(36).substring(7);
  req.session.state = state;
  
  const authUrl = `${OKTA_ISSUER}/v1/authorize?` +
    `client_id=${OKTA_CLIENT_ID}&` +
    `response_type=code&` +
    `scope=openid profile email&` +
    `redirect_uri=${encodeURIComponent(OKTA_REDIRECT_URI)}&` +
    `state=${state}`;
  
  res.redirect(authUrl);
});

app.get('/callback', async (req, res) => {
  const { code, state } = req.query;
  
  if (!code || state !== req.session.state) {
    return res.status(400).send('Invalid authorization callback');
  }
  
  try {
    // Exchange code for token
    const tokenResponse = await fetch(`${OKTA_ISSUER}/v1/token`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization': `Basic ${Buffer.from(`${OKTA_CLIENT_ID}:${OKTA_CLIENT_SECRET}`).toString('base64')}`
      },
      body: new URLSearchParams({
        grant_type: 'authorization_code',
        code,
        redirect_uri: OKTA_REDIRECT_URI
      })
    });
    
    const tokenData = await tokenResponse.json();
    
    if (!tokenResponse.ok) {
      throw new Error('Token exchange failed');
    }
    
    // Get user info
    const userResponse = await fetch(`${OKTA_ISSUER}/v1/userinfo`, {
      headers: {
        'Authorization': `Bearer ${tokenData.access_token}`
      }
    });
    
    const userData = await userResponse.json();
    
    if (!userResponse.ok) {
      throw new Error('Failed to get user info');
    }
    
    // Store user in session
    req.session.user = {
      id: userData.sub,
      email: userData.email,
      firstName: userData.given_name,
      lastName: userData.family_name
    };
    
    // Store/update user in database
    await pool.query(
      'INSERT INTO users (okta_id, email, first_name, last_name) VALUES ($1, $2, $3, $4) ON CONFLICT (okta_id) DO UPDATE SET email = $2, first_name = $3, last_name = $4',
      [userData.sub, userData.email, userData.given_name, userData.family_name]
    );
    
    res.redirect('/');
  } catch (error) {
    console.error('OAuth callback error:', error);
    res.status(500).send('Authentication failed');
  }
});

app.get('/logout', (req, res) => {
  req.session.destroy((err) => {
    if (err) {
      console.error('Session destruction error:', err);
    }
    res.redirect('/');
  });
});

app.get('/api/user', (req, res) => {
  if (req.session.user) {
    res.json(req.session.user);
  } else {
    res.status(401).json({ error: 'Not authenticated' });
  }
});

// Health check endpoint
app.get('/health', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    res.json({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      database: { status: 'connected' }
    });
  } catch (error) {
    res.status(503).json({
      status: 'unhealthy',
      timestamp: new Date().toISOString(),
      error: error.message,
      database: { status: 'disconnected' }
    });
  }
});

// Get Canvas accounts with sub-accounts
app.get('/api/accounts', requireAuth, async (req, res) => {
  try {
    console.log('Fetching Canvas accounts...');
    
    // First get the root account
    const rootResponse = await fetch(`${CANVAS_API_URL}/accounts`, {
      headers: {
        'Authorization': `Bearer ${CANVAS_API_TOKEN}`,
        'Content-Type': 'application/json'
      }
    });
    
    if (!rootResponse.ok) {
      throw new Error(`Canvas API error: ${rootResponse.status}`);
    }
    
    const rootAccounts = await rootResponse.json();
    console.log('Root accounts:', rootAccounts);
    
    // Get sub-accounts for each root account
    const allAccounts = [];
    
    for (const rootAccount of rootAccounts) {
      allAccounts.push(rootAccount);
      
      try {
        // Get sub-accounts
        const subResponse = await fetch(`${CANVAS_API_URL}/accounts/${rootAccount.id}/sub_accounts?recursive=true`, {
          headers: {
            'Authorization': `Bearer ${CANVAS_API_TOKEN}`,
            'Content-Type': 'application/json'
          }
        });
        
        if (subResponse.ok) {
          const subAccounts = await subResponse.json();
          allAccounts.push(...subAccounts);
        }
      } catch (subError) {
        console.warn(`Error fetching sub-accounts for ${rootAccount.name}:`, subError);
      }
    }
    
    console.log(`Total accounts found: ${allAccounts.length}`);
    res.json(allAccounts);
  } catch (error) {
    console.error('Error fetching accounts:', error);
    res.status(500).json({ error: 'Failed to fetch accounts', details: error.message });
  }
});

// Create course shells
app.post('/api/course-shells', requireAuth, async (req, res) => {
  try {
    const { shells, selectedAccounts } = req.body;
    
    if (!shells || !Array.isArray(shells)) {
      return res.status(400).json({ error: 'Invalid shells data' });
    }
    
    // Get user ID from database
    const userResult = await pool.query('SELECT id FROM users WHERE okta_id = $1', [req.session.user.id]);
    const userId = userResult.rows[0].id;
    
    // Create a batch record
    const batchId = `batch-${Date.now()}`;
    const batchResult = await pool.query(
      'INSERT INTO creation_batches (batch_id, user_id, total_shells, status) VALUES ($1, $2, $3, $4) RETURNING *',
      [batchId, userId, shells.length, 'in_progress']
    );
    
    // Insert course shells
    const courseShellPromises = shells.map(async (shell) => {
      try {
        // Create course in Canvas
        const canvasResponse = await fetch(`${CANVAS_API_URL}/accounts/${shell.accountId}/courses`, {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${CANVAS_API_TOKEN}`,
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({
            course: {
              name: shell.name,
              course_code: shell.courseCode,
              start_at: shell.startDate,
              end_at: shell.endDate
            }
          })
        });
        
        if (!canvasResponse.ok) {
          throw new Error(`Canvas API error: ${canvasResponse.status}`);
        }
        
        const canvasCourse = await canvasResponse.json();
        
        // Save to database
        await pool.query(
          'INSERT INTO course_shells (name, course_code, canvas_id, account_id, start_date, end_date, status, created_by_user_id, batch_id) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)',
          [shell.name, shell.courseCode, canvasCourse.id, shell.accountId, shell.startDate, shell.endDate, 'created', userId, batchId]
        );
        
        return { success: true, shell: shell.name };
      } catch (error) {
        console.error(`Error creating course ${shell.name}:`, error);
        
        // Save failed shell to database
        await pool.query(
          'INSERT INTO course_shells (name, course_code, account_id, start_date, end_date, status, created_by_user_id, batch_id, error) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)',
          [shell.name, shell.courseCode, shell.accountId, shell.startDate, shell.endDate, 'failed', userId, batchId, error.message]
        );
        
        return { success: false, shell: shell.name, error: error.message };
      }
    });
    
    // Wait for all course creations to complete
    const results = await Promise.all(courseShellPromises);
    
    // Update batch status
    const completed = results.filter(r => r.success).length;
    const failed = results.filter(r => !r.success).length;
    
    await pool.query(
      'UPDATE creation_batches SET completed_shells = $1, failed_shells = $2, status = $3 WHERE batch_id = $4',
      [completed, failed, 'completed', batchId]
    );
    
    res.json({
      batchId,
      results,
      summary: {
        total: shells.length,
        completed,
        failed
      }
    });
    
  } catch (error) {
    console.error('Error creating course shells:', error);
    res.status(500).json({ error: 'Failed to create course shells' });
  }
});

// Get batch status
app.get('/api/batch/:batchId', requireAuth, async (req, res) => {
  try {
    const { batchId } = req.params;
    
    const batchResult = await pool.query(
      'SELECT * FROM creation_batches WHERE batch_id = $1',
      [batchId]
    );
    
    if (batchResult.rows.length === 0) {
      return res.status(404).json({ error: 'Batch not found' });
    }
    
    const shellsResult = await pool.query(
      'SELECT * FROM course_shells WHERE batch_id = $1',
      [batchId]
    );
    
    res.json({
      batch: batchResult.rows[0],
      shells: shellsResult.rows
    });
    
  } catch (error) {
    console.error('Error fetching batch status:', error);
    res.status(500).json({ error: 'Failed to fetch batch status' });
  }
});

// Get recent activity
app.get('/api/recent-activity', requireAuth, async (req, res) => {
  try {
    // Get user ID from database
    const userResult = await pool.query('SELECT id FROM users WHERE okta_id = $1', [req.session.user.id]);
    const userId = userResult.rows[0].id;
    
    const result = await pool.query(
      'SELECT * FROM creation_batches WHERE user_id = $1 ORDER BY created_at DESC LIMIT 10',
      [userId]
    );
    
    res.json(result.rows);
  } catch (error) {
    console.error('Error fetching recent activity:', error);
    res.status(500).json({ error: 'Failed to fetch recent activity' });
  }
});

// Serve frontend
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Canvas Course Shell Generator running on port ${PORT}`);
});