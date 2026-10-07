<?php
/**
 * POST /login.php - Authenticate user against users table
 * Compatible with PostgreSQL and MySQL
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
    // Standard ANSI SQL case-insensitive search
    $stmt = $pdo->prepare("SELECT * FROM users WHERE LOWER(username) = LOWER(:username) LIMIT 1");
    $stmt->execute([':username' => $username]);
    $user = $stmt->fetch();

    if (!$user) {
        sendJson(['error' => 'Invalid username or password.'], 401);
    }

    $storedPassword = $user['password'] ?? '';
    $userId = isset($user['id']) ? (int)$user['id'] : (isset($user['userid']) ? (int)$user['userid'] : 1);
    $rawRole = strtolower(trim($user['role'] ?? 'staff'));
    $role = ($rawRole === 'admin') ? 'admin' : 'staff';
    $displayName = !empty($user['name']) ? $user['name'] : $user['username'];

    // Multi-scheme password verification
    $isValid = false;
    $shouldRehash = false;

    if (password_verify($password, $storedPassword)) {
        $isValid = true;
    } elseif ($password === $storedPassword || trim($password) === trim($storedPassword)) {
        $isValid = true;
        $shouldRehash = true;
    } elseif (md5($password) === $storedPassword || sha1($password) === $storedPassword) {
        $isValid = true;
        $shouldRehash = true;
    }

    if ($isValid) {
        // Upgrade password to secure BCrypt hash in background if needed
        if ($shouldRehash) {
            try {
                $newHash = password_hash($password, PASSWORD_DEFAULT);
                $upStmt = $pdo->prepare("UPDATE users SET password = :pw WHERE id = :id");
                $upStmt->execute([':pw' => $newHash, ':id' => $userId]);
            } catch (Exception $rehEx) {}
        }

        // Record login audit log
        try {
            $logStmt = $pdo->prepare("
                INSERT INTO logs (username, user_name, event, time) 
                VALUES (:username, :user_name, :event, :time)
            ");
            $logStmt->execute([
                ':username'  => $user['username'],
                ':user_name' => $displayName,
                ':event'     => "User Login ({$displayName} - @{$user['username']})",
                ':time'      => date('M d, Y h:i A')
            ]);
        } catch (Exception $logEx) {}

        sendJson([
            'status'  => 'ok',
            'message' => 'Login successful',
            'user'    => [
                'id'       => $userId,
                'name'     => $displayName,
                'username' => $user['username'],
                'role'     => $role,
            ]
        ]);
    } else {
        sendJson(['error' => 'Invalid username or password.'], 401);
    }
} catch (Exception $e) {
    sendJson(['error' => 'Login failed: ' . $e->getMessage()], 500);
}
