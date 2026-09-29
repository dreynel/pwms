import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl;

  ApiService({required this.baseUrl});

  String _buildUrl(String endpoint) {
    String base = baseUrl.trim();
    if (base.contains('?')) {
      base = base.split('?').first.trim();
    }
    if (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    if (!base.startsWith('http://') && !base.startsWith('https://')) {
      base = 'http://$base';
    }
    return '$base/$endpoint';
  }

  Map<String, String> get _defaultHeaders => {
    'Accept': 'application/json, text/plain, */*',
    'User-Agent': 'PWMS-App/1.0',
  };

  Map<String, String> get _jsonHeaders => {
    'Content-Type': 'application/json; charset=UTF-8',
    'Accept': 'application/json, text/plain, */*',
    'User-Agent': 'PWMS-App/1.0',
  };

  Future<http.Response> _get(String endpoint) async {
    final url = _buildUrl(endpoint);
    try {
      final res = await http.get(Uri.parse(url), headers: _defaultHeaders).timeout(const Duration(seconds: 8));
      if (res.statusCode == 404 && !endpoint.endsWith('.php')) {
        return await http.get(Uri.parse(_buildUrl('$endpoint.php')), headers: _defaultHeaders).timeout(const Duration(seconds: 8));
      }
      return res;
    } catch (_) {
      if (!endpoint.endsWith('.php')) {
        return await http.get(Uri.parse(_buildUrl('$endpoint.php')), headers: _defaultHeaders).timeout(const Duration(seconds: 8));
      }
      rethrow;
    }
  }

  Future<http.Response> _post(String endpoint, {required String body}) async {
    final url = _buildUrl(endpoint);
    try {
      final res = await http.post(Uri.parse(url), body: body, headers: _jsonHeaders).timeout(const Duration(seconds: 8));
      if (res.statusCode == 404 && !endpoint.endsWith('.php')) {
        return await http.post(Uri.parse(_buildUrl('$endpoint.php')), body: body, headers: _jsonHeaders).timeout(const Duration(seconds: 8));
      }
      return res;
    } catch (_) {
      if (!endpoint.endsWith('.php')) {
        return await http.post(Uri.parse(_buildUrl('$endpoint.php')), body: body, headers: _jsonHeaders).timeout(const Duration(seconds: 8));
      }
      rethrow;
    }
  }

  Future<http.Response> _put(String endpoint, {required String body}) async {
    final url = _buildUrl(endpoint);
    try {
      final res = await http.put(Uri.parse(url), body: body, headers: _jsonHeaders).timeout(const Duration(seconds: 8));
      if (res.statusCode == 404 && !endpoint.endsWith('.php')) {
        return await http.put(Uri.parse(_buildUrl('$endpoint.php')), body: body, headers: _jsonHeaders).timeout(const Duration(seconds: 8));
      }
      return res;
    } catch (_) {
      if (!endpoint.endsWith('.php')) {
        return await http.put(Uri.parse(_buildUrl('$endpoint.php')), body: body, headers: _jsonHeaders).timeout(const Duration(seconds: 8));
      }
      rethrow;
    }
  }

  Future<http.Response> _delete(String endpoint) async {
    final url = _buildUrl(endpoint);
    try {
      final res = await http.delete(Uri.parse(url), headers: _defaultHeaders).timeout(const Duration(seconds: 8));
      if (res.statusCode == 404 && !endpoint.endsWith('.php')) {
        return await http.delete(Uri.parse(_buildUrl('$endpoint.php')), headers: _defaultHeaders).timeout(const Duration(seconds: 8));
      }
      return res;
    } catch (_) {
      if (!endpoint.endsWith('.php')) {
        return await http.delete(Uri.parse(_buildUrl('$endpoint.php')), headers: _defaultHeaders).timeout(const Duration(seconds: 8));
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getStatus() async {
    try {
      final response = await _get('status.php');
      debugPrint('[API] getStatus: ${response.statusCode} -> ${response.body}');
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to get status (${response.statusCode})');
    } catch (e) {
      debugPrint('[API] getStatus error: $e');
      throw Exception('Connection Error: $e');
    }
  }

  Future<bool> toggleMotor(
    bool state, {
    String? username,
    String? name,
  }) async {
    try {
      debugPrint('[API] Sending toggleMotor(state: $state, user: $username)...');
      final payload = <String, dynamic>{'state': state};
      if (username != null && username.isNotEmpty) payload['username'] = username;
      if (name != null && name.isNotEmpty) payload['name'] = name;

      final response = await _post('toggle.php', body: json.encode(payload));
      debugPrint('[API] toggleMotor status: ${response.statusCode}, body: ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[API] toggleMotor error: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getSchedules() async {
    try {
      final response = await _get('schedules.php');
      debugPrint('[API] getSchedules: ${response.statusCode}');
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('[API] getSchedules error: $e');
      return [];
    }
  }

  Future<bool> updateSchedules(List<Map<String, dynamic>> schedules) async {
    try {
      final response = await _post('schedules.php', body: json.encode(schedules));
      debugPrint('[API] updateSchedules: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[API] updateSchedules error: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getLogs({String? username, String? role}) async {
    try {
      String endpoint = 'logs.php';
      if (username != null && username.isNotEmpty && role != 'admin') {
        endpoint = 'logs.php?username=${Uri.encodeComponent(username)}&role=staff';
      }
      final response = await _get(endpoint);
      debugPrint('[API] getLogs ($endpoint): ${response.statusCode}');
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('[API] getLogs error: $e');
      return [];
    }
  }

  Future<bool> clearLogs() async {
    try {
      final response = await _delete('logs.php');
      debugPrint('[API] clearLogs: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[API] clearLogs error: $e');
      return false;
    }
  }

  dynamic _safeDecode(http.Response response, {String fallbackError = 'Invalid server response'}) {
    try {
      return json.decode(response.body);
    } catch (_) {
      if (response.statusCode >= 400) {
        throw Exception('Server error (HTTP ${response.statusCode}). Please verify backend configuration.');
      }
      throw Exception(fallbackError);
    }
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _post(
        'login.php',
        body: json.encode({
          'username': username,
          'password': password,
        }),
      );
      debugPrint('[API] login: ${response.statusCode}');
      final data = _safeDecode(response, fallbackError: 'Login failed: unexpected server response');
      if (response.statusCode == 200 && data is Map<String, dynamic>) {
        return data;
      }
      if (data is Map<String, dynamic> && data['error'] != null) {
        throw Exception(data['error']);
      }
      throw Exception('Invalid username or password');
    } catch (e) {
      debugPrint('[API] login error: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      final response = await _get('users.php');
      debugPrint('[API] getUsers: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = _safeDecode(response);
        if (data is List) {
          return data.cast<Map<String, dynamic>>();
        }
      }
      return [];
    } catch (e) {
      debugPrint('[API] getUsers error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> createUser({
    String? name,
    required String username,
    required String password,
    required String role,
  }) async {
    try {
      final response = await _post(
        'users.php',
        body: json.encode({
          'name': name != null && name.trim().isNotEmpty ? name.trim() : username,
          'username': username,
          'password': password,
          'role': role,
        }),
      );
      debugPrint('[API] createUser: ${response.statusCode}');
      final data = _safeDecode(response, fallbackError: 'Failed to create user: server returned invalid response');
      if ((response.statusCode == 200 || response.statusCode == 201) && data is Map<String, dynamic>) {
        return data;
      }
      if (data is Map<String, dynamic> && data['error'] != null) {
        throw Exception(data['error']);
      }
      throw Exception('Failed to create user (HTTP ${response.statusCode})');
    } catch (e) {
      debugPrint('[API] createUser error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateUser(
    int id, {
    String? name,
    String? username,
    String? password,
    String? role,
  }) async {
    try {
      final Map<String, dynamic> payload = {'id': id};
      if (name != null && name.isNotEmpty) payload['name'] = name;
      if (username != null && username.isNotEmpty) payload['username'] = username;
      if (password != null && password.isNotEmpty) payload['password'] = password;
      if (role != null && role.isNotEmpty) payload['role'] = role;

      final response = await _put(
        'users.php',
        body: json.encode(payload),
      );
      debugPrint('[API] updateUser: ${response.statusCode}');
      final data = _safeDecode(response, fallbackError: 'Failed to update user: server returned invalid response');
      if (response.statusCode == 200 && data is Map<String, dynamic>) {
        return data;
      }
      if (data is Map<String, dynamic> && data['error'] != null) {
        throw Exception(data['error']);
      }
      throw Exception('Failed to update user (HTTP ${response.statusCode})');
    } catch (e) {
      debugPrint('[API] updateUser error: $e');
      rethrow;
    }
  }

  Future<bool> deleteUser(int id) async {
    try {
      final response = await _delete('users.php?id=$id');
      debugPrint('[API] deleteUser: ${response.statusCode}');
      if (response.statusCode == 200) {
        return true;
      }
      final data = _safeDecode(response);
      if (data is Map<String, dynamic> && data['error'] != null) {
        throw Exception(data['error']);
      }
      throw Exception('Failed to delete user');
    } catch (e) {
      debugPrint('[API] deleteUser error: $e');
      rethrow;
    }
  }
}
