import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:conveyor_ctrl/models/user_model.dart';
import 'package:conveyor_ctrl/providers/control_provider.dart';
import 'package:conveyor_ctrl/screens/users_screen.dart';

void main() {
  group('UserModel Tests (Admin & Staff)', () {
    test('Correctly parses Admin user from and to JSON', () {
      final json = {
        'id': 1,
        'name': 'Mario Santos',
        'username': 'mario_s',
        'role': 'admin',
        'created_at': '2026-09-03 12:00:00',
      };

      final user = UserModel.fromJson(json);
      expect(user.id, 1);
      expect(user.name, 'Mario Santos');
      expect(user.displayName, 'Mario Santos');
      expect(user.initials, 'MS');
      expect(user.username, 'mario_s');
      expect(user.role, 'admin');
      expect(user.isAdmin, isTrue);
      expect(user.isStaff, isFalse);
      expect(user.roleDisplay, 'Administrator');

      final serialized = user.toJson();
      expect(serialized['id'], 1);
      expect(serialized['name'], 'Mario Santos');
      expect(serialized['username'], 'mario_s');
      expect(serialized['role'], 'admin');
    });

    test('Correctly parses Staff user from JSON and maps legacy roles', () {
      const staffUser = UserModel(id: 2, name: 'John Doe', username: 'john_d', role: 'staff');
      expect(staffUser.isStaff, isTrue);
      expect(staffUser.isAdmin, isFalse);
      expect(staffUser.roleDisplay, 'Staff');
      expect(staffUser.initials, 'JD');

      // Legacy role json mapping
      final legacy = UserModel.fromJson({'id': 3, 'username': 'legacy_user', 'role': 'operator'});
      expect(legacy.role, 'staff');
      expect(legacy.isStaff, isTrue);
      expect(legacy.isAdmin, isFalse);
    });
  });

  group('ControlProvider RBAC & Scoped Logs Tests', () {
    test('Verifies Admin vs Staff permissions', () async {
      final provider = ControlProvider();

      // Default when no user logged in (defaults to Admin mode)
      expect(provider.isAdmin, isTrue);
      expect(provider.canControlMotor, isTrue);
      expect(provider.canEditSchedules, isTrue);
      expect(provider.canClearLogs, isTrue);
      expect(provider.canManageUsers, isTrue);

      // Log in as fallback admin
      await provider.login('admin', 'admin123');
      expect(provider.currentUser?.username, 'admin');
      expect(provider.isAdmin, isTrue);
      expect(provider.canManageUsers, isTrue);
      expect(provider.canClearLogs, isTrue);

      // Logout
      provider.logout();
      expect(provider.currentUser, isNull);
    });
  });

  group('UsersScreen Widget Tests', () {
    testWidgets('Renders UsersScreen with Admin & Staff search and add button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ControlProvider()),
          ],
          child: const MaterialApp(
            home: UsersScreen(),
          ),
        ),
      );

      expect(find.text('User Management'), findsOneWidget);
      expect(find.text('WORKFORCE & ACCESS'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('ADD STAFF / USER'), findsOneWidget);
    });
  });
}
