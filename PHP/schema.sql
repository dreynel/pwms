-- ========================================================
-- Plant Water Management System (PWMS) / Conveyor Control
-- MySQL Database Schema & Initial Data
-- Compatible with InfinityFree & Standard MySQL / MariaDB
-- ========================================================

-- 1. Schedules Table (Recurring & Calendar Date Plans)
CREATE TABLE IF NOT EXISTS `schedules` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `type` VARCHAR(20) NOT NULL DEFAULT 'recurring', -- 'recurring' or 'calendar'
    `time` VARCHAR(20) NOT NULL,                     -- e.g. '10:30 AM'
    `date` VARCHAR(20) DEFAULT NULL,                 -- e.g. '2026-09-30' (for calendar type)
    `days` TEXT DEFAULT NULL,                        -- JSON string: '["Mon","Wed"]' (for recurring)
    `duration` INT NOT NULL DEFAULT 1,               -- Duration in minutes
    `enabled` TINYINT(1) NOT NULL DEFAULT 1,         -- 1 = enabled, 0 = disabled
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2. Hardware & Activity Logs Table (User-tracked)
CREATE TABLE IF NOT EXISTS `logs` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `username` VARCHAR(50) DEFAULT NULL,            -- Associated worker username (e.g. 'mario_s')
    `user_name` VARCHAR(100) DEFAULT NULL,          -- Associated worker display name
    `event` VARCHAR(255) NOT NULL,
    `time` VARCHAR(60) NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 3. Live Device State Table (Motor State & ESP32 Heartbeat)
CREATE TABLE IF NOT EXISTS `device_state` (
    `id` INT PRIMARY KEY DEFAULT 1,
    `motor_state` TINYINT(1) NOT NULL DEFAULT 0,
    `last_ping` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `ip_address` VARCHAR(45) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 4. Users Table (Admin & Staff Authentication)
CREATE TABLE IF NOT EXISTS `users` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(100) NOT NULL DEFAULT '',         -- Worker / User Full Name
    `username` VARCHAR(50) NOT NULL UNIQUE,          -- Login username
    `password` VARCHAR(255) NOT NULL,                -- Plaintext or BCrypt hash (auto-hashed)
    `role` VARCHAR(20) NOT NULL DEFAULT 'staff',     -- 'admin' or 'staff'
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------
-- Initial Data Seeding
-- --------------------------------------------------------

-- Initialize default admin user (Username: admin | Password: admin123)
INSERT INTO `users` (`id`, `name`, `username`, `password`, `role`)
VALUES (1, 'System Administrator', 'admin', 'admin123', 'admin')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `role` = VALUES(`role`);

-- Initialize default device state record
INSERT INTO `device_state` (`id`, `motor_state`, `last_ping`, `ip_address`)
VALUES (1, 0, NOW(), '127.0.0.1')
ON DUPLICATE KEY UPDATE `id` = `id`;
