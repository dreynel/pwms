class UserModel {
  final int id;
  final String name;
  final String username;
  final String role;
  final String? createdAt;

  const UserModel({
    required this.id,
    this.name = '',
    required this.username,
    required this.role,
    this.createdAt,
  });

  String get displayName => name.trim().isNotEmpty ? name.trim() : username;

  String get initials {
    final clean = displayName.trim();
    if (clean.isEmpty) return 'U';
    final parts = clean.split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return clean.substring(0, clean.length >= 2 ? 2 : 1).toUpperCase();
  }

  bool get isAdmin => role.toLowerCase() == 'admin';
  bool get isStaff => !isAdmin;

  String get roleDisplay => isAdmin ? 'Administrator' : 'Staff';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final rawRole = json['role']?.toString().toLowerCase() ?? 'staff';
    final role = (rawRole == 'admin') ? 'admin' : 'staff';

    return UserModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      role: role,
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'role': role,
      'created_at': createdAt,
    };
  }

  UserModel copyWith({
    int? id,
    String? name,
    String? username,
    String? role,
    String? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          username == other.username &&
          role == other.role;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ username.hashCode ^ role.hashCode;
}
