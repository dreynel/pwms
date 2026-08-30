<?php
/**
 * POST /login.php - Authenticate user against MySQL users table
 */

require_once __DIR__ . '/db.php';

$pdo = getDb();
$input = getJsonInput();

$username = isset($input['username']) ? trim($input['username']) : '';
$password = isset($input['password']) ? trim($input['password']) : '';

if (empty($username) || empty($password)) {
    sendJson(['error' => 'Username and password are required.'], 400);
}

try {
    $stmt = $pdo->prepare("SELECT * FROM users WHERE username = :username LIMIT 1");
    $stmt->execute([':username' => $username]);
    $user = $stmt->fetch();

    if (!$user) {
        sendJson(['error' => 'Invalid username or password.'], 401);
    }

    // Verify password (supports direct match or password_hash)
    $storedPassword = $user['password'];
    $isValid = ($password === $storedPassword) || (password_verify($password, $storedPassword));

    if ($isValid) {
        // Record login audit in logs
        try {
            $logStmt = $pdo->prepare("INSERT INTO logs (event, time) VALUES (:event, :time)");
            $logStmt->execute([
                ':event' => 'User Login (' . $user['username'] . ')',
                ':time'  => date('D h:i A')
            ]);
        } catch (Exception $logEx) {
            // Ignore log errors during login
        }

        sendJson([
            'status' => 'ok',
            'message' => 'Login successful',
            'user' => [
                'id'       => (int)$user['id'],
                'username' => $user['username'],
                'role'     => $user['role'] ?? 'admin'
            ]
        ]);
    } else {
        sendJson(['error' => 'Invalid username or password.'], 401);
    }
} catch (Exception $e) {
    sendJson(['error' => 'Login failed: ' . $e->getMessage()], 500);
}
