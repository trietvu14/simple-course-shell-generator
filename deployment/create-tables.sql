-- Create database tables for Canvas Course Shell Generator
-- Run this once before deploying the application

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    okta_id VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(255) NOT NULL,
    first_name VARCHAR(255),
    last_name VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Creation batches table
CREATE TABLE IF NOT EXISTS creation_batches (
    id SERIAL PRIMARY KEY,
    batch_id VARCHAR(255) UNIQUE NOT NULL,
    user_id INTEGER REFERENCES users(id),
    total_shells INTEGER NOT NULL DEFAULT 0,
    completed_shells INTEGER NOT NULL DEFAULT 0,
    failed_shells INTEGER NOT NULL DEFAULT 0,
    status VARCHAR(50) NOT NULL DEFAULT 'in_progress',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Course shells table
CREATE TABLE IF NOT EXISTS course_shells (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    course_code VARCHAR(255) NOT NULL,
    canvas_id VARCHAR(255),
    account_id VARCHAR(255) NOT NULL,
    start_date DATE,
    end_date DATE,
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    created_by_user_id INTEGER REFERENCES users(id),
    batch_id VARCHAR(255) REFERENCES creation_batches(batch_id),
    error TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_okta_id ON users(okta_id);
CREATE INDEX IF NOT EXISTS idx_creation_batches_batch_id ON creation_batches(batch_id);
CREATE INDEX IF NOT EXISTS idx_creation_batches_user_id ON creation_batches(user_id);
CREATE INDEX IF NOT EXISTS idx_course_shells_batch_id ON course_shells(batch_id);
CREATE INDEX IF NOT EXISTS idx_course_shells_user_id ON course_shells(created_by_user_id);

-- Grant permissions to canvas_app user
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO canvas_app;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO canvas_app;