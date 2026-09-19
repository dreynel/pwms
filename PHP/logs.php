<?php
/**
 * /logs.php - Hardware and Activity Logs Management
 * Admin can view all logs; Staff can view ONLY their own logs.
 */

require_once __DIR__ . '/db.php';

$pdo = getDb();
$method = $_SERVER['REQUEST_METHOD'];

// Handle GET: Retrieve logs (All for Admin; Self-only for Staff)
if ($method === 'GET') {
    $username = isset($_GET['username']) ? trim($_GET['username']) : '';
    $role     = isset($_GET['role']) ? strtolower(trim($_GET['role'])) : '';

    try {
        // If Staff (username provided and role is not admin), filter only his/her logs
        if (!empty($username) && $role !== 'admin') {
            $stmt = $pdo->prepare("
                SELECT * FROM logs 
                WHERE username = :username 
                   OR event LIKE :fuzzy1 
                   OR event LIKE :fuzzy2
                ORDER BY id DESC 
                LIMIT 100
            ");
            $stmt->execute([
                ':username' => $username,
                ':fuzzy1'   => "%(@{$username})%",
                ':fuzzy2'   => "%({$username})%"
            ]);
        } else {
            // Admin or general fetch: Retrieve all logs
            $stmt = $pdo->query("SELECT * FROM logs ORDER BY id DESC LIMIT 100");
        }

        $rows = $stmt->fetchAll();

        $logs = [];
        foreach ($rows as $row) {
            $logs[] = [
                'id'         => (int)$row['id'],
                'username'   => $row['username'] ?? null,
                'user_name'  => $row['user_name'] ?? null,
                'event'      => $row['event'],
                'time'       => $row['time'],
                'created_at' => $row['created_at']
            ];
        }

        sendJson($logs);
    } catch (Exception $e) {
        sendJson(['error' => $e->getMessage()], 500);
    }
}

// Handle POST: Add new log entry (with optional user tracking)
if ($method === 'POST') {
    $input = getJsonInput();

    if (empty($input['event'])) {
        sendJson(['error' => 'Missing "event" string.'], 400);
    }

    $event     = trim($input['event']);
    $time      = !empty($input['time']) ? trim($input['time']) : date('D h:i A');
    $username  = isset($input['username']) ? trim($input['username']) : null;
    $userName  = isset($input['user_name']) ? trim($input['user_name']) : (isset($input['name']) ? trim($input['name']) : null);

    try {
        $stmt = $pdo->prepare("
            INSERT INTO logs (username, user_name, event, time) 
            VALUES (:username, :user_name, :event, :time)
        ");
        $stmt->execute([
            ':username'  => $username,
            ':user_name' => $userName,
            ':event'     => $event,
            ':time'      => $time
        ]);

        sendJson([
            'status' => 'created',
            'id'     => (int)$pdo->lastInsertId()
        ]);
    } catch (Exception $e) {
        sendJson(['error' => $e->getMessage()], 500);
    }
}

// Handle DELETE: Clear logs (Admin only)
if ($method === 'DELETE') {
    try {
        $pdo->exec("DELETE FROM logs");
        sendJson(['status' => 'deleted', 'message' => 'All logs cleared.']);
    } catch (Exception $e) {
        sendJson(['error' => $e->getMessage()], 500);
    }
}
