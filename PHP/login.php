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
    $cols = $pdo->query("SHOW COLUMNS FROM `users`")->fetchAll(PDO::FETCH_COLUMN);
    $idCol = in_array('id', $cols, true) ? '`id`' : (in_array('userid', $cols, true) ? '`userid`' : '`id`');

    // Query user case-insensitively
    $stmt = $pdo->prepare("SELECT * FROM `users` WHERE LOWER(`username`) = LOWER(:username) LIMIT 1");
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
                $upStmt = $pdo->prepare("UPDATE `users` SET `password` = :pw WHERE $idCol = :id");
                $upStmt->execute([':pw' => $newHash, ':id' => $userId]);
            } catch (Exception $rehEx) {}
        }

        // Record login audit log
        try {
            $logCols = $pdo->query("SHOW COLUMNS FROM `logs`")->fetchAll(PDO::FETCH_COLUMN);
            $logFields = ['`event`', '`time`'];
            $logPlaceholders = [':event', ':time'];
            $logParams = [
                ':event' => "User Login ({$displayName} - @{$user['username']})",
                ':time'  => date('D h:i A'),
            ];

            if (in_array('username', $logCols, true)) {
                $logFields[] = '`username`';
                $logPlaceholders[] = ':username';
                $logParams[':username'] = $user['username'];
            }
            if (in_array('user_name', $logCols, true)) {
                $logFields[] = '`user_name`';
                $logPlaceholders[] = ':user_name';
                $logParams[':user_name'] = $displayName;
            }

            $lFieldsStr = implode(', ', $logFields);
            $lPlaceStr = implode(', ', $logPlaceholders);

            $logStmt = $pdo->prepare("INSERT INTO `logs` ($lFieldsStr) VALUES ($lPlaceStr)");
            $logStmt->execute($logParams);
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
