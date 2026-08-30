<?php
/**
 * POST /toggle.php - Toggle or set motor state remotely
 */

require_once __DIR__ . '/db.php';

$pdo = getDb();
$input = getJsonInput();

if (!isset($input['state'])) {
    sendJson(['error' => 'Missing "state" boolean field in request body.'], 400);
}

$newState = (bool)$input['state'];
$newStateInt = $newState ? 1 : 0;

try {
    // 1. Update motor state in database
    $stmt = $pdo->prepare("UPDATE device_state SET motor_state = :state WHERE id = 1");
    $stmt->execute([':state' => $newStateInt]);

    // 2. Add an event log entry
    $eventText = $newState ? 'Motor ON (Manual)' : 'Motor OFF (Manual)';
    $logTime = date('D h:i A'); // e.g. "Sat 07:15 AM"

    $logStmt = $pdo->prepare("INSERT INTO logs (event, time) VALUES (:event, :time)");
    $logStmt->execute([
        ':event' => $eventText,
        ':time'  => $logTime
    ]);

    sendJson([
        'status' => 'ok',
        'motor'  => $newState,
        'time'   => date('h:i A')
    ]);
} catch (Exception $e) {
    sendJson(['error' => $e->getMessage()], 500);
}

