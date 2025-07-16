#!/usr/bin/env node

import { config } from 'dotenv';
import pg from 'pg';

// Load environment variables
config();

console.log('Environment Variables Test:');
console.log('=========================');
console.log('DATABASE_URL:', process.env.DATABASE_URL || 'NOT SET');
console.log('PGUSER:', process.env.PGUSER || 'NOT SET');
console.log('PGPASSWORD:', process.env.PGPASSWORD || 'NOT SET');
console.log('PGDATABASE:', process.env.PGDATABASE || 'NOT SET');
console.log('PGHOST:', process.env.PGHOST || 'NOT SET');
console.log('PGPORT:', process.env.PGPORT || 'NOT SET');

// Test connection string parsing
if (process.env.DATABASE_URL) {
  try {
    const url = new URL(process.env.DATABASE_URL);
    console.log('\nParsed Connection String:');
    console.log('Protocol:', url.protocol);
    console.log('Username:', url.username);
    console.log('Password:', url.password ? '***' : 'NOT SET');
    console.log('Hostname:', url.hostname);
    console.log('Port:', url.port);
    console.log('Database:', url.pathname.substring(1));
  } catch (error) {
    console.error('Error parsing DATABASE_URL:', error.message);
  }
}

// Test actual database connection
const { Pool } = pg;

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: false
});

console.log('\nTesting database connection...');
pool.query('SELECT 1')
  .then(() => {
    console.log('Database connection: SUCCESS');
    process.exit(0);
  })
  .catch(error => {
    console.error('Database connection: FAILED');
    console.error('Error:', error.message);
    process.exit(1);
  });