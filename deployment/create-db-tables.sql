-- Create database tables for Canvas Course Generator
-- Based on shared/schema.ts

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    okta_id VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    first_name VARCHAR(255) NOT NULL,
    last_name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Canvas accounts table
CREATE TABLE IF NOT EXISTS canvas_accounts (
    id SERIAL PRIMARY KEY,
    canvas_id VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    parent_account_id VARCHAR(255),
    workflow_state VARCHAR(50) NOT NULL,
    root_account_id VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Creation batches table
CREATE TABLE IF NOT EXISTS creation_batches (
    id SERIAL PRIMARY KEY,
    batch_id VARCHAR(255) UNIQUE NOT NULL,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    total_shells INTEGER NOT NULL DEFAULT 0,
    completed_shells INTEGER NOT NULL DEFAULT 0,
    failed_shells INTEGER NOT NULL DEFAULT 0,
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
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
    created_by_user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    batch_id VARCHAR(255) REFERENCES creation_batches(batch_id) ON DELETE CASCADE,
    error TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- User sessions table
CREATE TABLE IF NOT EXISTS user_sessions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    session_token VARCHAR(255) UNIQUE NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_okta_id ON users(okta_id);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_canvas_accounts_canvas_id ON canvas_accounts(canvas_id);
CREATE INDEX IF NOT EXISTS idx_canvas_accounts_parent_id ON canvas_accounts(parent_account_id);
CREATE INDEX IF NOT EXISTS idx_course_shells_batch_id ON course_shells(batch_id);
CREATE INDEX IF NOT EXISTS idx_course_shells_account_id ON course_shells(account_id);
CREATE INDEX IF NOT EXISTS idx_creation_batches_user_id ON creation_batches(user_id);
CREATE INDEX IF NOT EXISTS idx_user_sessions_token ON user_sessions(session_token);
CREATE INDEX IF NOT EXISTS idx_user_sessions_user_id ON user_sessions(user_id);

-- Grant permissions to canvas_app user
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO canvas_app;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO canvas_app;