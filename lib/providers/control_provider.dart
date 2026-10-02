import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class ControlProvider with ChangeNotifier {
  late ApiService _apiService;
  bool _isMotorOn = false;
  bool _isConnected = false;
  List<Map<String, dynamic>> _schedules = [];
  String _ipAddress = 'https://pwms-9jkw.onrender.com'; // Live Render Cloud API

  UserModel? _currentUser;
  List<UserModel> _users = [];

  bool get isMotorOn => _isMotorOn;
  bool get isConnected => _isConnected;
  List<Map<String, dynamic>> get schedules => _schedules;
  String get ipAddress => _ipAddress;

  UserModel? get currentUser => _currentUser;
  List<UserModel> get users => _users;

  String get currentUserRole => _currentUser?.role.toLowerCase() ?? 'admin';
  bool get isAdmin => currentUserRole == 'admin';
  bool get isStaff => !isAdmin;

  bool get canControlMotor => true;
  bool get canEditSchedules => true;
  bool get canClearLogs => isAdmin;
  bool get canManageUsers => isAdmin;

  ControlProvider() {
    _apiService = ApiService(baseUrl: _ipAddress);
    refreshStatus();
  }

  void setIpAddress(String ip) {
    _ipAddress = ip.trim();
    _apiService = ApiService(baseUrl: _ipAddress);
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
    debugPrint('[PROVIDER] Toggling motor from $_isMotorOn to ${!_isMotorOn} by ${_currentUser?.displayName}...');
    final targetState = !_isMotorOn;
    final success = await _apiService.toggleMotor(
      targetState,
      username: _currentUser?.username,
      name: _currentUser?.displayName,
    );
    if (success) {
      _isMotorOn = targetState;
      debugPrint('[PROVIDER] Motor state updated in app to: $_isMotorOn');
      // Refresh logs so the action appears immediately in the logs tab
      fetchLogs();
      notifyListeners();
    } else {
      debugPrint('[PROVIDER] toggleMotor failed on API level!');
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
    final fetched = await _apiService.getLogs(
      username: _currentUser?.username,
      role: _currentUser?.role,
    );
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

  // --- USER MANAGEMENT METHODS ---

  Future<void> fetchUsers() async {
    try {
      final fetched = await _apiService.getUsers();
      _users = fetched.map((json) => UserModel.fromJson(json)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('[PROVIDER] fetchUsers error: $e');
    }
  }

  Future<void> createUser({
    String? name,
    required String username,
    required String password,
    required String role,
  }) async {
    try {
      await _apiService.createUser(
        name: name,
        username: username,
        password: password,
        role: role,
      );
      await fetchUsers();
    } catch (e) {
      debugPrint('[PROVIDER] createUser error: $e');
      rethrow;
    }
  }

  Future<void> updateUser(
    int id, {
    String? name,
    String? username,
    String? password,
    String? role,
  }) async {
    try {
      await _apiService.updateUser(
        id,
        name: name,
        username: username,
        password: password,
        role: role,
      );
      // If updating currently logged in user, refresh _currentUser state
      if (_currentUser != null && _currentUser!.id == id) {
        _currentUser = _currentUser!.copyWith(
          name: name,
          username: username,
          role: role,
        );
      }
      await fetchUsers();
    } catch (e) {
      debugPrint('[PROVIDER] updateUser error: $e');
      rethrow;
    }
  }

  Future<void> deleteUser(int id) async {
    try {
      await _apiService.deleteUser(id);
      _users.removeWhere((u) => u.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('[PROVIDER] deleteUser error: $e');
      rethrow;
    }
  }

  Future<bool> login(String username, String password) async {
    try {
      final res = await _apiService.login(username, password);
      if (res['status'] == 'ok') {
        if (res['user'] != null) {
          _currentUser = UserModel.fromJson(res['user']);
        } else {
          _currentUser = UserModel(id: 1, username: username, role: 'admin');
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (_) {
      // Fallback verification for default admin
      if (username == 'admin' && password == 'admin123') {
        _currentUser = const UserModel(id: 1, username: 'admin', role: 'admin');
        notifyListeners();
        return true;
      }
      rethrow;
    }
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
