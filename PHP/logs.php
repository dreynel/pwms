<?php
/**
 * /logs.php - Hardware and Automation Logs Management
 */

require_once __DIR__ . '/db.php';

$pdo = getDb();
$method = $_SERVER['REQUEST_METHOD'];

// Handle GET: Retrieve last 50 logs
if ($method === 'GET') {
    try {
        $stmt = $pdo->query("SELECT * FROM logs ORDER BY id DESC LIMIT 50");
        $rows = $stmt->fetchAll();

        $logs = [];
        foreach ($rows as $row) {
            $logs[] = [
                'id'         => (int)$row['id'],
                'event'      => $row['event'],
                'time'       => $row['time'],
                'created_at' => $row['created_at']
            ];
        }

        // Return array of logs
        sendJson($logs);
    } catch (Exception $e) {
        sendJson(['error' => $e->getMessage()], 500);
    }
}

// Handle POST: Add new log entry (e.g. from ESP32 or app)
if ($method === 'POST') {
    $input = getJsonInput();

    if (empty($input['event'])) {
        sendJson(['error' => 'Missing "event" string.'], 400);
    }

    $event = trim($input['event']);
    $time = !empty($input['time']) ? trim($input['time']) : date('D h:i A');

    try {
        $stmt = $pdo->prepare("INSERT INTO logs (event, time) VALUES (:event, :time)");
        $stmt->execute([
            ':event' => $event,
            ':time'  => $time
        ]);

        sendJson([
            'status' => 'created',
            'id'     => (int)$pdo->lastInsertId()
        ]);
    } catch (Exception $e) {
        sendJson(['error' => $e->getMessage()], 500);
    }
}

// Handle DELETE: Clear all logs
if ($method === 'DELETE') {
    try {
        $pdo->exec("DELETE FROM logs");
        sendJson(['status' => 'deleted']);
    } catch (Exception $e) {
        sendJson(['error' => $e->getMessage()], 500);
    }
}

