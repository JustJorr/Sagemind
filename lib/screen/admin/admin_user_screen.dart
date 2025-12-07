import 'package:flutter/material.dart';
import '../../services/firestore_services.dart';
import '../../models/user_model.dart';

class AdminUserScreen extends StatefulWidget {
  const AdminUserScreen({super.key});

  @override
  _AdminUserScreenState createState() => _AdminUserScreenState();
}

class _AdminUserScreenState extends State<AdminUserScreen> {
  final FirestoreServices _firestore = FirestoreServices();
  List<UserModel> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    _users = await _firestore.getAllUsers();
    setState(() => _isLoading = false);
  }

  Future<void> _refresh() async {
    await _loadUsers();
    await Future.delayed(const Duration(milliseconds: 250));
  }

  Future<void> _updateUserRole(String userId, String newRole) async {
    await _firestore.updateUserRole(userId, newRole);
    await _loadUsers();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User role updated')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Users')),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())

          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  final user = _users[index];

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text(user.username),
                      subtitle: Text("${user.email} • Role: ${user.role}"),
                      trailing: DropdownButton<String>(
                        underline: const SizedBox(),
                        value: user.role,
                        items: const [
                          DropdownMenuItem(value: 'user', child: Text('User')),
                          DropdownMenuItem(value: 'admin', child: Text('Admin')),
                        ],
                        onChanged: (role) {
                          if (role != null && role != user.role) {
                            _updateUserRole(user.id, role);
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
