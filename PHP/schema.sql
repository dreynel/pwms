-- ========================================================
-- Conveyor Control System - Hostinger MySQL Database Schema
-- ========================================================

-- 1. Schedules Table (Recurring & Calendar Date Plans)
CREATE TABLE IF NOT EXISTS `schedules` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `type` VARCHAR(20) NOT NULL DEFAULT 'recurring', -- 'recurring' or 'calendar'
    `time` VARCHAR(20) NOT NULL,                     -- e.g. '10:30 AM'
    `date` VARCHAR(20) DEFAULT NULL,                 -- e.g. '2026-08-30' (for calendar type)
    `days` TEXT DEFAULT NULL,                        -- JSON string: '["Mon","Wed"]' (for recurring)
    `duration` INT NOT NULL DEFAULT 1,               -- Duration in minutes
    `enabled` TINYINT(1) NOT NULL DEFAULT 1,         -- 1 = enabled, 0 = disabled
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2. Hardware Event Logs Table
CREATE TABLE IF NOT EXISTS `logs` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `event` VARCHAR(255) NOT NULL,
    `time` VARCHAR(60) NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 3. Live Device State Table (Motor State & Heartbeat)
CREATE TABLE IF NOT EXISTS `device_state` (
    `id` INT PRIMARY KEY DEFAULT 1,
    `motor_state` TINYINT(1) NOT NULL DEFAULT 0,
    `last_ping` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `ip_address` VARCHAR(45) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 4. Users Table (Mobile & Web Authentication)
CREATE TABLE IF NOT EXISTS `users` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `username` VARCHAR(50) NOT NULL UNIQUE,
    `password` VARCHAR(255) NOT NULL,
    `role` VARCHAR(20) NOT NULL DEFAULT 'admin',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Initialize default admin user (admin / admin123)
INSERT INTO `users` (`id`, `username`, `password`, `role`)
VALUES (1, 'admin', 'admin123', 'admin')
ON DUPLICATE KEY UPDATE `id` = `id`;


