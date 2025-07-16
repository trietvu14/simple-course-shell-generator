-- Canvas Course Shell Generator Database Schema
-- Run this script to create all required tables

-- Users table
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    okta_id TEXT UNIQUE NOT NULL,
    email TEXT UNIQUE NOT NULL,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- Canvas accounts table
CREATE TABLE canvas_accounts (
    id SERIAL PRIMARY KEY,
    canvas_id TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    parent_account_id TEXT,
    workflow_state TEXT NOT NULL,
    root_account_id TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- Creation batches table
CREATE TABLE creation_batches (
    id SERIAL PRIMARY KEY,
    batch_id TEXT UNIQUE NOT NULL,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    total_shells INTEGER NOT NULL,
    completed_shells INTEGER NOT NULL DEFAULT 0,
    failed_shells INTEGER NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'in_progress',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- Course shells table
CREATE TABLE course_shells (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    course_code TEXT NOT NULL,
    canvas_id TEXT UNIQUE,
    account_id TEXT NOT NULL,
    start_date TIMESTAMP,
    end_date TIMESTAMP,
    status TEXT NOT NULL DEFAULT 'pending',
    created_by_user_id INTEGER REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    batch_id TEXT REFERENCES creation_batches(batch_id) ON DELETE CASCADE,
    error TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- User sessions table
CREATE TABLE user_sessions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    session_token TEXT UNIQUE NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- Create indexes for better performance
CREATE INDEX idx_users_okta_id ON users(okta_id);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_canvas_accounts_canvas_id ON canvas_accounts(canvas_id);
CREATE INDEX idx_canvas_accounts_parent_id ON canvas_accounts(parent_account_id);
CREATE INDEX idx_course_shells_batch_id ON course_shells(batch_id);
CREATE INDEX idx_course_shells_account_id ON course_shells(account_id);
CREATE INDEX idx_creation_batches_user_id ON creation_batches(user_id);
CREATE INDEX idx_user_sessions_token ON user_sessions(session_token);
CREATE INDEX idx_user_sessions_user_id ON user_sessions(user_id);

-- Grant permissions to canvas_app user
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO canvas_app;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO canvas_app;