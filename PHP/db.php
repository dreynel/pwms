<?php
/**
 * Conveyor Control - Hostinger MySQL Database Connection & Helpers
 */

// Enable CORS for Flutter & Web Clients
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");
header("Content-Type: application/json; charset=UTF-8");

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// -------------------------------------------------------------
// Database Configuration (Update with your Hostinger MySQL details)
// -------------------------------------------------------------
define('DB_HOST', 'localhost');                  // Usually 'localhost' on Hostinger
define('DB_NAME', 'u534933225_dbpwms');        // Your Hostinger Database Name
define('DB_USER', 'u534933225_pwms');          // Your Hostinger Database Username
define('DB_PASS', 'QIr0lbg5*');                // Your Hostinger Database Password
define('TIMEZONE', 'Asia/Singapore');            // Adjust timezone (e.g. Asia/Singapore, Asia/Manila, UTC)

date_default_timezone_set(TIMEZONE);

/**
 * Get PDO Database Connection (Auto-creates tables if they do not exist)
 */
function getDb() {
    static $pdo = null;
    if ($pdo === null) {
        try {
            $dsn = "mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4";
            $options = [
                PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES   => false,
            ];
            $pdo = new PDO($dsn, DB_USER, DB_PASS, $options);
            
            // Auto-initialize tables if not yet created
            autoSetupTables($pdo);
        } catch (PDOException $e) {
            sendJson([
                'error' => 'Database connection failed: ' . $e->getMessage(),
                'hint'  => 'Please verify your Hostinger DB_NAME and DB_USER in db.php. In Hostinger hPanel, they usually have an account prefix (e.g. u123456789_dbwpms).'
            ], 500);
        }
    }
    return $pdo;
}

/**
 * Automatically create tables on first run
 */
function autoSetupTables($pdo) {
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
                `username` VARCHAR(50) NOT NULL UNIQUE,
                `password` VARCHAR(255) NOT NULL,
                `role` VARCHAR(20) NOT NULL DEFAULT 'admin',
                `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

            INSERT INTO `users` (`id`, `username`, `password`, `role`)
            VALUES (1, 'admin', 'admin123', 'admin')
            ON DUPLICATE KEY UPDATE `id` = `id`;

            INSERT INTO `device_state` (`id`, `motor_state`, `last_ping`, `ip_address`)
            VALUES (1, 0, NOW(), '127.0.0.1')
            ON DUPLICATE KEY UPDATE `id` = `id`;
        ");
    } catch (Exception $e) {
        // Continue if tables already exist
    }
}

/**
 * Send JSON Response and Terminate
 */
function sendJson($data, $statusCode = 200) {
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

// If db.php is opened directly in a browser, test connection and display status
if (basename($_SERVER['SCRIPT_FILENAME'] ?? '') === 'db.php') {
    $pdo = getDb();
    sendJson([
        'status'   => 'success',
        'message'  => 'Database connected & tables initialized successfully!',
        'database' => DB_NAME,
        'user'     => DB_USER,
        'time'     => date('Y-m-d h:i:s A'),
        'tables'   => ['schedules' => 'Ready ✅', 'logs' => 'Ready ✅', 'device_state' => 'Ready ✅']
    ]);
}

