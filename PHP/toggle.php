<?php
/**
 * POST /toggle.php - Toggle or set motor state remotely with user audit tracking
 */

require_once __DIR__ . '/db.php';

$pdo = getDb();
$input = getJsonInput();

if (!isset($input['state'])) {
    sendJson(['error' => 'Missing "state" boolean field in request body.'], 400);
}

$newState = (bool)$input['state'];
$newStateInt = $newState ? 1 : 0;
$username = isset($input['username']) ? trim($input['username']) : null;
$userName = isset($input['name']) ? trim($input['name']) : (isset($input['user_name']) ? trim($input['user_name']) : null);

try {
    // 1. Update motor state in database
    $stmt = $pdo->prepare("UPDATE device_state SET motor_state = :state WHERE id = 1");
    $stmt->execute([':state' => $newStateInt]);

    // 2. Add an event log entry with user attribution
    $userLabel = '';
    if (!empty($userName) || !empty($username)) {
        $display = !empty($userName) ? $userName : $username;
        $userLabel = " by {$display}" . (!empty($username) ? " (@{$username})" : "");
    }

    $action = $newState ? 'Motor turned ON' : 'Motor turned OFF';
    $eventText = $action . $userLabel;
    $logTime = date('M d, Y h:i A'); // e.g. "Oct 07, 2026 10:55 AM"

    $logStmt = $pdo->prepare("
        INSERT INTO logs (username, user_name, event, time) 
        VALUES (:username, :user_name, :event, :time)
    ");
    $logStmt->execute([
        ':username'  => $username,
        ':user_name' => $userName,
        ':event'     => $eventText,
        ':time'      => $logTime
    ]);

    sendJson([
        'status' => 'ok',
        'motor'  => $newState,
        'time'   => date('h:i A')
    ]);
} catch (Exception $e) {
    sendJson(['error' => $e->getMessage()], 500);
}
