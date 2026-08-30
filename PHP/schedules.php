<?php
/**
 * /schedules.php - Manage Automation Plans (CRUD)
 */

require_once __DIR__ . '/db.php';

$pdo = getDb();
$method = $_SERVER['REQUEST_METHOD'];

// Handle GET: Retrieve all automation schedules
if ($method === 'GET') {
    try {
        $stmt = $pdo->query("SELECT * FROM schedules ORDER BY id ASC");
        $rows = $stmt->fetchAll();

        $schedules = [];
        foreach ($rows as $row) {
            $days = [];
            if (!empty($row['days'])) {
                $decodedDays = json_decode($row['days'], true);
                $days = is_array($decodedDays) ? $decodedDays : explode(',', $row['days']);
            }

            $item = [
                'id'       => (int)$row['id'],
                'type'     => $row['type'] ?? 'recurring',
                'time'     => $row['time'],
                'duration' => (int)$row['duration'],
                'enabled'  => (bool)$row['enabled']
            ];

            if ($item['type'] === 'calendar' || !empty($row['date'])) {
                $item['date'] = $row['date'];
            } else {
                $item['days'] = !empty($days) ? $days : ['Daily'];
            }

            $schedules[] = $item;
        }

        sendJson($schedules);
    } catch (Exception $e) {
        sendJson(['error' => $e->getMessage()], 500);
    }
}

// Handle POST / PUT: Create or Replace/Update schedules
if ($method === 'POST' || $method === 'PUT') {
    $input = getJsonInput();

    try {
        // If an array of schedules is provided (bulk sync / replace all)
        if (isset($input[0]) && is_array($input[0])) {
            $pdo->beginTransaction();
            $pdo->exec("DELETE FROM schedules"); // Clean current list

            $insertStmt = $pdo->prepare("
                INSERT INTO schedules (type, time, date, days, duration, enabled)
                VALUES (:type, :time, :date, :days, :duration, :enabled)
            ");

            foreach ($input as $item) {
                $type = $item['type'] ?? (isset($item['date']) ? 'calendar' : 'recurring');
                $time = $item['time'] ?? '12:00 PM';
                $date = $item['date'] ?? null;
                $daysJson = isset($item['days']) && is_array($item['days']) 
                    ? json_encode(array_values($item['days'])) 
                    : json_encode(['Daily']);
                $duration = isset($item['duration']) ? (int)$item['duration'] : 1;
                $enabled = isset($item['enabled']) ? ($item['enabled'] ? 1 : 0) : 1;

                $insertStmt->execute([
                    ':type'     => $type,
                    ':time'     => $time,
                    ':date'     => $date,
                    ':days'     => $daysJson,
                    ':duration' => $duration,
                    ':enabled'  => $enabled
                ]);
            }

            $pdo->commit();
            sendJson(['status' => 'saved', 'count' => count($input)]);
        } 
        // Single schedule object provided
        else if (is_array($input) && !empty($input)) {
            $id = isset($input['id']) ? (int)$input['id'] : null;
            $type = $input['type'] ?? (isset($input['date']) ? 'calendar' : 'recurring');
            $time = $input['time'] ?? '12:00 PM';
            $date = $input['date'] ?? null;
            $daysJson = isset($input['days']) && is_array($input['days']) 
                ? json_encode(array_values($input['days'])) 
                : json_encode(['Daily']);
            $duration = isset($input['duration']) ? (int)$input['duration'] : 1;
            $enabled = isset($input['enabled']) ? ($input['enabled'] ? 1 : 0) : 1;

            if ($id) {
                // Update existing
                $stmt = $pdo->prepare("
                    UPDATE schedules 
                    SET type = :type, time = :time, date = :date, days = :days, duration = :duration, enabled = :enabled
                    WHERE id = :id
                ");
                $stmt->execute([
                    ':id'       => $id,
                    ':type'     => $type,
                    ':time'     => $time,
                    ':date'     => $date,
                    ':days'     => $daysJson,
                    ':duration' => $duration,
                    ':enabled'  => $enabled
                ]);
                sendJson(['status' => 'updated', 'id' => $id]);
            } else {
                // Insert new
                $stmt = $pdo->prepare("
                    INSERT INTO schedules (type, time, date, days, duration, enabled)
                    VALUES (:type, :time, :date, :days, :duration, :enabled)
                ");
                $stmt->execute([
                    ':type'     => $type,
                    ':time'     => $time,
                    ':date'     => $date,
                    ':days'     => $daysJson,
                    ':duration' => $duration,
                    ':enabled'  => $enabled
                ]);
                sendJson(['status' => 'created', 'id' => (int)$pdo->lastInsertId()]);
            }
        } else {
            sendJson(['error' => 'Invalid schedule payload.'], 400);
        }
    } catch (Exception $e) {
        if ($pdo->inTransaction()) {
            $pdo->rollBack();
        }
        sendJson(['error' => $e->getMessage()], 500);
    }
}

// Handle DELETE: Delete a schedule by ID
if ($method === 'DELETE') {
    $id = isset($_GET['id']) ? (int)$_GET['id'] : null;
    if (!$id) {
        $input = getJsonInput();
        $id = isset($input['id']) ? (int)$input['id'] : null;
    }

    if (!$id) {
        sendJson(['error' => 'Missing schedule "id" to delete.'], 400);
    }

    try {
        $stmt = $pdo->prepare("DELETE FROM schedules WHERE id = :id");
        $stmt->execute([':id' => $id]);
        sendJson(['status' => 'deleted', 'id' => $id]);
    } catch (Exception $e) {
        sendJson(['error' => $e->getMessage()], 500);
    }
}

