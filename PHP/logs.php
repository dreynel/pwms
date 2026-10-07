<?php
/**
 * /logs.php - Hardware and Activity Logs Management
 * Retrieves and logs system and hardware activity (formatted as M d, Y).
 */

require_once __DIR__ . '/db.php';

$pdo = getDb();
$method = $_SERVER['REQUEST_METHOD'];

// Handle GET: Retrieve all system logs (Newest first for both Admin and Staff)
if ($method === 'GET') {
    try {
        $stmt = $pdo->query("SELECT * FROM logs ORDER BY id DESC LIMIT 150");
        $rows = $stmt->fetchAll();

        $logs = [];
        foreach ($rows as $row) {
            $timeVal = $row['time'];
            if (!empty($row['created_at'])) {
                try {
                    $dt = new DateTime($row['created_at'], new DateTimeZone('UTC'));
                    $dt->setTimezone(new DateTimeZone(TIMEZONE));
                    $timeVal = $dt->format('M d, Y h:i A');
                } catch (Exception $e) {
                    $timeVal = $row['time'];
                }
            }

            $logs[] = [
                'id'         => (int)$row['id'],
                'username'   => $row['username'] ?? null,
                'user_name'  => $row['user_name'] ?? null,
                'event'      => $row['event'],
                'time'       => $timeVal,
                'created_at' => $row['created_at']
            ];
        }

        sendJson($logs);
    } catch (Exception $e) {
        sendJson(['error' => $e->getMessage()], 500);
    }
}

// Handle POST: Add new log entry (with user tracking)
if ($method === 'POST') {
    $input = getJsonInput();

    if (empty($input['event'])) {
        sendJson(['error' => 'Missing "event" string.'], 400);
    }

    $event     = trim($input['event']);
    $time      = !empty($input['time']) ? trim($input['time']) : date('M d, Y h:i A');
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
