import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl;

  ApiService({required this.baseUrl});

  Future<Map<String, dynamic>> getStatus() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/status')).timeout(const Duration(seconds: 5));
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
      final response = await http.post(
        Uri.parse('$baseUrl/toggle'),
        body: json.encode({'state': state}),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getSchedules() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/schedules')).timeout(const Duration(seconds: 5));
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
      final response = await http.post(
        Uri.parse('$baseUrl/schedules'),
        body: json.encode(schedules),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getLogs() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/logs')).timeout(const Duration(seconds: 5));
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
      final response = await http.delete(Uri.parse('$baseUrl/logs')).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
