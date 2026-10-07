<?php
/**
 * /users.php - User Management API (CRUD for Admin & Staff only)
 * Compatible with PostgreSQL & MySQL
 */

require_once __DIR__ . '/db.php';

$pdo = getDb();
$method = $_SERVER['REQUEST_METHOD'];

// Handle GET: List all users
if ($method === 'GET') {
    try {
        $stmt = $pdo->query("SELECT * FROM users ORDER BY id ASC");
        $rows = $stmt->fetchAll();

        $users = [];
        foreach ($rows as $row) {
            $rawRole = strtolower(trim($row['role'] ?? 'staff'));
            $role = ($rawRole === 'admin') ? 'admin' : 'staff';
            $username = $row['username'] ?? '';
            $name = !empty($row['name']) ? $row['name'] : $username;
            $id = isset($row['id']) ? (int)$row['id'] : (isset($row['userid']) ? (int)$row['userid'] : 1);

            $users[] = [
                'id'         => $id,
                'name'       => $name,
                'username'   => $username,
                'role'       => $role,
                'created_at' => $row['created_at'] ?? null,
            ];
        }

        sendJson($users);
    } catch (Exception $e) {
        sendJson(['error' => 'Failed to fetch users: ' . $e->getMessage()], 500);
    }
}

// Handle POST: Create a new user (Admin or Staff)
if ($method === 'POST') {
    $input = getJsonInput();

    $name     = isset($input['name']) ? trim($input['name']) : '';
    $username = isset($input['username']) ? trim($input['username']) : '';
    $password = isset($input['password']) ? trim($input['password']) : '';
    $rawRole  = isset($input['role']) ? strtolower(trim($input['role'])) : 'staff';
    $role     = ($rawRole === 'admin') ? 'admin' : 'staff';

    // Validate inputs
    if (empty($username) || empty($password)) {
        sendJson(['error' => 'Username and password are required.'], 400);
    }

    if (empty($name)) {
        $name = $username;
    }

    if (strlen($username) < 3) {
        sendJson(['error' => 'Username must be at least 3 characters.'], 400);
    }

    if (strlen($password) < 4) {
        sendJson(['error' => 'Password must be at least 4 characters.'], 400);
    }

    try {
        // Check if username already exists
        $checkStmt = $pdo->prepare("SELECT * FROM users WHERE LOWER(username) = LOWER(:username) LIMIT 1");
        $checkStmt->execute([':username' => $username]);
        if ($checkStmt->fetch()) {
            sendJson(['error' => "Username '{$username}' is already taken."], 409);
        }

        // Hash password securely
        $hashedPassword = password_hash($password, PASSWORD_DEFAULT);

        // Insert new user
        $insertStmt = $pdo->prepare("
            INSERT INTO users (name, username, password, role)
            VALUES (:name, :username, :password, :role)
        ");
        $insertStmt->execute([
            ':name'     => $name,
            ':username' => $username,
            ':password' => $hashedPassword,
            ':role'     => $role,
        ]);

        $newId = (int)$pdo->lastInsertId();

        // Audit log in logs table
        try {
            $logStmt = $pdo->prepare("
                INSERT INTO logs (username, user_name, event, time)
                VALUES (:username, :user_name, :event, :time)
            ");
            $logStmt->execute([
                ':username'  => $username,
                ':user_name' => $name,
                ':event'     => "Added user '{$name}' (@{$username}, {$role})",
                ':time'      => date('M d, Y h:i A'),
            ]);
        } catch (Exception $ex) {
            // Ignore log failure
        }

        sendJson([
            'status'  => 'created',
            'message' => 'User created successfully.',
            'user'    => [
                'id'         => $newId,
                'name'       => $name,
                'username'   => $username,
                'role'       => $role,
                'created_at' => date('Y-m-d H:i:s'),
            ]
        ], 201);
    } catch (Exception $e) {
        sendJson(['error' => 'Failed to create user: ' . $e->getMessage()], 500);
    }
}

// Handle PUT: Update an existing user account
if ($method === 'PUT') {
    $input = getJsonInput();

    $id       = isset($input['id']) ? (int)$input['id'] : null;
    $name     = isset($input['name']) ? trim($input['name']) : null;
    $username = isset($input['username']) ? trim($input['username']) : null;
    $rawRole  = isset($input['role']) ? strtolower(trim($input['role'])) : null;
    $password = isset($input['password']) ? trim($input['password']) : null;

    if (!$id) {
        sendJson(['error' => 'Missing user ID to update.'], 400);
    }

    try {
        // Fetch current user
        $fetchStmt = $pdo->prepare("SELECT * FROM users WHERE id = :id LIMIT 1");
        $fetchStmt->execute([':id' => $id]);
        $currentUser = $fetchStmt->fetch();

        if (!$currentUser) {
            sendJson(['error' => 'User not found.'], 404);
        }

        // Validate name if provided
        if ($name === null || empty($name)) {
            $name = !empty($currentUser['name']) ? $currentUser['name'] : $currentUser['username'];
        }

        // Validate username if provided
        if ($username !== null) {
            if (strlen($username) < 3) {
                sendJson(['error' => 'Username must be at least 3 characters.'], 400);
            }

            // If username changed, check uniqueness
            if ($username !== $currentUser['username']) {
                $checkStmt = $pdo->prepare("SELECT * FROM users WHERE LOWER(username) = LOWER(:username) AND id != :id LIMIT 1");
                $checkStmt->execute([':username' => $username, ':id' => $id]);
                if ($checkStmt->fetch()) {
                    sendJson(['error' => "Username '{$username}' is already taken."], 409);
                }
            }
        } else {
            $username = $currentUser['username'];
        }

        // Validate role if provided
        if ($rawRole !== null) {
            $role = ($rawRole === 'admin') ? 'admin' : 'staff';

            // Prevent demoting the only admin account
            if (($currentUser['role'] ?? '') === 'admin' && $role !== 'admin') {
                $adminCountStmt = $pdo->query("SELECT COUNT(*) as count FROM users WHERE role = 'admin'");
                $adminCount = (int)$adminCountStmt->fetch()['count'];
                if ($adminCount <= 1) {
                    sendJson(['error' => 'Cannot demote the only remaining Administrator.'], 400);
                }
            }
        } else {
            $role = $currentUser['role'] ?? 'staff';
        }

        // Build update query
        if (!empty($password)) {
            if (strlen($password) < 4) {
                sendJson(['error' => 'Password must be at least 4 characters.'], 400);
            }
            $updateStmt = $pdo->prepare("
                UPDATE users 
                SET name = :name, username = :username, role = :role, password = :password 
                WHERE id = :id
            ");
            $updateStmt->execute([
                ':name'     => $name,
                ':username' => $username,
                ':role'     => $role,
                ':password' => password_hash($password, PASSWORD_DEFAULT),
                ':id'       => $id,
            ]);
        } else {
            $updateStmt = $pdo->prepare("
                UPDATE users 
                SET name = :name, username = :username, role = :role 
                WHERE id = :id
            ");
            $updateStmt->execute([
                ':name'     => $name,
                ':username' => $username,
                ':role'     => $role,
                ':id'       => $id,
            ]);
        }

        // Audit log in logs table
        try {
            $logStmt = $pdo->prepare("
                INSERT INTO logs (username, user_name, event, time) 
                VALUES (:username, :user_name, :event, :time)
            ");
            $logStmt->execute([
                ':username'  => $username,
                ':user_name' => $name,
                ':event'     => "Updated user '{$name}' (@{$username}, role: {$role}" . (!empty($password) ? ", pwd changed" : "") . ")",
                ':time'      => date('M d, Y h:i A'),
            ]);
        } catch (Exception $ex) {
            // Ignore log failure
        }

        sendJson([
            'status'  => 'updated',
            'message' => 'User updated successfully.',
            'user'    => [
                'id'       => $id,
                'name'     => $name,
                'username' => $username,
                'role'     => $role,
            ]
        ]);
    } catch (Exception $e) {
        sendJson(['error' => 'Failed to update user: ' . $e->getMessage()], 500);
    }
}

// Handle DELETE: Delete a user by ID
if ($method === 'DELETE') {
    $id = isset($_GET['id']) ? (int)$_GET['id'] : null;
    if (!$id) {
        $input = getJsonInput();
        $id = isset($input['id']) ? (int)$input['id'] : null;
    }

    if (!$id) {
        sendJson(['error' => 'Missing user ID to delete.'], 400);
    }

    try {
        // Fetch target user
        $fetchStmt = $pdo->prepare("SELECT * FROM users WHERE id = :id LIMIT 1");
        $fetchStmt->execute([':id' => $id]);
        $targetUser = $fetchStmt->fetch();

        if (!$targetUser) {
            sendJson(['error' => 'User not found.'], 404);
        }

        // Prevent deleting the only admin
        if (($targetUser['role'] ?? '') === 'admin') {
            $adminCountStmt = $pdo->query("SELECT COUNT(*) as count FROM users WHERE role = 'admin'");
            $adminCount = (int)$adminCountStmt->fetch()['count'];
            if ($adminCount <= 1) {
                sendJson(['error' => 'Cannot delete the only remaining Administrator account.'], 400);
            }
        }

        $deleteStmt = $pdo->prepare("DELETE FROM users WHERE id = :id");
        $deleteStmt->execute([':id' => $id]);

        $displayName = !empty($targetUser['name']) ? $targetUser['name'] : ($targetUser['username'] ?? 'User');

        // Audit log in logs table
        try {
            $logStmt = $pdo->prepare("
                INSERT INTO logs (username, user_name, event, time) 
                VALUES (:username, :user_name, :event, :time)
            ");
            $logStmt->execute([
                ':username'  => $targetUser['username'] ?? '',
                ':user_name' => $displayName,
                ':event'     => "Deleted user '{$displayName}' (@" . ($targetUser['username'] ?? '') . ")",
                ':time'      => date('M d, Y h:i A'),
            ]);
        } catch (Exception $ex) {
            // Ignore log failure
        }

        sendJson([
            'status'  => 'deleted',
            'message' => "User '{$displayName}' deleted successfully.",
            'id'      => $id
        ]);
    } catch (Exception $e) {
        sendJson(['error' => 'Failed to delete user: ' . $e->getMessage()], 500);
    }
}
