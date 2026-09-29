-- ========================================================
-- Plant Water Management System (PWMS)
-- PostgreSQL Database Schema & Default Admin Account
-- For Render.com Managed PostgreSQL Database
-- ========================================================

-- 1. Schedules Table
CREATE TABLE IF NOT EXISTS schedules (
    id SERIAL PRIMARY KEY,
    type VARCHAR(20) NOT NULL DEFAULT 'recurring',
    time VARCHAR(20) NOT NULL,
    date VARCHAR(20) DEFAULT NULL,
    days TEXT DEFAULT NULL,
    duration INT NOT NULL DEFAULT 1,
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Logs Table (User-tracked)
CREATE TABLE IF NOT EXISTS logs (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) DEFAULT NULL,
    user_name VARCHAR(100) DEFAULT NULL,
    event VARCHAR(255) NOT NULL,
    time VARCHAR(60) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Live Device State Table (Motor State & ESP32 Heartbeat)
CREATE TABLE IF NOT EXISTS device_state (
    id INT PRIMARY KEY DEFAULT 1,
    motor_state INT NOT NULL DEFAULT 0,
    last_ping TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45) DEFAULT NULL
);

-- 4. Users Table (Admin & Staff Authentication)
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL DEFAULT '',
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'staff',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- --------------------------------------------------------
-- Initial Data Seeding
-- --------------------------------------------------------

-- Default Administrator (Username: admin | Password: admin123)
INSERT INTO users (name, username, password, role)
VALUES ('System Administrator', 'admin', 'admin123', 'admin')
ON CONFLICT (username) DO NOTHING;

-- Default Device State
INSERT INTO device_state (id, motor_state, last_ping, ip_address)
VALUES (1, 0, NOW(), '127.0.0.1')
ON CONFLICT (id) DO NOTHING;
