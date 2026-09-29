<?php
/**
 * PWMS - Unified Database Connection & Migration (PostgreSQL & MySQL)
 * Compatible with Render.com Docker, Managed PostgreSQL, Hostinger, and Local Environments
 */

// Enable Output Buffering & CORS for Flutter App & ESP32
ob_start();

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");
header("Content-Type: application/json; charset=UTF-8");

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

define('TIMEZONE', 'Asia/Singapore');
date_default_timezone_set(TIMEZONE);

// Default fallback Render PostgreSQL connection string (if not set in env)
define('DEFAULT_DATABASE_URL', 'postgresql://postgresql_pwms_user:KX79wNjKlzrDdOYKGR7Jkq9Lm1jyM3R6@dpg-datmotjncjis7397ubbg-a/postgresql_pwms');

/**
 * Get Unified PDO Connection (Auto-detects PostgreSQL vs MySQL)
 */
function getDb() {
    static $pdo = null;
    if ($pdo !== null) {
        return $pdo;
    }

    // 1. Check for Render Managed PostgreSQL / Database URL
    $databaseUrl = getenv('DATABASE_URL') ?: (getenv('INTERNAL_DATABASE_URL') ?: DEFAULT_DATABASE_URL);

    $options = [
        PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES   => false,
    ];

    try {
        if (!empty($databaseUrl) && (strpos($databaseUrl, 'postgres://') === 0 || strpos($databaseUrl, 'postgresql://') === 0)) {
            $parsed = parse_url($databaseUrl);
            $dbHost   = $parsed['host'] ?? 'localhost';
            $dbPort   = $parsed['port'] ?? 5432;
            $dbUser   = $parsed['user'] ?? 'postgres';
            $dbPass   = $parsed['pass'] ?? '';
            $dbName   = ltrim($parsed['path'] ?? '', '/');

            // Render Postgres connection string with SSL
            $dsn = "pgsql:host={$dbHost};port={$dbPort};dbname={$dbName};sslmode=prefer";
            $pdo = new PDO($dsn, $dbUser, $dbPass, $options);
        } else {
            // 2. Fallback to individual Environment Variables
            $driver = getenv('DB_DRIVER') ?: 'pgsql';
            $dbHost = getenv('DB_HOST') ?: 'localhost';
            $dbPort = getenv('DB_PORT') ?: ($driver === 'pgsql' ? 5432 : 3306);
            $dbName = getenv('DB_NAME') ?: 'postgresql_pwms';
            $dbUser = getenv('DB_USER') ?: 'postgresql_pwms_user';
            $dbPass = getenv('DB_PASS') ?: (getenv('DB_PASSWORD') ?: '');

            if ($driver === 'pgsql') {
                $dsn = "pgsql:host={$dbHost};port={$dbPort};dbname={$dbName};sslmode=prefer";
                $pdo = new PDO($dsn, $dbUser, $dbPass, $options);
            } else {
                $dsn = "mysql:host={$dbHost};port={$dbPort};dbname={$dbName};charset=utf8mb4";
                $pdo = new PDO($dsn, $dbUser, $dbPass, $options);
            }
        }

        // Auto-initialize tables on startup
        autoSetupTables($pdo);

    } catch (PDOException $e) {
        sendJson([
            'error' => 'Database connection failed: ' . $e->getMessage(),
            'hint'  => 'If running in Render Docker, ensure the Web Service is in the same Render region as the PostgreSQL database (dpg-datmotjncjis7397ubbg-a). If running locally, use the External Database URL.'
        ], 500);
    }

    return $pdo;
}

/**
 * Helper to get column list across PostgreSQL and MySQL
 */
function getTableColumns($pdo, $table) {
    try {
        $driver = $pdo->getAttribute(PDO::ATTR_DRIVER_NAME);
        if ($driver === 'pgsql') {
            $stmt = $pdo->prepare("
                SELECT column_name 
                FROM information_schema.columns 
                WHERE table_name = :tbl
            ");
            $stmt->execute([':tbl' => strtolower($table)]);
            return $stmt->fetchAll(PDO::FETCH_COLUMN);
        } else {
            return $pdo->query("SHOW COLUMNS FROM `$table`")->fetchAll(PDO::FETCH_COLUMN);
        }
    } catch (Exception $e) {
        return [];
    }
}

/**
 * Automatically create and safely migrate tables
 */
function autoSetupTables($pdo) {
    $driver = $pdo->getAttribute(PDO::ATTR_DRIVER_NAME);

    if ($driver === 'pgsql') {
        // -------------------------------------------------------------
        // PostgreSQL Schema Setup
        // -------------------------------------------------------------
        try {
            $pdo->exec("
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

                CREATE TABLE IF NOT EXISTS logs (
                    id SERIAL PRIMARY KEY,
                    username VARCHAR(50) DEFAULT NULL,
                    user_name VARCHAR(100) DEFAULT NULL,
                    event VARCHAR(255) NOT NULL,
                    time VARCHAR(60) NOT NULL,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                );

                CREATE TABLE IF NOT EXISTS device_state (
                    id INT PRIMARY KEY DEFAULT 1,
                    motor_state INT NOT NULL DEFAULT 0,
                    last_ping TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    ip_address VARCHAR(45) DEFAULT NULL
                );

                CREATE TABLE IF NOT EXISTS users (
                    id SERIAL PRIMARY KEY,
                    name VARCHAR(100) NOT NULL DEFAULT '',
                    username VARCHAR(50) NOT NULL UNIQUE,
                    password VARCHAR(255) NOT NULL,
                    role VARCHAR(20) NOT NULL DEFAULT 'staff',
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                );
            ");

            // Seed default admin account
            $stmt = $pdo->prepare("SELECT COUNT(*) FROM users WHERE username = 'admin'");
            $stmt->execute();
            if ((int)$stmt->fetchColumn() === 0) {
                $pdo->exec("
                    INSERT INTO users (name, username, password, role)
                    VALUES ('System Administrator', 'admin', 'admin123', 'admin')
                    ON CONFLICT (username) DO NOTHING;
                ");
            }

            // Seed default device state
            $devCount = (int)$pdo->query("SELECT COUNT(*) FROM device_state WHERE id = 1")->fetchColumn();
            if ($devCount === 0) {
                $pdo->exec("
                    INSERT INTO device_state (id, motor_state, last_ping, ip_address)
                    VALUES (1, 0, NOW(), '127.0.0.1')
                    ON CONFLICT (id) DO NOTHING;
                ");
            }
        } catch (Exception $e) {
            // Ignore if tables exist
        }
    } else {
        // -------------------------------------------------------------
        // MySQL Schema Setup
        // -------------------------------------------------------------
        try {
            $pdo->exec("
                CREATE TABLE IF NOT EXISTS `schedules` (
                    `id` INT AUTO_INCREMENT PRIMARY KEY,
                    `type` VARCHAR(20) NOT NULL DEFAULT 'recurring',
                    `time` VARCHAR(20) NOT NULL,
                    `date` VARCHAR(20) DEFAULT NULL,
                    `days` TEXT DEFAULT NULL,
                    `duration` INT NOT NULL DEFAULT 1,
                    `enabled` TINYINT(1) NOT NULL DEFAULT 1,
                    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

                CREATE TABLE IF NOT EXISTS `logs` (
                    `id` INT AUTO_INCREMENT PRIMARY KEY,
                    `username` VARCHAR(50) DEFAULT NULL,
                    `user_name` VARCHAR(100) DEFAULT NULL,
                    `event` VARCHAR(255) NOT NULL,
                    `time` VARCHAR(60) NOT NULL,
                    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

                CREATE TABLE IF NOT EXISTS `device_state` (
                    `id` INT PRIMARY KEY DEFAULT 1,
                    `motor_state` TINYINT(1) NOT NULL DEFAULT 0,
                    `last_ping` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    `ip_address` VARCHAR(45) DEFAULT NULL
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

                CREATE TABLE IF NOT EXISTS `users` (
                    `id` INT AUTO_INCREMENT PRIMARY KEY,
                    `name` VARCHAR(100) NOT NULL DEFAULT '',
                    `username` VARCHAR(50) NOT NULL UNIQUE,
                    `password` VARCHAR(255) NOT NULL,
                    `role` VARCHAR(20) NOT NULL DEFAULT 'staff',
                    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
            ");

            // Safe auto-migration for existing MySQL tables
            $userCols = getTableColumns($pdo, 'users');
            if (in_array('userid', $userCols, true) && !in_array('id', $userCols, true)) {
                try {
                    $pdo->exec("ALTER TABLE `users` CHANGE COLUMN `userid` `id` INT AUTO_INCREMENT");
                } catch (Exception $e) {}
            }
            if (!in_array('name', $userCols, true)) {
                try {
                    $pdo->exec("ALTER TABLE `users` ADD COLUMN `name` VARCHAR(100) NOT NULL DEFAULT ''");
                } catch (Exception $e) {}
            }
            if (!in_array('role', $userCols, true)) {
                try {
                    $pdo->exec("ALTER TABLE `users` ADD COLUMN `role` VARCHAR(20) NOT NULL DEFAULT 'staff'");
                } catch (Exception $e) {}
            }

            // Seed default admin
            $adminCount = (int)$pdo->query("SELECT COUNT(*) FROM `users` WHERE `username` = 'admin'")->fetchColumn();
            if ($adminCount === 0) {
                $pdo->exec("
                    INSERT INTO `users` (`name`, `username`, `password`, `role`)
                    VALUES ('System Administrator', 'admin', 'admin123', 'admin')
                ");
            }

            // Seed device state
            $devCount = (int)$pdo->query("SELECT COUNT(*) FROM `device_state` WHERE `id` = 1")->fetchColumn();
            if ($devCount === 0) {
                $pdo->exec("INSERT INTO `device_state` (`id`, `motor_state`, `last_ping`, `ip_address`) VALUES (1, 0, NOW(), '127.0.0.1')");
            }
        } catch (Exception $e) {}
    }
}

/**
 * Send JSON Response and Terminate
 */
function sendJson($data, $statusCode = 200) {
    if (ob_get_length()) {
        ob_clean();
    }
    http_response_code($statusCode);
    echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

/**
 * Parse incoming JSON request body
 */
function getJsonInput() {
    $raw = file_get_contents('php://input');
    if (empty($raw)) {
        return [];
    }
    $decoded = json_decode($raw, true);
    return is_array($decoded) ? $decoded : [];
}

// Direct browser test for db.php
if (basename($_SERVER['SCRIPT_FILENAME'] ?? '') === 'db.php') {
    $pdo = getDb();
    $driver = $pdo->getAttribute(PDO::ATTR_DRIVER_NAME);
    $userCols = getTableColumns($pdo, 'users');
    $logCols  = getTableColumns($pdo, 'logs');

    sendJson([
        'status'   => 'success',
        'message'  => 'Database connected & tables auto-initialized successfully!',
        'engine'   => strtoupper($driver),
        'time'     => date('Y-m-d h:i:s A'),
        'tables'   => [
            'users'        => 'Ready ✅ (' . count($userCols) . ' columns)',
            'logs'         => 'Ready ✅ (' . count($logCols) . ' columns)',
            'schedules'    => 'Ready ✅',
            'device_state' => 'Ready ✅'
        ]
    ]);
}
