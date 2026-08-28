import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ControlProvider with ChangeNotifier {
  late ApiService _apiService;
  bool _isMotorOn = false;
  bool _isConnected = false;
  List<Map<String, dynamic>> _schedules = [];
  String _ipAddress = '192.168.1.1'; // Default ESP32 IP

  bool get isMotorOn => _isMotorOn;
  bool get isConnected => _isConnected;
  List<Map<String, dynamic>> get schedules => _schedules;
  String get ipAddress => _ipAddress;

  ControlProvider() {
    _apiService = ApiService(baseUrl: 'http://$_ipAddress');
    refreshStatus();
  }

  void setIpAddress(String ip) {
    _ipAddress = ip;
    _apiService = ApiService(baseUrl: 'http://$_ipAddress');
    refreshStatus();
    notifyListeners();
  }

  Future<void> refreshStatus() async {
    try {
      final status = await _apiService.getStatus();
      _isMotorOn = status['motor'] ?? false;
      _isConnected = true;
    } catch (e) {
      _isConnected = false;
    }
    notifyListeners();
  }

  Future<void> toggleMotor() async {
    final success = await _apiService.toggleMotor(!_isMotorOn);
    if (success) {
      _isMotorOn = !_isMotorOn;
      notifyListeners();
    }
  }

  Future<void> fetchSchedules() async {
    _schedules = await _apiService.getSchedules();
    notifyListeners();
  }

  Future<void> addSchedule({
    required String time,
    String type = 'recurring',
    List<String>? days,
    String? date,
    int duration = 1,
    bool enabled = true,
  }) async {
    final Map<String, dynamic> schedule = {
      'type': type,
      'time': time,
      'enabled': enabled,
      'duration': duration, // Duration in minutes
    };
    if (type == 'calendar' && date != null) {
      schedule['date'] = date;
    } else {
      schedule['days'] = days ?? ['Daily'];
    }
    _schedules.add(schedule);
    await _apiService.updateSchedules(_schedules);
    notifyListeners();
  }

  Future<void> updateSchedule(
    int index, {
    required String time,
    String type = 'recurring',
    List<String>? days,
    String? date,
    int duration = 1,
    bool? enabled,
  }) async {
    final bool currentEnabled = _schedules[index]['enabled'] ?? true;
    final Map<String, dynamic> schedule = {
      'type': type,
      'time': time,
      'enabled': enabled ?? currentEnabled,
      'duration': duration,
    };
    if (type == 'calendar' && date != null) {
      schedule['date'] = date;
    } else {
      schedule['days'] = days ?? ['Daily'];
    }
    _schedules[index] = schedule;
    await _apiService.updateSchedules(_schedules);
    notifyListeners();
  }

  Future<void> toggleSchedule(int index) async {
    if (index >= 0 && index < _schedules.length) {
      final current = _schedules[index]['enabled'] ?? true;
      _schedules[index]['enabled'] = !current;
      await _apiService.updateSchedules(_schedules);
      notifyListeners();
    }
  }

  Future<void> deleteSchedule(int index) async {
    _schedules.removeAt(index);
    await _apiService.updateSchedules(_schedules);
    notifyListeners();
  }

  List<Map<String, dynamic>> _logs = [];
  List<Map<String, dynamic>> get logs => _logs;

  Future<void> fetchLogs() async {
    final fetched = await _apiService.getLogs();
    _logs = fetched.reversed.toList();
    notifyListeners();
  }

  Future<void> clearLogs() async {
    final success = await _apiService.clearLogs();
    if (success) {
      _logs.clear();
      notifyListeners();
    }
  }
}
