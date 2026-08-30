<?php
/**
 * /device_sync.php - ESP32 Hardware Heartbeat & Synchronization Endpoint
 */

require_once __DIR__ . '/db.php';

$pdo = getDb();
$input = getJsonInput();
$clientIp = $_SERVER['REMOTE_ADDR'] ?? 'unknown';

try {
    // 1. If ESP32 reported a log event, record it
    if (!empty($input['log_event'])) {
        $logTime = !empty($input['log_time']) ? $input['log_time'] : date('D h:i A');
        $logStmt = $pdo->prepare("INSERT INTO logs (event, time) VALUES (:event, :time)");
        $logStmt->execute([
            ':event' => trim($input['log_event']),
            ':time'  => $logTime
        ]);
    }

    // 2. If ESP32 reported a physical state change (e.g. physical button / timer finish)
    if (isset($input['actual_motor_state'])) {
        $actualState = (bool)$input['actual_motor_state'] ? 1 : 0;
        $upStmt = $pdo->prepare("
            UPDATE device_state 
            SET motor_state = :motor, last_ping = NOW(), ip_address = :ip 
            WHERE id = 1
        ");
        $upStmt->execute([
            ':motor' => $actualState,
            ':ip'    => $clientIp
        ]);
    } else {
        // Just update heartbeat ping and IP
        $upStmt = $pdo->prepare("
            UPDATE device_state 
            SET last_ping = NOW(), ip_address = :ip 
            WHERE id = 1
        ");
        $upStmt->execute([':ip' => $clientIp]);
    }

    // 3. Fetch current device state
    $stateStmt = $pdo->query("SELECT * FROM device_state WHERE id = 1 LIMIT 1");
    $stateRow = $stateStmt->fetch();
    $targetMotorState = $stateRow ? (bool)$stateRow['motor_state'] : false;

    // 4. Fetch all active schedules
    $schedStmt = $pdo->query("SELECT * FROM schedules WHERE enabled = 1 ORDER BY id ASC");
    $schedRows = $schedStmt->fetchAll();

    $schedules = [];
    foreach ($schedRows as $row) {
        $days = [];
        if (!empty($row['days'])) {
            $decodedDays = json_decode($row['days'], true);
            $days = is_array($decodedDays) ? $decodedDays : explode(',', $row['days']);
        }

        $schedules[] = [
            'id'       => (int)$row['id'],
            'type'     => $row['type'] ?? 'recurring',
            'time'     => $row['time'],
            'date'     => $row['date'],
            'days'     => !empty($days) ? $days : ['Daily'],
            'duration' => (int)$row['duration'],
            'enabled'  => (bool)$row['enabled']
        ];
    }

    // 5. Return sync payload to ESP32
    sendJson([
        'status'             => 'ok',
        'target_motor_state' => $targetMotorState,
        'server_time'        => date('h:i A'),
        'server_date'        => date('Y-m-d'),
        'server_day'         => date('D'),
        'timestamp'          => time(),
        'schedules'          => $schedules
    ]);
} catch (Exception $e) {
    sendJson(['error' => $e->getMessage()], 500);
}

