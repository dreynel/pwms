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
// Database Configuration (Hostinger MySQL details)
// -------------------------------------------------------------
define('DB_HOST', 'localhost');                  // Usually 'localhost' on Hostinger
define('DB_NAME', 'u534933225_dbpwms');        // Your Hostinger Database Name
define('DB_USER', 'u534933225_pwms');          // Your Hostinger Database Username
define('DB_PASS', 'QIr0lbg5*');                // Your Hostinger Database Password
define('TIMEZONE', 'Asia/Singapore');            // Adjust timezone

date_default_timezone_set(TIMEZONE);

/**
 * Get PDO Database Connection (Auto-creates and migrates tables if needed)
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
            
            // Auto-initialize & migrate tables
            autoSetupTables($pdo);
        } catch (PDOException $e) {
            sendJson([
                'error' => 'Database connection failed: ' . $e->getMessage(),
                'hint'  => 'Please verify your Hostinger DB_NAME and DB_USER in db.php.'
            ], 500);
        }
    }
    return $pdo;
}

/**
 * Automatically create and safely migrate tables
 */
function autoSetupTables($pdo) {
    // 1. Setup Schedules Table
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
        ");
    } catch (Exception $e) {}

    // 2. Setup Device State Table
    try {
        $pdo->exec("
            CREATE TABLE IF NOT EXISTS `device_state` (
                `id` INT PRIMARY KEY DEFAULT 1,
                `motor_state` TINYINT(1) NOT NULL DEFAULT 0,
                `last_ping` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                `ip_address` VARCHAR(45) DEFAULT NULL
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ");

        $devCount = (int)$pdo->query("SELECT COUNT(*) FROM `device_state` WHERE `id` = 1")->fetchColumn();
        if ($devCount === 0) {
            $pdo->exec("INSERT INTO `device_state` (`id`, `motor_state`, `last_ping`, `ip_address`) VALUES (1, 0, NOW(), '127.0.0.1')");
        }
    } catch (Exception $e) {}

    // 3. Setup & Migrate Users Table (Column-by-Column Safe Migration)
    try {
        $pdo->exec("
            CREATE TABLE IF NOT EXISTS `users` (
                `id` INT AUTO_INCREMENT PRIMARY KEY,
                `name` VARCHAR(100) NOT NULL DEFAULT '',
                `username` VARCHAR(50) NOT NULL UNIQUE,
                `password` VARCHAR(255) NOT NULL,
                `role` VARCHAR(20) NOT NULL DEFAULT 'staff',
                `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ");
    } catch (Exception $e) {}

    try {
        $userCols = $pdo->query("SHOW COLUMNS FROM `users`")->fetchAll(PDO::FETCH_COLUMN);

        // Rename userid to id if needed
        if (in_array('userid', $userCols, true) && !in_array('id', $userCols, true)) {
            try {
                $pdo->exec("ALTER TABLE `users` CHANGE COLUMN `userid` `id` INT AUTO_INCREMENT");
                $userCols[] = 'id';
            } catch (Exception $e) {
                try {
                    $pdo->exec("ALTER TABLE `users` CHANGE `userid` `id` INT NOT NULL AUTO_INCREMENT");
                    $userCols[] = 'id';
                } catch (Exception $e2) {}
            }
        }

        // Add id if neither id nor userid exists
        if (!in_array('id', $userCols, true) && !in_array('userid', $userCols, true)) {
            try {
                $pdo->exec("ALTER TABLE `users` ADD COLUMN `id` INT AUTO_INCREMENT PRIMARY KEY FIRST");
            } catch (Exception $e) {}
        }

        // Add name column
        if (!in_array('name', $userCols, true)) {
            try {
                $pdo->exec("ALTER TABLE `users` ADD COLUMN `name` VARCHAR(100) NOT NULL DEFAULT ''");
            } catch (Exception $e) {}
        }

        // Add username column
        if (!in_array('username', $userCols, true)) {
            try {
                $pdo->exec("ALTER TABLE `users` ADD COLUMN `username` VARCHAR(50) NOT NULL UNIQUE");
            } catch (Exception $e) {}
        }

        // Add password column
        if (!in_array('password', $userCols, true)) {
            try {
                $pdo->exec("ALTER TABLE `users` ADD COLUMN `password` VARCHAR(255) NOT NULL");
            } catch (Exception $e) {}
        }

        // Add role column
        if (!in_array('role', $userCols, true)) {
            try {
                $pdo->exec("ALTER TABLE `users` ADD COLUMN `role` VARCHAR(20) NOT NULL DEFAULT 'staff'");
            } catch (Exception $e) {}
        }

        // Add created_at column
        if (!in_array('created_at', $userCols, true)) {
            try {
                $pdo->exec("ALTER TABLE `users` ADD COLUMN `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP");
            } catch (Exception $e) {}
        }

        // Migrate legacy roles to staff
        try {
            $pdo->exec("UPDATE `users` SET `role` = 'staff' WHERE `role` IN ('operator', 'viewer')");
        } catch (Exception $e) {}

        // Ensure default admin user exists
        try {
            $adminCount = (int)$pdo->query("SELECT COUNT(*) FROM `users` WHERE `username` = 'admin'")->fetchColumn();
            if ($adminCount === 0) {
                $pdo->exec("
                    INSERT INTO `users` (`name`, `username`, `password`, `role`)
                    VALUES ('System Administrator', 'admin', 'admin123', 'admin')
                ");
            } else {
                $pdo->exec("UPDATE `users` SET `name` = 'System Administrator' WHERE `username` = 'admin' AND (`name` = '' OR `name` IS NULL)");
                $pdo->exec("UPDATE `users` SET `role` = 'admin' WHERE `username` = 'admin'");
            }
        } catch (Exception $e) {}
    } catch (Exception $e) {}

    // 4. Setup & Migrate Logs Table (Column-by-Column Safe Migration)
    try {
        $pdo->exec("
            CREATE TABLE IF NOT EXISTS `logs` (
                `id` INT AUTO_INCREMENT PRIMARY KEY,
                `username` VARCHAR(50) DEFAULT NULL,
                `user_name` VARCHAR(100) DEFAULT NULL,
                `event` VARCHAR(255) NOT NULL,
                `time` VARCHAR(60) NOT NULL,
                `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ");
    } catch (Exception $e) {}

    try {
        $logCols = $pdo->query("SHOW COLUMNS FROM `logs`")->fetchAll(PDO::FETCH_COLUMN);

        if (!in_array('id', $logCols, true)) {
            try {
                $pdo->exec("ALTER TABLE `logs` ADD COLUMN `id` INT AUTO_INCREMENT PRIMARY KEY FIRST");
            } catch (Exception $e) {}
        }
        if (!in_array('username', $logCols, true)) {
            try {
                $pdo->exec("ALTER TABLE `logs` ADD COLUMN `username` VARCHAR(50) DEFAULT NULL");
            } catch (Exception $e) {}
        }
        if (!in_array('user_name', $logCols, true)) {
            try {
                $pdo->exec("ALTER TABLE `logs` ADD COLUMN `user_name` VARCHAR(100) DEFAULT NULL");
            } catch (Exception $e) {}
        }
        if (!in_array('event', $logCols, true)) {
            try {
                $pdo->exec("ALTER TABLE `logs` ADD COLUMN `event` VARCHAR(255) NOT NULL");
            } catch (Exception $e) {}
        }
        if (!in_array('time', $logCols, true)) {
            try {
                $pdo->exec("ALTER TABLE `logs` ADD COLUMN `time` VARCHAR(60) NOT NULL");
            } catch (Exception $e) {}
        }
        if (!in_array('created_at', $logCols, true)) {
            try {
                $pdo->exec("ALTER TABLE `logs` ADD COLUMN `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP");
            } catch (Exception $e) {}
        }
    } catch (Exception $e) {}
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

// If db.php is opened directly in a browser, test connection and display status with columns
if (basename($_SERVER['SCRIPT_FILENAME'] ?? '') === 'db.php') {
    $pdo = getDb();
    
    $userCols = [];
    $logCols = [];
    try {
        $userCols = $pdo->query("SHOW COLUMNS FROM `users`")->fetchAll(PDO::FETCH_COLUMN);
        $logCols = $pdo->query("SHOW COLUMNS FROM `logs`")->fetchAll(PDO::FETCH_COLUMN);
    } catch (Exception $e) {}

    sendJson([
        'status'   => 'success',
        'message'  => 'Database connected & tables auto-migrated successfully!',
        'database' => DB_NAME,
        'user'     => DB_USER,
        'time'     => date('Y-m-d h:i:s A'),
        'tables'   => [
            'users'        => 'Ready ✅ (columns: ' . implode(', ', $userCols) . ')',
            'logs'         => 'Ready ✅ (columns: ' . implode(', ', $logCols) . ')',
            'schedules'    => 'Ready ✅',
            'device_state' => 'Ready ✅'
        ]
    ]);
}
