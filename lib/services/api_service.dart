import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl;

  ApiService({required this.baseUrl});

  String _buildUrl(String endpoint) {
    String base = baseUrl.trim();
    if (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    if (!base.startsWith('http://') && !base.startsWith('https://')) {
      base = 'http://$base';
    }
    return '$base/$endpoint';
  }

  Future<http.Response> _get(String endpoint) async {
    final url = _buildUrl(endpoint);
    try {
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));
      if (res.statusCode == 404 && !endpoint.endsWith('.php')) {
        return await http.get(Uri.parse(_buildUrl('$endpoint.php'))).timeout(const Duration(seconds: 8));
      }
      return res;
    } catch (_) {
      if (!endpoint.endsWith('.php')) {
        return await http.get(Uri.parse(_buildUrl('$endpoint.php'))).timeout(const Duration(seconds: 8));
      }
      rethrow;
    }
  }

  Future<http.Response> _post(String endpoint, {required String body}) async {
    final headers = {'Content-Type': 'application/json'};
    final url = _buildUrl(endpoint);
    try {
      final res = await http.post(Uri.parse(url), body: body, headers: headers).timeout(const Duration(seconds: 8));
      if (res.statusCode == 404 && !endpoint.endsWith('.php')) {
        return await http.post(Uri.parse(_buildUrl('$endpoint.php')), body: body, headers: headers).timeout(const Duration(seconds: 8));
      }
      return res;
    } catch (_) {
      if (!endpoint.endsWith('.php')) {
        return await http.post(Uri.parse(_buildUrl('$endpoint.php')), body: body, headers: headers).timeout(const Duration(seconds: 8));
      }
      rethrow;
    }
  }

  Future<http.Response> _delete(String endpoint) async {
    final url = _buildUrl(endpoint);
    try {
      final res = await http.delete(Uri.parse(url)).timeout(const Duration(seconds: 8));
      if (res.statusCode == 404 && !endpoint.endsWith('.php')) {
        return await http.delete(Uri.parse(_buildUrl('$endpoint.php'))).timeout(const Duration(seconds: 8));
      }
      return res;
    } catch (_) {
      if (!endpoint.endsWith('.php')) {
        return await http.delete(Uri.parse(_buildUrl('$endpoint.php'))).timeout(const Duration(seconds: 8));
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getStatus() async {
    try {
      final response = await _get('status');
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to get status');
    } catch (e) {
      throw Exception('Connection Error: $e');
    }
  }

  Future<bool> toggleMotor(bool state) async {
    try {
      final response = await _post('toggle', body: json.encode({'state': state}));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getSchedules() async {
    try {
      final response = await _get('schedules');
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> updateSchedules(List<Map<String, dynamic>> schedules) async {
    try {
      final response = await _post('schedules', body: json.encode(schedules));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getLogs() async {
    try {
      final response = await _get('logs');
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> clearLogs() async {
    try {
      final response = await _delete('logs');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _post(
        'login',
        body: json.encode({
          'username': username,
          'password': password,
        }),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      final err = json.decode(response.body);
      throw Exception(err['error'] ?? 'Invalid username or password');
    } catch (e) {
      rethrow;
    }
  }
}
