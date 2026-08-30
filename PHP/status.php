<?php
/**
 * GET /status.php - Fetch current system & motor status
 */

require_once __DIR__ . '/db.php';

$pdo = getDb();

try {
    $stmt = $pdo->query("SELECT * FROM device_state WHERE id = 1 LIMIT 1");
    $state = $stmt->fetch();

    $motorState = false;
    $isConnected = false;
    $lastPingStr = '';

    if ($state) {
        $motorState = (bool)$state['motor_state'];
        $lastPingStr = $state['last_ping'];

        // If ESP32 checked in within the last 90 seconds, consider it online
        if (!empty($state['last_ping'])) {
            $lastPingTime = strtotime($state['last_ping']);
            if (time() - $lastPingTime <= 90) {
                $isConnected = true;
            }
        }
    }

    sendJson([
        'motor'        => $motorState,
        'connected'    => $isConnected,
        'time'         => date('h:i A'),
        'current_date' => date('Y-m-d'),
        'current_day'  => date('D'),
        'last_ping'    => $lastPingStr
    ]);
} catch (Exception $e) {
    sendJson(['error' => $e->getMessage()], 500);
}

