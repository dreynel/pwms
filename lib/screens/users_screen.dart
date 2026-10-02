import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/control_provider.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  String _selectedRoleFilter = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ControlProvider>(context, listen: false).fetchUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<UserModel> _filterUsers(List<UserModel> users) {
    return users.where((user) {
      final matchesRole = _selectedRoleFilter == 'all' ||
          user.role.toLowerCase() == _selectedRoleFilter.toLowerCase();
      final query = _searchQuery.toLowerCase();
      final matchesSearch = query.isEmpty ||
          user.name.toLowerCase().contains(query) ||
          user.username.toLowerCase().contains(query);
      return matchesRole && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ControlProvider>(context);
    final filteredUsers = _filterUsers(provider.users);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildStickyHeader(context, provider),
            _buildSearchAndFilters(provider),
            Expanded(
              child: filteredUsers.isEmpty
                  ? _buildEmptyState()
                  : _buildUsersList(context, provider, filteredUsers),
            ),
            if (provider.canManageUsers) _buildAddAction(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStickyHeader(BuildContext context, ControlProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF1E293B)),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WORKFORCE & ACCESS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.blueAccent,
                    letterSpacing: 1.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Text(
                  'User Management',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF94A3B8), size: 20),
            tooltip: 'Refresh Users',
            onPressed: () => provider.fetchUsers(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(ControlProvider provider) {
    final allCount = provider.users.length;
    final adminCount = provider.users.where((u) => u.isAdmin).length;
    final staffCount = provider.users.where((u) => u.isStaff).length;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Column(
        children: [
          // Search Box
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              decoration: InputDecoration(
                hintText: 'Search by name or username...',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF94A3B8)),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Role Filter Tabs (Admin and Staff only)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildRoleFilterChip('all', 'All ($allCount)', Icons.people_outline_rounded),
                const SizedBox(width: 8),
                _buildRoleFilterChip('admin', 'Admins ($adminCount)', Icons.shield_outlined),
                const SizedBox(width: 8),
                _buildRoleFilterChip('staff', 'Staff ($staffCount)', Icons.badge_outlined),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleFilterChip(String key, String label, IconData icon) {
    final isSelected = _selectedRoleFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedRoleFilter = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 30,
                ),
              ],
            ),
            child: const Icon(Icons.person_off_rounded, size: 54, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 20),
          const Text(
            'No Users Found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'No users match "$_searchQuery"'
                : 'No users registered in this category.',
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList(
    BuildContext context,
    ControlProvider provider,
    List<UserModel> users,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
      physics: const BouncingScrollPhysics(),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final isCurrent = provider.currentUser?.id == user.id ||
            provider.currentUser?.username.toLowerCase() == user.username.toLowerCase();

        return _buildUserCard(context, provider, user, isCurrent);
      },
    );
  }

  Widget _buildUserCard(
    BuildContext context,
    ControlProvider provider,
    UserModel user,
    bool isCurrent,
  ) {
    final bool isAdmin = user.isAdmin;
    final Color roleColor = isAdmin ? const Color(0xFF7C3AED) : const Color(0xFF0284C7);
    final IconData roleIcon = isAdmin ? Icons.shield_rounded : Icons.badge_rounded;
    final String roleLabel = user.roleDisplay;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCurrent ? Colors.blueAccent.withValues(alpha: 0.5) : const Color(0xFFF1F5F9),
          width: isCurrent ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar with Initials & Role Theme
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                user.initials,
                style: TextStyle(
                  color: roleColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.displayName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Text(
                          'YOU',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: Colors.blueAccent,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '@${user.username}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: roleColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(roleIcon, size: 10, color: roleColor),
                          const SizedBox(width: 3),
                          Text(
                            roleLabel.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: roleColor,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Actions (Admin only)
          if (provider.canManageUsers) ...[
            const SizedBox(width: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: const Icon(Icons.edit_outlined, color: Color(0xFF64748B), size: 18),
                  tooltip: 'Edit User',
                  onPressed: () => _showUserFormDialog(context, existingUser: user),
                ),
                const SizedBox(width: 2),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: isCurrent ? const Color(0xFFCBD5E1) : Colors.redAccent,
                    size: 18,
                  ),
                  tooltip: isCurrent ? 'Cannot delete current account' : 'Delete User',
                  onPressed: isCurrent
                      ? null
                      : () => _confirmDeleteUser(context, provider, user),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddAction(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E293B),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          onPressed: () => _showUserFormDialog(context),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_add_alt_1_rounded, size: 18),
              SizedBox(width: 8),
              Text(
                'ADD STAFF / USER',
                style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.1, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUserFormDialog(BuildContext context, {UserModel? existingUser}) {
    final provider = Provider.of<ControlProvider>(context, listen: false);
    final isEditing = existingUser != null;

    final nameController = TextEditingController(text: existingUser?.name ?? '');
    final usernameController = TextEditingController(text: existingUser?.username ?? '');
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    String selectedRole = existingUser?.role.toLowerCase() ?? 'staff';
    if (selectedRole != 'admin') selectedRole = 'staff';

    bool obscurePassword = true;
    bool obscureConfirm = true;
    String? formError;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              actionsOverflowButtonSpacing: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Icon(
                    isEditing ? Icons.manage_accounts_rounded : Icons.person_add_rounded,
                    color: Colors.blueAccent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isEditing ? 'Edit User' : 'New Staff / User',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Full Name Field
                      const Text('Full Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          hintText: 'e.g. Mario Santos',
                          prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Username Field
                      const Text('Login Username', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: usernameController,
                        decoration: InputDecoration(
                          hintText: 'e.g. mario_s',
                          prefixIcon: const Icon(Icons.alternate_email_rounded, size: 20),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Role Selector (Admin or Staff only)
                      const Text('Access Role', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedRole,
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(
                                value: 'staff',
                                child: Text(
                                  'Staff (Controls & Schedules)',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'admin',
                                child: Text(
                                  'Administrator (Full Control)',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() => selectedRole = val);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Password Field
                      Text(
                        isEditing ? 'New Password (leave blank to keep current)' : 'Password',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        decoration: InputDecoration(
                          hintText: isEditing ? 'Leave blank to keep current' : 'Min 4 characters',
                          prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                              size: 18,
                              color: const Color(0xFF94A3B8),
                            ),
                            onPressed: () {
                              setDialogState(() => obscurePassword = !obscurePassword);
                            },
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Confirm Password Field (if creating or if password entered)
                      if (!isEditing || passwordController.text.isNotEmpty) ...[
                        const Text('Confirm Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: confirmPasswordController,
                          obscureText: obscureConfirm,
                          decoration: InputDecoration(
                            hintText: 'Repeat password',
                            prefixIcon: const Icon(Icons.lock_reset_rounded, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscureConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                size: 18,
                                color: const Color(0xFF94A3B8),
                              ),
                              onPressed: () {
                                setDialogState(() => obscureConfirm = !obscureConfirm);
                              },
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                      ],

                      // Form Error Display
                      if (formError != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  formError!,
                                  style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final name = nameController.text.trim();
                          final username = usernameController.text.trim();
                          final password = passwordController.text;
                          final confirmPassword = confirmPasswordController.text;

                          if (username.length < 3) {
                            setDialogState(() => formError = 'Username must be at least 3 characters.');
                            return;
                          }

                          if (!isEditing && password.isEmpty) {
                            setDialogState(() => formError = 'Password is required for new accounts.');
                            return;
                          }

                          if (password.isNotEmpty && password.length < 4) {
                            setDialogState(() => formError = 'Password must be at least 4 characters.');
                            return;
                          }

                          if (password.isNotEmpty && password != confirmPassword) {
                            setDialogState(() => formError = 'Passwords do not match.');
                            return;
                          }

                          setDialogState(() {
                            isSubmitting = true;
                            formError = null;
                          });

                          try {
                            if (isEditing) {
                              await provider.updateUser(
                                existingUser.id,
                                name: name.isNotEmpty ? name : username,
                                username: username,
                                role: selectedRole,
                                password: password.isNotEmpty ? password : null,
                              );
                            } else {
                              await provider.createUser(
                                name: name.isNotEmpty ? name : username,
                                username: username,
                                password: password,
                                role: selectedRole,
                              );
                            }

                            if (!context.mounted) return;
                            Navigator.pop(dialogContext);

                            final displayName = name.isNotEmpty ? name : username;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isEditing
                                      ? 'User "$displayName" updated successfully.'
                                      : 'User "$displayName" created successfully.',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            setDialogState(() {
                              isSubmitting = false;
                              formError = e.toString().replaceAll('Exception: ', '');
                            });
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          isEditing ? 'Save Changes' : 'Create Account',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteUser(
    BuildContext context,
    ControlProvider provider,
    UserModel user,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
              SizedBox(width: 8),
              Expanded(
                child: Text('Delete User', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete user "${user.displayName}" (@${user.username})? This action cannot be undone.',
            style: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);
                try {
                  await provider.deleteUser(user.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('User "${user.displayName}" was deleted.'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.toString().replaceAll('Exception: ', '')),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
