# Hostinger PHP + MySQL Cloud Deployment Guide

This guide walks you through deploying the Conveyor Control PHP backend and MySQL database on Hostinger in just a few minutes.

---

## 1. Create MySQL Database in Hostinger hPanel

1. Log in to your [Hostinger hPanel](https://hpanel.hostinger.com).
2. Under **Databases**, select **MySQL Databases**.
3. Fill in:
   - **Database name**: e.g., `conveyor_db` (Hostinger will prefix it, e.g. `u123456789_conveyor_db`)
   - **Database username**: e.g., `conveyor_user`
   - **Password**: Create a strong password
4. Click **Create**.
5. Note down the **full database name**, **username**, and **password**.

---

## 2. Import Database Schema in phpMyAdmin

1. In Hostinger hPanel under **MySQL Databases**, find your new database and click **Enter phpMyAdmin**.
2. Inside phpMyAdmin, click the **Import** tab at the top.
3. Click **Choose File** and select `schema.sql` (located in the `PHP/` folder).
4. Click **Import** (or **Go** at the bottom).
5. The tables `schedules`, `logs`, and `device_state` will be created automatically.

---

## 3. Configure `PHP/db.php`

Open `PHP/db.php` and update the constants with your Hostinger database details:

```php
define('DB_HOST', 'localhost');                  // Keep 'localhost'
define('DB_NAME', 'u123456789_conveyor_db');    // Your Hostinger Database Name
define('DB_USER', 'u123456789_conveyor_user');  // Your Hostinger Database Username
define('DB_PASS', 'YourStrongPasswordHere');     // Your Hostinger Database Password
define('TIMEZONE', 'Asia/Singapore');            // Set your local timezone (e.g. UTC, Asia/Manila, etc.)
```

---

## 4. Upload Files to Hostinger

1. In Hostinger hPanel, go to **Files** -> **File Manager** (or connect via FTP / FileZilla).
2. Navigate to `public_html/`.
3. Create a new folder named `api` (path: `public_html/api/`).
4. Upload all files from the `PHP/` directory into `public_html/api/`:
   - `db.php`
   - `status.php`
   - `toggle.php`
   - `schedules.php`
   - `logs.php`
   - `device_sync.php`
   - `.htaccess`

---

## 5. Verify the API in Your Browser

Open your browser and navigate to:
```
https://yourdomain.com/api/status.php
```
*(Replace `yourdomain.com` with your actual domain or Hostinger preview domain)*

You should receive a JSON response similar to:
```json
{
  "motor": false,
  "connected": false,
  "time": "07:15 AM",
  "current_date": "2026-08-29",
  "current_day": "Sat",
  "last_ping": "2026-08-29 07:15:00"
}
```

---

## 6. Connect Flutter App & ESP32

### In the Flutter App:
1. Open the mobile app.
2. Go to the **CONFIG** (Settings) tab.
3. In the **API / SERVER URL** field, enter your full URL:
   ```
   https://yourdomain.com/api
   ```
4. Tap **Save**. Your app will now communicate directly with your Hostinger MySQL database from anywhere in the world.

### In the ESP32 Code (`conveyor_esp32.ino`):
Set the server URL in your Arduino code:
```cpp
const char* serverUrl = "https://yourdomain.com/api";
```
Upload the code to your ESP32 board.

